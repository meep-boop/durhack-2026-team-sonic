---
name: sign-off
description: Use when the user says "I'm signing off", "I have to go", "wrapping up", "closing the terminal", "going to sleep", "taking a break" or "handing over", or a session is about to end with work in progress.
---

# Sign-off

Leave the next session, yours or a teammate's, a clean and exact starting point. Nothing important stays only in
this chat.

## Steps
1. **Save the work.** Commit and push finished work on the user's branch. For uncommitted work in progress, tell the
   user and offer a WIP commit on their branch, never on `main`. If access is blocked, ask once.
2. **Save what was learned.** Decisions go through `team-docs`, findings through `research-ledger`, gotchas into the
   brief's Reference section or a `progress.md` entry, and personal notes into your memory if the harness has one.
   Depth beats brevity here: never drop a detail that matters to save tokens.
3. **De-stale every mirror this session touched.** That means `PROJECT.md` NOW (Active tasks, Decisions, Pending,
   Blockers), the brief (task status, Done log, Waiting on), and `progress.md` (an entry per finished task, plus the
   Latest block if a volatile fact changed). Open each one by name, because status tables buried deep in a doc drift
   silently. Superseded items go to Archived, never deleted. Not a docs owner? Update only your own brief, and send
   the rest as a `📨 To @<owner>` line in `progress.md`.
4. **Leave a START HERE note with the exact next step.** Half-done: name the task, the file and the spot ("didn't
   finish `parse_feed()` in `ingest/feeds.py`: the retry branch"). All done: point at the next-highest task. Put it
   at the top of the brief's `▶ Current tasks` as a 🟡 note.
5. **Publish** the doc edits and push `progress.md`.
6. **List what dies with this session:** dev servers, background loops, tunnels, watchers. Give the command that
   restarts each one.
7. **Confirm** in a few lines: what was saved, where, and the START HERE.
