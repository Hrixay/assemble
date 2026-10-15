#!/usr/bin/env bash
# tests/fixtures/gh-logged-out/setup.sh: build the "gh-logged-out" fixture in a new or empty folder.
#
# Simulates: gh is installed but not logged in to GitHub: `gh auth status` says
#            "You are not logged into any GitHub hosts", and `gh auth login` prints a fake
#            one-time code (FAKE-0000) and logs in nobody.
# What /assemble must do with it: tests/fixtures/gh-logged-out/expected.md. How to run it: tests/checklist.md.
#
# Usage: tests/fixtures/gh-logged-out/setup.sh <new or empty folder>    (for example "$TMPDIR/fx-gh-logged-out")
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../lib/fixture.sh"

fixture_begin gh-logged-out "$@"
fixture_repo --origin https://github.com/priya-acme/acme.git --identity --helper
fixture_shims --gh logged-out --git fake-remote
fixture_end
