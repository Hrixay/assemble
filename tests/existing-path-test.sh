#!/usr/bin/env bash
# existing-path-test.sh: run the Existing path's git and gh steps end to end, offline, the way
# skills/assemble/reference/scan.md and git-model.md list them, on the five existing-repo fixtures.
# No Claude session is needed: this script plays the setup chat (the scan's reads, then the
# commands after the write screen), then the notebook writer and the human, and checks what lands
# where. The files the setup chat would write are the hand-rendered examples (tests/rendered/acme,
# acme-small and lemonade), changed the way interview.md part G8 says for each case.
#
#   small-node-app                       in-repo, Standard: a new CLAUDE.md, missing .gitignore lines
#                                        appended, setup PR #1, merge gate, after-merge switch
#   dirty-feature-branch-with-claude-md  in-repo, Small: the user's feature branch, its unpushed
#                                        commit and uncommitted edits stay exactly as they were;
#                                        the block is appended to main's CLAUDE.md (not the edited
#                                        one); LOG.md adopted (manifest, owner row, setup entry);
#                                        docs/decisions.md left as it is; the PR number predicted
#                                        (#3) and the PR holds only the listed files
#   claude-md-symlink                    in-repo: CLAUDE.md (a link) and AGENTS.md untouched; the
#                                        block goes in .claude/CLAUDE.md with @../team/CHATS.md
#   deploys-on-main                      beside-repo: a new private notes repo with the project's
#                                        git identity, its own setup PR #1; zero committed
#                                        footprint in the project repo
#   shared-repo                          beside-repo for someone else's repo (master, protected,
#                                        rulesets unreadable): zero footprint there; a doer's work
#                                        PR on the real repo; the merge gate's head check
#
# Four more cases use fixtures built here from tests/lib/fixture.sh (no folder under fixtures/):
#   busy-config                          the scan's listing on 41 files under .claude/ and 45
#                                        workflows: CLAUDE.md, LOG.md and package.json still listed
#   existing-no-identity                 in-repo with no git name or email: D1's identity lines,
#                                        so the setup commit carries the noreply address
#   no-remote                            in-repo for a repo with no remote: D1 creates the private
#                                        repo and pushes main, then the usual setup PR #1
#   husky-hooks                          in-repo, the project's pre-commit hook fails in the fresh
#                                        notebook folder; D6's cleanup, then beside-repo works
#
# Every case also checks: the scan's listing command, copied from scan.md, runs on the fakes and
# finds what the fixture holds; the reads change nothing (tests/check-untouched.sh); no command is
# refused by the shims' rule guards; no project script ran. And Cancel: reads only, nothing written.
#
# Usage: tests/existing-path-test.sh [--keep]      (--keep leaves the scratch folder in place)
# Exit:  0 = every check passed, 1 = at least one failed.
# Portable bash: macOS bash 3.2 and Linux. No GNU-only flags.

set -eu
LC_ALL=C
export LC_ALL
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
keep=no
[ "${1:-}" != --keep ] || keep=yes
work=$(mktemp -d "${TMPDIR:-/tmp}/assemble-existing.XXXXXX")
work=$(CDPATH= cd -- "$work" && pwd -P)
if [ "$keep" = yes ]; then echo "scratch folder: $work"; else trap 'rm -rf "$work"' EXIT; fi
REAL_GIT=$(command -v git)

STAMP=20261013-0930
BRANCH="assemble/setup-$STAMP"
NAME='Priya Example'
EMAIL='12345678+priya-acme@users.noreply.github.com'

fails=0
checks=0
ok() { checks=$((checks + 1)); printf 'ok    %s\n' "$*"; }
bad() { checks=$((checks + 1)); fails=$((fails + 1)); printf 'FAIL  %s\n' "$*"; }
show() { printf '%s\n' "$OUT" | sed 's/^/      | /'; }

