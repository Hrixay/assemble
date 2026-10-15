#!/usr/bin/env bash
# templates-test.sh: the skill's templates, templates/PLACEHOLDERS.md and the hand-rendered examples
# (tests/rendered/*) agree.
#
#   1. The core templates exist (later PRs add more; this is the minimum).
#   2. Every role file, in the templates and in every rendered example, has the shared skeleton:
#      the ten headings in order, the two plan lists word for word, and the right Type on its
#      Address line (every doer says "Type: doer").
#   3. The lemonade example still shows what it exists to show: a Researcher and a Designer, a
#      filled-in runbook, at least one entry in PROPOSALS.md, a decision briefing, one lesson in
#      LESSONS.md with its LOG entry, and a GLOSSARY.md row for every D, T and track name its notes
#      use, plus the chats row.
#   4. The rendered role files and CHATS.md are exactly what their template gives with that
#      example's flags and values (so a template change cannot leave an example behind); the
#      same for LESSONS.md and GLOSSARY.md at setup (acme, acme-small), and TRIED-AND-DROPPED.md.
#   4b. Always a Chief of Staff (plan decisions 10 to 12): no Lead, Solo or Pair (or old Lead
#      name) in the skill, the examples, the fixtures, the scripts or CI; the Chief's role file has its thinking-partner section and the decision briefing;
#      CHATS.md has the lessons list in rule 1 and chats that talk to each other; the review
#      checklist treats a repeated lesson as HIGH.
#   5. Every placeholder is well formed: each "{{" starts a {{NAME}} of capital letters, digits
#      and underscores.
#   6. Line flags ({{IF_...}}) appear only at the very start of a line.
#   7. Every {{NAME}} used in a template is listed in PLACEHOLDERS.md, and every {{NAME}} listed
#      there is used in some template.
#
# Usage: tests/templates-test.sh
# Exit:  0 = all checks passed, 1 = at least one failed.
# Portable bash: runs on macOS bash 3.2 and on Linux. No GNU-only flags.

set -eu
LC_ALL=C
export LC_ALL

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tdir="$root/skills/assemble/templates"
doc="$tdir/PLACEHOLDERS.md"
work=$(mktemp -d "${TMPDIR:-/tmp}/templates-test.XXXXXX")
trap 'rm -rf "$work"' EXIT

fails=0
fail() { printf 'FAIL  %s\n' "$*"; fails=$((fails + 1)); }
pass() { printf 'ok    %s\n' "$*"; }

CORE="claude-block.md README.md CHATS.md ROSTER.md the-ask.md LOG.md DECISIONS.md TASKS.md
TRIED-AND-DROPPED.md review-checklist.md LESSONS.md GLOSSARY.md assemble.json
pull_request_template.md PLAN.md PLACEHOLDERS.md roles/chief.md roles/reviewer.md roles/builder.md"

missing=0
for f in $CORE; do
  if [ ! -f "$tdir/$f" ]; then
    fail "templates/$f is missing"
    missing=1
  fi
done
[ "$missing" -eq 1 ] || pass "the core templates exist"

# Added in PR 7: the remaining roles and the duty files.
PR7="roles/editor.md roles/analyst.md roles/designer.md roles/researcher.md roles/custom.md
RUNBOOK.md PROPOSALS.md research-START-HERE.md research-dossier.md"

missing=0
for f in $PR7; do
  if [ ! -f "$tdir/$f" ]; then
    fail "templates/$f is missing"
    missing=1
  fi
done
[ "$missing" -eq 1 ] || pass "the PR 7 role and duty templates exist"

# Every role file has the shared skeleton (plan section 7.2): the same ten headings in the same
# order, and the two short lists word for word. A line flag in front of a heading is ignored.
# The Address line (line 2) ends with the role's Type: every doer says "Type: doer" (a custom role
# is always a doer).
HEADINGS="Your job|You never|You usually write to|Decide yourself|Stop and raise|Every session, first|First session (once)|How you work|How you report|When your context gets long"
# A rendered Reviewer helper (no standing Reviewer chat) has no session sections.
HEADINGS_HELPER="Your job|You never|You usually write to|Decide yourself|Stop and raise|How you work|How you report"
DECIDE='naming · implementation details · debugging · reversible how-to choices'
STOP='a conflict with a recorded decision · a new dependency or cost · unclear scope · anything irreversible or visible to users'

