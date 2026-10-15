#!/usr/bin/env bash
# tests/fixtures/empty-dir/setup.sh: build the "empty-dir" fixture in a new or empty folder.
#
# Simulates: a brand-new project: the folder acme/ is empty and not a git repo. gh is logged in
#            as priya-acme over HTTPS and knows no repo yet (priya-acme/acme and
#            priya-acme/acme-team don't exist). No git name, email or credential helper is set
#            anywhere the run can see. Writes are allowed after the write screen: the fake gh
#            creates repos and pull requests on local bare repos under remotes/, and the fake
#            git pushes there, so the whole New path runs offline.
# What /assemble must do with it: tests/fixtures/empty-dir/expected.md. How to run it: tests/checklist.md.
#
# Usage: tests/fixtures/empty-dir/setup.sh <new or empty folder>    (for example "$TMPDIR/fx-empty-dir")
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../lib/fixture.sh"

fixture_begin empty-dir "$@"
fixture_empty
fixture_shims --gh ok --git local-remote --gh-repo '' --writes
fixture_end
