#!/usr/bin/env bash
# new-path-test.sh: run the New path's git and gh steps end to end, offline, the way
# skills/assemble/reference/git-model.md lists them, on the empty-dir and files-no-git fixtures,
# once as a Small team and once as a Standard one. No Claude session is needed: this script plays
# the setup chat (the commands after the write screen), then the Chief, the Builder and the human,
# and checks what lands where. The files the setup chat would write are the hand-rendered examples
# tests/rendered/acme-small (Chief, Builder, reviewer helper) and tests/rendered/acme (Chief,
# Reviewer, Builder), with a CLAUDE.md that holds only the block.
#
# Each run covers: preflight reads change nothing; the write gate; the project repo (git init,
# identity, gh auth setup-git, the first commit, gh repo create --push); the notebook folder on
# the setup branch (--no-track); write, check-output, commit, push -u origin HEAD; the exclude line
# (twice, one line); the setup PR (#1); re-run detection sees it; the PR has exactly our files;
# the user's checkout is untouched; a review verdict and a Decision update comment (the head
# doesn't move); the merge gate; the human's merge (tests/lib/fake-gh-merge); the after-merge
# switch and branch delete; the merged .gitignore ignores the left-out files; Priya's own
# git pull leaves her folder clean; a notebook write; a rejected push that syncs and pushes again; the
# Builder's own worktree with step 0 (push.default=upstream can't send it to main), its PR, merge
# and after-merge cleanup; a
# rebase conflict that stops with a clean folder; and no command refused by the shims' rule guards.
# Then the guards themselves: writes before the gate, and rule-breaking writes after it, are
# refused. And Cancel: reads only, tests/check-untouched.sh passes.
#
# Usage: tests/new-path-test.sh [--keep]      (--keep leaves the scratch folder in place)
# Exit:  0 = every check passed, 1 = at least one failed.
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
LC_ALL=C
export LC_ALL
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
keep=no
[ "${1:-}" != --keep ] || keep=yes
work=$(mktemp -d "${TMPDIR:-/tmp}/assemble-newpath.XXXXXX")
work=$(CDPATH= cd -- "$work" && pwd -P)
if [ "$keep" = yes ]; then echo "scratch folder: $work"; else trap 'rm -rf "$work"' EXIT; fi
REAL_GIT=$(command -v git)

STAMP=20261012-1435
BRANCH="assemble/setup-$STAMP"
REPO=priya-acme/acme
NAME='Priya Example'
EMAIL='12345678+priya-acme@users.noreply.github.com'

fails=0
checks=0
ok() { checks=$((checks + 1)); printf 'ok    %s\n' "$*"; }
bad() { checks=$((checks + 1)); fails=$((fails + 1)); printf 'FAIL  %s\n' "$*"; }
show() { printf '%s\n' "$OUT" | sed 's/^/      | /'; }

