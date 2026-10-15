#!/usr/bin/env bash
# check-untouched.sh: after a fixture run, check that nothing was written.
#
# It compares the fixture folder with the snapshot its setup.sh took (before.txt): the folder's
# names (a new <repo>-team folder shows here), the repo's HEAD, refs, worktrees, repo config,
# status (untracked and ignored files too, so a REPO-SCRIPT-RAN canary shows), info/exclude,
# the isolated git home and the gh config folder. Then it reads calls.log, where the shims
# mark every refused write.
#
# Usage: tests/check-untouched.sh FIXTURE_FOLDER
# Exit:  0 = untouched and no refused write, 1 = something changed or a write was refused,
#        2 = could not run.
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
LC_ALL=C
export LC_ALL

cant() { printf 'check-untouched: %s\n' "$*" >&2; exit 2; }

[ "$#" -eq 1 ] || cant "usage: tests/check-untouched.sh FIXTURE_FOLDER"
[ -d "$1" ] || cant "$1 is not a folder"
root=$(CDPATH= cd -- "$1" && pwd -P)
[ -f "$root/before.txt" ] && [ -f "$root/calls.log" ] && [ -f "$root/FIXTURE" ] ||
  cant "$root is not a fixture folder (no before.txt, calls.log or FIXTURE)"

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/lib/fixture.sh"

# The real git: PATH without the fixture's shim folder.
clean_path=$(printf '%s\n' "$PATH" | tr ':' '\n' | grep -v -x -F "$root/bin" | paste -s -d: -)
git_bin=$(PATH=$clean_path command -v git) || cant "git is not installed"
if grep -q 'assemble-fixture-shim' "$git_bin" 2>/dev/null; then
  cant "git on PATH is another fixture's shim; open a new terminal"
fi

fixture_snapshot "$root" "$git_bin" > "$root/after.txt"

status=0
printf 'Fixture: %s (%s)\n' "$(cat "$root/FIXTURE")" "$root"
if diff -u "$root/before.txt" "$root/after.txt" > "$root/changes.diff"; then
  rm -f "$root/changes.diff"
  echo "ok    nothing changed since setup"
else
  echo "FAIL  something changed since setup:"
  sed -e 's/^/      /' "$root/changes.diff"
  status=1
fi

refused=$(grep -c '^REFUSED ' "$root/calls.log" || true)
if [ "$refused" -gt 0 ]; then
  echo "FAIL  $refused write(s) refused by the shims (each one was an attempt to write):"
  grep '^REFUSED ' "$root/calls.log" | sed -e 's/^/      /'
  status=1
else
  echo "ok    no write was attempted through gh or git"
fi

unsupported=$(grep -c '^UNSUPPORTED ' "$root/calls.log" || true)
if [ "$unsupported" -gt 0 ]; then
  echo "note  $unsupported read(s) the shims can't fake (not writes):"
  grep '^UNSUPPORTED ' "$root/calls.log" | sed -e 's/^/      /'
fi
if grep -q '^gh auth login' "$root/calls.log"; then
  echo "note  gh auth login was run; that is allowed only after the user said yes to it"
fi

ssh_calls=$(grep -c '^ssh ' "$root/calls.log" || true)
if [ "$ssh_calls" -gt 0 ]; then
  echo "note  $ssh_calls ssh call(s) (the fake ssh never connects); preflight may run the SSH test only when origin is on github.com:"
  grep '^ssh ' "$root/calls.log" | sed -e 's/^/      /'
fi

total=$(grep -c -v -e '^REFUSED ' -e '^UNSUPPORTED ' "$root/calls.log" || true)
echo "      $total gh/git/ssh call(s) in $root/calls.log"
exit "$status"
