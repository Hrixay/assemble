# Manual test checklist

A manual run script: each fixture on each surface. A fixture is a scratch project built by its
`tests/fixtures/<name>/setup.sh`, plus fake `gh`, `git` and `ssh` commands put first on PATH, so a
run never touches the network, your real GitHub account or your real SSH keys. Each fixture's
`expected.md` says what the skill must say and do, and what it may write (most fixtures: nothing).

## Before you start

1. Run the self-tests, which need no Claude session: `tests/build-fixtures.sh` builds every
   fixture, checks the fake commands answer as each `expected.md` assumes, and checks that
   `tests/check-untouched.sh` catches a write; `tests/new-path-test.sh` and
   `tests/existing-path-test.sh` run the New and Existing paths' git and gh steps end to end
   on the fakes. All three must end "all checks passed".
2. Make sure the skill you test is this checkout's: copy `skills/assemble` to your personal
   skills folder, `$HOME/.claude/skills/assemble`, replacing any older copy.

## Run one fixture (terminal)

1. Build it in a new folder:
   `tests/fixtures/<name>/setup.sh "$TMPDIR/fx-<name>"`
2. Open a **new** terminal (the fixture changes PATH and git settings in it) and run:
   `. "$TMPDIR/fx-<name>/env.sh" && cd "$TMPDIR/fx-<name>/acme" && claude`
