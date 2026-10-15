# Fixture: open-setup-pr

**Simulates:** a setup that reached its pull request and stopped there. Setup PR #1 is OPEN on
`priya-acme/acme`, opened by `priya-acme` from `assemble/setup-20261012-1435`. The notebook
folder `acme-team/` next to the project is a worktree of `acme` on that branch, holding the
setup files for **Cyrus** (Chief), **Vito** (Reviewer) and **Bram** (Builder), taken from
`tests/rendered/acme`. Priya's own checkout `acme/` is still on its two first commits, clean.
`main` has no team yet, and no leftovers exist. gh is logged in as `priya-acme`. The fake
GitHub is a set of local bare repos under `remotes/`.

**Where the run must go:** preflight passes rows 0 to 10; part C check 1 finds the open setup
PR and asks; **Continue it** goes to Step 6, part A. No interview, no Call 1. Never a second
setup PR.

**Build and run:** `tests/checklist.md`. Allow the prompts for reads. **The approval gate:**
Continue it covers part A's two small writes (recreating a missing notebook folder, the local
exclude line), so before you answer a run that needs them, run `touch "<fixture
folder>/write-screen-approved"` in another terminal; the shims refuse writes until then.

## Answers

| Run | You answer |
|---|---|
| Continue, folder present | `Setup PR`: Continue it |
| Continue, folder deleted | first `rm -rf "<fixture folder>/acme-team"`; then as above |
| Continue, a fresh clone | first clone the project somewhere else (`git clone` of `remotes/priya-acme/acme.git`, then `git remote set-url origin https://github.com/priya-acme/acme.git`), run `/assemble` there; `Setup PR`: Continue it |
| Close it and start over | `Setup PR`: Close it and start over (open the gate first); then `Leftovers`: Clean up and start over |
| Leave it and stop | `Setup PR`: Leave it and stop |

## The run must

1. **Preflight** part C, check 1: `gh pr list --repo priya-acme/acme --state open --json
   number,headRefName,url,author --limit 100` shows PR #1 with head
   `assemble/setup-20261012-1435` and author `priya-acme`. `gh repo view priya-acme/acme-team`
   fails (so there is no second list). It asks one question, header `Setup PR`: "A setup PR is
   already open (#1, opened by you). Continue it, or close it and start over?" after showing
   what closing would run: `gh pr close 1 --repo priya-acme/acme` (never `--delete-branch`).
   Options: Continue it · Close it and start over.
2. **Continue it** (rerun.md part A):
   - `gh pr view 1 --repo priya-acme/acme --json state,headRefName,headRefOid,author` says OPEN.
   - Folder present (listed, on the PR's branch): it builds nothing; `git -C acme-team status
     --short` is empty; `git -C acme-team rev-parse HEAD` equals `headRefOid`.
   - Folder deleted by hand: `git worktree list --porcelain` marks it `prunable`; it says what
     it will do, runs `git -C <acme> worktree prune`, then `git -C <acme> worktree add
     <acme-team> assemble/setup-20261012-1435` (the local branch exists), and `HEAD` equals
     `headRefOid` again.
   - Fresh clone: no folder, no local branch: `git -C <acme> worktree add --no-track -b
     assemble/setup-20261012-1435 <acme-team> origin/assemble/setup-20261012-1435`; the new
     branch has no upstream.
   - Then the local exclude line (git-model.md D4), once, and the opening steps for the surface:
     the Cyrus and Vito lines (terminal: `cd "<acme-team>" && claude -n ... --permission-mode
     acceptEdits -- "<kickoff>"`; desktop: the folder, worktree off, the mode that accepts
     edits...), Bram's marked "open after setup PR #1 merges". Every path in a kickoff exists
     (`<acme-team>/team/CHATS.md`, each `team/roles/<role>.md`).
   - It says "Setup PR #1 is still open. ... I changed nothing except <...>" and stops. It does
     not join the team.
3. **Close it and start over:** it runs `gh pr close 1 --repo priya-acme/acme` and nothing more
   on the PR; part C check 3 then finds the notebook folder (a worktree on a setup branch), the
   local setup branch and the setup branch on GitHub, shows the commands in order (`git -C
   <acme> worktree remove <acme-team>`; `git -C <acme> branch -D assemble/setup-20261012-1435`;
   `gh api -X DELETE repos/priya-acme/acme/git/refs/heads/assemble/setup-20261012-1435`), and
   asks `Leftovers`. After the yes it runs them one at a time, never `git push`, and part C
   passes. Then the interview starts: this is now an Existing repo (a stub in this version).
4. **Leave it and stop:** "Nothing was changed. Run /assemble again when you're ready."
   `tests/check-untouched.sh` exits 0.

## Check after the run (with `env.sh` loaded)

- `gh pr list --repo priya-acme/acme --state all --json number` shows only #1 (no second PR).
- Continue it: `gh pr view 1 --json headRefOid` equals `git -C acme-team rev-parse HEAD`;
  `acme/.git/info/exclude` holds `.claude/worktrees/` exactly once; `acme/` is still on `main`
  at "Add the first page" with an empty `git status --porcelain`.
- `grep -c '^REFUSED' "<fixture>/calls.log"` is 0.

## The run must not

- open a second setup PR, push, force anything or reset the notebook folder;
- delete or overwrite a folder that isn't a worktree of this project;
- close the PR on its own: closing is the user's answer to the question;
- use `--delete-branch` (it also deletes the local branch and can switch the checkout);
- ask any interview question while the setup PR is open;
- print terminal lines to a desktop user (or the desktop steps to a terminal user).
