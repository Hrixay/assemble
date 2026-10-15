# Fixture: deploys-on-main

**Simulates:** Priya's own repo `priya-acme/acme` (admin, `main` not protected, no rulesets),
but **public**, with `.github/workflows/deploy.yml`, which publishes the site to GitHub
Pages (`actions/deploy-pages`) on every push to `main`. A second person, **Jordan Example**,
committed in the last 90 days and has an open PR (#1, from `jordan/banner`). 9 files on
`main`, among them an `.env.example` naming `MAIL_API_KEY` and `MAIL_FROM` (a paid email
service). git has a name and email only in the project repo's own config (no global identity),
plus the gh credential helper. Writes are allowed after the write screen, against local
bare repos under `remotes/`.

**Where the run must go:** the Existing path, a **Standard** team (main deploys, and two
people commit), **beside-repo**: a new private repo `priya-acme/acme-team` holds the notes and its
own setup PR #1. **Nothing is committed to `priya-acme/acme`**: no branch, no PR, no file.

**Build and run:** `tests/checklist.md`, with the write gate as in
`small-node-app/expected.md`.

## Answers

| Question | Answer |
|---|---|
| `Project` | Existing, it's mine |
| `Next` · `Stakes` | New features · Touches something live (Spends money left out) |
| The ask (paste) | `Add an events page and a Friday opening-hours banner.` |
| `Team` · Names | Hire this team · `Chief`: Cyrus · `Reviewer`: Vito · `Builder`: Bram |
| `Write files` | (open the gate) Write and open the PR |
| "type `/add-dir ...`" | type it, then "done" |

## The run must

1. **Preflight** passes, with the warning "this repo is public". Call 1 marks "Existing,
   it's mine (looks like it: you have admin rights; Jordan Example also committed in 180
   days)": Priya owns it, and other committers don't move the mark (they move the notes
   beside the repo instead, step 6).
2. **The scan** lists `path .github/workflows/deploy.yml`, reads it with
   `git show origin/main:.github/workflows/deploy.yml`, and finds **main deploys** (a push
   to `main` runs `actions/deploy-pages`). It doesn't run the Pages API call (a deploy was
   already found). `git shortlog -sn --since=90.days origin/main` shows two people; `gh pr
   list` shows Jordan's open PR.
3. **What it found** names the deploy (with the file), the public repo, Jordan's commits and
   open PR.
4. **Call 2**: `Next` and `Stakes` only. No `Deploys?` (a deploy file was found), no
   `Use these?` (beside-repo). `Stakes` marks "Touches something live (found:
   `.github/workflows/deploy.yml`)" and "Spends money (found: `.env.example` lists
   MAIL_API_KEY and MAIL_FROM)". Priya picks only Touches something live, so there is no
   re-ask after the ask (that is only for "None of these") and money stays off: no
   `IF_MONEY`, no spend guard. Because the scan found it, the notes say so (interview.md
   part G3): a README fact "The scan saw MAIL_API_KEY and MAIL_FROM in .env.example; Priya
   didn't pick Spends money" (checked by `setup scan`), a line in the handover's context,
   and the-ask's Stakes line "Money: not picked; the scan saw ...".
5. **Roster**: "Standard (3 chats)": Chief, Reviewer, Builder; evidence: deploys on every push
   (stakes) and two people commit (others). Fewer chats names "Small: the Chief and the
   Builder; a fresh reviewer helper checks each PR"; no More chats option.
6. **The write screen** (interview.md part G7): storage "Beside-repo, because pushing to main
   deploys your site (`.github/workflows/deploy.yml`), the repo is public, and Jordan
   Example also commits here."; notebook folder `../acme-team`, "its own private repo
   `priya-acme/acme-team`". Before it, `gh repo view priya-acme/acme-team` finds no repo.
   Actions: create the notes repo with this repo's git name and email and a private GitHub
   repo `priya-acme/acme-team`, with the `/add-dir` step ("Nothing is committed to
   `priya-acme/acme`"); the setup PR on `priya-acme/acme-team`; the exclude line. No
   `.gitignore` line for the project. Files: `CLAUDE.md` (the block with the beside-repo
   line), `.gitignore` (`.claude/worktrees/`), `team/pr-template.md`, the `team/` files,
   `team/RUNBOOK.md` (skeleton: the work touches something live), the roles, the handover;
   no `.github/` file and no `team/PROPOSALS.md`. Under the files: "Nothing is written in
   your `acme` folder or committed to `priya-acme/acme`." Warnings: the repo is public;
   Jordan Example committed here in 90 days.
7. **After "Write and open the PR"** (git-model.md D2, beside-repo): `git init -b main
   <acme-team>`; `git -C <acme-team> config user.name "Priya Example"` and `user.email
   "12345678+priya-acme@users.noreply.github.com"` (the values `git -C <acme> config --get`
   printed); `commit --allow-empty -m Start`; `gh repo create priya-acme/acme-team --private
   --source <acme-team> --remote origin --push`; `switch --no-track -c
   assemble/setup-<stamp>`; the files; add, commit, `push -u origin HEAD`; the exclude
   command in `acme`; `gh pr create --repo priya-acme/acme-team --base main --head
   assemble/setup-<stamp>` (`/pull/1`). Flags: `IF_BESIDE_REPO`, `IF_PUBLIC_OR_SHARED`,
   `IF_LIVE` (not `IF_MONEY`); the findings-only lines name `priya-acme/acme` and say PRs in
   the notes repo may carry rulings; `team/assemble.json` has `"mode": "beside-repo"` and
   `"adopted": {}`, and its
   precious list ends with `"team/RUNBOOK.md"`.
8. **Hand-off**: Cyrus and Vito lines `cd "<acme-team>" ... --add-dir "<acme>" -- ...`
   (beside-repo); Bram `cd "<acme>" && claude -w bram ... --add-dir "<acme-team>"`. The
   closing message uses the beside-repo wording ("Nothing was written or committed in
   `acme`"; to undo: close PR #1 in `priya-acme/acme-team`, move the `acme-team` folder to
   the Trash, delete the repo on github.com).

## Check after the run (with `env.sh` loaded)

- **Zero committed footprint:** `git --git-dir="<fixture>/remotes/priya-acme/acme.git"
  for-each-ref` is the same as before the run; `gh pr list --repo priya-acme/acme --state
  all` still shows only Jordan's PR #1; in `acme/`, `git status --porcelain` is empty, the
  branch is `main` and HEAD hasn't moved; there is no `acme/team/`.
- `git -C acme-team log -1 --format=%ae` is the noreply address (the identity carried over).
- `scripts/check-output.sh "<fixture>/acme-team"` passes; `grep -c '^REFUSED'
  "<fixture>/calls.log"` is 0.
- `tests/existing-path-test.sh` runs the same git and gh steps without a session.

## The run must not

- push a branch, open a PR or comment on `priya-acme/acme` during setup;
- write a `.gitignore` line, a PR template or a CLAUDE.md block in the project;
- offer to switch to in-repo: scan.md part D ("Switching") never allows it for a public repo
  with another committer;
- let the notes repo commit with an identity git made up from the computer's account.

## Cancel

As in `small-node-app`: nothing written, `tests/check-untouched.sh "<fixture>"` exits 0, and
no `priya-acme/acme-team` exists (`<fixture>/remotes/priya-acme/` holds only `acme.git`).