# check_role LABEL FILE KIND TYPE: KIND is "template" (line flags are stripped first) or "rendered"
# (read as is, and no "{{" may be left). Prints a FAIL line per problem; returns 1 if there was one.
check_role() {
  label=$1 file=$2 kind=$3 want_type=$4
  rc=0
  if [ "$kind" = template ]; then
    sed 's/^{{IF_[A-Z0-9_]*}}//' "$file" > "$work/role"
  else
    cp "$file" "$work/role"
    if grep -q '{{' "$work/role"; then
      fail "$label: a \"{{\" is left in a rendered file"
      rc=1
    fi
  fi
  want=$HEADINGS
  if [ "$kind" = rendered ] && grep -q '^No standing chat:' "$work/role"; then want=$HEADINGS_HELPER; fi
  got=$(awk -v want="$want" '
    BEGIN { n = split(want, w, "|"); for (i = 1; i <= n; i++) ok[w[i]] = 1 }
    /^## / { h = substr($0, 4); if (h in ok) { printf "%s%s", (c ? "|" : ""), h; c++ } }' "$work/role")
  if [ "$got" != "$want" ]; then
    fail "$label: headings are not the shared skeleton (found: $got)"
    rc=1
  fi
  d=$(awk '/^## Decide yourself$/ { getline; print; exit }' "$work/role")
  s=$(awk '/^## Stop and raise$/ { getline; print; exit }' "$work/role")
  if [ "$d" != "$DECIDE" ]; then fail "$label: the \"Decide yourself\" list is not the plan's"; rc=1; fi
  if [ "$s" != "$STOP" ]; then fail "$label: the \"Stop and raise\" list is not the plan's"; rc=1; fi
  line2=$(sed -n 2p "$work/role")
  if [ "${line2%"$want_type"}" = "$line2" ]; then
    fail "$label: the Address line must end with \"$want_type\""
    rc=1
  fi
  return $rc
}

skeleton=0
for p in "$tdir"/roles/*.md; do
  f=roles/${p##*/}
  case "$f" in
    roles/chief.md) t='Type: notebook writer' ;;
    roles/reviewer.md) t='Type: Reviewer' ;;
    *) t='Type: doer' ;;
  esac
  check_role "templates/$f" "$p" template "$t" || skeleton=1
done
[ "$skeleton" -eq 1 ] || pass "every role template has the shared skeleton, and the doers say Type: doer"

# The same check on every role file in every hand-rendered example. The role is told by its file
# name (chief, reviewer, each with an optional -<handle>); anything else is a doer.
rskeleton=0
nroles=0
for p in "$root"/tests/rendered/*/team/roles/*.md; do
  [ -f "$p" ] || continue
  nroles=$((nroles + 1))
  base=${p##*/}
  base=${base%.md}
  f=${p#"$root"/}
  case "$base" in
    chief|chief-*) t='Type: notebook writer' ;;
    reviewer|reviewer-*) t='Type: Reviewer' ;;
    *) t='Type: doer' ;;
  esac
  check_role "$f" "$p" rendered "$t" || rskeleton=1
done
if [ "$nroles" -eq 0 ]; then
  fail "no role files found under tests/rendered/*/team/roles/"
elif [ "$rskeleton" -eq 0 ]; then
  pass "every rendered role file ($nroles) has the shared skeleton, no \"{{\", and the right Type"
fi

# The lemonade example is a Team with a Researcher and a Designer, a filled-in runbook and a
# proposal. Losing any of them would leave the example showing nothing.
lem="$root/tests/rendered/lemonade/team"
lemfail=0
for f in roles/researcher.md roles/designer.md RUNBOOK.md PROPOSALS.md research/START-HERE.md; do
  if [ ! -f "$lem/$f" ]; then
    fail "tests/rendered/lemonade/team/$f is missing (the example shows a Researcher, a Designer, a runbook, proposals and research)"
    lemfail=1
  fi
done
if [ -f "$lem/RUNBOOK.md" ]; then
  status=$(grep -m1 '^\*Status:' "$lem/RUNBOOK.md" || true)
  if [ -z "$status" ]; then
    fail "tests/rendered/lemonade/team/RUNBOOK.md has no \"*Status:\" line"
    lemfail=1
  elif printf '%s\n' "$status" | grep -qi 'skeleton'; then
    fail "tests/rendered/lemonade/team/RUNBOOK.md still says skeleton (the example's runbook is filled in)"
    lemfail=1
  fi
