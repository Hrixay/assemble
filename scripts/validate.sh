#!/usr/bin/env bash
# validate.sh: check every skill folder under skills/ (today only skills/assemble).
#
#   1. SKILL.md starts with a closed YAML frontmatter block.
#   2. Every top-level frontmatter key is on the documented list below. Claude Code ignores
#      unknown keys without an error, so a misspelled key would otherwise go unnoticed.
#   3. name equals the folder name (lowercase letters, digits and hyphens, at most 64 characters).
#   4. description is present and at most 1024 characters (counted in bytes, which is stricter).
#   5. SKILL.md is at most 300 lines.
#   6. VERSION holds one version (x.y.z) and equals metadata.version in the frontmatter.
#   7. The frontmatter parses as real YAML (python3 with PyYAML, else ruby), and the parser reads
#      the same name, description length and metadata.version as the line-based checks above.
#      No parser available: skipped with a note, unless ASSEMBLE_REQUIRE_YAML=1 (CI sets it),
#      which makes a missing parser a failure.
#
# Usage: scripts/validate.sh        (from anywhere inside the repo)
# Exit:  0 = every check passed, 1 = at least one check failed.
# Portable bash: runs on macOS bash 3.2 and on Linux. No GNU-only flags.

set -eu
LC_ALL=C
export LC_ALL

# The documented SKILL.md frontmatter keys. Change this list only in a reviewed PR.
ALLOWED_KEYS="name description argument-hint license compatibility metadata allowed-tools disable-model-invocation model context agent hooks user-invocable"
MAX_LINES=300
MAX_DESC=1024
MAX_NAME=64

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

fails=0
fail() { printf 'FAIL  %s\n' "$*"; fails=$((fails + 1)); }
pass() { printf 'ok    %s\n' "$*"; }
note() { printf 'note  %s\n' "$*"; }

