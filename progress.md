# TBD: progress log and conflict board

**Every builder, every prompt:** the Claude hook shows the entries that are new since you last looked (by hand:
`git fetch && git diff HEAD..origin/main -- progress.md`). If an open `⚠️ Conflicts` line names you, tell your user,
then agree a fix with whoever flagged it before you touch that area.

**Every completed task** (a brief task, a merge to `main`, a deploy change, a fix) gets one entry, newest at the
bottom, pushed to `main` straight away:

```
### <YYYY-MM-DD HH:MM> — <feature or task> — @<builder>
- Shipped: <what changed, why>
- Touched: <files / modules / endpoints / shared contracts>
- Decision: <one line, who decided> (only if one was made)
- ⚠️ Conflicts: @<name> — <what of theirs this changes or could break> | none
- Conflict status: open | resolved by @<name> <date>
```

## Headline
_The one-line pitch, once it's picked (copied from `PROJECT.md` → NOW)._

## Start here (teammates, first 15 minutes)
1. **GitHub:** accept the collaborator invite for `github.com/meep-boop/durhack-2026-team-sonic`, then in **Git Bash** on Windows (plain `bash` in
   PowerShell can start WSL instead) or any terminal on Mac/Linux:
   ```bash
   git clone https://github.com/meep-boop/durhack-2026-team-sonic.git && cd durhack-2026-team-sonic
   git config user.email "<the email on YOUR GitHub account>"   # judges read who committed
   bash scripts/setup.sh <your key from team.conf>              # who you are, commit hooks, first docs sync
   ```
   Not in `team.conf` yet? Ask a docs owner (ahmed) to add your key and brief.
2. **Claude Code:** start it **in the repo root**, so the every-prompt hook in `.claude/settings.json` runs (trust the
   folder when it asks). Then say "fetch the context".
3. **Optional, but it's what we use:** `gitleaks` (secret scan on every commit), plus the Claude Code plugins listed
   in `README.md`.
4. **Things that live only on one machine** (read them there; never paste them in chat or commit them):

   | What | Where |
   |---|---|
   | _e.g. API keys_ | _e.g. `secrets/` on the server, or a password manager_ |

## Who owns what
Ask the owner before changing their area, and flag them in `⚠️ Conflicts` if you touch it. Full task lists are in
each builder's brief (`builder-file-<name>.md`, on the `context` branch).

| Who | Role | Branch | Owns (paths / pieces) | How the rest plugs into it |
|---|---|---|---|---|
| **Ahmed** `meep-boop` | Docs owner; build role TBD at kickoff | `ahmed-<area>` | The team kit (`scripts/`, `kit/`, `team.conf`), the shared docs on `context` | Add teammates: their key in `team.conf`, a brief, a row here |
| **Max** `xaw1` | TBD at kickoff | `max-<area>` | TBD | Setup: `bash scripts/setup.sh max` |
| **Laura** `furtunalaura` | TBD at kickoff | `laura-<area>` | TBD | Setup: `bash scripts/setup.sh laura` |
| **Salman** `salman-abdulrazaq-ali` | TBD at kickoff | `salman-<area>` | TBD | Setup: `bash scripts/setup.sh salman` |

**Shared** (anyone may edit; flag it): `contracts/*`, `fixtures/*`

## How we work (read once)
- **Code from your own laptop, as yourself.** One branch each (`<name>-<area>`). Per feature: code and test → push
  your branch → `git merge origin/main` into it and re-test → merge to `main` → an entry here. Your Claude runs this
  as the `ship` skill.
- **Shared docs** (`CLAUDE.md`, `PROJECT.md`, `EVENT.md`, briefs, research, skills) are **never** committed to
  `main`. They live on the `context` branch. Edit, then `bash scripts/publish-context.sh "what changed"`,
  and every agent picks it up on its next prompt.
- **Deploy:** _blank_ (where it runs, who restarts it, how).

## Latest
- **The volatile facts live here only:** the current commit, test counts, what's merged vs. local-only, and deploy
  status.
- **As of 2026-11-14 18:45:** `main` has the team kit, and the `context` branch is seeded. Kit tests are
  green locally (`test-context-scripts.sh`, `test-git-hooks.sh`). No project code yet. All four of us have repo access.

---

### 2026-11-14 17:05 — team kit + repo scaffold — @ahmed
- Shipped: the Claude Code team flow from the IBM Z Datathon, generalised for any project. Setup, sync, publish and
  init scripts; commit hooks; the every-prompt Claude hook; the charter, project doc, event doc, brief and research
  templates; 16 skills. The `context` branch is seeded from `kit/`.