# run_in FX DIR CMD...: run CMD in DIR with the fixture's env.sh loaded. Output in $OUT, code in $RC.
run_in() {
  fx=$1 dir=$2
  shift 2
  OUT=$( ( . "$fx/env.sh"; cd "$dir"; "$@" ) 2>&1 ) && RC=0 || RC=$?
}
must() {
  run_in "$@"
  shift 2
  if [ "$RC" = 0 ]; then ok "$*"; else bad "\"$*\" exited $RC"; show; fi
}
must_rc() {
  want=$1
  shift
  run_in "$@"
  shift 2
  if [ "$RC" = "$want" ]; then ok "\"$*\" exits $want"; else bad "\"$*\" exited $RC, expected $want"; show; fi
}
same() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1: got \"$2\", expected \"$3\""; fi; }
has() { if printf '%s\n' "$2" | grep -Eq -- "$3"; then ok "$1"; else bad "$1: no \"$3\" in:"; printf '%s\n' "$2" | sed 's/^/      | /'; fi; }
lacks() { if printf '%s\n' "$2" | grep -Eq -- "$3"; then bad "$1: found \"$3\" in:"; printf '%s\n' "$2" | sed 's/^/      | /'; else ok "$1"; fi; }
# The real git on a fixture's files, outside the shims.
other_git() {
  env HOME="$fxdir/git-home" GIT_CONFIG_GLOBAL="$fxdir/git-home/.gitconfig" GIT_CONFIG_NOSYSTEM=1 \
    GIT_TERMINAL_PROMPT=0 GIT_CEILING_DIRECTORIES="$work" \
    "$REAL_GIT" -c user.name="$NAME" -c user.email="$EMAIL" "$@"
}
# inline_fixture NAME DIR: build a test-only fixture (listed at the top) with tests/lib/fixture.sh.
inline_fixture() {
  case "$1" in
    busy-config) gr=priya-acme/acme; set -- "$1" "$2" --claude-md --log --many-config --identity --helper ;;
    existing-no-identity) gr=priya-acme/acme; set -- "$1" "$2" --helper ;;
    no-remote) gr=''; set -- "$1" "$2" --no-remote --identity --helper ;;
    husky-hooks) gr=priya-acme/acme; set -- "$1" "$2" --husky --identity --helper ;;
    *) echo "no fixture named $1"; return 1 ;;
  esac
  ifname=$1 ifdir=$2
  shift 2
  # Its own bash, so set -e holds inside the fixture helpers (it doesn't under "build && ...").
  bash -eu -c '. "$1/tests/lib/fixture.sh"; n=$2 d=$3 gr=$4; shift 4
    fixture_begin "$n" "$d"; fixture_existing "$@"
    fixture_shims --gh ok --git local-remote --gh-repo "$gr" --writes; fixture_end' inline-fixture "$root" "$ifname" "$ifdir" "$gr" "$@"
}
build() { # build FIXTURE DIR: a fixture folder's setup.sh, or a test-only fixture (inline_fixture)
  if [ -f "$root/tests/fixtures/$1/setup.sh" ]; then
    bash "$root/tests/fixtures/$1/setup.sh" "$2" > "$work/build.log" 2>&1 && brc=0 || brc=$?
  else
    inline_fixture "$1" "$2" > "$work/build.log" 2>&1 && brc=0 || brc=$?
  fi
  if [ "$brc" = 0 ]; then
    ok "$1 builds in $(basename "$2")"
  else
    bad "$1 did not build:"; sed -e 's/^/      /' "$work/build.log"
    return 1
  fi
}
untouched() {
  if bash "$root/tests/check-untouched.sh" "$1" > "$work/check.log" 2>&1; then rc=0; else rc=$?; fi
  if [ "$rc" = "$2" ]; then ok "$(basename "$1"): check-untouched exits $rc"; else bad "$(basename "$1"): check-untouched exited $rc, expected $2"; sed -e 's/^/      /' "$work/check.log"; fi
}
calls_clean() {
  if grep -q -e '^REFUSED ' -e '^UNSUPPORTED ' "$1/calls.log"; then
    bad "$(basename "$1"): the shims refused or couldn't answer a call:"; grep -e '^REFUSED ' -e '^UNSUPPORTED ' "$1/calls.log" | sed 's/^/      /'
  else
    ok "$(basename "$1"): no call was refused by the shims ($(grep -c . "$1/calls.log") calls)"
  fi
}
exclude_cmd() {
  printf '( cd "%s" && f="$(git rev-parse --git-path info/exclude)" && mkdir -p "$(dirname "$f")" && { grep -qxF '"'"'.claude/worktrees/'"'"' "$f" 2>/dev/null || printf '"'"'%%s\\n'"'"' '"'"'.claude/worktrees/'"'"' >> "$f"; } )' "$1"
}
check_output() { # check_output DIR LABEL
  if bash "$root/scripts/check-output.sh" "$1" > "$work/co.log" 2>&1; then ok "check-output passes on $2"; else bad "check-output failed on $2:"; sed 's/^/      /' "$work/co.log"; fi
}
# The scan's listing command, exactly as scan.md part B prints it (the first ```sh block).
awk '/^```sh$/ { on = 1; next } on && /^```$/ { exit } on' "$root/skills/assemble/reference/scan.md" > "$work/listing.tpl"
if grep -q 'git ls-tree -r "<ref>"' "$work/listing.tpl"; then ok "scan.md part B has the listing command"; else bad "scan.md part B: no listing command found"; fi
listing() { # listing FX REF: run scan.md's listing command in the fixture's acme/
  sed "s|<ref>|$2|g" "$work/listing.tpl" > "$work/listing.sh"
  run_in "$1" "$1/acme" bash "$work/listing.sh"
}
# The marked CLAUDE.md block of a rendered example (begin to end marker).
block_of() { awk 'index($0, "<!-- assemble:begin") { on = 1 } on { print } index($0, "<!-- assemble:end -->") { exit }' "$1"; }
# copy_tree SRC DEST LIST: copy every file of SRC into DEST, listing the paths in LIST.
copy_tree() {
  ( cd "$1" && find . -type f | sed 's|^\./||' | sort ) > "$3"
  while IFS= read -r p; do
    mkdir -p "$2/$(dirname "$p")"
    cp "$1/$p" "$2/$p"
  done < "$3"
}
# only_adds LABEL PATH: the staged change to PATH in $NB adds lines and removes none.
only_adds() {
  run_in "$fxdir" "$NB" git -C "$NB" diff --cached --numstat -- "$2"
  added=$(printf '%s\n' "$OUT" | awk '{ print $1 }')
  removed=$(printf '%s\n' "$OUT" | awk '{ print $2 }')
  if [ -n "$added" ] && [ "$added" != 0 ] && [ "$removed" = 0 ]; then
    ok "$1: $2 only gains lines ($added added, none removed or changed)"
  else
    bad "$1: $2 must only gain lines (numstat: $OUT)"
  fi
}
# The checkout state the setup chat records before writing (interview.md part G8): branch, HEAD,
# status, a fingerprint of every uncommitted edit, and the stash.
record() {
  printf '%s\n%s\n%s\n%s\n%s\n' "$(other_git -C "$1" branch --show-current)" "$(other_git -C "$1" rev-parse HEAD)" \
    "$(other_git -C "$1" status --porcelain --untracked-files=all)" \
    "$(other_git -C "$1" diff HEAD | other_git hash-object --stdin)" "$(other_git -C "$1" stash list)"
}

