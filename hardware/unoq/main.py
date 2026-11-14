"""Runs on the UNO Q: reads which regions the Nicla Vision sees the stickered part in, follows the guide through the
relay as the `rig`, and reports `step.verified`.

    RELAY_URL=ws://<relay laptop>:8080 python main.py            # Nicla on the hub, found automatically
    python main.py --relay ws://... --nicla /dev/ttyACM0
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
    parser.add_argument("--relay", default=os.environ.get("RELAY_URL"), help="e.g. ws://192.168.1.20:8080")
    parser.add_argument("--nicla", default=os.environ.get("NICLA_PORT"), help="serial port, or - for stdin")
    args = parser.parse_args()
    if not args.relay:
        sys.exit("Say where the relay is: --relay ws://<laptop address>:8080 (or set RELAY_URL).")

    rig = Rig()
    # The relay's thread and the Nicla's thread both change the rig.
    lock = threading.Lock()

    def send(messages: list[dict]) -> None:
        for message in messages:
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
            send(rig.on_relay(message))

    def on_close(_app: websocket.WebSocketApp, code: int | None, reason: str | None) -> None:
        print(f"lost the relay ({code} {reason or ''}); retrying", flush=True)

    app = websocket.WebSocketApp(args.relay, on_open=on_open, on_message=on_message, on_close=on_close)
    threading.Thread(target=app.run_forever, kwargs={"reconnect": 2}, daemon=True).start()

    for line in nicla_lines(args.nicla or find_nicla()):
        seen = parse_seen(line.strip())
        if seen is None:
            continue
        print(f"nicla sees the part in: {', '.join(sorted(seen)) or 'no region'}", flush=True)
        with lock:
            send(rig.on_seen(seen))


if __name__ == "__main__":
    main()
