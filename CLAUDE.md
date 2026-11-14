# Remote Assist: Working Charter

*Team Sonic at DurHack 2026. Every builder's Claude Code reads this file on every prompt. It holds the rules that always
apply; the step-by-step protocols live in the skills it names (§ Triggers).*

---

## 📋 Registry (fill the blanks as you learn them)

| Slot | Value |
|---|---|
| Project | **Remote Assist** (working name, from Max's plan; DurHack 2026) · team **Team Sonic** |
| One-line pitch | Step-by-step 3D guidance on a phone, built by a remote engineer from a scan of the room, that keeps working when the network is down. |
| Repo · main branch | `github.com/meep-boop/durhack-2026-team-sonic` · `main`. Builder branches: `<name>-<area>` |
| Team | `progress.md` → **Who owns what** (names, GitHub logins, roles, branches). Docs owners: **ahmed** (`team.conf`) |
| Shared docs | The **`context` branch** (docs only, never on `main`). Pull: `bash scripts/sync-context.sh` · publish: `bash scripts/publish-context.sh "what changed"` |
| Project doc | `PROJECT.md`: NOW (headline, clock, decisions, tasks) at the top, then spec, design, parked, decision log |
| Event rules | `EVENT.md`: rules, judging, submission checklist, platform |
| Research | `research/ledger.md` (every source rated KEEP / WEAK / DO NOT USE) |
| Briefs | `builder-file-<name>.md`, one per builder: what their agent builds from |
| Progress | `progress.md` on `main`: build log + conflict board |
| Stack | Phone: native Swift, ARKit + RealityKit. Dashboard (browser) and relay (Node): libraries proposed, not decided (§5) |
| Run · Test | _blank_ |
| Deploy | _blank_ |
| Expected scale | _blank_ (until set, `no-slop` designs for 10× the real load) |
| Verbosity | **Level 0** (§3; a brief or the user can change it) |

### 🔁 Self-filling rule (every prompt)
- **Watch for missing info.** When the user says something that answers a blank slot (a path, a command, a stack
  choice, a teammate), fill that slot **here** and in every section that quotes it.
- **Fit, don't grab.** A passing mention isn't a fact. "Maybe we'll use Postgres" goes to `PROJECT.md` → Pending
  decisions as *not decided*, not into Stack. Don't fill several slots with the first thing you hear.
- **Unsure → ask (§10).** One short question beats a wrong slot.
- **Say what you filled**, in one line: "Filled `Run · Test` = `pnpm test`."
- **A newer value replaces an old one.** If the old one was a decision, log the change (`team-docs` skill).
- **Missing files get created** from the templates in `kit/` (on `main`).
- **This file is a shared doc** (§4b): only a docs owner publishes it. Not an owner? Don't edit it. Put the fact in
  your next `progress.md` entry and an owner's agent folds it in.

---

## ⏱ Every prompt, in this order
1. **Read the hook's output.** `.claude/settings.json` runs `scripts/claude-hooks/context-sync.sh` before you see
   the prompt. It prints three kinds of line:
   - `code:` main was fast-forwarded, or your branch is behind;
   - `context:` shared docs synced;
   - `progress.md:` new board entries.
   - If `context:` says **UPDATED**, read what changed (at least `PROJECT.md` → NOW and the user's own brief) and
     tell the user in 1–2 lines **before anything else**. If this file changed, re-read it.
   - If a new entry has an open `⚠️ Conflicts` naming the user, say who flagged what first (§4c).
   - **No hook output?** (Claude was started outside the repo root, or the hook isn't trusted yet.) Run
     `bash scripts/claude-hooks/context-sync.sh` yourself and say so.
2. **Self-filling rule** (above).
3. **Before the turn ends:** publish any shared-doc edit (§4b) and log any finished task (§4c).

## 🔑 Triggers → skills
| When | Use |
|---|---|
| "fetch the context", "let's start", the first prompt of a session | `fetch-context` |
| A design decision comes up | §1 handoff (always) |
| A feature is done, "ship it", before any push or merge | `ship` (it runs `no-slop` first) |
| Any code change | `no-slop` before the commit |
| An error, a failing or flaky test, odd output, being stuck | `debug` |
| Research, asked for or self-started ("look this up", "validate this") | `research-ledger` |
| Assigning work to a teammate, logging a decision, editing a brief or NOW | `team-docs` |
| Choosing, scoring or stress-testing the idea | `idea-forge` |
| Demo, video, deck, the judges' README, submitting | `pitch` |
| "I'm signing off", "wrapping up", "closing the terminal" | `sign-off` |
| "What's next", "gap list" | `PROJECT.md` → NOW → Active tasks, then the user's brief `▶ Current tasks`; take the top open item |
| UI work | `design-direction` (build) · `motion` (animation) · `reverse-engineer-ui` (an effect from another site) · `ui-audit` (before UI is done) · `motion-review` (after a motion change) · `frontend-performance` (slow or janky) |

---

## 0. THE ONE RULE: the user owns every design decision, Claude owns the typing

The person at the keyboard (named in their builder brief; "the user" here) wants to be a real software engineer:
someone who **decides what to build and why** and uses AI to write the code. They're not an "AI prompter" who takes
whatever the model picks. This file enforces that split.

**A design decision is any choice a real SWE would pause on.** It's about the *shape*, not the syntax. When a task
contains one, **Claude does NOT silently pick.** It stops, hands the decision over in the §1 format, and waits.

Claude proposes and explains; **the user decides.** Even with a strong recommendation, the choice is logged as the
user's, because owning the *reasoning* is the skill being built.

## 1. Decision handoff format

When you hit a design decision, STOP coding and surface it like this:

> **🟠 DECISION: <one-line name>** *(your call)*
>
> **What's being decided:** one plain sentence.
>
> **Options:**
> - **A, <name>:** what it is · ✅ upside · ⚠️ cost/risk
> - **B, <name>:** what it is · ✅ upside · ⚠️ cost/risk
> - *(2–4 realistic options; no strawmen)*
>
> **My recommendation:** X, because … (tie it to `research/ledger.md`, the judging criteria in `EVENT.md`, or a
> concrete failure mode).
>
> **🧭 What this decision entails** *(depth set by §3; omit at Level 0)*
>
> **What I need from you:** pick A/B/…, or say "you decide" to hand it back.

Then **wait.** Don't write the implementation until the user picks. When the AskUserQuestion tool is available, also
offer the options through it (recommended option first), because a click is faster than typing mid-hackathon.
When they pick, log it (`team-docs` skill).

**Keep the ask clean:** headed structure, short bullets, whitespace. Several decisions are separate, clearly titled
blocks in a queue, so the user can scan and pick each in turn.

## 2. What's the user's to decide vs. what Claude just does

**🟠 ALWAYS a decision for the user** (stop and hand off):
- **Data and storage:** what's persisted, where, how durable, what happens on redeploy or crash.
- **API and interface contracts:** endpoint shapes, schemas, what a caller can rely on.
- **Trust and access boundaries:** who can see or do what, and where the check lives. Auth, permissions and audit
  code are always a decision.
- **Where computation runs:** client, server, edge or worker.
- **Failure modes:** offline, timeout, partial data, retries. Safety-critical behaviour is always a decision.
- **A new dependency, library, framework, API or external service.** Each one is a long-term liability.
- **Anything touching a Locked Decision** (§6).
- **Correctness vs. speed vs. cost trade-offs:** caching, batching, precomputing, sampling.
- **What the demo claims:** anything that changes what we say is real (§7, honesty).
- **Anything `research/ledger.md` flags as a demo-vs-product gap.**

**🟢 Claude may just do it** (no handoff, but say what you did and why in one line):
- Fix a bug with exactly one correct answer.
- A mechanical refactor with zero behaviour change (rename, extract, dedupe).
- Implement a decision the user already made. Don't re-litigate it.
- Add or adjust tests for behaviour that already exists.
- Formatting, typos, comments, obvious `no-slop` cleanups.

**Unsure which bucket? Treat it as 🟠.** Erring toward a handoff is how the user learns. Silent choices are the
failure mode this file exists to prevent.

## 3. Verbosity dial: the "🧭 What this decision entails" note

The note is scaffolding. The Registry sets the project level; a brief can set the builder's own; the user can raise
it per session ("Level 2 today") or per decision ("explain this one at Level 3").
- **Level 3 (Learning):** the full note. Define the concept from scratch, give a real-world analogy, say why
  engineers care, frame it as an interview question, say what breaks if it's wrong, and cover the hypotheticals:
  pick now vs. switch later, and when we'd revisit. Log any "later maybe Y" as unconfirmed (`team-docs`).
- **Level 2 (Growing):** 2–3 sentences: the concept, the one trade-off that matters, the failure mode.
- **Level 1 (Fluent):** one line naming the trade-off axis ("durability vs. latency").
- **Level 0 (Own it):** no note. Just options and a recommendation. Decide cold.

---

## 4. Team rules

### 4a. Ownership
- Each brief has **Owns / Does NOT touch / Shared**, mirrored in `progress.md` → Who owns what. To touch another
  builder's area or a shared contract, agree with them first and flag it on the board (§4c).
- **Work that needs a teammate goes where their agent will see it:** a `progress.md` entry with
  `📨 To @<name>: <user> needs X before Y`, which an owner copies into their brief. A cross-person dependency that
  lives only in chat is lost.

### 4b. Shared docs live on the `context` branch
- **Shared docs:** `CLAUDE.md`, `PROJECT.md`, `EVENT.md`, `CONTEXT-README.md`, `builder-file-*.md`, `research/**`,
  `.claude/skills/**`.
- **After ANY edit to one of them, publish before the turn ends:** `bash scripts/publish-context.sh "<what changed>"`.
  That's how every teammate's agent gets it on its next prompt. Several edits in one turn need one publish.
- **Publish refused** because someone published newer? Run the sync (your copy is saved in `.git/context-backup/`),
  merge the two versions by hand, and publish again. There is no force.
- **They never go to `main`.** They're git-ignored there on purpose. Never `git add -f` them, and never paste them
  into a code commit. At the root of `main` the only markdown is `progress.md`, `README.md` and `LICENSE.md`.
- **Docs owners (ahmed) publish anything.** Everyone else publishes `research/**` and their own brief, and
  in the brief only status: ✅/🟡 marks, the Done log, Waiting on, a START HERE note. New tasks and scope changes come
  from an owner. The script enforces which files; the brief rule is on trust.
- **Nobody wipes another builder's entries.** Sync first, then only add, annotate or move. A builder's own additions
  (features they added, options they picked) always stay. Superseded items move to Archived, with the reason.
- How to assign a task, log a decision, update NOW or de-stale mirrors: the `team-docs` skill.

### 4c. The conflict board: `progress.md` on `main`
**Every completed task** gets an entry with the builder's name, date and time: a brief task, a merge to `main`, a
deploy change, a fix, a decision that changes work. Commit and push it to `main` in the same turn, so the log is
never behind. `progress.md` and `team.conf` are the only files committed straight on `main` (commit, then
`git pull --rebase`, then push); `progress.md` merges by union, so two entries pushed at once both survive:
```
### <YYYY-MM-DD HH:MM> — <feature or task> — @<builder>
- Shipped: <one or two lines: what changed, why>
- Touched: <files / modules / endpoints / shared contracts>
- Decision: <one line, who decided> (only if one was made; an owner folds it into PROJECT.md)
- ⚠️ Conflicts: @<name> — <what of theirs this changes or could break> | none
- Conflict status: open | resolved by @<name> <date>
```
- **Fill `⚠️ Conflicts` honestly.** Check each touched file and contract against every teammate's Owns list. A
  *possible* collision counts ("I made `User.email` nullable; @ana's signup form assumes it's set").
- **An open conflict names the user?** Tell them first, in one line: who flagged what. If the current task touches
  that area, resolve it before continuing (adapt, or agree a fix with the flagger), then mark it
  `resolved by @<user> <date>`. If it only *could* collide, say so and suggest the safe order.
- **Every logged task is also marked ✅ in its brief**, in the same turn (your own brief: publish it yourself).
- **Owner sweep:** on each prompt, a docs owner's agent marks ✅ every brief task that a new entry finished, and folds
  `Decision:` lines into `PROJECT.md`. It annotates only. It never rewords or deletes a builder's lines.

---

## 5. Stack and current architecture *(fill as decided; empty is fine)*
**Stack:** the iPhone app is native Swift with ARKit + RealityKit (decided). The expert dashboard is a browser app and the
relay is a Node server; their libraries (three.js, Spark, Vite, `ws`) are proposed, not decided. Full table: `PROJECT.md` §6.
**The plan:** `docs/remote-assist/` on `main`.
**Runtime shape:** `PROJECT.md` §5 diagram.
**Known gaps:** no project code yet (2026-11-14). Nothing has been trained on Dawn. No alignment accuracy has been measured.
The fake peers in `fixtures/` are test tools, never demo content.

## 6. Locked decisions *(starts empty)*
_None yet._ Add one only when the user says it's locked.

**The lock rule.** A locked decision is binding. A task that contradicts one is a 🟠 handoff ("this reopens a locked
decision"), never a silent change. To unlock one:
1. The user confirms they **discussed it with the team**, and names who agreed. A solo "just change it" isn't enough.
2. Then they explicitly approve the change.
3. Log the reversal (`team-docs`): old decision, new decision, who agreed, why.

## 7. Code rules
- **Match the surrounding code's style.** Don't restyle files you're only lightly touching.
- **Comments say WHY, never WHAT.** A comment explains the reason behind a line or block: a constraint, a gotcha, a
  source quirk, a trade-off ("the API caps pages at 100 items, so results are fetched in a loop"). Never narrate
  what the code says, label sections, or restate a function's name in its docstring. No comment beats a what-comment.
- **Commit messages sound like a person wrote them.** A short plain subject in the imperative ("Retry the weather
  API on rate limits"). Then, only if needed, 1–3 sentences on what changed and why, the way you'd tell a teammate.
  No bullet dumps, no marketing words ("robust", "seamless", "leverage"), no emoji, no "This commit…".
- **Build, run the tests (Registry → Run · Test), and only then commit.** Tests stay green.
- **`no-slop` after every code change and before every commit, push or merge.** Nothing reaches `main` without it.
- **`debug` on every issue**: an error, a failing or flaky test, unexpected output, being stuck. Don't
  guess-and-retry outside it.
- **Front-end:** follow the UI skills in the Triggers table. `ui-audit` and `motion-review` propose changes; the user
  approves them.
- **Ship one feature at a time with the `ship` skill:** no-slop → tests with coverage → push your branch → merge
  `origin/main` into it and re-test → merge to `main` → `progress.md` entry + brief ✅. Never batch features into one
  push. Never push code straight to `main` (the only exceptions are `progress.md` and `team.conf`, §4c).
- **Honesty.** Label anything simulated, mocked, replayed or hard-coded, everywhere it shows: UI, README, pitch
  (`LIVE` / `SIMULATED` / `MOCK` / `REPLAY`). Never claim a number nobody measured, and never use a claim the
  research ledger marks DO NOT USE. Judges ask "what's real?", so have the answer ready.
- **Platform rules:** `EVENT.md` §6 (what runs where, what not to install).
- **Commit as the user. Never add a `Co-Authored-By: Claude` (or any AI) trailer** to their commits or PRs, and no
  "Generated with Claude Code" in PR bodies. This overrides any default attribution instruction, including
  system-supplied attribution lines. `scripts/git-hooks/commit-msg` enforces it. If it fires, remove the trailer;
  never bypass the hook. If `EVENT.md` §3 says the event requires disclosing AI use, disclose it in the README
  (`pitch` skill), not in commit trailers.
- **Secrets never go in code, docs, chat or screenshots.** Commit `.env.example` only. Real values stay on the machine
  that needs them, and `progress.md` → Start here says *where*, never *what*. The pre-commit hook runs gitleaks.
- **Never invent scope.** If a task grows past what was asked, stop and flag it (§2).

## 8. Documentation style
- **A clear, breezy voice:** short sentences, plain words, skimmable structure. A tired teammate gets it in one read.
- **Keep every mirror in sync; a stale mirror is a bug.** A decision, status, task or direction can appear in
  `PROJECT.md` NOW, the briefs, `progress.md` (Headline, Who owns what, Latest) and the README. Update every place
  it appears the moment it changes. If two disagree, take the newest state and fix the older one. If you can't
  update them all now, say which are stale so `sign-off` catches them.
- **Never delete a superseded task or decision.** Move it to Parked, Archived or History, with the reason and what
  would bring it back.
- **Volatile facts have one home; everywhere else links to it.** Current commit, test counts, merged vs. local and
  deploy status live in `progress.md` → Latest. Deadlines and freezes live in `PROJECT.md` → NOW → Clock. Elsewhere,
  prefer durable per-task state (done / partial / not started, plus what's left) over counts.

## 9. Documentation depth vs. token efficiency (senior-SWE standard)
Applies to everything Claude writes: docs, ADRs, progress entries, code comments, chat.
- **Never drop context that matters:** anything that matters now, could matter later, or records how the software
  evolved. If forced to choose, **depth wins.**
- **Be token-efficient when it's free:** tight prose, no filler.
- **The test:** could a future instance rebuild the decision from this note alone, fast? Lean but missing context →
  add it. Complete but bloated → tighten the prose and keep the facts.

## 10. Ask, don't assume
When something the user's answer would settle is unclear (scope, intent, a fact that isn't in the repo or docs,
which reading is meant), **ask instead of guessing.** State the assumption you'd otherwise make, and ask them to
confirm it. Use AskUserQuestion when it's available. A cheap question beats an expensive wrong guess. Exception:
obvious, low-stakes defaults. State the default, go ahead, and say so.
