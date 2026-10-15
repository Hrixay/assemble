# tests/lib/fixture.sh: shared helpers for tests/fixtures/<name>/setup.sh. Source it; don't run it.
#
# A fixture folder (the one folder a setup.sh is given) ends up holding:
#   acme/         the scratch project repo; the tester runs claude here
#   bin/          the PATH shims: a fake gh (fake-gh), a git wrapper (fake-git) and a fake ssh (fake-ssh)
#   git-home/     an empty home for git only, so the tester's own git settings never leak in
#   gh-config/    an empty gh config folder, so a real gh (if it ever runs) is logged out
#   fixture.conf  the settings the shims read (mode, fake account, real git path)
#   env.sh        sourced in a new terminal before launching claude
#   calls.log     every call the shims saw; refused writes are marked REFUSED
#   before.txt    a snapshot of everything a run must leave unchanged (tests/check-untouched.sh)
# A fixture built with writes (fixture_shims --writes) can also end up holding, after the write
# screen was approved:
#   write-screen-approved  the write gate: the tester creates it while the write screen is on
#                 screen; until it exists the shims refuse every write
#   remotes/      the fake GitHub: one bare repo per GitHub repo, remotes/<owner>/<name>.git
#   gh-state/     the fake GitHub's pull requests and their comments
#
# Every name, account and address here is fictional (Acme, Priya, priya-acme, Jordan, jordan-acme,
# maple-st). Nothing in a fixture touches the network or the tester's real GitHub account.
# Portable bash: macOS bash 3.2 and Linux, used under set -eu. No GNU-only flags.

LC_ALL=C
export LC_ALL
FIXTURE_LIB_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

FX_LOGIN=priya-acme
FX_ID=12345678
FX_NAME='Priya Example'
FX_EMAIL="$FX_ID+$FX_LOGIN@users.noreply.github.com"

fx_die() { printf 'fixture: %s\n' "$*" >&2; exit 1; }

# fixture_begin NAME TARGET: check the target folder, find the real git, make the layout.
fixture_begin() {
  [ "$#" -eq 2 ] || { printf 'usage: tests/fixtures/%s/setup.sh <empty or new folder>\n' "${1:-<name>}" >&2; exit 2; }
  FX_FIXTURE=$1
  case "$2" in
    *"'"*|*'
'*) fx_die "the folder path must not contain a single quote or a newline" ;;
  esac
  if [ -e "$2" ]; then
    [ -d "$2" ] || fx_die "$2 exists and is not a folder"
    [ -z "$(ls -A "$2")" ] || fx_die "$2 is not empty; give a new or empty folder (for example under \$TMPDIR)"
  fi
  mkdir -p "$2"
  FX_ROOT=$(CDPATH= cd -- "$2" && pwd -P)

  FX_REAL_GIT=$(command -v git) || fx_die "git is not installed"
  if grep -q 'assemble-fixture-shim' "$FX_REAL_GIT" 2>/dev/null; then
    fx_die "this shell has a fixture's env.sh loaded (git is a shim); open a new terminal"
  fi

  mkdir "$FX_ROOT/bin" "$FX_ROOT/git-home" "$FX_ROOT/gh-config"
  : > "$FX_ROOT/git-home/.gitconfig"
  : > "$FX_ROOT/calls.log"
  printf '%s\n' "$FX_FIXTURE" > "$FX_ROOT/FIXTURE"
}

# fx_git ARGS...: the real git, with the tester's global and system settings shut out.
fx_git() {
  env HOME="$FX_ROOT/git-home" XDG_CONFIG_HOME="$FX_ROOT/git-home/.config" \
    GIT_CONFIG_GLOBAL="$FX_ROOT/git-home/.gitconfig" GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 \
    GIT_CEILING_DIRECTORIES="$FX_ROOT" "$FX_REAL_GIT" "$@"
}

