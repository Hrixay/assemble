#!/usr/bin/env bash
# tests/fixtures/gitlab-remote/setup.sh: build the "gitlab-remote" fixture in a new or empty folder.
#
# Simulates: a normal repo whose origin is on gitlab.com, not github.com. git and gh
#            are fine (gh is logged in to github.com as priya-acme).
# What /assemble must do with it: tests/fixtures/gitlab-remote/expected.md. How to run it: tests/checklist.md.
#
# Usage: tests/fixtures/gitlab-remote/setup.sh <new or empty folder>    (for example "$TMPDIR/fx-gitlab-remote")
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../lib/fixture.sh"

fixture_begin gitlab-remote "$@"
fixture_repo --origin https://gitlab.com/priya-acme/acme.git --identity --helper
fixture_shims --gh ok --git fake-remote --gh-repo ''
fixture_end
