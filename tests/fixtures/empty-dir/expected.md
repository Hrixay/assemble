# Fixture: empty-dir

**Simulates:** a brand-new project. The folder `acme/` is empty and not a git repo. gh is
logged in to github.com as `priya-acme` over HTTPS and knows no repo yet:
`priya-acme/acme` and `priya-acme/acme-team` don't exist. No git name, email or credential
helper is set anywhere the run can see. After the write screen, the fake gh makes repos and
pull requests on local bare repos under `remotes/`, and the fake git pushes there, so the
whole New path runs offline.

**Where the run must go:** preflight passes (row 6: an empty folder is the New path), then
Steps 2 to 5 for a new project in the terminal, ending with setup PR #1 open and the launch
lines printed.

**Build and run:** `tests/checklist.md`. Allow the prompts for reads (`gh api user`) and,
after the write screen, for the writes. **The write gate:** when the write screen is on
screen, before you answer it, run `touch "<fixture folder>/write-screen-approved"` in another
terminal. Until that file exists the shims refuse every write, which proves nothing was
written before the approval.

## Answers

| Question | Small run | Standard run |
|---|---|---|
| `Project` | New project | New project |
| The ask (paste) | the text below | the text below |
| `Kind` · `Size` · `Sign-off` · `Stakes` | Software · Small · Just me · None of these | Software · Medium · Just me · None of these |
| `Team` | Hire this team | Hire this team |
| Names | `Chief`: Cyrus · `Builder`: Bram | `Chief`: Cyrus · `Reviewer`: Vito · `Builder`: Bram |
| `Write files` | (open the gate) Write and open the PR | (open the gate) Write and open the PR |
| "type `/add-dir ...`" | type it, then "done" | type it, then "done" |

The ask, pasted as one line exactly as below (`team/the-ask.md` must keep it as one quoted
line, never re-wrapped):

```
I want a small web page for Acme, my weekend bike repair stall: opening hours, a price list and a way for neighbours to ask a question. It's for people in my street. It's done when the page works and a friend can find the hours in under ten seconds.
```

A third run answers **Cancel** on the write screen (no gate): nothing may be written.

## The run must

1. **Preflight** passes rows 0 to 10. Row 5 records two write-screen lines: "Set your git name
   and email for this repo" (Priya Example, `12345678+priya-acme@users.noreply.github.com`,
   from `gh api user`) and "Let git use your gh login (`gh auth setup-git`)". Row 6 sees an
   empty folder: the New path, with "Create private GitHub repo `priya-acme/acme` and push
   `main`". Part C has no origin: no fetch; `gh repo view priya-acme/acme-team` finds no name
   clash.
2. **Call 1**: header `Project`, with "New project" marked "(looks like it: this folder is
   empty)". It never asks for your name, the project name or the surface.
3. **The ask**: the free-text request exactly as in interview.md part C1, then **Call 2**: the
   four questions in one call, `Stakes` multi-select.
4. **Roster**: Small run: the proposal "Small (2 chats)", a Chief of Staff and a Builder, with
   their evidence (small, no stakes, only you; the work is software); the `Team` question offers
   Hire this team and More chats ("Standard: add a standing Reviewer"), no Fewer chats (Small is
   the minimum). Standard run: "Standard (3 chats)": Chief, Reviewer, Builder; Fewer chats names
   Small, and there is no More chats option (the ask's open points, where the page lives and
   how a question reaches Priya, are facts only Priya can give, not research load).
5. **Names**: header `Chief` first, with Cyrus · Celia · Cormac, then `Builder` with Bram ·
   Bilal · Bea (Standard: also `Reviewer` with Vito · Vanya · Viggo), each with its title as the
   description ("Cyrus · Acme Chief").
6. **The write screen**: settings (Priya · Acme · "Detected: Terminal" · in-repo, "a new private
   repo; nothing deploys from main yet" · `../acme-team` · the precious list · Cyrus Opus, Bram
   Sonnet, and Standard: Vito Opus); the actions in this order: the identity line, `gh auth setup-git`, the
   private repo with an empty first commit, the notebook folder with the `/add-dir` step, the
   setup PR from `assemble/setup-<YYYYMMDD-HHMM>`, the `.env` lines, the exclude line, then
   "Claude Code will ask permission for each of these commands ... Writing the files in
   `../acme-team` may also ask permission, file by file, even after `/add-dir`."; the
   files table: `CLAUDE.md`, `.gitignore`, `.github/pull_request_template.md`, the twelve
   `team/` files (LESSONS.md and GLOSSARY.md among them), `team/roles/chief.md`,
   `team/roles/builder.md`, `team/roles/reviewer.md` (Small: the helper version),
   `team/handovers/setup-<date>.md`.