fi
if [ -f "$lem/PROPOSALS.md" ]; then
  if ! awk 'index($0, "<!-- new entries go directly below this line -->") { on = 1; next }
            on && /^## / { n++ }
            END { exit (n ? 0 : 1) }' "$lem/PROPOSALS.md"; then
    fail "tests/rendered/lemonade/team/PROPOSALS.md has no entry below its marker line"
    lemfail=1
  fi
fi
for f in LESSONS.md GLOSSARY.md; do
  if [ ! -f "$lem/$f" ]; then
    fail "tests/rendered/lemonade/team/$f is missing"
    lemfail=1
  fi
done
nl=$(grep -c '^| L[0-9]' "$lem/LESSONS.md" 2>/dev/null || true)
if [ "$nl" != 1 ]; then fail "tests/rendered/lemonade/team/LESSONS.md should hold exactly one lesson (found ${nl:-0})"; lemfail=1; fi
# Each lesson is logged under the headline "Lesson L<n>" (roles/chief.md, Habits).
for lid in $(grep -oE '^\| L[0-9]+ ' "$lem/LESSONS.md" 2>/dev/null | grep -oE 'L[0-9]+'); do
  grep -q "^## .* · Lesson $lid\$" "$lem/LOG.md" || { fail "tests/rendered/lemonade/team/LOG.md has no \"Lesson $lid\" entry"; lemfail=1; }
done
# The glossary is seeded after the setup PR merges and grows with every new name: each D<n> in
# DECISIONS.md and TASKS.md, each T<n> and each track name in TASKS.md, must be a word in the first
# cell of some glossary row.
awk '/^\| Name or ID \|/ { on = 1; getline; next } on && /^\|/ { n = split($0, c, "|"); print c[2] }' "$lem/GLOSSARY.md" 2>/dev/null > "$work/gloss-names" || true
{
  grep -oE '^\| D[0-9]+ \|' "$lem/DECISIONS.md" | grep -oE 'D[0-9]+'
  grep -oE '^- D[0-9]+ ' "$lem/TASKS.md" | grep -oE 'D[0-9]+'
  grep -oE '^- \[.\] T[0-9]+ ' "$lem/TASKS.md" | grep -oE 'T[0-9]+'
  grep -oE '\[track: [^]<]+\]' "$lem/TASKS.md" | sed 's/^\[track: //; s/\]$//'
} 2>/dev/null | sort -u > "$work/gloss-want"
# The chats share one row: every name in ROSTER's first table (the human aside) is in it.
awk '/^## / { exit } /^\| [A-Z]/ { n = split($0, c, "|"); a = c[3]; gsub(/^ +| +$/, "", a); nm = c[2]; gsub(/^ +| +$/, "", nm); if (a != "(none)" && a != "Address (exact title)") print nm }' "$lem/ROSTER.md" >> "$work/gloss-want"
ngw=$(awk 'END { print NR }' "$work/gloss-want")
if [ "$ngw" -lt 3 ]; then fail "tests/rendered/lemonade/team: found only $ngw D, T and track names to look up in GLOSSARY.md"; lemfail=1; fi
while IFS= read -r id; do
  [ -n "$id" ] || continue
  if ! awk -v id="$id" '{ n = split($0, w, ","); for (i = 1; i <= n; i++) { gsub(/^[ \t]+|[ \t]+$/, "", w[i]); if (w[i] == id) f = 1 } } END { exit (f ? 0 : 1) }' "$work/gloss-names"; then
    fail "tests/rendered/lemonade/team/GLOSSARY.md has no row for \"$id\" (used in DECISIONS.md, TASKS.md or ROSTER.md)"
    lemfail=1
  fi
done < "$work/gloss-want"
nb=$(ls "$lem/briefings" 2>/dev/null | grep -c '^D[0-9][0-9]*-.*\.md$' || true)
if [ "$nb" -lt 1 ]; then
  fail "tests/rendered/lemonade/team/briefings/ has no D<n>-<slug>.md briefing"
  lemfail=1
else
  for b in "$lem"/briefings/D*.md; do
    id=$(basename "$b" | sed 's/-.*//')
    for h in "## The problem" "## Options" "## Evidence" "## One worked example" "## Our leaning" "## The question"; do
      grep -q "^$h" "$b" || { fail "tests/rendered/lemonade/team/briefings/$(basename "$b") has no \"$h\" heading"; lemfail=1; }
    done
    grep -q "^- $id · .*(briefings/$(basename "$b"))" "$lem/TASKS.md" || { fail "TASKS \"Decisions you owe\" doesn't link briefings/$(basename "$b") from its $id line"; lemfail=1; }
  done