# fixture_repo [--origin URL] [--identity] [--helper]: build the scratch repo acme/ on main.
#   --origin URL  set origin to URL and give it a local origin/main ref (nothing is fetched)
#   --identity    store user.name and user.email in the repo's own config
#   --helper      store the gh credential helper for https://github.com in the repo's config
fixture_repo() {
  local origin='' identity=no helper=no repo
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --origin) origin=$2; shift 2 ;;
      --identity) identity=yes; shift ;;
      --helper) helper=yes; shift ;;
      *) fx_die "fixture_repo: unknown option $1" ;;
    esac
  done
  repo="$FX_ROOT/acme"
  mkdir "$repo"
  fx_git -c init.defaultBranch=main init -q "$repo"
  fx_git -C "$repo" symbolic-ref HEAD refs/heads/main

  printf '# Acme\n\nA tiny fictional web app. It exists only to test /assemble.\n' > "$repo/README.md"
  printf 'node_modules/\n.env\n' > "$repo/.gitignore"
  fx_git -C "$repo" add -- README.md .gitignore
  fx_git -C "$repo" -c user.name="$FX_NAME" -c user.email="$FX_EMAIL" commit -q -m "Start"

  printf '<!doctype html>\n<title>Acme</title>\n<h1>Acme</h1>\n<script src="app.js"></script>\n' > "$repo/index.html"
  printf 'document.querySelector("h1").textContent = "Hello from Acme";\n' > "$repo/app.js"
  # A canary: /assemble must never run a repo's scripts. If anything runs these, the file
  # REPO-SCRIPT-RAN appears and tests/check-untouched.sh reports it.
  printf '{\n  "name": "acme",\n  "private": true,\n  "scripts": {\n    "start": "touch REPO-SCRIPT-RAN",\n    "test": "touch REPO-SCRIPT-RAN",\n    "postinstall": "touch REPO-SCRIPT-RAN"\n  }\n}\n' > "$repo/package.json"
  fx_git -C "$repo" add -- index.html app.js package.json
  fx_git -C "$repo" -c user.name="$FX_NAME" -c user.email="$FX_EMAIL" commit -q -m "Add the first page"

  if [ -n "$origin" ]; then
    fx_git -C "$repo" remote add origin "$origin"
    fx_git -C "$repo" update-ref refs/remotes/origin/main refs/heads/main
    fx_git -C "$repo" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
  fi
  if [ "$identity" = yes ]; then
    fx_git -C "$repo" config user.name "$FX_NAME"
    fx_git -C "$repo" config user.email "$FX_EMAIL"
  fi
  if [ "$helper" = yes ]; then
    fx_git -C "$repo" config credential.https://github.com.helper '!gh auth git-credential'
  fi
}

# fixture_shims --gh MODE --git MODE [--gh-repo OWNER/NAME] [--writes]: install the PATH shims (gh, git, ssh).
#   The fake ssh never connects: it logs the call and answers "Permission denied (publickey)."
#   gh modes:  missing (command not found) · logged-out · offline · ok (logged in as priya-acme)
#   git modes: fake-remote (fetch and ls-remote answer from the local origin refs, no network)
#              offline (fetch and ls-remote fail with "Could not resolve host")
#              local-remote (GitHub repos are bare repos under remotes/, made by the fake
#              `gh repo create`; fetch, push and ls-remote reach them instead of the network)
#   --gh-repo  the one GitHub repo the fake gh knows from the start; empty for none. Default
#              priya-acme/acme. Repos made by the fake `gh repo create` are known as well.
#   --writes   writes are allowed once the write gate (write-screen-approved) exists. Without
#              it every write is refused, as in a read-only fixture.
fixture_shims() {
  local ghmode='' gitmode='' ghrepo="$FX_LOGIN/acme" writes=no
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --gh) ghmode=$2; shift 2 ;;
      --git) gitmode=$2; shift 2 ;;
      --gh-repo) ghrepo=$2; shift 2 ;;
      --writes) writes=yes; shift ;;
      *) fx_die "fixture_shims: unknown option $1" ;;
    esac
  done
  case "$ghmode" in missing|logged-out|offline|ok) ;; *) fx_die "fixture_shims: bad --gh mode '$ghmode'" ;; esac
  case "$gitmode" in fake-remote|offline|local-remote) ;; *) fx_die "fixture_shims: bad --git mode '$gitmode'" ;; esac
  FX_WRITES=$writes
  cp "$FIXTURE_LIB_DIR/fake-gh" "$FX_ROOT/bin/gh"
  cp "$FIXTURE_LIB_DIR/fake-git" "$FX_ROOT/bin/git"
  cp "$FIXTURE_LIB_DIR/fake-ssh" "$FX_ROOT/bin/ssh"
  chmod 755 "$FX_ROOT/bin/gh" "$FX_ROOT/bin/git" "$FX_ROOT/bin/ssh"
  {
    printf "FIXTURE_NAME='%s'\n" "$FX_FIXTURE"
    printf "FIXTURE_ROOT='%s'\n" "$FX_ROOT"
    printf "FIXTURE_REAL_GIT='%s'\n" "$FX_REAL_GIT"
    printf "FIXTURE_GH_MODE='%s'\n" "$ghmode"
    printf "FIXTURE_GIT_MODE='%s'\n" "$gitmode"
    printf "FIXTURE_GH_REPO='%s'\n" "$ghrepo"
    printf "FIXTURE_GH_LOGIN='%s'\n" "$FX_LOGIN"
    printf "FIXTURE_GH_ID='%s'\n" "$FX_ID"
    printf "FIXTURE_GH_NAME='%s'\n" "$FX_NAME"
    printf "FIXTURE_WRITES='%s'\n" "$writes"
  } > "$FX_ROOT/fixture.conf"
}

