#!/usr/bin/env bash
# check-output.sh: check a folder that /assemble filled in (a rendered example or fixture, or a
# notebook folder after setup).
#
# Checks:
#   1. Placeholders: no "{{" is left in the files setup writes.
#   2. Owners: every notebook file has exactly one owner. That means exactly one row in the
#      "Who updates what" table of team/CHATS.md, and that row names the notebook writer: the one
#      chat in the team table of team/ROSTER.md whose title ends in "Chief" (every team has
#      exactly one Chief of Staff, and it is always the notebook writer).
#      Notebook files are every file under team/ except the work files (CHATS.md, roles/,
#      PLAN.md, research/, RUNBOOK.md, assemble.json, pr-template.md) and the-ask.md, so they
#      include LESSONS.md, GLOSSARY.md, LOG-archive.md and briefings/ when present, plus every
#      adopted path listed in team/assemble.json, by job: an adopted "ask" follows the same rule as
#      the-ask.md (one row, owner starts with "nobody"), an adopted "research" path is work landed
#      by PR and is skipped like team/research/, any other adopted path is a notebook file.
#      the-ask.md, when present, needs one row whose owner starts with "nobody". Adopted paths must
#      be relative and stay inside the repo.
#   3. Marker: the CLAUDE.md block appears exactly once across CLAUDE.md and .claude/CLAUDE.md
#      (a symlinked CLAUDE.md is skipped: setup never writes through it), begin before end, with
#      the import line between them: "@team/CHATS.md" in CLAUDE.md, "@../team/CHATS.md" in
#      .claude/CLAUDE.md (an import resolves from the file that holds it), with "_team" in place
#      of "team" when the manifest is in _team/.
#   4. Paths: no home-folder path (macOS, Linux or Windows style) in the files setup writes.
#   5. Precious list: when the notes folder holds a RUNBOOK.md (the work touches something live),
#      the "precious" list in its assemble.json names it. Anything touching the runbook is full
#      tier, and assemble.json is the one home of the precious list.
#   6. A doer: the team table of team/ROSTER.md has at least one chat whose title ends in neither
#      "Chief" nor "Reviewer". The Chief never does the heavy work itself, so the smallest team is
#      the Chief plus one doer.
#   7. The files every chat reads at session start (CHATS.md rule 1) exist: README.md, LESSONS.md,
#      ROSTER.md, GLOSSARY.md, LOG.md, DECISIONS.md and TASKS.md (for an adopted log, decisions or
#      tasks job, its adopted path instead), roles/chief.md and roles/reviewer.md (written for every
#      roster), and each ROSTER chat's role file: roles/<role>.md or roles/<role>-<handle>.md, the
#      role from the title's last word (Research -> researcher, otherwise in lowercase) and the
#      handle the name in lowercase. A missing LESSONS.md would silently turn the lessons list off.
#
# The files setup writes: everything under team/ (or _team/, when the manifest is there), the
# marked block of CLAUDE.md or .claude/CLAUDE.md (the lines outside it are the user's own and are
# not checked) and .github/pull_request_template.md. If DIR is the top of a git work tree, only
# files git tracks there are read; otherwise every file under DIR.
#
# Usage: scripts/check-output.sh DIR      (DIR holds CLAUDE.md and team/)
# Exit:  0 = every check passed, 1 = at least one check failed, 2 = could not run.
# Portable bash: runs on macOS bash 3.2 and on Linux. No GNU-only flags.

set -eu
LC_ALL=C
export LC_ALL
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

cant() { echo "check-output: $*" >&2; exit 2; }
fails=0
fail() { printf 'FAIL  %s\n' "$*"; fails=$((fails + 1)); }
pass() { printf 'ok    %s\n' "$*"; }

[ "$#" -eq 1 ] || cant "usage: check-output.sh DIR"
[ -d "$1" ] || cant "$1 is not a folder"
root=$(CDPATH= cd -- "$1" && pwd)
cd "$root"

work=$(mktemp -d "${TMPDIR:-/tmp}/check-output.XXXXXX") || cant "could not make a temporary folder"
trap 'rm -rf "$work"' EXIT
tab=$(printf '\t')

# Every file under DIR, relative, one per line, byte-sorted.
if top=$(git rev-parse --show-toplevel 2>/dev/null) && [ "$(CDPATH= cd -- "$top" && pwd -P)" = "$(pwd -P)" ]; then
  # -z: no quoting of non-ASCII names (a quoted name would match no file and be skipped).
  git ls-files -z > "$work/all.z" || cant "git ls-files failed in $root"
  tr '\0' '\n' < "$work/all.z" > "$work/all" || cant "could not read the file list"