# ------------------------------------------------------------------------------------------------
# The scan: reads only. Checks the facts each fixture's expected.md relies on.
scan_case() { # scan_case FIXTURE FXDIR DEFAULT
  f=$1 fx=$2 d=$3
  m="$fx/acme"
  ref="origin/$d"
  if [ "$f" = no-remote ]; then
    # scan.md part A: no remote, so <ref> is the local default branch.
    run_in "$fx" "$m" git remote -v
    same "$f: no remote at all" "$OUT" ''
    run_in "$fx" "$m" git branch --list main master
    same "$f: <ref> is the local default branch" "$(printf '%s' "$OUT" | tr -d ' *')" "$d"
    ref=$d
  fi
  listing "$fx" "$ref"
  if [ "$RC" = 0 ]; then ok "$f: the scan's listing command runs"; else bad "$f: the listing command exited $RC"; show; fi
  sheet=$OUT
  run_in "$fx" "$m" git shortlog -sn --since=90.days "$ref"
  people=$(printf '%s\n' "$OUT" | grep -c . || true)
  slug='' facts=''
  if [ "$f" != no-remote ]; then
    run_in "$fx" "$m" git remote get-url origin
    slug=$(printf '%s' "$OUT" | sed 's|^https://github.com/||; s|\.git$||')
    run_in "$fx" "$m" gh repo view "$slug" --json viewerPermission,visibility,isPrivate,defaultBranchRef,isFork,parent
    facts=$OUT
    has "$f: default branch is $d" "$facts" "\"defaultBranchRef\":\\{\"name\":\"$d\"\\}"
  fi
  if [ "$f" = husky-hooks ]; then
    run_in "$fx" "$m" git config --get core.hooksPath
    same "$f: the repo's hooks live in .husky" "$OUT" .husky
    run_in "$fx" "$m" git rev-parse --git-path hooks
    same "$f: git rev-parse --git-path hooks names that folder" "$OUT" .husky
    same "$f: the hook names the write screen warns about" "$(ls "$m/.husky" | grep -v '\.sample$' | grep -vx _ | tr '\n' ' ')" 'pre-commit '
  else
    must_rc 1 "$fx" "$m" git config --get core.hooksPath
  fi
  if [ "$f" = existing-no-identity ]; then
    must_rc 1 "$fx" "$m" git config --get user.email
  fi
  # scan.md part B: the user's own checkout, read-only. G8's record goes through the shims too
  # (stash list and hash-object without -w are reads, so they run even before the write gate).
  must "$fx" "$m" git branch --show-current
  must "$fx" "$m" git status --porcelain
  must "$fx" "$m" git -C "$m" stash list
  must "$fx" "$m" bash -c "git -C \"$m\" diff HEAD | git hash-object --stdin"
  run_in "$fx" "$m" git show "$ref:.env.example"
  case "$f" in
    small-node-app|deploys-on-main) has "$f: .env.example names a mail service (the money signal)" "$OUT" '^MAIL_API_KEY=$' ;;
    *) lacks "$f: .env.example names no paid service" "$OUT" 'MAIL|STRIPE|TWILIO' ;;
  esac
  case "$f" in
    small-node-app)
      has "$f: 78 files (size M)" "$sheet" '^files 78$'
      has "$f: a test suite (35 test files)" "$sheet" '^test files 35$'
      has "$f: the CI workflow is listed to read" "$sheet" '^path \.github/workflows/ci\.yml$'
      has "$f: package.json is listed to read" "$sheet" '^path package\.json$'
      lacks "$f: no AI rules or notes files" "$sheet" '^path (CLAUDE|AGENTS|LOG|TODO|TASKS)'
      run_in "$fx" "$m" git show "origin/$d:.github/workflows/ci.yml"
      lacks "$f: ci.yml runs tests only (no deploy step)" "$OUT" 'deploy|pages|publish'
      has "$f: ci.yml runs npm test (read, never run)" "$OUT" 'npm test'
      same "$f: one person committed in 90 days" "$people" 1
      has "$f: private and admin" "$facts" '"viewerPermission":"ADMIN","visibility":"PRIVATE"' ;;
    dirty-feature-branch-with-claude-md)
      has "$f: 10 files (size S)" "$sheet" '^files 10$'
      has "$f: CLAUDE.md, LOG.md and docs/decisions.md are listed" "$(printf '%s\n' "$sheet" | grep '^path ' | tr '\n' ' ')" 'path CLAUDE\.md path LOG\.md path docs/decisions\.md'
      run_in "$fx" "$m" git show "origin/$d:CLAUDE.md"
      main_claude=$OUT
      has "$f: main's CLAUDE.md has the commit-to-main rule" "$main_claude" '^- Commit straight to main for small fixes'
      lacks "$f: main's CLAUDE.md doesn't have the user's uncommitted edit" "$main_claude" 'Local draft rule'
      has "$f: the user's own copy does (it must stay theirs)" "$(cat "$m/CLAUDE.md")" 'Local draft rule'
      run_in "$fx" "$m" git log --since=90.days --format=%an "origin/$d" -- LOG.md
      same "$f: only Priya edited LOG.md in 90 days (adoptable)" "$(printf '%s\n' "$OUT" | sort -u | tr '\n' ' ')" 'Priya Example '
      run_in "$fx" "$m" git branch --show-current
      same "$f: the user is on the feature branch" "$OUT" priya/menu
      run_in "$fx" "$m" gh api "repos/$slug/issues?state=all&per_page=1" --jq '.[0].number'
      same "$f: two earlier PRs, so the setup PR is predicted as #3" "$OUT" 2 ;;
    claude-md-symlink)
      has "$f: CLAUDE.md is listed as a link" "$sheet" '^path CLAUDE\.md  \(a link\)$'
      has "$f: AGENTS.md is listed" "$sheet" '^path AGENTS\.md$'
      run_in "$fx" "$m" git ls-files -s -- CLAUDE.md
      has "$f: git stores CLAUDE.md as a symlink (mode 120000)" "$OUT" '^120000 ' ;;
    deploys-on-main)
      has "$f: the deploy workflow is listed" "$sheet" '^path \.github/workflows/deploy\.yml$'
      run_in "$fx" "$m" git show "origin/$d:.github/workflows/deploy.yml"
      has "$f: deploy.yml publishes with actions/deploy-pages" "$OUT" 'actions/deploy-pages'
      has "$f: on every push to main" "$OUT" 'branches: \[main\]'
      same "$f: two people committed in 90 days" "$people" 2
      has "$f: public" "$facts" '"visibility":"PUBLIC"'
      run_in "$fx" "$m" gh pr list --repo "$slug" --state open --json number,title,author --limit 20
      has "$f: Jordan has an open PR" "$OUT" '"login":"jordan-acme"' ;;
    shared-repo)
      has "$f: owned by maple-st, Priya can write" "$facts" '"owner":\{"login":"maple-st"\}.*"viewerPermission":"WRITE"'
      # scan.md part D: shared from preflight's evidence alone (the owner isn't priya-acme and
      # the permission is below ADMIN), whatever Call 1's answer was.
      if printf '%s' "$facts" | grep -q '"owner":{"login":"priya-acme"}' || printf '%s' "$facts" | grep -q '"viewerPermission":"ADMIN"'; then
        bad "$f: the facts should make it shared"
      else
        ok "$f: shared by the evidence (not your repo, not admin), whatever the answer"
      fi
      run_in "$fx" "$m" gh api "repos/$slug/branches/$d" --jq .protected
      same "$f: master is protected" "$OUT" true
      must_rc 1 "$fx" "$m" gh api "repos/$slug/rules/branches/$d"
      has "$f: the rulesets answer 403 (can't tell)" "$OUT" 'HTTP 403'
      has "$f: its own PR template and CODEOWNERS are listed" "$(printf '%s\n' "$sheet" | grep '^path ' | tr '\n' ' ')" 'CODEOWNERS.*pull_request_template'
      same "$f: two people committed in 90 days" "$people" 2 ;;
  esac
  [ "$f" != no-remote ] || return 0
  run_in "$fx" "$m" gh api "repos/$slug/pages" --jq .source
  if [ "$RC" != 0 ] && printf '%s\n' "$OUT" | grep -q 'HTTP 404'; then ok "$f: GitHub Pages answers 404 (off)"; else bad "$f: pages should answer 404"; show; fi
  must_rc 1 "$fx" "$m" gh repo view priya-acme/acme-team --json name,defaultBranchRef
}

