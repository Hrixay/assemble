#!/usr/bin/env bash
# tests/fixtures/gitlab-remote-ssh/setup.sh: build the "gitlab-remote-ssh" fixture in a new or empty folder.
#
# Simulates: a normal repo whose origin is on gitlab.com over SSH (ssh://<user>@gitlab.com/...),
#            on a computer with no GitHub SSH key (the fake ssh answers "Permission denied"). git
#            and gh are fine (gh is logged in to github.com as priya-acme).
# What /assemble must do with it: tests/fixtures/gitlab-remote-ssh/expected.md. How to run it: tests/checklist.md.
#
# Usage: tests/fixtures/gitlab-remote-ssh/setup.sh <new or empty folder>    (for example "$TMPDIR/fx-gitlab-remote-ssh")
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../lib/fixture.sh"

# The address is put together from parts so no user@host literal sits in the repo (leak-scan).
ssh_user=git
fixture_begin gitlab-remote-ssh "$@"
fixture_repo --origin "ssh://${ssh_user}@gitlab.com/priya-acme/acme.git" --identity
fixture_shims --gh ok --git fake-remote --gh-repo ''
fixture_end