# fixture_empty: the project folder acme/ exists and is empty (a new project).
fixture_empty() {
  mkdir "$FX_ROOT/acme"
}

# fixture_files: the project folder acme/ holds a few starter files and no git: a page, a script,
# a note, a package.json canary, a .env with a made-up value, a key-looking file, a sparse file
# just over 50 MB (it takes almost no disk) and two .DS_Store files (the top and notes/). The
# last four kinds must never be committed.
fixture_files() {
  local d="$FX_ROOT/acme"
  mkdir "$d" "$d/notes"
  printf '<!doctype html>\n<title>Acme</title>\n<h1>Acme</h1>\n<p>Opening hours: soon.</p>\n' > "$d/index.html"
  printf 'document.querySelector("h1").textContent = "Acme";\n' > "$d/app.js"
  printf '# Ideas\n\n- opening hours\n- price list\n- a question form\n' > "$d/notes/ideas.md"
  # A canary: /assemble must never run a project's scripts. If anything runs these, the file
  # REPO-SCRIPT-RAN appears and the snapshot shows it.
  printf '{\n  "name": "acme",\n  "private": true,\n  "scripts": {\n    "start": "touch REPO-SCRIPT-RAN",\n    "postinstall": "touch REPO-SCRIPT-RAN"\n  }\n}\n' > "$d/package.json"
  printf 'MAIL_PASSWORD=fixture-made-up-value\n' > "$d/.env"
  printf 'MAIL_PASSWORD=\n' > "$d/.env.example"
  printf 'fixture: not a real key\n' > "$d/dev.pem"
  dd if=/dev/zero of="$d/video.raw" bs=1 count=0 seek=52428801 2>/dev/null || fx_die "could not make the sparse 50 MB file"
  printf 'fixture: macOS folder junk\n' > "$d/.DS_Store"
  printf 'fixture: macOS folder junk\n' > "$d/notes/.DS_Store"
}

# A second person who commits to some fixtures' repos (fictional; a GitHub noreply address).
FX2_LOGIN=jordan-acme
FX2_NAME='Jordan Example'
FX2_EMAIL="87654321+$FX2_LOGIN@users.noreply.github.com"

# fx_commit WHO MESSAGE PATH...: commit PATHs in acme/ as WHO (priya or jordan).
fx_commit() {
  local who=$1 msg=$2 n e
  shift 2
  if [ "$who" = jordan ]; then n=$FX2_NAME; e=$FX2_EMAIL; else n=$FX_NAME; e=$FX_EMAIL; fi
  fx_git -C "$FX_ROOT/acme" add -- "$@"
  fx_git -C "$FX_ROOT/acme" -c user.name="$n" -c user.email="$e" commit -q -m "$msg" -- "$@"
}

