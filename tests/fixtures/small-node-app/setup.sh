#!/usr/bin/env bash
# tests/fixtures/small-node-app/setup.sh: build the "small-node-app" fixture in a new or empty folder.
#
# Simulates: an existing Node app that is Priya's own: a private GitHub repo priya-acme/acme
#            (admin, main not protected, no rulesets), about 80 files with a src/ and a test/
#            folder and `npm test` in package.json (a canary: running it leaves REPO-SCRIPT-RAN),
#            and a CI workflow that only runs the tests. Only Priya committed. No CLAUDE.md, no
#            notes files, no PR template, nothing that deploys; .env.example names MAIL_API_KEY
#            and MAIL_FROM (a paid email service). Writes are allowed after the write screen,
#            against local bare repos under remotes/.
# What /assemble must do with it: tests/fixtures/small-node-app/expected.md. How to run it: tests/checklist.md.
#
# Usage: tests/fixtures/small-node-app/setup.sh <new or empty folder>    (for example "$TMPDIR/fx-small-node-app")
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../lib/fixture.sh"

fixture_begin small-node-app "$@"
fixture_existing --size medium --ci --mail-keys --identity --helper
fixture_shims --gh ok --git local-remote --gh-repo priya-acme/acme --writes
fixture_end