7. **After "Write and open the PR"**, the writes appear in `calls.log` in git-model.md part D
   order: `git init -b main`; `git config user.name ...` and `user.email ...` (no `--global`);
   `gh auth setup-git`; `git commit --allow-empty -m Start`; `gh repo create priya-acme/acme
   --private --source . --remote origin --push`; `git -C <acme> fetch origin`;
   `git -C <acme> ls-remote --heads origin assemble/setup-*`; `git -C <acme> worktree add
   --no-track -b assemble/setup-<stamp> <acme-team> origin/main`; then it asks you to type
   `/add-dir <full path of acme-team>`; then `git -C <acme-team> add -- <paths>`,
   `commit ... -- <paths>`, `push -u origin HEAD`; the exclude command; `gh pr create --repo
   priya-acme/acme --base main --head assemble/setup-<stamp> ...`.
8. **Hand-off**: the PR URL ends `/pull/1`. The launch lines in opening order: Cyrus (Standard:
   then Vito), each starting `cd "<acme-team>" && claude -n "<title>" --model opus
   --permission-mode acceptEdits`; then Bram's, marked "Open after setup PR #1 merges", starting
   `cd "<acme>" && claude -w bram` with `--add-dir "<acme-team>"`; every one with `--` before
   the kickoff; then the closing message (launch.md part E). The chat then stops; it does not
   join the team.

## Check after the run (with `env.sh` loaded)

- `scripts/check-output.sh "<fixture>/acme-team"` passes. Run it on the notebook folder, not
  on `acme/`: the project folder stays on its "Start" commit (no `CLAUDE.md`, no `team/`)
  until Priya runs `git pull` there after the merge, so check-output fails there by design.
- `grep -c '^REFUSED' "<fixture>/calls.log"` is 0.
- In `acme/`: `git status --porcelain` is empty; `git symbolic-ref HEAD` is `refs/heads/main`;
  `git log --format=%s` is just "Start"; there is no `README.md`, `CLAUDE.md` or `team/`.
- `acme/.git/info/exclude` holds `.claude/worktrees/` once.
- `gh pr view 1 --repo priya-acme/acme --json state` says OPEN, and
  `gh pr diff 1 --repo priya-acme/acme --name-only` lists exactly the write screen's files.
- `acme-team/team/ROSTER.md`: Cyrus's and Bram's rows (Standard: and Vito's); Small also has
  "Reviewer: helper, no standing chat", and `team/roles/reviewer.md` is the helper version.
  `team/the-ask.md` quotes the ask word for word. Compare the files with
  `tests/rendered/acme-small` (Small) or `tests/rendered/acme` (Standard; its CLAUDE.md also
  holds a project's own lines above the block, which a new project doesn't have): the wording
  of the generated parts may differ, the structure may not.

## A fresh chat from the kickoff (the build plan's done-when for PR 4)

Open the printed Cyrus line in a new terminal (with `env.sh` loaded). From the kickoff alone,
with nothing explained: Cyrus does "First session", sees `git branch --show-current` print the
setup branch, doesn't sync, and (Small) runs a fresh reviewer helper on PR #1 and posts
`## Review of PR #1: round 1 (helper)` with its Reviewed commit. Standard: open Vito's line;
Vito reviews PR #1 and posts `## Review of PR #1: round 1 (Vito)`. When the verdict is READY TO
MERGE and Cyrus says it's safe, merge with `tests/lib/fake-gh-merge "<fixture>" 1`; Cyrus then
runs the after-merge steps (`git switch --detach origin/main`, `git branch -D` the setup
branch), commits the notes that waited, pushed to main, and hands Priya Bram's steps.

**Merged before Cyrus opens** (a second fresh-chat run): merge PR #1 with `fake-gh-merge`
first, then open Cyrus. It sees the setup branch, runs `gh pr view 1 --json state`, reads
`MERGED`, does the after-merge steps instead of the setup-PR window, then tells Priya the PR
merged with no verdict and gets the PR's `headRefOid` reviewed (Small: the helper; Standard: Vito).

## The run must not

- write anything before the gate (a write before it shows as REFUSED in `calls.log`);
- create a README.md, use `--global`, `git add -A`, a bare `git push` or `gh pr merge`
  (each shows as REFUSED);
- ask for your name, the project name or the surface;
- print desktop steps, or join the team after the hand-off.

## Cancel

Answer **Cancel** on the write screen, without the gate. It says "Nothing was written. ..."
and stops. `tests/check-untouched.sh "<fixture>"` exits 0.