# Reads one SKILL.md and prints tab-separated facts for the shell to check:
#   ERR <message> | NAME <value> | VERSION <value> | DESCLEN <n> | LINES <n> | KEY <key>
# It understands the YAML this project uses: "key: value" lines, quoted values, folded (>, >-)
# and literal (|, |-) block scalars, and one nested level (metadata.version).
read_frontmatter() {
  awk -v allowed="$ALLOWED_KEYS" '
    function err(msg) { printf "ERR\t%s\n", msg }
    function unquote(v) {
      sub(/^[ ]+/, "", v); sub(/[ ]+$/, "", v)
      if (v ~ /^".*"$/ || v ~ /^\047.*\047$/) v = substr(v, 2, length(v) - 2)
      return v
    }
    function close_key() {
      if (cur == "description") {
        desc = (desc_style == "|") ? desc_lit : desc_fold
        gotdesc = 1
      }
      cur = ""
    }
    function add_desc(text) {
      # folded style: lines join with one space, a blank line becomes a newline
      if (text == "") { desc_fold = desc_fold "\n"; desc_lit = desc_lit "\n"; lastblank = 1; return }
      if (desc_fold == "" || lastblank) desc_fold = desc_fold text
      else desc_fold = desc_fold " " text
      desc_lit = (desc_lit == "") ? text : desc_lit "\n" text
      lastblank = 0
    }
    BEGIN {
      n = split(allowed, list, " ")
      for (i = 1; i <= n; i++) ok[list[i]] = 1
      state = 0; cur = ""; desc = ""; gotdesc = 0; version = ""; name = ""
    }
    {
      line = $0
      sub(/\r$/, "", line)
    }
    NR == 1 {
      if (line != "---") { err("line 1 must be \"---\": the frontmatter has to start the file"); state = 3 }
      else state = 1
      next
    }
    state == 1 && line == "---" { close_key(); state = 2; next }
    state == 1 {
      if (line ~ /^[ ]*\t/) { err("line " NR ": tab used for indentation (YAML allows spaces only)"); next }
      if (line ~ /^[ ]*$/) {                     # blank line
        if (cur == "description") add_desc("")
        next
      }
      if (line ~ /^#/) next                       # comment at top level
      if (line ~ /^ /) {                          # indented: belongs to the current key
        if (cur == "") { err("line " NR ": indented line with no key above it"); next }
        text = line; sub(/^[ ]+/, "", text)
        if (cur == "description") add_desc(text)
        else if (cur == "metadata" && text ~ /^version:/) {
          v = text; sub(/^version:/, "", v); version = unquote(v); gotversion = 1
        }
        next
      }
      # a top-level "key: value" line
      p = index(line, ":")
      if (p < 2) { err("line " NR ": not a \"key: value\" line"); next }
      key = substr(line, 1, p - 1)
      rest = substr(line, p + 1)
      if (key !~ /^[A-Za-z0-9_-]+$/) { err("line " NR ": not a \"key: value\" line"); next }
      if (rest != "" && rest !~ /^ /) { err("line " NR ": put a space after \"" key ":\""); next }
      close_key()
      printf "KEY\t%s\n", key
      if (key in seen) err("duplicate key \"" key "\" (line " NR ")")
      seen[key] = 1
      if (!(key in ok)) err("unknown frontmatter key \"" key "\" (line " NR "); allowed: " allowed)
      cur = key
      sub(/^[ ]+/, "", rest); sub(/[ ]+$/, "", rest)
      if (key == "name") { name = unquote(rest); gotname = 1 }
      if (key == "description") {
        desc_fold = ""; desc_lit = ""; lastblank = 0
        if (rest ~ /^[>|][-+]?$/) desc_style = substr(rest, 1, 1)
        else { desc_style = ">"; if (rest != "") add_desc(unquote(rest)) }
      }
      next
    }
    END {
      if (state == 1) err("the frontmatter is never closed with a \"---\" line")
      if (state == 2) {
        if (!gotname) err("frontmatter has no \"name\"")
        if (!gotdesc) err("frontmatter has no \"description\"")
        if (!gotversion) err("frontmatter has no metadata.version")
        sub(/\n+$/, "", desc)
        printf "NAME\t%s\n", name
        printf "VERSION\t%s\n", version
        printf "DESCLEN\t%d\n", length(desc)
      }
      printf "LINES\t%d\n", NR
    }
  ' "$1"
}

# Prints the frontmatter block of $1: the lines between the first "---" line and the next one.
frontmatter_block() {
  awk 'NR == 1 { if ($0 !~ /^---\r?$/) exit; next } /^---\r?$/ { exit } { print }' "$1"
}

# Real YAML parsers. Each reads the block on stdin and prints ERR <message>, or
# NAME / DESCLEN (bytes, trailing newlines dropped) / VERSION lines like read_frontmatter.
PY_YAML='
import sys
import yaml
try:
    d = yaml.safe_load(sys.stdin.buffer.read().decode("utf-8"))
except Exception as e:
    print("ERR\t" + " ".join(str(e).split()))
    sys.exit(0)
if not isinstance(d, dict):
    print("ERR\tthe frontmatter is not a YAML mapping of keys to values")
    sys.exit(0)
m = d.get("metadata")
v = m.get("version") if isinstance(m, dict) else None
n = d.get("name")
s = d.get("description")
print("NAME\t" + (n if isinstance(n, str) else "<not a string>"))
print("DESCLEN\t" + (str(len(s.rstrip("\n").encode("utf-8"))) if isinstance(s, str) else "<not a string>"))
print("VERSION\t" + (v if isinstance(v, str) else "<not a string>"))
'
RB_YAML='
begin
  d = YAML.safe_load($stdin.read.force_encoding("UTF-8"))
rescue StandardError, Psych::Exception => e
  puts "ERR\t" + e.message.split.join(" ")
  exit 0
end
unless d.is_a?(Hash)
  puts "ERR\tthe frontmatter is not a YAML mapping of keys to values"
  exit 0
end
m = d["metadata"]
v = m.is_a?(Hash) ? m["version"] : nil
n = d["name"]
s = d["description"]
puts "NAME\t" + (n.is_a?(String) ? n : "<not a string>")
puts "DESCLEN\t" + (s.is_a?(String) ? s.sub(/\n+\z/, "").bytesize.to_s : "<not a string>")
puts "VERSION\t" + (v.is_a?(String) ? v : "<not a string>")
'

# Check 7: parse the frontmatter with a real YAML parser and compare it with the line-based reader.
yaml_check() {
  y_skill=$1; y_name=$2; y_len=$3; y_ver=$4
  y_block=$(frontmatter_block "$y_skill")
  if command -v python3 >/dev/null 2>&1 && python3 -I -c 'import yaml' >/dev/null 2>&1; then
    y_parser="python3 yaml.safe_load"
    y_out=$(printf '%s\n' "$y_block" | python3 -I -c "$PY_YAML" 2>&1) || y_out="ERR${tab}python3 exited with an error: $y_out"
  elif command -v ruby >/dev/null 2>&1 && ruby -ryaml -e 'exit 0' >/dev/null 2>&1; then
    y_parser="ruby YAML.safe_load"
    y_out=$(printf '%s\n' "$y_block" | ruby -ryaml -e "$RB_YAML" 2>&1) || y_out="ERR${tab}ruby exited with an error: $y_out"
  elif [ "${ASSEMBLE_REQUIRE_YAML:-}" = "1" ]; then
    fail "no YAML parser found (python3 with PyYAML, or ruby), and ASSEMBLE_REQUIRE_YAML=1 requires one"
    return 0
  else
    note "YAML parse skipped: no python3 with PyYAML and no ruby here (CI requires it)"
    return 0
  fi
  y_errs=0; p_name=""; p_len=""; p_ver=""
  while IFS="$tab" read -r kind value; do
    case "$kind" in
      ERR) fail "$y_skill: the frontmatter is not valid YAML ($y_parser): $value"; y_errs=$((y_errs + 1)) ;;
      NAME) p_name=$value ;;
      DESCLEN) p_len=$value ;;
      VERSION) p_ver=$value ;;
    esac
  done <<EOF
