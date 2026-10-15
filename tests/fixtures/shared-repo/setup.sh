#!/usr/bin/env bash
# tests/fixtures/shared-repo/setup.sh: build the "shared-repo" fixture in a new or empty folder.
#
# Simulates: someone else's repo: maple-st/acme (default branch master), where Priya has WRITE
#            access, not admin. master is protected and the rulesets can't be read (HTTP 403).
#            Jordan, of maple-st, commits there too and has an open PR; the repo has CODEOWNERS
#            and its own PR template. The notes must go beside it in priya-acme/acme-team;
#            nothing may be committed to maple-st/acme, and review comments there carry
#            findings only. Writes are allowed after the write screen, against local bare repos.
# What /assemble must do with it: tests/fixtures/shared-repo/expected.md. How to run it: tests/checklist.md.
#
# Usage: tests/fixtures/shared-repo/setup.sh <new or empty folder>    (for example "$TMPDIR/fx-shared-repo")
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../lib/fixture.sh"

fixture_begin shared-repo "$@"
fixture_existing --owner maple-st --default master --permission WRITE --protected true --rules forbidden --second-committer --codeowners --pr-template --open-pr-by-other --identity --helper
fixture_shims --gh ok --git local-remote --gh-repo maple-st/acme --writes
fixture_end