else
  find . -name .git -prune -o \( -type f -o -type l \) -print | sed 's|^\./||' | sort > "$work/all" \
    || cant "could not list $root"
fi

echo "== check-output: $root"

# ---------------------------------------------------------------------------------------------
# Which notes folder: team/ or _team/, whichever holds assemble.json.
folder=""
for f in team _team; do
  if grep -qxF -- "$f/assemble.json" "$work/all"; then
    if [ -n "$folder" ]; then
      fail "both team/ and _team/ hold an assemble.json; there must be one notes folder"
      folder=""
      break
    fi
    folder=$f
  fi
done
if [ -n "$folder" ]; then
  pass "notes folder is $folder/ (it holds assemble.json)"
else
  [ "$fails" -gt 0 ] || fail "no team/assemble.json or _team/assemble.json, so this is not a filled folder"
fi

# The files setup writes, minus the CLAUDE.md block (checked separately, block lines only).
: > "$work/written"
if [ -n "$folder" ]; then
  grep -E "^$folder/" "$work/all" >> "$work/written" || true
fi
if grep -qxF -- ".github/pull_request_template.md" "$work/all"; then
  echo ".github/pull_request_template.md" >> "$work/written"
fi
claude_files=""
for f in CLAUDE.md .claude/CLAUDE.md; do
  if grep -qxF -- "$f" "$work/all" && [ -f "$f" ] && [ ! -L "$f" ]; then
    claude_files="$claude_files $f"
  fi
done

# Prints "<file>:<line>: <what>" for each placeholder or home-folder path.
# BLOCK=1: only the lines from the begin marker to the end marker, markers included.
# String pieces are split ("/" "home/") so this file never matches the leak scan's patterns.
SCAN_AWK='
BEGIN { home = "/" "home/"; inblock = 0 }
{
  line = $0
  sub(/\r$/, "", line)
  if (ENVIRON["BLOCK"] == "1") {
    if (index(line, "<!-- assemble:begin")) inblock = 1
    if (!inblock) next
  }
  if (index(line, "{{")) {
    what = "{{"
    if (match(line, /\{\{[^}]*\}\}/)) what = substr(line, RSTART, RLENGTH)
    printf "%s:%d: placeholder left: %s\n", FILENAME, FNR, what
  }
  if (line ~ /\/[Uu][Ss][Ee][Rr][Ss]\//) printf "%s:%d: home-folder path (macOS style)\n", FILENAME, FNR
  if (index(line, home)) printf "%s:%d: home-folder path (Linux style)\n", FILENAME, FNR
  if (line ~ /[A-Za-z]:\\+[Uu][Ss][Ee][Rr][Ss]/) printf "%s:%d: home-folder path (Windows style)\n", FILENAME, FNR
  if (ENVIRON["BLOCK"] == "1" && index(line, "<!-- assemble:end -->")) inblock = 0
}
'

: > "$work/hits"
nscanned=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if [ -f "$f" ] && [ ! -L "$f" ]; then
    BLOCK=0 awk "$SCAN_AWK" "$f" >> "$work/hits" || cant "the scan failed on $f"
    nscanned=$((nscanned + 1))
  fi
done < "$work/written"
for f in $claude_files; do
  BLOCK=1 awk "$SCAN_AWK" "$f" >> "$work/hits" || cant "the scan failed on $f"
  nscanned=$((nscanned + 1))
done

# Check 1: placeholders.
if grep -q ': placeholder left: ' "$work/hits"; then
  while IFS= read -r h; do fail "$h"; done <<EOF
$(grep ': placeholder left: ' "$work/hits")
EOF
else
  pass "no {{ placeholders left ($nscanned files)"
fi

# Check 4: home-folder paths.
if grep -q ': home-folder path ' "$work/hits"; then
  while IFS= read -r h; do fail "$h"; done <<EOF
$(grep ': home-folder path ' "$work/hits")
EOF
else
  pass "no home-folder paths ($nscanned files)"
fi

