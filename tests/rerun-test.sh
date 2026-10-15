#!/usr/bin/env bash
# rerun-test.sh: run the re-run commands of skills/assemble/reference/rerun.md end to end, offline,
# on the three re-run fixtures (already-set-up, open-setup-pr, setup-leftovers). No Claude session is
# needed: this script plays the chat that follows rerun.md (and preflight.md part C), then the
# reviewer and the human, and checks what lands where. Commands are the ones the skill text prints,
# with the same flags, in the same order.
#
# Covered:
#   - the Reviewer flag flip (C6, D5): the "before" renderings of CHATS.md, the Chief's and the
#     Builder's role files and reviewer.md are exactly the hand-rendered Small example; the "after"
#     role files are exactly the Standard example's (CHATS.md differs from it only in the duty
#     lines); the line differences apply as a patch, both ways; a Reviewer added after setup (C6
#     step 4) has no setup PR in its first session;
#   - A, continue an open setup PR: the notebook folder present, deleted by hand, and on a fresh clone;
#     "close it and start over" and its cleanup; "leave it and stop" changes nothing;
#   - preflight part C check 3, setup leftovers: found, "leave them" changes nothing, cleaned up
#     (a locked worktree, a local branch, a branch on GitHub), also when the folder was deleted by hand;
#   - B, the team is read from the default branch (the repo is `origin`'s, and the manifest agrees);
#     the update check (a 404, and a newer release);
#   - E, check: clean on the fixture, every seeded problem found; repair through a PR on
#     assemble/repair-<stamp>, then clean again; E1 searches only the files setup wrote (the user's
#     own CI workflow, with a template expression and a runner path in it, comes out clean); E2b,
#     setup branches and re-run branches (with their working copies) left beside a team and their
#     repairs, no --force; a retry of an Add that stopped never collides with the leftover (B4 step
#     2); the CHATS.md owner row copied from the template; B4's self-check run after the add, so a
#     new or stray file shows; the PR body is scanned before it goes to GitHub;
#   - C, add a Designer and a role of the user's own: the next decision ID skips one a pending briefing
#     holds (B1); the Add PR holds only the role file, the user's
#     checkout and the notebook folder are untouched while it is open, the merge, F (cleanup, sync,
#     notes, check);
#   - D, retire a chat: the handover, the RETIRED banner PR, the notes;
#   - the shims refuse nothing the skill text says to do (no REFUSED line), and refuse a rule-breaking
#     write before the approval.
#
# Usage: tests/rerun-test.sh [--keep]      (--keep leaves the scratch folder in place)
# Exit:  0 = every check passed, 1 = at least one failed.
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
LC_ALL=C
export LC_ALL
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
keep=no
[ "${1:-}" != --keep ] || keep=yes
work=$(mktemp -d "${TMPDIR:-/tmp}/assemble-rerun.XXXXXX")
work=$(CDPATH= cd -- "$work" && pwd -P)
if [ "$keep" = yes ]; then echo "scratch folder: $work"; else trap 'rm -rf "$work"' EXIT; fi
REAL_GIT=$(command -v git)
tdir="$root/skills/assemble/templates"

REPO=priya-acme/acme
NAME='Priya Example'
EMAIL='12345678+priya-acme@users.noreply.github.com'
SETUP_BRANCH=assemble/setup-20261012-1435
# The home-folder patterns of rerun.md B4 and E1, written the way the skill prints them.
HOMEPAT='/Us[e]rs/|/ho[m]e/|[A-Za-z]:\\+Us[e]rs'
# A made-up home-folder path for the seeded problem, split so this file never holds one.
FAKEHOME='/Us''ers/someone/acme'

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
must() {
  run_in "$@"
  shift 2
  if [ "$RC" = 0 ]; then ok "$*"; else bad "\"$*\" exited $RC"; show; fi
}
must_rc() {
  want=$1
  shift
  run_in "$@"
  shift 2
  if [ "$RC" = "$want" ]; then ok "\"$*\" exits $want"; else bad "\"$*\" exited $RC, expected $want"; show; fi
}
same() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1: got \"$2\", expected \"$3\""; fi; }
has() { if printf '%s\n' "$2" | grep -Eq -- "$3"; then ok "$1"; else bad "$1: no \"$3\" in:"; printf '%s\n' "$2" | sed 's/^/      | /'; fi; }
lacks() { if printf '%s\n' "$2" | grep -Eq -- "$3"; then bad "$1: found \"$3\" in:"; printf '%s\n' "$2" | sed 's/^/      | /'; else ok "$1"; fi; }
# The real git on a fixture's files, outside the shims (Priya in her own checkout, or other people).
other_git() {
  env HOME="$fxdir/git-home" GIT_CONFIG_GLOBAL="$fxdir/git-home/.gitconfig" GIT_CONFIG_NOSYSTEM=1 \
    GIT_TERMINAL_PROMPT=0 GIT_CEILING_DIRECTORIES="$work" \
    "$REAL_GIT" -c user.name="$NAME" -c user.email="$EMAIL" "$@"
}
# bare_git ARGS...: the real git on the fake GitHub's bare repo of the project.
bare_git() { other_git --git-dir="$fxdir/remotes/$REPO.git" "$@"; }
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
no_call() { # no_call FOLDER PATTERN WHAT: calls.log has no line matching PATTERN
  if grep -Eq -- "$2" "$1/calls.log"; then bad "$3: found a call matching \"$2\":"; grep -E -- "$2" "$1/calls.log" | sed 's/^/      /'; else ok "$3"; fi
}
# The exclude command, exactly as git-model.md D4 prints it, with <MAIN> filled in.
exclude_cmd() {
  printf '( cd "%s" && f="$(git rev-parse --git-path info/exclude)" && mkdir -p "$(dirname "$f")" && { grep -qxF '"'"'.claude/worktrees/'"'"' "$f" 2>/dev/null || printf '"'"'%%s\\n'"'"' '"'"'.claude/worktrees/'"'"' >> "$f"; } )' "$1"
}
# open_gate / close_gate: the human's approval (the tester touches the file while the screen is up).
open_gate() { : > "$fxdir/write-screen-approved"; }
close_gate() { rm -f "$fxdir/write-screen-approved"; }

# render FLAGS VARS TEMPLATE: print TEMPLATE filled in as PLACEHOLDERS.md "How to fill a template"
# says (the same filler as tests/templates-test.sh). FLAGS: the line flags that hold, space-separated.
# VARS: a file of NAME=value lines. A line that is only a {{BLOCK}} whose value is empty is dropped.
render() {
  awk -v flags=" $1 " '
    NR == FNR { i = index($0, "="); v[substr($0, 1, i - 1)] = substr($0, i + 1); next }
    {
      line = $0
      if (match(line, /^\{\{IF_[A-Z0-9_]+\}\}/)) {
        if (index(flags, " " substr(line, 3, RLENGTH - 4) " ") == 0) next
        line = substr(line, RLENGTH + 1)
      }
      if (match(line, /^\{\{[A-Z0-9_]+\}\}$/) && (substr(line, 3, RLENGTH - 4) in v) && v[substr(line, 3, RLENGTH - 4)] == "") next
      out = ""
      while ((i = index(line, "{{")) > 0) {
        rest = substr(line, i)
        if (match(rest, /^\{\{[A-Z0-9_]+\}\}/)) {
          n = substr(rest, 3, RLENGTH - 4)
          out = out substr(line, 1, i - 1) ((n in v) ? v[n] : substr(rest, 1, RLENGTH))
          line = substr(rest, RLENGTH + 1)
        } else {
          out = out substr(line, 1, i + 1)
          line = substr(rest, 3)
        }
      }
      print out line
    }' "$2" "$3"
}

# ---------------------------------------------------------------------------------------------
echo "== C6 and D5: the Reviewer flag flip is exactly the difference between the Small and Standard examples"
printf '%s\n' PROJECT=Acme HUMAN=Priya DATE=2026-10-12 STAMP=20261012-1435 SETUP_PR=1 VERSION=1.0.0 REPO=acme \
  DEFAULT_BRANCH=main NOTES_BRANCH=main REMOTE=priya-acme/acme WRITER=Cyrus REVIEWER=Vito ADOPTED_OWNER_ROWS= > "$work/vars-cyrus"
