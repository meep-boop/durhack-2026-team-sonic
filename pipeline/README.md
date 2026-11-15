# Scans made in our own app

The phone app's **Scan the room** records photos plus where the camera was for each one, measured from the printed
marker. The Spark trains a Gaussian splat from them with no COLMAP step, and the splat comes out already in the
marker's frame, in metres. Scaniverse stays the main scan route; this is the alternative to compare against.

**Status:** built on `max-ios-scan`, not run end to end yet. The phone part needs Salman to build it in Xcode. No
training time or alignment error has been measured, so don't quote any.

## 1. The laptop's inbox

On the laptop that runs the relay (Node 24, no install):

```bash
node pipeline/scan-inbox.ts
```

It prints `http://<ip>:8090/scan`. The phone finds it by itself: same address as the relay, port 8090. Scans land in
`pipeline/inbox/` (git-ignored) as `scan-<time>.zip`. Anyone on the hotspot can post to it, as with the relay; it
only ever writes new zips into that folder, up to 1 GB each.

## 2. On the phone

Home → **Scan the room**. Find the marker, tap Start, walk slowly round the laptop at three heights, make close
passes over the screws, come back to the marker, then Stop and save → Send to laptop. It keeps at most 400 photos and
skips any taken while the phone moves too fast.

## 3. Train on the Spark

Copy the zip across (FTP or `scp`), then once, in its own folder so `~/pixal3d` is untouched:

```bash
python3 -m venv ~/scan && source ~/scan/bin/activate
pip install torch==2.9.1 --index-url https://download.pytorch.org/whl/cu130   # the build ~/pixal3d already runs
pip install numpy pillow ninja packaging gsplat==1.5.3   # gsplat needs packaging but doesn't declare it
```

gsplat compiles its CUDA code on first use (set `TORCH_CUDA_ARCH_LIST="12.0"` for the GB10; ledger § 9). Then:

```bash
python train_scan.py scan-<time>.zip --check                  # what's in it; no GPU needed
python train_scan.py scan-<time>.zip --out app-<time>.ply     # 7000 steps on 960×720 photos
```

Copy `app-<time>.ply` into `dashboard/public/scans/` under a new name (the name is its calibration id) and open the
dashboard with `?open=app-<time>.ply`. Calibrate it with the four corner clicks as usual: because the scan is already
in the marker's frame, the clicks should land almost exactly on the printed corners, which is the check that it worked.

Tests: `node --test pipeline/` (the inbox) and `python -m unittest test_train_scan` from `pipeline/` (needs numpy).
