"""The UNO Q's decision: given the guide's current step and the regions the Nicla Vision sees the stickered part in,
is the step done right, done wrong, or not done yet? No I/O here, so it runs and tests anywhere."""

from __future__ import annotations

Verdict = tuple[bool, str | None]


def parse_seen(line: str) -> set[str] | None:
    """The Nicla prints `seen=ssd-bay`, or `seen=` when the sticker is in none of its regions."""
    if not line.startswith("seen="):
        return None
    return {region for region in line[len("seen="):].split(",") if region}


def judge(expects: list[dict], seen: set[str]) -> Verdict | None:
    wanted = {e["region"] for e in expects if e["present"]}
    unwanted = {e["region"] for e in expects if not e["present"]}
    if wanted <= seen and not unwanted & seen:
        return True, None
    stray = seen - wanted
    missing = wanted - seen
    # Only the part sitting in a region it shouldn't be in is "wrong". A part not put in yet, or not taken out yet,
    # just means the user hasn't done the step, and warning then would flash ✗ at the start of every step.
    if stray and missing:
        return False, f"seen in {', '.join(sorted(stray))}, expected in {', '.join(sorted(missing))}"
    return None


class Rig:
    def __init__(self) -> None:
        self.guide: dict | None = None
        self.step_index = 0
        self.seen: set[str] | None = None
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

    def on_seen(self, seen: set[str]) -> list[dict]:
        self.seen = seen
        return self.check()

    def check(self) -> list[dict]:
        step = self.current_step()
        if step is None or self.seen is None:
            return []
        expects = [obj["expect"] for obj in step["objects"] if "expect" in obj]
        verdict = judge(expects, self.seen) if expects else None
        if verdict is None or self.sent.get(step["id"]) == verdict:
            return []
        self.sent[step["id"]] = verdict
        ok, detail = verdict
        message = {"type": "step.verified", "guideId": self.guide["id"], "stepId": step["id"], "ok": ok}
        if detail:
            message["detail"] = detail
        return [message]
