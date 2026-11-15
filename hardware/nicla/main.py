# Runs on the Nicla Vision (OpenMV). Watches the open laptop and prints which of its regions the brightly coloured
# sticker is in, e.g. "seen=ssd-bay", or "seen=" for none, for the UNO Q to read over USB. The sticker goes on the
# part the guide moves: the SSD in the demo.
#
# REGIONS and STICKER_LAB below are EXAMPLE values: set both on the real set before the demo, in OpenMV IDE.
# Regions: drag a box over each place in the frame buffer and read its x, y, w, h. Colour: point the camera at the
# sticker and use Tools > Machine Vision > Threshold Editor. Then Tools > Save open script to OpenMV Cam.
import sensor
import time

# Region name -> (x, y, w, h) in pixels at 320x240. Names must match the guide's `expect.region`. Beyond the right
# place, only add places the part could wrongly end up: the UNO Q reports the sticker in any other region as a
# mistake, so a region for "resting on the desk" would warn every time the part is put down.
REGIONS = {
    "ssd-bay": (120, 90, 90, 40),
}
# LAB range of the sticker (L min, L max, A min, A max, B min, B max). This one is a bright green.
STICKER_LAB = (30, 100, -128, -20, -128, 127)
# Fewer matching pixels than this in a region is noise, not the sticker.
MIN_PIXELS = 40
# A hand passing over the laptop flickers the detections, so a change is reported only after this many identical
# frames. A hand resting over the sticker for longer still reads as "gone": keep hands clear when a step is checked.
STABLE_FRAMES = 5
# The current state is repeated this often, so a UNO Q app that starts late still learns it.
REPEAT_MS = 2000

sensor.reset()
sensor.set_pixformat(sensor.RGB565)
sensor.set_framesize(sensor.QVGA)
sensor.skip_frames(time=2000)
# Automatic gain and white balance shift the sticker's colour as the scene changes, so they go off where the sensor
# allows it. The Nicla Vision's GC2145 refuses ("operation is not supported by the sensor"): there, keep the light on
# the set steady and tune STICKER_LAB under that light.
for lock_setting in (sensor.set_auto_gain, sensor.set_auto_whitebal):
    try:
        lock_setting(False)
    except RuntimeError:
        print("this sensor can't turn off " + lock_setting.__name__[4:])


def seen_in(img):
    return sorted(
        name
        for name, roi in REGIONS.items()
        if img.find_blobs([STICKER_LAB], roi=roi, pixels_threshold=MIN_PIXELS, merge=True)
    )


reported, candidate, count, last_print = None, None, 0, time.ticks_ms()
while True:
    regions = seen_in(sensor.snapshot())
    if regions == candidate:
        count += 1
    else:
        candidate, count = regions, 1
    now = time.ticks_ms()
    if count >= STABLE_FRAMES and (candidate != reported or time.ticks_diff(now, last_print) >= REPEAT_MS):
        print("seen=" + ",".join(candidate))
        reported, last_print = candidate, now
