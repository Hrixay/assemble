#!/usr/bin/env bash
# tests/fixtures/no-git-identity/setup.sh: build the "no-git-identity" fixture in a new or empty folder.
#
# Simulates: everything passes except git identity: no user.name or user.email in
#            any git config the run can see (the tester's own settings are shut out). gh is
#            logged in as priya-acme, the repo is private, unprotected, and Priya is ADMIN.
# What /assemble must do with it: tests/fixtures/no-git-identity/expected.md. How to run it: tests/checklist.md.
#
# Usage: tests/fixtures/no-git-identity/setup.sh <new or empty folder>    (for example "$TMPDIR/fx-no-git-identity")
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../lib/fixture.sh"

fixture_begin no-git-identity "$@"
fixture_repo --origin https://github.com/priya-acme/acme.git --helper
fixture_shims --gh ok --git fake-remote
fixture_end
