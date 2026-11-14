#!/bin/bash
# Runs setup, init, sync, publish and the every-prompt hook against a throwaway remote with a three-person team.
# A stale copy must never undo a teammate's published edit, non-owners may publish only their own brief, sync must
# never lose an unpublished edit, and credentials never get published.
# Usage: bash scripts/test-context-scripts.sh
set -euo pipefail
here=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }
quiet() { "$@" >/dev/null 2>&1; }
# MSYS_NO_PATHCONV only around `git show`: elsewhere Git Bash must still translate the /tmp paths for Windows git
on_context() { (cd "$tmp/$1" && git fetch -q origin context && MSYS_NO_PATHCONV=1 git show "origin/context:$2"); }

git init -q --bare "$tmp/remote.git"
git init -q -b main "$tmp/seed"
cd "$tmp/seed"
git config user.email seed@test
git config user.name seed
cp -r "$here/scripts" "$here/kit" "$here/.gitignore" "$here/.gitattributes" .
printf 'PROJECT_NAME="R&D/Test"\nTEAM_NAME="Team Test"\nEVENT_NAME="TestHack"\nCONTEXT_BRANCH="context"\nBUILDERS="ana ben cal"\nDOCS_OWNERS="ana"\n' > team.conf
git add -A
git commit -qm main --no-verify
git remote add origin "$tmp/remote.git"
git push -q origin main

clone() {  # clone <key>: a teammate's clone, set up with scripts/setup.sh
  git clone -q -b main "$tmp/remote.git" "$tmp/$1"
  git -C "$tmp/$1" config user.email "$1@test"
  git -C "$tmp/$1" config user.name "$1"
  (cd "$tmp/$1" && quiet bash scripts/setup.sh "$1") || true
}

clone ana
cd "$tmp/ana"
[ "$(git config team.builder)" = ana ] || fail "setup didn't record who ana is"
[ "$(git config core.hooksPath)" = scripts/git-hooks ] || fail "setup didn't turn on the commit hooks"
quiet bash scripts/setup.sh zed && fail "setup accepted a key that isn't in team.conf"
quiet bash scripts/init-context.sh || fail "ana (docs owner) couldn't seed the context branch"
grep -q "R&D/Test" CLAUDE.md || fail "init didn't fill {{PROJECT}} (or mangled the & and /)"
[ -f builder-file-cal.md ] && grep -q "cal" builder-file-cal.md || fail "init didn't write a brief per builder"
[ -f .claude/skills/no-slop/SKILL.md ] || fail "init didn't ship the skills"
grep -rq "{{" CLAUDE.md PROJECT.md EVENT.md builder-file-ana.md && fail "init left a {{placeholder}} unfilled"
[ -f progress.md ] || fail "init didn't create progress.md"
quiet bash scripts/init-context.sh && fail "init ran twice over an existing context branch"
git add progress.md && git commit -qm "Add progress board" && git push -q origin main

clone ben
clone cal
[ -f "$tmp/ben/PROJECT.md" ] || fail "ben's setup didn't sync the shared docs"
(cd "$tmp/cal" && quiet bash scripts/init-context.sh) && fail "cal (not an owner) could seed context"

# the original clobber bug: cal publishes his own brief from a sync older than ben's publish
cd "$tmp/ben"
echo "ben: task 3 done" >> builder-file-ben.md
quiet bash scripts/publish-context.sh "ben done" || fail "ben could not publish his own brief"
cd "$tmp/cal"
echo "cal: task 6 done" >> builder-file-cal.md
quiet bash scripts/publish-context.sh "cal done" || fail "cal could not publish his own brief"
on_context cal builder-file-ben.md | grep -q "task 3 done" || fail "cal's stale copy undid ben's edit"
grep -q "task 3 done" "$tmp/cal/builder-file-ben.md" || fail "publish left cal's stale copy in place"

# a skill added on context after ben's last sync survives ben's next publish
cd "$tmp/ana"
quiet bash scripts/sync-context.sh
mkdir -p .claude/skills/added
echo "new skill" > .claude/skills/added/SKILL.md
quiet bash scripts/publish-context.sh "ana adds a skill" || fail "ana could not add a skill"
cd "$tmp/ben"
echo "ben: task 4 done" >> builder-file-ben.md
quiet bash scripts/publish-context.sh "ben again" || fail "ben's second publish failed"
on_context ben .claude/skills/added/SKILL.md | grep -q "new skill" || fail "ben's publish dropped a skill added after his sync"

