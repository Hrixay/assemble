#!/usr/bin/env bash
# tests/fixtures/already-set-up/setup.sh: build the "already-set-up" fixture in a new or empty folder.
#
# Simulates: a project whose team is set up and whose setup PR was merged: Priya's acme/ (a private
#            repo she owns, only she committed) holds CLAUDE.md with the team block, the PR template and
#            team/ for Cyrus (Chief), Vito (Reviewer) and Bram (Builder), taken from tests/rendered/acme.
#            Her checkout is on main, pulled, and clean. The notebook folder ../acme-team is a detached
#            worktree at origin/main. PR #1 is MERGED; its branch is deleted. No other PR is open. gh is
#            logged in as priya-acme. Writes are allowed after the approval screen: the fake gh opens
#            pull requests on local bare repos under remotes/, and the fake git pushes there.
# What /assemble must do with it: tests/fixtures/already-set-up/expected.md. How to run it: tests/checklist.md.
#
# Usage: tests/fixtures/already-set-up/setup.sh <new or empty folder>    (for example "$TMPDIR/fx-already-set-up")
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../lib/fixture.sh"
. "$here/../../lib/team-fixture.sh"

fixture_begin already-set-up "$@"
fixture_repo --origin https://github.com/priya-acme/acme.git --identity --helper
fixture_shims --gh ok --git local-remote --writes
tf_publish
tf_setup_branch "$TF_STAMP" "$here/../../rendered/acme"
tf_exclude
tf_open_pr
tf_merge_pr
tf_finish
fixture_end