# rerun.md B1 says where each value is: DATE and VERSION in CHATS.md's second line, STAMP and SETUP_PR in
# the first LOG entry. Read them from the Small example and compare with the values used below.
small_team="$root/tests/rendered/acme-small/team"
std_team="$root/tests/rendered/acme/team"
same "B1: DATE and VERSION are in CHATS.md's second line" "$(sed -n '2s/^\*Set up \([0-9-]*\) with \/assemble \([0-9.]*\)\..*/\1 \2/p' "$small_team/CHATS.md")" '2026-10-12 1.0.0'
same "B1: STAMP and SETUP_PR are in the first LOG entry" "$(sed -n 's/^Done: team\/ and the CLAUDE.md block on assemble\/setup-\([0-9-]*\) (PR #\([0-9]*\))\./\1 \2/p' "$small_team/LOG.md")" '20261012-1435 1'
SMALL_FLAGS="IF_NO_REVIEWER IF_IN_REPO IF_NO_DUTIES"
STANDARD_FLAGS="IF_REVIEWER IF_IN_REPO IF_NO_DUTIES"
# no_duties FILE: the file without its "### Duties for this project" lines (the Standard example spends
# money, the Small one doesn't; the Reviewer flip never touches duties).
no_duties() { awk '/^### Duties for this project$/ { skip = 1; next } skip && /^## / { skip = 0 } !skip' "$1"; }
flip() { # flip TEMPLATE for the small (before) and the standard (after) renderings
  tpl=$1
  for which in small standard; do
    cp "$work/vars-cyrus" "$work/vars-$which"
    if [ "$which" = small ]; then flags=$SMALL_FLAGS; else flags=$STANDARD_FLAGS; fi
    case "$tpl" in
      roles/chief.md) printf '%s\n' NAME=Cyrus 'TITLE=Cyrus · Acme Chief' MODEL=Opus HANDLE=cyrus >> "$work/vars-$which" ;;
      roles/builder.md) printf '%s\n' NAME=Bram 'TITLE=Bram · Acme Builder' MODEL=Sonnet HANDLE=bram >> "$work/vars-$which" ;;
      roles/reviewer.md)
        if [ "$which" = small ]; then printf '%s\n' NAME=helper 'TITLE=Reviewer helper · Acme' MODEL=Opus HANDLE=helper >> "$work/vars-$which"
        else printf '%s\n' NAME=Vito 'TITLE=Vito · Acme Reviewer' MODEL=Opus HANDLE=vito >> "$work/vars-$which"; fi ;;
    esac
    render "$flags" "$work/vars-$which" "$tdir/$tpl" > "$work/$which.$(basename "$tpl")"
  done
  base=$(basename "$tpl")
  if diff -q "$work/small.$base" "$small_team/$tpl" > /dev/null; then ok "the 'before' rendering of $tpl is the Small example"; else bad "the 'before' rendering of $tpl is not the Small example"; diff "$work/small.$base" "$small_team/$tpl" | head -8 | sed 's/^/      | /'; fi
  if [ "$tpl" = CHATS.md ]; then
    if [ "$(no_duties "$work/standard.$base")" = "$(no_duties "$std_team/$tpl")" ]; then ok "the 'after' rendering of $tpl is the Standard example, duty lines aside"; else bad "the 'after' rendering of $tpl is not the Standard example (duty lines aside)"; fi
  elif diff -q "$work/standard.$base" "$std_team/$tpl" > /dev/null; then ok "the 'after' rendering of $tpl is the Standard example"; else bad "the 'after' rendering of $tpl is not the Standard example"; diff "$work/standard.$base" "$std_team/$tpl" | head -8 | sed 's/^/      | /'; fi
  # The line differences, applied to the current (Small) file, give the Standard file; and back.
  cp "$small_team/$tpl" "$work/cur.$base"
  diff -u "$work/small.$base" "$work/standard.$base" > "$work/fix.patch" || true
  if patch -s "$work/cur.$base" < "$work/fix.patch" > /dev/null 2>&1 && diff -q "$work/cur.$base" "$work/standard.$base" > /dev/null; then ok "$tpl: Small + the differences = Standard"; else bad "$tpl: the differences don't turn the Small file into the Standard file"; fi
  cp "$work/standard.$base" "$work/cur.$base"
  diff -u "$work/standard.$base" "$work/small.$base" > "$work/fix.patch" || true
  if patch -s "$work/cur.$base" < "$work/fix.patch" > /dev/null 2>&1 && diff -q "$work/cur.$base" "$small_team/$tpl" > /dev/null; then ok "$tpl: Standard + the differences = Small (D5)"; else bad "$tpl: the differences don't turn the Standard file into the Small file"; fi
}
flip CHATS.md
flip roles/chief.md
flip roles/builder.md
flip roles/reviewer.md
# C6 step 4: a Reviewer added after setup has no setup PR to review; its 'First session' steps 3 and 5 change.
rv="$root/tests/rendered/acme/team/roles/reviewer.md"
same "C6.4: the template's step 5 is one findable line in the Standard example" "$(grep -c '^5\. First job: review setup PR #' "$rv")" 1
same "C6.4: rerun.md gives the replacement" "$(grep -c 'First job: list the open PRs' "$root/skills/assemble/reference/rerun.md")" 1
NEW5='5. First job: list the open PRs (`gh pr list --state open`) and review the oldest one that has no verdict from a Reviewer yet. If none is open, tell Cyrus you are ready and wait for the next doorbell. Then propose checklist tailoring to Cyrus. A PR that has merged is never reviewed again here.'
awk -v n="$NEW5" '/^5\. First job: review setup PR #/ { print n; next } { sub(/starting the setup PR review\./, "ready for its first PR."); print }' "$rv" > "$work/reviewer-later.md"
same "C6.4: exactly two lines change (step 3's message and step 5)" "$(diff "$rv" "$work/reviewer-later.md" | grep -c '^<')" 2
lacks "C6.4: no setup PR is left in the Reviewer's first session" "$(sed -n '/^## First session/,/^## How you work/p' "$work/reviewer-later.md")" 'setup PR|merged with no verdict'
lacks "C6.4: and no placeholder" "$(cat "$work/reviewer-later.md")" '\{\{'

# ---------------------------------------------------------------------------------------------
echo
echo "== A: continue an open setup PR (open-setup-pr)"
# preflight part C, check 1 (reads only), then rerun.md part A.
setup_pr_reads() { # setup_pr_reads: the reads preflight makes, on the fixture in $fxdir
  must "$fxdir" "$MAIN" git fetch origin
  run_in "$fxdir" "$MAIN" gh pr list --repo "$REPO" --state open --json number,headRefName,url,author --limit 100
  has "preflight check 1 sees setup PR #1 (head, and who opened it)" "$OUT" "\"headRefName\":\"$SETUP_BRANCH\".*\"author\":\\{\"login\":\"priya-acme\"\\}|\"author\":\\{\"login\":\"priya-acme\"\\}.*\"headRefName\":\"$SETUP_BRANCH\""
  must_rc 1 "$fxdir" "$MAIN" gh repo view "$REPO-team" --json name,defaultBranchRef
  must_rc 128 "$fxdir" "$MAIN" git show origin/main:team/assemble.json
}
fxdir="$work/open-setup-pr"
if build open-setup-pr "$fxdir"; then
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  MAIN="$fxdir/acme"
  NB="$fxdir/acme-team"
  setup_pr_reads
  untouched "$fxdir" 0

  # Part A step 1, then the folder is where it should be (step 2, first bullet).
  run_in "$fxdir" "$MAIN" gh pr view 1 --repo "$REPO" --json state,headRefName,headRefOid,author
  has "A1: the PR is OPEN" "$OUT" '"state":"OPEN"'
  head=$(printf '%s\n' "$OUT" | sed -n 's/.*"headRefOid":"\([0-9a-f]*\)".*/\1/p')
  run_in "$fxdir" "$MAIN" git worktree list --porcelain
  has "A2: the notebook folder is listed" "$OUT" "^worktree $NB\$"
  lacks "A2: and it is not prunable" "$OUT" '^prunable'
  same "A2: it is on the PR's branch" "$(other_git -C "$NB" branch --show-current)" "$SETUP_BRANCH"
  same "A2: and clean" "$(other_git -C "$NB" status --short)" ''
  same "A3: its HEAD is the PR's head" "$(other_git -C "$NB" rev-parse HEAD)" "$head"
  open_gate
  must "$fxdir" "$fxdir" bash -c "$(exclude_cmd "$MAIN")"
  must "$fxdir" "$fxdir" bash -c "$(exclude_cmd "$MAIN")"
  same "A4: the exclude line is there exactly once" "$(grep -cx '\.claude/worktrees/' "$MAIN/.git/info/exclude")" 1
  # A5: the kickoff paths exist (the printed steps name them).
  for f in CHATS.md roles/chief.md roles/reviewer.md roles/builder.md ROSTER.md; do
    if [ -f "$NB/team/$f" ]; then ok "A5: $NB/team/$f exists, so the kickoff path is real"; else bad "A5: team/$f is missing in the notebook folder"; fi
  done
  no_call "$fxdir" '^gh pr create' "Continue it opens no second setup PR"
  same "the user's checkout is untouched (branch, commit)" "$(other_git -C "$MAIN" symbolic-ref HEAD) $(other_git -C "$MAIN" log -1 --format=%s)" 'refs/heads/main Add the first page'
  calls_clean "$fxdir"
fi

echo
echo "== A: the notebook folder was deleted by hand (prunable)"
fxdir="$work/open-pruned"
if build open-setup-pr "$fxdir"; then
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  MAIN="$fxdir/acme"
  NB="$fxdir/acme-team"
  head=$(other_git -C "$MAIN" rev-parse "origin/$SETUP_BRANCH")
  rm -rf "$NB"
  run_in "$fxdir" "$MAIN" git worktree list --porcelain
  has "git marks the deleted notebook folder prunable" "$OUT" '^prunable'
  open_gate
  must "$fxdir" "$MAIN" git -C "$MAIN" worktree prune
  run_in "$fxdir" "$MAIN" git -C "$MAIN" branch --list "$SETUP_BRANCH"
  has "the local setup branch is still there" "$OUT" "$SETUP_BRANCH"
  must "$fxdir" "$MAIN" git -C "$MAIN" worktree add "$NB" "$SETUP_BRANCH"
  same "A3: the recreated folder is at the PR's head" "$(other_git -C "$NB" rev-parse HEAD)" "$head"
  same "and clean, on the setup branch" "$(other_git -C "$NB" status --short)$(other_git -C "$NB" branch --show-current)" "$SETUP_BRANCH"
  calls_clean "$fxdir"
fi

echo
echo "== A: a fresh clone (no notebook folder, no local setup branch)"
fxdir="$work/open-clone"
if build open-setup-pr "$fxdir"; then
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  head=$(bare_git rev-parse "refs/heads/$SETUP_BRANCH")
  mkdir "$fxdir/other"
  MAIN="$fxdir/other/acme"
  NB="$fxdir/other/acme-team"
  other_git clone -q "$fxdir/remotes/$REPO.git" "$MAIN"
  other_git -C "$MAIN" remote set-url origin "https://github.com/$REPO.git"
  other_git -C "$MAIN" config user.name "$NAME"
  other_git -C "$MAIN" config user.email "$EMAIL"
  run_in "$fxdir" "$MAIN" git worktree list --porcelain
  same "only the clone itself is a worktree" "$(printf '%s\n' "$OUT" | grep -c '^worktree ')" 1
  open_gate
  must "$fxdir" "$MAIN" git -C "$MAIN" fetch origin
  run_in "$fxdir" "$MAIN" git -C "$MAIN" branch --list "$SETUP_BRANCH"
  same "no local setup branch yet" "$OUT" ''
  must "$fxdir" "$MAIN" git -C "$MAIN" worktree add --no-track -b "$SETUP_BRANCH" "$NB" "origin/$SETUP_BRANCH"
  same "A3: the new notebook folder is at the PR's head" "$(other_git -C "$NB" rev-parse HEAD)" "$head"
  must_rc 128 "$fxdir" "$NB" git rev-parse --abbrev-ref '@{u}'
  must "$fxdir" "$fxdir" bash -c "$(exclude_cmd "$MAIN")"
  same "the exclude line is in the clone" "$(grep -cx '\.claude/worktrees/' "$MAIN/.git/info/exclude")" 1
  calls_clean "$fxdir"
fi

echo
echo "== A: 'Close it and start over' (never --delete-branch), then the leftovers it leaves"
fxdir="$work/open-close"
if build open-setup-pr "$fxdir"; then
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  MAIN="$fxdir/acme"
  NB="$fxdir/acme-team"
  open_gate
  must "$fxdir" "$MAIN" gh pr close 1 --repo "$REPO"
  run_in "$fxdir" "$MAIN" gh pr view 1 --repo "$REPO" --json state --jq .state
  same "the PR is CLOSED" "$OUT" CLOSED
  run_in "$fxdir" "$MAIN" gh pr list --repo "$REPO" --state open --json number,headRefName,url,author --limit 100
  same "check 1 now finds no open setup PR" "$OUT" '[]'
  # check 3 finds the folder, the local branch and the branch on GitHub; the cleanup runs them in order.
  run_in "$fxdir" "$MAIN" git worktree list --porcelain
  has "check 3 finds the notebook folder as a worktree on a setup branch" "$OUT" "^branch refs/heads/$SETUP_BRANCH\$"
  must "$fxdir" "$MAIN" git -C "$MAIN" worktree remove "$NB"
  must "$fxdir" "$MAIN" git -C "$MAIN" branch -D "$SETUP_BRANCH"
  must "$fxdir" "$MAIN" gh api -X DELETE "repos/$REPO/git/refs/heads/$SETUP_BRANCH"
  run_in "$fxdir" "$MAIN" git -C "$MAIN" ls-remote --heads origin "assemble/setup-*"
  same "nothing is left on GitHub" "$OUT" ''
  run_in "$fxdir" "$MAIN" git -C "$MAIN" branch --list "assemble/setup-*"
  same "nothing is left on this computer" "$OUT" ''
  no_call "$fxdir" '^git push' "the cleanup never runs git push (the repo's own hooks)"
  calls_clean "$fxdir"
