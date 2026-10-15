#!/usr/bin/env bash
# build-fixtures.sh: build every fixture in a scratch folder and check that each one is the state
# its expected.md assumes. (tests/new-path-test.sh runs the New path's writes on empty-dir and
# files-no-git, and tests/existing-path-test.sh the Existing path's on the five existing-repo
# fixtures; this script checks only their state before the write screen.) It needs no Claude session: it runs the shims the way
# the skill would, checks their answers, then checks that tests/check-untouched.sh passes on
# each fresh build and catches a refused write and a new folder.
#
# Usage: tests/build-fixtures.sh [--keep]      (--keep leaves the scratch folder in place)
# Exit:  0 = every check passed, 1 = at least one failed.
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
LC_ALL=C
export LC_ALL

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
keep=no
[ "${1:-}" != --keep ] || keep=yes
work=$(mktemp -d "${TMPDIR:-/tmp}/assemble-fixtures.XXXXXX")
if [ "$keep" = yes ]; then echo "scratch folder: $work"; else trap 'rm -rf "$work"' EXIT; fi

fails=0
ok() { printf 'ok    %s\n' "$*"; }
bad() { printf 'FAIL  %s\n' "$*"; fails=$((fails + 1)); }

# expect DIR WANT_RC PATTERN CMD...: run CMD in DIR/acme with DIR/env.sh loaded, then check the
# exit code and that the output (stdout and stderr) matches PATTERN (empty = don't check).
expect() {
  local dir=$1 want=$2 pat=$3 out rc
  shift 3
  out=$( ( . "$dir/env.sh"; cd "$dir/acme"; "$@" ) 2>&1 ) && rc=0 || rc=$?
  if [ "$rc" != "$want" ]; then
    bad "$(basename "$dir"): \"$*\" exited $rc, expected $want"
  elif [ -n "$pat" ] && ! printf '%s\n' "$out" | grep -q -e "$pat"; then
    bad "$(basename "$dir"): \"$*\" output has no \"$pat\""
  else
    ok "$(basename "$dir"): \"$*\" exits $rc"
  fi
}

build() { # build FIXTURE FOLDER
  if bash "$root/tests/fixtures/$1/setup.sh" "$2" > "$work/build.log" 2>&1; then
    ok "$1 builds in $(basename "$2")"
  else
    bad "$1 did not build:"; sed -e 's/^/      /' "$work/build.log"
    return 1
  fi
}

untouched() { # untouched FOLDER WANT_EXIT
  local rc
  bash "$root/tests/check-untouched.sh" "$1" > "$work/check.log" 2>&1 && rc=0 || rc=$?
  if [ "$rc" = "$2" ]; then
    ok "$(basename "$1"): check-untouched exits $rc"
  else
    bad "$(basename "$1"): check-untouched exited $rc, expected $2:"; sed -e 's/^/      /' "$work/check.log"
  fi
}