# ------------------------------------------------------------------------------------------------
in_repo_case() { # in_repo_case FIXTURE TREE PR_NUMBER
  f=$1 tree=$2 prn=$3
  echo
  echo "== $f (in-repo)"
  fxdir="$work/$f"
  build "$f" "$fxdir" || return 0
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  MAIN="$fxdir/acme"
  NB="$fxdir/acme-team"
  REPO=priya-acme/acme
  scan_case "$f" "$fxdir" main
  untouched "$fxdir" 0
  before=$(record "$MAIN")
  main_before=$(other_git --git-dir="$fxdir/remotes/$REPO.git" rev-parse refs/heads/main 2>/dev/null || true)

  : > "$fxdir/write-screen-approved"

  # git-model.md D1: only the lines the write screen listed.
  case "$f" in
    existing-no-identity)
      must "$fxdir" "$MAIN" git -C "$MAIN" config user.name "$NAME"
      must "$fxdir" "$MAIN" git -C "$MAIN" config user.email "$EMAIL" ;;
    no-remote)
      same "$f: no GitHub repo yet" "$(ls "$fxdir/remotes" 2>/dev/null || true)" ''
      must "$fxdir" "$MAIN" gh repo create "$REPO" --private --source "$MAIN" --remote origin
      must "$fxdir" "$MAIN" git -C "$MAIN" push -u origin main
      run_in "$fxdir" "$MAIN" git -C "$MAIN" remote get-url origin
      same "$f: origin is the new private GitHub repo" "$OUT" "https://github.com/$REPO.git"
      run_in "$fxdir" "$MAIN" git -C "$MAIN" rev-parse --abbrev-ref 'main@{upstream}'
      same "$f: main now tracks origin/main (part I lists it)" "$OUT" origin/main
      main_before=$(other_git --git-dir="$fxdir/remotes/$REPO.git" rev-parse refs/heads/main)
      same "$f: GitHub has main, and only main" "$(other_git --git-dir="$fxdir/remotes/$REPO.git" for-each-ref --format='%(refname)')" refs/heads/main ;;
  esac

  # git-model.md D2, in-repo: the notebook folder on the setup branch, from origin/main.
  must "$fxdir" "$MAIN" bash -c "git -C \"$MAIN\" fetch origin || git -C \"$MAIN\" fetch origin"
  run_in "$fxdir" "$MAIN" git -C "$MAIN" ls-remote --heads origin "assemble/setup-*"
  same "$f: no setup branch on GitHub yet" "$OUT" ''
  must "$fxdir" "$MAIN" git -C "$MAIN" worktree add --no-track -b "$BRANCH" "$NB" origin/main
  same "$f: the notebook folder holds main's files, not the user's branch" "$(other_git -C "$NB" rev-parse HEAD)" "$main_before"

  # The files (interview.md part G8), from the stand-in rendered example.
  copy_tree "$root/tests/rendered/$tree/team" "$NB/team" "$work/team-$f.txt"
  sed 's|^|team/|' "$work/team-$f.txt" > "$work/paths-$f.txt"
  mkdir -p "$NB/.github"
  cp "$root/tests/rendered/$tree/.github/pull_request_template.md" "$NB/.github/pull_request_template.md"
  echo .github/pull_request_template.md >> "$work/paths-$f.txt"
  block_of "$root/tests/rendered/$tree/CLAUDE.md" > "$work/block.txt"
  case "$f" in
    small-node-app|existing-no-identity|no-remote)
      cp "$work/block.txt" "$NB/CLAUDE.md"
      echo CLAUDE.md >> "$work/paths-$f.txt" ;;
    dirty-feature-branch-with-claude-md)
      { printf '\n'; cat "$work/block.txt"; } >> "$NB/CLAUDE.md"
      echo CLAUDE.md >> "$work/paths-$f.txt"
      # Adopt LOG.md: no team/LOG.md; the setup entry goes at the top of LOG.md (newest first);
      # the manifest, the owner row, ROSTER "Where things are" and the IF_ADOPTED line say so.
      rm "$NB/team/LOG.md"
      grep -v -x 'team/LOG.md' "$work/paths-$f.txt" > "$work/p" && mv "$work/p" "$work/paths-$f.txt"
      awk 'BEGIN { done = 0 } { print } !done && $0 == "Newest first." { getline; print; print "## 2026-10-13 · Cyrus (Chief) · Team set up with /assemble"; print "Done: team/ and the CLAUDE.md block on '"$BRANCH"' (PR #3). Ruled (Priya): D1 the team, D2 the names, D3 a new team/DECISIONS.md, D4 and D5 two rule clashes."; print ""; done = 1 }' \
        "$NB/LOG.md" > "$work/l" && mv "$work/l" "$NB/LOG.md"
      echo LOG.md >> "$work/paths-$f.txt"
      sed 's|"adopted": {}|"adopted": { "log": "LOG.md" }|' "$NB/team/assemble.json" > "$work/a" && mv "$work/a" "$NB/team/assemble.json"
      # CHATS.md as the template gives it with IF_ADOPTED on (WRITER = Cyrus).
      awk -v line="$(sed -n 's/^{{IF_ADOPTED}}//p' "$root/skills/assemble/templates/CHATS.md" | sed 's/{{WRITER}}/Cyrus/g')" \
        '{ print } index($0, "- The notebook folder is ") == 1 { print line }' "$NB/team/CHATS.md" > "$work/c" && mv "$work/c" "$NB/team/CHATS.md"
      has "$f: CHATS.md has the adopted-files line" "$(cat "$NB/team/CHATS.md")" '^- Some notes stay in files the project already had'
      # The adopted log's owner row replaces the team/LOG.md row (one row per notes file).
      awk 'index($0, "| `team/LOG.md` |") == 1 { next } index($0, "| `team/handovers/` |") { print; print "| `LOG.md` | Cyrus | After every event (adopted: the log) |"; next } { print }' "$NB/team/CHATS.md" > "$work/c" && mv "$work/c" "$NB/team/CHATS.md"
      lacks "$f: CHATS.md has no team/LOG.md row once LOG.md is adopted" "$(cat "$NB/team/CHATS.md")" '^\| `team/LOG\.md` \|'
      has "$f: CHATS.md has the adopted log's owner row" "$(cat "$NB/team/CHATS.md")" '^\| `LOG\.md` \| Cyrus \|'
      awk 'index($0, "| Precious list (full-tier paths) |") { print; print "| Log (adopted) | `LOG.md` |"; print "| Decisions (yours, not adopted; read-only) | `docs/decisions.md` |"; next } { print }' "$NB/team/ROSTER.md" > "$work/r" && mv "$work/r" "$NB/team/ROSTER.md" ;;
    claude-md-symlink)
      mkdir -p "$NB/.claude"
      sed 's|^@team/CHATS.md$|@../team/CHATS.md|' "$work/block.txt" > "$NB/.claude/CLAUDE.md"
      echo .claude/CLAUDE.md >> "$work/paths-$f.txt" ;;
  esac
  # .gitignore: main's file ignores node_modules/ and .env, so only the missing lines are added.
  printf '%s\n' '' '# assemble:begin · managed by /assemble' '.claude/worktrees/' '.env.*' '!.env.example' '# assemble:end' >> "$NB/.gitignore"
  echo .gitignore >> "$work/paths-$f.txt"
  sort "$work/paths-$f.txt" > "$work/p" && mv "$work/p" "$work/paths-$f.txt"

  # shellcheck disable=SC2046
  must "$fxdir" "$NB" git -C "$NB" add -- $(cat "$work/paths-$f.txt")
  check_output "$NB" "$f's staged notebook folder"
  # Self-check 11: the staged change is exactly the listed paths, and the user's files only grow.
  run_in "$fxdir" "$NB" git -C "$NB" diff --cached --name-only
  same "$f: the staged files are exactly the write screen's" "$(printf '%s\n' "$OUT" | sort | tr '\n' ' ')" "$(tr '\n' ' ' < "$work/paths-$f.txt")"
  only_adds "$f" .gitignore
  case "$f" in
    dirty-feature-branch-with-claude-md)
      only_adds "$f" CLAUDE.md
      only_adds "$f" LOG.md
      run_in "$fxdir" "$NB" git -C "$NB" diff --cached -- docs/decisions.md
      same "$f: docs/decisions.md is untouched (settled by default: a new team/DECISIONS.md)" "$OUT" ''
      if [ -f "$NB/team/DECISIONS.md" ] && [ ! -f "$NB/team/LOG.md" ]; then ok "$f: team/DECISIONS.md is new; team/LOG.md isn't made (LOG.md adopted)"; else bad "$f: wrong team files for the adoption"; fi ;;
    claude-md-symlink)
      run_in "$fxdir" "$NB" git -C "$NB" diff --cached -- CLAUDE.md AGENTS.md
      same "$f: CLAUDE.md (the link) and AGENTS.md are untouched" "$OUT" ''
      same "$f: CLAUDE.md is still a link to AGENTS.md" "$(readlink "$NB/CLAUDE.md")" AGENTS.md ;;
  esac
  must "$fxdir" "$NB" git -C "$NB" commit -m "Set up the team with /assemble" -- $(cat "$work/paths-$f.txt")
  if [ "$f" = existing-no-identity ]; then
    same "$f: the setup commit carries the noreply address (D1's identity lines)" "$(other_git -C "$NB" log -1 --format='%an <%ae>')" "$NAME <$EMAIL>"
    run_in "$fxdir" "$NB" git -C "$NB" config --get user.email
    same "$f: self-check 13: the notebook folder has the noreply email" "$OUT" "$EMAIL"
  fi
  must "$fxdir" "$NB" git -C "$NB" push -u origin HEAD
  same "$f: GitHub's main didn't move (no PR-less setup)" "$(other_git --git-dir="$fxdir/remotes/$REPO.git" rev-parse refs/heads/main)" "$main_before"

  # D4 and D5.
  must "$fxdir" "$fxdir" bash -c "$(exclude_cmd "$MAIN")"
  same "$f: info/exclude has the worktrees line once" "$(grep -cx '\.claude/worktrees/' "$MAIN/.git/info/exclude")" 1
  printf '## What this PR does\nSets up the team.\n\n## Reviewer handoff\n- **Tier:** full\n' > "$work/body-$f.md"
  must "$fxdir" "$NB" gh pr create --repo "$REPO" --base main --head "$BRANCH" --title "Set up the team with /assemble" --body-file "$work/body-$f.md"
  same "$f: the setup PR is #$prn, as predicted" "$(printf '%s\n' "$OUT" | tail -n 1)" "https://github.com/$REPO/pull/$prn"
  run_in "$fxdir" "$NB" gh pr diff "$prn" --repo "$REPO" --name-only
  same "$f: the PR holds only our files" "$(printf '%s\n' "$OUT" | sort | tr '\n' ' ')" "$(tr '\n' ' ' < "$work/paths-$f.txt")"
  same "$f: the user's checkout is exactly as recorded (branch, HEAD, uncommitted changes)" "$(record "$MAIN")" "$before"

  # The merge gate: a verdict at the head, the head check, the human's merge, the merged-sha check.
  run_in "$fxdir" "$NB" gh pr view "$prn" --json headRefOid --jq .headRefOid
  reviewed=$OUT
  printf '## Review of PR #%s: round 1 (Vito)\n**Reviewed commit:** %s   **Tier:** full\n**Verdict:** READY TO MERGE\n' "$prn" "$reviewed" > "$work/verdict.md"
  must "$fxdir" "$NB" gh pr comment "$prn" --body-file "$work/verdict.md"
  run_in "$fxdir" "$NB" gh pr view "$prn" --json headRefOid,mergeable,state
  has "$f: merge gate: the head is still the reviewed commit" "$OUT" "\"headRefOid\":\"$reviewed\""
  if bash "$root/tests/lib/fake-gh-merge" "$fxdir" "$prn" --repo "$REPO" > "$work/merge.log" 2>&1; then ok "$f: Priya merges PR #$prn"; else bad "$f: the merge failed:"; sed 's/^/      /' "$work/merge.log"; fi
  run_in "$fxdir" "$NB" gh pr view "$prn" --json headRefOid --jq .headRefOid
  same "$f: the merged head is the reviewed commit" "$OUT" "$reviewed"
  must "$fxdir" "$NB" git fetch --prune origin
  must "$fxdir" "$NB" git switch --detach origin/main
  must "$fxdir" "$NB" git branch -D "$BRANCH"
  must "$fxdir" "$MAIN" git show origin/main:team/assemble.json
  check_output "$NB" "$f's merged notebook folder"
  if [ "$f" = dirty-feature-branch-with-claude-md ]; then
    run_in "$fxdir" "$MAIN" git show origin/main:CLAUDE.md
    lacks "$f: merged CLAUDE.md doesn't carry the user's uncommitted edit" "$OUT" 'Local draft rule'
    has "$f: merged CLAUDE.md keeps the user's rules above the block" "$OUT" '^- Commit straight to main for small fixes'
    has "$f: merged CLAUDE.md ends with the block" "$(printf '%s\n' "$OUT" | tail -n 1)" '^<!-- assemble:end -->$'
    # A notebook write to the adopted log: sync, edit at its own path, push to main.
    must "$fxdir" "$NB" git rebase --autostash origin/main
    awk 'BEGIN { done = 0 } { print } !done && $0 == "Newest first." { getline; print; print "## 2026-10-13 · Cyrus (Chief) · Merged PR #3"; print "Merged the setup."; print ""; done = 1 }' "$NB/LOG.md" > "$work/l" && mv "$work/l" "$NB/LOG.md"
    must "$fxdir" "$NB" git add -- LOG.md
    must "$fxdir" "$NB" git commit -m "notes: merged setup PR #3 [skip ci]" -- LOG.md
    must "$fxdir" "$NB" git push origin HEAD:main
  fi
  same "$f: after the merge the user's checkout is still as recorded (no chat pulls for them)" "$(record "$MAIN")" "$before"
  if [ -e "$MAIN/REPO-SCRIPT-RAN" ] || [ -e "$NB/REPO-SCRIPT-RAN" ]; then bad "$f: a project script ran"; else ok "$f: no project script ran"; fi
  calls_clean "$fxdir"
}

