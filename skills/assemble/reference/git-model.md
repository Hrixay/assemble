# Git model (Step 5, and every chat afterwards)

Where the notes live, the exact commands that land the setup as a pull request, and the git
habits every chat keeps. The role files carry the parts each chat needs at runtime (the
notebook write protocol, the setup-PR window, task worktrees); this file is the full picture.

## A. Two kinds of file, one writer for notes

- **Notebook files** are the team's running notes: `team/README.md`, ROSTER, LOG (and
  LOG-archive), DECISIONS, TASKS, TRIED-AND-DROPPED, the review checklist, LESSONS, GLOSSARY,
  decision briefings (`team/briefings/`), handovers, PROPOSALS (shared repos) and the adopted
  root files listed in `assemble.json` (in-repo only). **Exactly one chat ever commits them:
  the notebook writer, which is always the Chief.** They go straight to the default branch
  from the notebook folder, unreviewed, because they record what happened rather than change
  what the project does.
- **Work files** are everything else, including the rules: code, content, `team/CHATS.md`,
  `team/roles/**`, `team/PLAN.md`, `team/research/**`, `team/RUNBOOK.md`,
  `team/assemble.json`, CLAUDE.md, `.github/**`, `.claude/**`. They land only by PR: own
  branch in own worktree, then review, then the human's Merge click. The Chief's only work
  PRs are skill maintenance (setup, add, retire, repair) on `assemble/*` branches; it does
  no tasks of its own.
- Anything the human will rule on, and any result that sets a number, lands by PR (quick tier
  at least), even in a notebook-looking folder. The Chief's decision briefings are notes that
  cite only what has landed that way.
- Other chats never commit notes. The Reviewer sends checklist wording to the notebook
  writer; doers put spend and LOG lines in their PR or report; the notebook writer commits.

## B. Where the notebook lives

The **notebook folder** `<nb>` is always `../<repo>-team`: a visible folder next to the
project holding the `team/` folder. Only the repo it belongs to differs.

| Mode | When | `<nb>` is |
|---|---|---|
| **In-repo** | New path: a new project without "Touches something live". Existing path: all five conditions in scan.md part D hold (the user's own repo, private, main doesn't deploy, main not protected, nobody else committing) | a second checkout (a git worktree) of the project repo; `team/` is committed to the project's default branch |
| **Beside-repo** | Existing path: everything else, including every shared or someone else's repo. New path: a project that "Touches something live" (not offered on the New path yet: interview.md part C3 asks `Notes`) | its own repo with a private GitHub remote `<you>/<repo>-team`; nothing is committed to the project repo |

The write screen gives the reason in one line, for example "In-repo: a new private repo;
nothing deploys from main yet." or "Beside-repo, because pushing to main deploys your site
(`.github/workflows/deploy.yml`)." When unsure, beside-repo. GitHub renders
`team/README.md` when you open the `team/` folder, in either repo.

**A host connected later (in-repo):** the notebook writer's milestone check looks for a
deploy file on `origin/<default>`; if one appears, or the human mentions connecting a host,
it stops pushing notes and asks the human how to go on. A host set up from its own dashboard
leaves no file, so only the human can say so: when a live project keeps its notes in-repo,
the README Traps line and a TASKS row tell them (interview.md parts F2 and G8). Moving
between modes is manual in v1.

## C. Paths: MAIN and NB

- **MAIN**, the project's main checkout, is the path on the first `worktree` line of
  `git worktree list --porcelain`, never `git rev-parse --show-toplevel`. On the New path,
  before `git init`, it is the current folder (its full path).
- **NB** is `<parent folder of MAIN>/<repo>-team`, always built as a **full path**, never
  relative to the current folder. `<repo>` is MAIN's folder name.
