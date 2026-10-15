#!/usr/bin/env bash
# denylist-scan.sh: check every file of a checkout or folder against the maintainer's private
# denylist: file contents and file paths.
#
# Where the denylist comes from (first match wins):
#   1. the file named in $ASSEMBLE_DENYLIST_FILE (set but unreadable = failure);
#   2. the text in $ASSEMBLE_DENYLIST (CI reads it from an encrypted Actions secret);
#   3. the file $HOME/.config/assemble/denylist.txt.
# None of these (or a list with no terms) FAILS CLOSED with exit 2: the maintainer must run the
# local denylist. The list itself is never committed, and this script never prints a term.
#
# Denylist format, one entry per line (spaces around an entry are ignored, and a run of spaces
# or tabs inside an entry counts as one space):
#   blank lines, and lines starting with #   ignored
#   word:Term                                Term as a whole word, case-sensitive
#   anything else                            a substring, case-insensitive (ASCII letters)
#
# How text is matched:
#   - each line, with runs of spaces and tabs squeezed to one space;
#   - entries with a space in them also against each paragraph: consecutive non-blank lines
#     joined with one space, after dropping leading comment or quote markers (#, >, //, *, -, ;),
#     so a phrase that wraps onto the next line is still found; reported at its first line;
#   - every path, as written and with - _ . / read as spaces (so "a-b-c.md" matches "a b c").
#     A path hit prints "tracked path #N: path matches the denylist" (N counts files from 1 in
#     listing order), never the path itself, and content hits in that file use the same label.
#     Find the path with: git ls-files | sed -n 'Np'
#
# Exceptions: denylist-allow.txt NEXT TO THIS SCRIPT (never the copy in the folder being
# scanned), lines of "path:line-text". A hit on a line of that file which contains that text is
# skipped. Each entry's text must be at least 12 characters and must appear on exactly one line
# of its file; an entry with shorter text, or text found on no line or on several lines, fails
# the scan. The scan prints how many entries it used.
#
# What is scanned:
#   no argument  the files git tracks in the checkout this script sits in (working-tree copies)
#   DIR          the checkout at DIR (if DIR is the top of a git work tree: the files git tracks
#                there), or else every file under DIR. Use this to scan someone else's branch
#                with a trusted copy of this script, never with the branch's own copy.
# A tracked symlink is scanned by its target text. A file with a NUL byte (binary, UTF-16, most
# images and PDFs) FAILS the scan unless its exact path is listed in binary-allow.txt next to
# this script (a reviewed list; empty today); a listed file has its printable text scanned.
# A run that scans no file at all fails.
#
# Output: "file:line" for each hit, nothing else about it.
# Usage:  scripts/denylist-scan.sh [DIR]
# Exit:   0 = no hits, 1 = at least one hit, an unscannable file or a bad exception entry,
#         2 = no denylist or could not run (fails closed).
# Portable bash: runs on macOS bash 3.2 and on Linux. No GNU-only flags.

set -eu
LC_ALL=C
export LC_ALL
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

closed() {
  echo "denylist: FAILING CLOSED: $*" >&2
  echo "denylist: the maintainer must run the local denylist (scripts/denylist-scan.sh with the private list in place)." >&2
  exit 2
}

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ "$#" -gt 1 ]; then
  closed "usage: denylist-scan.sh [DIR]"
elif [ "$#" -eq 1 ]; then
  [ -d "$1" ] || closed "$1 is not a folder"
  target=$(CDPATH= cd -- "$1" && pwd)
else
  target=$(CDPATH= cd -- "$script_dir/.." && pwd)
fi
cd "$target"
mode=folder
if top=$(git rev-parse --show-toplevel 2>/dev/null) && [ "$(CDPATH= cd -- "$top" && pwd -P)" = "$(pwd -P)" ]; then
  mode=git
elif [ "$#" -eq 0 ]; then
  closed "$target is not the top of a git work tree (pass a folder to scan one)"
fi

DENY_SOURCE=""
DENY_FILE=""
default_file=""
if [ -n "${HOME:-}" ]; then
  default_file="$HOME/.config/assemble/denylist.txt"
fi
if [ -n "${ASSEMBLE_DENYLIST_FILE:-}" ]; then
  DENY_FILE=$ASSEMBLE_DENYLIST_FILE
  if [ ! -f "$DENY_FILE" ] || [ ! -r "$DENY_FILE" ]; then
    closed "ASSEMBLE_DENYLIST_FILE is set, but that file can't be read"
  fi
  DENY_SOURCE=file
  where="the file named in ASSEMBLE_DENYLIST_FILE"
elif [ -n "${ASSEMBLE_DENYLIST:-}" ]; then
  DENY_SOURCE=env
  where="the ASSEMBLE_DENYLIST variable"
