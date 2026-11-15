"""The parts of train_scan.py that need no GPU: reading a phone scan, the camera maths, and the splat file layout.

    python -m unittest test_train_scan      (from pipeline/, with numpy installed)
"""

import json
import tempfile
import unittest
import zipfile
from pathlib import Path

import numpy as np

from train_scan import intrinsics, load_scan, open_scan, save_ply, view_matrix


def write_scan(folder: Path, photos: int, missing: int = 0) -> None:
    (folder / "images").mkdir(parents=True)
    frames = []
    for i in range(photos):
        name = f"images/{i:05d}.jpg"
        if i >= missing:
            (folder / name).write_bytes(b"jpeg")
        pose = np.eye(4)
        pose[:3, 3] = [0.1 * i, 0.3, 0.5]
        frames.append({"file_path": name, "transform_matrix": pose.tolist(), "fl_x": 1500, "fl_y": 1500,
                       "cx": 959.5, "cy": 719.5, "w": 1920, "h": 1440, "time": i})
    index = {"format": "remote-assist-scan/1", "frame_of_reference": "marker", "marker_width_m": 0.18,
             "ply_file_path": "points.ply", "frames": frames}
    (folder / "transforms.json").write_text(json.dumps(index))
    (folder / "points.ply").write_text(
        "ply\nformat ascii 1.0\nelement vertex 2\nproperty float x\nproperty float y\nproperty float z\nend_header\n"
        "0.1 0.0 0.2\n-0.1 0.05 0.0\n"
    )


class TrainScanTests(unittest.TestCase):
    def test_reads_a_zipped_scan_with_its_top_folder(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            write_scan(tmp / "scan-1", photos=3)
            with zipfile.ZipFile(tmp / "scan.zip", "w") as archive:
                for path in (tmp / "scan-1").rglob("*"):
                    archive.write(path, path.relative_to(tmp))
            work = tmp / "work"
            work.mkdir()
            meta, root, frames, points = load_scan(open_scan(tmp / "scan.zip", work))
            self.assertEqual(meta["frame_of_reference"], "marker")
            self.assertEqual(len(frames), 3)
            self.assertEqual(points.shape, (2, 3))
            self.assertAlmostEqual(float(points[1, 1]), 0.05, places=6)

    def test_skips_frames_whose_photo_is_missing(self):
        with tempfile.TemporaryDirectory() as tmp:
            write_scan(Path(tmp), photos=4, missing=1)
            _, _, frames, _ = load_scan(open_scan(Path(tmp), Path(tmp)))
            self.assertEqual([f["file_path"] for f in frames], ["images/00001.jpg", "images/00002.jpg", "images/00003.jpg"])

    def test_a_camera_looking_at_the_marker_sees_it_in_front(self):
        # An ARKit camera 1 m above the marker plane's origin along +Z, looking down its own -Z at the origin.
        pose = np.eye(4)
        pose[:3, 3] = [0, 0, 1]
        origin = view_matrix(pose) @ np.array([0, 0, 0, 1])
        np.testing.assert_allclose(origin[:3], [0, 0, 1], atol=1e-6)
        right = view_matrix(pose) @ np.array([0.1, 0.2, 0, 1])
        np.testing.assert_allclose(right[:3], [0.1, -0.2, 1], atol=1e-6)

    def test_halving_the_photo_halves_the_lens(self):
        K = intrinsics({"fl_x": 1500, "fl_y": 1400, "cx": 959.5, "cy": 719.5}, 2)
        np.testing.assert_allclose(K, [[750, 0, 479.5], [0, 700, 359.5], [0, 0, 1]])

    def test_splat_file_has_the_3dgs_layout(self):
        n = 5
        rng = np.random.default_rng(1)
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "out.ply"
            save_ply(path, rng.normal(size=(n, 3)), rng.normal(size=(n, 3)), rng.normal(size=(n, 4)),
                     rng.normal(size=n), rng.normal(size=(n, 1, 3)), rng.normal(size=(n, 15, 3)))
            raw = path.read_bytes()
            header, body = raw.split(b"end_header\n", 1)
            properties = [line.split()[-1] for line in header.decode().splitlines() if line.startswith("property")]
            self.assertEqual(len(properties), 62)
            self.assertEqual(properties[:9], ["x", "y", "z", "nx", "ny", "nz", "f_dc_0", "f_dc_1", "f_dc_2"])
            self.assertEqual(properties[-8:], ["opacity", "scale_0", "scale_1", "scale_2", "rot_0", "rot_1", "rot_2", "rot_3"])
            self.assertEqual(len(body), n * 62 * 4)
            rows = np.frombuffer(body, "<f4").reshape(n, 62)
            np.testing.assert_allclose(np.linalg.norm(rows[:, -4:], axis=1), 1, atol=1e-5)


if __name__ == "__main__":
    unittest.main()