- Committed files name the folder only relatively (`../<repo>-team`, or "the `<repo>-team`
  folder next to the project"). Full paths appear only in chat: kickoffs and launch lines.
- Beside-repo, inside `<nb>` the first `worktree` line is `<nb>` itself, so chats there take
  the project's path from the CLAUDE.md block's beside-repo line: `../<repo>`.

## D. Setup sequence

Run these only after the write screen's **Write and open the PR**, in this order, each
command in its own Bash call (no `&&` chains, except the one exclude command in D4). Use
only the actions the write screen listed. `<you>` is the gh login; `<name>` is the GitHub
repo name shown on the write screen (an existing repo: `<owner>/<name>` from `origin`);
`<STAMP>` is the setup branch time chosen for the write screen (`date +%Y%m%d-%H%M`);
`<default>` is the default branch: `main` on the New path, preflight's default branch on the
Existing path.

If a sandbox blocks a command (an "Operation not permitted" error, for example while making
`<nb>` outside this folder, or a network call), stop and show the error. Ask the user how to
go on: they can allow it in the sandbox settings (`/sandbox`), or approve running that one
command outside the sandbox. Never retry outside the sandbox on your own.

### D1. The project repo

**An existing repo on github.com:** only what the write screen listed:
`git -C "<MAIN>" config user.name "<name>"` and
`git -C "<MAIN>" config user.email "<id>+<login>@users.noreply.github.com"` (repo-local,
never `--global`; a worktree shares them), and `gh auth setup-git`. An empty GitHub repo
(no `origin/<default>`) also runs `git -C "<MAIN>" push -u origin "<default>"` (the
default branch only), before D2. The user's checkout is never switched, stashed, pulled or
committed to (part I).

**An existing repo with no remote:**

1. The identity and `gh auth setup-git` lines above, when listed.
2. `gh repo create <you>/<name> --private --source "<MAIN>" --remote origin`
3. `git -C "<MAIN>" push -u origin "<default>"` (the default branch only; the user's other
   branches stay on this computer). This runs the repo's pre-push hook, if it has one: the
   write screen said so.

**Empty folder:**

1. `git init -b main`
2. Only if the write screen listed it: `git config user.name "<name>"`, then
   `git config user.email "<id>+<login>@users.noreply.github.com"` (repo-local, never
   `--global`).
3. Only if the write screen listed it: `gh auth setup-git`.
4. `git commit --allow-empty -m "Start"`
5. `gh repo create <you>/<name> --private --source . --remote origin --push`

**Never create a README.md**, or any other file, in the project folder.

**Files but no git** (the user chose New project for a folder of starter files):

1. `git init -b main`, then steps 2 and 3 above.
2. `git ls-files --others --exclude-standard` lists the files git would take (it follows
   `.gitignore`).
3. Leave out `.env` and every `.env.*` (keep `.env.example`), key and credential files
   (`*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa*`, `id_ed25519*`, `id_ecdsa*`), every
   `.DS_Store`, files over 50 MB (`find . -type f -size +50M -not -path './.git/*'`), and
   anything the write screen didn't list. Never open those files; their names are enough.
   The marked `.gitignore` block ignores each of them (interview.md part F2).
4. Write the rest, one path per line, to a list file outside the project folder (in the
   system temp folder: `printenv TMPDIR`, or `/tmp`).
5. `git add --pathspec-from-file=<list file>`
6. `git commit -m "Start" --pathspec-from-file=<list file>`
7. `git status --short`: only the left-out files may remain, as untracked (`??`). Anything
   else: stop and report.
8. `gh repo create <you>/<name> --private --source . --remote origin --push`

### D2. The notebook folder, on the setup branch

**In-repo** (the New path, and the Existing path in-repo):

1. `git -C "<MAIN>" fetch origin` (if it fails with "cannot lock ref", run it once more).
2. `git -C "<MAIN>" ls-remote --heads origin "assemble/setup-*"`. If the same branch name is
   already there, add a minute to `<STAMP>`.
3. `git -C "<MAIN>" worktree add --no-track -b assemble/setup-<STAMP> "<NB>" "origin/<default>"`.
   Without `--no-track` the branch would track `origin/<default>`: a bare `git push` would
   then error, or with `push.default=upstream` send the setup straight to the default branch
   with no PR. The new folder holds the default branch's files, whatever the user's own
   checkout is on: that is what the setup PR changes.
4. Access (desktop app: grant `<NB>` the app's way first, SKILL.md Step 2; fall back to the
   line below): say "Please type `/add-dir <NB>` and press Enter, then tell me 'done'." (with the
   full path). Wait for it. `/add-dir` gives this chat access to the folder, but it doesn't
   stop the prompts: in the default permission mode each file write may still ask, one by
   one (the write screen says so). If the user skips it, every write there needs its own
   approval.

**Beside-repo** (the notes get their own repo; nothing is committed to the project repo):

1. `git init -b main "<NB>"`.
2. Give it the project's git identity, repo-local: `git -C "<NB>" config user.name "<name>"`
   and `git -C "<NB>" config user.email "<email>"`, with the values from
   `git -C "<MAIN>" config --get user.name` and `user.email` (or the write screen's identity
   line). Repo settings don't carry over to a new repo, and without a name and email git
   makes one up from the computer's account without failing.
3. `git -C "<NB>" commit --allow-empty -m "Start"`
4. `gh repo create <you>/<repo>-team --private --source "<NB>" --remote origin --push` (the
   name the write screen showed, `-2` if it changed).
5. `git -C "<NB>" switch --no-track -c assemble/setup-<STAMP>`
6. Access, as step 4 of in-repo.

The notes repo's default branch is `main`, whatever the project uses (`{{NOTES_BRANCH}}`).

### D3. Write, check, commit, push

1. Write each file at its full path under `<NB>` (interview.md part F says what goes in
   each; the Existing path also G8). Nothing is written in MAIN.
2. `git -C "<NB>" add -- <every path you wrote>` (never `-A` or `.`).
3. Self-check (interview.md part F). Fix anything it finds and add the file again.
4. `git -C "<NB>" commit -m "Set up the team with /assemble" -- <the same paths>`
5. `git -C "<NB>" push -u origin HEAD` (never a bare `git push`).

### D4. The local exclude line (once; never committed)

Run from inside MAIN, because `git rev-parse --git-path` prints a path relative to the
current folder:

```
( cd "<MAIN>" && f="$(git rev-parse --git-path info/exclude)" && mkdir -p "$(dirname "$f")" && { grep -qxF '.claude/worktrees/' "$f" 2>/dev/null || printf '%s\n' '.claude/worktrees/' >> "$f"; } )
```

Without it, a `git add -A` in the human's checkout would add each doer worktree as an
embedded repo.

### D5. The setup PR

1. Write the PR body to a temporary file outside both folders (system temp folder). It
   follows the PR template just written: What this PR does (the team and its notes) · Why
   (D1 the team, D2 the names, and any later setup decisions) · How it was tested (the
   self-check, item by item) · Reviewer handoff (Tier: full, because it adds CLAUDE.md and
   the rules; Focus here first: `team/CHATS.md`, `team/roles/`, the CLAUDE.md block, and any
   adopted file; Deploy dependencies: none; Manual actions after merge: open the chats that
   wait for the merge, if any) · the checklist. On a public repo it carries no quotes from
   the human: their words stay in the notes.
2. In-repo: `gh pr create --repo <owner>/<name> --base "<default>" --head assemble/setup-<STAMP> --title "Set up the team with /assemble" --body-file <file>`.
   Beside-repo, run in `<NB>`: `gh pr create --repo <you>/<repo>-team --base main --head assemble/setup-<STAMP> --title "Set up the team with /assemble" --body-file <file>`.
3. The printed URL ends in the PR number. It should be the number the files say (1 in a
   repo this run created; the predicted number on an existing repo, interview.md G7). If it
   differs, change the number in every file that names it, then
   `git -C "<NB>" add -- <paths>`, `git -C "<NB>" commit -m "setup: PR number" -- <paths>`
   and `git -C "<NB>" push origin HEAD`.

### D6. If anything fails after approval

Stop at once. Say exactly what was done and what wasn't, then print the cleanup steps for
the parts that were done (print them; run none without the user's yes to the exact commands):

- an open setup PR: `gh pr close <n> --repo <the PR's repo>` (never `--delete-branch`);
- in-repo, the notebook folder: `git -C "<MAIN>" worktree remove "<NB>"` (if git refuses,
  show its message; never add `--force` on your own);
- in-repo, the setup branch: `git -C "<MAIN>" branch -D assemble/setup-<STAMP>`, and on
  GitHub `gh api -X DELETE "repos/<owner>/<name>/git/refs/heads/assemble/setup-<STAMP>"`;
- beside-repo, for the human only: "Move the folder `<NB>` to the Trash (or delete it)
  yourself" (it is its own repo, not a worktree of the project), and the notes repo
  `<you>/<repo>-team` on github.com (below);
- for the human only: a GitHub repo this run created can be deleted on github.com (the repo
  page → Settings → Delete this repository);
- for the human only, when this run ran `git init` in the project folder (the next
  /assemble would then treat it as an existing repo): "To start over, delete the `.git`
  folder inside `<folder>` yourself, after the steps above. It holds only the Start commit
  (your files stay). Delete the GitHub repo on github.com if one was made. Then run
  /assemble again."

A chat never deletes a GitHub repo or a `.git` folder, and never deletes any other folder
without the user's yes to the exact command.

**In-repo, a git hook failed** (on D2's `worktree add`, or the commit or push in `<nb>`;
nothing was merged and no PR is open): show the hook's message and what was done, then ask
one question, header `Hook`: "Your repo's git hook <name> stopped setup. Keep the notes
beside the repo instead, where your hooks don't run?" **Notes beside the repo**: "I remove
`../<repo>-team` and the setup branch (commands shown first), then show you the write
screen again for a separate notes repo" · **Stop here**: "I print the cleanup steps; fix
the hook, then run /assemble again". On the first, after the user's yes to the exact
commands, run the in-repo cleanup above (the folder holds only setup's files, so
`worktree remove` may take `--force`; the setup branch was never pushed if the hook stopped
the commit), then go back to interview.md part G7 with storage beside-repo and the reason
"your repo's git hook <name> failed on setup's <step>". That screen is a new approval.

## E. After setup

- **The setup-PR window.** D1 (the team) and D2 (the names) ship inside the setup PR. While
  it is open, `<nb>` holds the setup branch: no sync, no notebook writes, no task branches.
  The branch name alone doesn't say the PR is still open (the human may merge before the
  notebook writer's first session), so each session starts with
  `gh pr view <n> --json state --jq .state`: `OPEN` is the window, `MERGED` goes straight
  to "After the merge". A ruling made in the window is posted as a `**Decision update:**`
  comment on the setup PR (a comment doesn't move the head, so the verdict stays valid) and
  committed as a note after the merge. Nothing else is pushed to the setup branch except
  fixes the review asks for, which need a re-review.
- **Review.** The setup PR is full tier (it adds CLAUDE.md and the rules). Standard or Full:
  the Reviewer reviews it. Small: the Chief runs the reviewer helper (roster.md part C). The
  human clicks Merge.
- **After the merge** (the notebook writer, once): when `gh pr view <n> --json state` says
  `MERGED` and `git status --short` in `<nb>` is empty (otherwise stop and tell the human):
  in-repo `git fetch --prune origin && git switch --detach "origin/<default>"`, beside-repo
  `git switch main && git pull --ff-only`; then `git branch -D assemble/setup-<STAMP>`
  (`-d` refuses after a squash or rebase merge). Then it commits the notes that waited.
  That is the last `git switch` ever run in `<nb>`. It runs `gh pr view <n> --json
  headRefOid,mergeCommit`: if no READY verdict has the PR's `headRefOid` as its Reviewed
  commit (the human merged before the review), it tells the human and gets that `headRefOid`
  reviewed now; a fix goes in a new PR on an `assemble/*` branch. The setup branch on GitHub
  stays until the human clicks **Delete branch** on the PR page (the closing message asks);
  a leftover one is harmless. The human's own checkout stays where it was until they pull
  there; no chat does it for them.
- **Order of opening:** the Chief (in `<nb>`; it reads the setup handover) → the Reviewer, if
  there is one, whose first job is the setup PR → setup merged → the doers → anyone else.

## F. Git habits and the notebook write protocol (every chat)

- **Every branch a chat creates uses `--no-track`; its first push is `git push -u origin
  HEAD`; nobody runs a bare `git push`.** The rule covers branches the skill and the chats
  create. The project's own `main`, which `gh repo create --push` set to track
  `origin/main`, is the human's and stays as it is. Beside-repo, the notes repo's own `main`
  tracks `origin/main` on purpose (`gh repo create --push` sets it, and the after-merge
  `git pull --ff-only` needs it). A check that no branch tracks the default branch covers
  only `assemble/*` and `<handle>/*` branches.
- **Every `git fetch` is retried once if it fails** ("cannot lock ref" when two worktrees
  fetch at once).
- Commit with explicit paths (`git commit -m "<message>" -- <paths>`); never `git add -A`, a
  bare `git commit`, `--amend` on a pushed commit, `--force`, or `--no-verify`.
- Nobody runs `git switch` or `git checkout` in `<nb>` after the setup merge; only the sync.
- **Notebook writes** (the notebook writer only, in `<nb>`, only after the setup PR merged):

  ```
  git fetch origin || git fetch origin        # sync 1/2 (retry once)
  git rebase --autostash origin/<default>     # sync 2/2, before editing; on a conflict: git rebase --abort, stop, tell <Human>
  # edit files under team/
  git add -- <paths>
  git commit -m "notes: <what> [skip ci]" -- <paths>
  git push origin HEAD:<default>
  # rejected: sync again and push again; 3 push attempts in all, then tell <Human> plainly.
  # The unpushed commit stays on HEAD and goes out with the next write.
  ```

  Sync at session start, right after every merge (even with nothing to write), and before
  every write. If a sync changes `CLAUDE.md` or `team/CHATS.md`, re-read them. Push after
  every notebook commit, so every branch cut from `origin/<default>` starts with the notes.
- The Reviewer shares `<nb>` but never writes there: it judges rules by
  `git show origin/<default>:team/CHATS.md` and tests only in `$TMPDIR` worktrees.

## G. Doer worktrees

All task work is done by doers; the Chief has no task worktrees.

- **Doers** (`claude -w <handle>`), step 0 of every task, in their own worktree:
  `(git fetch origin || git fetch origin) && git switch --no-track -c <handle>/T<n>-<slug> origin/<default>`.
  Never commit on `worktree-<handle>`. After a merge:
  `git fetch --prune origin && git switch --detach origin/<default> && git branch -D <handle>/T<n>-<slug>`.

## H. Who runs where

| Chat | Runs from | Commits |
|---|---|---|
| Chief (notebook writer) | `<nb>`; beside-repo with `--add-dir <MAIN>` | notes; skill-maintenance PRs on `assemble/*` |
| Reviewer | `<nb>`; beside-repo with `--add-dir <MAIN>`; tests in `$TMPDIR` worktrees | never |
| Doers | their own worktree of the project repo (`claude -w <handle>`), with `--add-dir <nb>` | their own task branches only |

The Chief and the Reviewer start in `acceptEdits` permission mode; doers keep the human's
normal mode (launch.md).

## I. Existing repos: what setup never touches

- **The user's own checkout** (MAIN) keeps its branch, its HEAD, its uncommitted changes and
  its untracked files exactly as they were. Setup reads the default branch with
  `git show "origin/<default>:<path>"` and builds everything in `<nb>`: in-repo a new worktree
  on the setup branch, beside-repo a separate repo. Nothing runs `git switch`, `checkout`,
  `stash`, `pull`, `reset` or `commit` in MAIN. The only changes under MAIN's `.git` are the
  refs `git fetch` updates, the worktree record and the local setup branch (in-repo), the
  exclude line (D4), and what D1 does when the write screen listed it: the repo-local name
  and email, and for a repo with no remote the new `origin` and `<default>`'s upstream (an
  empty GitHub repo: the upstream). `gh auth setup-git` changes git's global settings, not
  MAIN's `.git`.
- **A feature branch with uncommitted work** stays as it is. The setup PR is cut from
  `origin/<default>`, so it never carries the user's unpushed commits or edits; their branch
  takes the setup later, like any other merged change.
- **The setup PR holds only the write screen's files.** In-repo: lines added at the end of
  `CLAUDE.md` (or `.claude/CLAUDE.md`), a marked `.gitignore` block, the PR template (new,
  or a section appended to the existing one), `team/`, and new entries in adopted files.
  Beside-repo: nothing at all in the project repo.
- **Never overwrite.** A file the skill didn't create is never deleted, renamed, reformatted
  or rewritten; it is only appended to, in the places just listed.
- **Hooks.** In-repo, D2's `worktree add` (post-checkout) and the commit and push in `<nb>`
  run the project's own git hooks, because a worktree shares the repo's `.git`; D1's push of
  `<default>` runs its pre-push hook in either mode. SKILL.md hard rule 3 means no chat
  runs a hook script itself; this is the one place git runs them, for steps the user
  approved on the write screen, which warned about them. They are never skipped (no
  `--no-verify`). A failing hook stops setup; in-repo, D6 then offers notes beside the repo.
- After the merge, the human pulls into their own checkout when they choose. No chat does it.

## J. Shared and public repos

- **Push access is required.** A repo the user can only read (READ or TRIAGE) gets "not yet"
  at preflight row 7. Contributing through a fork isn't in v1.
- **Every shared repo is beside-repo** (scan.md part D: the user said so, or the owner isn't
  them and they aren't an admin). The notes, the rulings and the setup PR live in
  `<you>/<repo>-team`. Nothing about the team lands in the owners' repo except the work PRs
  themselves.
- **Work PRs go on the real repo,** from `<handle>/T<n>-<slug>` branches, and the review
  rounds happen there, **findings only**: technical findings, never the human's words, no
  `**Needs <Human>:**` text and no decision text. Rulings reach the author and the Reviewer
  by message, and DECISIONS in the notes repo is the record. The same holds on every public
  repo, the user's own included. The templates carry this on `{{IF_PUBLIC_OR_SHARED}}`
  lines (CHATS.md "How chats talk", every role file, the PR template).
- **PRs in the private notes repo** (the setup PR, doers' work under `team/`) are the
  team's own: rulings, `**Decision update:**` comments and quotes are fine there. The
  findings-only lines name the project repo (`{{REMOTE}}`) so no chat mixes the two up.
- **PR bodies** follow the project's own PR template when it has one, with the Reviewer
  handoff section from `team/pr-template.md` added below it.
- **Proposals:** anything that would change what the owners' product does goes in
  `team/PROPOSALS.md` (a notebook file), and only the human sends it to them.
- **Merging** is the owners' process: their click replaces the human's. The notebook writer
  still checks the PR head against the reviewed commit before calling a PR ready for them.

## K. The merge gate (every repo)

- **No chat runs `gh pr merge`,** in any permission mode. The human's Merge click on GitHub
  is the consent (on a shared repo, the owners').
- **Before "safe to click":** the notebook writer runs
  `gh pr view <n> --json headRefOid,mergeable,state` and checks that `headRefOid` equals the
  Reviewed commit of the newest READY verdict. If it doesn't, it asks for a re-review. Its
  message gives the short sha, so the human can check the PR page shows the same latest
  commit.
- **After the merge:** run `gh pr view <n> --json headRefOid,mergeCommit`. The PR's
  `headRefOid`, not the merge commit, must still equal the Reviewed commit of the newest READY
  verdict. A squash, merge-commit or rebase merge always gives the default branch a new sha;
  that is expected and never a finding. If `headRefOid` differs, tell the human and get the
  extra commits reviewed now. Then LOG "Merged PR #N at `<sha>`" (the merge commit), and
  TASKS, "Who's on what" and README the same turn.
- **Checked live:** when main deploys or the task touches something live, it moves to Done
  only after the live result is checked and logged "Checked live: <what, how>". Until then
  TASKS says "merged, not yet checked live". State reported after a merge is re-read from
  `origin/<default>`, never the local copy.
- **A required approving review** (preflight row 8): a PR from the user's own account can't
  approve itself, so each merge needs another person's approval or an admin bypass.
- At runtime the role files carry these steps: "Merge gate" in roles/chief.md, and the pin to
  one commit in roles/reviewer.md.
