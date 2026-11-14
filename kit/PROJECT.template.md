# {{PROJECT}}: the project doc
*{{TEAM}} · {{EVENT}} · repo `{{REPO}}` · started {{DATE}}.*

**How to read this:** **NOW** is what's true and in progress today, so start there. **Part A** is the spec. **Part B**
is the design, one section per feature. **Parked** holds what was doable but not chosen. The **Decision log** says why
the system is shaped this way, and **History** says how we got here.
- Event rules and judging: `EVENT.md`. Evidence: `research/ledger.md`. Your tasks: `builder-file-<name>.md`.
- Live status and conflicts: `progress.md` on `main`.

*Italic lines are prompts. Replace them as you fill each section, and leave a section empty rather than invent it.*

---

## NOW (updated {{DATE}})

### Headline
*The one sentence we pitch, plus what we must never claim. Fill it once the idea is picked (`idea-forge`).*

**Never pitch:** _blank_

### Clock
*The single home for every deadline. Briefs and chat point here and never copy the times.*

| When | What |
|---|---|
| _blank_ | Hacking starts |
| _blank_ | Walking skeleton end to end (the first thing that must work) |
| _blank_ | Feature freeze: after it, only fixes, and no API shape changes |
| _blank_ | Demo recorded / deck done |
| _blank_ | **Submission deadline** (use the earliest time any source gives) |
| _blank_ | Judging / presentations |

### Decisions in force
*One line each, newest first: what, who decided, when. The full record is in the Decision log below.*

| Date | Decision |
|---|---|

### Pending decisions
*Open questions, each with an owner and what it's waiting on. Unconfirmed leanings go here too, marked **not decided**.*
- _none yet_

### Active tasks (details in each brief)
| Who | Now |
|---|---|

### Blockers only humans can clear
*Accounts, API keys, access, team registration, hardware, asking the organisers.*
- _none yet_

---

# Part A: Spec

## 0. One page
- **One-liner:** _blank_
- **The person it's for, and the harm or pain:** _a named persona and a sourced number_
- **What it does:** _3–5 bullets_
- **What's real in the demo vs. simulated:** _a list: be exact, because judges ask_
- **Novelty line:** _what exists today, and the one thing none of it does that we do_
- **Track / challenges entered:** _blank_

## 1. Problem and evidence
*Cite `research/ledger.md` by section. Only KEEP sources carry a load-bearing number.*

## 2. Goals, non-goals, success metrics
| Goal | Metric | Target | How we measure it |
|---|---|---|---|

**Non-goals:** _what we deliberately won't do this weekend_

## 3. Users, journeys and outputs
*Who uses it, the 2–3 journeys the demo shows, and what each output is: a decision, not just a label.*

## 4. Features
| # | Feature | Owner | Priority | Status |
|---|---|---|---|---|
| F1 | _blank_ | | P0 | ⬜ |

*P0 = the demo fails without it. P1 = it makes the demo better. Parked = doable, decided against (see Parked).*

## 5. Architecture
*A diagram (Mermaid or ASCII) of the runtime shape: inputs → processing → outputs, and where each part runs.*

## 6. Tech stack
| Layer | Choice | Why | Checked on the platform? |
|---|---|---|---|

## 7. Data
| Source | What | Licence | Where it lives | Real / simulated |
|---|---|---|---|---|

## 8. Security and privacy
*Secrets handling, personal data (ideally none), auth, what's public.*

## 9. Demo plan
*The beat sheet, to the second (the `pitch` skill has the skeleton). What's on screen at each beat, and who speaks.*

## 10. Team, timeline, cut order
- **Who owns what:** `progress.md` → Who owns what.
- **Timeline:** NOW → Clock.
- **Cut order (first to go → last):** _blank_
- **Never cut:** _blank_

## 11. Risks and judge questions
| Question a judge will ask | Our answer |
|---|---|
| What's actually real here? | |
| Why not just use <the obvious existing tool>? | |
| Does it work beyond the demo data? | |

---

# Part B: Design per feature

## How to use this
- **Building?** Read the summary table, then only your feature's section. Each section ends with a **Spec**: build
  from that.
- **🟠 marks an open team decision.** It has a recommendation, but nothing marked 🟠 is decided until the user picks.
- **Facts that shape everything:** _platform limits, verified versions, API quotas, each with its evidence._

## Summary: feature → choice → why
| # | Feature | Choice | One-line why |
|---|---|---|---|

## B1. _feature name_
**Options**
- **A.** _what · upside · cost_
- **B.** _what · upside · cost_

**Choice:** _the option, and who decided_

**Spec:** _the finished state, constraints, acceptance ("done when …")_

---

## Parked
*Doable, decided against. Each item says why, and what would bring it back.*

## Decision log
*Full records, newest first. NOW → Decisions in force holds the one-line versions.*
```
## <date> — <decision name>
- Chose: <option> (<who>)
- Because: <one line>
- Rejected: <alternatives + why not>
- Revisit if: <the condition that would change this>
```

## History
*How the idea and the plan changed, and why. Superseded plans move here, never deleted.*
