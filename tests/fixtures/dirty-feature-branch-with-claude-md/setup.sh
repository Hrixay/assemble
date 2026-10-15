#!/usr/bin/env bash
# tests/fixtures/dirty-feature-branch-with-claude-md/setup.sh: build the "dirty-feature-branch-with-claude-md" fixture in a new or empty folder.
#
# Simulates: Priya's own private repo priya-acme/acme (admin, not protected, only she commits,
#            two earlier PRs merged) with a CLAUDE.md that has project rules and four rules that
#            conflict with the method, a newest-first LOG.md and docs/decisions.md. She is on
#            the feature branch priya/menu with one unpushed commit, uncommitted edits to
#            CLAUDE.md and src/app.js, and an untracked notes-draft.md: all must stay as they are.
#            Writes are allowed after the write screen, against local bare repos under remotes/.
# What /assemble must do with it: tests/fixtures/dirty-feature-branch-with-claude-md/expected.md. How to run it: tests/checklist.md.
#
# Usage: tests/fixtures/dirty-feature-branch-with-claude-md/setup.sh <new or empty folder>    (for example "$TMPDIR/fx-dirty-feature-branch-with-claude-md")
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../lib/fixture.sh"

fixture_begin dirty-feature-branch-with-claude-md "$@"
fixture_existing --claude-md --log --decisions --merged-prs 2 --feature-branch --identity --helper
fixture_shims --gh ok --git local-remote --gh-repo priya-acme/acme --writes
fixture_end