# run_in FX DIR CMD...: run CMD in DIR with the fixture's env.sh loaded (its fake gh and git first
# on PATH). Output (stdout and stderr) in $OUT, exit code in $RC.
run_in() {
  fx=$1 dir=$2
  shift 2
  OUT=$( ( . "$fx/env.sh"; cd "$dir"; "$@" ) 2>&1 ) && RC=0 || RC=$?
}
# must FX DIR CMD...: run_in, and CMD must exit 0.
must() {
  run_in "$@"
  shift 2
  if [ "$RC" = 0 ]; then ok "$*"; else bad "\"$*\" exited $RC"; show; fi
}
# must_rc WANT FX DIR CMD...: run_in, and CMD must exit WANT.
must_rc() {
  want=$1
  shift
  run_in "$@"
  shift 2
  if [ "$RC" = "$want" ]; then ok "\"$*\" exits $want"; else bad "\"$*\" exited $RC, expected $want"; show; fi
}
# same NAME GOT WANT
same() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1: got \"$2\", expected \"$3\""; fi; }
# has NAME TEXT PATTERN (grep -E)
has() { if printf '%s\n' "$2" | grep -Eq -- "$3"; then ok "$1"; else bad "$1: no \"$3\" in:"; printf '%s\n' "$2" | sed 's/^/      | /'; fi; }
# lacks NAME TEXT PATTERN
lacks() { if printf '%s\n' "$2" | grep -Eq -- "$3"; then bad "$1: found \"$3\" in:"; printf '%s\n' "$2" | sed 's/^/      | /'; else ok "$1"; fi; }
# The real git on a fixture's files, outside the shims (the other people pushing to GitHub).
other_git() {
  env HOME="$fxdir/git-home" GIT_CONFIG_GLOBAL="$fxdir/git-home/.gitconfig" GIT_CONFIG_NOSYSTEM=1 \
    GIT_TERMINAL_PROMPT=0 GIT_CEILING_DIRECTORIES="$work" \
    "$REAL_GIT" -c user.name="$NAME" -c user.email="$EMAIL" "$@"
}
build() { # build FIXTURE FOLDER
  if bash "$root/tests/fixtures/$1/setup.sh" "$2" > "$work/build.log" 2>&1; then
    ok "$1 builds in $(basename "$2")"
  else
    bad "$1 did not build:"; sed -e 's/^/      /' "$work/build.log"
    return 1
  fi
}
untouched() { # untouched FOLDER WANT
  if bash "$root/tests/check-untouched.sh" "$1" > "$work/check.log" 2>&1; then rc=0; else rc=$?; fi
  if [ "$rc" = "$2" ]; then ok "$(basename "$1"): check-untouched exits $rc"; else bad "$(basename "$1"): check-untouched exited $rc, expected $2"; sed -e 's/^/      /' "$work/check.log"; fi
}
calls_clean() { # calls_clean FOLDER: no refused or unsupported call in calls.log
  if grep -q -e '^REFUSED ' -e '^UNSUPPORTED ' "$1/calls.log"; then
    bad "$(basename "$1"): the shims refused or couldn't answer a call:"; grep -e '^REFUSED ' -e '^UNSUPPORTED ' "$1/calls.log" | sed 's/^/      /'
  else
    ok "$(basename "$1"): no call was refused by the shims ($(grep -c . "$1/calls.log") calls)"
  fi
}
# The exclude command, exactly as git-model.md D4 prints it, with <MAIN> filled in.
exclude_cmd() {
  printf '( cd "%s" && f="$(git rev-parse --git-path info/exclude)" && mkdir -p "$(dirname "$f")" && { grep -qxF '"'"'.claude/worktrees/'"'"' "$f" 2>/dev/null || printf '"'"'%%s\\n'"'"' '"'"'.claude/worktrees/'"'"' >> "$f"; } )' "$1"
}