# ------------------------------------------------------------------------------------------------
beside_case() { # beside_case FIXTURE OWNER DEFAULT
  f=$1 owner=$2 d=$3
  echo
  echo "== $f (beside-repo)"
  fxdir="$work/$f"
  build "$f" "$fxdir" || return 0
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  MAIN="$fxdir/acme"
  NB="$fxdir/acme-team"
  REPO="$owner/acme"
  NOTES=priya-acme/acme-team
  scan_case "$f" "$fxdir" "$d"
  untouched "$fxdir" 0
  before=$(record "$MAIN")
  refs_before=$(other_git --git-dir="$fxdir/remotes/$REPO.git" for-each-ref --format='%(refname) %(objectname)')
  prs_before=$(ls "$fxdir/gh-state/$REPO" | grep -c '^pr-' || true)

  : > "$fxdir/write-screen-approved"

  # git-model.md D2, beside-repo.
  must "$fxdir" "$MAIN" git init -b main "$NB"
  run_in "$fxdir" "$MAIN" git -C "$MAIN" config --get user.name
  pname=$OUT
  run_in "$fxdir" "$MAIN" git -C "$MAIN" config --get user.email
  pemail=$OUT
  run_in "$fxdir" "$MAIN" git -C "$NB" config --get user.email
  same "$f: without step 2 the notes repo would have no git email of its own" "$RC" 1
  must "$fxdir" "$MAIN" git -C "$NB" config user.name "$pname"
  must "$fxdir" "$MAIN" git -C "$NB" config user.email "$pemail"
  must "$fxdir" "$MAIN" git -C "$NB" commit --allow-empty -m "Start"
  must "$fxdir" "$MAIN" gh repo create "$NOTES" --private --source "$NB" --remote origin --push
  must "$fxdir" "$MAIN" git -C "$NB" switch --no-track -c "$BRANCH"

  copy_tree "$root/tests/rendered/lemonade" "$NB" "$work/paths-$f.txt"
  if [ "$f" = deploys-on-main ]; then
    # Not someone else's repo: no PROPOSALS.md.
    rm "$NB/team/PROPOSALS.md"
    grep -v -x 'team/PROPOSALS.md' "$work/paths-$f.txt" > "$work/p" && mv "$work/p" "$work/paths-$f.txt"
  fi
  printf '%s\n' '# assemble:begin · managed by /assemble' '.claude/worktrees/' '# assemble:end' > "$NB/.gitignore"
  echo .gitignore >> "$work/paths-$f.txt"
  sort "$work/paths-$f.txt" > "$work/p" && mv "$work/p" "$work/paths-$f.txt"
  if grep -qx '\.github/.*' "$work/paths-$f.txt"; then bad "$f: beside-repo writes no .github/ file"; else ok "$f: no .github/ file in the notes repo (team/pr-template.md instead)"; fi
  # shellcheck disable=SC2046
  must "$fxdir" "$NB" git -C "$NB" add -- $(cat "$work/paths-$f.txt")
  check_output "$NB" "$f's staged notes repo"
  must "$fxdir" "$NB" git -C "$NB" commit -m "Set up the team with /assemble" -- $(cat "$work/paths-$f.txt")
  same "$f: the notes repo's commit carries the project's git email" "$(other_git -C "$NB" log -1 --format=%ae)" "$pemail"
  must "$fxdir" "$NB" git -C "$NB" push -u origin HEAD
  must "$fxdir" "$fxdir" bash -c "$(exclude_cmd "$MAIN")"
  printf '## What this PR does\nSets up the team.\n' > "$work/body-$f.md"
  must "$fxdir" "$NB" gh pr create --repo "$NOTES" --base main --head "$BRANCH" --title "Set up the team with /assemble" --body-file "$work/body-$f.md"
  same "$f: the setup PR is #1 in the notes repo" "$(printf '%s\n' "$OUT" | tail -n 1)" "https://github.com/$NOTES/pull/1"

  # Zero committed footprint in the project repo.
  same "$f: the project repo's branches on GitHub are unchanged" "$(other_git --git-dir="$fxdir/remotes/$REPO.git" for-each-ref --format='%(refname) %(objectname)')" "$refs_before"
  same "$f: no PR was opened on $REPO" "$(ls "$fxdir/gh-state/$REPO" | grep -c '^pr-' || true)" "$prs_before"
  same "$f: the user's checkout is exactly as recorded" "$(record "$MAIN")" "$before"
  if [ -e "$MAIN/team" ] || other_git -C "$MAIN" status --porcelain | grep -q 'CLAUDE'; then bad "$f: something was written in the project folder"; else ok "$f: nothing written in the project folder (no team/, CLAUDE.md as it was)"; fi

  # The notes repo's setup PR: verdict, merge, after-merge steps (beside-repo form).
  run_in "$fxdir" "$NB" gh pr view 1 --json headRefOid --jq .headRefOid
  reviewed=$OUT
  printf '## Review of PR #1: round 1 (Vito)\n**Reviewed commit:** %s   **Tier:** full\n**Verdict:** READY TO MERGE\n' "$reviewed" > "$work/verdict.md"
  must "$fxdir" "$NB" gh pr comment 1 --body-file "$work/verdict.md"
  if bash "$root/tests/lib/fake-gh-merge" "$fxdir" 1 --repo "$NOTES" > "$work/merge.log" 2>&1; then ok "$f: Priya merges notes PR #1"; else bad "$f: the merge failed:"; sed 's/^/      /' "$work/merge.log"; fi
  must "$fxdir" "$NB" git switch main
  must "$fxdir" "$NB" git pull --ff-only
  must "$fxdir" "$NB" git branch -D "$BRANCH"
  check_output "$NB" "$f's merged notes repo"
  run_in "$fxdir" "$NB" gh api "repos/$NOTES/contents/team/assemble.json?ref=main" --jq .path
  same "$f: re-run detection finds the manifest in the notes repo" "$OUT" team/assemble.json

  if [ "$f" = shared-repo ]; then
    # A doer's work PR goes on the real repo, from its own worktree and branch.
    wt="$MAIN/.claude/worktrees/bram-T1"
    must "$fxdir" "$MAIN" bash -c "git -C \"$MAIN\" fetch origin || git -C \"$MAIN\" fetch origin"
    must "$fxdir" "$MAIN" git -C "$MAIN" worktree add --no-track -b bram/T1-hours "$wt" "origin/$d"
    printf '<p>Hours: Tuesday to Saturday</p>\n' > "$wt/hours.html"
    must "$fxdir" "$wt" git add -- hours.html
    must "$fxdir" "$wt" git commit -m "T1: opening hours" -- hours.html
    must "$fxdir" "$wt" git push -u origin HEAD
    lacks "$f: the user's checkout doesn't show the doer worktree (exclude line)" "$(other_git -C "$MAIN" status --porcelain --untracked-files=all)" '\.claude'
    { cat "$MAIN/.github/pull_request_template.md"; sed -n '/^## Reviewer handoff/,$p' "$NB/team/pr-template.md"; } > "$work/body-doer.md"
    has "$f: the doer's PR body is the owners' template plus our Reviewer handoff" "$(cat "$work/body-doer.md")" '^## Summary$'
    must "$fxdir" "$wt" gh pr create --repo "$REPO" --base "$d" --head bram/T1-hours --title "T1: opening hours" --body-file "$work/body-doer.md"
    same "$f: the work PR is #2 on $REPO (Jordan's is #1)" "$(printf '%s\n' "$OUT" | tail -n 1)" "https://github.com/$REPO/pull/2"
    run_in "$fxdir" "$wt" gh pr view 2 --repo "$REPO" --json headRefOid --jq .headRefOid
    same "$f: merge gate: the head is the doer's pushed commit" "$OUT" "$(other_git -C "$wt" rev-parse HEAD)"
    # The rendered rules say what may be posted there: findings only.
    has "$f: CHATS.md says PR comments on the project repo carry technical findings only" "$(cat "$NB/team/CHATS.md")" "PR comments on the project repo, [^ ]+ \(public or someone else's\), carry technical findings only"
    has "$f: CHATS.md says PRs in the notes repo may carry rulings" "$(cat "$NB/team/CHATS.md")" "When the notes have their own private repo, its PRs"
    has "$f: the Reviewer leaves Needs and decision text off the PR" "$(cat "$NB/team/roles/reviewer.md")" 'leaves out the "Needs Priya" section'
    has "$f: CHATS.md says the owners merge" "$(cat "$NB/team/CHATS.md")" 'the owners merge, by their own process'
    has "$f: a doer's role file says to fill the owners' PR template first" "$(cat "$NB/team/roles/designer.md")" 'if it has its own PR template, fill that, then add the "Reviewer handoff" and "Checklist" sections'
    must "$fxdir" "$MAIN" git -C "$MAIN" worktree remove "$wt"
    must "$fxdir" "$MAIN" git -C "$MAIN" branch -D bram/T1-hours
  fi
  same "$f: at the end the user's checkout is still as recorded" "$(record "$MAIN")" "$before"
  if [ -e "$MAIN/REPO-SCRIPT-RAN" ]; then bad "$f: a project script ran"; else ok "$f: no project script ran"; fi
  calls_clean "$fxdir"
}