# ---------------------------------------------------------------------------------------------
# Check 3: the CLAUDE.md marker block, exactly once.
nbegin=0
nend=0
block_ok=1
for f in $claude_files; do
  b=$(grep -c '<!-- assemble:begin' "$f" || true)
  e=$(grep -c '<!-- assemble:end -->' "$f" || true)
  nbegin=$((nbegin + b))
  nend=$((nend + e))
  if [ "$b" -eq 1 ] && [ "$e" -eq 1 ]; then
    case "$f" in
      .claude/*) imp="@../${folder:-team}/CHATS.md" ;;
      *) imp="@${folder:-team}/CHATS.md" ;;
    esac
    res=$(awk -v imp="$imp" '
      { sub(/\r$/, "") }
      index($0, "<!-- assemble:begin") { b = NR }
      index($0, "<!-- assemble:end -->") { e = NR }
      b && !e && $0 == imp { found = 1 }
      END {
        if (!(b < e)) print "order"
        else if (!found) print "import"
        else print "ok"
      }' "$f")
    case "$res" in
      order) fail "$f: the assemble:end marker comes before assemble:begin"; block_ok=0 ;;
      import) fail "$f: the marked block has no line \"$imp\""; block_ok=0 ;;
    esac
  elif [ "$b" -gt 0 ] || [ "$e" -gt 0 ]; then
    if [ "$b" -ne "$e" ]; then
      fail "$f: $b assemble:begin marker(s) but $e assemble:end marker(s)"
      block_ok=0
    fi
  fi
done
if [ -z "$claude_files" ]; then
  fail "no CLAUDE.md or .claude/CLAUDE.md (a symlinked CLAUDE.md doesn't count)"
elif [ "$nbegin" -ne 1 ] || [ "$nend" -ne 1 ]; then
  fail "the CLAUDE.md block must appear exactly once; found $nbegin begin and $nend end marker(s) in:$claude_files"
elif [ "$block_ok" -eq 1 ]; then
  pass "the CLAUDE.md block appears exactly once and imports $folder/CHATS.md"
fi

# ---------------------------------------------------------------------------------------------
# Check 2: one owner per notebook file.
if [ -n "$folder" ]; then
  roster="$folder/ROSTER.md"
  chats="$folder/CHATS.md"
  manifest="$folder/assemble.json"
  owners_ready=1

  # The notebook writer: rows of the first table in ROSTER.md (before the first "## " heading)
  # whose title cell ends in Chief.
  writer=""
  if [ -f "$roster" ]; then
    awk '
      /^## / { exit }
      /^\|/ {
        n = split($0, c, "|")
        name = c[2]; addr = c[3]
        gsub(/^[ \t]+|[ \t]+$/, "", name); gsub(/[`"]/, "", addr); gsub(/^[ \t]+|[ \t]+$/, "", addr)
        if (name == "Name" || name ~ /^:?-+:?$/) next
        if (addr ~ /(^|[ ])Chief$/) print name
      }' "$roster" > "$work/writers"
    ndoers=$(awk '
      /^## / { exit }
      /^\|/ {
        n = split($0, c, "|")
        name = c[2]; addr = c[3]
        gsub(/^[ \t]+|[ \t]+$/, "", name); gsub(/[`"]/, "", addr); gsub(/^[ \t]+|[ \t]+$/, "", addr)
        if (name == "Name" || name ~ /^:?-+:?$/ || addr == "" || addr == "(none)") next
        if (addr !~ /(^|[ ])(Chief|Reviewer)$/) d++
      }
      END { print d + 0 }' "$roster")
    if [ "$ndoers" -ge 1 ]; then
      pass "$roster has at least one doer ($ndoers)"
    else
      fail "$roster: the team table has no doer (a chat titled neither Chief nor Reviewer); the smallest team is the Chief plus one doer"
    fi
    nw=$(awk 'END { print NR }' "$work/writers")
    if [ "$nw" -eq 1 ]; then
      writer=$(cat "$work/writers")
      pass "one notebook writer in $roster: $writer"
    else
      fail "$roster: the team table must have exactly one chat titled \"<Name> · <Project> Chief\" (the Chief of Staff, the notebook writer); found $nw"
      owners_ready=0
    fi
  else
    fail "$roster is missing"
    owners_ready=0
  fi

  # The "Who updates what" table: one "path<TAB>owner" line per path named in a row.
  if [ -f "$chats" ]; then
    awk -v OFS="\t" '
      /^## / { insec = ($0 ~ /^## Who updates what[ \t]*$/); next }
      insec && /^\|/ {
        n = split($0, c, "|")
        files = c[2]; owner = c[3]
        gsub(/^[ \t]+|[ \t]+$/, "", owner)
        gsub(/`/, "", files)
        if (files ~ /^[ \t]*File[ \t]*$/ || files ~ /^[ \t]*:?-+:?[ \t]*$/) next
        m = split(files, p, ",")
        for (i = 1; i <= m; i++) {
          gsub(/^[ \t]+|[ \t]+$/, "", p[i])
          if (p[i] ~ /^[A-Za-z0-9_.\/*-]+$/ && p[i] ~ /[.\/]/) print p[i], owner
        }
      }' "$chats" > "$work/rows"
    if [ -s "$work/rows" ]; then
      pass "$chats has a \"Who updates what\" table"
    else
      fail "$chats: no \"## Who updates what\" table with file rows"
      owners_ready=0
    fi
  else
    fail "$chats is missing"
    owners_ready=0
  fi

  # Adopted paths from the manifest.
  : > "$work/adopted"
  : > "$work/adopted_ask"
  : > "$work/adopted_jobs"
  if command -v python3 >/dev/null 2>&1; then
    if ! python3 -I -c 'import json, sys; json.load(open(sys.argv[1]))' "$manifest" 2>/dev/null; then
      fail "$manifest is not valid JSON"
    fi
  fi
  adopted_out=$(awk '
    { buf = buf $0 "\n" }
    END {
      p = index(buf, "\"adopted\"")
      if (p == 0) { print "NOKEY"; exit }
      rest = substr(buf, p + 9)
      q = index(rest, "{")
      if (q == 0 || substr(rest, 1, q - 1) !~ /^[ \t\n]*:[ \t\n]*$/) { print "BAD"; exit }
      rest = substr(rest, q + 1)
      e = index(rest, "}")
      if (e == 0) { print "BAD"; exit }
      obj = substr(rest, 1, e - 1)
      while (match(obj, /"[^"]*"[ \t\n]*:[ \t\n]*"[^"]*"/)) {
        pair = substr(obj, RSTART, RLENGTH)
        obj = substr(obj, RSTART + RLENGTH)
        key = pair
        sub(/^"/, "", key)
        sub(/".*$/, "", key)
        if (key == "") key = "-"
        sub(/^"[^"]*"[ \t\n]*:[ \t\n]*"/, "", pair)
        sub(/"$/, "", pair)
        print "PATH\t" key "\t" pair
      }
    }' "$manifest")
  case "$adopted_out" in
    NOKEY) fail "$manifest has no \"adopted\" key (use {} when nothing is adopted)" ;;
    BAD) fail "$manifest: \"adopted\" must be an object of job -> path" ;;
    *)
      while IFS="$tab" read -r kind key path; do
        [ "$kind" = PATH ] || continue
        case "/$path/" in
          //|/\/*|*/../*) fail "$manifest: adopted path \"$path\" must be relative and inside the repo" ;;
          *)
            printf '%s\t%s\n' "$key" "$path" >> "$work/adopted_jobs"
            case "$key" in
              research) ;;
              ask) printf '%s\n' "$path" >> "$work/adopted_ask" ;;
              *) printf '%s\n' "$path" >> "$work/adopted" ;;
            esac
            ;;
        esac
      done <<EOF
$adopted_out
EOF
      ;;
  esac

  if [ "$owners_ready" -eq 1 ]; then
    # Notebook files: every file under the notes folder except work files and the-ask.md.
    : > "$work/notebook"
    : > "$work/frozen"
    grep -E "^$folder/" "$work/all" | while IFS= read -r f; do
      sub=${f#"$folder"/}
      case "$sub" in
        CHATS.md|PLAN.md|RUNBOOK.md|assemble.json|pr-template.md|roles/*|research/*) ;;
        the-ask.md) printf '%s\n' "$f" >> "$work/frozen" ;;
        *) printf '%s\n' "$f" >> "$work/notebook" ;;
      esac
    done
    cat "$work/adopted" >> "$work/notebook"
    cat "$work/adopted_ask" >> "$work/frozen"

    # For one file, prints "<number of matching rows><TAB><owners, joined by ' / '>".
    match_rows() {
      awk -F "\t" -v f="$1" '
        {
          p = $1; hit = 0
          if (p == f) hit = 1
          else if (p ~ /\/\*\*$/) { pre = substr(p, 1, length(p) - 2); hit = (index(f, pre) == 1) }
          else if (p ~ /\/$/) hit = (index(f, p) == 1)
          if (hit) { n++; owners = (owners == "") ? $2 : owners " / " $2 }
        }
        END { printf "%d\t%s\n", n, owners }' "$work/rows"
    }

    bad_owner=0
    nnotebook=0
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      nnotebook=$((nnotebook + 1))
      res=$(match_rows "$f")
      n=${res%%"$tab"*}
      who=${res#*"$tab"}
      if [ "$n" -eq 0 ]; then
        fail "$f: notebook file with no owner row in $chats \"Who updates what\""
        bad_owner=1
      elif [ "$n" -gt 1 ]; then
        fail "$f: $n owner rows in $chats \"Who updates what\" ($who); it must have exactly one"
        bad_owner=1
      elif [ "$who" != "$writer" ]; then
        fail "$f: owner is \"$who\"; notebook files are owned by the notebook writer, $writer"
        bad_owner=1
      fi
    done < "$work/notebook"
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      res=$(match_rows "$f")
      n=${res%%"$tab"*}
      who=${res#*"$tab"}
      if [ "$n" -ne 1 ]; then
        fail "$f: needs exactly one row in $chats \"Who updates what\" (found $n)"
        bad_owner=1
      else
        case "$who" in
          [Nn]obody*) ;;
          *) fail "$f: owner is \"$who\"; nobody updates the-ask.md after setup"; bad_owner=1 ;;
        esac
      fi
    done < "$work/frozen"
    if [ "$bad_owner" -eq 0 ]; then
      pass "every notebook file has exactly one owner, $writer ($nnotebook files and adopted paths)"
    fi
  fi
fi

# ---------------------------------------------------------------------------------------------
# Check 7: the files CHATS.md rule 1 reads exist (each chat reads them at every session start).
if [ -n "$folder" ]; then
  : > "$work/missing"
  for f in README.md LESSONS.md ROSTER.md GLOSSARY.md roles/chief.md roles/reviewer.md; do
    grep -qxF -- "$folder/$f" "$work/all" || printf '%s\n' "$folder/$f" >> "$work/missing"
  done
  for pair in log:LOG.md decisions:DECISIONS.md tasks:TASKS.md; do
    job=${pair%%:*}
    f=${pair#*:}
    p=$(awk -F "$tab" -v j="$job" '$1 == j { print $2; exit }' "$work/adopted_jobs")
    if [ -z "$p" ]; then
      grep -qxF -- "$folder/$f" "$work/all" || printf '%s\n' "$folder/$f" >> "$work/missing"
    else
      case "$p" in
        */) awk -v p="$p" 'index($0, p) == 1 { f = 1 } END { exit (f ? 0 : 1) }' "$work/all" || printf '%s (adopted %s)\n' "$p" "$job" >> "$work/missing" ;;
        *) grep -qxF -- "$p" "$work/all" || printf '%s (adopted %s)\n' "$p" "$job" >> "$work/missing" ;;
      esac
    fi
  done
  if [ -f "$folder/ROSTER.md" ]; then
    awk '
      /^## / { exit }
      /^\|/ {
        n = split($0, c, "|")
        name = c[2]; addr = c[3]
        gsub(/^[ \t]+|[ \t]+$/, "", name); gsub(/[`"]/, "", addr); gsub(/^[ \t]+|[ \t]+$/, "", addr)
        if (name == "Name" || name ~ /^:?-+:?$/ || addr == "" || addr == "(none)") next
        k = split(addr, w, " ")
        print name "\t" w[k]
      }' "$folder/ROSTER.md" > "$work/chats"
    while IFS="$tab" read -r name label; do
      [ -n "$name" ] || continue
      role=$(printf '%s' "$label" | tr 'A-Z' 'a-z')
      [ "$role" != research ] || role=researcher
      handle=$(printf '%s' "$name" | tr 'A-Z' 'a-z')
      if ! grep -qxF -- "$folder/roles/$role.md" "$work/all" && ! grep -qxF -- "$folder/roles/$role-$handle.md" "$work/all"; then
        printf '%s (role file for %s; or %s)\n' "$folder/roles/$role.md" "$name" "$folder/roles/$role-$handle.md" >> "$work/missing"
      fi
    done < "$work/chats"
  fi
  if [ -s "$work/missing" ]; then
    while IFS= read -r m; do fail "missing: $m (every chat reads it at session start, CHATS.md rule 1)"; done < "$work/missing"
  else
    pass "the files CHATS.md rule 1 reads exist, and every ROSTER chat has its role file"
  fi
fi

# ---------------------------------------------------------------------------------------------
# Check 5: the runbook is on the precious list.
if [ -n "$folder" ] && grep -qxF -- "$folder/RUNBOOK.md" "$work/all"; then
  # The "precious" array: from its key to the first closing bracket.
  precious=$(awk '/"precious"/ { on = 1 } on { print } on && /\]/ { exit }' "$folder/assemble.json" 2>/dev/null || true)
  if printf '%s\n' "$precious" | grep -qF -- "\"$folder/RUNBOOK.md\""; then
    pass "$folder/RUNBOOK.md is on the precious list in $folder/assemble.json"
  else
    fail "$folder/assemble.json: the \"precious\" list must include \"$folder/RUNBOOK.md\" (anything touching the runbook is full tier)"
  fi
fi

if [ "$fails" -gt 0 ]; then
  echo "check-output: $fails check(s) failed"
  exit 1
fi
echo "check-output: all checks passed"
