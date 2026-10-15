# Contributing

Thanks for helping.

## Your contribution's licence (inbound = outbound)

By opening a pull request, you agree that:

1. your contribution is licensed under the MIT licence, the same licence as the rest of this
   repository (see [LICENSE](LICENSE)); and
2. to the extent your contribution ends up in files that /assemble writes into someone's project
   (for example `team/`, the CLAUDE.md block and the PR template), you dedicate any rights you
   have in that output to the public domain under CC0 1.0, on the same terms as the
   "Files the skill generates" section of [LICENSE](LICENSE).

Only contribute work you have the right to license this way.

## Keep private details out

- Examples are fictional: the project "Acme" or "Lemonade Stand", the human "Priya", the chats
  Cyrus, Vito and Bram, and paths like `/path/to/acme`.
- Never include real people, clients, projects, email addresses, home-folder paths or keys.
- Commit with your GitHub noreply email address.

## Checks

Run these before you push. All three must pass.

```
scripts/validate.sh     # skill frontmatter (also parsed as real YAML), name, description, line count, VERSION
scripts/leak-scan.sh    # emails, home-folder paths, keys, IP addresses, in file contents and file names
scripts/selftest.sh     # plants known-bad files and commits, and confirms every check above (and the pre-push hook) catches them
```

`scripts/selftest.sh` takes about ten seconds and works only in temporary copies. It never reads the
private denylist (it makes up its own throwaway one) and never prints a term.

Both scanners fail on a binary file (anything with a NUL byte, including UTF-16 text), so keep
every file UTF-8 text. `.gitattributes` checks text files out with LF line endings everywhere,
because the scripts fail with Windows line endings.

The maintainer also keeps a private denylist (`scripts/denylist-scan.sh`). CI runs it from an
encrypted secret, which GitHub doesn't pass to pull requests from forks, so on those that job
fails on purpose with "maintainer must run the local denylist". The maintainer runs it before
merging, as below.

## For maintainers

**Never run a pull request's own scripts or hooks.** A branch can change `scripts/` to print or
send the private denylist, add its own exceptions, or simply exit 0. A pull request also runs its
own copy of `.github/workflows/` and `scripts/` in CI, so if it changes either, its green checks
prove nothing: read those changes line by line yourself.

To scan a pull request, run main's copies of the scanners against a checkout of it. Both scanners
take the folder to scan, and read their exception lists from beside themselves, not from the PR:

```
git fetch origin
trusted=$(mktemp -d)
git archive origin/main scripts | tar -x -C "$trusted"
bash "$trusted/scripts/leak-scan.sh" /path/to/pr-checkout
bash "$trusted/scripts/denylist-scan.sh" /path/to/pr-checkout
```

Run `scripts/install-hooks.sh` once per clone, from an up-to-date main. It copies the scanners
into the clone's git folder and installs a pre-push hook that runs those copies on every commit a
push would send (as committed, not the working tree). Run it again whenever main's copies of
`scripts/leak-scan.sh`, `scripts/denylist-scan.sh`, `scripts/denylist-allow.txt`,
`scripts/binary-allow.txt` or `scripts/install-hooks.sh` (it holds the hook text) change.

One-time GitHub setting: protect `main` and make `validate`, `leak-scan`, `denylist` and `selftest` required
status checks, so a pull request that deletes a job can't merge green. The `denylist` check
always fails on fork pull requests (no secret), so merge those only after the trusted local run
above passes.
