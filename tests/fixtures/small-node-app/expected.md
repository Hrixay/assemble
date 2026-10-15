# Fixture: small-node-app

**Simulates:** an existing Node app that is Priya's own. `acme/` is a clone of the private
GitHub repo `priya-acme/acme` (Priya has admin rights; `main` isn't protected; no rulesets;
GitHub Pages off). `main` holds 78 files: `src/` (37), `test/` (35 test files), a
`package.json` whose `test`, `start` and `postinstall` scripts would leave a
`REPO-SCRIPT-RAN` canary, `.github/workflows/ci.yml`, which only runs the tests, and an
`.env.example` naming `MAIL_API_KEY` and `MAIL_FROM` (a paid email service). Only
Priya committed. No CLAUDE.md or other AI rules, no notes files, no PR template, nothing that
deploys, no open PRs and no issues. The repo has its own git name, email and gh credential
helper. After the write screen, the fake gh and git work on local bare repos under
`remotes/`, so the run touches no network.

**Where the run must go:** preflight passes, then the Existing path (interview.md part G):
the scan, Call 2, the ask, a **Standard** team (roster.md part B: a medium project that spends
money), **in-repo**, setup PR #1 on `priya-acme/acme`, and the launch lines.

**Build and run:** `tests/checklist.md`. Allow the prompts for reads (`git fetch`, `gh api`,
the scan's listing command) and, after the write screen, for the writes. **The write gate:**
when the write screen is on screen, before you answer it, run
`touch "<fixture folder>/write-screen-approved"` in another terminal.

## Answers

| Question | Answer |
|---|---|
| `Project` | Existing, it's mine |
| `Deploys?` · `Next` · `Stakes` | No · New features · None of these |
| The ask (paste) | `Let people book a glazing night as well as a wheel hour. Done when both show on the booking page and the tests pass.` |
| `Stakes`, asked again on its own | Spends money |
| `Team` | Hire this team |
| Names | `Chief`: Cyrus · `Reviewer`: Vito · `Builder`: Bram |
| `Write files` | (open the gate) Write and open the PR |
| "type `/add-dir ...`" | type it, then "done" |

A second run answers **Cancel** on the write screen (no gate).

## The run must

1. **Preflight** passes rows 0 to 10 with no write-screen lines (identity and helper are set).
   Row 7: ADMIN, PRIVATE, default branch `main`, not a fork, owner is you. Row 8: not
   protected. Part C: `git fetch origin`, no open setup PR, no `priya-acme/acme-team`, no
   `team/assemble.json` on `origin/main`, no leftovers.
2. **Call 1** marks "Existing, it's mine (looks like it: you have admin rights and you're the
   only committer in 180 days)".
3. **The scan** (scan.md): says "Looking around: read-only, about a minute, I won't open
   anything secret."; runs the listing command once with `origin/main` (it prints
   `files 78`, `test files 35`, the paths `.env.example`, `.github/workflows/ci.yml`,
   `.gitignore`, `package.json`); reads `package.json` and `ci.yml` with
   `git show origin/main:<path>`; runs `git shortlog -sn --since=90.days origin/main` (one
   person), `gh pr list` (none) and `gh api repos/priya-acme/acme/pages --jq .source` (404,
   since no deploy was found). It never runs `npm` or anything from `package.json`.
4. **What it found**, at most 6 bullets, each with its evidence: about 78 files, mostly
   JavaScript; a test suite in `test/` run by `npm test` (read, not run); CI only runs the
   tests (`ci.yml`) and nothing deploys; only Priya in 90 days, no open PRs; private, admin,
   `main` not protected; no CLAUDE.md or notes files to reuse.
5. **Call 2** in one call: `Deploys?`, `Next`, `Stakes`, with `Stakes` marking "Spends
   money (found: `.env.example` lists MAIL_API_KEY and MAIL_FROM)". No `Kind` (package.json
   makes it software), no `Use these?` (nothing to adopt).
6. **The ask**: interview.md part G4's sentence, word for word. Then the re-ask (G4): "The
   scan saw MAIL_API_KEY and MAIL_FROM in .env.example, which usually means Spends money."
   and `Stakes` again on its own. The second answer, Spends money, stands: money holds
   (`IF_MONEY`, the paid service "the email service").
7. **Roster**: "Standard (3 chats)": Chief, Reviewer, Builder (medium-sized, and the email
   service costs money; the Builder's evidence quotes `npm test` in package.json, as in
   roster.md part E); Fewer chats names "Small: the Chief and the Builder; a fresh reviewer
   helper checks each PR"; no More chats option (the evidence names nothing to add).
8. **Names**: Chief Cyrus · Celia · Cormac, Reviewer Vito · Vanya · Viggo, Builder
   Bram · Bilal · Bea.
