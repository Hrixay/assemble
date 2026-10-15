#!/usr/bin/env bash
# selftest.sh: prove that the checks catch what they are there to catch.
#
# A check that always says "clean" looks exactly like a check that works. So this script plants
# known-bad files and known-bad commits and confirms that each check fails on them, and that the
# same checks pass on clean input:
#
#   leak-scan.sh      fails on a planted email, home path (macOS, Linux, tilde, Windows), token,
#                     private key, IP address, on a bad file NAME, on binary and UTF-16 files and on
#                     zero files; passes on clean text, the noreply address and the plan's
#                     install line (an exact allowlist entry).
#   denylist-scan.sh  with a made-up throwaway denylist: fails on a whole-word term, a plain
#                     substring, a phrase that wraps onto the next line and a bad file name; fails
#                     on binary and UTF-16 files and on zero files; FAILS CLOSED (exit 2) with no
#                     denylist, an unreadable one, an empty one and one with no terms.
#   validate.sh       fails on an unknown frontmatter key, a VERSION that differs from
#                     metadata.version, a too-long description, a wrong name and a too-long SKILL.md.
#   the pre-push hook (installed by install-hooks.sh into a throwaway repo, pushing to a local
#                     bare remote) blocks a committed leak, blocks a leak that a later commit
#                     removed, blocks a denylist hit, ignores uncommitted files, lets a clean push
#                     through, skips a commit with an empty tree, and blocks a commit in which two
#                     paths would land on one file.
#
# Everything runs in copies under $TMPDIR. It never reads or uses the real denylist (HOME is
# pointed at an empty folder and the denylist variables are cleared), and it never prints a term:
# the throwaway terms are made up, and the output is checked for them at the end. This file builds
# every planted bad string from pieces, so the scanners do not flag this file itself.
#
# Usage: scripts/selftest.sh           (from anywhere)
# Needs: bash, git, awk, sed, tr, grep. Same tools the other scripts use.
# Exit:  0 = every test passed, 1 = at least one failed.
# Portable bash: runs on macOS bash 3.2 and on Linux. No GNU-only flags.

set -eu
LC_ALL=C
export LC_ALL
unset CDPATH GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE ASSEMBLE_DENYLIST ASSEMBLE_DENYLIST_FILE

src=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
for f in leak-scan.sh denylist-scan.sh validate.sh install-hooks.sh; do
  if [ ! -f "$src/scripts/$f" ]; then
    echo "selftest: scripts/$f is missing in $src" >&2
    exit 2
  fi
done

work=$(mktemp -d "${TMPDIR:-/tmp}/assemble-selftest.XXXXXX") || { echo "selftest: could not make a temporary folder" >&2; exit 2; }
trap 'rm -rf "$work"' EXIT
work=$(CDPATH= cd -- "$work" && pwd -P)

# Never touch the real denylist, the real git config or the real home folder.
HOME="$work/home"
mkdir -p "$HOME"
export HOME
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=/dev/null
unset XDG_CONFIG_HOME GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS

passes=0
fails=0
log="$work/all-output.log"
out="$work/out"
: > "$log"
rc=0

pass() { printf 'ok    %s\n' "$*"; passes=$((passes + 1)); }
fail() { printf 'FAIL  %s\n' "$*"; fails=$((fails + 1)); }
note() { printf 'note  %s\n' "$*"; }
section() { printf '\n== %s\n' "$*"; }

# run CMD...: runs it with output captured in $out and its exit status in $rc.
run() {
  if "$@" > "$out" 2>&1 < /dev/null; then rc=0; else rc=$?; fi
  cat "$out" >> "$log"
}
# show: the captured output, indented (used only when a test fails; scanners never print terms).
show() { sed 's/^/        | /' "$out"; }

# expect_rc NAME WANTED: the last run() must have exited with WANTED.
expect_rc() {
  if [ "$rc" -eq "$2" ]; then pass "$1"; else fail "$1 (exit $rc, wanted $2)"; show; fi
}
# expect_out NAME PATTERN: the last run()'s output must match the grep pattern.
expect_out() {
  if grep -q -- "$2" "$out"; then pass "$1"; else fail "$1 (expected output not found)"; show; fi
}
# expect_no_text NAME TEXT...: the output must contain none of these fixed texts.
expect_no_text() {
  nt_name=$1; shift
  nt_hit=0
  for nt_t in "$@"; do if grep -qF -- "$nt_t" "$out"; then nt_hit=1; fi; done
  if [ "$nt_hit" -eq 0 ]; then pass "$nt_name"; else fail "$nt_name (found text that should not be printed)"; show; fi
}
# expect_no_out NAME PATTERN: the output must NOT match the grep pattern.
expect_no_out() {
  if grep -q -- "$2" "$out"; then fail "$1 (unexpected output)"; show; else pass "$1"; fi
}

