"""Train a Gaussian splat on the DGX Spark from a scan recorded in the phone app (ios/RemoteAssist/Scan).

The phone already knows where the camera was for every photo, measured from the printed marker, so this skips COLMAP
(the slow, fragile step of a desktop pipeline) and the splat comes out in the marker's frame, in metres. The
dashboard's four corner clicks then only confirm it lines up. ARKit's poses are good to about a centimetre
(research/ledger.md § 15), so this is a fast first version, not the sharpest possible splat.

    python train_scan.py <scan.zip or folder> --out app-<time>.ply [--steps 7000] [--downscale 2]
    python train_scan.py <scan.zip or folder> --check      # read the scan and print what's in it; no GPU needed
"""

import argparse
import json
import tempfile
import time
import zipfile
from pathlib import Path

import numpy as np

SH_C0 = 0.28209479177387814


def find_index(root: Path) -> Path:
    hits = sorted(root.rglob("transforms.json"))
    if not hits:
        raise SystemExit(f"no transforms.json under {root}")
    return hits[0]


def open_scan(source: Path, workdir: Path) -> Path:
    if source.is_dir():
        return find_index(source)
    # extractall drops absolute paths and ".." parts, so a zip can't write outside workdir.
    with zipfile.ZipFile(source) as archive:
        archive.extractall(workdir)
    return find_index(workdir)


def read_points(path: Path) -> np.ndarray:
    if not path.exists():
        return np.zeros((0, 3), np.float32)
    lines = path.read_text().splitlines()
    start = lines.index("end_header") + 1
    rows = [line.split()[:3] for line in lines[start:] if line.strip()]
    return np.asarray(rows, np.float32).reshape(-1, 3)


def load_scan(index_path: Path):
    meta = json.loads(index_path.read_text())
    if meta.get("frame_of_reference") != "marker":
        print("warning: this scan's poses aren't in the marker frame; the splat won't line up by itself")
    root = index_path.parent
    frames = [f for f in meta["frames"] if (root / f["file_path"]).exists()]
    missing = len(meta["frames"]) - len(frames)
    if missing:
        print(f"skipping {missing} frames whose photo never got written")
    points = read_points(root / meta.get("ply_file_path", "points.ply"))
    return meta, root, frames, points


def intrinsics(frame: dict, downscale: int) -> np.ndarray:
    # Pixel centres sit at +0.5, so the principal point shifts by more than a plain divide when the image shrinks.
    fx, fy = frame["fl_x"] / downscale, frame["fl_y"] / downscale
    cx, cy = (frame["cx"] + 0.5) / downscale - 0.5, (frame["cy"] + 0.5) / downscale - 0.5
    return np.array([[fx, 0, cx], [0, fy, cy], [0, 0, 1]], np.float32)


def view_matrix(camera_to_marker: np.ndarray) -> np.ndarray:
    # ARKit's camera looks down -Z with +Y up (OpenGL); gsplat wants OpenCV's +Z forward, +Y down.
    opencv = np.asarray(camera_to_marker, np.float64) @ np.diag([1.0, -1.0, -1.0, 1.0])
    return np.linalg.inv(opencv).astype(np.float32)


def camera_centres(frames: list) -> np.ndarray:
    return np.array([np.asarray(f["transform_matrix"])[:3, 3] for f in frames], np.float32)


def describe(meta: dict, frames: list, points: np.ndarray) -> None:
    centres = camera_centres(frames)
    distance = np.linalg.norm(centres, axis=1)
    print(f"format {meta.get('format')}, frame {meta.get('frame_of_reference')}, marker {meta.get('marker_width_m')} m")
    print(f"{len(frames)} photos, {frames[0]['w']}x{frames[0]['h']}, fx {frames[0]['fl_x']:.0f}")
    print(f"{len(points)} feature points; cameras {distance.min():.2f}-{distance.max():.2f} m from the marker centre")
    if len(points):
        print(f"points span x {np.ptp(points[:, 0]):.2f} m, y {np.ptp(points[:, 1]):.2f} m, z {np.ptp(points[:, 2]):.2f} m")


def starting_points(points: np.ndarray, rng: np.random.Generator) -> np.ndarray:
    # ARKit tracks only a few thousand corners on a plain desk; random fill gives densification something to grow from.
    if len(points) >= 2000:
        return points
    low, high = np.array([-0.6, -0.05, -0.6]), np.array([0.6, 0.5, 0.6])
    if len(points) >= 100:
        low, high = np.minimum(low, points.min(0)), np.maximum(high, points.max(0))
    fill = rng.uniform(low, high, size=(20000, 3)).astype(np.float32)
    return np.concatenate([points, fill])