$y_out
EOF
  [ "$y_errs" -eq 0 ] || return 0
  if [ "$p_name" != "$y_name" ]; then
    fail "the YAML parser reads name \"$p_name\", the line-based reader \"$y_name\""; y_errs=1
  fi
  if [ "$p_len" != "$y_len" ]; then
    fail "the YAML parser reads a $p_len-byte description, the line-based reader $y_len"; y_errs=1
  fi
  if [ "$p_ver" != "$y_ver" ]; then
    fail "the YAML parser reads metadata.version \"$p_ver\", the line-based reader \"$y_ver\""; y_errs=1
  fi
  if [ "$y_errs" -eq 0 ]; then
    pass "frontmatter is valid YAML ($y_parser) and matches the checks above"
  fi
}

tab=$(printf '\t')
found=0
for dir in skills/*/; do
  [ -d "$dir" ] || continue
  dir=${dir%/}
  folder=${dir#skills/}
  skill="$dir/SKILL.md"
  if [ ! -f "$skill" ]; then
    fail "$dir: no SKILL.md"
    continue
  fi
  found=$((found + 1))
  echo "== $dir"

  name=""; version=""; desclen=""; lines=""; errs=0
  facts=$(read_frontmatter "$skill")
  while IFS="$tab" read -r kind value; do
    case "$kind" in
      ERR) fail "$skill: $value"; errs=$((errs + 1)) ;;
      NAME) name=$value ;;
      VERSION) version=$value ;;
      DESCLEN) desclen=$value ;;
      LINES) lines=$value ;;
    esac
  done <<EOF
$facts
EOF
  if [ "$errs" -eq 0 ]; then
    pass "frontmatter parses; every key is on the documented list"
  fi

  if [ -n "$lines" ] && [ "$lines" -le "$MAX_LINES" ]; then
    pass "SKILL.md is $lines lines (limit $MAX_LINES)"
  else
    fail "SKILL.md is ${lines:-?} lines (limit $MAX_LINES)"
  fi

  if [ -n "$name" ]; then
    if [ "$name" != "$folder" ]; then
      fail "name \"$name\" does not match the folder name \"$folder\""
    elif ! printf '%s\n' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
      fail "name \"$name\" must be lowercase letters, digits and single hyphens"
    elif [ "${#name}" -gt "$MAX_NAME" ]; then
      fail "name is ${#name} characters (limit $MAX_NAME)"
    else
      pass "name \"$name\" matches the folder"
    fi
  fi

  if [ -n "$desclen" ]; then
    if [ "$desclen" -eq 0 ]; then
      fail "description is empty"
    elif [ "$desclen" -gt "$MAX_DESC" ]; then
      fail "description is $desclen characters (limit $MAX_DESC)"
    else
      pass "description is $desclen characters (limit $MAX_DESC)"
    fi
  fi

  if [ ! -f "$dir/VERSION" ]; then
    fail "$dir/VERSION is missing"
  else
    vlines=$(awk 'NF { n++ } END { print n + 0 }' "$dir/VERSION")
    vfile=$(awk 'NF { gsub(/[ \t\r]/, ""); print; exit }' "$dir/VERSION")
    if [ "$vlines" -ne 1 ]; then
      fail "$dir/VERSION must hold exactly one non-empty line (found $vlines)"
    elif ! printf '%s\n' "$vfile" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
      fail "$dir/VERSION \"$vfile\" is not a version like 1.2.3"
    elif [ "$vfile" != "$version" ]; then
      fail "VERSION \"$vfile\" does not equal metadata.version \"$version\""
    else
      pass "VERSION $vfile equals metadata.version"
    fi
  fi

  yaml_check "$skill" "$name" "$desclen" "$version"
done

if [ "$found" -eq 0 ]; then
  fail "no skills/<name>/SKILL.md found"
fi

if [ "$fails" -gt 0 ]; then
  echo "validate: $fails check(s) failed"
  exit 1
fi
echo "validate: all checks passed"