# ------------------------------------------------------------------------------------------------
# The scan's listing on a repo with more tool files than the listing's cap (scan.md part B).
busy_config_case() {
  f=busy-config
  echo
  echo "== $f (the scan's listing only)"
  fxdir="$work/$f"
  build "$f" "$fxdir" || return 0
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  listing "$fxdir" origin/main
  if [ "$RC" = 0 ]; then ok "$f: the listing runs"; else bad "$f: the listing exited $RC"; show; fi
  sheet=$OUT
  paths=$(printf '%s\n' "$sheet" | grep '^path ' | tr '\n' ' ')
  has "$f: 41 files under .claude/" "$sheet" '^folder \.claude/ \(41 files\)$'
  has "$f: CLAUDE.md is listed despite the cap" "$paths" 'path CLAUDE\.md '
  has "$f: LOG.md is listed despite the cap" "$paths" 'path LOG\.md '
  has "$f: package.json is listed despite the cap (kind: software)" "$paths" 'path package\.json '
  has "$f: .claude/settings.json is listed" "$paths" 'path \.claude/settings\.json '
  lacks "$f: the editor commands under .claude/ are only counted" "$paths" 'path \.claude/commands/'
  same "$f: 40 workflow lines, the cap" "$(printf '%s\n' "$sheet" | grep -c '^path \.github/workflows/')" 40
  has "$f: the left-out workflows are counted" "$sheet" '^more paths not listed: 5$'
  has "$f: type counts leave out .claude/ and .github/" "$sheet" '^type \.md 3$'
  lacks "$f: no .yml in the type counts" "$sheet" '^type \.yml'
  run_in "$fxdir" "$fxdir/acme" git ls-tree -r --name-only origin/main -- .github/
  same "$f: the command scan.md gives for the rest lists all 45 workflows" "$(printf '%s\n' "$OUT" | grep -c '^\.github/workflows/')" 45
  untouched "$fxdir" 0
  calls_clean "$fxdir"
}

