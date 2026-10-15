#!/usr/bin/env bash
# tests/fixtures/deploys-on-main/setup.sh: build the "deploys-on-main" fixture in a new or empty folder.
#
# Simulates: Priya's own repo priya-acme/acme, but PUBLIC, with a workflow that publishes the
#            site to GitHub Pages on every push to main, and a second person (Jordan) who
#            committed in the last 90 days and has an open PR. The notes must go beside the
#            repo, in a new private repo priya-acme/acme-team, and nothing may be committed to
#            priya-acme/acme. git has a name and email only in the project repo's own config.
#            .env.example names MAIL_API_KEY and MAIL_FROM (a paid email service).
#            Writes are allowed after the write screen, against local bare repos under remotes/.
# What /assemble must do with it: tests/fixtures/deploys-on-main/expected.md. How to run it: tests/checklist.md.
#
# Usage: tests/fixtures/deploys-on-main/setup.sh <new or empty folder>    (for example "$TMPDIR/fx-deploys-on-main")
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../lib/fixture.sh"

fixture_begin deploys-on-main "$@"
fixture_existing --deploy --second-committer --visibility PUBLIC --open-pr-by-other --mail-keys --identity --helper
fixture_shims --gh ok --git local-remote --gh-repo priya-acme/acme --writes
fixture_end