fi

echo
echo "== A: 'Leave it and stop' changes nothing"
fxdir="$work/open-leave"
if build open-setup-pr "$fxdir"; then
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  MAIN="$fxdir/acme"
  setup_pr_reads
  untouched "$fxdir" 0
fi

echo
echo "== preflight check 3: setup leftovers (setup-leftovers)"
leftover_reads() {
  must "$fxdir" "$MAIN" git fetch origin
  run_in "$fxdir" "$MAIN" gh pr list --repo "$REPO" --state open --json number,headRefName,url,author --limit 100
  same "check 1: no open setup PR" "$OUT" '[]'
  must_rc 1 "$fxdir" "$MAIN" gh repo view "$REPO-team" --json name,defaultBranchRef
  must_rc 128 "$fxdir" "$MAIN" git show origin/main:team/assemble.json
  must_rc 128 "$fxdir" "$MAIN" git show origin/main:_team/assemble.json
  run_in "$fxdir" "$MAIN" git worktree list --porcelain
  has "check 3: the notebook folder is a worktree on a setup branch" "$OUT" '^branch refs/heads/assemble/setup-20261010-0930$'
  has "check 3: and it is locked" "$OUT" '^locked'
  run_in "$fxdir" "$MAIN" git branch --list "assemble/setup-*"
  has "check 3: a local setup branch" "$OUT" 'assemble/setup-20261010-0930'
  run_in "$fxdir" "$MAIN" git ls-remote --heads origin "assemble/setup-*"
  has "check 3: a setup branch on GitHub" "$OUT" 'refs/heads/assemble/setup-20261010-0930'
}
fxdir="$work/leftovers-leave"
if build setup-leftovers "$fxdir"; then
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  MAIN="$fxdir/acme"
  leftover_reads
  untouched "$fxdir" 0
  must_rc 1 "$fxdir" "$MAIN" git -C "$MAIN" worktree unlock "$fxdir/acme-team"
  untouched "$fxdir" 1
fi

echo
echo "== preflight check 3: 'Clean up and start over'"
for variant in folder deleted; do
  fxdir="$work/leftovers-$variant"
  if build setup-leftovers "$fxdir"; then
    fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
    MAIN="$fxdir/acme"
    NB="$fxdir/acme-team"
    [ "$variant" = folder ] || { echo "-- the notebook folder was also deleted by hand"; rm -rf "$NB"; }
    if [ "$variant" = folder ]; then leftover_reads; fi
    open_gate
    # preflight.md part C check 3, commands 1, 4 and 5 in order (2 and 3 don't apply).
    must "$fxdir" "$MAIN" git -C "$MAIN" worktree unlock "$NB"
    must "$fxdir" "$MAIN" git -C "$MAIN" worktree remove "$NB"
    must "$fxdir" "$MAIN" git -C "$MAIN" branch -D assemble/setup-20261010-0930
    must "$fxdir" "$MAIN" gh api -X DELETE "repos/$REPO/git/refs/heads/assemble/setup-20261010-0930"
    # part C runs again from the top and finds nothing.
    run_in "$fxdir" "$MAIN" git worktree list --porcelain
    same "the worktree list is just the project" "$(printf '%s\n' "$OUT" | grep -c '^worktree ')" 1
    run_in "$fxdir" "$MAIN" git branch --list "assemble/setup-*"
    same "no local setup branch" "$OUT" ''
    run_in "$fxdir" "$MAIN" git ls-remote --heads origin "assemble/setup-*"
    same "no setup branch on GitHub" "$OUT" ''
    same "the user's checkout is untouched" "$(other_git -C "$MAIN" status --porcelain) $(other_git -C "$MAIN" symbolic-ref HEAD)" ' refs/heads/main'
    no_call "$fxdir" '^git push' "the cleanup never runs git push"
    calls_clean "$fxdir"
  fi
done

# ---------------------------------------------------------------------------------------------
# File helpers for the notes the notebook writer writes (rerun.md part F).
insert_after() { # insert_after FILE MATCH NEWLINE: add NEWLINE after the first line containing MATCH
  T=$2 N=$3 awk 'BEGIN { t = ENVIRON["T"]; n = ENVIRON["N"] } { print } !done && index($0, t) { print n; done = 1 } END { exit (done ? 0 : 3) }' "$1" > "$1.tmp" \
    && mv "$1.tmp" "$1" || { bad "insert_after: \"$2\" not found in $1"; rm -f "$1.tmp"; }
}
replace_line() { # replace_line FILE MATCH NEWLINE: replace the first line containing MATCH
  T=$2 N=$3 awk 'BEGIN { t = ENVIRON["T"]; n = ENVIRON["N"] } !done && index($0, t) { print n; done = 1; next } { print } END { exit (done ? 0 : 3) }' "$1" > "$1.tmp" \
    && mv "$1.tmp" "$1" || { bad "replace_line: \"$2\" not found in $1"; rm -f "$1.tmp"; }
}
drop_line() { # drop_line FILE MATCH: delete every line containing MATCH
  T=$2 awk 'BEGIN { t = ENVIRON["T"] } index($0, t) { next } { print }' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}
# sync_nb: the notebook writer's sync (git-model.md part F), in the notebook folder.
sync_nb() {
  must "$fxdir" "$NB" bash -c 'git fetch origin || git fetch origin'
  must "$fxdir" "$NB" git rebase --autostash origin/main
}
# notes_push MESSAGE PATH...: commit the notes with explicit paths and push them to main.
notes_push() {
  msg=$1
  shift
  must "$fxdir" "$NB" git add -- "$@"
  must "$fxdir" "$NB" git commit -m "$msg [skip ci]" -- "$@"
  must "$fxdir" "$NB" git push origin HEAD:main
}
# titles_of ROSTER_TEXT: the Address cells of the first table (before the first ## heading), one per line.
titles_of() {
  printf '%s\n' "$1" | awk '/^## / { exit } /^\|/ { n = split($0, c, "|"); a = c[3]; gsub(/^ +| +$/, "", a); if (a != "" && a != "(none)" && a !~ /^-+$/ && a != "Address (exact title)") print a }'
}
# checks_clean LABEL: the E1 checks that need no fixture knowledge, on the default branch, from $NB.
checks_clean() {
  must_rc 1 "$fxdir" "$NB" git grep -n -F '{{' origin/main -- team .github/pull_request_template.md
  must_rc 1 "$fxdir" "$NB" git grep -n -E "$HOMEPAT" origin/main -- team .github/pull_request_template.md
  run_in "$fxdir" "$NB" git show origin/main:CLAUDE.md
  same "$1: the CLAUDE.md block appears once" "$(printf '%s\n' "$OUT" | grep -c '<!-- assemble:begin')$(printf '%s\n' "$OUT" | grep -c '<!-- assemble:end -->')" 11
  # E1.7: the files every chat reads at session start (CHATS.md rule 1) are on the default branch.
  run_in "$fxdir" "$NB" git ls-tree -r --name-only origin/main -- team
  e17=''
  for f in README.md LESSONS.md ROSTER.md GLOSSARY.md LOG.md DECISIONS.md TASKS.md roles/chief.md roles/reviewer.md; do
    printf '%s\n' "$OUT" | grep -qxF -- "team/$f" || e17="$e17 team/$f"
  done
  same "$1: E1.7: the files rule 1 reads are on origin/main (missing:${e17:- none})" "$e17" ''
  if bash "$root/scripts/check-output.sh" "$NB" > "$work/co.log" 2>&1; then ok "$1: check-output passes on the notebook folder (owners, marker, placeholders, paths)"; else bad "$1: check-output failed on the notebook folder:"; sed 's/^/      /' "$work/co.log"; fi
}
ACME_VARS() { printf '%s\n' PROJECT=Acme HUMAN=Priya DATE=2026-10-12 STAMP=20261012-1435 SETUP_PR=1 VERSION=1.0.0 REPO=acme \
  DEFAULT_BRANCH=main NOTES_BRANCH=main REMOTE=priya-acme/acme WRITER=Cyrus REVIEWER=Vito ADOPTED_OWNER_ROWS=; }

