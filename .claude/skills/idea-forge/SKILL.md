---
name: idea-forge
description: Use when a team is choosing what to build at a hackathon, datathon or competition, comparing candidate ideas, deciding on a pivot, or when the user asks "what should we build", "score these ideas", "is this idea any good", or "red-team this".
---

# Idea forge

Pick the idea the judges will score highest **and** the team can actually build in the time. Judge it harshly
before anyone writes code.

## Inputs (get these first)
- `EVENT.md` §1, §3 and §4: tracks and challenges, rules, the judging criteria and their weights. Missing? Ask the
  user to paste them. Never invent a rubric.
- The team: who, their skills, and the hours left (`PROJECT.md` → NOW → Clock).
- The platform and sponsor tech, with its constraints (`EVENT.md` §6).

## Steps
1. **What wins here.** Do a `research-ledger` pass on past winners of this event or similar ones: what they built,
   what scored, what judges said. Take the patterns, never the ideas (original work only). Save to the ledger and
   to `EVENT.md` §5.
2. **Generate 8–15 varied candidates.** Each one gets: a one-liner, the person and their harm, the output (a decision
   or action, not a label), the one unusual ingredient, and what would be real vs. simulated in the demo.
3. **Two harsh judges** score every candidate on the event's own criteria and weights, independently (separate
   subagents when available). Then reconcile the two.
4. **Two red-team teardowns** of the top 3–5: why it loses, who already built it, what breaks in the demo.
5. **Feasibility check** of the top 3: does every part exist and run on our platform in our time? Check the
   packages, APIs, quotas and keys live. One unverifiable dependency on the critical path demotes the idea.
6. **Anti-wrapper test** for anything with an LLM in it. All six must hold:
   1. delete the LLM and the core still works;
   2. the value is our data, model or design;
   3. it beats "just ask ChatGPT";
   4. it can't be rebuilt in an afternoon;
   5. the LLM's job is small and checked;
   6. the sponsor or platform tech does real work.
7. **Rank and hand over** as a 🟠 decision (CLAUDE.md §1): the score table and a recommendation. The team picks.

## Score table
| Idea | <criterion> (weight) | <criterion> (weight) | … | Weighted /max | Buildable in time? | Red-team killer |
|---|---|---|---|---|---|---|

## Winning formula (check the chosen idea against it)
- [ ] A named person and a sourced harm in the first 15 seconds.
- [ ] The output is a decision or an action, not a dashboard.
- [ ] One unusual ingredient that nobody else will have.
- [ ] An honest baseline to beat.
- [ ] One "wow" visual moment.
- [ ] The platform or sponsor tech visibly doing real work.
- [ ] A closed loop if possible: it acts, sees the outcome, and grades itself.
- [ ] A repo that matches the video.

## After the pick
- `PROJECT.md`: the Headline, "Never pitch", §0 One page, cut order and never-cut list. `EVENT.md` §7: the
  candidates, their scores, and why the winner won. Rejected ideas go to History, not the bin.
- Publish, and add a `progress.md` entry.

## Common mistakes
- Scoring against generic "innovation" instead of this event's rubric.
- Picking the coolest tech over the clearest harm.
- Skipping the feasibility check, then finding out at hour 10 that the key API needs approval.
- Treating a "maybe later" tail as agreed scope.