fi
[ "$lemfail" -eq 1 ] || pass "the lemonade example has its Researcher, Designer, filled-in runbook, research, a proposal, a briefing, a lesson and a seeded glossary"

# render FLAGS VARS TEMPLATE: print TEMPLATE filled in as PLACEHOLDERS.md "How to fill a template"
# says. FLAGS: the line flags that hold, space-separated. VARS: a file of NAME=value lines. A line
# that is only a {{BLOCK}} whose value is empty is dropped.
render() {
  awk -v flags=" $1 " '
    NR == FNR { i = index($0, "="); v[substr($0, 1, i - 1)] = substr($0, i + 1); next }
    {
      line = $0
      if (match(line, /^\{\{IF_[A-Z0-9_]+\}\}/)) {
        if (index(flags, " " substr(line, 3, RLENGTH - 4) " ") == 0) next
        line = substr(line, RLENGTH + 1)
      }
      if (match(line, /^\{\{[A-Z0-9_]+\}\}$/) && (substr(line, 3, RLENGTH - 4) in v) && v[substr(line, 3, RLENGTH - 4)] == "") next
      out = ""
      while ((i = index(line, "{{")) > 0) {
        rest = substr(line, i)
        if (match(rest, /^\{\{[A-Z0-9_]+\}\}/)) {
          n = substr(rest, 3, RLENGTH - 4)
          out = out substr(line, 1, i - 1) ((n in v) ? v[n] : substr(rest, 1, RLENGTH))
          line = substr(rest, RLENGTH + 1)
        } else {
          out = out substr(line, 1, i + 1)
          line = substr(rest, 3)
        }
      }
      print out line
    }' "$2" "$3"
}

# The values and flags each example was rendered with.
ACME_FLAGS="IF_REVIEWER IF_IN_REPO IF_MONEY"
SMALL_FLAGS="IF_NO_REVIEWER IF_IN_REPO IF_NO_DUTIES"
LEMONADE_FLAGS="IF_REVIEWER IF_BESIDE_REPO IF_PUBLIC_OR_SHARED IF_SHARED IF_LIVE"
printf '%s\n' PROJECT=Acme HUMAN=Priya DATE=2026-10-12 STAMP=20261012-1435 SETUP_PR=1 VERSION=1.0.0 REPO=acme \
  DEFAULT_BRANCH=main NOTES_BRANCH=main REMOTE=priya-acme/acme WRITER=Cyrus REVIEWER=Vito \
  'PAID_SERVICE=the paid email service' ADOPTED_OWNER_ROWS= > "$work/vars-acme"
cp "$work/vars-acme" "$work/vars-acme-small"
printf '%s\n' PROJECT=Lemonade HUMAN=Priya DATE=2026-10-12 STAMP=20261012-1520 SETUP_PR=1 VERSION=1.0.0 REPO=lemonade \
  DEFAULT_BRANCH=master NOTES_BRANCH=main REMOTE=maple-st/lemonade WRITER=Cyrus REVIEWER=Vito \
  ADOPTED_OWNER_ROWS= > "$work/vars-lemonade"

