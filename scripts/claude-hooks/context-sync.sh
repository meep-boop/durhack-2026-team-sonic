#!/bin/bash
# UserPromptSubmit hook (registered in .claude/settings.json): the every-prompt routine. Pull the newest code, sync
# the shared docs from the context branch, show new progress.md entries. It runs before Claude reads the prompt, and
# whatever it prints lands in Claude's context. It always exits 0, because a dead network or a missing branch must
# never block a prompt: a failed step prints one line and the session carries on with what's on disk.
cd "$(dirname "$0")/../.." || exit 0
git rev-parse --git-dir >/dev/null 2>&1 && [ -f team.conf ] || exit 0
. scripts/lib.sh || exit 0
[ -n "$(git config --get team.builder)" ] || echo "setup: this clone has no builder set; run bash scripts/setup.sh <key>"
online=1
git fetch -q --prune origin 2>/dev/null || online=0
start_head=$(git rev-parse -q --verify HEAD)

# Pull only where nothing can go wrong: fast-forwards. A branch with commits of its own takes main through the
# ship sequence (`git merge origin/main`, then re-test), never silently in the middle of a prompt.
branch=$(git symbolic-ref -q --short HEAD)
if [ "$online" = 1 ] && [ -n "$branch" ] && [ ! -e "$gitdir/MERGE_HEAD" ] && [ ! -d "$gitdir/rebase-merge" ] && [ ! -d "$gitdir/rebase-apply" ]; then
  # A fetch into the branch, not update-ref: git refuses it while main is checked out in another worktree, where moving
  # the ref under that worktree's index would make its next commit quietly revert everyone else's work.
  if [ "$branch" != main ] && git merge-base --is-ancestor main origin/main 2>/dev/null; then
    git fetch -q . refs/remotes/origin/main:refs/heads/main 2>/dev/null || true
  fi
  for target in $(git rev-parse -q --abbrev-ref '@{u}' 2>/dev/null) origin/main; do
    git rev-parse -q --verify "$target" >/dev/null || continue
    git merge-base --is-ancestor "$target" HEAD && continue
    if git merge-base --is-ancestor HEAD "$target"; then
      if git merge --ff-only -q "$target" 2>/dev/null; then
        echo "code: fast-forwarded $branch to $target ($(git rev-parse --short HEAD))"
      else
        echo "code: couldn't fast-forward $branch to $target (uncommitted edits in the way?)"
      fi
    else
      echo "code: $branch has its own commits and is $(git rev-list --count "HEAD..$target") behind $target; merge it at the next ship (ship skill, step 5)"
    fi
  done
fi

# Docs edited or added since the last sync and not published yet. sync-context.sh backs an edit up before replacing
# it, so this is a reminder, not a rescue. A throwaway index of the last-synced tree lets git compare line-ending aware.
synced=$(cat "$gitdir/context-synced" 2>/dev/null)
if [ -n "$synced" ]; then
  export GIT_INDEX_FILE="$gitdir/context-check-index"
  if git read-tree "$synced" 2>/dev/null; then
    # --refresh exits 1 and prints "needs update" for every edited doc; the diff below is what reports them.
    git update-index -q --refresh >/dev/null 2>&1
    edited=$( { git diff --name-only --diff-filter=M 2>/dev/null
                LC_ALL=C comm -13 <(git ls-files | LC_ALL=C sort) <(local_shared_docs | LC_ALL=C sort); } )
  fi
  rm -f "$GIT_INDEX_FILE"
  unset GIT_INDEX_FILE
  if [ -n "$edited" ]; then
    echo "context: these docs have local edits that aren't published yet (publish before the turn ends: bash scripts/publish-context.sh \"what changed\"):"
    printf '%s\n' "$edited" | sed 's/^/  /'
  fi
fi

if [ "$online" = 1 ]; then
  bash scripts/sync-context.sh 2>&1 || echo "context: sync didn't finish; working on the local copy"
else
  echo "context: offline (fetch failed); working on the local copy"
fi

# "New since you last checked": a stamp of the origin/main last shown, so each entry appears once. The first run
# falls back to the HEAD this prompt started from, matching `git diff HEAD..origin/main -- progress.md`.
main=$(git rev-parse -q --verify origin/main) || exit 0
seen=$(cat "$gitdir/progress-seen" 2>/dev/null || echo "$start_head")
# Whole entries, not diff lines: diff alignment hides repeated lines such as "- Conflict status: open", and those are
# the lines that matter here.
headings() { git show "$1:progress.md" 2>/dev/null | grep '^### ' | LC_ALL=C sort -u; }
new_headings=$(LC_ALL=C comm -13 <(headings "$seen") <(headings "$main"))
if [ -n "$new_headings" ]; then
  echo "progress.md: new entries on origin/main since the last check:"
  git show "$main:progress.md" | HEADINGS="$new_headings" awk '
    BEGIN { n = split(ENVIRON["HEADINGS"], h, "\n"); for (i = 1; i <= n; i++) wanted[h[i]] = 1 }
    /^##+ / { show = ($0 in wanted) }
    show'
else
  echo "progress.md: no new entries"
fi
edited_lines=$(git diff "$seen" "$main" -- progress.md 2>/dev/null | grep -v -E '^--- (a/|/dev/null)' | grep -c '^-')
[ "$edited_lines" -gt 0 ] && echo "progress.md: $edited_lines earlier line(s) changed too, e.g. a conflict status or the Latest block: git diff ${seen:0:7} ${main:0:7} -- progress.md"
[ "$online" = 1 ] || echo "progress.md: offline, so that was the last fetched copy"
echo "$main" > "$gitdir/progress-seen"
exit 0