# ---------------------------------------------------------------------------------------------
echo
echo "== B and E: the team is here (already-set-up): read it and check it, read-only"
fxdir="$work/team"
if build already-set-up "$fxdir"; then
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  MAIN="$fxdir/acme"
  NB="$fxdir/acme-team"
  # preflight part C: no open setup PR, no notebook repo, a manifest on main.
  must "$fxdir" "$NB" git fetch origin
  run_in "$fxdir" "$NB" gh pr list --repo "$REPO" --state open --json number,headRefName,url,author --limit 100
  same "preflight check 1: no open setup PR" "$OUT" '[]'
  must_rc 1 "$fxdir" "$NB" gh repo view "$REPO-team" --json name,defaultBranchRef
  must "$fxdir" "$NB" git show origin/main:team/assemble.json
  # B1, run from the notebook writer's folder (it shares the project's repository).
  run_in "$fxdir" "$NB" git worktree list --porcelain
  same "MAIN is the first worktree entry, also from the notebook folder" "$(printf '%s\n' "$OUT" | sed -n '1s/^worktree //p')" "$MAIN"
  run_in "$fxdir" "$NB" git show origin/main:team/assemble.json
  manifest_remote=$(printf '%s\n' "$OUT" | sed -n 's/.*"remote": "\(.*\)".*/\1/p')
  has "B1: mode is in-repo" "$OUT" '"mode": "in-repo"'
  run_in "$fxdir" "$NB" git remote get-url origin
  same "B1: origin gives <owner>/<name>, and the manifest's remote agrees" "$OUT" "https://github.com/$manifest_remote.git"
  run_in "$fxdir" "$NB" git show origin/main:team/assemble.json
  has "B1: the precious list is there" "$OUT" '"team/roles/\*\*"'
  run_in "$fxdir" "$NB" git show origin/main:team/ROSTER.md
  same "B1: the chats, from the first ROSTER table" "$(titles_of "$OUT" | tr '\n' '|')" 'Cyrus · Acme Chief|Vito · Acme Reviewer|Bram · Acme Builder|'
  writer=$(titles_of "$OUT" | grep -E ' Chief$' | sed 's/ ·.*//')
  same "B1: the notebook writer is the row ending in Chief" "$writer" Cyrus
  same "B1: there is a standing Reviewer" "$(titles_of "$OUT" | grep -c ' Reviewer$')" 1
  run_in "$fxdir" "$NB" git show origin/main:team/DECISIONS.md
  same "B1: the next decision ID" "D$(( $(printf '%s\n' "$OUT" | sed -n 's/^| D\([0-9]*\) .*/\1/p' | sort -n | tail -n 1) + 1 ))" D3
  # B2: the update check. No release in the fixture = 404 = "can't tell".
  must_rc 1 "$fxdir" "$NB" gh api repos/Hrixay/assemble/releases/latest --jq .tag_name
  # E1 to E4 on the clean fixture.
  checks_clean "E1"
  run_in "$fxdir" "$NB" git worktree list --porcelain
  has "E2: the notebook folder is listed" "$OUT" "^worktree $NB\$"
  lacks "E2: and not prunable" "$OUT" '^prunable'
  same "E2: not behind origin/main" "$(other_git -C "$NB" rev-list --count HEAD..origin/main)" 0
  same "(the fixture's notebook folder is clean and holds no branch)" "$(other_git -C "$NB" status --short)$(other_git -C "$NB" branch --show-current)" ''
  run_in "$fxdir" "$NB" git ls-tree -r --name-only origin/main
  lacks "E3: no deploy file on origin/main" "$OUT" '(^|/)(vercel\.json|netlify\.toml|wrangler\.toml|wrangler\.json|fly\.toml)$|^\.github/workflows/'
  must "$fxdir" "$NB" git check-ignore -q .env
  must "$fxdir" "$NB" git check-ignore -q .env.local
  run_in "$fxdir" "$NB" git ls-tree -r --name-only origin/main
  lacks "E4: no tracked key file" "$OUT" '(^|/)\.env($|\.[^e])|\.env\.local|\.pem$|\.key$|\.p12$|\.pfx$|id_rsa|id_ed25519|id_ecdsa'
  untouched "$fxdir" 0
  calls_clean "$fxdir"
  # B2 again, with a newer release: the Upgrade option and E5.
  printf "FIXTURE_LATEST_RELEASE='v2.0.0'\n" >> "$fxdir/fixture.conf"
  run_in "$fxdir" "$NB" gh api repos/Hrixay/assemble/releases/latest --jq .tag_name
  same "B2: the newest release is v2.0.0, so the menu offers Upgrade" "$OUT" v2.0.0
  latest=$(printf '%s' "$OUT" | sed 's/^v//')
  installed=$(tr -d ' \n' < "$root/skills/assemble/VERSION")
  same "E5: the release is newer than the installed skill ($installed)" "$(printf '%s\n%s\n' "$latest" "$installed" | sort -t. -k1,1n -k2,2n -k3,3n | tail -n 1)" "$latest"
fi

# ---------------------------------------------------------------------------------------------
echo
echo "== E1: the user's own CI workflow is not the team's file (already-set-up + a workflow with a template expression and a runner path)"
# rerun.md E1 searches only what setup wrote: <folder>, the CLAUDE.md block and .github/pull_request_template.md.
# A workflow is the user's: ${{ matrix.node }} and a runner's home path in it are normal and are never repaired.
fxdir="$work/e1ci"
if build already-set-up "$fxdir"; then
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  MAIN="$fxdir/acme"
  NB="$fxdir/acme-team"
  other="$fxdir/other"
  other_git clone -q "$fxdir/remotes/$REPO.git" "$other"
  mkdir -p "$other/.github/workflows"
  printf '%s\n' 'name: ci' 'on: [pull_request]' 'jobs:' '  test:' '    runs-on: ubuntu-24.04' '    strategy:' '      matrix:' '        node: [20, 22]' '    steps:' \
    '      - run: echo "node ${{ matrix.node }} in /ho''me/runner/work"' > "$other/.github/workflows/ci.yml"
  other_git -C "$other" add -- .github/workflows/ci.yml
  other_git -C "$other" commit -q -m "Add CI" -- .github/workflows/ci.yml
  other_git -C "$other" push -q origin HEAD:main
  must "$fxdir" "$NB" git fetch origin
  run_in "$fxdir" "$NB" git grep -n -F '{{' origin/main -- team .github
  has "(the fixture has teeth: searching all of .github would flag the workflow)" "$OUT" '\.github/workflows/ci\.yml'
  run_in "$fxdir" "$NB" git grep -n -E "$HOMEPAT" origin/main -- team .github
  has "(and its runner path too)" "$OUT" '\.github/workflows/ci\.yml'
  must_rc 1 "$fxdir" "$NB" git grep -n -F '{{' origin/main -- team .github/pull_request_template.md
  must_rc 1 "$fxdir" "$NB" git grep -n -E "$HOMEPAT" origin/main -- team .github/pull_request_template.md
  open_gate
  sync_nb
  close_gate
  if bash "$root/scripts/check-output.sh" "$NB" > "$work/co.log" 2>&1; then ok "E1: check-output passes too (it reads the same files), workflow and all"; else bad "E1: check-output failed on the user's workflow case:"; sed 's/^/      /' "$work/co.log"; fi
  calls_clean "$fxdir"
fi

# ---------------------------------------------------------------------------------------------
echo
echo "== E2b: setup branches left behind beside a team (already-set-up + two seeded branches)"
# Preflight check 3 only runs when there is no team, so rerun.md E2b is where these are found: a branch with no
# PR is a problem; one whose PR merged is harmless (click Delete branch); and the repairs never use git push.
fxdir="$work/e2b"
if build already-set-up "$fxdir"; then
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  MAIN="$fxdir/acme"
  NB="$fxdir/acme-team"
  LEFT=assemble/setup-20261010-0930
  MERGED_BR=$SETUP_BRANCH
  main_sha=$(bare_git rev-parse refs/heads/main)
  bare_git update-ref "refs/heads/$LEFT" "$main_sha"
  bare_git update-ref "refs/heads/$MERGED_BR" "$main_sha"
  other_git -C "$MAIN" branch --no-track "$LEFT" origin/main
  must "$fxdir" "$NB" git fetch origin
  run_in "$fxdir" "$NB" git branch --list 'assemble/setup-*'
  has "E2b: the leftover is on this computer" "$OUT" "$LEFT"
  run_in "$fxdir" "$NB" git ls-remote --heads origin 'assemble/setup-*'
  has "E2b: the leftover is on GitHub" "$OUT" "refs/heads/$LEFT"
  has "E2b: and so is the branch of the merged setup PR" "$OUT" "refs/heads/$MERGED_BR"
  run_in "$fxdir" "$NB" gh pr list --repo "$REPO" --state all --head "$LEFT" --json number,state
  same "E2b: the leftover has no PR at all: a problem" "$OUT" '[]'
  run_in "$fxdir" "$NB" gh pr list --repo "$REPO" --state all --head "$MERGED_BR" --json number,state
  has "E2b: the other one's PR is MERGED: harmless, click Delete branch" "$OUT" '"state":"MERGED"'
  run_in "$fxdir" "$NB" git worktree list --porcelain
  lacks "E2b: no worktree holds the leftover, so branch -D can run" "$OUT" "refs/heads/$LEFT"
  # The user says yes to the two repairs of E6 (the gate is the approval); the merged one is left alone.
  open_gate
  must "$fxdir" "$NB" git -C "$MAIN" branch -D "$LEFT"
  must "$fxdir" "$NB" gh api -X DELETE "repos/$REPO/git/refs/heads/$LEFT"
  close_gate
  run_in "$fxdir" "$NB" git ls-remote --heads origin 'assemble/setup-*'
  lacks "E2b: the leftover is gone from GitHub" "$OUT" "$LEFT"
  has "E2b: the merged PR's branch is untouched (the user clicks Delete branch)" "$OUT" "refs/heads/$MERGED_BR"
  run_in "$fxdir" "$NB" git branch --list 'assemble/setup-*'
  same "E2b: and from this computer" "$OUT" ''
  no_call "$fxdir" '^git push' "the repair never runs git push (the repo's own hooks)"
  calls_clean "$fxdir"
fi