# ---------------------------------------------------------------------------------------------
# Planted bad strings, built from pieces so this file never matches the scanners itself.
AT='@'
USR='/Us''ers'                 # a macOS home folder
LNX='/ho''me'                  # a Linux home folder
TIL='~'                        # a tilde home shorthand
sk_pre='s''k-'
gh_pre='g''hp_'
bad_email="someone${AT}example.org"
ok_email="priya${AT}users.noreply.github.com"
bad_ipv4="203.0.113"".7"
ip6a='2001:db8:85a3'; ip6b='0:0:8a2e'; ip6c='370:7334'
bad_ipv6="${ip6a}:${ip6b}:${ip6c}"

# Made-up throwaway denylist terms (nothing real). Used only inside the temporary folders.
T_WORD='Zorblax'
T_PLAIN='quuxfrob'
T_PHRASE='purple walrus ledger'
T_FILE='flarn wibble'

# --- helpers that build temporary folders --------------------------------------------------------
# new_scripts DIR [BINARY_ALLOW_LINE]: copies the scanners and the hook installer into DIR,
# with EMPTY exception lists (so a later reviewed entry in the real lists can't make a planted run
# "stale"). The scripts themselves are byte-for-byte the repo's.
new_scripts() {
  mkdir -p "$1"
  cp "$src/scripts/leak-scan.sh" "$src/scripts/denylist-scan.sh" "$src/scripts/validate.sh" "$src/scripts/install-hooks.sh" "$1/"
  : > "$1/denylist-allow.txt"
  : > "$1/binary-allow.txt"
  if [ -n "${2:-}" ]; then
    printf '%s\n' "$2" > "$1/binary-allow.txt"
  fi
}

S="$work/scripts"
new_scripts "$S"
DL="$work/throwaway-denylist.txt"
{
  echo "# made-up list for the self-test; none of this is real"
  echo "word:$T_WORD"
  echo "$T_PLAIN"
  echo "$T_PHRASE"
  echo "$T_FILE"
} > "$DL"

leak() { bash "$S/leak-scan.sh" "$@"; }
deny() { ASSEMBLE_DENYLIST_FILE="$DL" bash "$S/denylist-scan.sh" "$@"; }
deny_none() { bash "$S/denylist-scan.sh" "$@"; }

mkd() { mkdir -p "$work/$1"; printf '%s' "$work/$1"; }

# ===============================================================================================
section "leak-scan.sh: each planted leak is caught"

D=$(mkd leak-bad)
printf 'contact %s today\n' "$bad_email"          > "$D/seed-email.txt"
printf 'see %s/priya/notes\n' "$USR"              > "$D/seed-macos-home.txt"
printf 'see %s/priya/notes\n' "$LNX"              > "$D/seed-linux-home.txt"
printf 'see %s/notes\n' "$TIL"                    > "$D/seed-tilde-home.txt"
printf 'see %s\n' 'C:\Us''ers\priya\notes'        > "$D/seed-windows-home.txt"
printf 'key = %s%s\n' "$sk_pre" 'abcdefgh12345678' > "$D/seed-sk-key.txt"
printf 'token %s%s\n' "$gh_pre" 'abcdefghij0123456789' > "$D/seed-github-token.txt"
printf '%s\n' '-----BEGIN PRIV''ATE KEY-----'     > "$D/seed-private-key.txt"
printf 'server %s ready\n' "$bad_ipv4"            > "$D/seed-ipv4.txt"
printf 'server %s ready\n' "$bad_ipv6"            > "$D/seed-ipv6.txt"
printf 'fine line\nsecond line has %s in it\n' "$bad_email" > "$D/seed-line2.txt"
run leak "$D"
expect_rc "bad folder exits 1" 1
expect_out "email"                  'seed-email.txt:1: email'
expect_out "macOS home path"        'seed-macos-home.txt:1: macos-home-path'
expect_out "Linux home path"        'seed-linux-home.txt:1: linux-home-path'
expect_out "tilde home path"        'seed-tilde-home.txt:1: tilde-home-path'
expect_out "Windows home path"      'seed-windows-home.txt:1: windows-home-path'
expect_out "sk- key"                'seed-sk-key.txt:1: sk-key'
expect_out "GitHub token"           'seed-github-token.txt:1: github-token'
expect_out "private key header"     'seed-private-key.txt:1: private-key'
expect_out "IPv4 address"           'seed-ipv4.txt:1: ipv4'
expect_out "IPv6 address"           'seed-ipv6.txt:1: ipv6'
expect_out "the hit is reported on its own line number" 'seed-line2.txt:2: email'
expect_no_out "the matched text is never printed" "someone"

