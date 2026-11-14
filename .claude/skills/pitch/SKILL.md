---
name: pitch
description: Use when preparing anything judges see (the demo video, a live demo, slides, the README for judges, the submission form, judge Q&A), and when the feature freeze or the submission deadline is close.
---

# Pitch

Judges score what they see in a few minutes. Plan the demo early, because it decides what's worth building, and
lock it before the freeze.

## Demo skeleton (scale it to the time limit; here, 3:00)
| Time | Beat |
|---|---|
| 0:00 | **Hook:** a named person and a sourced number |
| 0:15 | The problem, and the data or insight behind the answer |
| 0:35 | **Live demo**, building to the wow moment |
| 1:35 | How it works: a diagram, and the platform or sponsor tech doing real work on screen |
| 2:20 | Proof it's real, plus one honest limitation |
| 2:40 | Close: the impact, with the whole team visible |

Aim about 5% under the limit. If teamwork is judged, everyone speaks. Burn captions in if they're allowed. Record
against the real deployed app, and keep a recorded fallback for any live demo.

## Deck
Problem (person + stat) · Solution (one screenshot) · How it works (diagram) · Demo (a real screenshot, never an
empty slide) · Proof it's real · Tech, and why · Team (who did what) · Next steps.

## README for judges
Before submitting, replace `README.md` with a filled-in `kit/README.judges.template.md`. Every claim matches the video
and `PROJECT.md`. The "What's real" table is mandatory, and the "What went wrong, and what we changed" section earns
trust. If `EVENT.md` §3 requires disclosing AI use, fill the AI use section.

## Judge Q&A
Fill `PROJECT.md` §11 with the 8–10 hardest questions and a one-line answer each ("what's real?", "why not <existing
tool>?", "does it work beyond the demo data?", "what did each of you build?"). Rehearse them once out loud.

## Honesty pass (before recording)
- Every number is measured, with its source, and none comes from a DO NOT USE ledger entry.
- Everything simulated or mocked is labelled on screen.
- Nothing from `PROJECT.md` → NOW → "Never pitch" is said.
- No secrets in any frame, and never an address and a token in the same frame.

## Submission (the final hour)
1. Walk the `EVENT.md` §2 checklist item by item.
2. Run `bash scripts/submission-check.sh` until it reports no blockers.
3. If the repo goes public: after the last doc edit, delete the context branch. The script prints the command. Ask
   the user first, because it can't be undone.
4. Submit early, by the earliest deadline any source gives, and confirm every member is on the submission.

## Common mistakes
- Building features the demo never shows.
- A demo that needs live luck, with no recorded fallback.
- A README promising more than the video shows.
- Leaving the video to the last hour.