# fixture_existing [options]: an existing project, acme/, already on GitHub. Its GitHub copy is a
# bare repo under remotes/<owner>/acme.git (the fake gh and git, in local-remote mode, reach it
# instead of the network); origin is https://github.com/<owner>/acme.git and the origin/* refs are
# fetched. The repo's facts for the fake gh go in gh-state/<owner>/acme/repo.conf.
#   --owner O            the GitHub owner (default priya-acme, the logged-in user)
#   --default B          the default branch (default main)
#   --size small|medium  about 8 files, or about 80 (a src/ and a test/ folder of 35 each)
#   --tests              a test/ folder and "npm test" (medium always has them)
#   --ci                 .github/workflows/ci.yml: runs the tests on push and pull_request (not a deploy)
#   --deploy             .github/workflows/deploy.yml: publishes to GitHub Pages on every push to B
#   --second-committer   Jordan also commits to B (2 people in 90 days)
#   --claude-md          a CLAUDE.md with project rules and four that conflict with the method
#   --claude-symlink     CLAUDE.md is a symlink to AGENTS.md
#   --log                a newest-first LOG.md
#   --decisions          docs/decisions.md (a table)
#   --codeowners         .github/CODEOWNERS
#   --pr-template        .github/pull_request_template.md
#   --feature-branch     the user is on priya/menu: one local commit, an edited CLAUDE.md (or
#                        app.js), an edited src/app.js and an untracked notes-draft.md
#   --open-pr-by-other   an open PR by Jordan from jordan/banner
#   --merged-prs N       N earlier PRs by Priya, merged (so the next PR number is N+1)
#   --visibility V --permission P --protected T --rules R --pages J   repo.conf facts (fake-gh)
#   --identity           user.name and user.email in the repo's own config
#   --helper             the gh credential helper in the repo's own config
#   --mail-keys          .env.example lists MAIL_API_KEY and MAIL_FROM (a paid email service: the
#                        scan's money signal) instead of PORT and SITE_URL (no signal)
#   --many-config        40 files in .claude/commands/, a .claude/settings.json and 45 workflows
#                        that only run checks (more than the scan's listing cap of 40 lines)
#   --husky              git hooks the husky way: core.hooksPath .husky, a tracked
#                        .husky/pre-commit that sources .husky/_/husky.sh, which is generated
#                        locally and ignored, so a fresh worktree has none and the hook fails there
#   --no-remote          no GitHub copy and no origin: the repo exists only on this computer
fixture_existing() {
  local owner=$FX_LOGIN def=main size=small tests=no ci=no deploy=no second=no claude=no symlink=no
  local log=no decisions=no codeowners=no prt=no feature=no openpr=no merged=0 identity=no helper=no mail=no
  local many=no husky=no remote=yes
  local vis=PRIVATE perm=ADMIN prot=false rules='[]' pages='' repo i n bare state
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --owner) owner=$2; shift 2 ;;
      --default) def=$2; shift 2 ;;
      --size) size=$2; shift 2 ;;
      --tests) tests=yes; shift ;;
      --ci) ci=yes; shift ;;
      --deploy) deploy=yes; shift ;;
      --second-committer) second=yes; shift ;;
      --claude-md) claude=yes; shift ;;
      --claude-symlink) symlink=yes; shift ;;
      --log) log=yes; shift ;;
      --decisions) decisions=yes; shift ;;
      --codeowners) codeowners=yes; shift ;;
      --pr-template) prt=yes; shift ;;
      --feature-branch) feature=yes; shift ;;
      --open-pr-by-other) openpr=yes; shift ;;
      --merged-prs) merged=$2; shift 2 ;;
      --visibility) vis=$2; shift 2 ;;
      --permission) perm=$2; shift 2 ;;
      --protected) prot=$2; shift 2 ;;
      --rules) rules=$2; shift 2 ;;
      --pages) pages=$2; shift 2 ;;
      --identity) identity=yes; shift ;;
      --helper) helper=yes; shift ;;
      --mail-keys) mail=yes; shift ;;
      --many-config) many=yes; shift ;;
      --husky) husky=yes; shift ;;
      --no-remote) remote=no; shift ;;
      *) fx_die "fixture_existing: unknown option $1" ;;
    esac
  done
  [ "$size" != medium ] || tests=yes
  repo="$FX_ROOT/acme"
  mkdir "$repo"
  fx_git -c init.defaultBranch="$def" init -q "$repo"
  fx_git -C "$repo" symbolic-ref HEAD "refs/heads/$def"

  printf '# Acme\n\nBookings for a pottery studio. A fictional app that exists only to test /assemble.\n' > "$repo/README.md"
  printf 'node_modules/\n.env\n' > "$repo/.gitignore"
  if [ "$mail" = yes ]; then
    printf 'MAIL_API_KEY=\nMAIL_FROM=\n' > "$repo/.env.example"
  else
    printf 'PORT=\nSITE_URL=\n' > "$repo/.env.example"
  fi
  # A canary: /assemble must never run a repo's scripts. If anything runs these, the file
  # REPO-SCRIPT-RAN appears and tests/check-untouched.sh reports it.
  printf '{\n  "name": "acme",\n  "private": true,\n  "scripts": {\n    "start": "touch REPO-SCRIPT-RAN",\n    "test": "touch REPO-SCRIPT-RAN",\n    "postinstall": "touch REPO-SCRIPT-RAN"\n  }\n}\n' > "$repo/package.json"
  fx_commit priya "Start" README.md .gitignore .env.example package.json

  mkdir "$repo/src"
  printf '<!doctype html>\n<title>Acme</title>\n<h1>Acme pottery</h1>\n<script src="src/app.js"></script>\n' > "$repo/index.html"
  printf 'document.querySelector("h1").textContent = "Book a wheel";\n' > "$repo/src/app.js"
  printf 'export const menu = ["Wheel hour", "Glazing night"];\n' > "$repo/src/menu.js"
  fx_commit priya "Add the booking page" index.html src/app.js src/menu.js

  if [ "$size" = medium ]; then
    mkdir -p "$repo/test"
    i=1
    while [ "$i" -le 35 ]; do
      n=$(printf '%02d' "$i")
      printf 'export function part%s(x) { return x + %d; }\n' "$n" "$i" > "$repo/src/part$n.js"
      printf 'import { part%s } from "../src/part%s.js";\nif (part%s(1) !== %d) throw new Error("part%s");\n' "$n" "$n" "$n" "$((i + 1))" "$n" > "$repo/test/part$n.test.js"
      i=$((i + 1))
    done
    ( cd "$repo" && fx_git add -- src test )
    fx_git -C "$repo" -c user.name="$FX_NAME" -c user.email="$FX_EMAIL" commit -q -m "Split the app into parts, with tests" -- src test
  elif [ "$tests" = yes ]; then
    mkdir -p "$repo/test"
    printf 'import { menu } from "../src/menu.js";\nif (menu.length !== 2) throw new Error("menu");\n' > "$repo/test/menu.test.js"
    fx_commit priya "Add a test" test/menu.test.js
  fi
  if [ "$ci" = yes ]; then
    mkdir -p "$repo/.github/workflows"
    printf 'name: tests\non:\n  push:\n  pull_request:\njobs:\n  test:\n    runs-on: ubuntu-24.04\n    steps:\n      - uses: actions/checkout@v4\n      - run: npm test\n' > "$repo/.github/workflows/ci.yml"
    fx_commit priya "Run the tests in CI" .github/workflows/ci.yml
  fi
  if [ "$deploy" = yes ]; then
    mkdir -p "$repo/.github/workflows"
    printf 'name: deploy\non:\n  push:\n    branches: [%s]\npermissions:\n  pages: write\n  id-token: write\njobs:\n  deploy:\n    runs-on: ubuntu-24.04\n    environment: github-pages\n    steps:\n      - uses: actions/checkout@v4\n      - uses: actions/upload-pages-artifact@v3\n        with:\n          path: .\n      - uses: actions/deploy-pages@v4\n' "$def" > "$repo/.github/workflows/deploy.yml"
    fx_commit priya "Publish the site on every push" .github/workflows/deploy.yml
  fi
  if [ "$claude" = yes ]; then
    printf '# Acme\n\nNotes for AI assistants working on this repo.\n\n- Use 2-space indentation and keep functions small.\n- Run `npm test` before pushing.\n- Commit straight to %s for small fixes; no pull request needed.\n- Merge your own pull request once CI is green.\n- Work in the main checkout only; never create extra worktrees.\n- Add a LOG.md entry with every change you make.\n' "$def" > "$repo/CLAUDE.md"
    fx_commit priya "Add notes for AI assistants" CLAUDE.md
  fi
  if [ "$symlink" = yes ]; then
    printf '# Agent rules\n\n- Use 2-space indentation.\n- Run the tests before pushing.\n' > "$repo/AGENTS.md"
    ln -s AGENTS.md "$repo/CLAUDE.md"
    fx_commit priya "Share the agent rules with Claude" AGENTS.md CLAUDE.md
  fi
  if [ "$log" = yes ]; then
    printf '# Log\n\nNewest first.\n\n## 2026-09-30 · Priya · Menu page started\nDrafted the menu page on a branch.\n\n## 2026-09-12 · Priya · First release\nThe booking page works.\n' > "$repo/LOG.md"
    fx_commit priya "Keep a log" LOG.md
  fi
  if [ "$decisions" = yes ]; then
    mkdir -p "$repo/docs"
    printf '# Decisions\n\n| Date | Decision | Why |\n|---|---|---|\n| 2026-09-10 | Plain HTML, no framework | A small site |\n| 2026-09-20 | Bookings by email for now | No payment provider yet |\n' > "$repo/docs/decisions.md"
    fx_commit priya "Write down the decisions so far" docs/decisions.md
  fi
  if [ "$codeowners" = yes ]; then
    mkdir -p "$repo/.github"
    printf '* @%s\n' "$owner" > "$repo/.github/CODEOWNERS"
    fx_commit jordan "Add code owners" .github/CODEOWNERS
  fi
  if [ "$prt" = yes ]; then
    mkdir -p "$repo/.github"
    printf '## Summary\n\n## How to test\n' > "$repo/.github/pull_request_template.md"
    fx_commit jordan "Add a PR template" .github/pull_request_template.md
  fi
  if [ "$second" = yes ]; then
    printf '.banner { color: teal; }\n' > "$repo/src/banner.css"
    fx_commit jordan "Add the banner style" src/banner.css
  fi
  if [ "$many" = yes ]; then
    mkdir -p "$repo/.claude/commands" "$repo/.github/workflows"
    i=1
    while [ "$i" -le 45 ]; do
      n=$(printf '%02d' "$i")
      [ "$i" -gt 40 ] || printf '# Command %s\n\nA saved prompt for the editor.\n' "$n" > "$repo/.claude/commands/cmd-$n.md"
      printf 'name: check-%s\non:\n  pull_request:\njobs:\n  check:\n    runs-on: ubuntu-24.04\n    steps:\n      - uses: actions/checkout@v4\n' "$n" > "$repo/.github/workflows/check-$n.yml"
      i=$((i + 1))
    done
    printf '{\n  "permissions": { "allow": [] }\n}\n' > "$repo/.claude/settings.json"
    ( cd "$repo" && fx_git add -- .claude .github/workflows )
    fx_git -C "$repo" -c user.name="$FX_NAME" -c user.email="$FX_EMAIL" commit -q -m "Editor commands and checks" -- .claude .github/workflows
  fi
  if [ "$husky" = yes ]; then
    mkdir -p "$repo/.husky"
    printf '#!/bin/sh\n. "$(dirname -- "$0")/_/husky.sh"\nexit 0\n' > "$repo/.husky/pre-commit"
    chmod 755 "$repo/.husky/pre-commit"
    printf '.husky/_/\n' >> "$repo/.gitignore"
    fx_commit priya "Run checks before each commit" .husky/pre-commit .gitignore
  fi

  # GitHub's copy: a bare repo with the default branch, and the origin refs on this computer.
  [ "$remote" = yes ] || { merged=0; openpr=no; }
  bare="$FX_ROOT/remotes/$owner/acme.git"
  if [ "$remote" = yes ]; then
    mkdir -p "$FX_ROOT/remotes/$owner"
    fx_git init -q --bare -b "$def" "$bare"
    fx_git -C "$repo" push -q "$bare" "refs/heads/$def:refs/heads/$def"
    fx_git -C "$repo" remote add origin "https://github.com/$owner/acme.git"
    fx_git -C "$repo" -c "url.$FX_ROOT/remotes/.insteadOf=https://github.com/" fetch -q origin
    fx_git -C "$repo" symbolic-ref refs/remotes/origin/HEAD "refs/remotes/origin/$def"
    fx_git -C "$repo" branch -q --set-upstream-to "origin/$def" "$def"

    state="$FX_ROOT/gh-state/$owner/acme"
    mkdir -p "$state"
    {
      printf "PERMISSION='%s'\nVISIBILITY='%s'\nDEFAULT='%s'\nPROTECTED='%s'\n" "$perm" "$vis" "$def" "$prot"
      printf "RULES='%s'\nPAGES='%s'\n" "$rules" "$pages"
    } > "$state/repo.conf"
  fi
  i=1
  while [ "$i" -le "$merged" ]; do
    mkdir -p "$state/pr-$i/comments"
    printf 'priya/T%s' "$i" > "$state/pr-$i/head"
    printf '%s' "$def" > "$state/pr-$i/base"
    printf 'MERGED' > "$state/pr-$i/state"
    printf 'Earlier change %s' "$i" > "$state/pr-$i/title"
    printf '%s' "$FX_LOGIN" > "$state/pr-$i/author"
    printf 'An earlier change.\n' > "$state/pr-$i/body"
    fx_git -C "$repo" rev-parse "refs/heads/$def" > "$state/pr-$i/head_oid"
    i=$((i + 1))
  done
  if [ "$openpr" = yes ]; then
    n=$((merged + 1))
    fx_git -C "$repo" switch -q -c jordan/banner
    printf '<p class="banner">Open late on Fridays</p>\n' > "$repo/banner.html"
    fx_commit jordan "Add a Friday banner" banner.html
    fx_git -C "$repo" push -q "$bare" refs/heads/jordan/banner:refs/heads/jordan/banner
    fx_git -C "$repo" switch -q "$def"
    fx_git -C "$repo" branch -q -D jordan/banner
    fx_git -C "$repo" -c "url.$FX_ROOT/remotes/.insteadOf=https://github.com/" fetch -q origin
    mkdir -p "$state/pr-$n/comments"
    printf 'jordan/banner' > "$state/pr-$n/head"
    printf '%s' "$def" > "$state/pr-$n/base"
    printf 'OPEN' > "$state/pr-$n/state"
    printf 'Friday banner' > "$state/pr-$n/title"
    printf '%s' "$FX2_LOGIN" > "$state/pr-$n/author"
    printf 'Adds a banner for Friday opening hours.\n' > "$state/pr-$n/body"
  fi

  if [ "$feature" = yes ]; then
    fx_git -C "$repo" switch -q -c priya/menu
    printf 'export const menu = ["Wheel hour", "Glazing night", "Kids clay"];\n' > "$repo/src/menu.js"
    fx_commit priya "Add a kids class to the menu" src/menu.js
    # Uncommitted work: two edited tracked files and one untracked file.
    printf 'document.querySelector("h1").textContent = "Book a wheel or a class";\n' > "$repo/src/app.js"
    if [ -f "$repo/CLAUDE.md" ] && [ ! -L "$repo/CLAUDE.md" ]; then
      printf -- '- Local draft rule: try the new menu first.\n' >> "$repo/CLAUDE.md"
    fi
    printf 'Menu ideas: kids clay, glazing night.\n' > "$repo/notes-draft.md"
  fi
  if [ "$identity" = yes ]; then
    fx_git -C "$repo" config user.name "$FX_NAME"
    fx_git -C "$repo" config user.email "$FX_EMAIL"
  fi
  if [ "$helper" = yes ]; then
    fx_git -C "$repo" config credential.https://github.com.helper '!gh auth git-credential'
  fi
  if [ "$husky" = yes ]; then
    # What the project's install step leaves in the user's own checkout: ignored, never committed.
    mkdir -p "$repo/.husky/_"
    printf '# made by the install step (fixture)\n' > "$repo/.husky/_/husky.sh"
    fx_git -C "$repo" config core.hooksPath .husky
  fi
}