# ------------------------------------------------------------------------------------------------
# In-repo, the project's own pre-commit hook fails in the fresh notebook folder (git-model.md D6):
# the cleanup after the user's yes, then the notes beside the repo, where the hooks don't run.
hook_case() {
  f=husky-hooks
  echo
  echo "== $f (in-repo, a hook fails, then beside-repo)"
  fxdir="$work/$f"
  build "$f" "$fxdir" || return 0
  fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
  MAIN="$fxdir/acme"
  NB="$fxdir/acme-team"
  REPO=priya-acme/acme
  NOTES=priya-acme/acme-team
  scan_case "$f" "$fxdir" main
  untouched "$fxdir" 0
  before=$(record "$MAIN")
  refs_before=$(other_git --git-dir="$fxdir/remotes/$REPO.git" for-each-ref --format='%(refname) %(objectname)')

  : > "$fxdir/write-screen-approved"
  must "$fxdir" "$MAIN" bash -c "git -C \"$MAIN\" fetch origin || git -C \"$MAIN\" fetch origin"
  must "$fxdir" "$MAIN" git -C "$MAIN" worktree add --no-track -b "$BRANCH" "$NB" origin/main
  copy_tree "$root/tests/rendered/acme-small/team" "$NB/team" "$work/team-$f.txt"
  sed 's|^|team/|' "$work/team-$f.txt" > "$work/paths-$f.txt"
  block_of "$root/tests/rendered/acme-small/CLAUDE.md" > "$NB/CLAUDE.md"
  printf '%s\n' '' '# assemble:begin · managed by /assemble' '.claude/worktrees/' '.env.*' '!.env.example' '# assemble:end' >> "$NB/.gitignore"
  printf '%s\n' CLAUDE.md .gitignore >> "$work/paths-$f.txt"
  # shellcheck disable=SC2046
  must "$fxdir" "$NB" git -C "$NB" add -- $(cat "$work/paths-$f.txt")
  # shellcheck disable=SC2046
  run_in "$fxdir" "$NB" git -C "$NB" commit -m "Set up the team with /assemble" -- $(cat "$work/paths-$f.txt")
  if [ "$RC" != 0 ] && printf '%s\n' "$OUT" | grep -q 'husky\.sh'; then
    ok "$f: the project's pre-commit hook runs in the notebook folder and fails there (no .husky/_ in a fresh checkout)"
  else
    bad "$f: the commit should fail in the project's hook (exit $RC)"; show
  fi
  same "$f: nothing reached GitHub" "$(other_git --git-dir="$fxdir/remotes/$REPO.git" for-each-ref --format='%(refname) %(objectname)')" "$refs_before"

  # D6, after the user's yes to the exact commands: the folder holds only setup's files.
  must "$fxdir" "$MAIN" git -C "$MAIN" worktree remove --force "$NB"
  must "$fxdir" "$MAIN" git -C "$MAIN" branch -D "$BRANCH"
  if [ -e "$NB" ]; then bad "$f: the notebook folder is still there"; else ok "$f: the notebook folder is gone"; fi
  run_in "$fxdir" "$MAIN" git -C "$MAIN" branch --list 'assemble/*'
  same "$f: no setup branch is left" "$OUT" ''
  same "$f: the user's checkout is exactly as recorded after the cleanup" "$(record "$MAIN")" "$before"

  # The new write screen (beside-repo, "your repo's git hook pre-commit failed") is approved.
  must "$fxdir" "$MAIN" git init -b main "$NB"
  must "$fxdir" "$MAIN" git -C "$NB" config user.name "$NAME"
  must "$fxdir" "$MAIN" git -C "$NB" config user.email "$EMAIL"
  must_rc 1 "$fxdir" "$MAIN" git -C "$NB" config --get core.hooksPath
  must "$fxdir" "$MAIN" git -C "$NB" commit --allow-empty -m "Start"
  must "$fxdir" "$MAIN" gh repo create "$NOTES" --private --source "$NB" --remote origin --push
  must "$fxdir" "$MAIN" git -C "$NB" switch --no-track -c "$BRANCH"
  copy_tree "$root/tests/rendered/lemonade" "$NB" "$work/paths-$f.txt"
  rm "$NB/team/PROPOSALS.md"
  grep -v -x 'team/PROPOSALS.md' "$work/paths-$f.txt" > "$work/p" && mv "$work/p" "$work/paths-$f.txt"
  printf '%s\n' '# assemble:begin · managed by /assemble' '.claude/worktrees/' '# assemble:end' > "$NB/.gitignore"
  echo .gitignore >> "$work/paths-$f.txt"
  # shellcheck disable=SC2046
  must "$fxdir" "$NB" git -C "$NB" add -- $(cat "$work/paths-$f.txt")
  # shellcheck disable=SC2046
  must "$fxdir" "$NB" git -C "$NB" commit -m "Set up the team with /assemble" -- $(cat "$work/paths-$f.txt")
  must "$fxdir" "$NB" git -C "$NB" push -u origin HEAD
  must "$fxdir" "$fxdir" bash -c "$(exclude_cmd "$MAIN")"
  printf '## What this PR does\nSets up the team.\n' > "$work/body-$f.md"
  must "$fxdir" "$NB" gh pr create --repo "$NOTES" --base main --head "$BRANCH" --title "Set up the team with /assemble" --body-file "$work/body-$f.md"
  same "$f: the setup PR is #1 in the notes repo" "$(printf '%s\n' "$OUT" | tail -n 1)" "https://github.com/$NOTES/pull/1"
  same "$f: the project repo on GitHub is unchanged" "$(other_git --git-dir="$fxdir/remotes/$REPO.git" for-each-ref --format='%(refname) %(objectname)')" "$refs_before"
  same "$f: at the end the user's checkout is still as recorded" "$(record "$MAIN")" "$before"
  if [ -e "$MAIN/REPO-SCRIPT-RAN" ]; then bad "$f: a project script ran"; else ok "$f: no project script ran"; fi
  calls_clean "$fxdir"
}