section "leak-scan.sh: a bad file NAME is caught and the name is not printed"

D=$(mkd leak-name)
printf 'harmless\n' > "$D/note-for-$bad_email.txt"
printf 'harmless\n' > "$D/also-harmless.txt"
run leak "$D"
expect_rc "bad name exits 1" 1
expect_out "path hit uses the numbered label" 'tracked path #[0-9]*: email (in the path)'
expect_no_out "the bad name is not printed" "someone"

section "leak-scan.sh: binary, UTF-16 and zero files"

D=$(mkd leak-binary)
printf 'text\n' > "$D/readme.txt"
printf 'a\000b\n' > "$D/blob.bin"
run leak "$D"
expect_rc "a file with a NUL byte exits 1" 1
expect_out "it says binary" 'blob.bin: binary file'

D=$(mkd leak-utf16)
printf 'text\n' > "$D/readme.txt"
printf 'h\000i\000 \000t\000h\000e\000r\000e\000\n\000' > "$D/utf16.txt"
run leak "$D"
expect_rc "UTF-16 text exits 1" 1
expect_out "UTF-16 is reported as unscannable" 'utf16.txt: binary file'

D=$(mkd leak-empty)
run leak "$D"
expect_rc "a folder with no files exits 2 (proves nothing)" 2
expect_out "it says nothing was scanned" 'no file was scanned'

D=$(mkd leak-binary-listed)
printf 'a\000b clean words\n' > "$D/blob.bin"
BS="$work/scripts-binary-listed"
new_scripts "$BS" "blob.bin"
run bash "$BS/leak-scan.sh" "$D"
expect_rc "a binary file listed in binary-allow.txt is scanned as text and passes when clean" 0
printf 'a\000b contact %s\n' "$bad_email" > "$D/blob.bin"
run bash "$BS/leak-scan.sh" "$D"
expect_rc "a listed binary file with a leak in its text still fails" 1
expect_out "and the hit is reported" 'blob.bin \[binary, printable text\]:[0-9]*: email'

section "leak-scan.sh: clean input and the exact allowlist"

D=$(mkd leak-clean)
printf 'Hello from Priya, project Acme.\nSee /path/to/acme and /path/to/acme-team.\n' > "$D/clean.txt"
printf 'Commit as %s\n' "$ok_email" > "$D/noreply.txt"
printf 'cp -R %s/.assemble-src/skills/assemble %s/.claude/skills/assemble\n' "$TIL" "$TIL" > "$D/install-line.txt"
printf 'git clone --depth 1 https://example.org/x.git %s/.assemble-src\n' "$TIL" > "$D/clone-line.txt"
run leak "$D"
expect_rc "clean text, noreply address, placeholders and the plan's install line pass" 0
expect_out "it reports clean" 'leak-scan: clean'

D=$(mkd leak-allow-longer)
printf 'cp %s/.assemble-src/skills/assemble-extra /somewhere\n' "$TIL" > "$D/longer.txt"
printf 'cp %s/.assemble-src/skills/other /somewhere\n' "$TIL" > "$D/other.txt"
run leak "$D"
expect_rc "a longer path that merely starts with an allowed entry is still flagged" 1
expect_out "longer path flagged" 'longer.txt:1: tilde-home-path'
expect_out "a different sub-folder flagged" 'other.txt:1: tilde-home-path'

section "leak-scan.sh: no argument scans the files git tracks"

G="$work/leak-git"
mkdir -p "$G/scripts"
cp "$S/leak-scan.sh" "$S/binary-allow.txt" "$G/scripts/"
printf 'clean\n' > "$G/clean.txt"
printf 'contact %s\n' "$bad_email" > "$G/untracked-bad.txt"
( cd "$G" && git init -q && git add scripts clean.txt ) > /dev/null 2>&1
run bash "$G/scripts/leak-scan.sh"
expect_rc "an untracked leaky file is not scanned, tracked clean files pass" 0
( cd "$G" && git add untracked-bad.txt ) > /dev/null 2>&1
run bash "$G/scripts/leak-scan.sh"
expect_rc "once the leaky file is tracked the scan fails" 1