echo
echo "== E2b and B4 step 2: a re-run that stopped leaves a working copy and a branch; a retry never collides, the check removes them"
# An Add for Dara stopped after step 3 (a working copy, no PR); an Add for Tess left a working copy with an unsaved file.
fxdir="$work/e2b-rerun"
if build already-set-up "$fxdir"; then
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  MAIN="$fxdir/acme"
  NB="$fxdir/acme-team"
  DARA_BR=assemble/add-dara-20261010-0800
  DARA_WT="$MAIN/.claude/worktrees/assemble-add-dara-20261010-0800"
  TESS_BR=assemble/add-tess-20261010-0900
  TESS_WT="$MAIN/.claude/worktrees/assemble-add-tess-20261010-0900"
  main_sha=$(bare_git rev-parse refs/heads/main)
  for br in "$DARA_BR" "$TESS_BR"; do bare_git update-ref "refs/heads/$br" "$main_sha"; done
  other_git -C "$MAIN" fetch -q "$fxdir/remotes/$REPO.git" "+refs/heads/assemble/*:refs/remotes/origin/assemble/*"
  other_git -C "$MAIN" worktree add -q --no-track -b "$DARA_BR" "$DARA_WT" origin/main
  other_git -C "$MAIN" worktree add -q --no-track -b "$TESS_BR" "$TESS_WT" origin/main
  printf 'unsaved\n' > "$TESS_WT/notes.txt"
  # B4 steps 1 and 2, for a retry of the Add for Dara, a few days later.
  RETRY_STAMP=20261014-0915
  RETRY_BR="assemble/add-dara-$RETRY_STAMP"
  RETRY_WT="$MAIN/.claude/worktrees/assemble-add-dara-$RETRY_STAMP"
  must "$fxdir" "$NB" git -C "$MAIN" fetch origin
  run_in "$fxdir" "$NB" git -C "$MAIN" ls-remote --heads origin "assemble/add-*"
  has "B4.2: the stopped run's branch is on GitHub" "$OUT" "refs/heads/$DARA_BR"
  lacks "B4.2: and the retry's branch name is free there" "$OUT" "refs/heads/$RETRY_BR"
  run_in "$fxdir" "$NB" git branch --list "assemble/add-*"
  has "B4.2: the stopped run's branch is on this computer" "$OUT" "$DARA_BR"
  lacks "B4.2: and the retry's branch name is free here" "$OUT" "$RETRY_BR"
  run_in "$fxdir" "$NB" git worktree list --porcelain
  has "B4.2: the list shows the earlier run's working copy" "$OUT" "^worktree $DARA_WT\$"
  lacks "B4.2: and the retry's folder is free" "$OUT" "^worktree $RETRY_WT\$"
  open_gate
  must "$fxdir" "$NB" git -C "$MAIN" worktree add --no-track -b "$RETRY_BR" "$RETRY_WT" origin/main
  same "B4.3: the retry has a folder of its own (an unstamped folder name would have collided)" "$(other_git -C "$RETRY_WT" branch --show-current)" "$RETRY_BR"
  must "$fxdir" "$NB" git -C "$MAIN" worktree remove "$RETRY_WT"
  must "$fxdir" "$NB" git -C "$MAIN" branch -D "$RETRY_BR"
  close_gate
  # E2b: both leftovers are found and have no PR.
  run_in "$fxdir" "$NB" git branch --list 'assemble/*'
  has "E2b: the local list holds the Dara run" "$OUT" "$DARA_BR"
  has "E2b: and the Tess run" "$OUT" "$TESS_BR"
  for br in "$DARA_BR" "$TESS_BR"; do
    run_in "$fxdir" "$NB" gh pr list --repo "$REPO" --state all --head "$br" --json number,state
    same "E2b: $br has no PR at all: a problem" "$OUT" '[]'
  done
  run_in "$fxdir" "$NB" git worktree list --porcelain
  has "E2b: a worktree holds the Dara branch (a re-run working copy, so it is removable)" "$OUT" "^branch refs/heads/$DARA_BR\$"
  # E6, after the yes: remove the clean one; git refuses the one with an unsaved file and it is left alone (never --force).
  open_gate
  must "$fxdir" "$NB" git -C "$MAIN" worktree remove "$DARA_WT"
  must "$fxdir" "$NB" git -C "$MAIN" branch -D "$DARA_BR"
  must "$fxdir" "$NB" gh api -X DELETE "repos/$REPO/git/refs/heads/$DARA_BR"
  run_in "$fxdir" "$NB" git -C "$MAIN" worktree remove "$TESS_WT"
  if [ "$RC" != 0 ]; then ok "E6: git refuses to remove the working copy that holds an unsaved file"; else bad "E6: git removed a working copy that held an unsaved file"; fi
  if [ -f "$TESS_WT/notes.txt" ]; then ok "E6: and the file is still there (the skill shows git's message and leaves it)"; else bad "E6: the unsaved file is gone"; fi
  close_gate
  run_in "$fxdir" "$NB" git -C "$MAIN" ls-remote --heads origin "assemble/add-*"
  lacks "E6: the Dara branch is gone from GitHub" "$OUT" "$DARA_BR"
  no_call "$fxdir" '^git push' "the repairs never run git push"
  no_call "$fxdir" 'worktree remove .*--force' "and never pass --force"
  calls_clean "$fxdir"
fi

# ---------------------------------------------------------------------------------------------
echo
echo "== E: every seeded problem is found, and one repair PR plus notebook commits clear them (repair)"
fxdir="$work/repair"
if build already-set-up "$fxdir"; then
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  MAIN="$fxdir/acme"
  NB="$fxdir/acme-team"
  # Other people (and time) leave the team files in a worse state on main.
  other="$fxdir/other"
  other_git clone -q "$fxdir/remotes/$REPO.git" "$other"
  printf -- '- Spare: {{WRITER}} reads this twice.\n' >> "$other/team/CHATS.md"
  printf -- '<!-- see %s -->\n' "$FAKEHOME" >> "$other/.github/pull_request_template.md"
  printf '\nNote from a colleague: the old folder was %s.\n' "$FAKEHOME" >> "$other/team/LOG.md"
  awk '/<!-- assemble:begin/ { on = 1 } on { print } /<!-- assemble:end -->/ { on = 0 }' "$other/CLAUDE.md" >> "$other/CLAUDE.md"
  printf '{ "version": 2 }\n' > "$other/vercel.json"
  printf 'fixture: not a real key\n' > "$other/deploy.pem"
  printf '# Runbook\n' > "$other/team/RUNBOOK.md"
  drop_line "$other/team/CHATS.md" '| `team/LOG.md` | Cyrus |'
  drop_line "$other/.gitignore" '.env.*'
  other_git -C "$other" add -- team/CHATS.md .github/pull_request_template.md team/LOG.md CLAUDE.md vercel.json deploy.pem team/RUNBOOK.md .gitignore
  other_git -C "$other" commit -q -m "Colleague edits" -- team/CHATS.md .github/pull_request_template.md team/LOG.md CLAUDE.md vercel.json deploy.pem team/RUNBOOK.md .gitignore
  other_git -C "$other" push -q origin HEAD:main
  # The notebook writer's session start (routine, not part of the check): sync the notebook folder.
  open_gate
  sync_nb
  close_gate
  run_in "$fxdir" "$NB" git grep -n -F '{{' origin/main -- team .github/pull_request_template.md
  has "E1.1: the placeholder is found, in CHATS.md" "$OUT" 'team/CHATS.md'
  run_in "$fxdir" "$NB" git grep -n -E "$HOMEPAT" origin/main -- team .github/pull_request_template.md
  has "E1.2: the home-folder path is found in a work file" "$OUT" '\.github/pull_request_template\.md'
  has "E1.2: and in a notebook file" "$OUT" 'team/LOG\.md'
  run_in "$fxdir" "$NB" git show origin/main:CLAUDE.md
  same "E1.4: the block appears twice" "$(printf '%s\n' "$OUT" | grep -c '<!-- assemble:begin')" 2
  run_in "$fxdir" "$NB" bash "$root/scripts/check-output.sh" "$NB"
  has "E1.3: LOG.md has no owner row" "$OUT" 'team/LOG\.md: notebook file with no owner row'
  has "E1.5: the runbook isn't on the precious list" "$OUT" 'precious" list must include "team/RUNBOOK\.md"'
  run_in "$fxdir" "$NB" git ls-tree -r --name-only origin/main
  has "E3: a deploy file is on origin/main" "$OUT" '^vercel\.json$'
  run_in "$fxdir" "$NB" git ls-tree -r --name-only origin/main
  has "E4: a tracked key file is reported by name" "$OUT" '^deploy\.pem$'
  must_rc 0 "$fxdir" "$NB" git check-ignore -q .env
  must_rc 1 "$fxdir" "$NB" git check-ignore -q .env.local
  rm -rf "$NB"
  run_in "$fxdir" "$MAIN" git worktree list --porcelain
  has "E2: the deleted notebook folder shows as prunable" "$OUT" '^prunable'
  # The user says "Fix all of these". Local repair first: no PR.
  open_gate
  must "$fxdir" "$MAIN" git -C "$MAIN" worktree prune
  must "$fxdir" "$MAIN" git -C "$MAIN" worktree add --detach "$NB" origin/main
  same "the repaired notebook folder is at origin/main" "$(other_git -C "$NB" rev-parse HEAD)" "$(other_git -C "$MAIN" rev-parse origin/main)"
  same "and holds no branch, and is clean" "$(other_git -C "$NB" branch --show-current)$(other_git -C "$NB" status --short)" ''
  # One repair PR for the work files (B4, kind = repair: no handle).
  STAMP=20261014-1010
  WT="$MAIN/.claude/worktrees/assemble-repair-$STAMP"
  must "$fxdir" "$NB" bash -c "git -C \"$MAIN\" fetch origin || git -C \"$MAIN\" fetch origin"
  run_in "$fxdir" "$NB" git -C "$MAIN" ls-remote --heads origin "assemble/repair-*"
  same "no repair branch yet" "$OUT" ''
  must "$fxdir" "$NB" git -C "$MAIN" worktree add --no-track -b "assemble/repair-$STAMP" "$WT" origin/main
  # E6: the placeholder line goes; the missing owner row is the template's row for LOG.md, filled in with the
  # B1 values and put right after the row that precedes it there. The result is the example again.
  drop_line "$WT/team/CHATS.md" '- Spare: {{WRITER}}'
  grep -F '| `team/LOG.md` |' "$tdir/CHATS.md" > "$work/owner-row.tpl"
  ACME_VARS > "$work/vars-owner"
  owner_row=$(render "" "$work/vars-owner" "$work/owner-row.tpl")
  has "E6: the owner row is the template's row with the writer's name in it" "$owner_row" '^\| `team/LOG\.md` \| Cyrus \| After every event'
  insert_after "$WT/team/CHATS.md" '| `team/ROSTER.md` |' "$owner_row"
  if diff -q "$WT/team/CHATS.md" "$root/tests/rendered/acme/team/CHATS.md" > /dev/null; then ok "E6: CHATS.md is exactly the rendered example again"; else bad "E6: CHATS.md is not the example after the repair"; diff "$WT/team/CHATS.md" "$root/tests/rendered/acme/team/CHATS.md" | head -6 | sed 's/^/      | /'; fi
  drop_line "$WT/.github/pull_request_template.md" "$FAKEHOME"
  awk '/<!-- assemble:begin/ { n++ } n < 2 { print }' "$WT/CLAUDE.md" > "$WT/CLAUDE.md.tmp" && mv "$WT/CLAUDE.md.tmp" "$WT/CLAUDE.md"
  replace_line "$WT/team/assemble.json" '"db/migrations/**"' '    "db/migrations/**",
    "team/RUNBOOK.md"'
  printf '%s\n' '# assemble:begin · managed by /assemble' '.claude/worktrees/' '.env' '.env.*' '!.env.example' '# assemble:end' > "$WT/.gitignore.block"
  drop_line "$WT/.gitignore" '# assemble:'; drop_line "$WT/.gitignore" '.claude/worktrees/'; drop_line "$WT/.gitignore" '.env'; drop_line "$WT/.gitignore" '!.env.example'
  cat "$WT/.gitignore.block" >> "$WT/.gitignore"; rm -f "$WT/.gitignore.block"
  files="team/CHATS.md .github/pull_request_template.md CLAUDE.md team/assemble.json .gitignore"
  # B4 step 4 adds the paths, step 5 checks: `git status --short` lists exactly the shown files, all staged.
  # shellcheck disable=SC2086
  must "$fxdir" "$NB" git -C "$WT" add -- $files
  run_in "$fxdir" "$NB" git -C "$WT" status --short
  same "B4: the repair PR stages only the files it listed" "$(printf '%s\n' "$OUT" | sed 's/^M  //' | sort | tr '\n' ' ')" "$(printf '%s\n' $files | sort | tr '\n' ' ')"
  lacks "B4: and nothing is left unstaged or untracked" "$OUT" '^\?\?|^.M '
  run_in "$fxdir" "$NB" git -C "$WT" diff --cached --name-only origin/main
  same "B4: diff --cached against the default branch lists the same files" "$(printf '%s\n' "$OUT" | sort | tr '\n' ' ')" "$(printf '%s\n' $files | sort | tr '\n' ' ')"
  run_in "$fxdir" "$NB" git -C "$WT" grep -n -F '{{' -- team .github/pull_request_template.md
  same "B4 self-check: no placeholder in the worktree" "$RC" 1
  # shellcheck disable=SC2086
  must "$fxdir" "$NB" git -C "$WT" commit -m "Repair the team files" -- $files
  must "$fxdir" "$NB" git -C "$WT" push -u origin HEAD
  printf '## What this PR does\nRepairs the team files that the check found.\n\n## Reviewer handoff\n- **Tier:** full\n' > "$work/repair-body.md"
  must "$fxdir" "$NB" gh pr create --repo "$REPO" --base main --head "assemble/repair-$STAMP" --title "Repair the team files" --body-file "$work/repair-body.md"
  same "the repair PR is #2" "$(printf '%s\n' "$OUT" | tail -n 1)" "https://github.com/$REPO/pull/2"
  sha=$(bare_git rev-parse "refs/heads/assemble/repair-$STAMP")
  printf '## Ready for review: round 1 (Cyrus)\n**Tier:** full\n**Focus here first:** team/CHATS.md, CLAUDE.md, team/assemble.json\n' > "$work/ready.md"
  must "$fxdir" "$NB" gh pr comment 2 --repo "$REPO" --body-file "$work/ready.md"
  printf '## Review of PR #2: round 1 (Vito)\n**Reviewed commit:** %s   **Tier:** full\n**Verdict:** READY TO MERGE\n' "$sha" > "$work/verdict.md"
  must "$fxdir" "$NB" gh pr comment 2 --repo "$REPO" --body-file "$work/verdict.md"
  if bash "$root/tests/lib/fake-gh-merge" "$fxdir" 2 > "$work/merge.log" 2>&1; then ok "Priya merges PR #2"; else bad "the merge failed:"; sed 's/^/      /' "$work/merge.log"; fi
  # Part F.
  run_in "$fxdir" "$NB" gh pr view 2 --repo "$REPO" --json state,headRefOid
  has "F1: merged, and the head is the reviewed commit" "$OUT" "\"state\":\"MERGED\".*\"headRefOid\":\"$sha\"|\"headRefOid\":\"$sha\".*\"state\":\"MERGED\""
  must "$fxdir" "$NB" git -C "$MAIN" worktree remove "$WT"
  must "$fxdir" "$NB" git -C "$MAIN" branch -D "assemble/repair-$STAMP"
  open_gate
  sync_nb
  drop_line "$NB/team/LOG.md" "$FAKEHOME"
  awk '{ print } index($0, "<!-- new entries go directly below this line -->") { print "## 2026-10-14 · Cyrus (Chief) · Correction"; print "Done: the check found team files in a worse state; repair PR #2 merged; a home-folder path removed from this log." }' "$NB/team/LOG.md" > "$NB/team/LOG.md.tmp" && mv "$NB/team/LOG.md.tmp" "$NB/team/LOG.md"
  notes_push "notes: repaired a path" team/LOG.md
  sync_nb
  # The check again: what has a repair is clean; the two report-only findings are still reported.
  must_rc 1 "$fxdir" "$NB" git grep -n -F '{{' origin/main -- team .github/pull_request_template.md
  must_rc 1 "$fxdir" "$NB" git grep -n -E "$HOMEPAT" origin/main -- team .github/pull_request_template.md
  must "$fxdir" "$NB" git check-ignore -q .env.local
  if bash "$root/scripts/check-output.sh" "$NB" > "$work/co.log" 2>&1; then ok "check-output passes on the notebook folder again"; else bad "check-output still fails:"; sed 's/^/      /' "$work/co.log"; fi
  run_in "$fxdir" "$NB" git ls-tree -r --name-only origin/main
  has "E3 stays reported: a deploy file needs the user's decision" "$OUT" '^vercel\.json$'
  has "E4 stays reported: a tracked key file needs the user" "$OUT" '^deploy\.pem$'
  same "the user's checkout is untouched by all of this" "$(other_git -C "$MAIN" status --porcelain) $(other_git -C "$MAIN" symbolic-ref HEAD)" ' refs/heads/main'
  calls_clean "$fxdir"