def ssim_loss(x, y):
    import torch
    import torch.nn.functional as F

    size, sigma = 11, 1.5
    coords = torch.arange(size, device=x.device, dtype=x.dtype) - size // 2
    g = torch.exp(-(coords**2) / (2 * sigma**2))
    g = g / g.sum()
    window = (g[:, None] * g[None, :]).expand(3, 1, size, size).contiguous()

    def blur(t):
        return F.conv2d(t, window, padding=size // 2, groups=3)

    mu_x, mu_y = blur(x), blur(y)
    var_x = blur(x * x) - mu_x**2
    var_y = blur(y * y) - mu_y**2
    cov = blur(x * y) - mu_x * mu_y
    c1, c2 = 0.01**2, 0.03**2
    ssim = ((2 * mu_x * mu_y + c1) * (2 * cov + c2)) / ((mu_x**2 + mu_y**2 + c1) * (var_x + var_y + c2))
    return 1 - ssim.mean()


def save_ply(path: Path, means, log_scales, quats, opacity_logits, sh0, sh_rest) -> None:
    """The original 3DGS layout (log scales, logit opacity, wxyz quaternions), which Spark and every viewer read."""
    n = len(means)
    quats = quats / np.linalg.norm(quats, axis=1, keepdims=True)
    f_dc = sh0.reshape(n, 3)
    # 3DGS stores the higher bands channel by channel: all red coefficients, then green, then blue.
    f_rest = sh_rest.transpose(0, 2, 1).reshape(n, -1)
    names = ["x", "y", "z", "nx", "ny", "nz", "f_dc_0", "f_dc_1", "f_dc_2"]
    names += [f"f_rest_{i}" for i in range(f_rest.shape[1])]
    names += ["opacity", "scale_0", "scale_1", "scale_2", "rot_0", "rot_1", "rot_2", "rot_3"]
    data = np.concatenate(
        [means, np.zeros((n, 3)), f_dc, f_rest, opacity_logits.reshape(n, 1), log_scales, quats], axis=1
    ).astype("<f4")
    header = f"ply\nformat binary_little_endian 1.0\nelement vertex {n}\n"
    header += "".join(f"property float {name}\n" for name in names) + "end_header\n"
    with open(path, "wb") as out:
        out.write(header.encode())
        out.write(data.tobytes())


def train(root: Path, frames: list, points: np.ndarray, args) -> None:
    import torch
    from gsplat import rasterization
    from gsplat.strategy import DefaultStrategy
    from PIL import Image

    device = "cuda"
    rng = np.random.default_rng(0)
    torch.manual_seed(0)

    started = time.time()
    images, Ks, viewmats = [], [], []
    for frame in frames:
        width, height = frame["w"] // args.downscale, frame["h"] // args.downscale
        image = Image.open(root / frame["file_path"]).convert("RGB").resize((width, height), Image.Resampling.BILINEAR)
        images.append(torch.from_numpy(np.asarray(image)).to(device))
        Ks.append(intrinsics(frame, args.downscale))
        viewmats.append(view_matrix(frame["transform_matrix"]))
    Ks = torch.from_numpy(np.stack(Ks)).to(device)
    viewmats = torch.from_numpy(np.stack(viewmats)).to(device)
    height, width = images[0].shape[:2]
    print(f"loaded {len(images)} photos at {width}x{height} in {time.time() - started:.0f} s")

    centres = camera_centres(frames)
    scene_scale = float(np.linalg.norm(centres - centres.mean(0), axis=1).max() * 1.1)

    means = torch.from_numpy(starting_points(points, rng)).to(device)
    # Start each splat about as wide as the gap to its three nearest neighbours.
    nearest = torch.cat([torch.cdist(chunk, means).topk(4, largest=False).values[:, 1:] for chunk in means.split(1024)])
    log_scales = torch.log(nearest.mean(1).clamp(min=1e-4, max=0.05)).unsqueeze(1).repeat(1, 3)
    n = len(means)
    rest = (args.sh_degree + 1) ** 2 - 1
    params = torch.nn.ParameterDict({
        "means": torch.nn.Parameter(means),
        "scales": torch.nn.Parameter(log_scales),
        "quats": torch.nn.Parameter(torch.rand(n, 4, device=device)),
        "opacities": torch.nn.Parameter(torch.logit(torch.full((n,), 0.1, device=device))),
        "sh0": torch.nn.Parameter(torch.zeros(n, 1, 3, device=device)),
        "shN": torch.nn.Parameter(torch.zeros(n, rest, 3, device=device)),
    })
    # gsplat's simple_trainer defaults; only the means scale with the size of the scene.
    rates = {"means": 1.6e-4 * scene_scale, "scales": 5e-3, "quats": 1e-3, "opacities": 5e-2, "sh0": 2.5e-3, "shN": 2.5e-3 / 20}
    optimizers = {
        name: torch.optim.Adam([{"params": params[name], "lr": rate, "name": name}], eps=1e-15) for name, rate in rates.items()
    }
    schedule = torch.optim.lr_scheduler.ExponentialLR(optimizers["means"], gamma=0.01 ** (1.0 / args.steps))
    # Stop adding and pruning splats with 30% of the run left, so the final ones settle before export.
    strategy = DefaultStrategy(refine_stop_iter=int(args.steps * 0.7), verbose=False)
    strategy.check_sanity(params, optimizers)
    state = strategy.initialize_state(scene_scale=scene_scale)

    started = time.time()
    order = rng.permutation(len(images))
    for step in range(args.steps):
        if step and step % len(images) == 0:
            order = rng.permutation(len(images))
        i = int(order[step % len(images)])
        truth = images[i].float() / 255
        render, _, info = rasterization(
            means=params["means"],
            quats=params["quats"],
            scales=torch.exp(params["scales"]),
            opacities=torch.sigmoid(params["opacities"]),
            colors=torch.cat([params["sh0"], params["shN"]], 1),
            viewmats=viewmats[i : i + 1],
            Ks=Ks[i : i + 1],
            width=width,
            height=height,
            sh_degree=min(step // 1000, args.sh_degree),
            packed=False,
        )
        strategy.step_pre_backward(params, optimizers, state, step, info)
        prediction = render[0]
        loss = 0.8 * (prediction - truth).abs().mean() + 0.2 * ssim_loss(
            prediction.permute(2, 0, 1)[None], truth.permute(2, 0, 1)[None]
        )
        loss.backward()
        for optimizer in optimizers.values():
            optimizer.step()
            optimizer.zero_grad(set_to_none=True)
        schedule.step()
        strategy.step_post_backward(params, optimizers, state, step, info, packed=False)
        if step % 500 == 0 or step == args.steps - 1:
            print(f"step {step:5d}  loss {loss.item():.4f}  splats {len(params['means']):7d}  {time.time() - started:5.0f} s")
    print(f"trained {args.steps} steps in {time.time() - started:.0f} s")

    with torch.no_grad():
        keep = (params["means"].norm(dim=1) < args.crop) & (torch.sigmoid(params["opacities"]) > 0.005)
        print(f"kept {int(keep.sum())} of {len(keep)} splats within {args.crop} m of the marker")
        save_ply(
            args.out,
            params["means"][keep].cpu().numpy(),
            params["scales"][keep].cpu().numpy(),
            params["quats"][keep].cpu().numpy(),
            params["opacities"][keep].cpu().numpy(),
            params["sh0"][keep].cpu().numpy(),
            params["shN"][keep].cpu().numpy(),
        )
    print(f"wrote {args.out} ({args.out.stat().st_size / 1024**2:.1f} MB)")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("scan", type=Path, help="the zip from pipeline/inbox, or an unzipped scan folder")
    parser.add_argument("--out", type=Path, help="where to write the splat (.ply)")
    parser.add_argument("--steps", type=int, default=7000)
    parser.add_argument("--downscale", type=int, default=2, help="train on 1/N-size photos (2 = 960x720)")
    parser.add_argument("--sh-degree", type=int, default=3)
    parser.add_argument("--crop", type=float, default=1.5, help="drop splats further than this (m) from the marker")
    parser.add_argument("--check", action="store_true", help="only read the scan and print what's in it")
    args = parser.parse_args()

    with tempfile.TemporaryDirectory() as work:
        meta, root, frames, points = load_scan(open_scan(args.scan, Path(work)))
        if not frames:
            raise SystemExit("no photos in this scan")
        describe(meta, frames, points)
        if args.check:
            return
        if args.out is None:
            raise SystemExit("--out is needed to train")
        train(root, frames, points, args)


if __name__ == "__main__":
    main()