# ===============================================================================================
section "denylist-scan.sh (made-up throwaway list): each planted hit is caught"

D=$(mkd deny-bad)
printf 'the %s shipped\n' "$T_WORD"                    > "$D/seed-word.txt"
printf 'fine\nthe QUUXFROBnicator\n'                   > "$D/seed-plain.txt"
printf 'a note about the purple walrus\nledger and more\n' > "$D/seed-phrase-wrap.txt"
printf 'a note about the  purple  walrus   ledger\n'   > "$D/seed-phrase-spaces.txt"
printf 'fine text\n'                                   > "$D/flarn-wibble.md"
printf 'also fine\n'                                   > "$D/clean-neighbour.txt"
run deny "$D"
expect_rc "bad folder exits 1" 1
expect_out "whole-word term"                 'seed-word.txt:1'
expect_out "plain substring (any letter case), on its own line" 'seed-plain.txt:2'
expect_out "phrase wrapped onto the next line, reported at its first line" 'seed-phrase-wrap.txt:1'
expect_out "phrase with extra spaces" 'seed-phrase-spaces.txt:1'
expect_out "bad file name" 'tracked path #[0-9]*: path matches the denylist'
expect_no_out "a clean neighbour is not reported" 'clean-neighbour'
expect_no_out "the bad file name is not printed" 'flarn'
expect_out "the term count is printed, never the terms" 'terms; terms are never printed'

section "denylist-scan.sh: whole-word terms are exact"

D=$(mkd deny-word-ok)
printf '%ses and x%s and zorblax and Zorblaxy\n' "$T_WORD" "$T_WORD" > "$D/near-misses.txt"
run deny "$D"
expect_rc "a whole-word term does not match inside a longer word or in another letter case" 0

section "denylist-scan.sh: binary, UTF-16 and zero files"

D=$(mkd deny-binary)
printf 'text\n' > "$D/readme.txt"
printf 'a\000b\n' > "$D/blob.bin"
run deny "$D"
expect_rc "a file with a NUL byte exits 1" 1
expect_out "it says binary" 'blob.bin: binary file'

D=$(mkd deny-utf16)
printf 'text\n' > "$D/readme.txt"
printf 'h\000i\000\n\000' > "$D/utf16.txt"
run deny "$D"
expect_rc "UTF-16 text exits 1" 1

D=$(mkd deny-empty)
run deny "$D"
expect_rc "a folder with no files fails closed (exit 2)" 2
expect_out "it says nothing was scanned" 'no file was scanned'

D=$(mkd deny-binary-listed)
printf 'a\000b clean words\n' > "$D/blob.bin"
run env ASSEMBLE_DENYLIST_FILE="$DL" bash "$BS/denylist-scan.sh" "$D"
expect_rc "a listed binary file is scanned as text and passes when clean" 0
printf 'a\000b the %s shipped\n' "$T_WORD" > "$D/blob.bin"
run env ASSEMBLE_DENYLIST_FILE="$DL" bash "$BS/denylist-scan.sh" "$D"
expect_rc "a listed binary file with a term in its text fails" 1

section "denylist-scan.sh: clean input passes"

D=$(mkd deny-clean)
printf 'Nothing to see here.\n' > "$D/clean.txt"
run deny "$D"
expect_rc "clean text passes" 0
expect_out "it reports clean" 'denylist: clean'

section "denylist-scan.sh: FAILS CLOSED when it has no usable denylist"

D=$(mkd deny-closed)
printf 'Nothing to see here.\n' > "$D/clean.txt"
run deny_none "$D"
expect_rc "no denylist at all: exit 2" 2
expect_out "it says it is failing closed" 'FAILING CLOSED'

run env ASSEMBLE_DENYLIST_FILE="$work/does-not-exist.txt" bash "$S/denylist-scan.sh" "$D"
expect_rc "a denylist file that is named but missing: exit 2" 2

run env ASSEMBLE_DENYLIST="" bash "$S/denylist-scan.sh" "$D"
expect_rc "an empty ASSEMBLE_DENYLIST (what CI sees on a fork): exit 2" 2

printf '# only a comment\n\n   \n' > "$work/no-terms.txt"
run env ASSEMBLE_DENYLIST_FILE="$work/no-terms.txt" bash "$S/denylist-scan.sh" "$D"
expect_rc "a denylist with no terms in it: exit 2" 2
expect_out "it says there are no terms" 'has no terms'