fi

# ---------------------------------------------------------------------------------------------
echo
echo "== C: add a Designer (already-set-up, the same fixture as the check)"
fxdir="$work/team"
MAIN="$fxdir/acme"
NB="$fxdir/acme-team"
ADD_STAMP=20261014-0915
ADD_BRANCH="assemble/add-dara-$ADD_STAMP"
WT="$MAIN/.claude/worktrees/assemble-add-dara-$ADD_STAMP"
main_before=$(other_git -C "$MAIN" rev-parse HEAD)
# B1 with a pending briefing: before this re-run, Cyrus briefed a decision Priya owes (roles/chief.md,
# Decisions 1), so the briefing holds D3 while DECISIONS.md stops at D2. (That notes commit came earlier,
# from another copy, with the real git.) The next decision ID skips it: the Add is D4, never a second D3.
earlier="$fxdir/cyrus-earlier"
other_git clone -q "$fxdir/remotes/$REPO.git" "$earlier"
mkdir -p "$earlier/team/briefings"
printf '%s\n' '# D3 · Where does the booking page live?' '*Briefing by Cyrus, 2026-10-14, for Priya. Nothing here is decided.*' '' \
  '## The problem' 'The page needs a host before it can go live.' '' '## Options' '1. **A free static host.** 2. **The stall'"'"'s own domain.**' '' \
  '## Evidence' '- **ours:** both are free to start.' '' '## One worked example' 'Priya picks the free host; Bram adds its file by PR.' '' \
  '## Our leaning (ours)' 'The free host: nothing to buy.' '' '## The question' 'Which host should the booking page use?' > "$earlier/team/briefings/D3-booking-host.md"
