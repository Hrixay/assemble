#!/usr/bin/env bash
# leak-scan.sh: look for generic leaks in every file of a checkout or folder.
#
# Patterns (each hit prints "file:line: <pattern name>", never the matched text):
#   email              any email address except <anything>@users.noreply.github.com
#   macos-home-path    a macOS home folder path (slash, "Users", slash), in any letter case
#   linux-home-path    a Linux home folder path (slash, "home", slash)
#   tilde-home-path    a tilde-slash home shorthand
#   windows-home-path  a Windows home folder path (drive letter, backslash, "Users", backslash;
#                      any letter case, and the doubled backslash of escaped strings too)
#   sk-key             an API key that starts "sk-" (8 or more key characters after it; real keys
#                      are far longer, so even a shortened example is caught)
#   github-token       a GitHub token: ghp_, gho_, ghu_, ghs_, ghr_ or github_pat_ (20+ characters after it)
#   private-key        a PEM private key header
#   ipv4               an IPv4 address
#   ipv6               an IPv6 address with at least four hex groups ("::" allowed between them)
#
# Paths are checked too. A file whose path matches a pattern is reported as
# "tracked path #N" (N counts files from 1 in listing order) so the path itself is never printed;
# content hits in that file use the same label. Find the path with: git ls-files | sed -n 'Np'
#
# Allowlist: the exact strings in LEAK_ALLOW below are removed from a line before the patterns
# run, but only where the string ends there: at the end of the line, before a space, tab, quote,
# backtick, ")", "]", ">", ",", ";", ":", or a "." that ends a sentence (one trailing slash is
# allowed first). A longer path that merely starts with an allowed string is still flagged, so
# each longer path needs its own entry. They are reviewed placeholders from the build plan. Add
# one only in a reviewed PR, and never loosen a pattern instead: examples use placeholders like
# /path/to/acme.
#
# What is scanned:
#   no argument  the files git tracks in the checkout this script sits in (working-tree copies)
#   DIR          the checkout at DIR (if DIR is the top of a git work tree: the files git tracks
#                there), or else every file under DIR. Use this to scan someone else's branch
#                with a trusted copy of this script, never with the branch's own copy.
# A tracked symlink is scanned by its target text. A file with a NUL byte (binary, UTF-16, most
# images and PDFs) FAILS the scan unless its exact path is listed in binary-allow.txt next to
# this script (a reviewed list; empty today); a listed file has its printable text scanned.
# A run that scans no file at all fails. The patterns are written so this file never matches
# itself.
#
# Usage: scripts/leak-scan.sh [DIR]
# Exit:  0 = no hits, 1 = at least one hit or an unscannable file, 2 = could not run.
# Portable bash: runs on macOS bash 3.2 and on Linux. No GNU-only flags.

set -eu
LC_ALL=C
export LC_ALL
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

LEAK_ALLOW='~/.assemble-src
~/.claude/skills/assemble
~/.claude/skills
/path/to/acme-team
/path/to/acme'
# One more reviewed exact entry: the plan's install line (section 2.4) copies the clone's
# skills/assemble folder into the skills folder, so it names the clone folder plus
# "/skills/assemble", and the shorter clone-folder entry above does not cover a longer path.
# Its leading tilde is held in a variable, and the entry is kept apart from the list above, because
# a clone's pre-push hook runs an older installed copy of this scanner until install-hooks.sh is
# run again from main, and that copy flags a source line that starts with tilde-slash. Once every
# clone has the new copy, this can be folded into the list above as one plain line.
tilde='~'
LEAK_ALLOW="$LEAK_ALLOW
${tilde}/.assemble-src/skills/assemble"
export LEAK_ALLOW

cant() { echo "leak-scan: $*" >&2; exit 2; }

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ "$#" -gt 1 ]; then
  cant "usage: leak-scan.sh [DIR]"
elif [ "$#" -eq 1 ]; then
  [ -d "$1" ] || cant "$1 is not a folder"
  target=$(CDPATH= cd -- "$1" && pwd)