no_terms=$(printf '\n   \n# only a comment')
run env ASSEMBLE_DENYLIST="$no_terms" bash "$S/denylist-scan.sh" "$D"
expect_rc "an ASSEMBLE_DENYLIST with no terms in it: exit 2" 2

section "denylist-scan.sh: the other two ways to supply a denylist"

D=$(mkd deny-sources)
printf 'the %s shipped\n' "$T_WORD" > "$D/seed.txt"
run env ASSEMBLE_DENYLIST="word:$T_WORD" bash "$S/denylist-scan.sh" "$D"
expect_rc "the text in ASSEMBLE_DENYLIST (the CI route) catches a hit" 1
# This test writes and then deletes a file at the path where the real denylist lives, so it must be
# sure that HOME is the temporary folder made above.
[ "$HOME" = "$work/home" ] || { echo "selftest: HOME is not the temporary folder; stopping" >&2; exit 2; }
mkdir -p "$HOME/.config/assemble"
cp "$DL" "$HOME/.config/assemble/denylist.txt"
run deny_none "$D"
expect_rc "the default file in the home folder (the maintainer route) catches a hit" 1
rm -f "$HOME/.config/assemble/denylist.txt"

section "denylist-scan.sh: no argument scans the files git tracks"

G="$work/deny-git"
mkdir -p "$G/scripts"
cp "$S/denylist-scan.sh" "$S/denylist-allow.txt" "$S/binary-allow.txt" "$G/scripts/"
printf 'clean\n' > "$G/clean.txt"
printf 'the %s shipped\n' "$T_WORD" > "$G/untracked-bad.txt"
( cd "$G" && git init -q && git add scripts clean.txt ) > /dev/null 2>&1
run env ASSEMBLE_DENYLIST_FILE="$DL" bash "$G/scripts/denylist-scan.sh"
expect_rc "an untracked file with a term is not scanned" 0
( cd "$G" && git add untracked-bad.txt ) > /dev/null 2>&1
run env ASSEMBLE_DENYLIST_FILE="$DL" bash "$G/scripts/denylist-scan.sh"
expect_rc "once it is tracked the scan fails" 1

# ===============================================================================================
section "validate.sh: each planted frontmatter fault is caught"

# make_skill DIR: a minimal good skill (name, description, version) with the real validate.sh beside it.
make_skill() {
  rm -rf "$1"
  mkdir -p "$1/scripts" "$1/skills/assemble"
  cp "$src/scripts/validate.sh" "$1/scripts/validate.sh"
  {
    echo '---'
    echo 'name: assemble'
    echo 'description: A short description for the self-test.'
    echo 'metadata:'
    echo '  version: "1.2.3"'
    echo '---'
    echo 'Body text.'
  } > "$1/skills/assemble/SKILL.md"
  echo '1.2.3' > "$1/skills/assemble/VERSION"
}
vrun() { run bash "$1/scripts/validate.sh"; }

V="$work/validate-case"
make_skill "$V"
vrun "$V"
expect_rc "a good skill passes" 0

make_skill "$V"
awk '{ print } /^name:/ { print "bogus-key: 1" }' "$V/skills/assemble/SKILL.md" > "$V/x" && mv "$V/x" "$V/skills/assemble/SKILL.md"
vrun "$V"
expect_rc "an unknown frontmatter key: exit 1" 1
expect_out "it names the unknown key" 'unknown frontmatter key'

make_skill "$V"
echo '9.9.9' > "$V/skills/assemble/VERSION"
vrun "$V"
expect_rc "VERSION different from metadata.version: exit 1" 1
expect_out "it says they differ" 'does not equal metadata.version'

make_skill "$V"
long=$(awk 'BEGIN { for (i = 0; i < 1100; i++) printf "x" }')
awk -v d="description: $long" '/^description:/ { print d; next } { print }' "$V/skills/assemble/SKILL.md" > "$V/x" && mv "$V/x" "$V/skills/assemble/SKILL.md"
vrun "$V"
expect_rc "a description over 1024 characters: exit 1" 1
expect_out "it says the description is too long" 'description is 1100 characters (limit 1024)'

make_skill "$V"
sed 's/^name: assemble$/name: other-name/' "$V/skills/assemble/SKILL.md" > "$V/x" && mv "$V/x" "$V/skills/assemble/SKILL.md"
vrun "$V"
expect_rc "a name that differs from the folder: exit 1" 1
expect_out "it says the name does not match" 'does not match the folder name'

make_skill "$V"
awk 'BEGIN { for (i = 0; i < 305; i++) print "filler line" }' >> "$V/skills/assemble/SKILL.md"
vrun "$V"
expect_rc "a SKILL.md over 300 lines: exit 1" 1
expect_out "it says the file is too long" 'lines (limit 300)'

