# Remote Assist: progress log and conflict board

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
**Remote Assist.** Step-by-step 3D guidance on a phone, built by a remote engineer from a scan of the room, that keeps working when the network is down. The plan: `docs/remote-assist/`.

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
| **Ahmed** `meep-boop` | Docs owner; relay, protocol, sync, UNO Q rig | `ahmed-relay` | `relay/`, `contracts/`, `fixtures/`, `hardware/` (the UNO Q rig), the labelling endpoint; the team kit (`scripts/`, `kit/`, `team.conf`) and the shared docs on `context` | Build against `contracts/protocol.ts` and the fake peers in `fixtures/`. Ask Ahmed for protocol changes |
| **Max** `xaw1` | Dashboard 3D view and the splats | `max-scene` | `dashboard/src/scene/`, the `dashboard/` shell, `splats/`, `pipeline/`, `docs/remote-assist/` | The guide builder calls `dashboard/src/scene/api.ts` |
| **Laura** `furtunalaura` | Guide builder, models, demo set, pitch | `laura-guide` | `dashboard/src/guide/`, `assets/` (marker and models), the demo set, the README and video | Both apps load `assets/models/`; don't rename or resize a model without flagging |
| **Salman** `salman-abdulrazaq-ali` | The iPhone app | `salman-ios` | `ios/` | Speaks `contracts/protocol.ts` to the relay; loads the marker and USDZ models from `assets/` |

**Shared** (flag every edit): `contracts/*` and `fixtures/*` (Ahmed writes them, everyone builds on them), `dashboard/src/scene/api.ts`
(the seam between Max and Laura), `assets/models/` (loaded by both apps).

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

### 2026-11-14 20:20 — plan agreed, work split four ways — @ahmed
- Shipped: every brief now has an owner area and ordered tasks; `PROJECT.md` has the pitch, the decisions and the
  open questions; `research/ledger.md` § 5 adds to Max's § 2 and § 3. Who owns what (above) is filled in.
- Touched: `progress.md`; on `context`: `PROJECT.md`, `CLAUDE.md`, all four briefs, `research/ledger.md`
- Decision: by Ahmed, on top of Max's round 1: printed-marker alignment; WebRTC live view from the start; cut-outs
  show on the phone as a box plus a built-in model; enter Neptune North, Accenture, Marshall Wace and RS; Scaniverse
  before Dawn; all four build in parallel against fake peers. Full records: `PROJECT.md` → Decision log.
- 📨 To @salman: you have the iPhone app (`ios/`). Start with marker detection on a real phone. Ahmed needs your
  pick of WebRTC library before signalling can be written.
- 📨 To @max: your research (ledger § 1–4) landed while this was being written, and it cuts against two of
  Ahmed's calls: cut-outs on the phone (you found RealityKit on iOS 27.2+ can draw splats) and live view (you
  recommend JPEG first). Both are in `PROJECT.md` → Pending as reopened, not changed. Talk to Ahmed.
- 📨 To @max: you have the dashboard's 3D view and the splats. Your two requests are in `PROJECT.md` → NOW. Laura
  needs `dashboard/src/scene/api.ts` from you before her guide builder can start.
- 📨 To @laura: you have the guide builder, the models, the demo set, the UNO Q rig and the pitch. Salman and Max
  need the printed marker from you before anything lines up. Yours is the longest list: say so if it's too much.
- 📨 To @max @laura @salman: Ahmed owes you `contracts/protocol.ts`, a sample guide and the fake peers. Until then
  use the draft in `docs/remote-assist/architecture.md`.
- ⚠️ Conflicts: @max @laura @salman — new tasks in your brief, and roles and decisions made without you in the room.
  Object here before building on them.
- Conflict status: open

### 2026-11-14 20:28 — UNO Q rig moves to Ahmed — @ahmed
- Shipped: Ahmed builds the UNO Q rig himself (`hardware/`), so it's off Laura's list. Briefs, `PROJECT.md` and Who
  owns what are updated. Ahmed also confirmed the phone app is native, built in Xcode.
- Touched: `progress.md`; on `context`: `PROJECT.md`, the briefs
- Decision: the UNO Q rig is Ahmed's, not Laura's (Ahmed).
- 📨 To @laura: the two UNO Q tasks are gone from your brief (archived at the bottom). Keep a spot on the demo set
  for the rig, and agree it with Ahmed before the set is scanned.
- 📨 To @max: `docs/remote-assist/open-questions.md` is out of step with `PROJECT.md`. Question 1 is decided (option
  B, the printed marker, by Ahmed). Questions 2 and 3 are still open between you and Ahmed: he chose the box-and-model
  stand-in and WebRTC before seeing your recommendations. Please update your file once you two have talked.
- 📨 To @salman: please check the Mac's Xcode version and the demo iPhone's iOS version, and post them.
- ⚠️ Conflicts: @laura — your brief changed (two tasks removed) | @max — your open-questions file disagrees with
  `PROJECT.md` on questions 1 to 3
- Conflict status: open