# fixture_global_identity: put user.name, user.email and the gh credential helper in the fixture's
# own (isolated) global git config, as on a computer that already uses git with GitHub.
fixture_global_identity() {
  fx_git config --global user.name "$FX_NAME"
  fx_git config --global user.email "$FX_EMAIL"
  fx_git config --global credential.https://github.com.helper '!gh auth git-credential'
}

# fixture_snapshot ROOT GIT: print everything a run must leave unchanged.
fixture_snapshot() {
  local root=$1 git=$2 repo="$1/acme"
  sgit() {
    env HOME="$root/git-home" XDG_CONFIG_HOME="$root/git-home/.config" \
      GIT_CONFIG_GLOBAL="$root/git-home/.gitconfig" GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 \
      GIT_CEILING_DIRECTORIES="$root" "$git" -C "$repo" "$@" 2>&1 || true
  }
  echo "== fixture folder (names)"
  ls -A "$root" | grep -v -x -e before.txt -e after.txt -e changes.diff -e write-screen-approved || true
  echo "== home for git (files)"
  ( cd "$root/git-home" && find . -type f | sort )
  echo "== isolated global git config"
  cat "$root/git-home/.gitconfig"
  echo "== gh config folder (names)"
  ls -A "$root/gh-config"
  [ -d "$repo" ] || return 0
  echo "== project folder (names, outside .git)"
  ( cd "$repo" && find . -path ./.git -prune -o -print | sort )
  echo "== HEAD"
  sgit symbolic-ref -q HEAD
  sgit rev-parse HEAD
  echo "== refs"
  sgit for-each-ref --format='%(refname) %(objectname)'
  echo "== worktrees"
  sgit worktree list --porcelain
  echo "== repo config"
  sgit config --local --list
  echo "== status (untracked and ignored files too)"
  sgit status --porcelain=v1 --untracked-files=all --ignored
  echo "== info/exclude"
  cat "$repo/.git/info/exclude" 2>/dev/null || echo "(none)"
}