busy_config_case
in_repo_case small-node-app acme 1
in_repo_case dirty-feature-branch-with-claude-md acme-small 3
in_repo_case claude-md-symlink acme-small 1
in_repo_case existing-no-identity acme-small 1
in_repo_case no-remote acme-small 1
hook_case
beside_case deploys-on-main priya-acme main
beside_case shared-repo maple-st master

echo
echo "== Cancel at the write screen: reads only, nothing written"
for f in small-node-app dirty-feature-branch-with-claude-md claude-md-symlink deploys-on-main shared-repo; do
  fxdir="$work/cancel-$f"
  if build "$f" "$fxdir"; then
    fxdir=$(CDPATH= cd -- "$fxdir" && pwd -P)
    d=main
    [ "$f" != shared-repo ] || d=master
    must "$fxdir" "$fxdir/acme" bash -c 'git fetch origin || git fetch origin'
    listing "$fxdir" "origin/$d"
    if [ "$RC" = 0 ]; then ok "$f: the listing runs"; else bad "$f: the listing failed"; show; fi
    untouched "$fxdir" 0
  fi
done

echo
if [ "$fails" -eq 0 ]; then
  echo "existing-path-test: all $checks checks passed"
else
  echo "existing-path-test: $fails of $checks checks failed"
  exit 1
fi