- Touched: everything (new repo)
- ⚠️ Conflicts: none
- Conflict status: resolved by @ahmed 2026-11-14

### 2026-11-14 18:40 — Max, Laura and Salman added — @ahmed
- Shipped: keys `max`, `laura`, `salman` in `team.conf`; a brief for each on `context` (roles set at kickoff); rows in Who owns what. GitHub invites still to send.
- Touched: `team.conf`, `progress.md`, `builder-file-{max,laura,salman}.md` on `context`
- ⚠️ Conflicts: @max @laura @salman — once invited: clone, then `bash scripts/setup.sh <your key>` (Start here, step 1)
- Conflict status: open

### 2026-11-14 18:45 — teammates on GitHub — @ahmed
- Shipped: Max (`xaw1`), Laura (`furtunalaura`) and Salman (`salman-abdulrazaq-ali`) accepted their invites, with write access. Salman's login is in his brief and in Who owns what.
- Touched: `progress.md`, `builder-file-salman.md` on `context`
- ⚠️ Conflicts: @max @laura @salman — clone, then `bash scripts/setup.sh <your key>` (Start here, step 1)
- Conflict status: open

### 2026-11-14 19:00 — Remote Assist plan docs — @max
- Shipped: `docs/remote-assist/` with the idea (demo, pitch, challenge fit) and the planned architecture (components, calibration, message protocol). Plan only, no code; everything marked proposed is open for kickoff.
- Touched: `docs/remote-assist/README.md`, `docs/remote-assist/architecture.md`
- ⚠️ Conflicts: none
- Conflict status: resolved by @max 2026-11-14

### 2026-11-14 19:40 — Remote Assist plan: round-1 decisions — @max
- Shipped: `docs/remote-assist/` rewritten for the MSP setting (on-site user with an iPhone, remote MSP engineer on a dashboard) and stepped 3D animated guides. Quest and ISS framing moved to Parked.
- Touched: `docs/remote-assist/README.md`, `docs/remote-assist/architecture.md`
- Decision: iPhone native app, no Quest; expert builds the guide, live or ahead; built-in models plus cut-outs from the scan; preset animations; user taps Next; boxes stay alongside models. Decided by @max, needs team agreement at kickoff.
- 📨 To @ahmed: please add to PROJECT.md → Active tasks: "Pick and get the demo objects (unassigned)" and "Check we have a Mac with Xcode for the iPhone app".
- ⚠️ Conflicts: none
- Conflict status: resolved by @max 2026-11-14

### 2026-11-14 20:30 — Remote Assist plan: round 2 and research — @max
- Shipped: `docs/remote-assist/open-questions.md` for the hard problems (lining up the scan with the room, splat cut-outs on the iPhone, live camera). Researched the last two: iOS 27 RealityKit can draw splats natively; JPEG frames over the relay is the cheapest live video. Research is in `research/ledger.md` § 1–2 on `context`. On branch `max-docs`, by pull request.
- Touched: `docs/remote-assist/README.md`, `docs/remote-assist/architecture.md`, `docs/remote-assist/open-questions.md`, `research/ledger.md` (context)
- Decision: @salman's MacBook builds the iPhone app; prepared guides come before live guide-building. Decided by @max.
- 📨 To @salman: @max needs your MacBook ready for iPhone builds before the phone app starts: Xcode 27, Apple ID signed in, the demo iPhone on iOS 27.2+ running a test app.
- ⚠️ Conflicts: @salman — plan assumes your MacBook for every iPhone build
- Conflict status: open

### 2026-11-14 21:15 — Remote Assist plan: unknowns researched, working defaults set — @max
- Shipped: researched alignment (printed marker + ARKit poses recorded during the scan) and the scan pipeline (Scaniverse first, Dawn as stretch; cut-outs via Spark's CPU API, exported as PLY for RealityKit). Set working defaults for open questions 1–4; added open question 4. Ledger § 3–4 on `context`. Via PR on `max-docs`.
- Touched: `docs/remote-assist/open-questions.md`, `docs/remote-assist/README.md`, `docs/remote-assist/architecture.md`, `research/ledger.md` (context)
- Decision: working defaults (not confirmed by the team): marker + ARKit poses for alignment; RealityKit splats with a stand-in fallback; JPEG over the relay, LiveKit later; Scaniverse first. @max asked for defaults over more questions.
- 📨 To @ahmed: please add "Ask the organisers whether DurHack teams can get Dawn access" to PROJECT.md → Active tasks.
- ⚠️ Conflicts: none
- Conflict status: resolved by @max 2026-11-14
