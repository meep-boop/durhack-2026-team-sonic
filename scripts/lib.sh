#!/bin/bash
# Shared by the scripts: find the repo root, load team.conf, decide what counts as a shared doc, spot secrets.
# Git Bash on Windows rewrites "rev:.claude/..." arguments as Windows paths unless this is set.
export MSYS_NO_PATHCONV=1
# A dead credential or a missing branch must fail fast, never wait on a login prompt nobody can see.
export GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never
cd "$(git rev-parse --show-toplevel)" || exit 1
[ -f team.conf ] || { echo "team.conf is missing from the repo root" >&2; exit 1; }
# shellcheck source=../team.conf
. ./team.conf
CONTEXT_BRANCH=${CONTEXT_BRANCH:-context}
gitdir=$(git rev-parse --git-dir)
context_refspec="+refs/heads/$CONTEXT_BRANCH:refs/remotes/origin/$CONTEXT_BRANCH"

# Without this, git prints a name like "café notes.md" as "caf\303\251 notes.md" and every later lookup fails.
git() { command git -c core.quotePath=false "$@"; }

# The only paths sync writes and publish sends. Anything else on the context branch (a stray .env from a manual push)
# never reaches anyone's disk, and tool output inside the skills folder never leaves it.
is_shared_doc() {
  case "$1" in
    */node_modules/* | */.venv/* | */__pycache__/* | *.pyc | */.DS_Store | .DS_Store | */Thumbs.db | *.swp | *~) return 1 ;;
    CLAUDE.md | PROJECT.md | EVENT.md | CONTEXT-README.md | builder-file-*.md | research/* | .claude/skills/*) return 0 ;;
  esac
  return 1
}

local_shared_docs() {
  { ls CLAUDE.md PROJECT.md EVENT.md CONTEXT-README.md builder-file-*.md 2>/dev/null
    find research .claude/skills -type f 2>/dev/null
  } | while IFS= read -r f; do is_shared_doc "$f" && printf '%s\n' "$f"; done
  return 0
}

is_docs_owner() {
  case " $DOCS_OWNERS " in *" $1 "*) return 0 ;; esac
  return 1
}

# Prints the files that look like they hold a credential. Patterns match the shape of a secret, never a fragment of a
# real one, because this file is in the repo. "(^|[^A-Za-z0-9_])" stands in for \b, which BSD grep on macOS lacks.
# Plain words like "token" stay out because the design skills say "design token" everywhere.
secret_shaped() {
  local edge='(^|[^A-Za-z0-9_])'
  { grep -l -E "BEGIN [A-Z ]*PRIVATE KEY|${edge}(gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|AKIA[0-9A-Z]{16}|sk-(ant-|proj-)?[A-Za-z0-9_-]{30,}|xox[abpr]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}|[sr]k_live_[A-Za-z0-9]{20,}|hf_[A-Za-z0-9]{30,})|eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.|drive\.google\.com/(file|drive)/|[a-z][a-z0-9+.-]*://[^/@ :<]+:[^/@ <]+@" "$@"
    grep -l -i -E "(password|passphrase|passwd)[\"']? *[:=] *[\"']?[^ \"'<\`]{8,}" "$@"
  } 2>/dev/null | sort -u
  if command -v gitleaks >/dev/null 2>&1; then
    local f
    for f in "$@"; do
      gitleaks dir --no-banner --redact --log-level error "$f" >/dev/null 2>&1 || printf '%s\n' "$f"
    done
  fi
}