elif [ -n "$default_file" ] && [ -f "$default_file" ] && [ -r "$default_file" ]; then
  DENY_FILE=$default_file
  DENY_SOURCE=file
  where="the default file in your home folder (.config/assemble/denylist.txt)"
else
  closed "no denylist found (no ASSEMBLE_DENYLIST_FILE, ASSEMBLE_DENYLIST is empty, no default file)"
fi
export DENY_SOURCE DENY_FILE

work=$(mktemp -d "${TMPDIR:-/tmp}/denylist-scan.XXXXXX") || closed "could not make a temporary folder"
trap 'rm -rf "$work"' EXIT
STATS_FILE="$work/allow-stats"
: > "$STATS_FILE"
export STATS_FILE

ALLOW_FILE="$script_dir/denylist-allow.txt"
if [ ! -f "$ALLOW_FILE" ]; then
  ALLOW_FILE=""
fi
export ALLOW_FILE

: > "$work/binary-allow"
if [ -f "$script_dir/binary-allow.txt" ]; then
  awk '{ sub(/\r$/, "") } $0 != "" && substr($0, 1, 1) != "#"' "$script_dir/binary-allow.txt" > "$work/binary-allow"
fi

# Check the exception entries before anything else: "path:text", text at least 12 characters.
# Prints "<line number in the allow file> <path>" for each good entry, or "BAD <line> <why>".
if [ -n "$ALLOW_FILE" ]; then
  awk '
    { l = $0; sub(/\r$/, "", l) }
    l == "" || substr(l, 1, 1) == "#" { next }
    {
      p = index(l, ":")
      if (p < 2) { printf "BAD %d not a \"path:line-text\" entry\n", NR; next }
      t = substr(l, p + 1); sub(/^[ \t]+/, "", t); sub(/[ \t]+$/, "", t)
      if (length(t) < 12) { printf "BAD %d the line-text must be at least 12 characters\n", NR; next }
      printf "%d %s\n", NR, substr(l, 1, p - 1)
    }
  ' "$ALLOW_FILE" > "$work/allow-entries"
  if grep -q '^BAD ' "$work/allow-entries"; then
    sed -n 's/^BAD \([0-9]*\) \(.*\)$/denylist-allow.txt:\1: \2/p' "$work/allow-entries" >&2
    echo "denylist: fix denylist-allow.txt (next to this script) and run again." >&2
    exit 1
  fi
else
  : > "$work/allow-entries"
fi