9. **The write screen** (interview.md parts E and G7): storage "In-repo: your private repo,
   only you commit, main isn't protected and nothing deploys from it (you said so)."; the
   notebook folder `../acme-team`, a second checkout. Before it, the PR number is predicted:
   `gh api "repos/priya-acme/acme/issues?state=all&per_page=1" --jq '.[0].number'` prints
   `null`, so #1. Actions: the notebook folder on a new branch `assemble/setup-<stamp>` from
   `origin/main` ("your own checkout ... stay exactly as they are") with the `/add-dir`
   step; the setup PR on `priya-acme/acme`; the `.gitignore` line naming only
   `.claude/worktrees/`, `.env.*` and `!.env.example` (`.env` is already ignored); the
   exclude line. No repo-create, identity or `gh auth setup-git` line. Files: `CLAUDE.md`
   (create: there is none on `main`), `.gitignore` (append a marked block),
   `.github/pull_request_template.md` (create), the `team/` files, `team/roles/chief.md`,
   `reviewer.md`, `builder.md`, `team/handovers/setup-<date>.md`. No "needs your call", no
   warnings. One question: `Write files`.
10. **After "Write and open the PR"**, in git-model.md part D order: it records the checkout
    (`branch --show-current`, `rev-parse HEAD`, `status --porcelain`); `git -C <acme> fetch
    origin`; `ls-remote --heads origin assemble/setup-*`; `worktree add --no-track -b
    assemble/setup-<stamp> <acme-team> origin/main`; asks you to type `/add-dir`; writes the
    files in `acme-team`; `git -C <acme-team> add -- <paths>`, `commit ... -- <paths>`,
    `push -u origin HEAD`; the exclude command; `gh pr create --repo priya-acme/acme --base
    main --head assemble/setup-<stamp> ...`, which prints `/pull/1`.
11. **Hand-off**: three launch lines: Cyrus and Vito (`cd "<acme-team>"`, `--permission-mode
    acceptEdits`, no `--add-dir`), Bram (`cd "<acme>" && claude -w bram ... --add-dir
    "<acme-team>"`, after PR #1 merges), each with `--` before the kickoff; then the closing
    message with launch.md part E's "Existing project" wording: "To undo" is close PR #1,
    then remove the `acme-team` folder and the setup branch; "Nothing else was created". It
    never mentions deleting the GitHub repo or a `.git` folder.

## Check after the run (with `env.sh` loaded)

- `scripts/check-output.sh "<fixture>/acme-team"` passes; `grep -c '^REFUSED'
  "<fixture>/calls.log"` is 0; there is no `acme/REPO-SCRIPT-RAN`.
- In `acme/`: `git status --porcelain` is empty, `git branch --show-current` is `main`, HEAD
  is the commit it was on; no `CLAUDE.md` or `team/` until Priya pulls.
- `acme/.git/info/exclude` holds `.claude/worktrees/` once.
- `gh pr diff 1 --repo priya-acme/acme --name-only` lists exactly the write screen's files,
  and `git -C acme-team diff origin/main --numstat -- .gitignore` shows lines added, none
  removed.
- `acme-team/team/assemble.json`: `"mode": "in-repo"`, `"defaultBranch": "main"`,
  `"adopted": {}`. ROSTER: Cyrus (Chief, Active), Vito (Active), Bram (Standby). CHATS.md
  has the spend guard for the email service; TASKS has the spending-limit row, the "Open
  Cyrus", "Open Vito" and "Open Bram" rows and "Pull `main` into your checkout". Compare the
  files with `tests/rendered/acme` (a Standard team, in-repo): the wording of the generated parts may
  differ, the structure may not.
- `tests/existing-path-test.sh` runs the same git and gh steps without a session.

## A fresh chat from the kickoff

Open Cyrus's and Vito's printed lines. From the kickoffs alone, Vito reviews PR #1 and posts
`## Review of PR #1: round 1 (Vito)` with its Reviewed commit; Cyrus checks the head with
`gh pr view 1 --json headRefOid,mergeable,state` before saying it's safe to click Merge.
Merge with `tests/lib/fake-gh-merge "<fixture>" 1 --repo priya-acme/acme`; Cyrus then checks
that `gh pr view 1 --json headRefOid,mergeCommit` still shows Vito's Reviewed commit as
`headRefOid` (main's new sha after the squash is expected, not a finding), runs `git fetch --prune origin && git switch --detach origin/main` and
`git branch -D` the setup branch in `acme-team`, commits the notes that waited, and hands
Priya Bram's line.

## The run must not

- run anything from `package.json`, or write anything before the gate (a write before it
  shows as REFUSED);
- read `src/` or `test/` file by file (the listing is enough), or open `.env*`;
- ask for your name, the project name or the surface;
- create a README.md, use `--global`, `git add -A`, a bare `git push` or `gh pr merge`.

## Cancel

Answer **Cancel** on the write screen, without the gate. It says "Nothing was written. ..."
and stops. `tests/check-untouched.sh "<fixture>"` exits 0.