run_case() { # run_case FIXTURE ROSTER
  fixture=$1 roster=$2
  echo
  echo "== $fixture as $roster"
  fxdir="$work/$fixture-$roster"
  build "$fixture" "$fxdir" || return 0
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  MAIN="$fxdir/acme"
  NB="$fxdir/acme-team"
  if [ "$roster" = small ]; then tree="$root/tests/rendered/acme-small"; who=helper; else tree="$root/tests/rendered/acme"; who=Vito; fi

  # --- Preflight and the interview: reads only, so nothing may change.
  must "$fxdir" "$MAIN" gh --version
  run_in "$fxdir" "$MAIN" gh auth status
  has "gh is logged in as priya-acme" "$OUT" 'Logged in to github.com account priya-acme'
  must_rc 128 "$fxdir" "$MAIN" git rev-parse --is-inside-work-tree
  must_rc 1 "$fxdir" "$MAIN" gh repo view "$REPO" --json name
  must_rc 1 "$fxdir" "$MAIN" gh repo view "$REPO-team" --json name,defaultBranchRef
  if [ "$fixture" = empty-dir ]; then
    must_rc 1 "$fxdir" "$MAIN" git config --get user.name
    must_rc 1 "$fxdir" "$MAIN" git config --get credential.https://github.com.helper
  else
    must "$fxdir" "$MAIN" git config --get user.name
  fi
  untouched "$fxdir" 0

  # --- The user picks "Write and open the PR": the tester opens the write gate.
  : > "$fxdir/write-screen-approved"

  # --- git-model.md D1: the project repo.
  must "$fxdir" "$MAIN" git init -b main
  if [ "$fixture" = empty-dir ]; then
    must "$fxdir" "$MAIN" git config user.name "$NAME"
    must "$fxdir" "$MAIN" git config user.email "$EMAIL"
    must "$fxdir" "$MAIN" gh auth setup-git
    must "$fxdir" "$MAIN" git commit --allow-empty -m "Start"
    same "the isolated global git config now has the gh credential helper" \
      "$(other_git config --global --get credential.https://github.com.helper)" '!gh auth git-credential'
  else
    must "$fxdir" "$MAIN" git ls-files --others --exclude-standard
    list="$work/first-commit-$roster.txt"
    big=$(cd "$MAIN" && find . -type f -size +50M -not -path './.git/*' | sed 's|^\./||')
    printf '%s\n' "$OUT" | while IFS= read -r p; do
      [ -n "$p" ] || continue
      case "$p" in
        .env.example) ;;
        .env|.env.*|*.pem|*.key|*.p12|*.pfx|id_rsa*|id_ed25519*|id_ecdsa*|.DS_Store|*/.DS_Store) continue ;;
      esac
      if printf '%s\n' "$big" | grep -qxF -- "$p"; then continue; fi
      printf '%s\n' "$p"
    done > "$list"
    must "$fxdir" "$MAIN" git add --pathspec-from-file="$list"
    must "$fxdir" "$MAIN" git commit -m "Start" --pathspec-from-file="$list"
    run_in "$fxdir" "$MAIN" git ls-tree -r --name-only HEAD
    same "the first commit holds exactly the starter files" "$(printf '%s\n' "$OUT" | tr '\n' ' ')" \
      '.env.example app.js index.html notes/ideas.md package.json '
    run_in "$fxdir" "$MAIN" git status --short
    same "only the left-out files stay untracked" "$(printf '%s\n' "$OUT" | tr '\n' ' ')" '?? .DS_Store ?? .env ?? dev.pem ?? notes/.DS_Store ?? video.raw '
  fi
  must "$fxdir" "$MAIN" gh repo create "$REPO" --private --source . --remote origin --push
  run_in "$fxdir" "$MAIN" git remote get-url origin
  same "origin is the github.com address" "$OUT" "https://github.com/$REPO.git"
  start=$(other_git -C "$MAIN" rev-parse HEAD)
  same "GitHub's main is the first commit" "$(other_git --git-dir="$fxdir/remotes/$REPO.git" rev-parse refs/heads/main)" "$start"

  # --- D2: the notebook folder, on the setup branch.
  run_in "$fxdir" "$MAIN" git worktree list --porcelain
  same "MAIN is the first worktree line" "$(printf '%s\n' "$OUT" | sed -n '1s/^worktree //p')" "$MAIN"
  must "$fxdir" "$MAIN" bash -c "git -C \"$MAIN\" fetch origin || git -C \"$MAIN\" fetch origin"
  run_in "$fxdir" "$MAIN" git -C "$MAIN" ls-remote --heads origin "assemble/setup-*"
  same "no setup branch on GitHub yet" "$OUT" ''
  must "$fxdir" "$MAIN" git -C "$MAIN" worktree add --no-track -b "$BRANCH" "$NB" origin/main
  must_rc 128 "$fxdir" "$NB" git rev-parse --abbrev-ref '@{u}'

  # --- D3: write, check, commit, push. The setup chat's files are the rendered example.
  ( cd "$tree" && find . -type f | sed 's|^\./||' | sort ) > "$work/paths-$roster.txt"
  while IFS= read -r p; do
    mkdir -p "$NB/$(dirname "$p")"
    cp "$tree/$p" "$NB/$p"
  done < "$work/paths-$roster.txt"
  # A new project's CLAUDE.md holds only the block (interview.md part F2).
  awk 'index($0, "<!-- assemble:begin") { on = 1 } on { print } index($0, "<!-- assemble:end -->") { exit }' "$tree/CLAUDE.md" > "$NB/CLAUDE.md"
  if [ ! -f "$tree/.gitignore" ]; then
    printf '%s\n' '# assemble:begin · managed by /assemble' '.claude/worktrees/' '.env' '.env.*' '!.env.example' '# assemble:end' > "$NB/.gitignore"
    { cat "$work/paths-$roster.txt"; echo .gitignore; } | sort > "$work/p" && mv "$work/p" "$work/paths-$roster.txt"
  fi
  if [ "$fixture" = files-no-git ]; then
    # interview.md part F2: the first commit left files out, so the marked block also ignores
    # the key-file patterns, .DS_Store and each left-out large file.
    printf '%s\n' '# assemble:begin · managed by /assemble' '.claude/worktrees/' '.env' '.env.*' '!.env.example' \
      '*.pem' '*.key' '*.p12' '*.pfx' 'id_rsa*' 'id_ed25519*' 'id_ecdsa*' '.DS_Store' '/video.raw' '# assemble:end' > "$NB/.gitignore"
  fi
  # shellcheck disable=SC2046
  must "$fxdir" "$NB" git -C "$NB" add -- $(cat "$work/paths-$roster.txt")
  if bash "$root/scripts/check-output.sh" "$NB" > "$work/co.log" 2>&1; then ok "check-output passes on the staged notebook folder"; else bad "check-output failed on the staged notebook folder:"; sed 's/^/      /' "$work/co.log"; fi
  # shellcheck disable=SC2046
  must "$fxdir" "$NB" git -C "$NB" commit -m "Set up the team with /assemble" -- $(cat "$work/paths-$roster.txt")
  must "$fxdir" "$NB" git -C "$NB" push -u origin HEAD
  same "the setup branch is on GitHub" "$(other_git --git-dir="$fxdir/remotes/$REPO.git" rev-parse "refs/heads/$BRANCH")" "$(other_git -C "$NB" rev-parse HEAD)"
  same "GitHub's main didn't move (no PR-less setup)" "$(other_git --git-dir="$fxdir/remotes/$REPO.git" rev-parse refs/heads/main)" "$start"
  run_in "$fxdir" "$NB" git rev-parse --abbrev-ref '@{u}'
  same "the setup branch tracks its own remote branch" "$OUT" "origin/$BRANCH"

  # --- D4: the exclude line, run twice, lands once.
  must "$fxdir" "$fxdir" bash -c "$(exclude_cmd "$MAIN")"
  must "$fxdir" "$NB" bash -c "$(exclude_cmd "$MAIN")"
  same "info/exclude has the worktrees line exactly once" "$(grep -cx '\.claude/worktrees/' "$MAIN/.git/info/exclude")" 1

  # --- D5: the setup PR.
  printf '## What this PR does\nSets up the team (%s) and its notes.\n\n## Reviewer handoff\n- **Tier:** full\n' "$roster" > "$work/body-$roster.md"
  must "$fxdir" "$NB" gh pr create --repo "$REPO" --base main --head "$BRANCH" --title "Set up the team with /assemble" --body-file "$work/body-$roster.md"
  same "the setup PR is #1" "$(printf '%s\n' "$OUT" | tail -n 1)" "https://github.com/$REPO/pull/1"
  run_in "$fxdir" "$MAIN" gh pr list --repo "$REPO" --state open --json number,headRefName,url,author --limit 100
  has "re-run detection would see the open setup PR" "$OUT" "\"headRefName\":\"$BRANCH\""
  run_in "$fxdir" "$NB" gh pr diff 1 --repo "$REPO" --name-only
  same "the PR holds exactly the setup files" "$(printf '%s\n' "$OUT" | sort | tr '\n' ' ')" "$(tr '\n' ' ' < "$work/paths-$roster.txt")"
  same "the user's checkout is still on main" "$(other_git -C "$MAIN" symbolic-ref HEAD)" refs/heads/main
  same "the user's checkout is still at the first commit" "$(other_git -C "$MAIN" rev-parse HEAD)" "$start"
  st=$(other_git -C "$MAIN" status --porcelain --untracked-files=all | tr '\n' ' ')
  if [ "$fixture" = empty-dir ]; then same "the user's checkout has no new files" "$st" ''; else same "the user's checkout has only its own untracked files" "$st" '?? .DS_Store ?? .env ?? dev.pem ?? notes/.DS_Store ?? video.raw '; fi
  if [ -e "$MAIN/README.md" ] || [ -e "$MAIN/team" ] || [ -e "$MAIN/CLAUDE.md" ]; then bad "setup wrote into the project folder"; else ok "nothing was written into the project folder (no README.md, team/ or CLAUDE.md)"; fi

  # --- The review: a verdict pinned to the head, then a Decision update that doesn't move it.
  run_in "$fxdir" "$NB" gh pr view 1 --json headRefOid --jq .headRefOid
  reviewed=$OUT
  same "headRefOid is the setup commit" "$reviewed" "$(other_git -C "$NB" rev-parse HEAD)"
  printf '## Review of PR #1: round 1 (%s)\n**Reviewed commit:** %s   **Tier:** full\n**Verdict:** READY TO MERGE\n**In plain English:** the setup files are complete.\n' "$who" "$reviewed" > "$work/verdict-$roster.md"
  must "$fxdir" "$NB" gh pr comment 1 --body-file "$work/verdict-$roster.md"
  must "$fxdir" "$NB" gh pr comment 1 --body "**Decision update:** Priya: \"keep the hours page plain\" (2026-10-12)."
  run_in "$fxdir" "$NB" gh pr view 1 --json comments --jq '.comments[].body'
  has "the verdict comment is on the PR" "$OUT" "^## Review of PR #1: round 1 \\($who\\)"
  has "the Decision update comment is on the PR" "$OUT" '^\*\*Decision update:\*\*'
  # The helper's prompt reads comments with exactly this command (roles/reviewer.md).
  run_in "$fxdir" "$NB" gh pr view 1 --comments
  has "gh pr view --comments shows each comment's author" "$OUT" '^author:[[:space:]]+priya-acme$'
  has "gh pr view --comments shows the verdict" "$OUT" "^## Review of PR #1: round 1 \\($who\\)"
  has "gh pr view --comments shows the Decision update" "$OUT" '^\*\*Decision update:\*\*'
  run_in "$fxdir" "$NB" gh pr view 1
  has "gh pr view shows the description" "$OUT" '^## Reviewer handoff$'
  run_in "$fxdir" "$NB" gh pr view 1 --json headRefOid,mergeable,state
  has "merge gate: the head is still the reviewed commit" "$OUT" "\"headRefOid\":\"$reviewed\""
  has "merge gate: the PR is open and mergeable" "$OUT" '"mergeable":"MERGEABLE","state":"OPEN"'

  # --- The human clicks Merge (the stand-in), then the notebook writer's after-merge steps.
  if bash "$root/tests/lib/fake-gh-merge" "$fxdir" 1 > "$work/merge.log" 2>&1; then ok "Priya merges PR #1 (squash)"; else bad "the merge failed:"; sed 's/^/      /' "$work/merge.log"; fi
  run_in "$fxdir" "$NB" gh pr view 1 --json state --jq .state
  same "PR #1 is MERGED" "$OUT" MERGED
  # The after-merge check compares the PR's head, never the merge commit (a squash gives main a new sha).
  run_in "$fxdir" "$NB" gh pr view 1 --json headRefOid,mergeCommit
  has "after the merge: the PR's headRefOid is still the reviewed commit" "$OUT" "\"headRefOid\":\"$reviewed\""
  run_in "$fxdir" "$NB" gh pr view 1 --json mergeCommit --jq .mergeCommit.oid
  merged=$OUT
  if [ -n "$merged" ] && [ "$merged" != "$reviewed" ]; then ok "the squash merge gave main a new sha, which is expected (not a finding)"; else bad "the merge commit should differ from the reviewed commit (got \"$merged\")"; fi
  same "the notebook folder still says the setup branch (so the role file asks gh, not the branch name)" "$(other_git -C "$NB" branch --show-current)" "$BRANCH"
  run_in "$fxdir" "$NB" git status --short
  same "the notebook folder is clean before the switch" "$OUT" ''
  must "$fxdir" "$NB" git fetch --prune origin
  must "$fxdir" "$NB" git switch --detach origin/main
  must "$fxdir" "$NB" git branch -D "$BRANCH"
  same "the notebook folder holds no branch" "$(other_git -C "$NB" branch --show-current)" ''
  must "$fxdir" "$MAIN" git show origin/main:team/assemble.json
  if bash "$root/scripts/check-output.sh" "$NB" > "$work/co.log" 2>&1; then ok "check-output passes on the merged notebook folder"; else bad "check-output failed after the merge:"; sed 's/^/      /' "$work/co.log"; fi
  ignored=.env
  [ "$fixture" = empty-dir ] || ignored=".env dev.pem video.raw .DS_Store notes/.DS_Store"
  for f in $ignored; do
    if other_git -C "$NB" check-ignore -q "$f"; then ok "the merged .gitignore ignores $f"; else bad "the merged .gitignore doesn't ignore $f"; fi
  done

  # --- Priya's own git pull in her folder (the closing message asks her; no chat runs it).
  other_git -c "url.$fxdir/remotes/.insteadOf=https://github.com/" -C "$MAIN" pull -q --ff-only origin main
  same "after Priya's git pull, her folder is clean (the left-out files are ignored)" "$(other_git -C "$MAIN" status --porcelain | tr '\n' ' ')" ''
  if [ -f "$MAIN/CLAUDE.md" ] && [ -f "$MAIN/team/assemble.json" ]; then ok "after the pull, her folder has CLAUDE.md and team/"; else bad "after the pull, CLAUDE.md or team/ is missing in her folder"; fi

  # --- A notebook write: sync, edit, commit with explicit paths, push to main.
  must "$fxdir" "$NB" bash -c 'git fetch origin || git fetch origin'
  must "$fxdir" "$NB" git rebase --autostash origin/main
  awk -v e="## 2026-10-12 · Cyrus (Chief) · Merged PR #1" '{ print } index($0, "<!-- new entries go directly below this line -->") { print e; print "Merged PR #1 (setup)." }' \
    "$NB/team/LOG.md" > "$work/log.tmp" && mv "$work/log.tmp" "$NB/team/LOG.md"
  must "$fxdir" "$NB" git add -- team/LOG.md
  must "$fxdir" "$NB" git commit -m "notes: merged setup PR #1 [skip ci]" -- team/LOG.md
  must "$fxdir" "$NB" git push origin HEAD:main
  same "GitHub's main has the note" "$(other_git --git-dir="$fxdir/remotes/$REPO.git" rev-parse refs/heads/main)" "$(other_git -C "$NB" rev-parse HEAD)"

  # --- A rejected push: someone else merged first; sync and push again.
  other="$work/other-$fixture-$roster"
  other_git clone -q "$fxdir/remotes/$REPO.git" "$other"
  printf 'hours: Saturday 10-14\n' > "$other/hours.txt"
  other_git -C "$other" add -- hours.txt
  other_git -C "$other" commit -q -m "Add the hours" -- hours.txt
  other_git -C "$other" push -q origin HEAD:main
  printf -- '- [ ] T4 · A map to the stall · [track: page] · Bram · done when a friend finds it · (proposal)\n' >> "$NB/team/TASKS.md"
  must "$fxdir" "$NB" git add -- team/TASKS.md
  must "$fxdir" "$NB" git commit -m "notes: T4 proposed [skip ci]" -- team/TASKS.md
  run_in "$fxdir" "$NB" git push origin HEAD:main
  if [ "$RC" != 0 ]; then ok "the push is rejected while main has moved"; else bad "the push should have been rejected"; fi
  must "$fxdir" "$NB" bash -c 'git fetch origin || git fetch origin'
  must "$fxdir" "$NB" git rebase --autostash origin/main
  must "$fxdir" "$NB" git push origin HEAD:main
  run_in "$fxdir" "$NB" git log --format=%s origin/main
  has "main has the other commit" "$OUT" '^Add the hours$'
  has "main has the note after the retry" "$OUT" '^notes: T4 proposed \[skip ci\]$'

  # --- The Builder's own worktree (claude -w bram), then step 0. push.default=upstream is the trap
  #     --no-track prevents; worktree-bram itself tracks origin/main, which is why nobody commits on it.
  must "$fxdir" "$NB" bash -c "git -C \"$MAIN\" fetch origin || git -C \"$MAIN\" fetch origin"
  must "$fxdir" "$NB" git -C "$MAIN" config push.default upstream
  wt="$MAIN/.claude/worktrees/bram"
  other_git -C "$MAIN" worktree add -q -b worktree-bram "$wt" origin/main
  same "claude -w's own branch tracks origin/main (the trap step 0 steps off)" "$(other_git -C "$wt" rev-parse --abbrev-ref 'worktree-bram@{upstream}')" origin/main
  must "$fxdir" "$wt" bash -c '(git fetch origin || git fetch origin) && git switch --no-track -c bram/T1-readiness origin/main'
  must_rc 128 "$fxdir" "$wt" git rev-parse --abbrev-ref '@{u}'
  printf '# Plan: Acme\n\n## Goal and done-when\n- Goal: the page.\n' > "$wt/team/PLAN.md"
  must "$fxdir" "$wt" git add -- team/PLAN.md
  must "$fxdir" "$wt" git commit -m "T1: draft team/PLAN.md" -- team/PLAN.md
  main_before=$(other_git --git-dir="$fxdir/remotes/$REPO.git" rev-parse refs/heads/main)
  must "$fxdir" "$wt" git push -u origin HEAD
  same "the task branch is on GitHub" "$(other_git --git-dir="$fxdir/remotes/$REPO.git" rev-parse refs/heads/bram/T1-readiness)" "$(other_git -C "$wt" rev-parse HEAD)"
  same "the task push didn't touch main" "$(other_git --git-dir="$fxdir/remotes/$REPO.git" rev-parse refs/heads/main)" "$main_before"
  lacks "the user's checkout doesn't show the Builder's worktree" "$(other_git -C "$MAIN" status --porcelain --untracked-files=all)" '\.claude'
  must "$fxdir" "$wt" gh pr create --base main --head bram/T1-readiness --title "T1: build-readiness note and PLAN.md" --body "T1."
  same "the task PR is #2" "$(printf '%s\n' "$OUT" | tail -n 1)" "https://github.com/$REPO/pull/2"
  if bash "$root/tests/lib/fake-gh-merge" "$fxdir" 2 > "$work/merge.log" 2>&1; then ok "Priya merges PR #2"; else bad "the merge of PR #2 failed:"; sed 's/^/      /' "$work/merge.log"; fi
  # The Builder's after-merge commands (roles/builder.md), then the old worktree-bram branch.
  must "$fxdir" "$wt" bash -c 'git fetch --prune origin && git switch --detach origin/main && git branch -D bram/T1-readiness'
  must "$fxdir" "$wt" git branch -D worktree-bram
  same "the Builder's worktree holds no branch until its next step 0" "$(other_git -C "$wt" branch --show-current)" ''
  must "$fxdir" "$MAIN" git show origin/main:team/PLAN.md

  # --- A rebase conflict stops the write with a clean folder.
  must "$fxdir" "$NB" bash -c 'git fetch origin || git fetch origin'
  must "$fxdir" "$NB" git rebase --autostash origin/main
  other_git -C "$other" pull -q --ff-only origin main
  sed 's/^Merged PR #1 (setup)\.$/Merged PR #1 (setup), said the other clone./' "$other/team/LOG.md" > "$work/l" && mv "$work/l" "$other/team/LOG.md"
  sed 's/^Merged PR #1 (setup)\.$/Merged PR #1 (setup), said Cyrus./' "$NB/team/LOG.md" > "$work/l" && mv "$work/l" "$NB/team/LOG.md"
  must "$fxdir" "$NB" git add -- team/LOG.md
  must "$fxdir" "$NB" git commit -m "notes: reword [skip ci]" -- team/LOG.md
  local_note=$(other_git -C "$NB" rev-parse HEAD)
  other_git -C "$other" commit -q -m "notes: reword elsewhere" -- team/LOG.md
  other_git -C "$other" push -q origin HEAD:main
  run_in "$fxdir" "$NB" git push origin HEAD:main
  if [ "$RC" != 0 ]; then ok "the conflicting push is rejected"; else bad "the conflicting push should have been rejected"; fi
  must "$fxdir" "$NB" bash -c 'git fetch origin || git fetch origin'
  run_in "$fxdir" "$NB" git rebase --autostash origin/main
  if [ "$RC" != 0 ]; then ok "the sync stops on the conflict"; else bad "the rebase should have conflicted"; fi
  must "$fxdir" "$NB" git rebase --abort
  run_in "$fxdir" "$NB" git status --short
  same "after git rebase --abort the notebook folder is clean" "$OUT" ''
  same "the unpushed note is still on HEAD" "$(other_git -C "$NB" rev-parse HEAD)" "$local_note"

  if [ -e "$MAIN/REPO-SCRIPT-RAN" ]; then bad "a project script ran (REPO-SCRIPT-RAN exists)"; else ok "no project script ran"; fi
  calls_clean "$fxdir"
}

