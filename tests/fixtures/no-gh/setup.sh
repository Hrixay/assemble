#!/usr/bin/env bash
# tests/fixtures/no-gh/setup.sh: build the "no-gh" fixture in a new or empty folder.
#
# Simulates: git works and the repo is a normal github.com repo, but the GitHub CLI (gh)
#            isn't installed: the fake gh on PATH answers "command not found" (exit 127).
# What /assemble must do with it: tests/fixtures/no-gh/expected.md. How to run it: tests/checklist.md.
#
# Usage: tests/fixtures/no-gh/setup.sh <new or empty folder>    (for example "$TMPDIR/fx-no-gh")
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../lib/fixture.sh"

fixture_begin no-gh "$@"
fixture_repo --origin https://github.com/priya-acme/acme.git --identity --helper
fixture_shims --gh missing --git fake-remote
fixture_end
