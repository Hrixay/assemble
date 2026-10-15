#!/usr/bin/env bash
# tests/fixtures/offline/setup.sh: build the "offline" fixture in a new or empty folder.
#
# Simulates: no network: gh is installed and has an account, but every gh call fails to
#            connect (`gh auth status` reports a timeout), and git fetch and git ls-remote fail
#            with "Could not resolve host: github.com".
# What /assemble must do with it: tests/fixtures/offline/expected.md. How to run it: tests/checklist.md.
#
# Usage: tests/fixtures/offline/setup.sh <new or empty folder>    (for example "$TMPDIR/fx-offline")
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../lib/fixture.sh"

fixture_begin offline "$@"
fixture_repo --origin https://github.com/priya-acme/acme.git --identity --helper
fixture_shims --gh offline --git offline
fixture_end
