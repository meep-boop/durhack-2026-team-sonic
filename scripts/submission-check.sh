#!/bin/bash
# Before you submit or make the repo public: checks what judges and the public would see. Changes nothing; it prints
# the commands to run. Exits 1 if a blocker is found.
# Usage: bash scripts/submission-check.sh
set -uo pipefail
. "$(dirname "$0")/lib.sh"
git fetch -q --prune origin 2>/dev/null || echo "warn: fetch failed, so this checks the last fetched copy of origin"
blockers=0
block() { echo "BLOCKER: $*"; blockers=1; }
branches=$(git for-each-ref --format='%(refname:short)' refs/remotes/origin | sed 's#^origin/##' | grep -v -x -E "HEAD|origin|$CONTEXT_BRANCH")

# Every pushed branch goes public with the repo, not just main.
for b in $branches; do
  docs=$(git ls-tree -r --name-only "origin/$b" | while IFS= read -r f; do is_shared_doc "$f" && printf '%s\n' "$f"; done)
  [ -n "$docs" ] && block "shared docs are committed on origin/$b (git rm --cached them there, then commit):" \
    && printf '%s\n' "$docs" | sed 's/^/  /'
  [ "$b" = main ] || git merge-base --is-ancestor "origin/$b" origin/main 2>/dev/null || echo "todo: origin/$b has commits that aren't on main"
done

readme=$(git show origin/main:README.md 2>/dev/null || true)
if grep -q 'kit-readme' <<< "$readme"; then
  block "README.md is still the team-kit README; swap in the judges' version (pitch skill, kit/README.judges.template.md)"
elif grep -q -E '\{\{|_blank_|_link_' <<< "$readme"; then
  block "README.md still has template blanks ({{...}}, _blank_ or _link_)"
fi

if command -v gitleaks >/dev/null 2>&1; then
  gitleaks git --no-banner --redact --log-level warn . >/dev/null 2>&1 \
    || block "gitleaks found a secret in the history (see: gitleaks git --redact .). Rotate it first; deleting the commit isn't enough once pushed"
else
  echo "warn: gitleaks isn't installed, so the history wasn't scanned for secrets"
fi

if git ls-remote --exit-code -q origin "refs/heads/$CONTEXT_BRANCH" >/dev/null 2>&1; then
  echo "todo: the '$CONTEXT_BRANCH' branch is still on GitHub. After the last doc edit: git push origin --delete $CONTEXT_BRANCH"
fi

git log origin/main --format=%B | grep -qiE '^(co-authored-by|generated[- ]with):.*(@anthropic\.com|@openai\.com|copilot|chatgpt)' \
  && echo "note: main's history has AI attribution trailers; fine if the event's AI policy allows it (EVENT.md §3)"

echo "commits on main by author (judges check that everyone contributed):"
git shortlog -sne origin/main | sed 's/^/  /'
git cat-file -e origin/main:LICENSE 2>/dev/null || git cat-file -e origin/main:LICENSE.md 2>/dev/null \
  || echo "todo: no LICENSE on main; add one if the event wants open source (EVENT.md §3)"

if [ "$blockers" = 0 ]; then echo "submission-check: no blockers"; else exit 1; fi