# The awk program.
#   DENY_MODE=count  print how many word and substring terms the list has
#   DENY_MODE=path   print "hit" if SCAN_PATH matches the list
#   otherwise        scan standard input; print "<label>:<line>" per hit; append
#                    "<allow-file line> <lines containing its text> <hits it skipped>" to STATS_FILE
DENY_AWK='
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function squeeze(s) { gsub(/[ \t]+/, " ", s); return s }
function sepview(s) { gsub(/[-_.\/]+/, " ", s); return trim(squeeze(s)) }
function bounded(s, p, L,   b, a) {
  b = (p > 1) ? substr(s, p - 1, 1) : ""
  a = substr(s, p + L, 1)
  return (b !~ /[A-Za-z0-9_]/ && a !~ /[A-Za-z0-9_]/)
}
function word_hit(s, w,   p, off, L) {
  L = length(w); off = 0
  while ((p = index(substr(s, off + 1), w)) > 0) {
    if (bounded(s, off + p, L)) return 1
    off += p
  }
  return 0
}
function any_hit(s, sv,   i, low, lowv) {
  low = tolower(s); lowv = tolower(sv)
  for (i = 1; i <= ns; i++) if (index(low, subs[i]) || index(lowv, subsv[i])) return 1
  for (i = 1; i <= nw; i++) if (word_hit(s, word[i]) || word_hit(sv, wordv[i])) return 1
  return 0
}
function line_at(a,   l) {
  for (l = pend; l > pstart; l--) if (off[l] <= a) return l
  return pstart
}
function mark(first, last) {
  if (!(first in hl) || last > hl[first]) hl[first] = last
}
function flush(   i, low, p, o, L) {
  if (np == 0) return
  low = tolower(para)
  for (i = 1; i <= ns; i++) {
    if (!smulti[i]) continue
    L = length(subs[i]); o = 0
    while ((p = index(substr(low, o + 1), subs[i])) > 0) { mark(line_at(o + p), line_at(o + p + L - 1)); o += p }
  }
  for (i = 1; i <= nw; i++) {
    if (!wmulti[i]) continue
    L = length(word[i]); o = 0
    while ((p = index(substr(para, o + 1), word[i])) > 0) {
      if (bounded(para, o + p, L)) mark(line_at(o + p), line_at(o + p + L - 1))
      o += p
    }
  }
  np = 0; para = ""
}
function allowed_by(m,   k) {
  for (k = 1; k <= na; k++) if (index(raw[m], atext[k]) > 0) return k
  return 0
}
BEGIN {
  label = ENVIRON["DENY_LABEL"]
  n = 0
  if (ENVIRON["DENY_SOURCE"] == "env") {
    n = split(ENVIRON["ASSEMBLE_DENYLIST"], rawlist, "\n")
  } else {
    f = ENVIRON["DENY_FILE"]
    while ((r = (getline l < f)) > 0) rawlist[++n] = l
    close(f)
    if (r < 0) { print "denylist: could not read the denylist file" > "/dev/stderr"; exit 3 }
  }
  nw = 0; ns = 0
  for (i = 1; i <= n; i++) {
    t = rawlist[i]
    sub(/\r$/, "", t)
    t = trim(t)
    if (t == "" || substr(t, 1, 1) == "#") continue
    if (substr(t, 1, 5) == "word:") {
      t = squeeze(trim(substr(t, 6)))
      if (t != "") { word[++nw] = t; wordv[nw] = sepview(t); wmulti[nw] = (index(t, " ") > 0) }
    } else {
      t = tolower(squeeze(t))
      subs[++ns] = t; subsv[ns] = sepview(t); smulti[ns] = (index(t, " ") > 0)
      if (subsv[ns] == "") subsv[ns] = t
    }
  }
  for (i = 1; i <= nw; i++) if (wordv[i] == "") wordv[i] = word[i]
  if (ENVIRON["DENY_MODE"] == "count") { printf "%d %d\n", nw, ns; exit 0 }
  if (ENVIRON["DENY_MODE"] == "path") {
    sp = ENVIRON["SCAN_PATH"]
    if (any_hit(sp, sepview(sp))) print "hit"
    exit 0
  }

  na = 0
  scanpath = ENVIRON["SCAN_PATH"]
  af = ENVIRON["ALLOW_FILE"]
  if (af != "") {
    al = 0
    while ((getline l < af) > 0) {
      al++
      sub(/\r$/, "", l)
      if (l == "" || substr(l, 1, 1) == "#") continue
      p = index(l, ":")
      if (p < 2) continue
      if (substr(l, 1, p - 1) == scanpath) {
        atext[++na] = substr(l, p + 1); aline[na] = al; acount[na] = 0; aused[na] = 0
      }
    }
    close(af)
  }
  np = 0; para = ""
}
{
  line = $0
  sub(/\r$/, "", line)
  raw[FNR] = line
  for (k = 1; k <= na; k++) if (index(line, atext[k]) > 0) acount[k]++
  sq = squeeze(line)
  low = tolower(sq)
  for (i = 1; i <= ns; i++) if (index(low, subs[i]) > 0) { mark(FNR, FNR); break }
  for (i = 1; i <= nw; i++) if (word_hit(sq, word[i])) { mark(FNR, FNR); break }
  pv = trim(sq)
  for (;;) {
    if (pv ~ /^[#>*;\/-]+$/) { pv = ""; break }
    if (match(pv, /^[#>*;\/-]+ /)) pv = substr(pv, RLENGTH + 1); else break
  }
  if (pv == "") { flush(); next }
  if (np == 0) { pstart = FNR; para = pv; off[FNR] = 1 }
  else { off[FNR] = length(para) + 2; para = para " " pv }
  np++; pend = FNR
}
END {
  flush()
  skipped = 0
  for (l = 1; l <= NR; l++) {
    if (!(l in hl)) continue
    k = allowed_by(l)
    for (m = l + 1; m <= hl[l] && k; m++) if (!allowed_by(m)) k = 0
    if (k) { skipped++; aused[k]++ }
    else printf "%s:%d\n", label, l
  }
  sf = ENVIRON["STATS_FILE"]
  for (k = 1; k <= na; k++) printf "%d %d %d\n", aline[k], acount[k], aused[k] >> sf
}
'

counts=$(DENY_MODE=count DENY_LABEL="" awk "$DENY_AWK" < /dev/null) || closed "could not read the denylist"
nwords=${counts% *}
nsubs=${counts#* }
if [ $((nwords + nsubs)) -eq 0 ]; then
  closed "the denylist from $where has no terms"
fi
echo "denylist: using $where ($((nwords + nsubs)) terms; terms are never printed)"

if [ "$mode" = git ]; then
  git ls-files -z > "$work/list" || closed "git ls-files failed"
else
  # Every file and symlink, byte-sorted: the same order as `git ls-tree -r` for an exported commit.
  find . -name .git -prune -o \( -type f -o -type l \) -print0 > "$work/found" || closed "could not list $target"
  sort -z "$work/found" > "$work/list" || closed "could not sort the file list"
fi

count_lines() { printf '%s\n' "$1" | awk 'END { print NR }'; }
bytes() { wc -c | awk '{ print $1 + 0 }'; }

n=0
hits=0
scanned=0
unscannable=0
hidden=0
while IFS= read -r -d '' f; do
  n=$((n + 1))
  if [ "$mode" = folder ]; then
    f=${f#./}
  fi
  label=$f
  pout=$(DENY_MODE=path SCAN_PATH="$f" awk "$DENY_AWK" < /dev/null) || closed "the path check failed on file #$n"
  if [ -n "$pout" ]; then
    label="tracked path #$n"
    echo "$label: path matches the denylist"
    hits=$((hits + 1))
    hidden=1
  fi
  p="./$f"
  if [ -L "$p" ]; then
    out=$(readlink "$p" | DENY_LABEL="$label" SCAN_PATH="$f" awk "$DENY_AWK") || closed "the scan failed on $label"
  elif [ ! -f "$p" ]; then
    echo "denylist: note: not scanned (missing from the working tree, or not a file): $label" >&2
    continue
  elif [ ! -s "$p" ]; then
    scanned=$((scanned + 1))
    continue
  elif [ "$(tr -d '\000' < "$p" | bytes)" -ne "$(bytes < "$p")" ]; then
    if grep -Fxq -- "$f" "$work/binary-allow"; then
      out=$(tr -c '\11\40-\176' '\n' < "$p" | DENY_LABEL="$label [binary, printable text]" SCAN_PATH="$f" awk "$DENY_AWK") || closed "the scan failed on $label"
    else
      echo "$label: binary file (it has a NUL byte), so it can't be scanned" >&2
      unscannable=$((unscannable + 1))
      continue
    fi
  else
    out=$(DENY_LABEL="$label" SCAN_PATH="$f" awk "$DENY_AWK" < "$p") || closed "the scan failed on $label"
  fi
  scanned=$((scanned + 1))
  if [ -n "$out" ]; then
    printf '%s\n' "$out"
    hits=$((hits + $(count_lines "$out")))
  fi
done < "$work/list"

# Every exception entry must have matched exactly one line of a scanned file.
bad_allow=0
used=0
skipped=0
while read -r aln apath; do
  [ -n "$aln" ] || continue
  stat=$(awk -v L="$aln" '$1 == L { c += $2; u += $3; seen = 1 } END { if (seen) print c, u; else print "none" }' "$STATS_FILE")
  case "$stat" in
    none)
      echo "denylist-allow.txt:$aln: stale entry: its file was not scanned (not tracked, missing or binary)" >&2
      bad_allow=$((bad_allow + 1)) ;;
    "0 "*)
      echo "denylist-allow.txt:$aln: stale entry: its text is on no line of its file" >&2
      bad_allow=$((bad_allow + 1)) ;;
    "1 "*)
      used=$((used + 1))
      skipped=$((skipped + ${stat#* }))
      if [ "${stat#* }" -eq 0 ]; then
        echo "denylist: note: denylist-allow.txt:$aln matched its line but skipped no hit" >&2
      fi ;;
    *)
      echo "denylist-allow.txt:$aln: too broad: its text is on ${stat% *} lines of its file (it must pick exactly one)" >&2
      bad_allow=$((bad_allow + 1)) ;;
  esac
done < "$work/allow-entries"
if [ "$used" -gt 0 ]; then
  echo "denylist: $used exception entr(y/ies) in denylist-allow.txt used, $skipped line(s) skipped"
fi

if [ "$hidden" -eq 1 ]; then
  echo "denylist: a \"tracked path #N\" label hides a path that contains a term; see it with: git ls-files | sed -n 'Np' (in a plain folder: the Nth file in byte order)" >&2
fi
if [ "$unscannable" -gt 0 ]; then
  echo "denylist: $unscannable binary file(s) can't be scanned. Convert them to UTF-8 text, or list the exact path in binary-allow.txt in a reviewed PR." >&2
fi
if [ "$hits" -gt 0 ] || [ "$unscannable" -gt 0 ] || [ "$bad_allow" -gt 0 ]; then
  echo "denylist: $hits hit(s) in $scanned scanned file(s) (terms not shown). Reword those lines or rename those files." >&2
  exit 1
fi
if [ "$scanned" -eq 0 ]; then
  closed "no file was scanned in $target, so this proves nothing"
fi
echo "denylist: clean ($scanned files scanned)"
