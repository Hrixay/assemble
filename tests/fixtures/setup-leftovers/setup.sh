#!/usr/bin/env bash
# tests/fixtures/setup-leftovers/setup.sh: build the "setup-leftovers" fixture in a new or empty folder.
#
# Simulates: a setup that stopped before it opened its pull request, two days ago: the notebook folder
#            ../acme-team is a locked worktree of acme on assemble/setup-20261010-0930 (two files committed),
#            that branch is on GitHub too, and no pull request exists. There is no team on main. Priya's
#            checkout is on main, clean. Cleaning up is allowed after her yes: the fake gh and git work on
#            local bare repos under remotes/.
# What /assemble must do with it: tests/fixtures/setup-leftovers/expected.md. How to run it: tests/checklist.md.
#
# Usage: tests/fixtures/setup-leftovers/setup.sh <new or empty folder>    (for example "$TMPDIR/fx-setup-leftovers")
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../lib/fixture.sh"
. "$here/../../lib/team-fixture.sh"

fixture_begin setup-leftovers "$@"
fixture_repo --origin https://github.com/priya-acme/acme.git --identity --helper
fixture_shims --gh ok --git local-remote --writes
tf_publish
tf_leftover 20261010-0930 "$here/../../rendered/acme"
tf_exclude
tf_finish
fixture_end