else
  target=$(CDPATH= cd -- "$script_dir/.." && pwd)
fi
cd "$target"
mode=folder
if top=$(git rev-parse --show-toplevel 2>/dev/null) && [ "$(CDPATH= cd -- "$top" && pwd -P)" = "$(pwd -P)" ]; then
  mode=git
elif [ "$#" -eq 0 ]; then
  cant "$target is not the top of a git work tree (pass a folder to scan one)"
fi

work=$(mktemp -d "${TMPDIR:-/tmp}/leak-scan.XXXXXX") || cant "could not make a temporary folder"
trap 'rm -rf "$work"' EXIT
if [ "$mode" = git ]; then
  git ls-files -z > "$work/list" || cant "git ls-files failed"
else
  # Every file and symlink, byte-sorted: the same order as `git ls-tree -r` for an exported commit.
  find . -name .git -prune -o \( -type f -o -type l \) -print0 > "$work/found" || cant "could not list $target"
  sort -z "$work/found" > "$work/list" || cant "could not sort the file list"
fi
: > "$work/binary-allow"
if [ -f "$script_dir/binary-allow.txt" ]; then
  awk '{ sub(/\r$/, "") } $0 != "" && substr($0, 1, 1) != "#"' "$script_dir/binary-allow.txt" > "$work/binary-allow"
fi

