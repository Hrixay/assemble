#!/usr/bin/env bash
# install-hooks.sh: install a git pre-push hook that scans exactly what a push sends.
#
# For every commit the push would add to the remote (each pushed ref, every new commit on it, not
# just the tip), the hook writes that commit's files into a temporary folder straight from git's
# object store and runs the leak scan and the private denylist scan on that folder. Any hit, any
# unscannable file, or no denylist (the denylist scan fails closed) blocks the push. The working
# tree is never what gets scanned, so uncommitted edits and the checked-out branch don't matter.
#
# Trusted copies: this script copies scripts/leak-scan.sh, scripts/denylist-scan.sh,
# scripts/denylist-allow.txt and scripts/binary-allow.txt into <git folder>/assemble-hooks/, and
# the hook runs those copies, never the scripts of whatever branch is checked out. So run this
# from an up-to-date main checkout, and run it again whenever main's copies of those files change
# or this script itself changes (the hook text is written by it).
#
# Two guards inside the hook: a commit whose tree has no files is skipped with a note (an empty
# tree can't leak, and the scanners refuse to scan zero files); and a commit in which two paths
# would land on the same file or folder on this disk (names that differ only in letter case or
# accents, on a case- or accent-insensitive disk) blocks the push, because one of the two would go
# unscanned. The hook checks this twice: while writing each file, and at the end by comparing the
# files it wrote with the commit's own list of paths, byte for byte (that second check also catches
# two folders that differ only in letter case or accents).
#
# Run it once per clone. If a pre-push hook that this script didn't write is already there, or if
# core.hooksPath points outside this repository's git folder (a shared hooks folder), it stops and
# changes nothing.
#
# Usage: scripts/install-hooks.sh
# Portable bash: runs on macOS bash 3.2 and on Linux.

set -eu
LC_ALL=C
export LC_ALL

MARKER="assemble:pre-push-hook"
COPIES="leak-scan.sh denylist-scan.sh denylist-allow.txt binary-allow.txt"

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
cd "$root"
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "install-hooks: $root is not a git work tree" >&2
  exit 1
fi
common=$(CDPATH= cd -- "$(git rev-parse --git-common-dir)" && pwd -P)

