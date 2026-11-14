import json
import pathlib
import unittest

from rig import Rig, judge, parse_ports

SAMPLE = json.loads((pathlib.Path(__file__).parents[2] / "fixtures" / "sample-guide.json").read_text(encoding="utf-8"))
GUIDE_ID = SAMPLE["id"]


def rig_on(step_id: str) -> Rig:
    rig = Rig()
    rig.on_relay({"type": "guide.set", "guide": SAMPLE})
    rig.on_relay({"type": "step.set", "guideId": GUIDE_ID, "stepId": step_id})
    return rig


def verdicts(messages: list[dict]) -> list[tuple]:
    return [(m["stepId"], m["ok"], m.get("detail")) for m in messages]


class ParsePorts(unittest.TestCase):
    def test_reads_the_nicla_line(self):
        self.assertEqual(parse_ports("ports=14,17"), {"14", "17"})
        self.assertEqual(parse_ports("ports="), set())

    def test_ignores_anything_else_the_nicla_prints(self):
        self.assertIsNone(parse_ports("OpenMV v4 booting"))


class Judge(unittest.TestCase):
    def test_right_port(self):
        self.assertEqual(judge([{"port": "17", "cable": "in"}], {"17"}), (True, None))

    def test_wrong_port_names_both(self):
        self.assertEqual(judge([{"port": "17", "cable": "in"}], {"16"}), (False, "cable in port 16, expected 17"))

    def test_not_plugged_in_yet_is_not_wrong(self):
        self.assertIsNone(judge([{"port": "17", "cable": "in"}], set()))

    def test_pulling_out(self):
        self.assertIsNone(judge([{"port": "14", "cable": "out"}], {"14"}))
        self.assertEqual(judge([{"port": "14", "cable": "out"}], set()), (True, None))


class RigFollowsTheGuide(unittest.TestCase):
    def test_nothing_to_say_before_the_nicla_reports_or_on_unchecked_steps(self):
        self.assertEqual(rig_on("s4").check(), [])
        self.assertEqual(rig_on("s1").on_ports({"16"}), [])

    def test_wrong_then_right_is_reported_once_each(self):
        rig = rig_on("s4")
        self.assertEqual(rig.on_ports(set()), [])
        self.assertEqual(verdicts(rig.on_ports({"16"})), [("s4", False, "cable in port 16, expected 17")])
        self.assertEqual(rig.on_ports({"16"}), [])
        self.assertEqual(verdicts(rig.on_ports({"17"})), [("s4", True, None)])
        self.assertEqual(rig.on_ports({"17"}), [])

    def test_next_moves_on_and_judges_the_new_step(self):
        rig = rig_on("s3")
        rig.on_ports({"14"})
        self.assertEqual(verdicts(rig.on_ports(set())), [("s3", True, None)])
        rig.on_relay({"type": "step.done", "guideId": GUIDE_ID, "stepId": "s3"})
        self.assertEqual(rig.current_step()["id"], "s4")
        self.assertEqual(verdicts(rig.on_ports({"17"})), [("s4", True, None)])

    def test_replayed_step_done_for_earlier_steps_does_not_move_the_rig(self):
        rig = rig_on("s3")
        rig.on_relay({"type": "step.done", "guideId": GUIDE_ID, "stepId": "s1"})
        self.assertEqual(rig.current_step()["id"], "s3")

    def test_messages_for_another_guide_are_ignored(self):
        rig = rig_on("s4")
        rig.on_relay({"type": "step.set", "guideId": "another-guide", "stepId": "s1"})
        self.assertEqual(rig.current_step()["id"], "s4")

    def test_an_edit_keeps_the_step_but_a_new_guide_starts_over(self):
        rig = rig_on("s4")
        rig.on_relay({"type": "guide.set", "guide": {**SAMPLE, "rev": 2}})
        self.assertEqual(rig.current_step()["id"], "s4")
        rig.on_relay({"type": "guide.set", "guide": {**SAMPLE, "id": "another-guide"}})
        self.assertEqual(rig.current_step()["id"], "s1")

    def test_after_a_reconnect_the_current_verdict_is_sent_again(self):
        rig = rig_on("s4")
        rig.on_ports({"17"})
        rig.reconnected()
        self.assertEqual(verdicts(rig.check()), [("s4", True, None)])


if __name__ == "__main__":
    unittest.main()
