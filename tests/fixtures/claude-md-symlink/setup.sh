#!/usr/bin/env bash
# tests/fixtures/claude-md-symlink/setup.sh: build the "claude-md-symlink" fixture in a new or empty folder.
#
# Simulates: Priya's own small private repo priya-acme/acme (admin, not protected, only she
#            commits) whose CLAUDE.md is a symlink to AGENTS.md, which other tools read. Setup
#            must leave both untouched and put the team block in .claude/CLAUDE.md (the safe
#            default). Writes are allowed after the write screen, against local bare repos.
# What /assemble must do with it: tests/fixtures/claude-md-symlink/expected.md. How to run it: tests/checklist.md.
#
# Usage: tests/fixtures/claude-md-symlink/setup.sh <new or empty folder>    (for example "$TMPDIR/fx-claude-md-symlink")
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../lib/fixture.sh"

fixture_begin claude-md-symlink "$@"
fixture_existing --claude-symlink --identity --helper
fixture_shims --gh ok --git local-remote --gh-repo priya-acme/acme --writes
fixture_end