make_skill "$V"
rm -f "$V/skills/assemble/VERSION"
vrun "$V"
expect_rc "a missing VERSION file: exit 1" 1

# ===============================================================================================
section "the pre-push hook: installed by install-hooks.sh in a throwaway repo, pushing to a local bare remote"

H="$work/hookrepo"
R="$work/remote.git"
mkdir -p "$H"
git init -q "$H" > /dev/null 2>&1
git init -q --bare "$R" > /dev/null 2>&1
# Our own default branch name, whatever the installed git's default is.
git -C "$H" symbolic-ref HEAD refs/heads/main
git -C "$H" config user.name "Self Test"
git -C "$H" config user.email "1+selftest${AT}users.noreply.github.com"
git -C "$H" config commit.gpgsign false
git -C "$H" remote add origin "$R"
mkdir -p "$H/scripts"
cp "$S/leak-scan.sh" "$S/denylist-scan.sh" "$S/install-hooks.sh" "$S/denylist-allow.txt" "$S/binary-allow.txt" "$H/scripts/"
# The copies of the scripts stay out of the commits (they are only there to install the hook from).
echo 'scripts/' >> "$H/.git/info/exclude"
printf 'A clean readme.\n' > "$H/README.md"
git -C "$H" add README.md
git -C "$H" commit -q -m "clean start"
base=$(git -C "$H" rev-parse HEAD)

# The hook runs the scanners with this environment: the throwaway denylist only.
export ASSEMBLE_DENYLIST_FILE="$DL"

run bash "$H/scripts/install-hooks.sh"
expect_rc "install-hooks.sh installs the hook" 0
if [ -x "$H/.git/hooks/pre-push" ] && [ -f "$H/.git/assemble-hooks/leak-scan.sh" ]; then
  pass "the hook and the trusted scanner copies are in place"
else
  fail "the hook and the trusted scanner copies are in place"
fi

remote_tip() { git --git-dir="$R" rev-parse --verify -q "refs/heads/$1" 2> /dev/null || echo "none"; }
hpush() { run git -C "$H" push "$@"; }

hpush -u origin main
expect_rc "a clean push goes through" 0
expect_out "the hook says it scanned and found nothing" 'scanned, clean'
if [ "$(remote_tip main)" = "$base" ]; then pass "the remote received the commit"; else fail "the remote received the commit"; fi

# A committed leak is blocked.
printf 'contact %s\n' "$bad_email" > "$H/leak.txt"
git -C "$H" add leak.txt
git -C "$H" commit -q -m "add a leak"
leak_commit=$(git -C "$H" rev-parse HEAD)
hpush origin main
expect_rc "a committed email leak blocks the push" 1
expect_out "the hook names the leak scan" 'leak scan failed'
if [ "$(remote_tip main)" = "$base" ]; then pass "the remote did not move"; else fail "the remote did not move"; fi

# The tip is cleaned up, but the leak is still in an earlier commit that would be sent.
git -C "$H" rm -q leak.txt
git -C "$H" commit -q -m "remove the leak again"
hpush origin main
expect_rc "a leak in an earlier commit still blocks the push when the tip is clean" 1
if [ "$(remote_tip main)" = "$base" ]; then pass "the remote did not move"; else fail "the remote did not move"; fi

# A denylist hit is blocked.
git -C "$H" reset -q --hard "$base"
printf 'the %s shipped\n' "$T_WORD" > "$H/deny.txt"
git -C "$H" add deny.txt
git -C "$H" commit -q -m "add a denylisted word"
hpush origin main
expect_rc "a committed denylist hit blocks the push" 1
expect_out "the hook names the denylist scan" 'denylist scan failed'
expect_no_out "the hook output has no term in it" "$T_WORD"
if [ "$(remote_tip main)" = "$base" ]; then pass "the remote did not move"; else fail "the remote did not move"; fi

# Uncommitted files are not what the hook scans: the commits are.
git -C "$H" reset -q --hard "$base"
printf 'A clean second file.\n' > "$H/second.txt"
git -C "$H" add second.txt
git -C "$H" commit -q -m "clean second file"
printf 'contact %s\n' "$bad_email" > "$H/uncommitted-leak.txt"
printf 'A clean readme.\ncontact %s\n' "$bad_email" > "$H/README.md"
hpush origin main
expect_rc "uncommitted leaks in the working tree don't matter; the clean commit goes through" 0
rm -f "$H/uncommitted-leak.txt"
git -C "$H" checkout -q -- README.md
good=$(git -C "$H" rev-parse HEAD)
if [ "$(remote_tip main)" = "$good" ]; then pass "the remote received the clean commit"; else fail "the remote received the clean commit"; fi

