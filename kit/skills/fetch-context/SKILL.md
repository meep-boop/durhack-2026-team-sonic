---
name: fetch-context
description: Use at the start of every session, and when the user says "fetch the context", "let's start", "where are we", "catch me up", or names the project as a starting point, before touching any code.
---

# Fetch the context

Read first, code second. Assemble one clear starting point from the shared docs, then propose the next step.

## Steps
1. **Who's at the keyboard?** If the user hasn't said, ask (AskUserQuestion, with the keys from `team.conf` →
   `BUILDERS`). If `git config team.builder` doesn't match, run `bash scripts/setup.sh <key>`.
2. **Sync.** Use this prompt's hook output. If there isn't any, run `bash scripts/claude-hooks/context-sync.sh`.
3. **Their brief** (`builder-file-<name>.md`): read **only** `▶ Current tasks`, Ownership, and Contract and
   guardrails. Never action anything below the Archived divider.
4. **Project state** (`PROJECT.md` → NOW): Headline, Clock, Decisions in force, Pending, Active tasks, Blockers.
5. **Local vs. repo:** `git status --short --branch`, `git log --oneline HEAD..origin/main`, `git log --oneline
   origin/main..HEAD`, `git stash list`. Note what's shipped vs. local only.
6. **Conflict board:** open `⚠️ Conflicts` naming the user (from the hook output, or search `progress.md` for
   `@<name>` with `Conflict status: open`).
7. **Blocking blanks:** empty CLAUDE.md Registry slots the next task needs (Run · Test, Stack, Deploy), an empty
   Clock, an empty `EVENT.md` §1–§4.

## Report (one screen, this shape)
```
**You:** <name> on <branch> · <n> ahead / <m> behind main · <clean | n uncommitted files>
**Clock:** <next deadline and the time left> | no deadlines in PROJECT.md yet
**Changed since last time:** <1–3 lines from the hook: context and progress.md>
**Conflicts for you:** <who flagged what> | none
**Your next task:** <the top ▶ Current task, with its Done-when>
**Waiting on:** <📥 items> | nothing
**Decisions to confirm:** <Pending / not-decided items in PROJECT.md, by name> | none
```
Then propose starting that task, or ask which one.

## Kickoff (the first session of an event, a docs owner at the keyboard)
When `EVENT.md` and `PROJECT.md` are still mostly blank:
1. Ask the user to paste the event's rules, schedule and judging criteria. Fill `EVENT.md` and NOW → Clock.
2. Ask for the team: keys, GitHub logins, roles. Add each key to `team.conf` `BUILDERS` (commit it on `main`,
   `git pull --rebase`, push), fill
   `progress.md` → Who owns what, and write each missing brief from `kit/brief.template.md` (replace `{{NAME}}` and
   `{{DATE}}`).
3. If the idea isn't picked yet, run `idea-forge`.
4. Publish the docs and push `progress.md`.

## Common mistakes
- Reading the whole brief, Archived section included, and then actioning a superseded task.
- Starting to code before giving the report.
- Guessing the deadline. If the Clock is empty, ask.
