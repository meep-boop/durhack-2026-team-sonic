#!/bin/bash
# Once per project, by a docs owner: render kit/ into the shared docs and push them as a new context branch.
# Fills {{PROJECT}}, {{TEAM}}, {{EVENT}}, {{REPO}}, {{CONTEXT_BRANCH}}, {{DOCS_OWNERS}}, {{DATE}} from team.conf and git,
# and writes one builder-file-<key>.md per key in BUILDERS ({{NAME}}). Everything else is filled during the event.
# Usage: bash scripts/init-context.sh
set -euo pipefail
. "$(dirname "$0")/lib.sh"

builder=$(git config --get team.builder || true)
if ! is_docs_owner "$builder"; then
  echo "init refused: only a docs owner ($DOCS_OWNERS) seeds the context branch; run bash scripts/setup.sh <key> first" >&2
  exit 1
fi
if git ls-remote --exit-code -q origin "refs/heads/$CONTEXT_BRANCH" >/dev/null 2>&1; then
  echo "init refused: origin already has '$CONTEXT_BRANCH'. Run bash scripts/sync-context.sh instead" >&2
  exit 1
fi

# host/owner/repo with any scheme, user or token stripped: a token in the remote URL must never land in the docs.
repo=$(git remote get-url origin | sed -E 's#^[a-z+]+://##; s#^[^@/]*@##; s#^([^/:]+):#\1/#; s#\.git$##')
today=$(date +%Y-%m-%d)
# Escapes what sed treats as special in a replacement, so names like "R&D" or "a/b" survive.
esc() { printf '%s' "$1" | sed 's/[\\&|]/\\&/g'; }
render() {  # render <template> <builder key or empty>
  sed -e "s|{{PROJECT}}|$(esc "$PROJECT_NAME")|g" -e "s|{{TEAM}}|$(esc "$TEAM_NAME")|g" \
      -e "s|{{EVENT}}|$(esc "$EVENT_NAME")|g" -e "s|{{REPO}}|$(esc "$repo")|g" \
      -e "s|{{CONTEXT_BRANCH}}|$(esc "$CONTEXT_BRANCH")|g" -e "s|{{DOCS_OWNERS}}|$(esc "$DOCS_OWNERS")|g" \
      -e "s|{{DATE}}|$today|g" -e "s|{{NAME}}|$(esc "$2")|g" "$1"
}

out="$gitdir/context-init"
rm -rf "$out"
emit() {  # emit <path on context>, content on stdin
  mkdir -p "$out/$(dirname "$1")"
  cat > "$out/$1"
}
render kit/CLAUDE.template.md "" | emit CLAUDE.md
render kit/PROJECT.template.md "" | emit PROJECT.md
render kit/EVENT.template.md "" | emit EVENT.md
render kit/CONTEXT-README.md "" | emit CONTEXT-README.md
render kit/research.template.md "" | emit research/ledger.md
for key in $BUILDERS; do
  render kit/brief.template.md "$key" | emit "builder-file-$key.md"
done
[ -f progress.md ] || render kit/progress.template.md "" > progress.md
leaks=$( (cd "$out" && secret_shaped CLAUDE.md PROJECT.md EVENT.md CONTEXT-README.md research/ledger.md builder-file-*.md)
         secret_shaped progress.md)
if [ -n "$leaks" ]; then
  echo "init refused: the rendered docs look like they contain a credential (check team.conf and the origin URL):" >&2
  printf '%s\n' "$leaks" | sed 's/^/  /' >&2
  exit 1
fi
# Tracked files only, so whatever a tool left in kit/skills on this machine stays here.
while IFS= read -r f; do
  dest=".claude/skills/${f#kit/skills/}"
  if is_shared_doc "$dest"; then emit "$dest" < "$f"; fi
done < <(git ls-files kit/skills)

export GIT_INDEX_FILE="$gitdir/context-init-index"
rm -f "$GIT_INDEX_FILE"
while IFS= read -r f; do
  git update-index --add --cacheinfo "100644,$(git hash-object -w --path="$f" "$out/$f"),$f"
done < <(cd "$out" && find . -type f | sed 's#^\./##')
tree=$(git write-tree)
rm -f "$GIT_INDEX_FILE"
unset GIT_INDEX_FILE
rm -rf "$out"
commit=$(git commit-tree "$tree" -m "Seed the shared docs for $TEAM_NAME at $EVENT_NAME")
git push -q origin "$commit:refs/heads/$CONTEXT_BRANCH"
echo "context: seeded ${commit:0:7} on origin/$CONTEXT_BRANCH"
if [ -n "$(git status --porcelain -- progress.md)" ]; then
  echo "progress.md: created from the kit; commit it to main"
fi
bash scripts/sync-context.sh
