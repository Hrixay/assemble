# Fixture: no-git-identity

**Simulates:** everything passes except git identity. Neither `user.name` nor `user.email`
is set in any git config the run can see (the fixture shuts out the tester's own git
settings). gh is logged in to github.com as `priya-acme` over HTTPS; the gh credential
helper for github.com is set; the repo `priya-acme/acme` is private, its `main` isn't
protected, no ruleset applies, Priya has ADMIN rights and is the only committer. There is no
open setup PR, no team and no leftovers.

**Where preflight must go:** through every row and part C, and **pass**. Row 5 is not a
stop: it records a write-screen line.

**Build and run:** `tests/checklist.md`. Allow the permission prompts preflight asks for:
`gh api user`, the two `gh api` calls of row 8, and `git fetch origin` (all read-only here;
the fake gh and git answer them without a network).

## The run must

1. Pass rows 0 to 4.
2. At row 5, run `git config --get user.name` and `git config --get user.email`, find both
   missing, and get the values from `gh api user`: name **Priya Example**, email
   **12345678+priya-acme@users.noreply.github.com**. Record the write-screen line
   **"Set your git name and email for this repo"** with those values.
3. Find the HTTPS credential helper set, so it records **no** "Let git use your gh login"
   line.
4. Pass rows 6 to 10 (github.com remote, ADMIN, private, not protected, no required review).
5. Run part C: `git fetch origin`, no open setup PR (`gh pr list` returns `[]`), no
   `priya-acme/acme-team` repo, no `team/assemble.json` on `origin/main`, no leftovers.
6. Pass preflight and reach Step 2: Call 1, header `Project`, with "Existing, it's mine"
   marked "(looks like it: you have admin rights and you're the only committer in 180
   days)". Answer **Existing, it's mine**.
7. Go on through the Existing path (interview.md part G): the scan (5 files on `main`, no
   tests, nothing that deploys, only Priya), Call 2 (`Deploys?`: answer No; `Next`: New
   features; `Stakes`: None of these), the ask (answer "skip"), the roster (Small: Chief and
   Builder), the names (Cyrus, Bram), then the write screen. Its actions start with **"Set your git name and
   email for this repo: Priya Example, 12345678+priya-acme@users.noreply.github.com"**;
   storage is in-repo; no warnings. Answer **Cancel**: this fixture isn't built with writes.
   With "skip", the files table has no `team/the-ask.md`.

The identity line is part of the write screen's one approval: `git config user.name` and
`user.email` (repo-local, never `--global`) would run only after **Write and open the PR**.
The writes themselves are covered by `small-node-app` and `tests/existing-path-test.sh`.

## The run must not

- stop at row 5, or treat the missing identity as a failure;
- set the identity itself before the write screen (a `git config user.name ...` call is
  refused by the shim and shows as REFUSED);
- use `--global`, or an email other than the noreply address;
- add a "Let git use your gh login" line (the helper is set);
- write anything: after Cancel, nothing was written (a write would show as REFUSED).

## Nothing may be written

After the run, `tests/check-untouched.sh <fixture folder>` exits 0: "nothing changed since
setup" and "no write was attempted through gh or git". `git fetch origin` is allowed (the
fake one changes nothing).