# A commit whose tree has no files is skipped (an empty tree can't leak).
empty_tree=$(git -C "$H" hash-object -t tree -w /dev/null)
empty_commit=$(git -C "$H" commit-tree "$empty_tree" -m "empty tree")
hpush origin "$empty_commit:refs/heads/empty-tree"
expect_rc "a commit with an empty tree is let through" 0
expect_out "the hook says it skipped it" 'empty tree (no files)'
if [ "$(remote_tip empty-tree)" = "$empty_commit" ]; then pass "the remote received the empty-tree commit"; else fail "the remote received the empty-tree commit"; fi

# A commit in which two paths would land on one file. Built with plumbing so it works on any disk.
hex_to_bytes() { printf "$(printf '%s' "$1" | sed 's/../\\x&/g')"; }
# tree_of FILE NAME1 BLOB1 NAME2 BLOB2: writes a raw tree with two entries (it may repeat a name).
tree_of() {
  { printf '100644 %s\000' "$2"; hex_to_bytes "$3"; printf '100644 %s\000' "$4"; hex_to_bytes "$5"; } > "$1"
  git -C "$H" hash-object -t tree -w --literally "$1" 2> /dev/null
}
b1=$(printf 'one\n' | git -C "$H" hash-object -w --stdin)
b2=$(printf 'two\n' | git -C "$H" hash-object -w --stdin)

collide_tree() { # NAME TREE PATTERN TEXT...  -> pushes a commit with that tree; it must be blocked with that explanation and none of those texts
  name=$1; tree=$2; pat=$3; shift 3
  cc=$(git -C "$H" commit-tree "$tree" -m "$name" 2> /dev/null) || cc=""
  if [ -z "$cc" ]; then
    fail "$name: could not build the test commit with this git"
    return 0
  fi
  hpush origin "$cc:refs/heads/$name"
  expect_rc "$name: the push is blocked" 1
  expect_out "$name: the hook explains the collision" "$pat"
  expect_no_text "$name: the hook does not print the file names" "$@"
  if [ "$(remote_tip "$name")" = "none" ]; then pass "$name: the remote did not get the branch"; else fail "$name: the remote did not get the branch"; fi
}
collide() { # NAME TREE-OF-ARGS...  -> pushes a commit whose two top-level files may land on one file
  name=$1; shift
  tree=$(tree_of "$work/tree-$name" "$@") || tree=""
  if [ -z "$tree" ]; then
    fail "$name: could not build the test commit with this git"
    return 0
  fi
  collide_tree "$name" "$tree" 'same file as another path' dup.txt README.md readme.md caf
}
# folder_tree DIR1 DIR2: a tree with one file in each of two folders (a.md in DIR1, b.md in DIR2)
folder_tree() {
  fs1=$(printf '100644 blob %s\ta.md\n' "$b1" | git -C "$H" mktree 2> /dev/null) || return 1
  fs2=$(printf '100644 blob %s\tb.md\n' "$b2" | git -C "$H" mktree 2> /dev/null) || return 1
  printf '040000 tree %s\t%s\n040000 tree %s\t%s\n' "$fs1" "$1" "$fs2" "$2" | git -C "$H" mktree 2> /dev/null
}
collide_folders() { # NAME DIR1 DIR2 TEXT...  -> two folders whose names may land on one folder
  name=$1; fd1=$2; fd2=$3; shift 3
  tree=$(folder_tree "$fd1" "$fd2") || tree=""
  if [ -z "$tree" ]; then
    fail "$name: could not build the test commit with this git"
    return 0
  fi
  collide_tree "$name" "$tree" 'own list of paths' a.md b.md "$@"
}
collide duplicate-entry dup.txt "$b1" dup.txt "$b2"

