#!/bin/bash
# Once per clone, by every builder: say who you are, turn on the git hooks, pull the shared docs.
# Usage: bash scripts/setup.sh <your key from team.conf BUILDERS>
set -euo pipefail
. "$(dirname "$0")/lib.sh"
key=${1:-}

if [ -z "$key" ]; then
  echo "usage: bash scripts/setup.sh <key>   (keys in team.conf: $BUILDERS)" >&2
  exit 1
fi
case " $BUILDERS " in
  *" $key "*) ;;
  *) echo "'$key' isn't in team.conf BUILDERS ($BUILDERS). A docs owner adds you there first (and runs init or adds your brief)." >&2
     exit 1 ;;
esac

git config team.builder "$key"
git config core.hooksPath scripts/git-hooks
# git skips a hook that isn't executable; a zip download or a careless copy loses the bit the repo records.
chmod +x scripts/git-hooks/* 2>/dev/null || true
echo "setup: you are '$key'; commit hooks on (AI-trailer block + gitleaks secret scan)"

# Judges read who committed, so the email has to be the one on your GitHub account.
email=$(git config --get user.email || true)
if [ -z "$email" ]; then
  echo "setup: no git user.email. Set the one on your GitHub account: git config user.email \"you@example.com\"" >&2
else
  echo "setup: commits will be authored as $(git config --get user.name || echo '?') <$email>. Is that your GitHub email? If not: git config user.email \"...\""
fi
command -v gitleaks >/dev/null 2>&1 || echo "setup: gitleaks isn't installed, so commits aren't scanned for secrets (winget install Gitleaks.Gitleaks / brew install gitleaks)"

if bash scripts/sync-context.sh; then
  echo "setup: done. Open Claude Code in this folder and say \"fetch the context\"."
else
  echo "setup: the first docs sync didn't finish (reason above). Fix that, then run: bash scripts/sync-context.sh"
fi