for name in no-gh gh-logged-out no-git-identity gitlab-remote gitlab-remote-ssh offline empty-dir files-no-git \
  small-node-app dirty-feature-branch-with-claude-md claude-md-symlink deploys-on-main shared-repo; do
  echo "== $name"
  d="$work/$name"
  build "$name" "$d" || continue
  case "$name" in
    no-gh)
      expect "$d" 0 'git version' git --version
      expect "$d" 127 'command not found' gh --version ;;
    gh-logged-out)
      expect "$d" 0 'gh version' gh --version
      expect "$d" 1 'not logged into any GitHub hosts' gh auth status
      expect "$d" 4 'gh auth login' gh repo view priya-acme/acme --json viewerPermission ;;
    no-git-identity)
      expect "$d" 0 'Logged in to github.com account priya-acme' gh auth status
      expect "$d" 1 '' git config --get user.name
      expect "$d" 1 '' git config --get user.email
      expect "$d" 0 'gh auth git-credential' git config --get credential.https://github.com.helper
      expect "$d" 0 '12345678' gh api user --jq '.id, .login, .name'
      expect "$d" 0 '"viewerPermission":"ADMIN"' gh repo view priya-acme/acme --json viewerPermission,visibility,defaultBranchRef,isFork,parent
      expect "$d" 0 'false' gh api repos/priya-acme/acme/branches/main --jq .protected
      expect "$d" 0 '^\[\]$' gh api repos/priya-acme/acme/rules/branches/main
      expect "$d" 0 '' git fetch origin
      expect "$d" 0 '^\[\]$' gh pr list --repo priya-acme/acme --state open --json number,headRefName,url --limit 100
      expect "$d" 1 'Could not resolve to a Repository' gh repo view priya-acme/acme-team --json name,defaultBranchRef
      expect "$d" 128 'does not exist' git show origin/main:team/assemble.json
      expect "$d" 0 'refs/heads/main' git ls-remote --heads origin main ;;
    gitlab-remote)
      expect "$d" 0 'gitlab.com' git remote get-url origin
      expect "$d" 0 'Logged in to github.com' gh auth status
      expect "$d" 1 'none of the git remotes' gh repo view --json viewerPermission ;;
    gitlab-remote-ssh)
      expect "$d" 0 '^ssh://.*@gitlab[.]com/priya-acme/acme[.]git$' git remote get-url origin
      expect "$d" 0 'Logged in to github.com' gh auth status
      expect "$d" 255 'Permission denied' ssh -T -o BatchMode=yes -l git github.com ;;
    offline)
      expect "$d" 0 'gh version' gh --version
      expect "$d" 1 'Timeout trying to log in' gh auth status
      expect "$d" 1 'error connecting to api.github.com' gh api user
      expect "$d" 128 'Could not resolve host: github.com' git fetch origin
      expect "$d" 128 'Could not resolve host: github.com' git ls-remote --heads origin main ;;
    empty-dir|files-no-git)
      expect "$d" 0 'Logged in to github.com account priya-acme' gh auth status
      expect "$d" 128 'not a git repository' git rev-parse --is-inside-work-tree
      expect "$d" 1 'Could not resolve to a Repository' gh repo view priya-acme/acme --json name
      expect "$d" 1 'Could not resolve to a Repository' gh repo view priya-acme/acme-team --json name,defaultBranchRef
      expect "$d" 0 '12345678' gh api user --jq '.id, .login, .name'
      if [ "$name" = empty-dir ]; then
        expect "$d" 1 '' git config --get user.name
        expect "$d" 1 '' git config --get credential.https://github.com.helper
        if [ -z "$(ls -A "$d/acme")" ]; then ok "empty-dir: acme/ is empty"; else bad "empty-dir: acme/ is not empty"; fi
      else
        expect "$d" 0 'Priya Example' git config --get user.name
        expect "$d" 0 'noreply' git config --get user.email
        expect "$d" 0 'gh auth git-credential' git config --get credential.https://github.com.helper
        for f in index.html app.js notes/ideas.md package.json .env .env.example dev.pem video.raw; do
          if [ -e "$d/acme/$f" ]; then ok "files-no-git: acme/$f exists"; else bad "files-no-git: acme/$f is missing"; fi
        done
        if [ -n "$(cd "$d/acme" && find . -type f -size +50M)" ]; then ok "files-no-git: one file is over 50 MB"; else bad "files-no-git: no file over 50 MB"; fi
      fi ;;
    small-node-app|dirty-feature-branch-with-claude-md|claude-md-symlink|deploys-on-main)
      r=priya-acme/acme
      expect "$d" 0 'Logged in to github.com account priya-acme' gh auth status
      expect "$d" 0 'gh auth git-credential' git config --get credential.https://github.com.helper
      expect "$d" 0 '"defaultBranchRef":{"name":"main"}' gh repo view "$r" --json viewerPermission,visibility,isPrivate,defaultBranchRef,isFork,parent
      expect "$d" 0 '"viewerPermission":"ADMIN"' gh repo view "$r" --json viewerPermission,visibility,isPrivate,defaultBranchRef,isFork,parent
      expect "$d" 0 '^false$' gh api "repos/$r/branches/main" --jq .protected
      expect "$d" 0 '^\[\]$' gh api "repos/$r/rules/branches/main"
      expect "$d" 0 '' git fetch origin
      expect "$d" 1 'Could not resolve to a Repository' gh repo view priya-acme/acme-team --json name,defaultBranchRef
      expect "$d" 128 'does not exist' git show origin/main:team/assemble.json
      expect "$d" 1 'HTTP 404' gh api "repos/$r/pages" --jq .source
      expect "$d" 1 '' git config --get core.hooksPath
      case "$name" in
        small-node-app)
          expect "$d" 0 '"visibility":"PRIVATE"' gh repo view "$r" --json visibility,isPrivate
          expect "$d" 0 '^78$' bash -c 'git ls-tree -r --name-only origin/main | grep -c .'
          expect "$d" 0 '^35$' bash -c 'git ls-tree -r --name-only origin/main | grep -c "^test/.*\.test\.js$"'
          expect "$d" 0 'npm test' git show origin/main:.github/workflows/ci.yml
          expect "$d" 128 'does not exist' git show origin/main:CLAUDE.md
          expect "$d" 0 '^ *4[[:space:]]Priya Example$' git shortlog -sn --since=90.days origin/main
          expect "$d" 0 '^\[\]$' gh pr list --repo "$r" --state open --json number,headRefName,url,author --limit 100
          expect "$d" 0 '^null$' gh api "repos/$r/issues?state=all&per_page=1" --jq '.[0].number' ;;
        dirty-feature-branch-with-claude-md)
          expect "$d" 0 '^priya/menu$' git branch --show-current
          expect "$d" 0 '^ M CLAUDE.md$' git status --porcelain
          expect "$d" 0 '^?? notes-draft.md$' git status --porcelain
          expect "$d" 0 'Local draft rule' cat CLAUDE.md
          expect "$d" 0 'Commit straight to main for small fixes' git show origin/main:CLAUDE.md
          expect "$d" 0 'Newest first' git show origin/main:LOG.md
          expect "$d" 0 'Bookings by email' git show origin/main:docs/decisions.md
          expect "$d" 0 '"state":"MERGED"' gh pr list --repo "$r" --state all --json number,state
          expect "$d" 0 '^2$' gh api "repos/$r/issues?state=all&per_page=1" --jq '.[0].number' ;;
        claude-md-symlink)
          expect "$d" 0 '^120000 ' git ls-files -s -- CLAUDE.md
          expect "$d" 0 '^AGENTS.md' git show origin/main:CLAUDE.md
          expect "$d" 0 '2-space indentation' git show origin/main:AGENTS.md ;;
        deploys-on-main)
          expect "$d" 0 '"visibility":"PUBLIC"' gh repo view "$r" --json visibility,isPrivate
          expect "$d" 0 '"isPrivate":false' gh repo view "$r" --json visibility,isPrivate
          expect "$d" 0 'actions/deploy-pages' git show origin/main:.github/workflows/deploy.yml
          expect "$d" 0 'Jordan Example' git shortlog -sn --since=90.days origin/main
          expect "$d" 0 '"login":"jordan-acme"' gh pr list --repo "$r" --state open --json number,author
          expect "$d" 1 '' git -C . config --global --get user.email ;;
      esac ;;
    shared-repo)
      r=maple-st/acme
      expect "$d" 0 '"owner":{"login":"maple-st"}' gh repo view "$r" --json viewerPermission,visibility,isPrivate,defaultBranchRef,isFork,parent
      expect "$d" 0 '"viewerPermission":"WRITE"' gh repo view "$r" --json viewerPermission,visibility,isPrivate,defaultBranchRef,isFork,parent
      expect "$d" 0 '"defaultBranchRef":{"name":"master"}' gh repo view "$r" --json defaultBranchRef
      expect "$d" 0 '^true$' gh api "repos/$r/branches/master" --jq .protected
      expect "$d" 1 'HTTP 403' gh api "repos/$r/rules/branches/master"
      expect "$d" 0 'refs/remotes/origin/master' git symbolic-ref refs/remotes/origin/HEAD
      expect "$d" 0 'Jordan Example' git shortlog -sn --since=90.days origin/master
      expect "$d" 0 '"login":"jordan-acme"' gh pr list --repo "$r" --state open --json number,author
      expect "$d" 0 '## Summary' git show origin/master:.github/pull_request_template.md
      expect "$d" 0 '' git fetch origin ;;
  esac
  untouched "$d" 0
