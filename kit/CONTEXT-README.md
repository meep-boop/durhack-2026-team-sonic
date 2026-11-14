# {{PROJECT}}: shared context (the `{{CONTEXT_BRANCH}}` branch)

This branch holds **only the team's shared docs**, no code. Code lives on `main`. ⚠ If the repo goes public, **delete
this branch first** (`bash scripts/submission-check.sh` reminds you).

| File | What |
|---|---|
| `CLAUDE.md` | The working rules. Every builder's Claude Code reads it on every prompt |
| `PROJECT.md` | **The project doc:** NOW (headline, clock, decisions, tasks) at the top, then spec, design, parked, decision log |
| `EVENT.md` | Event rules, judging, submission checklist, platform |
| `builder-file-<name>.md` | Each builder's brief (read your own) |
| `research/ledger.md` | The evidence ledger (KEEP / WEAK / DO NOT USE) |
| `.claude/skills/` | The project skills: workflow (`fetch-context`, `ship`, `team-docs`, `research-ledger`, `idea-forge`, `pitch`, `sign-off`), code (`no-slop`, `debug`), front-end (`design-direction`, `motion`, `motion-review`, `ui-audit`, `reverse-engineer-ui`, `frontend-performance`) |

**How the sync works:**
- In your clone of `main`, `bash scripts/setup.sh <your key>` does the first sync. From then on, the hook in
  `.claude/settings.json` re-syncs before every prompt and tells your Claude what changed.
- Files are unpacked, never staged, so they can't reach `main`.
- **Publishing:** `bash scripts/publish-context.sh "what changed"`. Docs owners ({{DOCS_OWNERS}}) publish anything.
  Everyone else publishes `research/` and the status of their own brief. The script refuses to overwrite someone's
  newer edit, and refuses anything that looks like a credential.
