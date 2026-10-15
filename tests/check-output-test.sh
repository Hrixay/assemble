#!/usr/bin/env bash
# check-output-test.sh: scripts/check-output.sh must pass on the hand-rendered examples
# (tests/rendered/acme, a Standard team; acme-small, a Small team; and tests/rendered/lemonade: a
# Full team with a Researcher and a Designer, a beside-repo notes folder, a filled RUNBOOK and
# PROPOSALS, a lesson, a seeded glossary and a decision briefing) and on a
# few harmless variations of them, and must fail on each seeded bad copy. Every copy is made in
# $TMPDIR; the examples themselves are never changed.
#
# Usage: tests/check-output-test.sh
# Exit:  0 = every expectation held, 1 = at least one did not.
# Portable bash: runs on macOS bash 3.2 and on Linux. No GNU-only flags.

set -eu
LC_ALL=C
export LC_ALL
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
check="$root/scripts/check-output.sh"
example="$root/tests/rendered/acme"
lemonade="$root/tests/rendered/lemonade"
[ -f "$check" ] || { echo "check-output-test: $check is missing" >&2; exit 1; }
[ -d "$example" ] || { echo "check-output-test: $example is missing" >&2; exit 1; }
[ -d "$lemonade" ] || { echo "check-output-test: $lemonade is missing" >&2; exit 1; }

