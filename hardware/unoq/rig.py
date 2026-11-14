"""The UNO Q's decision: given the guide's current step and the ports the Nicla Vision sees the coloured cable in,
is the step done right, done wrong, or not done yet? No I/O here, so it runs and tests anywhere."""

from __future__ import annotations

Verdict = tuple[bool, str | None]


def parse_ports(line: str) -> set[str] | None:
    """The Nicla prints `ports=14,17`, or `ports=` when it sees the cable in no port."""
    if not line.startswith("ports="):
        return None
    return {port for port in line[len("ports="):].split(",") if port}


def judge(expects: list[dict], ports: set[str]) -> Verdict | None:
    wanted_in = {e["port"] for e in expects if e["cable"] == "in"}
    wanted_out = {e["port"] for e in expects if e["cable"] == "out"}
    if wanted_in <= ports and not wanted_out & ports:
        return True, None
    stray = ports - wanted_in
    missing = wanted_in - ports
    # Only a cable sitting in the wrong port is "wrong". A cable not plugged in yet, or not pulled out yet, just
    # means the user hasn't done the step, and warning then would flash ✗ at the start of every step.
    if stray and missing:
        return False, f"cable in port {', '.join(sorted(stray))}, expected {', '.join(sorted(missing))}"
    return None


class Rig:
    def __init__(self) -> None:
        self.guide: dict | None = None
        self.step_index = 0
        self.ports: set[str] | None = None
        self.sent: dict[str, Verdict] = {}

    def current_step(self) -> dict | None:
        if self.guide is None or self.step_index >= len(self.guide["steps"]):
            return None
        return self.guide["steps"][self.step_index]

    def reconnected(self) -> None:
        # The relay never kept verdicts sent while it was unreachable, so judge everything afresh.
        self.sent = {}

    def on_relay(self, message: dict) -> list[dict]:
        kind = message["type"]
        if kind == "guide.set":
            guide = message["guide"]
            if self.guide is None or self.guide["id"] != guide["id"]:
                self.step_index = 0
                self.sent = {}
            self.guide = guide
            self.step_index = min(self.step_index, len(guide["steps"]))
        elif kind in ("step.set", "step.done") and self.guide and message["guideId"] == self.guide["id"]:
            ids = [step["id"] for step in self.guide["steps"]]
            if message["stepId"] not in ids:
                return []
            index = ids.index(message["stepId"])
            if kind == "step.set":
                self.step_index = index
            elif index == self.step_index:
                # The relay replays every past step.done on connect; only Next on the current step moves the rig on.
                self.step_index += 1
        else:
            return []
        return self.check()

    def on_ports(self, ports: set[str]) -> list[dict]:
        self.ports = ports
        return self.check()

    def check(self) -> list[dict]:
        step = self.current_step()
        if step is None or self.ports is None:
            return []
        expects = [obj["expect"] for obj in step["objects"] if "expect" in obj]
        verdict = judge(expects, self.ports) if expects else None
        if verdict is None or self.sent.get(step["id"]) == verdict:
            return []
        self.sent[step["id"]] = verdict
        ok, detail = verdict
        message = {"type": "step.verified", "guideId": self.guide["id"], "stepId": step["id"], "ok": ok}
        if detail:
            message["detail"] = detail
        return [message]