replace_line "$earlier/team/TASKS.md" 'None yet.' '- D3 · Where does the booking page live? · [briefing](briefings/D3-booking-host.md) · Not taught yet'
other_git -C "$earlier" add -- team/briefings/D3-booking-host.md team/TASKS.md
other_git -C "$earlier" commit -q -m "notes: briefing D3, the booking page host [skip ci]" -- team/briefings/D3-booking-host.md team/TASKS.md
other_git -C "$earlier" push -q origin HEAD:main
must "$fxdir" "$NB" bash -c 'git fetch origin || git fetch origin'
run_in "$fxdir" "$NB" git show origin/main:team/DECISIONS.md
dmax=$(printf '%s\n' "$OUT" | sed -n 's/^| D\([0-9]*\) .*/\1/p' | sort -n | tail -n 1)
run_in "$fxdir" "$NB" git ls-tree --name-only origin/main -- team/briefings/
same "B1: the briefing file names are listed" "$OUT" team/briefings/D3-booking-host.md
bmax=$(printf '%s\n' "$OUT" | sed -n 's|^team/briefings/D\([0-9]*\)-.*|\1|p' | sort -n | tail -n 1)
same "B1: DECISIONS.md alone would give D3, a clash with the briefing" "D$((dmax + 1))" D3
same "B1: the next decision ID counts the briefings too" "D$(( (dmax > ${bmax:-0} ? dmax : ${bmax:-0}) + 1 ))" D4
# B3 rule 3 and C3: one maintenance PR at a time; the name is free (the roster, retired chats included).
run_in "$fxdir" "$NB" gh pr list --repo "$REPO" --state open --json number,headRefName,url --limit 100
same "B3: no maintenance PR is open" "$OUT" '[]'
run_in "$fxdir" "$NB" git show origin/main:team/ROSTER.md
lacks "C3: Dara isn't on the roster" "$OUT" 'Dara'
# C4: the user picks "Open the Add PR": the gate opens; then B4.
open_gate
must "$fxdir" "$NB" bash -c "git -C \"$MAIN\" fetch origin || git -C \"$MAIN\" fetch origin"
run_in "$fxdir" "$NB" git -C "$MAIN" ls-remote --heads origin "assemble/add-*"
same "B4.2: no add branch on GitHub" "$OUT" ''
must "$fxdir" "$NB" git -C "$MAIN" worktree add --no-track -b "$ADD_BRANCH" "$WT" origin/main
# C5: the role file, filled in from the template with the B1 values.
{ ACME_VARS; printf '%s\n' NAME=Dara 'TITLE=Dara · Acme Designer' MODEL=Sonnet HANDLE=dara; } > "$work/vars-dara"
render "IF_REVIEWER IF_IN_REPO" "$work/vars-dara" "$tdir/roles/designer.md" > "$WT/team/roles/designer.md"
lacks "C5: no placeholder left in the role file" "$(cat "$WT/team/roles/designer.md")" '\{\{'
lacks "C5: no home-folder path in it" "$(cat "$WT/team/roles/designer.md")" "$HOMEPAT"
same "C5: its second line carries exactly the title the roster will" "$(sed -n 2p "$WT/team/roles/designer.md" | sed 's/ · Model.*//')" 'Address: "Dara · Acme Designer"'
has "C5: its Type is doer" "$(sed -n 2p "$WT/team/roles/designer.md")" 'Type: doer$'
has "C5: it sends Vito the doorbell (a standing Reviewer)" "$(cat "$WT/team/roles/designer.md")" 'Send Vito a one-line doorbell'
lacks "C5: and has none of the notes-repo lines (in-repo)" "$(cat "$WT/team/roles/designer.md")" 'notes repo'
# B4 steps 4 and 5: add first, then check. Before the add a new file is invisible to `git diff`; after it,
# `git status --short` lists exactly the shown file, and a stray extra file is caught.
run_in "$fxdir" "$NB" git -C "$WT" diff --name-only origin/main
same "B4: before the add, git diff shows nothing for the new role file (why the check runs after the add)" "$OUT" ''
must "$fxdir" "$NB" git -C "$WT" add -- team/roles/designer.md
run_in "$fxdir" "$NB" git -C "$WT" status --short
same "B4: after the add, status lists exactly the shown file, staged" "$OUT" 'A  team/roles/designer.md'
printf 'stray\n' > "$WT/team/stray.md"
run_in "$fxdir" "$NB" git -C "$WT" status --short
has "B4: a stray file the screen didn't show is caught by the same check" "$OUT" '^\?\? team/stray\.md$'
rm -f "$WT/team/stray.md"
must "$fxdir" "$NB" git -C "$WT" commit -m "Add Dara, the Designer" -- team/roles/designer.md
must "$fxdir" "$NB" git -C "$WT" push -u origin HEAD
printf '## What this PR does\nAdds Dara, the Designer.\n\n## Reviewer handoff\n- **Tier:** full (team/roles/** is on the precious list)\n- **Focus here first:** team/roles/designer.md, a new rule file\n' > "$work/add-body.md"
lacks "B4.7: the PR body is scanned before it goes to GitHub: no home-folder path, no placeholder" "$(cat "$work/add-body.md")" "$HOMEPAT|\\{\\{"
printf 'Built in git -C "%s" with the working copy.\n' "$FAKEHOME" > "$work/body-bad.md"
has "B4.7: and a body that does hold a path is caught by the same patterns" "$(grep -E "$HOMEPAT" "$work/body-bad.md" || true)" 'someone'
must "$fxdir" "$NB" gh pr create --repo "$REPO" --base main --head "$ADD_BRANCH" --title "Add Dara, the Designer" --body-file "$work/add-body.md"
same "the Add PR is #2" "$(printf '%s\n' "$OUT" | tail -n 1)" "https://github.com/$REPO/pull/2"
printf '## Ready for review: round 1 (Cyrus)\n**Tier:** full\n**Focus here first:** team/roles/designer.md\n' > "$work/ready.md"
must "$fxdir" "$NB" gh pr comment 2 --repo "$REPO" --body-file "$work/ready.md"
run_in "$fxdir" "$NB" gh pr diff 2 --repo "$REPO" --name-only
same "C4: the PR holds only the role file" "$OUT" team/roles/designer.md
same "the user's checkout is untouched while the PR is open (branch, commit, status)" "$(other_git -C "$MAIN" symbolic-ref HEAD) $(other_git -C "$MAIN" rev-parse HEAD) $(other_git -C "$MAIN" status --porcelain)" "refs/heads/main $main_before "
same "the notebook folder is untouched (no branch, clean)" "$(other_git -C "$NB" branch --show-current)$(other_git -C "$NB" status --short)" ''
lacks "the PR's working copy is invisible to the user's checkout" "$(other_git -C "$MAIN" status --porcelain --untracked-files=all)" '\.claude'
# C5 end: the follow-up in TASKS, a notebook write while the PR is open.
sync_nb
insert_after "$NB/team/TASKS.md" '## Now' '- [ ] T4 · After PR #2 merges: notes for Dara and Dara'"'"'s opening steps · [track: team] · Cyrus · done when ROSTER has Dara'"'"'s row · (added 2026-10-14)'
notes_push "notes: Add PR #2 follow-up" team/TASKS.md
# The review, then the human's Merge.
sha=$(bare_git rev-parse "refs/heads/$ADD_BRANCH")
printf '## Review of PR #2: round 1 (Vito)\n**Reviewed commit:** %s   **Tier:** full\n**Verdict:** READY TO MERGE\n' "$sha" > "$work/verdict.md"
must "$fxdir" "$NB" gh pr comment 2 --repo "$REPO" --body-file "$work/verdict.md"
run_in "$fxdir" "$NB" gh pr view 2 --repo "$REPO" --json headRefOid,mergeable,state
has "merge gate: the head is the reviewed commit" "$OUT" "\"headRefOid\":\"$sha\""
if bash "$root/tests/lib/fake-gh-merge" "$fxdir" 2 > "$work/merge.log" 2>&1; then ok "Priya merges PR #2"; else bad "the merge failed:"; sed 's/^/      /' "$work/merge.log"; fi
# Part F.
run_in "$fxdir" "$NB" gh pr view 2 --repo "$REPO" --json state,headRefOid
has "F1: merged, and the head is the reviewed commit" "$OUT" "\"state\":\"MERGED\".*\"headRefOid\":\"$sha\"|\"headRefOid\":\"$sha\".*\"state\":\"MERGED\""
must "$fxdir" "$NB" git -C "$MAIN" worktree remove "$WT"
must "$fxdir" "$NB" git -C "$MAIN" branch -D "$ADD_BRANCH"
sync_nb
same "F3: the notebook folder holds no branch" "$(other_git -C "$NB" branch --show-current)" ''
insert_after "$NB/team/ROSTER.md" '| Bram | Bram · Acme Builder |' '| Dara | Dara · Acme Designer | UI and visual work, in the same files the Builder uses | Changes behaviour beyond the task; merges | its own branches and PRs | Sonnet | Standby (not opened yet) |'
insert_after "$NB/team/ROSTER.md" '| Bram · Acme Builder (after setup PR #1 merges) |' '| Dara · Acme Designer (open any time) | New session → choose the `acme` folder → worktree option on → model Sonnet → paste the kickoff → approve the `acme-team` folder when asked → ask Claude to rename the session to exactly "Dara · Acme Designer" | `claude -w dara -n "Dara · Acme Designer" --model sonnet --add-dir "../acme-team" -- "<kickoff>"` |'
printf '| D4 | 2026-10-14 | Hired Dara · Designer: UI and visual work | Priya | (clicked) "Open the Add PR" | LOG 2026-10-14, hired Dara |\n' >> "$NB/team/DECISIONS.md"
insert_after "$NB/team/LOG.md" '<!-- new entries go directly below this line -->' '## 2026-10-14 · Cyrus (Chief) · Hired Dara (Designer)
Done: team/roles/designer.md by PR #2, merged at `'"$(printf '%.7s' "$(bare_git rev-parse refs/heads/main)")"'`.
Ruled (Priya): D4 hire Dara.
D4 · Shown: Dara, Designer (Sonnet) · We recommended: Dara (the booking page has design work queued) · Priya chose: Open the Add PR
(clicked) "Open the Add PR"
Open: Priya opens Dara.'
insert_after "$NB/team/TASKS.md" '| Bram | Standby: opens after setup PR #1 merges |' '| Dara | First job: a design readiness note (T5) | team | Priya (opens Dara) | 2026-10-14 |'
insert_after "$NB/team/TASKS.md" '| Open Bram (Builder) |' '| Open Dara (Designer) | Cyrus prints the steps; they are also in ROSTER "How to open each chat" | Chats can'"'"'t open chats | when you want Dara to start | 2 min | ☐ |'
# The first-job T-line names who drafts team/PLAN.md: Bram's T1 does, so Dara's line says it is not hers (no PR conflict).
insert_after "$NB/team/TASKS.md" 'T1 · Build-readiness note and team/PLAN.md' '- [ ] T5 · Design readiness note, not team/PLAN.md (T1 drafts it) · [track: team] · Dara · done when its PR has a READY verdict and Priya merged it · (added 2026-10-14)'
# The C5 follow-up line moves to Done (IDs are never reused).
drop_line "$NB/team/TASKS.md" 'After PR #2 merges: notes for Dara'
insert_after "$NB/team/TASKS.md" '## Done (newest first)' '- [x] T4 · After PR #2 merges: notes for Dara and Dara'"'"'s opening steps · [track: team] · Cyrus · done when ROSTER has Dara'"'"'s row · (added 2026-10-14, done 2026-10-14)'
replace_line "$NB/team/README.md" 'Team set up today.' 'Dara, the Designer, joined on 2026-10-14 (Add PR #2). Setup PR #1 is waiting for Vito'"'"'s review; Bram opens after it merges.  ·  Now, Next and who we are waiting on: [TASKS.md](TASKS.md)'
notes_push "notes: hired Dara" team/ROSTER.md team/DECISIONS.md team/LOG.md team/TASKS.md team/README.md
run_in "$fxdir" "$NB" git show origin/main:team/TASKS.md
same "F4: exactly one open task of the team drafts team/PLAN.md (two doers never both open a PR for it)" "$(printf '%s\n' "$OUT" | grep '^- \[ \] T' | grep 'PLAN\.md' | grep -vc 'not team/PLAN\.md')" 1
same "F4: the follow-up line is under Done, not Now" "$(printf '%s\n' "$OUT" | grep -c 'T4 · After PR #2 merges')$(printf '%s\n' "$OUT" | sed -n '/^## Now/,/^## Next/p' | grep -c 'T4')" 10
same "main has Dara's role file and her row" "$(bare_git show main:team/roles/designer.md | head -1) / $(bare_git show main:team/ROSTER.md | grep -c '^| Dara | Dara · Acme Designer |')" '# Dara · Acme Designer / 1'
checks_clean "F5"
if [ -f "$NB/team/roles/designer.md" ]; then ok "F7: the kickoff path $NB/team/roles/designer.md exists, so Dara's steps can be printed"; else bad "F7: team/roles/designer.md is missing in the notebook folder"; fi
calls_clean "$fxdir"