# fixture_end: write env.sh, take the before snapshot, say what to do next.
fixture_end() {
  cat > "$FX_ROOT/env.sh" <<EOF
# Generated by tests/fixtures/$FX_FIXTURE/setup.sh. In a NEW terminal:  . '$FX_ROOT/env.sh'
# Puts the fixture's shims first on PATH and shuts out your own git and gh settings.
export PATH='$FX_ROOT/bin':"\$PATH"
export GIT_CONFIG_GLOBAL='$FX_ROOT/git-home/.gitconfig'
export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
# git never looks above the fixture folder for a repo, even if the fixture sits inside one.
export GIT_CEILING_DIRECTORIES='$FX_ROOT'
export GH_CONFIG_DIR='$FX_ROOT/gh-config'
unset GH_TOKEN GITHUB_TOKEN GH_ENTERPRISE_TOKEN GITHUB_ENTERPRISE_TOKEN GH_HOST
# The fixtures are terminal runs. A real claude sets CLAUDE_CODE_ENTRYPOINT=cli itself; setting it
# here too stops a value inherited from another Claude session (a desktop or cloud one) and lets a
# harness that drives the skill without a real claude see the terminal, so "Where" isn't asked.
export CLAUDE_CODE_ENTRYPOINT=cli
unset CLAUDE_CODE_REMOTE
export ASSEMBLE_FIXTURE='$FX_FIXTURE'
EOF
  fixture_snapshot "$FX_ROOT" "$FX_REAL_GIT" > "$FX_ROOT/before.txt"
  printf 'Built fixture "%s" in %s\n' "$FX_FIXTURE" "$FX_ROOT"
  printf 'Run it (tests/checklist.md): in a new terminal,\n'
  printf "  . '%s/env.sh' && cd '%s/acme' && claude\n" "$FX_ROOT" "$FX_ROOT"
  printf 'then type /assemble. Afterwards: tests/check-untouched.sh %s\n' "$FX_ROOT"
  if [ "${FX_WRITES:-no}" = yes ]; then
    printf 'This fixture allows writes after the write screen. When the write screen is on screen, before\n'
    printf 'you answer it, run in another terminal:  touch %s/write-screen-approved\n' "$FX_ROOT"
    printf 'To merge a PR as the human would on GitHub:  tests/lib/fake-gh-merge %s <PR number>\n' "$FX_ROOT"
  fi
}