work=$(mktemp -d "${TMPDIR:-/tmp}/check-output-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

bad=0
total=0

# expect pass|fail NAME DIR [TEXT]: run the check on DIR; a fail must also print TEXT.
expect() {
  want=$1 name=$2 dir=$3 needle=${4:-}
  total=$((total + 1))
  set +e
  out=$(bash "$check" "$dir" 2>&1)
  code=$?
  set -e
  if [ "$want" = pass ] && [ "$code" -eq 0 ]; then
    printf 'ok    passes: %s\n' "$name"
  elif [ "$want" = fail ] && [ "$code" -eq 1 ] && { [ -z "$needle" ] || printf '%s\n' "$out" | grep -qF -- "$needle"; }; then
    printf 'ok    caught: %s\n' "$name"
  else
    printf 'FAIL  %s: wanted %s, got exit %s\n' "$name" "$want" "$code"
    [ -z "$needle" ] || printf '      expected to see: %s\n' "$needle"
    printf '%s\n' "$out" | sed 's/^/      | /'
    bad=$((bad + 1))
  fi
}

# seed NAME: a fresh copy of the example; prints its path.
seed() {
  d="$work/$1"
  rm -rf "$d"
  cp -R "$example" "$d"
  printf '%s\n' "$d"
}

# lseed NAME: a fresh copy of the lemonade example; prints its path.
lseed() {
  d="$work/$1"
  rm -rf "$d"
  cp -R "$lemonade" "$d"
  printf '%s\n' "$d"
}

# replace FILE OLD NEW: replace every line that contains OLD (plain text) with NEW.
replace() {
  OLD=$2 NEW=$3 awk 'index($0, ENVIRON["OLD"]) { print ENVIRON["NEW"]; n++; next } { print } END { exit (n ? 0 : 3) }' "$1" > "$1.tmp" \
    || { echo "check-output-test: \"$2\" not found in $1" >&2; exit 1; }
  mv "$1.tmp" "$1"
}
# drop FILE TEXT: delete every line that contains TEXT.
drop() {
  T=$2 awk 'index($0, ENVIRON["T"]) { n++; next } { print } END { exit (n ? 0 : 3) }' "$1" > "$1.tmp" \
    || { echo "check-output-test: \"$2\" not found in $1" >&2; exit 1; }
  mv "$1.tmp" "$1"
}
# after FILE TEXT NEW: add the line NEW after every line that contains TEXT.
after() {
  T=$2 NEW=$3 awk '{ print } index($0, ENVIRON["T"]) { print ENVIRON["NEW"]; n++ } END { exit (n ? 0 : 3) }' "$1" > "$1.tmp" \
    || { echo "check-output-test: \"$2\" not found in $1" >&2; exit 1; }
  mv "$1.tmp" "$1"
}
block() { awk 'index($0, "<!-- assemble:begin") { on = 1 } on { print } index($0, "<!-- assemble:end -->") { on = 0 }' "$1"; }
# unblock FILE: the file without its marked block.
unblock() { awk 'index($0, "<!-- assemble:begin") { skip = 1 } !skip { print } index($0, "<!-- assemble:end -->") { skip = 0 }' "$1" > "$1.tmp"; mv "$1.tmp" "$1"; }
# claude_dir DIR IMPORT: move the CLAUDE.md block into .claude/CLAUDE.md, with IMPORT as its import line.
claude_dir() {
  mkdir -p "$1/.claude"
  block "$1/CLAUDE.md" | sed "s#^@.*CHATS\.md\$#$2#" > "$1/.claude/CLAUDE.md"
  unblock "$1/CLAUDE.md"
}
# underscore DIR: rename the notes folder to _team/ the way PLACEHOLDERS.md rule 5 says: every team/ that
# names the notes folder, including the one in acme-team/team/ (a letter, digit, _ or - before team/ means
# it is part of another name, such as acme-team/).
underscore() {
  mv "$1/team" "$1/_team"
  dirs="_team CLAUDE.md"
  [ ! -d "$1/.github" ] || dirs="$dirs .github"
  for f in $(cd "$1" && find $dirs -type f); do
    sed -E -e 's#(^|[^A-Za-z0-9_-])team/#\1_team/#g' -e 's#"folder": "team"#"folder": "_team"#' "$1/$f" > "$1/$f.tmp"
    mv "$1/$f.tmp" "$1/$f"
  done
}

readme_row='| `team/README.md` | Cyrus |'

echo "== the example and harmless variations"
expect pass "tests/rendered/acme as committed (Standard)" "$example"
expect pass "tests/rendered/acme-small as committed (a new project, Small: Chief, Builder, reviewer helper)" "$root/tests/rendered/acme-small"
expect pass "tests/rendered/lemonade as committed (Full)" "$lemonade"

d=$(seed log-archive)
printf '# Log archive\n*Older LOG.md entries, newest first, moved here from LOG.md. Never rewritten.*\n' > "$d/team/LOG-archive.md"
mkdir -p "$d/team/briefings"
printf '# D3 · Hosting\n## The problem\n' > "$d/team/briefings/D3-hosting.md"
expect pass "a LOG-archive.md and a briefing, both owned by the Chief through their CHATS.md rows" "$d"

d=$(seed user-braces)
after "$d/CLAUDE.md" "- Test: \`npm test\`" "- Templates in src/ use {{ title }} (the user's own text, above the block)"
expect pass "{{ in the user's own CLAUDE.md lines, outside the block" "$d"

d=$(seed adopted-with-row)
replace "$d/team/assemble.json" '"adopted": {}' '  "adopted": { "log": "LOG.md" }'
after "$d/team/CHATS.md" "$readme_row" '| `LOG.md` | Cyrus | After every event |'
printf '# Log\n' > "$d/LOG.md"
expect pass "an adopted LOG.md with its own owner row" "$d"

d=$(seed second-builder)
after "$d/team/ROSTER.md" "| Bram | Bram · Acme Builder |" "| Bilal | Bilal · Acme Builder | Builds the app | Merges | its own branches and PRs | Sonnet | Active |"
cp "$d/team/roles/builder.md" "$d/team/roles/builder-bilal.md"
expect pass "a second Builder with roles/builder-bilal.md (a second chat in a role)" "$d"

d=$(seed underscore-folder)
underscore "$d"
expect pass "the notes folder renamed _team/ (an unrelated team/ existed)" "$d"
total=$((total + 1))
left=$(grep -rEn '(^|[^A-Za-z0-9_-])team/' "$d" || true)
if [ -z "$left" ]; then
  printf 'ok    no team/ left that should have been renamed _team/ (including acme-team/_team/)\n'
else
  printf 'FAIL  a team/ was left after the _team/ rename:\n%s\n' "$left" | sed 's/^/      | /'
  bad=$((bad + 1))
fi

d=$(seed adopted-ask)
rm "$d/team/the-ask.md"
replace "$d/team/assemble.json" '"adopted": {}' '  "adopted": { "ask": "the-ask.md" }'
after "$d/team/CHATS.md" '| `team/the-ask.md` | nobody |' "| \`the-ask.md\` | nobody | Written once from Priya's own words; never changes after |"
expect pass "an adopted the-ask.md with a nobody row" "$d"

d=$(seed adopted-research)
replace "$d/team/assemble.json" '"adopted": {}' '  "adopted": { "research": "research/" }'
after "$d/team/CHATS.md" '| `team/research/**` |' '| `research/` | the Researcher, by PR | When a question is answered |'
expect pass "an adopted research/ with a Researcher, by PR row" "$d"

d=$(seed claude-dir)
claude_dir "$d" '@../team/CHATS.md'
expect pass "the block in .claude/CLAUDE.md with the import @../team/CHATS.md" "$d"

d=$(seed claude-dir-underscore)
underscore "$d"
claude_dir "$d" '@../_team/CHATS.md'
expect pass "the block in .claude/CLAUDE.md in a _team/ folder, import @../_team/CHATS.md" "$d"

d=$(seed git-tracked)
printf 'junk\n' > "$d/team/.DS_Store"
git -C "$d" init -q
git -C "$d" add -- CLAUDE.md .github team/CHATS.md team/DECISIONS.md team/LOG.md team/README.md team/ROSTER.md \
  team/TASKS.md team/TRIED-AND-DROPPED.md team/assemble.json team/handovers team/review-checklist.md team/roles team/the-ask.md \
  team/LESSONS.md team/GLOSSARY.md
expect pass "a git checkout: an untracked junk file in team/ is not read" "$d"

d=$(seed git-non-ascii-clean)
printf '# Notes\n' > "$d/team/handovers/$(printf 'caf\303\251')-notes.md"
git -C "$d" init -q
git -C "$d" add -- CLAUDE.md .github team
expect pass "a git checkout: a file with a non-ASCII name is read and passes" "$d"

echo "== seeded bad copies (each must fail)"
d=$(seed git-non-ascii-placeholder)
printf 'Owner: {{WRITER}}\n' > "$d/team/handovers/$(printf 'caf\303\251')-notes.md"
git -C "$d" init -q
git -C "$d" add -- CLAUDE.md .github team
expect fail "a placeholder left in a file with a non-ASCII name (git checkout)" "$d" "placeholder left: {{WRITER}}"

d=$(seed adopted-ask-owned)
rm "$d/team/the-ask.md"
replace "$d/team/assemble.json" '"adopted": {}' '  "adopted": { "ask": "the-ask.md" }'
after "$d/team/CHATS.md" '| `team/the-ask.md` | nobody |' '| `the-ask.md` | Cyrus | When Priya changes her mind |'
expect fail "an adopted the-ask.md given an owner" "$d" "nobody updates the-ask.md"

d=$(seed adopted-ask-no-row)
rm "$d/team/the-ask.md"
replace "$d/team/assemble.json" '"adopted": {}' '  "adopted": { "ask": "the-ask.md" }'
expect fail "an adopted the-ask.md with no row" "$d" "the-ask.md: needs exactly one row"

d=$(seed claude-dir-wrong-import)
claude_dir "$d" '@team/CHATS.md'
expect fail "the block in .claude/CLAUDE.md with the import @team/CHATS.md (it would not load)" "$d" 'has no line "@../team/CHATS.md"'

d=$(seed placeholder)
printf 'Owner: {{WRITER}}\n' >> "$d/team/TASKS.md"
expect fail "a placeholder left in team/TASKS.md" "$d" "team/TASKS.md:"

d=$(seed placeholder-block)
replace "$d/CLAUDE.md" "the notebook folder acme-team/team/ next to the main checkout (the first entry of" \
  "the notebook folder {{REPO}}-team/team/ next to the main checkout (the first entry of"
expect fail "a placeholder left in the CLAUDE.md block" "$d" "CLAUDE.md:"

d=$(seed placeholder-pr-template)
printf '%s\n' '- [ ] Cut from `origin/{{DEFAULT_BRANCH}}`' >> "$d/.github/pull_request_template.md"
expect fail "a placeholder left in the PR template" "$d" "placeholder left: {{DEFAULT_BRANCH}}"

d=$(seed no-owner-row)
drop "$d/team/CHATS.md" "$readme_row"
expect fail "team/README.md has no owner row" "$d" "team/README.md: notebook file with no owner row"

d=$(seed two-owner-rows)
after "$d/team/CHATS.md" "$readme_row" '| `team/README.md` | Vito | When Vito likes |'
expect fail "team/README.md has two owner rows" "$d" "team/README.md: 2 owner rows"

d=$(seed wrong-owner)
replace "$d/team/CHATS.md" '| `team/LOG.md` | Cyrus |' '| `team/LOG.md` | Vito | After every event |'
expect fail "team/LOG.md owned by the Reviewer" "$d" "team/LOG.md: owner is \"Vito\""

d=$(seed unowned-file)
printf '# Scratch notes\n' > "$d/team/NOTES.md"
expect fail "a new notebook file with no owner row" "$d" "team/NOTES.md: notebook file with no owner row"

d=$(seed no-lessons-row)
drop "$d/team/CHATS.md" '| `team/LESSONS.md` |'
expect fail "team/LESSONS.md has no owner row" "$d" "team/LESSONS.md: notebook file with no owner row"

d=$(seed glossary-owned-by-doer)
replace "$d/team/CHATS.md" '| `team/GLOSSARY.md` |' '| `team/GLOSSARY.md` | Bram | When Bram names something |'
expect fail "team/GLOSSARY.md owned by the Builder" "$d" "team/GLOSSARY.md: owner is \"Bram\""

d=$(seed briefing-no-row)
mkdir -p "$d/team/briefings"
printf '# D3 · Hosting\n' > "$d/team/briefings/D3-hosting.md"
drop "$d/team/CHATS.md" '| `team/briefings/` |'
expect fail "a decision briefing with no briefings/ owner row" "$d" "team/briefings/D3-hosting.md: notebook file with no owner row"

d=$(seed archive-no-row)
printf '# Log archive\n' > "$d/team/LOG-archive.md"
drop "$d/team/CHATS.md" '| `team/LOG-archive.md` |'
expect fail "LOG-archive.md with no owner row" "$d" "team/LOG-archive.md: notebook file with no owner row"

d=$(seed no-lessons-file)
rm "$d/team/LESSONS.md"
expect fail "team/LESSONS.md deleted (it would turn the lessons list off)" "$d" "missing: team/LESSONS.md"

d=$(seed no-glossary-file)
rm "$d/team/GLOSSARY.md"
expect fail "team/GLOSSARY.md deleted" "$d" "missing: team/GLOSSARY.md"

d=$(seed adopted-log-missing)
rm "$d/team/LOG.md"
drop "$d/team/CHATS.md" '| `team/LOG.md` |'
replace "$d/team/assemble.json" '"adopted": {}' '  "adopted": { "log": "LOG.md" }'
after "$d/team/CHATS.md" "$readme_row" '| `LOG.md` | Cyrus | After every event |'
expect fail "an adopted LOG.md that isn't there" "$d" "missing: LOG.md (adopted log)"

d=$(seed no-role-file)
rm "$d/team/roles/builder.md"
expect fail "a ROSTER chat without its role file" "$d" "role file for Bram"

d="$work/no-helper-file"
rm -rf "$d"
cp -R "$root/tests/rendered/acme-small" "$d"
rm "$d/team/roles/reviewer.md"
expect fail "no roles/reviewer.md with no standing Reviewer (the helper reads it)" "$d" "missing: team/roles/reviewer.md"

d=$(seed no-handovers-row)
drop "$d/team/CHATS.md" '| `team/handovers/` |'
expect fail "the setup handover has no owner row" "$d" "team/handovers/setup-2026-10-12.md: notebook file with no owner row"

d=$(seed ask-owned)
replace "$d/team/CHATS.md" '| `team/the-ask.md` | nobody |' '| `team/the-ask.md` | Cyrus | When Priya changes her mind |'
expect fail "the-ask.md given an owner" "$d" "nobody updates the-ask.md"

d=$(seed adopted-no-row)
replace "$d/team/assemble.json" '"adopted": {}' '  "adopted": { "log": "LOG.md" }'
expect fail "an adopted LOG.md with no owner row" "$d" "LOG.md: notebook file with no owner row"

d=$(seed adopted-absolute)
replace "$d/team/assemble.json" '"adopted": {}' '  "adopted": { "log": "/etc/LOG.md" }'
expect fail "an adopted path that is absolute" "$d" "must be relative"

d=$(seed adopted-outside)
replace "$d/team/assemble.json" '"adopted": {}' '  "adopted": { "log": "../other/LOG.md" }'
expect fail "an adopted path outside the repo" "$d" "must be relative"

d=$(seed no-adopted-key)
drop "$d/team/assemble.json" '"adopted"'
replace "$d/team/assemble.json" '  ],' '  ]'
expect fail "assemble.json without an adopted key" "$d" "no \"adopted\" key"

d=$(seed no-table)
replace "$d/team/CHATS.md" "## Who updates what" "## Who writes what"
expect fail "CHATS.md without the Who updates what table" "$d" "no \"## Who updates what\" table"

d=$(seed two-writers)
replace "$d/team/ROSTER.md" "| Vito | Vito · Acme Reviewer |" "| Vito | Vito · Acme Chief | Checks every PR | Merges | PR comments | Opus | Active |"
expect fail "two Chiefs (two notebook writers) in ROSTER.md" "$d" "found 2"

d=$(seed lead-is-no-writer)
replace "$d/team/ROSTER.md" "| Cyrus | Cyrus · Acme Chief |" "| Cyrus | Cyrus · Acme Lead | Takes in work and builds | Decides | notes | Opus | Active |"
expect fail "a chat titled Lead is not a notebook writer (there is no Lead role)" "$d" "found 0"

d=$(seed no-doer)
drop "$d/team/ROSTER.md" "| Bram | Bram · Acme Builder |"
expect fail "a roster with no doer (the Chief never does the heavy work itself)" "$d" "has no doer"

d="$work/chief-alone"
rm -rf "$d"
cp -R "$root/tests/rendered/acme-small" "$d"
drop "$d/team/ROSTER.md" "| Bram | Bram · Acme Builder |"
expect fail "a Chief alone (a Small team without its doer)" "$d" "has no doer"

d=$(seed no-writer)
replace "$d/team/ROSTER.md" "| Cyrus | Cyrus · Acme Chief |" "| Cyrus | Cyrus · Acme Boss | Takes in work | Decides | notes | Opus | Active |"
expect fail "no notebook writer in ROSTER.md" "$d" "found 0"

d=$(seed no-begin)
drop "$d/CLAUDE.md" "<!-- assemble:begin"
expect fail "the begin marker missing" "$d" "exactly once"

d=$(seed block-twice)
block "$d/CLAUDE.md" > "$d/block.txt"
cat "$d/block.txt" >> "$d/CLAUDE.md"
rm "$d/block.txt"
expect fail "the block appended twice" "$d" "exactly once"

d=$(seed block-in-both)
mkdir -p "$d/.claude"
block "$d/CLAUDE.md" > "$d/.claude/CLAUDE.md"
expect fail "the block in CLAUDE.md and .claude/CLAUDE.md" "$d" "exactly once"

d=$(seed no-import)
drop "$d/CLAUDE.md" "@team/CHATS.md"
expect fail "the block without its @team/CHATS.md import" "$d" "has no line"

d=$(seed no-claude-md)
rm "$d/CLAUDE.md"
expect fail "no CLAUDE.md at all" "$d" "no CLAUDE.md"

# Home-folder paths, built from pieces so this file never matches the leak scan.
d=$(seed mac-path)
printf 'Notes live in %sUsers%spriya/acme-team\n' "/" "/" >> "$d/team/README.md"
expect fail "a macOS home-folder path in team/README.md" "$d" "home-folder path (macOS style)"

d=$(seed linux-path)
printf 'Notes live in %shome%spriya/acme-team\n' "/" "/" >> "$d/team/roles/builder.md"
expect fail "a Linux home-folder path in a role file" "$d" "home-folder path (Linux style)"

d=$(seed windows-path)
printf 'Notes live in C:%sUsers%spriya\n' '\' '\' >> "$d/team/ROSTER.md"
expect fail "a Windows home-folder path in ROSTER.md" "$d" "home-folder path (Windows style)"

d=$(seed path-in-block)
replace "$d/CLAUDE.md" "work normally and don't edit team/. If anything above conflicts with team/CHATS.md, ask Priya;" \
  "$(printf 'work normally (see %shome%spriya). If anything above conflicts with team/CHATS.md, ask Priya;' / /)"
expect fail "a home-folder path inside the CLAUDE.md block" "$d" "CLAUDE.md:"

echo "== the lemonade example: a Researcher, a Designer, a RUNBOOK and PROPOSALS (beside-repo)"
# PROPOSALS.md is a notebook file (one owner row, the notebook writer). RUNBOOK.md, PLAN.md and
# research/ are work files that land by PR: they need no row of their own.
d=$(lseed lemonade-work-files-need-no-row)
drop "$d/team/CHATS.md" '| `team/RUNBOOK.md` |'
drop "$d/team/CHATS.md" '| `team/research/**` |'
drop "$d/team/CHATS.md" '| `team/PLAN.md` |'
expect pass "RUNBOOK.md, PLAN.md and research/ without owner rows (they are work files)" "$d"

d=$(lseed lemonade-new-dossier)
printf '# Another dossier\n\nNothing here is decided.\n' > "$d/team/research/payments.md"
expect pass "a new dossier in team/research/ (a work file, no owner row)" "$d"

# RUNBOOK.md is a work file with one extra rule: it must be on the precious list in assemble.json
# (anything touching it is full tier, and assemble.json is the one home of that list).
d=$(lseed lemonade-underscore-folder)
underscore "$d"
expect pass "the lemonade example with the notes folder renamed _team/ (the precious entry is _team/RUNBOOK.md)" "$d"

d=$(lseed lemonade-no-runbook)
rm "$d/team/RUNBOOK.md"
replace "$d/team/assemble.json" '"team/RUNBOOK.md"' '    "NOTES.md"'
expect pass "no RUNBOOK.md and no precious entry for it (nothing live to guard)" "$d"

d=$(lseed lemonade-runbook-not-precious)
replace "$d/team/assemble.json" '"team/RUNBOOK.md"' '    "NOTES.md"'
expect fail "RUNBOOK.md exists but is not on the precious list" "$d" 'must include "team/RUNBOOK.md"'

d=$(lseed lemonade-proposals-no-row)
drop "$d/team/CHATS.md" '| `team/PROPOSALS.md` |'
expect fail "team/PROPOSALS.md has no owner row" "$d" "team/PROPOSALS.md: notebook file with no owner row"

d=$(lseed lemonade-proposals-two-rows)
after "$d/team/CHATS.md" '| `team/PROPOSALS.md` |' '| `team/PROPOSALS.md` | Vito | When Vito has an idea |'
expect fail "team/PROPOSALS.md has two owner rows" "$d" "team/PROPOSALS.md: 2 owner rows"

d=$(lseed lemonade-proposals-researcher)
replace "$d/team/CHATS.md" '| `team/PROPOSALS.md` |' '| `team/PROPOSALS.md` | Rhea | When an idea for the owners comes up |'
expect fail "team/PROPOSALS.md owned by the Researcher" "$d" "team/PROPOSALS.md: owner is \"Rhea\""

d=$(lseed lemonade-unowned-note)
printf '# Wishes\n' > "$d/team/WISHES.md"
expect fail "a new notebook file next to PROPOSALS.md with no owner row" "$d" "team/WISHES.md: notebook file with no owner row"

d=$(lseed lemonade-two-writers)
replace "$d/team/ROSTER.md" "| Dara | Dara · Lemonade Designer |" "| Dara | Dara · Lemonade Chief | UI and visual work | Merges | her own branches | Sonnet | Active |"
expect fail "a Designer titled Chief makes a second notebook writer" "$d" "found 2"

d=$(lseed lemonade-briefing-placeholder)
printf 'Waiting on {{HUMAN}}\n' >> "$d/team/briefings/D4-send-proposal.md"
expect fail "a placeholder left in a decision briefing" "$d" "team/briefings/D4-send-proposal.md:"

d=$(lseed lemonade-lessons-owned-by-reviewer)
replace "$d/team/CHATS.md" '| `team/LESSONS.md` |' '| `team/LESSONS.md` | Vito | When Vito finds a slip |'
expect fail "team/LESSONS.md owned by the Reviewer" "$d" "team/LESSONS.md: owner is \"Vito\""

d=$(lseed lemonade-runbook-placeholder)
printf 'Taken by: {{HUMAN}}\n' >> "$d/team/RUNBOOK.md"
expect fail "a placeholder left in team/RUNBOOK.md" "$d" "team/RUNBOOK.md:"

d=$(lseed lemonade-dossier-placeholder)
printf 'Decisions for {{HUMAN}}\n' >> "$d/team/research/preorders.md"
expect fail "a placeholder left in a research dossier" "$d" "team/research/preorders.md:"

d=$(lseed lemonade-start-here-placeholder)
printf 'Kept by {{WRITER}}\n' >> "$d/team/research/START-HERE.md"
expect fail "a placeholder left in research/START-HERE.md" "$d" "team/research/START-HERE.md:"

d=$(lseed lemonade-proposals-placeholder)
printf 'Only {{HUMAN}} sends anything\n' >> "$d/team/PROPOSALS.md"
expect fail "a placeholder left in team/PROPOSALS.md" "$d" "team/PROPOSALS.md:"

d=$(lseed lemonade-role-placeholder)
printf 'Branch prefix: {{HANDLE}}/\n' >> "$d/team/roles/researcher.md"
expect fail "a placeholder left in the Researcher's role file" "$d" "team/roles/researcher.md:"

d=$(lseed lemonade-pr-template-placeholder)
printf '%s\n' '- [ ] Cut from `origin/{{DEFAULT_BRANCH}}`' >> "$d/team/pr-template.md"
expect fail "a placeholder left in team/pr-template.md (beside-repo PR template)" "$d" "team/pr-template.md:"

d=$(lseed lemonade-runbook-path)
printf 'Backup folder: %sUsers%spriya/lemonade-backup\n' "/" "/" >> "$d/team/RUNBOOK.md"
expect fail "a macOS home-folder path in team/RUNBOOK.md" "$d" "home-folder path (macOS style)"

d=$(lseed lemonade-dossier-path)
printf 'Photos are in %shome%spriya/photos\n' "/" "/" >> "$d/team/research/preorders-findings.md"
expect fail "a Linux home-folder path in a findings file" "$d" "home-folder path (Linux style)"

d=$(lseed lemonade-block-twice)
block "$d/CLAUDE.md" > "$d/block.txt"
cat "$d/block.txt" >> "$d/CLAUDE.md"
rm "$d/block.txt"
expect fail "the CLAUDE.md block in the notes folder appended twice" "$d" "exactly once"

if [ "$bad" -gt 0 ]; then
  echo "check-output-test: $bad of $total expectation(s) did not hold"
  exit 1
fi
echo "check-output-test: all $total expectations held"