for fixture in empty-dir files-no-git; do
  for roster in small standard; do
    run_case "$fixture" "$roster"
  done
done

echo
echo "== Cancel at the write screen: reads only, nothing written"
for fixture in empty-dir files-no-git; do
  fxdir="$work/cancel-$fixture"
  if build "$fixture" "$fxdir"; then
    must "$fxdir" "$fxdir/acme" gh auth status
    must_rc 1 "$fxdir" "$fxdir/acme" gh repo view "$REPO" --json name
    must "$fxdir" "$fxdir/acme" gh api user --jq '.id, .login, .name'
    untouched "$fxdir" 0
  fi
done

echo
echo "== Guards: writes before the gate, and rule-breaking writes after it, are refused"
fxdir="$work/guards"
if build empty-dir "$fxdir"; then
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  m="$fxdir/acme"
  must_rc 1 "$fxdir" "$m" git init -b main
  must_rc 1 "$fxdir" "$m" gh auth setup-git
  must_rc 1 "$fxdir" "$m" gh repo create "$REPO" --private --source . --remote origin --push
  same "no repo was made before the gate" "$( [ -e "$fxdir/remotes" ] && echo made || echo none)" none
  : > "$fxdir/write-screen-approved"
  must "$fxdir" "$m" git init -b main
  must "$fxdir" "$m" git config user.name "$NAME"
  must "$fxdir" "$m" git config user.email "$EMAIL"
  printf 'x\n' > "$m/x.txt"
  must_rc 1 "$fxdir" "$m" git add -A
  must_rc 1 "$fxdir" "$m" git add .
  must "$fxdir" "$m" git add -- x.txt
  must_rc 1 "$fxdir" "$m" git commit -m "no paths"
  must_rc 1 "$fxdir" "$m" git commit -a -m "all"
  must "$fxdir" "$m" git commit -m "x" -- x.txt
  must_rc 1 "$fxdir" "$m" gh repo create "$REPO" --public --source . --remote origin
  must_rc 1 "$fxdir" "$m" gh repo create "someone-else/acme" --private --source . --remote origin
  must "$fxdir" "$m" gh repo create "$REPO" --private --source . --remote origin --push
  must_rc 1 "$fxdir" "$m" gh repo create "$REPO" --private
  must_rc 1 "$fxdir" "$m" git push
  must_rc 1 "$fxdir" "$m" git push origin
  must_rc 1 "$fxdir" "$m" git push --force origin HEAD
  must_rc 1 "$fxdir" "$m" git push --no-verify origin HEAD
  must_rc 1 "$fxdir" "$m" git worktree add -b guard/x "$fxdir/x" origin/main
  must_rc 1 "$fxdir" "$m" git switch -c guard/y origin/main
  must_rc 1 "$fxdir" "$m" git checkout -b guard/z
  must_rc 1 "$fxdir" "$m" git branch guard/w origin/main
  must_rc 1 "$fxdir" "$m" git branch --track guard/v origin/main
  must_rc 1 "$fxdir" "$m" git config --global user.name Someone
  must_rc 1 "$fxdir" "$m" git stash
  must_rc 1 "$fxdir" "$m" git reset --hard HEAD
  must "$fxdir" "$m" git switch --no-track -c guard/ok origin/main
  printf 'y\n' > "$m/y.txt"
  must "$fxdir" "$m" git add -- y.txt
  must "$fxdir" "$m" git commit -m "y" -- y.txt
  must "$fxdir" "$m" git push -u origin HEAD
  must "$fxdir" "$m" gh pr create --base main --head guard/ok --title "Guard" --body "x"
  must_rc 1 "$fxdir" "$m" gh pr merge 1 --squash
  must_rc 1 "$fxdir" "$m" gh pr review 1 --approve
  must_rc 1 "$fxdir" "$m" gh pr close 1 --delete-branch
  run_in "$fxdir" "$m" gh pr view 1 --json state --jq .state
  same "the guarded PR is still open (nothing merged or closed it)" "$OUT" OPEN
  n=$(grep -c '^REFUSED ' "$fxdir/calls.log" || true)
  same "every refusal is logged as REFUSED (3 before the gate, 21 after)" "$n" 24
fi

echo
if [ "$fails" -eq 0 ]; then
  echo "new-path-test: all $checks checks passed"
else
  echo "new-path-test: $fails of $checks checks failed"
  exit 1
fi
