---
name: ship
description: Use when a feature or fix is finished and about to be committed, pushed, merged to main or deployed, and when the user says "ship it", "push this", "merge it", "it's done", or "we're done with X".
---

# Ship one feature

Every finished feature goes out the same way, one at a time. At a hackathon a broken `main` stops the whole team, so
nothing skips a step.

## The sequence (in order, every time)
1. **`no-slop`** on the finished feature, before any testing.
2. **Tests with real coverage.** Write or extend tests for the happy path, edge cases and failure paths. Run the
   Registry's Run · Test command with coverage. Changed code is well covered. Never push untested or failing code.
   No test setup in the project yet? Picking a framework adds a dependency, so it's a 🟠 decision: propose the
   lightest option.
3. **Commit as the user**, with a human message and no AI trailer (CLAUDE.md §7). Stage named files, not `git add -A`,
   and check `git status` for secrets and large files first.
4. **Push your own branch** (`<name>-<area>`). Never push straight to `main`.
5. **Conflict check:** `git fetch`, then `git merge origin/main` into your branch, then re-run the tests. A conflict
   in your code: fix it on your branch. In a teammate's code: agree the fix with them (a `progress.md` ping) first.
6. **Merge to `main`:** `git checkout main && git merge --ff-only origin/main && git merge --ff-only <branch> && git
   push origin main`. If the fast-forward fails, someone pushed in between: go back to step 5.
7. **Log it in the same turn:** you're on `main` after step 6, so add the `progress.md` entry (CLAUDE.md §4c) there,
   with honest `⚠️ Conflicts` checked against every teammate's Owns list. Commit, `git pull --rebase`, push. Then
   mark the task ✅ in your brief's Done log, publish it, and `git checkout <branch>` to carry on.
8. **Deploy** if the Registry has a Deploy step and the user wants it live. Warn the team first if the restart
   touches something they're using.

## Checks before the push
- `git diff --stat origin/main...HEAD` shows only this feature.
- No secrets, debug prints, commented-out code, or TODOs without a ticket.
- A changed contract (API shape, schema, event format) is a 🟠 decision, plus a `⚠️ Conflicts` line for each consumer.
- Anything simulated or mocked is labelled (CLAUDE.md §7, honesty).

## Near the deadline
After the feature freeze (`PROJECT.md` → NOW → Clock), only fixes ship. API shapes stay frozen: add endpoints, never
change existing ones. If there isn't time to finish the tests, tell the user plainly and let them decide. Never skip
step 2 silently.

## Report
```
ship: <feature> · <branch> → main <short sha>
no-slop: <n fixes> · tests: <passed>/<total>, coverage <x%> on changed files
conflicts flagged: <@name: what> | none · progress.md: pushed · brief: ✅ published
```
