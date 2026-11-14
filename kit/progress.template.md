# {{PROJECT}}: progress log and conflict board

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
1. **GitHub:** accept the collaborator invite for `{{REPO}}`, then in **Git Bash** on Windows (plain `bash` in
   PowerShell can start WSL instead) or any terminal on Mac/Linux:
   ```bash
   git clone https://{{REPO}}.git && cd "$(basename {{REPO}})"
   git config user.email "<the email on YOUR GitHub account>"   # judges read who committed
   bash scripts/setup.sh <your key from team.conf>              # who you are, commit hooks, first docs sync
   ```
   Not in `team.conf` yet? Ask a docs owner ({{DOCS_OWNERS}}) to add your key and brief.
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
each builder's brief (`builder-file-<name>.md`, on the `{{CONTEXT_BRANCH}}` branch).

| Who | Role | Branch | Owns (paths / pieces) | How the rest plugs into it |
|---|---|---|---|---|

**Shared** (anyone may edit; flag it): `contracts/*`, `fixtures/*`

## How we work (read once)
- **Code from your own laptop, as yourself.** One branch each (`<name>-<area>`). Per feature: code and test → push
  your branch → `git merge origin/main` into it and re-test → merge to `main` → an entry here. Your Claude runs this
  as the `ship` skill.
- **Shared docs** (`CLAUDE.md`, `PROJECT.md`, `EVENT.md`, briefs, research, skills) are **never** committed to
  `main`. They live on the `{{CONTEXT_BRANCH}}` branch. Edit, then `bash scripts/publish-context.sh "what changed"`,
  and every agent picks it up on its next prompt.
- **Deploy:** _blank_ (where it runs, who restarts it, how).

## Latest
- **The volatile facts live here only:** the current commit, test counts, what's merged vs. local-only, and deploy
  status.
- **As of {{DATE}}:** repo scaffolded with the team kit; no code yet.

---
