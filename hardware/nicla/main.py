# Runs on the Nicla Vision (OpenMV). Watches the patch panel and prints which ports hold the brightly coloured cable,
# e.g. "ports=17", or "ports=" for none, for the UNO Q to read over USB.
#
# PORT_REGIONS and CABLE_LAB below are EXAMPLE values: set both on the real set before the demo, in OpenMV IDE.
# Regions: drag a box over each port in the frame buffer and read its x, y, w, h. Colour: point the camera at the
# cable's plug boot and use Tools > Machine Vision > Threshold Editor. Then Tools > Save open script to OpenMV Cam.
import sensor
import time

# Port name -> (x, y, w, h) in pixels at 320x240. Names must match the guide's `expect.port`.
PORT_REGIONS = {
    "14": (100, 150, 30, 30),
    "17": (190, 150, 30, 30),
}
# LAB range of the plug boot (L min, L max, A min, A max, B min, B max). This one is a bright green.
CABLE_LAB = (30, 100, -128, -20, -128, 127)
# Fewer matching pixels than this in a region is noise, not a plug boot.
MIN_PIXELS = 40
# A hand passing over the panel flickers the detections, so a change is reported only after this many identical frames.
STABLE_FRAMES = 5
# The current state is repeated this often, so a UNO Q app that starts late still learns it.
REPEAT_MS = 2000

sensor.reset()
sensor.set_pixformat(sensor.RGB565)
sensor.set_framesize(sensor.QVGA)
sensor.skip_frames(time=2000)
# Automatic gain and white balance would shift the cable's colour as the scene changes and break the threshold.
sensor.set_auto_gain(False)
sensor.set_auto_whitebal(False)


def occupied(img):
    return sorted(
        name
        for name, roi in PORT_REGIONS.items()
        if img.find_blobs([CABLE_LAB], roi=roi, pixels_threshold=MIN_PIXELS, merge=True)
    )


reported, candidate, seen, last_print = None, None, 0, time.ticks_ms()
while True:
    ports = occupied(sensor.snapshot())
    if ports == candidate:
        seen += 1
    else:
        candidate, seen = ports, 1
    now = time.ticks_ms()
    if seen >= STABLE_FRAMES and (candidate != reported or time.ticks_diff(now, last_print) >= REPEAT_MS):
        print("ports=" + ",".join(candidate))
        reported, last_print = candidate, now