# compare_render EXAMPLE FLAGS TEMPLATE [NAME TITLE MODEL]: the rendered file of that name in the
# example must equal the template filled in with the example's values (a role file also gets its
# NAME, TITLE, MODEL and HANDLE, the name in lowercase).
rendered_ok=1
nrendered=0
compare_render() {
  ex=$1 flags=$2 tpl=$3
  cp "$work/vars-$ex" "$work/vars"
  if [ "$#" -ge 6 ]; then
    handle=$(printf '%s' "$4" | tr 'A-Z' 'a-z')
    printf '%s\n' "NAME=$4" "TITLE=$5" "MODEL=$6" "HANDLE=$handle" >> "$work/vars"
  fi
  target="$root/tests/rendered/$ex/team/$tpl"
  nrendered=$((nrendered + 1))
  if [ ! -f "$target" ]; then
    fail "tests/rendered/$ex/team/$tpl is missing"
    rendered_ok=0
    return
  fi
  render "$flags" "$work/vars" "$tdir/$tpl" > "$work/rendered.out"
  if ! diff -u "$work/rendered.out" "$target" > "$work/rendered.diff"; then
    fail "tests/rendered/$ex/team/$tpl is not what templates/$tpl gives (re-render it; first lines of the diff follow)"
    sed -n '1,12p' "$work/rendered.diff" | cut -c1-200 | sed 's/^/      | /'
    rendered_ok=0
  fi
}
compare_render acme "$ACME_FLAGS" CHATS.md
compare_render acme "$ACME_FLAGS" roles/chief.md Cyrus "Cyrus · Acme Chief" Opus
compare_render acme "$ACME_FLAGS" roles/reviewer.md Vito "Vito · Acme Reviewer" Opus
compare_render acme "$ACME_FLAGS" roles/builder.md Bram "Bram · Acme Builder" Sonnet
compare_render acme "$ACME_FLAGS" LESSONS.md
compare_render acme "$ACME_FLAGS" GLOSSARY.md
compare_render acme "$ACME_FLAGS" TRIED-AND-DROPPED.md
compare_render acme-small "$SMALL_FLAGS" CHATS.md
compare_render acme-small "$SMALL_FLAGS" roles/chief.md Cyrus "Cyrus · Acme Chief" Opus
compare_render acme-small "$SMALL_FLAGS" roles/builder.md Bram "Bram · Acme Builder" Sonnet
compare_render acme-small "$SMALL_FLAGS" roles/reviewer.md helper "Reviewer helper · Acme" Opus
compare_render acme-small "$SMALL_FLAGS" LESSONS.md
compare_render acme-small "$SMALL_FLAGS" GLOSSARY.md
compare_render acme-small "$SMALL_FLAGS" TRIED-AND-DROPPED.md
compare_render lemonade "$LEMONADE_FLAGS" CHATS.md
compare_render lemonade "$LEMONADE_FLAGS" roles/chief.md Cyrus "Cyrus · Lemonade Chief" Opus
compare_render lemonade "$LEMONADE_FLAGS" roles/reviewer.md Vito "Vito · Lemonade Reviewer" Opus
compare_render lemonade "$LEMONADE_FLAGS" roles/researcher.md Rhea "Rhea · Lemonade Research" Opus
compare_render lemonade "$LEMONADE_FLAGS" roles/designer.md Dara "Dara · Lemonade Designer" Sonnet
compare_render lemonade "$LEMONADE_FLAGS" TRIED-AND-DROPPED.md
[ "$rendered_ok" -eq 0 ] || pass "the rendered CHATS.md, role files, LESSONS.md, GLOSSARY.md and TRIED-AND-DROPPED.md match their templates ($nrendered files, three examples)"

# Always a Chief of Staff (plan decisions 10 to 12). The old sizes and the Lead are gone for good: not in
# the skill, the examples, the fixtures, the scripts or CI, and neither are the old Lead names (Lena, Luca,
# Lior). Test scripts are left out: check-output-test.sh seeds a "... Lead" title on purpose.
old=$(grep -rnw -E 'Lead|Solo|Pair|IF_LEAD|IF_CHIEF|WRITER_LABEL|Lena|Luca|Lior' "$root/skills" "$root/tests/rendered" \
  "$root/tests/fixtures" "$root/scripts" "$root/.github" || true)
if [ -n "$old" ]; then
  fail "a Lead, Solo or Pair (or an old Lead name) is still named (every team has a Chief of Staff now):"
  printf '%s\n' "$old" | sed "s|^$root/||" | head -10 | sed 's/^/      | /'
elif [ -e "$tdir/roles/lead.md" ]; then
  fail "templates/roles/lead.md still exists"
else
  pass "no Lead, Solo, Pair or old Lead name in the skill, examples, fixtures, scripts or CI, and no roles/lead.md"
