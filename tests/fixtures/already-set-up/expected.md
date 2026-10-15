# Fixture: already-set-up

**Simulates:** a project whose team is set up and whose setup PR was merged. Priya's private
repo `priya-acme/acme` (she owns it, only she committed) holds `CLAUDE.md` with the team block,
the PR template and `team/` for **Cyrus** (Chief), **Vito** (Reviewer) and **Bram** (Builder),
taken from `tests/rendered/acme`. Her checkout `acme/` is on `main`, pulled and clean; the
notebook folder `acme-team/` next to it is a detached worktree at `origin/main`. PR #1 is
MERGED and its branch is gone; no other PR is open. gh is logged in as `priya-acme`. The fake
GitHub is a set of local bare repos under `remotes/`, so pull requests, pushes and merges run
offline.

**Where the run must go:** preflight passes, then part C finds a manifest on `origin/main`
(check 2) and the run goes to Step 6, part B: **no interview, no Call 1.** Run it from either
folder: `acme/` (a fresh session in the project) or `acme-team/` (the Chief's own folder);
the results are the same.

**Build and run:** `tests/checklist.md`. Allow the prompts for reads (`git fetch`, `gh api`,
`gh pr view`, `git grep`, `git ls-tree`, `git rev-list`: none of them is on the skill's
pre-approved list) and, after the approval screen, for the writes. **The approval gate:** when a
re-run's approval screen is on screen, before you answer it, run
`touch "<fixture folder>/write-screen-approved"` in another terminal. Until that file exists the
shims refuse every write. The notebook writer's own routine sync (`git rebase`) is a write too:
open the gate before a run that syncs. **The Merge click:** `tests/lib/fake-gh-merge "<fixture
folder>" <PR number>`.

To see the **Upgrade** option, add the line `FIXTURE_LATEST_RELEASE='v2.0.0'` to the fixture's
`fixture.conf` before the run; without it the update check gets a 404 and says "can't tell".

**The notes are stale on purpose.** The team's notes are the hand-rendered setup-time example
(`tests/rendered/acme`), so TASKS still lists "Merge setup PR #1 ☐", README says "Setup PR #1 is
waiting for Vito's review" and LOG ends "Open: Vito reviews PR #1", although PR #1 is merged. No
after-merge notes were written. A run leaves those lines alone, except that an Add rewrites the
README summary line (rerun.md F4). The manifest's `remote` is `priya-acme/acme` and its `version`
`1.0.0`, the same as the repo and the installed skill.

**Seeded leftover (optional).** To test check E2b, push a branch `assemble/setup-20261010-0930`
to the fixture's fake GitHub (`remotes/priya-acme/acme.git`) and make it locally too, with no PR.
For a re-run that stopped, do the same with `assemble/add-dara-20261010-0800` and also make its
working copy: `git -C acme worktree add --no-track -b assemble/add-dara-20261010-0800
acme/.claude/worktrees/assemble-add-dara-20261010-0800 origin/main`.

**The user's own CI (optional).** Push `.github/workflows/ci.yml` to `main` with a line that holds
`${{ matrix.node }}` (and a runner's folder path): E1 must still say ok, and
the run must never offer to repair that file.

## Answers

| Run | You type or answer |
|---|---|
| Menu → Check | `/assemble`; `Team`: Check & repair |
| `check` typed | `/assemble check` (no menu) |
| Add a Designer | `/assemble add designer`; `Designer`: Dara; `Go ahead?`: (open the gate) Open the Add PR |
| Add, no role typed | `/assemble`; `Team`: Add someone; `Role`: the offered Designer; then as above |
| A role of your own | `/assemble add`; `Role`: A role of your own; the plain-chat message: "A Translator who translates the site into Hindi, one page per task. It never publishes without my yes. Usually writes in the translations folder. First task: the first translation pass. Label: Translator."; `Translator`: Tess; then as above |
| Retire Bram, the only doer | `/assemble retire bram` on the fixture as built |
| Retire Bram after the Add | the "Add a Designer" run first (merged), then `/assemble retire bram`; the reassignment for his three proposal tasks: Later; `Go ahead?`: (open the gate) Retire Bram |
| Retire Cyrus | `/assemble retire cyrus` |
| Upgrade | `FIXTURE_LATEST_RELEASE` set; `/assemble`; `Team`: Upgrade to v2.0.0 |
| Check with a leftover | the seeded branch above; `/assemble check`; `Repair`: Fix all of these (open the gate) |
| Cancel | any of the above, answer **Cancel** on the approval screen (no gate) |

## The run must

1. **Preflight** passes rows 0 to 10. Part C: `git fetch origin`; `gh pr list --state open`
   returns `[]`; `gh repo view priya-acme/acme-team` fails; `git show
   origin/main:team/assemble.json` succeeds. It goes to Step 6.
2. **Part B1** reads the team from `origin/main`: mode `in-repo`, the precious list, the three
   chats from the first ROSTER table (Cyrus is the notebook writer; Vito is the standing
   Reviewer), and `D3` as the next decision ID. It never asks for a name, the project name or
   the surface.
3. **The menu** (no word typed): header `Team`, "This project already has a team (Cyrus, Vito,
   Bram). What now?" with Add someone · Retire or replace someone · Check & repair, and, only
   with a newer release, Upgrade to v2.0.0. Four options at most.
4. **Check** (read-only):
   - E1: no `{{`, no home-folder path (in `team/`, the CLAUDE.md block and
     `.github/pull_request_template.md` only: never the rest of `.github`), the CLAUDE.md block
     once, one owner for each of the 8 notebook files, no RUNBOOK (so no precious check), the
     files CHATS.md rule 1 reads and each chat's role file present: all ok.
   - E2: `acme-team` is listed, not prunable, its folder exists, 0 commits behind: ok.
   - E2b: no `assemble/*` branch here or on GitHub: ok. With the seeded leftover: a problem
     (no PR), reported with its two repairs (`git -C <acme> branch -D <branch>` and `gh api -X
     DELETE repos/priya-acme/acme/git/refs/heads/<branch>`, never `git push`); the repair is one
     approval screen (findings with the exact commands, the actions, no PR needed, no warning).
     With the re-run leftover: the same, and its repair first removes the working copy
     (`git -C <acme> worktree remove <acme>/.claude/worktrees/assemble-add-dara-20261010-0800`,
     never `--force`), then `branch -D`, then the GitHub branch.
   - E3: no deploy file on `origin/main`: ok. E4: `.env` and `.env.local` are ignored, no tracked
     key file: ok.
   - E5 runs the release lookup itself when `check` was typed (no menu ran it): without a release,
     "can't tell" (a 404); with `v2.0.0`, the installed version, the newest release, and the
     update steps (terminal: `git -C ~/.assemble-src pull --ff-only`, then the `rm -rf` and `cp
     -R` lines; desktop: the download-and-copy request).
   - The report is a table; no problems, so no question and "Nothing was changed."
     `tests/check-untouched.sh` exits 0.
5. **Add a Designer:**
   - Names: header `Designer`, Dara · Dev · Dita, each with its title as the description ("Dara ·
     Acme Designer"). No name that is on the roster.
   - The approval screen shows the chat (Dara, "Dara · Acme Designer", handle `dara`, Sonnet,
     `team/roles/designer.md`, its row from roster.md part D), the evidence, the actions (when
     the chat was not started with access to `acme/`, the `/add-dir <acme>` line; the PR on
     `assemble/add-dara-<YYYYMMDD-HHMM>`; the TASKS follow-up line, a notes commit made right
     away; the notes after the merge), the files (the PR holds only the role file), the full-tier
     warning, then the question `Go ahead?`.
   - Before the screen, `calls.log` already shows the reads: `git -C <acme> fetch origin`; `gh pr
     list --repo priya-acme/acme --state open ...` (B3); `git -C <acme> ls-remote --heads origin
     assemble/add-*`, `git branch --list assemble/add-*` and `git worktree list --porcelain` (B4
     step 2, so the branch name on the screen is final). After the gate (and, for a chat without
     access, after the user types `/add-dir <acme>`) it shows, in order: `git -C <acme> worktree
     add --no-track -b assemble/add-dara-<stamp>
     <acme>/.claude/worktrees/assemble-add-dara-<stamp> origin/main`; `git -C <wt> add --
     team/roles/designer.md`; `git -C <wt> status --short` (it lists exactly `A  team/roles/designer.md`);
     `commit ... -- team/roles/designer.md`; `push -u origin HEAD`; `gh pr create --repo
     priya-acme/acme --base main --head assemble/add-dara-<stamp> --title "Add Dara, the
     Designer" --body-file ...` (the body has every heading of the repo's PR template: What this PR
     does, Why, How it was tested, Reviewer handoff with Risk, Checklist); `gh pr comment 2 ...`
     with `## Ready for review: round 1 (Cyrus)`. Vito is not open in this fixture (ListAgents
     lists no "Vito · Acme Reviewer"): the run says so, prints his opening steps (ROSTER "How to open
     each chat") and names PR #2 as waiting for his verdict; it sends nothing to any other session.
     When the chat that runs this was not started as Cyrus, it ends with the hand-off message
     (rerun.md F) and the comment says it was built for Cyrus.
   - PR #2's file list is exactly `team/roles/designer.md`. No LOG, DECISIONS or ROSTER line is
     in it. `acme/` is untouched (branch, commit, status) and so is `acme-team/` while the PR is
     open. The notebook writer adds the T-line "After PR #2 merges: ..." to TASKS "Now" (a notes
     commit pushed to main).
   - After `fake-gh-merge <fixture> 2`, part F: `gh pr view 2` says MERGED at the reviewed
     commit; the working copy and branch are removed; `acme-team` is synced; one notes commit
     (`notes: hired Dara [skip ci]`) adds Dara's ROSTER row (Standby) and her "How to open each
     chat" row (first cell "(open any time)"), `D3`, a LOG "Hired" entry with the `Shown · We
     recommended · Priya chose` line, a "Who's on what" row, a "Things only you can do" row "Open
     Dara", the first-job T-line that says Bram's T1 drafts `team/PLAN.md` (so Dara's does not),
     the follow-up line moved to Done, and updates README; E1's owner check passes; every other chat gets
     one SendMessage (or, with no other chat open, ListAgents shows none and it says so); Dara's
     opening steps are printed (terminal line with `claude -w dara`, or the desktop steps:
     New session → `acme` folder → worktree on).
6. **A role of your own:** the plain-chat questions come in one message; the role file
   `team/roles/translator.md` is filled from `templates/roles/custom.md` (no `{{`, `Type:
   doer`, the user's job and never lines, "First job: the first translation pass."); the PR is
   `assemble/add-tess-<stamp>`; the rest as for the Designer.
7. **Retire Bram, the only doer:** D1 stops with "Bram is the team's only doer. Add another doer
   first (`/assemble add <role>`), or replace Bram with a fresh chat with the same title. Nothing
   was changed." (the Chief never does the heavy work itself). `check-untouched.sh` exits 0.
   **Retire Cyrus:** no PR; it says retiring the Chief is a handover to a new Chief, lists the
   four steps (Cyrus writes and commits `team/handovers/chief-<date>.md`, the old session is
   renamed "Cyrus (old)" and archived, a fresh session takes the title "Cyrus · Acme Chief" with
   the kickoff that reads the handover first, the new Cyrus tells every chat), prints those
   opening steps and stops; nothing is written.
   **Retire Bram after the Add:** Dara is a second doer, so D1 lets it go on. D2 finds three open
   proposal tasks and no PR from a `bram/` branch. No handover from Bram is possible (he never
   opened), so Cyrus writes one "from the notes, not by Bram" as
   `team/handovers/builder-<date>.md`, a notes commit made after the yes and listed on the
   approval screen, before the PR. Run from any chat but Cyrus's, a Retire of a chat with open
   work stops at D2 ("Please run /assemble retire bram in Cyrus's chat") and changes nothing. The
   PR is
   `assemble/retire-bram-<stamp>` and changes one file: one `> **RETIRED <date>.** ...` line under
   the title of `team/roles/builder.md`. After the merge the notes move Bram's row to Retired
   chats, drop his open row, move his tasks to the user's choice, add `D<n>` and a LOG "Retired"
   entry, and tell the user to archive his session. `scripts/check-output.sh` passes on
   `acme-team`.
8. **Cancel / no answer:** "Nothing was changed." `check-untouched.sh` exits 0.

## Check after the run (with `env.sh` loaded)

- `grep -c '^REFUSED' "<fixture>/calls.log"` is 0 (on a run that wrote).
- `scripts/check-output.sh "<fixture>/acme-team"` passes after every flow.
- In `acme/`: `git status --porcelain` is empty, `git symbolic-ref HEAD` is `refs/heads/main`,
  and `git rev-parse HEAD` is the commit it had at setup (no chat pulled, switched or committed
  there). The only new thing is the folder `acme/.claude/worktrees/` while a PR is open, which
  the exclude line hides: `git status --porcelain --untracked-files=all` stays empty.
- `gh pr list --repo priya-acme/acme --state open` is empty after each flow's merge, and no
  `assemble/add-*`, `assemble/retire-*` or `assemble/repair-*` branch is left on this computer
  (`git branch --list 'assemble/*'`).

## The run must not

- ask the interview questions, `Project` (Call 1) or the names of the existing chats;
- write anything before the approval screen's yes (a write before it shows as REFUSED);
- open a second PR while one is open, build a PR by switching `acme/` or `acme-team/`, or push
  to a branch without `--no-track` and `push -u origin HEAD`;
- put a LOG, DECISIONS or ROSTER line in an Add or Retire PR;
- run `gh pr merge`, `gh pr review`, `--delete-branch`, `git add -A` or a bare `git push`
  (each shows as REFUSED);
- apply the update (`git pull` in `~/.assemble-src`, `cp`) from inside the skill: it only prints
  the steps;
- rename a role file or delete a retired chat's history.
