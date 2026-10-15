# tests/lib/team-fixture.sh: helpers for the re-run fixtures (already-set-up, open-setup-pr,
# setup-leftovers). Source it after tests/lib/fixture.sh; don't run it.
#
# They build the state a finished or half-finished setup leaves behind, on the fake GitHub (bare
# repos under <fixture>/remotes/, pull requests under <fixture>/gh-state/), using the real git
# for the repos and the fixture's own fake gh for the pull requests, so the state has exactly the
# shape the fakes later read. The fixture's write gate is opened only while a helper needs it and
# closed again, and calls.log is emptied at the end (tf_finish), so a run starts with a clean log.
#
# Every name here is fictional (Acme, Priya, priya-acme). Portable bash: macOS bash 3.2 and Linux.

TF_REPO=priya-acme/acme
TF_STAMP=20261012-1435
TF_BRANCH="assemble/setup-$TF_STAMP"

# tf_net ARGS...: the real git against the local bare repos (https://github.com/ is rewritten to
# <fixture>/remotes/ for that one call).
tf_net() { fx_git -c "url.$FX_ROOT/remotes/.insteadOf=https://github.com/" "$@"; }

# tf_gate open|close: the fixture's write gate (see tests/lib/fake-gh).
tf_gate() {
  case "$1" in
    open) : > "$FX_ROOT/write-screen-approved" ;;
    close) rm -f "$FX_ROOT/write-screen-approved" ;;
  esac
}

# tf_publish: put the project repo acme/ (main, as fixture_repo made it) on the fake GitHub.
tf_publish() {
  mkdir -p "$FX_ROOT/remotes/priya-acme"
  fx_git init -q --bare -b main "$FX_ROOT/remotes/$TF_REPO.git"
  fx_git -C "$FX_ROOT/acme" push -q "$FX_ROOT/remotes/$TF_REPO.git" main
}

# tf_copy_tree TREE DEST: copy every file of TREE into DEST at the same relative path and print the
# relative paths, one per line.
tf_copy_tree() {
  ( cd "$1" && find . -type f -print | sed 's|^\./||' | sort ) | while IFS= read -r p; do
    mkdir -p "$2/$(dirname "$p")"
    cp "$1/$p" "$2/$p"
    printf '%s\n' "$p"
  done
}

# tf_setup_branch STAMP TREE: the notebook folder acme-team as a worktree of acme on the setup branch
# assemble/setup-STAMP, holding the files of TREE (a hand-rendered example) plus the marked
# .gitignore block, committed and pushed (git-model.md D2 and D3).
tf_setup_branch() {
  local stamp=$1 tree=$2 nb="$FX_ROOT/acme-team" branch="assemble/setup-$1" list
  fx_git -C "$FX_ROOT/acme" worktree add -q --no-track -b "$branch" "$nb" origin/main
  list=$(tf_copy_tree "$tree" "$nb")
  cat "$FX_ROOT/acme/.gitignore" > "$nb/.gitignore"
  printf '%s\n' '# assemble:begin · managed by /assemble' '.claude/worktrees/' '.env.*' '!.env.example' '# assemble:end' >> "$nb/.gitignore"
  # shellcheck disable=SC2086
  fx_git -C "$nb" add -- $list .gitignore
  # shellcheck disable=SC2086
  fx_git -C "$nb" commit -q -m "Set up the team with /assemble" -- $list .gitignore
  tf_net -C "$nb" push -q -u origin HEAD
  tf_net -C "$FX_ROOT/acme" fetch -q origin
}

# tf_exclude: the local exclude line (git-model.md D4), once.
tf_exclude() {
  local f="$FX_ROOT/acme/.git/info/exclude"
  mkdir -p "$(dirname "$f")"
  grep -qxF '.claude/worktrees/' "$f" 2>/dev/null || printf '%s\n' '.claude/worktrees/' >> "$f"
}

# tf_open_pr: setup PR #1 on the fake GitHub, opened the way the setup chat opens it.
tf_open_pr() {
  local body
  body=$(mktemp "${TMPDIR:-/tmp}/tf-body.XXXXXX")
  printf '## What this PR does\nSets up the team and its notes.\n\n## Reviewer handoff\n- **Tier:** full\n' > "$body"
  tf_gate open
  "$FX_ROOT/bin/gh" pr create --repo "$TF_REPO" --base main --head "$TF_BRANCH" \
    --title "Set up the team with /assemble" --body-file "$body" > /dev/null
  tf_gate close
  rm -f "$body"
}

# tf_merge_pr: the reviewer's READY TO MERGE verdict on PR #1 (pinned to its head), then Priya's
# Merge click (tests/lib/fake-gh-merge), then the notebook writer's after-merge steps (git-model.md
# E: detach the notebook folder at origin/main, delete the setup branch), Priya's Delete branch
# click, and Priya's own git pull in acme/.
tf_merge_pr() {
  local nb="$FX_ROOT/acme-team" acme="$FX_ROOT/acme" sha body
  sha=$("$FX_ROOT/bin/gh" pr view 1 --repo "$TF_REPO" --json headRefOid --jq .headRefOid)
  body=$(mktemp "${TMPDIR:-/tmp}/tf-body.XXXXXX")
  printf '## Review of PR #1: round 1 (Vito)\n**Reviewed commit:** %s   **Tier:** full\n**Verdict:** READY TO MERGE\n**In plain English:** the setup files are complete.\n' "$sha" > "$body"
  tf_gate open
  "$FX_ROOT/bin/gh" pr comment 1 --repo "$TF_REPO" --body-file "$body" > /dev/null
  tf_gate close
  rm -f "$body"
  bash "$FIXTURE_LIB_DIR/fake-gh-merge" "$FX_ROOT" 1 > /dev/null
  tf_net -C "$nb" fetch -q --prune origin
  fx_git -C "$nb" switch -q --detach origin/main
  fx_git -C "$nb" branch -q -D "$TF_BRANCH"
  fx_git --git-dir="$FX_ROOT/remotes/$TF_REPO.git" update-ref -d "refs/heads/$TF_BRANCH"
  tf_net -C "$acme" fetch -q --prune origin
  tf_net -C "$acme" pull -q --ff-only origin main
}

# tf_leftover STAMP TREE: what a setup that stopped partway leaves behind: the notebook folder acme-team
# as a worktree of acme on assemble/setup-STAMP (locked, as a `claude -w` worktree stays after its
# session ends), two files committed and pushed to the branch, and no pull request.
tf_leftover() {
  local stamp=$1 tree=$2 nb="$FX_ROOT/acme-team" branch="assemble/setup-$1"
  fx_git -C "$FX_ROOT/acme" worktree add -q --no-track -b "$branch" "$nb" origin/main
  mkdir -p "$nb/team"
  cp "$tree/CLAUDE.md" "$nb/CLAUDE.md"
  cp "$tree/team/README.md" "$nb/team/README.md"
  fx_git -C "$nb" add -- CLAUDE.md team/README.md
  fx_git -C "$nb" commit -q -m "Set up the team with /assemble" -- CLAUDE.md team/README.md
  tf_net -C "$nb" push -q -u origin HEAD
  tf_net -C "$FX_ROOT/acme" fetch -q origin
  fx_git -C "$FX_ROOT/acme" worktree lock --reason "claude agent session" "$nb"
}

# tf_finish: forget how the state was built. The log starts empty; the gate is closed.
tf_finish() {
  tf_gate close
  : > "$FX_ROOT/calls.log"
}