done

echo "== guards"
if build no-gh "$work/no-gh-again" 2>/dev/null && bash "$root/tests/fixtures/no-gh/setup.sh" "$work/no-gh-again" > /dev/null 2>&1; then
  bad "setup.sh accepted a folder that is not empty"
else
  ok "setup.sh refuses a folder that is not empty"
fi
g="$work/guard-write"
if build no-git-identity "$g"; then
  expect "$g" 1 'refused' git commit --allow-empty -m probe
  expect "$g" 1 'refused' gh pr create --fill
  untouched "$g" 1
fi
g="$work/guard-read-only"
if build no-git-identity "$g"; then
  # Reads that can still write a file or delete a ref must be refused, and must change nothing.
  expect "$g" 1 'refused' git diff --output=leaked.txt
  expect "$g" 1 'refused' git log --output=leaked.txt
  expect "$g" 1 'refused' git symbolic-ref -d refs/remotes/origin/HEAD
  expect "$g" 1 'refused' git symbolic-ref --delete refs/remotes/origin/HEAD
  expect "$g" 1 'refused' git symbolic-ref -qd refs/remotes/origin/HEAD
  if [ -e "$g/acme/leaked.txt" ]; then bad "git --output wrote a file through the shim"; else ok "git --output wrote no file"; fi
  expect "$g" 0 'refs/remotes/origin/main' git symbolic-ref refs/remotes/origin/HEAD
  expect "$g" 0 'refs/heads/main' git symbolic-ref -q HEAD
  expect "$g" 0 '' git diff --stat
  expect "$g" 0 '^origin/main$' git symbolic-ref --short -q refs/remotes/origin/HEAD
  untouched "$g" 1
fi
g="$work/guard-write-gate"
if build empty-dir "$g"; then
  # A fixture built with writes still refuses every write until the write gate exists.
  expect "$g" 1 'refused' git init -b main
  expect "$g" 1 'refused' gh repo create priya-acme/acme --private --source . --remote origin --push
  expect "$g" 1 'refused' gh pr merge 1
  untouched "$g" 1
fi
g="$work/guard-existing"
if build small-node-app "$g"; then
  # An existing-repo fixture also refuses every write until the gate, and never creates a repo
  # for another owner.
  expect "$g" 1 'refused' git worktree add --no-track -b assemble/setup-x ../acme-team origin/main
  expect "$g" 1 'refused' git push -u origin HEAD
  expect "$g" 1 'refused' gh pr create --repo priya-acme/acme --base main --head main --title x --body x
  untouched "$g" 1
fi
g="$work/guard-folder"
if build gitlab-remote "$g"; then
  mkdir "$g/acme-team"
  untouched "$g" 1
fi

echo
if [ "$fails" -eq 0 ]; then
  echo "build-fixtures: all checks passed"
else
  echo "build-fixtures: $fails check(s) failed"
  exit 1
fi
