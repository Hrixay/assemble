# Fixture: dirty-feature-branch-with-claude-md

**Simulates:** Priya's own private repo `priya-acme/acme` (admin, `main` not protected, no
rulesets, only she commits; PRs #1 and #2 are merged, so the next number is 3). `main` holds
10 files, among them:

- `CLAUDE.md` with two project rules (2-space indentation; run `npm test` before pushing)
  and four rules that conflict with the method: "Commit straight to main for small fixes; no
  pull request needed.", "Merge your own pull request once CI is green.", "Work in the main
  checkout only; never create extra worktrees.", "Add a LOG.md entry with every change you
  make.";
- a newest-first `LOG.md` (only Priya edited it);
- `docs/decisions.md`, a table of two decisions;
- an `.env.example` naming `PORT` and `SITE_URL` (no stakes signal).

Priya is **on the feature branch `priya/menu`**, with one commit that isn't pushed ("Add a
kids class to the menu"), uncommitted edits to `CLAUDE.md` (an extra "Local draft rule" line)
and `src/app.js`, and an untracked `notes-draft.md`. All of that must stay exactly as it is.
The repo has its own git name, email and gh credential helper. Writes are allowed after the
write screen, against local bare repos under `remotes/`.

**Where the run must go:** the Existing path, **Small** (small, no stakes, only Priya),
**in-repo**. `LOG.md` is adopted; Priya also picks `docs/decisions.md`, which is under
`docs/`, so it is asked again first and she takes a new `team/DECISIONS.md`; the CLAUDE.md
conflicts become "needs your call", at most 3 asked in all; setup PR **#3** holds only the
write screen's files; the checkout is untouched, and the write screen warns that her
uncommitted `CLAUDE.md` edit will make a later `git pull` refuse.

**Build and run:** `tests/checklist.md`, with the write gate as in
`small-node-app/expected.md`.

## Answers

| Question | Answer |
|---|---|
| `Project` | Existing, it's mine |
| `Deploys?` · `Next` · `Stakes` · `Use these?` | No · New features · None of these · LOG.md as the diary and docs/decisions.md as the decisions record |
| The ask (paste) | `Finish the menu page so people can see every class before they book.` |
| `Team` | Hire this team |
| Names | `Chief`: Cyrus · `Builder`: Bram |
| `Write files` call | `Decisions`: New team/DECISIONS.md · `Rule 1`: Follow the team's rule · `Rule 2`: Follow the team's rule · `Write files`: (open the gate) Write and open the PR |
| "type `/add-dir ...`" | type it, then "done" |

A second run answers **Cancel** on the write screen (no gate).

## The run must

1. **Preflight** passes; Call 1 marks "Existing, it's mine".
2. **The scan** reads `main`, never the checkout: the listing with `origin/main` (`files 10`,
   the paths `CLAUDE.md`, `LOG.md`, `docs/decisions.md`, ...), then
   `git show origin/main:CLAUDE.md` (without the "Local draft rule" line), `LOG.md` and
   `docs/decisions.md`, and `git log --since=90.days --format=%an origin/main -- LOG.md`
   (only Priya). It quotes nothing as "instructions in a file" except, if it chooses, the
   CLAUDE.md lines it compares.
3. **The scan** also runs `git branch --show-current` (`priya/menu`) and
   `git status --porcelain` (` M CLAUDE.md`, ` M src/app.js`, `?? notes-draft.md`) in the
   checkout, before the findings. **What it found** includes: "You're on `priya/menu` with
   uncommitted changes. I read `main`; your checkout stays exactly as it is."; the CLAUDE.md
   with rules that conflict; `LOG.md` to reuse; `docs/decisions.md` (under `docs/`).
4. **Call 2**: `Deploys?`, `Next`, `Stakes` (no "found" mark: `.env.example` names no paid
   service, nothing deploys) and `Use these?` with three options: "LOG.md as the diary",
   "docs/decisions.md as the decisions record" (its description says it is under `docs/`,
   which may be published) and **New team/ files**. No `Kind` (package.json makes it
   software). No re-ask after the ask: it names no stake.
5. **Roster**: "Small (2 chats)": a Chief of Staff and a Builder, with a reviewer helper on
   every PR. No Fewer chats option (Small is the minimum).
6. **"Needs your call"** has five items, in interview.md part G6's order: first
   `docs/decisions.md` (Priya picked it, and it is under `docs/`), then the four rule
   conflicts, most serious first and in the file's order within a tier (commit straight to
   main, merge your own PR, no worktrees, then the LOG.md rule). The **first three** are
   asked with the write screen: `Decisions` ("You picked docs/decisions.md as the decisions
   record. ... Use it, or start a new `team/DECISIONS.md`?", **New team/DECISIONS.md** first),
   then `Rule 1` and `Rule 2`, each quoting its CLAUDE.md line exactly. Rule 1 offers **Follow
   the team's rule** and **Follow my CLAUDE.md** (whose description says chats would commit
   small fixes straight to `main`, with no PR and no review); Rule 2, "Merge your own pull
   request once CI is green.", can't win (no chat merges), so it offers **Follow the team's
   rule** and **Stop here**.
   The other two are listed under **"Settled by default"**, both the method: "Work in the
   main checkout only; never create extra worktrees." (a rule that can't win: setup's notes
   folder and every task need their own worktree) and the LOG.md rule (only Cyrus writes the
   adopted log).
