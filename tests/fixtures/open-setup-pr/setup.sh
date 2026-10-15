#!/usr/bin/env bash
# tests/fixtures/open-setup-pr/setup.sh: build the "open-setup-pr" fixture in a new or empty folder.
#
# Simulates: a setup that reached its pull request and stopped there: setup PR #1 is OPEN on
#            priya-acme/acme (opened by priya-acme, head assemble/setup-20261012-1435), and the notebook
#            folder ../acme-team is a worktree of acme on that branch holding the setup files (the
#            Cyrus, Vito and Bram team of tests/rendered/acme). Priya's own checkout is still on its
#            first commits, untouched. No team on main yet, no leftovers. Writes are allowed after the
#            approval: the fake gh and git work on local bare repos under remotes/.
# What /assemble must do with it: tests/fixtures/open-setup-pr/expected.md. How to run it: tests/checklist.md.
#
# Usage: tests/fixtures/open-setup-pr/setup.sh <new or empty folder>    (for example "$TMPDIR/fx-open-setup-pr")
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../lib/fixture.sh"
. "$here/../../lib/team-fixture.sh"

fixture_begin open-setup-pr "$@"
fixture_repo --origin https://github.com/priya-acme/acme.git --identity --helper
fixture_shims --gh ok --git local-remote --writes
tf_publish
tf_setup_branch "$TF_STAMP" "$here/../../rendered/acme"
tf_exclude
tf_open_pr
tf_finish
fixture_end
