#!/bin/bash
# Publish your edited shared docs to the context branch without switching branches.
# Usage: scripts/publish-context.sh "What changed, in plain words"
# Only files you changed since your last sync are sent. Everything else keeps the version already on context,
# so a stale local copy can never undo a teammate's edit. Refuses: a file changed on context AND locally, and
# anything that looks like a credential. Unless you are in DOCS_OWNERS (team.conf), only your own brief and research/
# are sent; other edits stay local and are listed.
# Who you are comes from `git config team.builder <key>` (scripts/setup.sh sets it).
set -euo pipefail
. "$(dirname "$0")/lib.sh"
msg=${1:?usage: scripts/publish-context.sh "what changed"}

builder=$(git config --get team.builder || true)
if [ -z "$builder" ]; then
  echo "publish refused: say who you are first: bash scripts/setup.sh <your key from team.conf>" >&2
  exit 1
fi
synced=$(cat "$gitdir/context-synced" 2>/dev/null || true)
if [ -z "$synced" ]; then
  echo "publish refused: run scripts/sync-context.sh first" >&2
  exit 1
fi
git fetch -q origin "$context_refspec"
parent=$(git rev-parse "origin/$CONTEXT_BRANCH")

blob() { git rev-parse -q --verify "$1:$2" 2>/dev/null || echo none; }
candidates=$( { git ls-tree -r --name-only "$parent" | while IFS= read -r f; do is_shared_doc "$f" && printf '%s\n' "$f"; done
                local_shared_docs; } | sort -u)

changed=()
conflicts=()
held=()
while IFS= read -r f; do
  [ -f "$f" ] || continue
  mine=$(git hash-object "$f"); base=$(blob "$synced" "$f"); remote=$(blob "$parent" "$f")
  if [ "$mine" = "$base" ] || [ "$mine" = "$remote" ]; then continue; fi
  if [ "$remote" != "$base" ]; then conflicts+=("$f"); continue; fi
  if is_docs_owner "$builder"; then changed+=("$f"); continue; fi
  case "$f" in
    "builder-file-$builder.md" | research/*) changed+=("$f") ;;
    *) held+=("$f") ;;
  esac
done <<< "$candidates"

if [ ${#conflicts[@]} -gt 0 ]; then
  printf 'publish refused: changed on %s since your last sync AND locally:\n' "$CONTEXT_BRANCH" >&2
  printf '  %s\n' "${conflicts[@]}" >&2
  echo "run scripts/sync-context.sh (it saves your copy under .git/context-backup/), re-apply your edit, re-run" >&2
  exit 1
fi
if [ ${#held[@]} -gt 0 ]; then
  echo "context: not sent, only $DOCS_OWNERS publish these (ask them in a progress.md ping, or undo the local edit):" >&2
  printf '  %s\n' "${held[@]}" >&2
fi
if [ ${#changed[@]} -eq 0 ]; then
  echo "context: nothing to publish"
  if [ ${#held[@]} -gt 0 ]; then exit 1; fi
  exit 0
fi
leaks=$(secret_shaped "${changed[@]}")
if [ -n "$leaks" ]; then
  printf 'publish refused: these look like they contain a credential:\n' >&2
  printf '%s\n' "$leaks" | sed 's/^/  /' >&2
  exit 1
fi

export GIT_INDEX_FILE="$gitdir/context-index"
rm -f "$GIT_INDEX_FILE"
git read-tree "$parent"
for f in "${changed[@]}"; do
  git update-index --add --cacheinfo "100644,$(git hash-object -w "$f"),$f"
done
tree=$(git write-tree)
rm -f "$GIT_INDEX_FILE"
unset GIT_INDEX_FILE
commit=$(git commit-tree "$tree" -p "$parent" -m "$msg")
git push -q origin "$commit:refs/heads/$CONTEXT_BRANCH"
git update-ref "refs/remotes/origin/$CONTEXT_BRANCH" "$commit"
echo "context: published ${commit:0:7} ($msg): ${changed[*]}"
# Brings in teammates' edits made since your last sync and moves the stamp, so the next publish sees only real edits.
# Your published files already match, and a held edit is untouched because nobody else changed that file.
bash "$(dirname "$0")/sync-context.sh" >/dev/null || echo "context: published, but the follow-up sync failed; run bash scripts/sync-context.sh" >&2
