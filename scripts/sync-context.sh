#!/bin/bash
# Pull the latest shared docs (CLAUDE.md, PROJECT.md, briefs, research, skills) from the context branch into this
# folder. Files are unpacked, never staged: main's .gitignore ignores them, so they can't be committed by accident.
# A doc you edited but haven't published is copied to .git/context-backup/ before it's replaced, so no edit is lost.
# Prints what changed since the last sync so Claude can tell the user before working.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

if ! git fetch -q origin "$context_refspec" 2>/dev/null; then
  if git ls-remote --exit-code -q origin "refs/heads/$CONTEXT_BRANCH" >/dev/null 2>&1; then
    echo "context: fetch failed (offline?); working on the local copy" >&2
  else
    echo "context: there's no '$CONTEXT_BRANCH' branch on origin (or it's unreachable). If the project is new, the docs owner ($DOCS_OWNERS) runs: bash scripts/init-context.sh" >&2
  fi
  exit 1
fi
new=$(git rev-parse "origin/$CONTEXT_BRANCH")
stamp="$gitdir/context-synced"
old=$(cat "$stamp" 2>/dev/null || echo none)
git cat-file -e "$old^{commit}" 2>/dev/null || old=none
zero=0000000000000000000000000000000000000000

# "<blob at the last sync> <blob now> <path>" for every doc to bring up to date: whatever changed on the branch since
# the last sync, plus anything missing from disk (a `git clean -X` wipes the ignored docs while the stamp stays current).
work() {
  if [ "$old" != none ]; then
    git diff --raw --no-abbrev --no-renames "$old" "$new" | while IFS=$'\t' read -r meta f; do
      set -- $meta
      printf '%s %s %s\n' "$3" "$4" "$f"
    done
  fi
  git ls-tree -r "$new" | while IFS=$'\t' read -r meta f; do
    set -- $meta
    if [ "$old" = none ] || [ ! -e "$f" ]; then printf 'none %s %s\n' "$3" "$f"; fi
  done
}

backup="$gitdir/context-backup/$(date +%Y%m%d-%H%M%S)"
saved=()
written=0
while read -r base latest f; do
  is_shared_doc "$f" || continue
  if [ -f "$f" ]; then
    mine=$(git hash-object "$f")
    [ "$mine" = "$latest" ] && continue
    if [ "$mine" != "$base" ]; then
      mkdir -p "$backup/$(dirname "$f")"
      cp "$f" "$backup/$f"
      saved+=("$f")
    fi
  elif [ "$latest" = "$zero" ]; then
    continue
  fi
  if [ "$latest" = "$zero" ]; then
    rm -f "$f"
  else
    mkdir -p "$(dirname "$f")"
    git cat-file blob "$latest" > "$f"
  fi
  written=$((written + 1))
done < <(work)
echo "$new" > "$stamp"

if [ "$old" = none ]; then
  echo "context: first sync at ${new:0:7}. Read PROJECT.md (NOW) and your builder-file-<name>.md."
elif [ "$old" != "$new" ]; then
  echo "context: UPDATED ${old:0:7} -> ${new:0:7}"
  git log --format='  %h %s (%an, %ar)' "$old..$new"
  git diff --stat "$old" "$new"
elif [ "$written" -gt 0 ]; then
  echo "context: up to date (${new:0:7}); restored $written missing doc(s)"
else
  echo "context: up to date (${new:0:7})"
fi
if [ ${#saved[@]} -gt 0 ]; then
  echo "context: you had unpublished edits, saved in $backup. Re-apply them, then publish:"
  printf '  %s\n' "${saved[@]}"
fi
