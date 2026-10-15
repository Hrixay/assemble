# Fixture: setup-leftovers

**Simulates:** a setup that stopped before it opened its pull request, two days ago. The
notebook folder `acme-team/` next to the project is a **locked** worktree of `acme` on
`assemble/setup-20261010-0930` (two files committed: `CLAUDE.md` and `team/README.md`); that
branch is on GitHub too; no pull request exists. `main` has no team and no manifest. Priya's
checkout is on `main`, clean. gh is logged in as `priya-acme`. The fake GitHub is a set of
local bare repos under `remotes/`.

**Where the run must go:** preflight passes rows 0 to 10; part C finds no setup PR (check 1),
no team (check 2: neither `team/assemble.json` nor `_team/assemble.json` on `origin/main`) and
**leftovers** (check 3), and asks before anything is removed. This is preflight's work: the run
does not reach Step 6 until the leftovers are gone, and then goes to Step 2.

**Build and run:** `tests/checklist.md`. Allow the prompts for reads and the cleanup commands.
**The approval gate:** the cleanup is allowed only after the user's yes to the exact commands,
so before you answer **Clean up and start over**, run `touch "<fixture folder>/write-screen-approved"`
in another terminal; the shims refuse writes until then.

## Answers

| Run | You answer |
|---|---|
| Leave them | `Leftovers`: Leave them and stop |
| Clean up | (open the gate) `Leftovers`: Clean up and start over |
| Clean up, folder deleted by hand | first `rm -rf "<fixture folder>/acme-team"`; then as above |

## The run must

1. **Part C** reads: `git fetch origin`; `gh pr list --state open` returns `[]`; `gh repo view
   priya-acme/acme-team` fails; both manifests are missing on `origin/main`. Check 3 finds, and
   lists with real paths and names: the notebook folder `acme-team` (a worktree, `locked`), the
   local branch `assemble/setup-20261010-0930`, and that branch on GitHub with no open PR. No
   notebook repo, so item 6 (for the human) does not appear.
2. **The question**, header `Leftovers`: "Leftovers from an unfinished setup: clean up and start
   over?" shown after the commands, in this order: `git -C <acme> worktree unlock <acme-team>`
   then `git -C <acme> worktree remove <acme-team>`; `git -C <acme> branch -D
   assemble/setup-20261010-0930`; `gh api -X DELETE
   "repos/priya-acme/acme/git/refs/heads/assemble/setup-20261010-0930"`. Options: Clean up and
   start over · Leave them and stop.
3. **Clean up and start over:** it runs those commands one at a time. A refusal (for example
   "contains modified or untracked files") stops it; it never adds `--force`, never runs `git
   push` (the repo's own hooks) and never `gh pr close --delete-branch`. Then part C runs again
   from the top and finds nothing, and the run goes on to Step 2 (Call 1 `Project`, with
   "Existing, it's mine" marked "looks like it": you have admin rights and you're the only
   committer; that path is a stub in this version).
4. **Folder deleted by hand:** the worktree is still locked, so `git worktree list` does not call
   it `prunable` yet; the same commands work: `unlock` makes it prunable, `remove` clears it.
5. **Leave them and stop:** "Nothing was changed. The leftovers are still there; run /assemble
   again when you want to clean them up." `tests/check-untouched.sh` exits 0.

## Check after the run (with `env.sh` loaded)

- After a cleanup: `git -C acme worktree list --porcelain` shows only the project; `git -C acme
  branch --list 'assemble/setup-*'` and `git -C acme ls-remote --heads origin 'assemble/setup-*'`
  print nothing; `acme/` is still on `main`, clean.
- `grep -c '^REFUSED' "<fixture>/calls.log"` is 0, and there is no `git push` line.

## The run must not

- remove anything before the user's yes to the exact commands;
- delete a folder that isn't a worktree of this project, or a GitHub repo;
- treat these leftovers as a team (there is no manifest) or offer the re-run menu.