# The awk program. String pieces are split ("s" "k-") so the source never matches itself.
LEAK_AWK='
function boundary_ok(s, q,   c, c2) {
  c = substr(s, q, 1)
  if (c == "/") { q++; c = substr(s, q, 1) }
  if (c == "" || index(" \t\"`),;:]>", c) > 0 || c == "\047") return 1
  if (c == ".") { c2 = substr(s, q + 1, 1); return (c2 == "" || c2 == " " || c2 == "\t") }
  return 0
}
function strip_allowed(s,   i, p, a, L, out) {
  for (i = 1; i <= na; i++) {
    a = allow[i]; L = length(a); out = ""
    while ((p = index(s, a)) > 0) {
      if (boundary_ok(s, p + L)) { out = out substr(s, 1, p - 1) " "; s = substr(s, p + L) }
      else { out = out substr(s, 1, p); s = substr(s, p + 1) }
    }
    s = out s
  }
  return s
}
function email_hit(s,   m) {
  while (match(s, email_re)) {
    m = substr(s, RSTART, RLENGTH)
    if (m !~ /@users[.]noreply[.]github[.]com$/) return 1
    s = substr(s, RSTART + RLENGTH)
  }
  return 0
}
function report(name) {
  if (pathmode) printf "%s: %s (in the path)\n", label, name
  else printf "%s:%d: %s\n", label, FNR, name
}
BEGIN {
  label = ENVIRON["LEAK_LABEL"]
  pathmode = (ENVIRON["LEAK_PATH"] == "1")
  n = split(ENVIRON["LEAK_ALLOW"], tmp, "\n")
  na = 0
  for (i = 1; i <= n; i++) if (tmp[i] != "") allow[++na] = tmp[i]
  # longest first, so a longer allowed string is removed before a shorter one inside it
  for (i = 1; i <= na; i++) for (j = i + 1; j <= na; j++)
    if (length(allow[j]) > length(allow[i])) { t = allow[i]; allow[i] = allow[j]; allow[j] = t }

  email_re = "[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+([.][A-Za-z0-9-]+)*[.][A-Za-z][A-Za-z]+"
  keych = "[A-Za-z0-9_-]"
  sk_re = "[^A-Za-z0-9_]s" "k-"
  for (i = 0; i < 8; i++) sk_re = sk_re keych
  tokch = "[A-Za-z0-9_]"
  gh_re = "[^A-Za-z0-9_](g" "h[pousr]_|git" "hub_pat_)"
  for (i = 0; i < 20; i++) gh_re = gh_re tokch
  oct = "(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])"
  ip_re = "[^0-9.]" oct "[.]" oct "[.]" oct "[.]" oct "([^0-9.]|[.][^0-9])"
  hx = "[0-9A-Fa-f]"
  h4 = hx hx "?" hx "?" hx "?"
  ip6_re = "[^0-9A-Za-z:](::)?" h4 "::?" h4 "::?" h4 "::?" h4 "[^0-9A-Za-z]"
  pk_re = "-----BEGIN [A-Z ]*PRIV" "ATE KEY-----"
  users_re = "/[Uu][Ss][Ee][Rr][Ss]/"
  win_re = "[A-Za-z]:\\\\+[Uu][Ss][Ee][Rr][Ss]\\\\"
  home = "/" "home/"
  tilde = "~" "/"
}
{
  line = $0
  sub(/\r$/, "", line)
  s = " " strip_allowed(line) " "
  if (email_hit(s)) report("email")
  if (s ~ users_re) report("macos-home-path")
  if (index(s, home)) report("linux-home-path")
  if (index(s, tilde)) report("tilde-home-path")
  if (s ~ win_re) report("windows-home-path")
  if (match(s, sk_re)) report("sk-key")
  if (match(s, gh_re)) report("github-token")
  if (match(s, pk_re)) report("private-key")
  if (match(s, ip_re)) report("ipv4")
  if (match(s, ip6_re)) report("ipv6")
}
'

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
  pout=$(printf '%s\n' "$f" | LEAK_LABEL="tracked path #$n" LEAK_PATH=1 awk "$LEAK_AWK") || cant "the path check failed on file #$n"
  if [ -n "$pout" ]; then
    printf '%s\n' "$pout"
    hits=$((hits + $(count_lines "$pout")))
    label="tracked path #$n"
    hidden=1
  fi
  p="./$f"
  if [ -L "$p" ]; then
    out=$(readlink "$p" | LEAK_LABEL="$label" awk "$LEAK_AWK") || cant "the scan failed on $label"
  elif [ ! -f "$p" ]; then
    echo "leak-scan: note: not scanned (missing from the working tree, or not a file): $label" >&2
    continue
  elif [ ! -s "$p" ]; then
    scanned=$((scanned + 1))
    continue
  elif [ "$(tr -d '\000' < "$p" | bytes)" -ne "$(bytes < "$p")" ]; then
    if grep -Fxq -- "$f" "$work/binary-allow"; then
      out=$(tr -c '\11\40-\176' '\n' < "$p" | LEAK_LABEL="$label [binary, printable text]" awk "$LEAK_AWK") || cant "the scan failed on $label"
    else
      echo "$label: binary file (it has a NUL byte), so it can't be scanned" >&2
      unscannable=$((unscannable + 1))
      continue
    fi
  else
    out=$(LEAK_LABEL="$label" awk "$LEAK_AWK" < "$p") || cant "the scan failed on $label"
  fi
  scanned=$((scanned + 1))
  if [ -n "$out" ]; then
    printf '%s\n' "$out"
    hits=$((hits + $(count_lines "$out")))
  fi
done < "$work/list"

if [ "$hidden" -eq 1 ]; then
  echo "leak-scan: a \"tracked path #N\" label hides a path that matched; see it with: git ls-files | sed -n 'Np' (in a plain folder: the Nth file in byte order)" >&2
fi
if [ "$unscannable" -gt 0 ]; then
  echo "leak-scan: $unscannable binary file(s) can't be scanned. Convert them to UTF-8 text, or list the exact path in binary-allow.txt in a reviewed PR." >&2
fi
if [ "$hits" -gt 0 ] || [ "$unscannable" -gt 0 ]; then
  echo "leak-scan: $hits hit(s) in $scanned scanned file(s). Fix them, or use a placeholder like /path/to/acme." >&2
  exit 1
fi
if [ "$scanned" -eq 0 ]; then
  cant "no file was scanned in $target, so this proves nothing"
fi
echo "leak-scan: clean ($scanned files scanned)"
