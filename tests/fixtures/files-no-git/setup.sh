#!/usr/bin/env bash
# tests/fixtures/files-no-git/setup.sh: build the "files-no-git" fixture in a new or empty folder.
#
# Simulates: a new project that already has a few starter files but no git: acme/ holds a page,
#            a script, a note, a package.json whose scripts would leave a REPO-SCRIPT-RAN canary,
#            a .env with a made-up value (and a .env.example), a key-looking dev.pem, a sparse
#            file just over 50 MB and two .DS_Store files. Those last ones must never be
#            committed. git already has a name, the noreply email and the gh credential helper
#            in the fixture's own global config. gh is logged in as priya-acme and knows no repo
#            yet. Writes are allowed after the write screen, against local bare repos under
#            remotes/.
# What /assemble must do with it: tests/fixtures/files-no-git/expected.md. How to run it: tests/checklist.md.
#
# Usage: tests/fixtures/files-no-git/setup.sh <new or empty folder>    (for example "$TMPDIR/fx-files-no-git")
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../lib/fixture.sh"

fixture_begin files-no-git "$@"
fixture_files
fixture_global_identity
fixture_shims --gh ok --git local-remote --gh-repo '' --writes
fixture_end
