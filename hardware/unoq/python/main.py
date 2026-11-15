"""Runs on the UNO Q: reads which regions the Nicla Vision sees the stickered part in, follows the guide through the
relay as the `rig`, reports `step.verified`, and shows a tick or a cross on the board's LED matrix.

    In App Lab: set RELAY_URL below, copy this folder and ../sketch into an app, press Run.
    RELAY_URL=ws://<relay laptop>:8080 python main.py            # over SSH or on a laptop: no LED matrix
    python main.py --relay ws://... --nicla -                     # type `seen=ssd-bay` lines instead of a Nicla
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import sys
import threading
from collections.abc import Iterator

import serial
import websocket

from rig import Rig, parse_seen

try:
    # Only there inside an App Lab app on the UNO Q. Elsewhere the rig runs the same, without the LED matrix.
    from arduino.app_utils import App, Bridge
except ImportError:
    App = Bridge = None

# App Lab can't pass arguments or environment variables, so in App Lab put the relay's address between these quotes.
# Edit this line; a second RELAY_URL line higher up is overwritten by this one.
RELAY_URL = ""

# Codes for show_verdict in ../sketch/sketch.ino.
BLANK, TICK, CROSS = 0, 1, 2


def show(code: int) -> None:
    if Bridge:
        Bridge.call("show_verdict", code)


def nicla_lines(path: str) -> Iterator[str]:
    if path == "-":
        yield from sys.stdin
        return
    nicla = serial.Serial()
    nicla.port, nicla.baudrate, nicla.timeout = path, 115200, 1
    # OpenMV holds back printed output while DTR is set (research/ledger.md § 10).
    nicla.dtr = False
    nicla.open()
    while True:
        yield nicla.readline().decode(errors="replace")


def find_nicla() -> str:
    ports = sorted(glob.glob("/dev/ttyACM*"))
    if not ports:
        sys.exit("No Nicla found on /dev/ttyACM*. Check the micro-USB data cable and the hub's power, or pass --nicla.")
    return ports[0]


def main() -> None:
    parser = argparse.ArgumentParser(description="The UNO Q rig for Remote Assist.")
    parser.add_argument("--relay", default=os.environ.get("RELAY_URL") or RELAY_URL, help="e.g. ws://192.168.1.20:8080")
    parser.add_argument("--nicla", default=os.environ.get("NICLA_PORT"), help="serial port, or - for stdin")
    args = parser.parse_args()
    if not args.relay:
        sys.exit("Say where the relay is: --relay ws://<laptop address>:8080, or set RELAY_URL (in App Lab, in this file).")

    rig = Rig()
    # The relay's thread and the Nicla's thread both change the rig.
    lock = threading.Lock()

    def position() -> tuple[str | None, str | None]:
        step = rig.current_step()
        return (rig.guide or {}).get("id"), step and step["id"]

    def send(messages: list[dict]) -> None:
        for message in messages:
            show(TICK if message["ok"] else CROSS)
            try:
                app.send(json.dumps(message))
                print(f"sent: {message['stepId']} {'correct' if message['ok'] else message['detail']}", flush=True)
            except websocket.WebSocketConnectionClosedException:
                print("relay unreachable; the verdict is sent again on reconnect", flush=True)

    def on_open(_app: websocket.WebSocketApp) -> None:
        print(f"connected to {args.relay}", flush=True)
        app.send(json.dumps({"type": "hello", "protocol": 1, "role": "rig", "client": "UNO Q rig"}))
        with lock:
            rig.reconnected()

    def on_message(_app: websocket.WebSocketApp, raw: str) -> None:
        message = json.loads(raw)
        if message["type"] == "error":
            print(f"relay refused {message.get('about', 'a message')}: {message['message']}", flush=True)
            return
        with lock:
            before = position()
            verdicts = rig.on_relay(message)
            # A new step starts blank: the last step's tick shouldn't look like this step's.
            if position() != before:
                show(BLANK)
            send(verdicts)

    def on_close(_app: websocket.WebSocketApp, code: int | None, reason: str | None) -> None:
        print(f"lost the relay ({code} {reason or ''}); retrying", flush=True)

    app = websocket.WebSocketApp(args.relay, on_open=on_open, on_message=on_message, on_close=on_close)
    threading.Thread(target=app.run_forever, kwargs={"reconnect": 2}, daemon=True).start()

    def handle(line: str) -> None:
        seen = parse_seen(line.strip())
        if seen is None:
            return
        print(f"nicla sees the part in: {', '.join(sorted(seen)) or 'no region'}", flush=True)
        with lock:
            send(rig.on_seen(seen))

    lines = nicla_lines(args.nicla or find_nicla())
    if App is None:
        for line in lines:
            handle(line)
    else:
        show(BLANK)
        # App Lab owns the main loop; it calls this over and over, and each call reads one line (or times out).
        App.run(user_loop=lambda: handle(next(lines)))


if __name__ == "__main__":
    main()