3. In the session, check the fakes come first: type `! command -v gh git ssh`. All three
   paths must be in `$TMPDIR/fx-<name>/bin/`. If they aren't, your shell profile puts another
   folder first on PATH, so the run would test your real tools: don't count it (see "If the
   fakes aren't first" below). Then type `! printenv CLAUDE_CODE_ENTRYPOINT`: it must print
   `cli` (a real `claude` sets it, and `env.sh` sets it too, so the skill detects the terminal
   and doesn't ask "Where").
4. Type `/assemble` and answer as the table says. Allow permission prompts for read-only
   commands (`git fetch`, `gh api ...`).
5. Compare what it said and did with `tests/fixtures/<name>/expected.md`. The calls it made
   are in `$TMPDIR/fx-<name>/calls.log`.
6. Quit the session, then run `tests/check-untouched.sh "$TMPDIR/fx-<name>"`. It must exit 0.
7. Mark the cell with the date and pass or fail, then remove the folder:
   `rm -rf "$TMPDIR/fx-<name>"`.

## Fixtures

The desktop app doesn't take the fixtures' PATH changes by itself; "Desktop runs" below says how
to run a fixture there. Every `PR 8` cell in the tables is run that way, and stays marked until
someone has.

| Fixture | Simulates | Answer | Must produce (details in expected.md) | Terminal | Desktop |
|---|---|---|---|---|---|
| `no-gh` | gh not installed | none | Row 2: "The GitHub CLI (gh) isn't installed ..." with the install steps for your computer and surface; stops; no question asked | ☐ | PR 8 |
| `gh-logged-out` | gh not logged in | No | Row 3: the `gh login` question; on No, prints the `gh auth login ... --web` command and stops; no `gh auth login` in calls.log | ☐ | PR 8 |
| `gh-logged-out` | gh not logged in | Yes | Row 3: runs the login only after Yes, relays code FAKE-0000 and the device page, re-checks, says "gh still isn't logged in ..." and stops | ☐ | PR 8 |
| `no-git-identity` | no git name or email | allow prompts; `Project`: Existing, it's mine; then `Deploys?` No · `Next` New features · `Stakes` None of these (None of these again if it is asked again) · the ask: skip · `Team` Hire · names Cyrus, Bram; **Cancel** | Passes preflight; Call 1 marks Existing, it's mine; the Existing path runs to the write screen, whose first action is "Set your git name and email for this repo" (Priya Example, the noreply address); Cancel writes nothing; git config not changed | ☐ | PR 8 |
| `gitlab-remote` | origin on gitlab.com | none | Row 6: "v1 works with github.com repos only. Your remote is gitlab.com. ..."; stops; no `gh repo view` or `git fetch` | ☐ | PR 8 |
| `gitlab-remote-ssh` | origin on gitlab.com over SSH, no GitHub SSH key | none | Row 6, same message as `gitlab-remote`; stops; **no `ssh` line in calls.log** and nothing about adding a GitHub key (row 5 skips the SSH test for a non-GitHub host) | ☐ | PR 8 |
| `offline` | no network | none | Row 4: "I couldn't reach GitHub (no network, or a sandbox is blocking it). ..."; never offers a login; stops | ☐ | PR 8 |

Every row above: nothing may be written, so `tests/check-untouched.sh` exits 0 after the run.

### Re-run fixtures (they write after an approval)

`already-set-up`, `open-setup-pr` and `setup-leftovers` are built with writes, like the New path
fixtures, and use the same two extra steps ("The write gate" and "The Merge click" under "New path
fixtures" below): the gate file is the user's yes to a re-run's approval screen (or to preflight's cleanup
or Continue it), and `tests/lib/fake-gh-merge` is the Merge click. Their fake GitHub holds a
finished team, an open setup PR, or an unfinished setup. `tests/rerun-test.sh` replays the re-run
commands of `reference/rerun.md` on all three without a Claude session (add, retire, check and
repair, continue, cleanup); run it first, it must end "all checks passed". The notebook writer's
own sync (`git rebase`) is a write too, so open the gate before a run that syncs.

| Fixture | Simulates | Answer | Must produce (details in expected.md) | Terminal | Desktop |
|---|---|---|---|---|---|
| `already-set-up` | a finished team (Cyrus, Vito, Bram), setup PR merged | `/assemble check` | Preflight passes and finds the manifest; no interview; E1 to E4 (with E2b) all ok, E5 runs the release lookup itself and says "can't tell"; "Nothing was changed"; `check-untouched.sh` exits 0 | ☐ | ☐ |
| `already-set-up` | same, plus a seeded leftover branch `assemble/setup-20261010-0930` (expected.md) | `/assemble check`; `Repair`: Fix all of these (gate open) | E2b reports the branch as a problem with the two commands (`branch -D`, `gh api -X DELETE`); one approval screen; no `git push`; the merged setup PR's branch, if present, is called harmless | ☐ | ☐ |
| `already-set-up` | same, plus a seeded re-run leftover `assemble/add-dara-20261010-0800` with its working copy (expected.md) | `/assemble check`; `Repair`: Fix all of these (gate open) | E2b reports the branch as a problem; the repair removes the working copy (no `--force`), then the local branch, then the GitHub branch; no `git push` | ☐ | ☐ |
| `already-set-up` | same, plus the user's own `.github/workflows/ci.yml` with `${{ matrix.node }}` (expected.md) | `/assemble check` | E1 says ok; the run never offers to repair the workflow | ☐ | ☐ |
| `already-set-up` | same | `/assemble`; `Team`: Add someone; the Designer; Dara; (gate) Open the Add PR | PR #2 holds only `team/roles/designer.md` on `assemble/add-dara-<stamp>`, built with `--no-track` and `push -u`; `acme/` and `acme-team/` untouched; after `fake-gh-merge ... 2`: the notes commit (ROSTER, D3, LOG, TASKS, README), Dara's opening steps | ☐ | ☐ |
| `already-set-up` | same | `/assemble retire bram` (Bram is the only doer) | Stops: "Bram is the team's only doer. Add another doer first ..."; nothing written; `check-untouched.sh` exits 0 | ☐ | ☐ |
| `already-set-up` | same | after the Designer's Add has merged: `/assemble retire bram`; Later for his tasks; (gate) Retire Bram | A handover, then a PR with one RETIRED line in `team/roles/builder.md`; after the merge Bram is under Retired chats; `check-output.sh` passes | ☐ | ☐ |
| `already-set-up` | same | `/assemble retire cyrus` | No PR: the handover to a new Chief (same title), its four steps and the Chief's opening steps; nothing written | ☐ | ☐ |
| `already-set-up` | same, `FIXTURE_LATEST_RELEASE='v2.0.0'` in `fixture.conf` | `/assemble`; `Team`: Upgrade to v2.0.0 | The menu has four options; Upgrade prints the update steps and changes nothing | ☐ | ☐ |
| `open-setup-pr` | setup PR #1 open, notebook folder on its branch | `Setup PR`: Continue it | Part A: PR OPEN, folder at the PR's head, exclude line once, the opening steps; no second PR; nothing joins the team | ☐ | ☐ |
| `open-setup-pr` | same, `acme-team` deleted by hand | Continue it (gate open) | Recreated with `worktree prune` and `worktree add <acme-team> <branch>`; same head | ☐ | ☐ |
| `open-setup-pr` | same | Close it and start over; then Clean up (gate open) | `gh pr close 1` without `--delete-branch`; then the `Leftovers` question and the three cleanup commands; no `git push` | ☐ | ☐ |
| `open-setup-pr` | same | Leave it and stop | "Nothing was changed."; `check-untouched.sh` exits 0 | ☐ | ☐ |
| `setup-leftovers` | an unfinished setup: locked worktree, local and GitHub branch, no PR | Leave them and stop | Part C check 3 lists the commands; "Nothing was changed."; `check-untouched.sh` exits 0 | ☐ | ☐ |
| `setup-leftovers` | same | Clean up and start over (gate open) | `worktree unlock`, `worktree remove`, `branch -D`, `gh api -X DELETE ...`, in that order; part C then finds nothing and the run goes to Step 2 | ☐ | ☐ |

### Desktop runs

A desktop session inherits the environment the desktop app was started with. To run a fixture
there:

1. Quit the desktop app. In a new terminal run `. "$TMPDIR/fx-<name>/env.sh"`.
2. Start the app from that terminal, so it inherits the shims. On a Mac `open -a` does not pass
   the environment: run the executable inside the app bundle instead (for example
   `/Applications/Claude.app/Contents/MacOS/Claude`, but the path is your install's). Whether
   the Code tab keeps that PATH is test T17's question.
3. In the Code tab choose New session and the folder `$TMPDIR/fx-<name>/acme`. In the session
   type `! command -v gh git ssh`: all three must be in `$TMPDIR/fx-<name>/bin/`. If not, don't
   count the run.
4. Type `/assemble` and answer as the table says. The session is detected as "Desktop"; compare
   the result with `expected.md`, with the desktop wording: no terminal line, `claude --resume`
   line or `/rename` anywhere; the opening steps are `launch.md` C2 (New session, the folder, the
   worktree option, the mode that accepts edits, paste the kickoff, ask Claude to rename); no
   `claude --version` call in `calls.log`.
5. A New path fixture (`empty-dir`, `files-no-git`) on the desktop runs the same interview as the
   terminal, with no `claude --version` call, and grants the notes folder the app's way.
6. Quit the app, then run `tests/check-untouched.sh "$TMPDIR/fx-<name>"` where `expected.md` says
   nothing may be written, and mark the Desktop cell with the date and pass or fail.

### New path fixtures (they write after the write screen)

`empty-dir` and `files-no-git` are built with writes. Their fake GitHub is a set of local bare
repos under `<fixture>/remotes/`, so a run creates a repo, a notebook folder, a branch and a
pull request without touching the network. Two extra steps:

- **The write gate.** When the write screen is on screen, **before** you answer it, run
  `touch "$TMPDIR/fx-<name>/write-screen-approved"` in another terminal. Until that file
  exists the shims refuse every write, so a write before the approval shows as REFUSED.
- **The Merge click.** To merge a PR as the human would on GitHub, run
  `tests/lib/fake-gh-merge "$TMPDIR/fx-<name>" <PR number>`. It is not on the fixture's PATH,
  so the session under test can't run it, and the fake `gh pr merge` stays refused.

Instead of `check-untouched.sh`, check the result as the fixture's `expected.md` says
("Check after the run"). Cancel and stub rows still use `check-untouched.sh` (it must exit 0).
`tests/new-path-test.sh` runs the same git and gh steps without a Claude session; run it first.

| Fixture | Simulates | Answer | Must produce (details in expected.md) | Terminal | Desktop |
|---|---|---|---|---|---|
| `empty-dir` | empty folder, no git, no identity | `Project` New · the ask · `Kind` Software · `Size` Small · `Sign-off` Just me · `Stakes` None of these · `Team` Hire · names Cyrus, Bram · gate, Write | Small (Chief and Builder): identity + `gh auth setup-git` + repo lines on the write screen; writes only after the gate, in git-model.md order; private repo with an empty "Start" commit; `../acme-team` on `assemble/setup-*`; PR #1 with exactly the listed files; Cyrus's launch line (acceptEdits, `--`), then Bram's (`-w bram`, `--add-dir`, after the merge); no REFUSED line | ☐ | PR 8 |
| `empty-dir` | same | as above, but Medium · Cyrus, Vito, Bram | Standard: three launch lines (Cyrus, Vito, then Bram after the merge); ROSTER and roles have Vito | ☐ | PR 8 |
| `empty-dir` | same | Cyrus's printed line, then Vito's (Standard) | A fresh Chief (Small: runs the reviewer helper on PR #1) or Reviewer (Standard: reviews PR #1) works from the kickoff alone; after `fake-gh-merge`, Cyrus switches `acme-team` to detached `origin/main`, pushes the waiting notes and hands Priya Bram's steps | ☐ | PR 8 |
| `empty-dir` | same | `fake-gh-merge` PR #1 first, then open Cyrus's line | Cyrus's `gh pr view 1 --json state` says MERGED: it does the after-merge steps instead of the setup-PR window, tells Priya it merged with no verdict, and gets the PR's `headRefOid` reviewed | ☐ | PR 8 |
| `empty-dir` | same | Cancel on the write screen (no gate) | "Nothing was written ..."; `check-untouched.sh` exits 0 | ☐ | PR 8 |
| `files-no-git` | starter files, `.env`, a key file, a 50 MB file, no git | New · as `empty-dir` Small, then Standard | First commit of the 5 starter files by `--pathspec-from-file`; `.env`, `dev.pem`, `video.raw` never committed or opened; no `REPO-SCRIPT-RAN`; then as `empty-dir` | ☐ | PR 8 |
| `files-no-git` | same | `Project`: Existing, it's mine; Cancel on the write screen | "This folder has no git history to scan, so /assemble sets it up as a new project ..."; then the New path as above; `check-untouched.sh` exits 0 | ☐ | PR 8 |

### Existing path fixtures (they write after the write screen)

The five existing-repo fixtures are clones of a GitHub repo whose GitHub copy is a local bare
repo under `<fixture>/remotes/<owner>/acme.git`, with its facts (permission, visibility,
default branch, protection, rulesets, earlier PRs) in `<fixture>/gh-state/<owner>/acme/`.
The write gate and the Merge click work as for the New path fixtures; pass `--repo` to
`fake-gh-merge` (`--repo priya-acme/acme-team` for a notes repo's PR). Check each run with
the fixture's "Check after the run". `tests/existing-path-test.sh` runs the same git and gh
steps without a Claude session; run it first.

| Fixture | Simulates | Answer | Must produce (details in expected.md) | Terminal | Desktop |
|---|---|---|---|---|---|
| `small-node-app` | your private Node repo, 78 files with tests, CI that only tests, only you commit; `.env.example` names a mail service | `Project` Existing, mine · `Deploys?` No · `Next` New features · `Stakes` None of these · the ask · `Stakes` again: Spends money · `Team` Hire · names Cyrus, Vito, Bram · gate, Write | The scan's listing once, nothing run from package.json; `Stakes` marks Spends money "found", and after the ask it is asked again on its own; the spend guard; Standard (medium, and the email service costs money); in-repo; `../acme-team` on `assemble/setup-*` from `origin/main`; a new CLAUDE.md, the missing `.gitignore` lines, a PR template, `team/`; setup PR #1 holds only those; checkout untouched; three launch lines | ☐ | PR 8 |
| `small-node-app` | same | Cancel on the write screen | "Nothing was written ..."; `check-untouched.sh` exits 0 | ☐ | PR 8 |
| `dirty-feature-branch-with-claude-md` | on `priya/menu` with an unpushed commit and uncommitted edits; CLAUDE.md with 4 conflicting rules; LOG.md; docs/decisions.md; 2 merged PRs | `Project` Existing, mine · `Deploys?` No · `Next` New features · `Stakes` None of these · `Use these?` LOG.md and docs/decisions.md · the ask · `Team` Hire · names Cyrus, Bram · `Decisions`: New team/DECISIONS.md · Rule 1-2: Follow the team's rule · gate, Write | Reads `main`, not the checkout; Small; in-repo; 3 "needs your call" questions (docs/decisions.md first, then two rules) plus "Settled by default" (the worktrees rule, which can't win, and the LOG.md rule); the warning that the uncommitted CLAUDE.md edit will make `git pull` refuse; LOG.md adopted (manifest, owner row in place of `team/LOG.md`, setup entry at the top); block appended to main's CLAUDE.md; PR #3 holds only our files; `priya/menu`, its commit, its uncommitted changes and its (empty) stash exactly as before | ☐ | PR 8 |
| `claude-md-symlink` | CLAUDE.md is a link to AGENTS.md | `Project` Existing, mine · `Deploys?` No · `Next` Fixing · `Stakes` None of these · the ask · `Team` Hire · names Cyrus, Bram · `CLAUDE.md`: .claude/CLAUDE.md · gate, Write | Small; in-repo; the block in `.claude/CLAUDE.md` with `@../team/CHATS.md`; the link and AGENTS.md untouched; D3 records the choice | ☐ | PR 8 |
| `deploys-on-main` | your public repo; a workflow publishes on every push to main; a second committer with an open PR; `.env.example` names a mail service | `Project` Existing, mine (marked) · `Next` New features · `Stakes` Touches something live only · the ask · `Team` Hire · names Cyrus, Vito, Bram · gate, Write | No `Deploys?` question; no re-ask; the unpicked money finding in README Facts, the handover and the-ask; Standard; beside-repo with the three reasons; a new private `priya-acme/acme-team` with the project's git identity and setup PR #1 there; RUNBOOK skeleton; zero committed footprint in `priya-acme/acme` | ☐ | PR 8 |
| `shared-repo` | `maple-st/acme` (master): you can write, not admin; protected; rulesets unreadable; CODEOWNERS and the owners' PR template | `Project` Existing, shared · `Deploys?` No · `Next` Fixing · `Stakes` None of these · the ask · `Team` Hire · names Cyrus, Vito, Bram · gate, Write | The required-review warning; Standard; beside-repo, no switch offered; PROPOSALS.md; findings-only rules rendered; zero footprint in `maple-st/acme`; the closing message says the owners merge | ☐ | PR 8 |

## If the fakes aren't first

Claude Code runs commands through your shell's own setup, and some profiles put their own
folders (for example Homebrew's) at the front of PATH, ahead of the fixture's `bin/`. Then
`! command -v gh` shows your real gh. The fixture's `env.sh` also points gh at an empty
config folder, so even your real gh is logged out there and nothing reaches your account, but
the run no longer tests the fixture. Move the PATH line in your profile so it adds to the end
of PATH instead of the front for the test, or test in a user account without that line.