# Where git looks for the hook (this respects core.hooksPath).
hook=$(git rev-parse --git-path hooks/pre-push)
case "$hook" in
  /*) ;;
  *) hook="$root/$hook" ;;
esac
hookdir=$(dirname -- "$hook")
if [ -d "$hookdir" ]; then
  hookdir_real=$(CDPATH= cd -- "$hookdir" && pwd -P)
elif [ -d "$(dirname -- "$hookdir")" ]; then
  hookdir_real="$(CDPATH= cd -- "$(dirname -- "$hookdir")" && pwd -P)/$(basename -- "$hookdir")"
else
  hookdir_real=$hookdir
fi
case "$hookdir_real/" in
  "$common"/*) ;;
  *)
    echo "install-hooks: git would look for hooks in a folder outside this repository's git folder:" >&2
    echo "  $hookdir" >&2
    echo "That is usually a shared core.hooksPath. A hook there would run for every repository, so" >&2
    echo "nothing was changed. To use this hook here, either point this repository back at its own" >&2
    echo "hooks folder (git config --local core.hooksPath \"$common/hooks\") and run this again," >&2
    echo "or add a pre-push hook to the shared folder by hand that calls this one only in this repo." >&2
    exit 1
    ;;
esac
hook="$hookdir_real/pre-push"

if [ -e "$hook" ] && ! grep -q "$MARKER" "$hook"; then
  echo "install-hooks: a pre-push hook that this script didn't write already exists:" >&2
  echo "  $hook" >&2
  echo "Nothing was changed. Move it aside (or merge it by hand), then run this again." >&2
  exit 1
fi

for c in $COPIES; do
  if [ ! -f "$root/scripts/$c" ]; then
    echo "install-hooks: scripts/$c is missing, so nothing was changed." >&2
    exit 1
  fi
done

branch=$(git branch --show-current 2>/dev/null || true)
head=$(git rev-parse --short HEAD 2>/dev/null || echo "no commit")
if [ "$branch" != "main" ]; then
  echo "install-hooks: warning: copying the scanners from branch \"${branch:-detached HEAD}\", not main." >&2
  echo "install-hooks: the hook trusts these copies; install from an up-to-date main when you can." >&2
fi
if [ -n "$(git status --porcelain -- scripts/ 2>/dev/null)" ]; then
  echo "install-hooks: warning: scripts/ has uncommitted changes, and they are what gets copied." >&2
fi

mkdir -p "$hookdir_real" "$common/assemble-hooks"
for c in $COPIES; do
  cp "$root/scripts/$c" "$common/assemble-hooks/$c.tmp.$$"
  mv "$common/assemble-hooks/$c.tmp.$$" "$common/assemble-hooks/$c"
done
chmod +x "$common/assemble-hooks/leak-scan.sh" "$common/assemble-hooks/denylist-scan.sh"

tmp="$hook.tmp.$$"
cat > "$tmp" <<'HOOK'
#!/usr/bin/env bash
# assemble:pre-push-hook (written by scripts/install-hooks.sh; re-run that script to update it)
# Scans every commit this push would add to the remote, as committed, with the trusted scanner
# copies in <git folder>/assemble-hooks/. Blocks the push on any hit, any unscannable file, or
# no denylist. Paths are never printed for files whose path matched; labels say "tracked path #N".
set -eu
LC_ALL=C
export LC_ALL
unset CDPATH

block() { echo "pre-push: $*" >&2; echo "pre-push: the push is blocked." >&2; exit 1; }

remote=${1:-}
remotes_arg="--remotes=$remote"
[ -n "$remote" ] || remotes_arg="--remotes"
common=$(cd -- "$(git rev-parse --git-common-dir)" && pwd -P)
trusted="$common/assemble-hooks"
for s in leak-scan.sh denylist-scan.sh; do
  [ -f "$trusted/$s" ] || block "the trusted copy $trusted/$s is missing; run scripts/install-hooks.sh from main"
done

tmp=$(mktemp -d "${TMPDIR:-/tmp}/assemble-prepush.XXXXXX") || block "could not make a temporary folder"
trap 'rm -rf "$tmp"' EXIT
: > "$tmp/done"
zero_re='^0+$'
tab=$(printf '\t')
total=0

# Said when two paths of a commit would land on one name on this disk. It never prints a name:
# $1 is the short commit id, $2 the first line, $3 a hint line that must not hold a name either.
collision() {
  echo "pre-push: commit $1: $2" >&2
  echo "pre-push: that happens when two names differ only in letter case or accents on a disk that ignores the difference," >&2
  echo "pre-push: and then one of the two would go unscanned. Rename one of them, or set TMPDIR to a folder on a" >&2
  echo "pre-push: case-sensitive disk and push again (the hook writes its scratch copy of the commit in TMPDIR)." >&2
  echo "pre-push: $3" >&2
  block "name collision in commit $1"
}

# Is something along the way to folder $1 (below the export folder $2) a file rather than a folder?
# Then two names collided. Any other reason a folder can't be made (a full disk, say) is not that.
file_in_the_way() {
  fw=$1
  while [ "$fw" != "$2" ] && [ "$fw" != "/" ] && [ "$fw" != "." ]; do
    if [ -e "$fw" ] || [ -L "$fw" ]; then
      if [ -d "$fw" ]; then return 1; fi
      return 0
    fi
    fw=$(dirname -- "$fw")
  done
  return 1
}

# Writes the files of commit $1 into folder $2, straight from the object store: no checkout,
# no filters, no export rules. A symlink becomes a file holding its target; a submodule an empty file.
# The commit's file list (git ls-tree -r -z --full-tree) must already be in $tmp/tree.
# If a file's target is already there, two paths would land on one file on this disk (names that
# differ only in letter case or accents on a case- or accent-insensitive disk, or a duplicate
# entry), so one of them would go unscanned: that blocks the push. The message gives the file's
# position in the commit's file list, never its name.
# Two folders that differ only that way become one folder, which keeps the first spelling, so their
# files are written without any file meeting another. So at the end the files on disk are compared
# with the commit's own list of paths, byte for byte, and any difference blocks the push too. (On a
# disk that rewrites accented names, such as HFS+, even a single accented name differs and blocks.)
export_commit() {
  mkdir -p "$2"
  short=$(git rev-parse --short "$1")
  idx=0
  while IFS= read -r -d '' entry; do
    idx=$((idx + 1))
    meta=${entry%%"$tab"*}
    path=${entry#*"$tab"}
    mode=${meta%% *}
    obj=${meta##* }
    case "/$path/" in
      *//*|*/./*|*/../*) block "commit $short has an unsafe path entry (file #$idx)" ;;
    esac
    pdir="$2/$(dirname -- "$path")"
    if ! mkdir -p "$pdir" 2>/dev/null; then
      if file_in_the_way "$pdir" "$2"; then
        collision "$short" "file #$idx has a folder name that would land on the same name as a file of that commit." \
          "find it with: git ls-tree -r --full-tree --name-only $short | sed -n '${idx}p'"
      fi
      block "could not make a folder for file #$idx of commit $short in $tmp (disk full, not writable, or a name too long for this disk?)"
    fi
    if [ -e "$2/$path" ] || [ -L "$2/$path" ]; then
      collision "$short" "file #$idx would land on the same file as another path of that commit." \
        "find it with: git ls-tree -r --full-tree --name-only $short | sed -n '${idx}p'"
    fi
    case "$mode" in
      160000) : > "$2/$path" ;;
      *) git cat-file blob "$obj" > "$2/$path" < /dev/null || block "could not read a file of commit $short (file #$idx)" ;;
    esac
  done < "$tmp/tree"

  # The byte-for-byte check: what is on this disk against what the commit lists.
  git ls-tree -r -z --name-only --full-tree "$1" > "$tmp/want.raw" || block "could not list the files of commit $short"
  find "$2" -type f -print0 > "$tmp/disk.raw" || block "could not list the files written for commit $short"
  while IFS= read -r -d '' f; do
    printf '%s\0' "${f#"$2"/}"
  done < "$tmp/disk.raw" > "$tmp/disk.stripped"
  sort -z "$tmp/want.raw" > "$tmp/want.sorted" || block "could not sort the file list of commit $short"
  sort -z "$tmp/disk.stripped" > "$tmp/disk.sorted" || block "could not sort the files written for commit $short"
  if ! cmp -s "$tmp/want.sorted" "$tmp/disk.sorted"; then
    collision "$short" "the files written to this disk don't match the commit's own list of paths (a folder or file name came out different)." \
      "list the commit's paths with: git ls-tree -r --full-tree --name-only $short  (look for folder names that differ only in case or accents)"
  fi
}

while read -r lref lsha rref rsha; do
  [ -n "${lsha:-}" ] || continue
  if printf '%s\n' "$lsha" | grep -Eq "$zero_re"; then
    continue                                   # deleting a remote ref sends no content
  fi
  type=$(git cat-file -t "$lsha" 2>/dev/null) || block "can't read the object being pushed to $rref"
  case "$type" in
    commit|tag) ;;
    *) block "$rref would point at a $type, which this hook can't scan" ;;
  esac
  # Commits new to this remote: reachable from what we push, not from the remote's current tip
  # (when we have it) or from any remote-tracking branch of this remote.
  if ! printf '%s\n' "$rsha" | grep -Eq "$zero_re" && git cat-file -e "$rsha^{commit}" 2>/dev/null; then
    git rev-list "$lsha" --not "$rsha" "$remotes_arg" > "$tmp/commits" || block "git rev-list failed for $rref"
  else
    git rev-list "$lsha" --not "$remotes_arg" > "$tmp/commits" || block "git rev-list failed for $rref"
  fi
  count=0
  skipped=0
  while read -r c; do
    [ -n "$c" ] || continue
    if grep -qx "$c" "$tmp/done"; then
      continue
    fi
    echo "$c" >> "$tmp/done"
    short=$(git rev-parse --short "$c")
    git ls-tree -r -z --full-tree "$c" > "$tmp/tree" || block "could not list the files of commit $short"
    if [ ! -s "$tmp/tree" ]; then
      echo "pre-push: commit $short has an empty tree (no files), so there is nothing to scan; skipped."
      skipped=$((skipped + 1))
      continue
    fi
    dir="$tmp/c-$c"
    export_commit "$c" "$dir"
    if ! bash "$trusted/leak-scan.sh" "$dir" < /dev/null > "$tmp/out" 2>&1; then
      cat "$tmp/out" >&2
      block "the leak scan failed on commit $short (labels are paths in that commit; see one with: git ls-tree -r --full-tree --name-only $short | sed -n 'Np')"
    fi
    if ! bash "$trusted/denylist-scan.sh" "$dir" < /dev/null > "$tmp/out" 2>&1; then
      cat "$tmp/out" >&2
      block "the denylist scan failed or found something on commit $short (see a \"tracked path #N\" with: git ls-tree -r --full-tree --name-only $short | sed -n 'Np')"
    fi
    rm -rf "$dir"
    count=$((count + 1))
  done < "$tmp/commits"
  total=$((total + count))
  note=""
  if [ "$skipped" -gt 0 ]; then
    note=" ($skipped empty-tree commit(s) skipped)"
  fi
  echo "pre-push: $rref: $count new commit(s) scanned, clean$note."
done

echo "pre-push: leak scan and denylist scan passed on all $total new commit(s)."
HOOK
chmod +x "$tmp"
mv "$tmp" "$hook"
echo "install-hooks: pre-push hook installed at $hook"
echo "install-hooks: trusted scanner copies in $common/assemble-hooks/ (from ${branch:-detached HEAD} at $head)"
