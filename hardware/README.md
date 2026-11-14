# The UNO Q rig (RS challenge)

The rig checks the person on site really did a step: a Nicla Vision watches the patch panel and sees which port the
brightly coloured cable is in; the UNO Q compares that with what the current step expects and reports right or wrong
to the relay, which shows it on the expert's dashboard and on the phone.

```
Nicla Vision ──USB──▶ powered hub ──▶ UNO Q ──Wi-Fi──▶ relay ──▶ dashboard + phone
 nicla/main.py                         unoq/main.py
 "ports=16"                            "step 4 wanted port 17: wrong"
```

## What you need
- Arduino UNO Q, Nicla Vision, a USB-C hub with its **own charger** in its power input (the UNO Q doesn't power it).
- A micro-USB **data** cable for the Nicla. Charge-only cables fail without an error.
- One patch cable with a brightly coloured plug boot, and guide steps that carry `expect` (`contracts/protocol.ts`).

## Set up
1. **Nicla:** open `nicla/main.py` in OpenMV IDE with the Nicla plugged into a laptop. Set `PORT_REGIONS` (drag a box
   over each port in the frame buffer) and `CABLE_LAB` (Tools > Machine Vision > Threshold Editor, pointed at the
   plug boot). The values in the file are examples. Then Tools > Save open script to OpenMV Cam.
2. **Wire:** hub into the UNO Q, charger into the hub, Nicla into the hub.
3. **UNO Q:** run `unoq/main.py` with `pyserial` and `websocket-client` installed (`unoq/requirements.txt`):
   `RELAY_URL=ws://<relay laptop>:8080 python main.py`. It finds the Nicla on `/dev/ttyACM*` by itself.

## Test without the hardware
- Logic: `cd unoq && python -m unittest test_rig`
- The whole chain with typed-in Nicla lines: `python main.py --relay ws://localhost:8080 --nicla -`, then type
  `ports=16` or `ports=17` while a guide with `expect` is on the step.

## Known gaps
- Whether an App Lab app can open the Nicla's USB port is untested; forum reports conflict
  (`research/ledger.md` § 10). If it can't, run `unoq/main.py` over SSH, outside App Lab.
- `nicla/main.py` hasn't run on a Nicla yet, and its regions and colour are examples.
- The ✓ / ✗ on the UNO Q's LED matrix isn't written yet.
