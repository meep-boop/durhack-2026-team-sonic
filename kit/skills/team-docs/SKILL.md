---
name: team-docs
description: Use when editing a shared doc (CLAUDE.md, PROJECT.md, EVENT.md, a builder brief, the research ledger, a skill), when the user assigns work to a teammate, mentions a decision (made, leaning, or "maybe later"), changes ownership or scope, or when two docs disagree.
---

# Team docs

The shared docs are how every agent on the team stays on one plan. Edit them like code: sync first, change only what's yours,
publish straight away.

## Who publishes what
| Doc | Who |
|---|---|
| `CLAUDE.md`, `PROJECT.md`, `EVENT.md`, skills, anyone else's brief | Docs owners (`team.conf` → `DOCS_OWNERS`) |
| `research/**` | Anyone (`research-ledger` skill) |
| Your own brief | You, for status only: ✅/🟡 marks, the Done log, Waiting on, a START HERE note |

Not an owner and need another change? Add a `progress.md` entry with `📨 To @<owner>: please …`, or a `Decision:` line.
An owner's agent folds it in.

## Every edit
1. **Sync first.** The hook said "up to date", or you ran `bash scripts/sync-context.sh`.
2. **Add, annotate or move.** Never reword or delete another builder's lines. Superseded items move to Archived, with
   the reason.
3. **Update every mirror** (below).
4. **Publish before the turn ends:** `bash scripts/publish-context.sh "<what changed, in plain words>"`. If it's
   refused, sync, re-apply your edit on top, and publish again.

## Assigning a task to a teammate (owners)
1. In their brief, add the task to a dated `▶ Current tasks` block at the **top**: ⬜, a Done-when, and
   `[⚠ conflicts with @x: what]` tags. Move what it supersedes below `── Archived (superseded <date> — do NOT
   action) ──`.
2. If ownership or scope changed, update `progress.md` → Who owns what and `PROJECT.md` → NOW → Active tasks.
3. When the task touches the seam between two builders, give both briefs the same interface note.
4. Publish, then add a `progress.md` entry with `⚠️ Conflicts: @<them> — new task in your brief`.

## Logging a decision
- **Decided:** a `PROJECT.md` → Decision log entry (its ADR format) plus one line in NOW → Decisions in force (date,
  decision, who).
- **Leaning, or "maybe later":** NOW → Pending decisions, marked **not decided**, with what would settle it. A
  parked idea is never treated as agreed.
- **Attribute by person.** Use the named owner. If it's unclear, write "(owner: TBC)". Never invent one.
- **Locked:** goes in CLAUDE.md §6 only when the user says to lock it.

## Mirrors (a stale mirror is a bug)
A fact can appear in `PROJECT.md` NOW, the briefs, `progress.md` (Headline, Who owns what, Latest), the README and
the CLAUDE.md Registry. When it changes, update every one. If two disagree, the newest wins: fix the older one. Can't
do them all now? Name the stale ones in your reply.

## Owner sweep (docs owners, every prompt)
For each new `progress.md` entry:
- mark the brief task it finished ✅, with the time;
- fold its `Decision:` line into `PROJECT.md`;
- copy its `📨` requests into the right brief.

Annotate only, then publish once.

## Common mistakes
- Editing from a stale copy, which gets the publish refused or loses the edit.
- Committing a shared doc to `main` (`git add -f`).
- Writing deadlines into briefs. They live only in NOW → Clock.
- Deleting a superseded task instead of archiving it.