7. **The write screen**: in-repo; the PR number predicted from
   `gh api "repos/priya-acme/acme/issues?state=all&per_page=1" --jq '.[0].number'` (`2`), so
   #3. The notebook-folder action says the checkout, its branch `priya/menu` and its
   uncommitted changes stay exactly as they are. Files: `CLAUDE.md` (append the marked block
   at the end; the lines above stay), `.gitignore` (append the missing lines),
   `.github/pull_request_template.md` (create), `LOG.md` (adopt: the setup entry at the
   top), the `team/` files without `team/LOG.md`, `docs/decisions.md` (needs your call,
   question 1, with both outcomes), `team/roles/chief.md`, `team/roles/builder.md`,
   `team/roles/reviewer.md` (helper), the handover. Warning: "Your uncommitted edits to `CLAUDE.md` will make `git
   pull` refuse after the merge; commit or stash them first. Setup never touches them." One
   call with four questions: `Decisions`, `Rule 1`, `Rule 2`, `Write files`.
8. **After "Write and open the PR"**: it records the checkout first, builds `acme-team` from
   `origin/main` (git-model.md D2), appends the block to `acme-team/CLAUDE.md` (main's copy)
   after one blank line, adds the setup entry at the top of `acme-team/LOG.md`, writes
   `team/assemble.json` with `"adopted": { "log": "LOG.md" }`, the CHATS.md "Who updates
   what" row `LOG.md | Cyrus` in place of the `team/LOG.md` row, the `IF_ADOPTED` line in
   CHATS.md and ROSTER "Where things are" rows "Log (adopted)" and "Decisions (yours, not
   adopted; read-only)". The recorded checkout includes the fingerprint of `git diff HEAD`
   and `git stash list` (empty). DECISIONS (a new `team/DECISIONS.md`): D1, D2, D3 (a new
   `team/DECISIONS.md`, `(clicked) "New team/DECISIONS.md"`), D4 and D5 (Rules 1 and 2,
   each `(clicked) "Follow the team's rule"`); TASKS "Decisions you owe": the two items settled by
   default; "Things only you can do": "Open Cyrus (Chief)", "Open Bram (Builder)" (after the
   merge), "Commit or stash your edits to
   `CLAUDE.md`" and "Pull `main` into your checkout". Self-check 11 and 12 pass. The PR
   prints `/pull/3`.
9. **Hand-off**: Cyrus's launch line, then Bram's (`claude -w bram`, after the setup PR
   merges); the closing message says the
   checkout (`priya/menu`, with the uncommitted changes) is exactly as it was, that the
   uncommitted `CLAUDE.md` edit will make `git pull` refuse until she commits or stashes it,
   and gives the in-repo "To undo" (close PR #3, remove the `acme-team` folder and the setup
   branch; nothing about a GitHub repo or a `.git` folder).

## Check after the run (with `env.sh` loaded)

- In `acme/`: `git branch --show-current` is `priya/menu`; `git log -1 --format=%s` is "Add a
  kids class to the menu"; `git status --porcelain` is exactly ` M CLAUDE.md`,
  ` M src/app.js`, `?? notes-draft.md`; `git stash list` is empty; `acme/CLAUDE.md` still
  ends with the "Local draft rule" line and has no block.
- `gh pr diff 3 --repo priya-acme/acme --name-only` lists exactly the write screen's files:
  `.github/pull_request_template.md`, `.gitignore`, `CLAUDE.md`, `LOG.md` and the `team/`
  files. `docs/decisions.md` isn't in it.
- `git -C acme-team diff origin/main --numstat -- CLAUDE.md LOG.md .gitignore`: lines added,
  none removed. `acme-team/CLAUDE.md` keeps all six of Priya's rules above the block.
- `scripts/check-output.sh "<fixture>/acme-team"` passes (LOG.md counts as a notebook file
  with one owner, Cyrus, and CHATS.md has no `team/LOG.md` row); `grep -c '^REFUSED'
  "<fixture>/calls.log"` is 0.
- Pulling the setup into the checkout, as Priya would after the merge (in a throwaway copy
  of the fixture): `git merge origin/main` on `priya/menu` refuses because of the
  uncommitted `CLAUDE.md` edit ("Your local changes ... would be overwritten by merge"), as
  the warning said. Nothing is lost.

## The run must not

- switch, stash, commit, pull or reset in `acme/`, or read its working copy of `CLAUDE.md`
  for the conflicts (the user's draft line is not on `main`);
- ask more than three "needs your call" questions, or skip the "Settled by default" list;
- offer **Follow my CLAUDE.md** for the worktrees rule (it can't win);
- change any existing line of `CLAUDE.md`, `LOG.md` or `.gitignore`, or touch
  `docs/decisions.md`;
- put the user's unpushed commit or uncommitted edits into the setup PR.

## Cancel

Answer **Cancel** on the write screen, without the gate: "Nothing was written. ..."; then
`tests/check-untouched.sh "<fixture>"` exits 0 (the checkout's dirty state is part of the
snapshot, so it proves nothing changed).