fi
d1012=0
want_line() { # want_line FILE TEXT WHAT
  if ! grep -qF -- "$2" "$tdir/$1"; then fail "templates/$1: $3"; d1012=1; fi
}
want_line roles/chief.md '## Think it through with {{HUMAN}}' 'no thinking-partner section'
want_line roles/chief.md '**Ideate.**' 'the thinking-partner section has no Ideate line'
want_line roles/chief.md '**Push back.**' 'the thinking-partner section has no Push back line'
want_line roles/chief.md 'team/briefings/D<n>-<slug>.md' 'no decision briefing'
want_line roles/chief.md 'Team update: re-read LESSONS.md (L<n>)' 'no lessons habit with the team update'
want_line roles/chief.md 'team/LOG-archive.md' 'no LOG archive habit'
want_line roles/chief.md 'never append' 'README "Where this stands" is not rewritten'
want_line CHATS.md 'LESSONS.md (every line)' 'rule 1 does not list LESSONS.md'
want_line CHATS.md 'GLOSSARY.md once it holds more than 5 rows' 'rule 1 does not list GLOSSARY.md'
want_line CHATS.md 'Talk to each other directly.' 'How chats talk: chats may not message each other'
want_line CHATS.md 'Only {{WRITER}} talks to {{HUMAN}} about decisions.' 'How chats talk: no "only the Chief talks to the human about decisions"'
want_line review-checklist.md 'repeating a lesson recorded in LESSONS.md' 'a repeated lesson is not HIGH'
want_line roles/reviewer.md 'team/LESSONS.md' 'the reviewer helper does not read LESSONS.md'
want_line roles/chief.md 'gh pr view <n> --json headRefOid,mergeCommit' 'the after-merge check does not compare the PR head (a merge commit always has a new sha)'
want_line roles/chief.md 'Lesson (to be L<n>)' 'no route for a lesson found while the setup PR is open'
want_line roles/chief.md 'GLOSSARY.md seeded with every D, T and track name' 'the glossary is not seeded after the setup PR merges'
want_line CHATS.md 'Please take that to {{WRITER}}' 'How chats talk: nothing for work the human gives a chat directly'
want_line review-checklist.md 'A first occurrence of a listed slip is MED' 'the checklist does not say how a first slip is judged'
want_line LOG.md 'Lesson L<n>' 'no LOG headline word for a lesson'
[ "$d1012" -eq 1 ] || pass "the Chief is a thinking partner with briefings, lessons, glossary and a LOG archive; chats talk to each other; a repeated lesson is HIGH"

# Template files: everything under templates/ except PLACEHOLDERS.md.
(cd "$tdir" && find . -type f ! -name PLACEHOLDERS.md | sed 's|^\./||' | sort) > "$work/files"

: > "$work/used"
malformed=0
midline=0
while IFS= read -r f; do
  p="$tdir/$f"
  awk -v f="$f" '
    {
      line = $0
      while ((i = index(line, "{{")) > 0) {
        rest = substr(line, i)
        if (match(rest, /^\{\{[A-Z0-9_]+\}\}/)) {
          name = substr(rest, 3, RLENGTH - 4)
          print "USED\t" name
          if (name ~ /^IF_/ && !(i == 1 && line == $0)) printf "MID\t%s:%d: %s is not at the start of the line\n", f, NR, name
          line = substr(rest, RLENGTH + 1)
        } else {
          printf "BAD\t%s:%d: a \"{{\" that does not start a {{NAME}}\n", f, NR
          line = substr(rest, 3)
        }
      }
    }' "$p" > "$work/scan"
  awk -F '\t' '$1 == "USED" { print $2 }' "$work/scan" >> "$work/used"
  while IFS="$(printf '\t')" read -r kind msg; do
    case "$kind" in
      BAD) fail "$msg"; malformed=1 ;;
      MID) fail "$msg"; midline=1 ;;
    esac
  done < "$work/scan"
done < "$work/files"
[ "$malformed" -eq 1 ] || pass "every placeholder is a well-formed {{NAME}}"
[ "$midline" -eq 1 ] || pass "every line flag starts its line"

sort -u "$work/used" > "$work/used.u"
grep -o '{{[A-Z0-9_]*}}' "$doc" | sed 's/^{{//; s/}}$//' | sort -u > "$work/doc.u"

undocumented=$(comm -23 "$work/used.u" "$work/doc.u")
unused=$(comm -13 "$work/used.u" "$work/doc.u")
if [ -n "$undocumented" ]; then
  for n in $undocumented; do fail "{{$n}} is used in a template but not listed in PLACEHOLDERS.md"; done
else
  pass "every placeholder used is listed in PLACEHOLDERS.md ($(awk 'END { print NR }' "$work/used.u") names)"
fi
if [ -n "$unused" ]; then
  for n in $unused; do fail "{{$n}} is listed in PLACEHOLDERS.md but no template uses it"; done
else
  pass "every placeholder listed in PLACEHOLDERS.md is used"
fi

if [ "$fails" -gt 0 ]; then
  echo "templates-test: $fails check(s) failed"
  exit 1
fi
echo "templates-test: all checks passed"