echo
echo "== D: retire Bram (the same fixture, after Dara joined)"
RET_STAMP=20261014-1130
RET_BRANCH="assemble/retire-bram-$RET_STAMP"
WT="$MAIN/.claude/worktrees/assemble-retire-bram-$RET_STAMP"
# D1: the team keeps at least one doer (a chat titled neither Chief nor Reviewer), and the Chief is only
# ever handed over. Bram can go because Dara joined; before that he was the only doer.
run_in "$fxdir" "$NB" git show origin/main:team/ROSTER.md
same "D1: two doers on the roster (Bram, Dara), so Bram is not the last one" "$(titles_of "$OUT" | grep -cvE ' (Chief|Reviewer)$')" 2
same "D1: rerun.md stops a Retire of the only doer" "$(grep -c "is the team's only doer" "$root/skills/assemble/reference/rerun.md")" 1
same "D1: rerun.md makes retiring the Chief a handover to a new Chief" "$(grep -c 'Retiring the Chief is a handover to a new Chief' "$root/skills/assemble/reference/rerun.md")" 1
# D2: what the retirement touches.
run_in "$fxdir" "$NB" git show origin/main:team/TASKS.md
bram_tasks=$(printf '%s\n' "$OUT" | grep -c '^- \[ \] T[0-9]* · .* · Bram · ')
same "D2: Bram owns three open tasks" "$bram_tasks" 3
run_in "$fxdir" "$NB" gh pr list --repo "$REPO" --state open --json number,headRefName,title --limit 100
lacks "D2: no open PR from a bram/ branch" "$OUT" '"headRefName":"bram/'
# The handover (a notebook commit before the PR): written by the notebook writer from the notes, because Bram never opened.
sync_nb
mkdir -p "$NB/team/handovers"
printf '# Handover: Bram (2026-10-14)\n*Written by Cyrus from the notes, not by Bram.*\n\n## Open tracks\nNone started; T1 to T3 were proposals.\n' > "$NB/team/handovers/builder-2026-10-14.md"
notes_push "notes: Bram's handover" team/handovers/builder-2026-10-14.md
# D3: "Retire Bram"; D4: the banner PR.
must "$fxdir" "$NB" bash -c "git -C \"$MAIN\" fetch origin || git -C \"$MAIN\" fetch origin"
must "$fxdir" "$NB" git -C "$MAIN" worktree add --no-track -b "$RET_BRANCH" "$WT" origin/main
cp "$WT/team/roles/builder.md" "$work/builder-before.md"
insert_after "$WT/team/roles/builder.md" '# Bram · Acme Builder' '> **RETIRED 2026-10-14.** Bram no longer works on Acme. Nobody opens or messages this chat; its handover is team/handovers/builder-2026-10-14.md.'
run_in "$fxdir" "$NB" git -C "$WT" diff --stat origin/main
has "D4: the only change is one inserted line in the role file" "$OUT" 'team/roles/builder\.md \| 1 \+$'
same "D4: nothing else in the role file changed (history is kept)" "$(diff "$work/builder-before.md" "$WT/team/roles/builder.md" | grep -c '^<')" 0
must "$fxdir" "$NB" git -C "$WT" add -- team/roles/builder.md
must "$fxdir" "$NB" git -C "$WT" commit -m "Retire Bram, the Builder" -- team/roles/builder.md
must "$fxdir" "$NB" git -C "$WT" push -u origin HEAD
printf '## What this PR does\nRetires Bram, the Builder.\n\n## Reviewer handoff\n- **Tier:** full (team/roles/** is on the precious list)\n- **Focus here first:** team/roles/builder.md, one banner line\n' > "$work/ret-body.md"
must "$fxdir" "$NB" gh pr create --repo "$REPO" --base main --head "$RET_BRANCH" --title "Retire Bram, the Builder" --body-file "$work/ret-body.md"
same "the Retire PR is #3" "$(printf '%s\n' "$OUT" | tail -n 1)" "https://github.com/$REPO/pull/3"
printf '## Ready for review: round 1 (Cyrus)\n**Tier:** full\n**Focus here first:** team/roles/builder.md\n' > "$work/ready.md"
must "$fxdir" "$NB" gh pr comment 3 --repo "$REPO" --body-file "$work/ready.md"
sha=$(bare_git rev-parse "refs/heads/$RET_BRANCH")
printf '## Review of PR #3: round 1 (Vito)\n**Reviewed commit:** %s   **Tier:** full\n**Verdict:** READY TO MERGE\n' "$sha" > "$work/verdict.md"
must "$fxdir" "$NB" gh pr comment 3 --repo "$REPO" --body-file "$work/verdict.md"
if bash "$root/tests/lib/fake-gh-merge" "$fxdir" 3 > "$work/merge.log" 2>&1; then ok "Priya merges PR #3"; else bad "the merge failed:"; sed 's/^/      /' "$work/merge.log"; fi
# D6 and F.
must "$fxdir" "$NB" git -C "$MAIN" worktree remove "$WT"
must "$fxdir" "$NB" git -C "$MAIN" branch -D "$RET_BRANCH"
sync_nb
# The ROSTER row moves; Bram's open row goes; the tasks go to Later (the user's choice); a decision and a log entry.
drop_line "$NB/team/ROSTER.md" '| Bram | Bram · Acme Builder |'
drop_line "$NB/team/ROSTER.md" '| Bram · Acme Builder (after setup PR #1 merges) |'
printf '| Bram · Acme Builder | 2026-10-12 | 2026-10-14 | team/handovers/builder-2026-10-14.md |\n' >> "$NB/team/ROSTER.md"
bram_lines=$(grep '^- \[ \] T[0-9]* · .* · Bram · ' "$NB/team/TASKS.md" | sed 's/ · Bram · / · unassigned · /')
drop_line "$NB/team/TASKS.md" ' · Bram · '
drop_line "$NB/team/TASKS.md" '| Bram | Standby'
LATER=$bram_lines insert_after "$NB/team/TASKS.md" '## Later' "$bram_lines"
printf '| D5 | 2026-10-14 | Retired Bram · Builder; his three proposed tasks wait under Later | Priya | (clicked) "Retire Bram" | LOG 2026-10-14, retired Bram |\n' >> "$NB/team/DECISIONS.md"
insert_after "$NB/team/LOG.md" '<!-- new entries go directly below this line -->' '## 2026-10-14 · Cyrus (Chief) · Retired Bram (Builder)
Done: team/roles/builder.md bannered by PR #3; handover team/handovers/builder-2026-10-14.md.
Ruled (Priya): D5 retire Bram.
D5 · Shown: Retire Bram · Change something · Cancel · We recommended: retire (no work started) · Priya chose: Retire Bram
(clicked) "Retire Bram"
Open: nobody can take doer tasks until a doer is added.'
notes_push "notes: retired Bram" team/ROSTER.md team/TASKS.md team/DECISIONS.md team/LOG.md
run_in "$fxdir" "$NB" git show origin/main:team/ROSTER.md
same "D6: the roster's chats are now Cyrus, Vito, Dara" "$(titles_of "$OUT" | tr '\n' '|')" 'Cyrus · Acme Chief|Vito · Acme Reviewer|Dara · Acme Designer|'
has "D6: Bram is under Retired chats, with his handover" "$OUT" '^\| Bram · Acme Builder \| 2026-10-12 \| 2026-10-14 \| team/handovers/builder-2026-10-14\.md \|$'
run_in "$fxdir" "$NB" git show origin/main:team/roles/builder.md
same "D4: the role file starts with its title and the banner" "$(printf '%s\n' "$OUT" | sed -n '1p;2p' | cut -c1-30 | tr '\n' '|')" '# Bram · Acme Builder|> **RETIRED 2026-10-14.** Bram|'
run_in "$fxdir" "$NB" git show origin/main:team/TASKS.md
same "D2: no open task is left with Bram" "$(printf '%s\n' "$OUT" | grep -c '^- \[ \] T[0-9]* · .* · Bram · ')" 0
checks_clean "D6/F5 (the owner check again)"
calls_clean "$fxdir"

echo
echo "== C: a role of the user's own (a Translator), on a fresh fixture"
fxdir="$work/custom"
if build already-set-up "$fxdir"; then
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  MAIN="$fxdir/acme"
  NB="$fxdir/acme-team"
  WT="$MAIN/.claude/worktrees/assemble-add-tess-20261014-1200"
  open_gate
  must "$fxdir" "$NB" git -C "$MAIN" worktree add --no-track -b assemble/add-tess-20261014-1200 "$WT" origin/main
  { ACME_VARS; printf '%s\n' NAME=Tess 'TITLE=Tess · Acme Translator' MODEL=Sonnet HANDLE=tess \
      'CUSTOM_JOB_LINES=- Translate the site and its emails into Hindi, one page per task.' \
      "CUSTOM_NEVER_LINES=- Publish a translation without Priya's yes." \
      'CUSTOM_WRITES_TO=the translations folder' 'CUSTOM_FIRST_JOB=the first translation pass'; } > "$work/vars-tess"
  render "IF_REVIEWER IF_IN_REPO" "$work/vars-tess" "$tdir/roles/custom.md" > "$WT/team/roles/translator.md"
  text=$(cat "$WT/team/roles/translator.md")
  lacks "C1: no placeholder left in the custom role file" "$text" '\{\{'
  has "C1: its Type is doer (a role of your own is always a doer)" "$(sed -n 2p "$WT/team/roles/translator.md")" 'Type: doer$'
  has "C1: the user's job line is in" "$text" '^- Translate the site and its emails into Hindi'
  has "C1: and the extra never line" "$text" "^- Publish a translation without Priya's yes\\."
  has "C1: and its first job" "$text" 'First job: the first translation pass\.'
  if [ "$(printf 'Tess · Acme Translator' | wc -c | tr -d ' ')" -le 40 ]; then ok "C1: the title is within the 40-character limit"; else bad "C1: the title is longer than 40 characters"; fi
  must "$fxdir" "$NB" git -C "$WT" add -- team/roles/translator.md
  must "$fxdir" "$NB" git -C "$WT" commit -m "Add Tess, the Translator" -- team/roles/translator.md
  must "$fxdir" "$NB" git -C "$WT" push -u origin HEAD
  printf '## What this PR does\nAdds Tess, the Translator.\n\n## Reviewer handoff\n- **Tier:** full\n' > "$work/add-body.md"
  must "$fxdir" "$NB" gh pr create --repo "$REPO" --base main --head assemble/add-tess-20261014-1200 --title "Add Tess, the Translator" --body-file "$work/add-body.md"
  run_in "$fxdir" "$NB" gh pr diff 2 --repo "$REPO" --name-only
  same "the PR holds only team/roles/translator.md" "$OUT" team/roles/translator.md
  if bash "$root/tests/lib/fake-gh-merge" "$fxdir" 2 > "$work/merge.log" 2>&1; then ok "Priya merges PR #2"; else bad "the merge failed:"; sed 's/^/      /' "$work/merge.log"; fi
  must "$fxdir" "$NB" git -C "$MAIN" worktree remove "$WT"
  must "$fxdir" "$NB" git -C "$MAIN" branch -D assemble/add-tess-20261014-1200
  sync_nb
  if bash "$root/scripts/check-output.sh" "$NB" > "$work/co.log" 2>&1; then ok "check-output passes with the custom role file in place"; else bad "check-output failed:"; sed 's/^/      /' "$work/co.log"; fi
  calls_clean "$fxdir"
fi

echo
echo "== Guards: the shims refuse a re-run write before the approval, and a rule-breaking one after it"
fxdir="$work/guards"
if build already-set-up "$fxdir"; then
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  MAIN="$fxdir/acme"
  NB="$fxdir/acme-team"
  must_rc 1 "$fxdir" "$NB" git -C "$MAIN" worktree add --no-track -b assemble/add-x-1 "$MAIN/.claude/worktrees/x" origin/main
  must_rc 1 "$fxdir" "$NB" gh pr create --repo "$REPO" --base main --head nothing --title x --body x
  open_gate
  must_rc 1 "$fxdir" "$NB" git -C "$MAIN" worktree add -b assemble/add-x-2 "$MAIN/.claude/worktrees/y" origin/main
  must "$fxdir" "$NB" git -C "$MAIN" worktree add --no-track -b assemble/add-x-3 "$MAIN/.claude/worktrees/z" origin/main
  printf 'x\n' > "$MAIN/.claude/worktrees/z/x.txt"
  must "$fxdir" "$NB" git -C "$MAIN/.claude/worktrees/z" add -- x.txt
  must_rc 1 "$fxdir" "$NB" git -C "$MAIN/.claude/worktrees/z" commit -m "no paths"
  must "$fxdir" "$NB" git -C "$MAIN/.claude/worktrees/z" commit -m "x" -- x.txt
  must_rc 1 "$fxdir" "$NB" git -C "$MAIN/.claude/worktrees/z" push
  must_rc 1 "$fxdir" "$NB" git -C "$MAIN/.claude/worktrees/z" push --force origin HEAD
  must "$fxdir" "$NB" git -C "$MAIN/.claude/worktrees/z" push -u origin HEAD
  must_rc 1 "$fxdir" "$NB" gh pr merge 2 --squash
  must_rc 1 "$fxdir" "$NB" gh pr review 2 --approve
  must_rc 1 "$fxdir" "$NB" gh pr close 2 --delete-branch
  same "every refusal is logged as REFUSED (2 before the approval, 7 after)" "$(grep -c '^REFUSED ' "$fxdir/calls.log" || true)" 9
fi

echo
if [ "$fails" -eq 0 ]; then
  echo "rerun-test: all $checks checks passed"
else
  echo "rerun-test: $fails of $checks checks failed"
  exit 1
fi