# A folder that can't be made for a reason other than a name collision gets its own message
# (every common disk refuses a name of 300 bytes).
long_name=$(awk 'BEGIN { for (i = 0; i < 300; i++) printf "x" }')
lt=$(printf '100644 blob %s\ta.md\n' "$b1" | git -C "$H" mktree 2> /dev/null) || lt=""
lt=$(printf '040000 tree %s\t%s\n' "$lt" "$long_name" | git -C "$H" mktree 2> /dev/null) || lt=""
if [ -n "$lt" ] && cc=$(git -C "$H" commit-tree "$lt" -m "long folder name" 2> /dev/null); then
  hpush origin "$cc:refs/heads/long-folder-name"
  expect_rc "long-folder-name: the push is blocked" 1
  expect_out "long-folder-name: the hook says the folder could not be made" 'could not make a folder'
  expect_no_out "long-folder-name: it is not reported as a name collision" 'same file as another path'
  if [ "$(remote_tip long-folder-name)" = "none" ]; then pass "long-folder-name: the remote did not get the branch"; else fail "long-folder-name: the remote did not get the branch"; fi
else
  fail "long-folder-name: could not build the test commit with this git"
fi

# Control: the same word in a folder name, spelled as the denylist has it, is a hit when it is scanned.
# (So the folder cases below show a real gap if the hook let them through as "scanned, clean".)
ctl=$(folder_tree "$T_WORD" other-folder) || ctl=""
if [ -n "$ctl" ] && cc=$(git -C "$H" commit-tree "$ctl" -m "folder control" 2> /dev/null); then
  hpush origin "$cc:refs/heads/folder-control"
  expect_rc "control: a denylisted word in a folder name blocks the push" 1
  expect_out "control: the hook names the denylist scan" 'denylist scan failed'
  expect_no_out "control: the hook output has no term in it" "$T_WORD"
else
  fail "control: could not build the test commit with this git"
fi

# Two names that differ only in letter case, and two that differ only in accents (NFC vs NFD), collide
# only on a disk that ignores the difference. Test them where this disk does; say so where it does not.
# Files that collide are caught while the files are written; folders that collide (the second
# folder's files then land in the first folder, under its spelling) only by the final comparison
# with the commit's own list of paths. The made-up denylist term is in the SECOND folder name, spelled
# the way the denylist has it (the term list is case-sensitive), so without that comparison the push
# would be scanned under the first spelling and pass.
probe_ci="$work/CaseProbe"; : > "$probe_ci"
if [ -e "$work/caseprobe" ]; then ci=1; else ci=0; fi
rm -f "$probe_ci"
nfc=$(printf 'caf\303\251'); nfd=$(printf 'cafe\314\201')
: > "$work/$nfc"
if [ -e "$work/$nfd" ]; then nf=1; else nf=0; fi
rm -f "$work/$nfc"
if [ "$ci" -eq 1 ]; then
  collide letter-case README.md "$b1" readme.md "$b2"
  upper=$(printf '%s' "$T_WORD" | tr 'a-z' 'A-Z')
  collide_folders folder-letter-case "$upper" "$T_WORD" "$T_WORD" "$upper"
  # A file and a folder whose names differ only in letter case: the folder cannot be made.
  ff=$(printf '100644 blob %s\ta.md\n' "$b2" | git -C "$H" mktree 2> /dev/null) || ff=""
  ff=$(printf '100644 blob %s\tREADME\n040000 tree %s\treadme\n' "$b1" "$ff" | git -C "$H" mktree 2> /dev/null) || ff=""
  if [ -n "$ff" ]; then
    collide_tree file-and-folder "$ff" 'folder name that would land' README readme a.md
  else
    fail "file-and-folder: could not build the test commit with this git"
  fi
else
  note "skipped the letter-case collisions: this disk tells README.md and readme.md apart (the duplicate-entry test above covers the same code path)"
fi
if [ "$nf" -eq 1 ]; then
  collide accents "$nfd.txt" "$b1" "$nfc.txt" "$b2"
  collide_folders folder-accents "$nfd" "$nfc" caf
else
  note "skipped the accent collisions: this disk tells the two spellings of an accented name apart"
fi

# ===============================================================================================
section "the output never held a term"

leaked=0
for t in zorblax quuxfrob "purple walrus" flarn; do
  if grep -qi -- "$t" "$log"; then leaked=1; fi
done
if [ "$leaked" -eq 0 ]; then pass "no throwaway term appears in anything the checks printed"; else fail "a throwaway term was printed by a check"; fi
if [ -z "${ASSEMBLE_DENYLIST:-}" ] && [ "$HOME" = "$work/home" ] && [ "${ASSEMBLE_DENYLIST_FILE:-}" = "$DL" ]; then
  pass "the real denylist was never in reach (the only list was the throwaway one, and HOME was an empty folder)"
else
  fail "the environment was not isolated"
fi

printf '\n'
if [ "$fails" -gt 0 ]; then
  echo "selftest: $fails failed, $passes passed"
  exit 1
fi
echo "selftest: all $passes tests passed"