# non-owners can't publish someone else's brief or other shared docs; the owner can publish several
cd "$tmp/cal"
quiet bash scripts/sync-context.sh
echo "cal edits ben" >> builder-file-ben.md
quiet bash scripts/publish-context.sh "x" && fail "cal published ben's brief"
on_context cal builder-file-ben.md > builder-file-ben.md
echo "cal edits the rules" >> CLAUDE.md
quiet bash scripts/publish-context.sh "x" && fail "cal published CLAUDE.md"
on_context cal CLAUDE.md > CLAUDE.md
echo "cal: a research pass" >> research/ledger.md
quiet bash scripts/publish-context.sh "research: x" || fail "cal could not publish research"
# a stray edit to an owner's doc is held back, and the rest of the publish still goes out
echo "cal: task 7 done" >> builder-file-cal.md
echo "cal's stray edit" >> PROJECT.md
quiet bash scripts/publish-context.sh "cal done" || fail "a held edit blocked cal's own brief"
on_context cal builder-file-cal.md | grep -q "task 7 done" || fail "cal's brief didn't go out alongside a held edit"
on_context cal PROJECT.md | grep -q "stray edit" && fail "cal published PROJECT.md"
grep -q "stray edit" PROJECT.md || fail "publish threw away cal's held local edit"
on_context cal PROJECT.md > PROJECT.md
# a research file with a non-ASCII name reaches teammates
echo "notes" > "research/café — notes.md"
quiet bash scripts/publish-context.sh "research: café" || fail "cal could not publish a non-ASCII file name"
(cd "$tmp/ben" && quiet bash scripts/sync-context.sh) || fail "a non-ASCII file name broke ben's sync"
[ -f "$tmp/ben/research/café — notes.md" ] || fail "ben didn't get the non-ASCII research file"
cd "$tmp/ana"
quiet bash scripts/sync-context.sh
echo "ana tidies" >> builder-file-ben.md
echo "ana tidies" >> builder-file-cal.md
mkdir -p .claude/skills/ui-audit/node_modules/x
echo "junk" > .claude/skills/ui-audit/node_modules/x/index.js
quiet bash scripts/publish-context.sh "ana tidies two briefs" || fail "ana could not publish two briefs"
on_context ana .claude/skills/ui-audit/node_modules/x/index.js >/dev/null 2>&1 && fail "tool output in the skills folder was published"

# a wiped doc comes back on the next sync even though nothing changed on the branch (cal, so ben's sync stays stale)
cd "$tmp/cal"
quiet bash scripts/sync-context.sh
rm PROJECT.md
quiet bash scripts/sync-context.sh
[ -f PROJECT.md ] || fail "sync didn't restore a doc deleted from disk"

# credentials are refused even from the owner; built at run time so this script never holds a key-shaped string
printf -- '-----BEGIN %s-----\n' "OPENSSH PRIVATE KEY" >> PROJECT.md
quiet bash scripts/publish-context.sh "x" && fail "publish sent a private key"
on_context ana PROJECT.md > PROJECT.md

# publishing without saying who you are is refused
cd "$tmp/cal"
git config --unset team.builder
quiet bash scripts/sync-context.sh
echo "x" >> builder-file-cal.md
quiet bash scripts/publish-context.sh "x" && fail "publish ran without team.builder"
git config team.builder cal
on_context cal builder-file-cal.md > builder-file-cal.md

# ben's last sync predates ana's tidy of his brief: publishing is refused, and sync keeps his edit as a backup
cd "$tmp/ben"
echo "ben: unpublished note" >> builder-file-ben.md
quiet bash scripts/publish-context.sh "conflict" && fail "publish ignored a change made on both sides"
quiet bash scripts/sync-context.sh
grep -rq "unpublished note" .git/context-backup || fail "sync lost ben's unpublished edit"
grep -q "ana tidies" builder-file-ben.md || fail "sync didn't bring in ana's tidy"

# the every-prompt hook: fast-forwards main, reports a new progress.md entry once, and always exits 0
cd "$tmp/ana"
printf '\n### 2026-01-01 10:00 — test entry — @ana\n- Shipped: x\n' >> progress.md
git commit -qam "Log a test entry" && git push -q origin main
cd "$tmp/ben"
out=$(bash scripts/claude-hooks/context-sync.sh) || fail "the hook exited non-zero"
grep -q "fast-forwarded main" <<< "$out" || fail "the hook didn't fast-forward main: $out"
grep -q "test entry — @ana" <<< "$out" || fail "the hook didn't show the new progress.md entry: $out"
out=$(bash scripts/claude-hooks/context-sync.sh)
grep -q "progress.md: no new entries" <<< "$out" || fail "the hook showed the same entry twice: $out"

# main checked out in another worktree: the hook must leave it alone, or that worktree's next commit reverts others
git checkout -q -b ben-feature
git worktree add -q "$tmp/ben-main" main
before=$(git rev-parse main)
cd "$tmp/ana"
printf '\n### 2026-01-01 11:00 — second entry — @ana\n- Shipped: y\n' >> progress.md
git commit -qam "Log a second entry" && git push -q origin main
cd "$tmp/ben"
bash scripts/claude-hooks/context-sync.sh >/dev/null || fail "the hook exited non-zero on a feature branch"
[ "$(git rev-parse main)" = "$before" ] || fail "the hook moved main under another worktree"
[ -z "$(git -C "$tmp/ben-main" status --porcelain --untracked-files=no)" ] || fail "the other worktree shows staged changes"
git remote set-url origin "$tmp/nowhere.git"
bash scripts/claude-hooks/context-sync.sh >/dev/null || fail "the hook failed offline instead of carrying on"

echo "PASS: context scripts"
