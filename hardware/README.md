# The UNO Q rig (RS challenge)

The rig checks the person on site really did a step. A bright sticker goes on the part the guide moves (the SSD in
the demo). A Nicla Vision watches the open laptop and sees whether the sticker is in the SSD bay; the UNO Q compares
that with what the current step expects and reports right or wrong to the relay, which shows it on the expert's
dashboard and on the phone.

```
Nicla Vision ──USB──▶ powered hub ──▶ UNO Q ──Wi-Fi──▶ relay ──▶ dashboard + phone
 nicla/main.py                         unoq/python/main.py + unoq/sketch/sketch.ino
 "seen=ssd-bay"                        "step 4 wanted it in the bay: correct", ✓ on its LED matrix
```

## What you need
- Arduino UNO Q, Nicla Vision, a USB-C hub with its **own charger** in its power input (the UNO Q doesn't power it).
- A micro-USB **data** cable for the Nicla. Charge-only cables fail without an error.
- One brightly coloured sticker on the SSD, in a colour nothing else in view has, and guide steps that carry
  `expect: { region, present }` (`contracts/protocol.ts`).

## Set up
1. **Nicla:** open `nicla/main.py` in OpenMV IDE with the Nicla plugged into a laptop. Set `REGIONS` (drag a box over
   the SSD bay in the frame buffer) and `STICKER_LAB` (Tools > Machine Vision > Threshold Editor, pointed at the
   sticker). The values in the file are examples. Then Tools > Save open script to OpenMV Cam.
2. **Wire:** hub into the UNO Q, charger into the hub, Nicla into the hub. Fix the Nicla so it can't move: its
   regions are in pixels.
3. **UNO Q, in App Lab:** make a new app. Copy everything in `unoq/python/` into the app's `python` folder
   (`requirements.txt` must sit there, beside `main.py`, or App Lab installs nothing) and `unoq/sketch/sketch.ino` over
   the app's sketch. Set `RELAY_URL` near the top of `main.py` to the address the relay prints. Press Run. It finds the
   Nicla on `/dev/ttyACM*` by itself, and the LED matrix shows ✓ or ✗ for the current step. If the sketch fails to
   compile on `Arduino_RouterBridge.h`, add that library to the app in App Lab.
4. **UNO Q, without App Lab** (if the access test shows App Lab can't open the Nicla's port): over SSH,
   `pip install -r requirements.txt`, then `RELAY_URL=ws://<relay laptop>:8080 python main.py` in `unoq/python/`. The
   rig works the same; only the LED matrix is off.

## Test without the hardware
- Logic: `cd unoq/python && python -m unittest test_rig`
- The whole chain with typed-in Nicla lines: start the relay, run `node fixtures/fake-expert.ts --step s3`, then
  `python main.py --relay ws://localhost:8080 --nicla -` and type `seen=ssd-bay`, then `seen=`.

## Known gaps
- Whether an App Lab app can open the Nicla's USB port is untested; forum reports conflict
  (`research/ledger.md` § 10). If it can't, run `unoq/python/main.py` over SSH, outside App Lab (step 4).
- `nicla/main.py` hasn't run on a Nicla yet, and its region and colour are examples.
- A hand resting over the sticker looks the same as the part being gone, so "take the SSD out" can tick early.
- The LED matrix code and the App Lab path haven't run on the board: they follow Arduino's own LED Matrix Painter
  example and were checked here against a stand-in for App Lab's module. If the tick looks scrambled, the matrix lays
  pixels out column by column (`sketch.ino` says how to flip it).
