# Fixture: shared-repo

**Simulates:** someone else's repo. `acme/` is a clone of `maple-st/acme` (an organisation's
private repo; default branch **`master`**), where Priya has **WRITE** access, not admin.
`master` is protected (`branches/master` says `"protected": true`) and the rulesets can't be
read (HTTP 403). Jordan Example, of maple-st, commits there too and has an open PR (#1, from
`jordan/banner`); the repo has `.github/CODEOWNERS` and its own
`.github/pull_request_template.md`. 10 files on `master`, nothing that deploys. The repo has
its own git name, email and gh credential helper. Writes are allowed after the write screen,
against local bare repos under `remotes/`.

**Where the run must go:** the Existing path for "Existing, shared or someone else's":
**beside-repo** always (notes in a new private `priya-acme/acme-team`, never in
`maple-st/acme`), a **Standard** team (small, but shared counts as others; no stakes), the shared-repo
duty (`team/PROPOSALS.md`), findings-only review comments on the real PRs, and the owners
merge.

**Build and run:** `tests/checklist.md`, with the write gate as in
`small-node-app/expected.md`.

## Answers

| Question | Answer |
|---|---|
| `Project` | Existing, shared or someone else's |
| `Deploys?` · `Next` · `Stakes` | No · Fixing and tidying · None of these |
| The ask (paste) | `Fix the booking form's date picker on phones, then send the fix to maple-st.` |
| `Team` · Names | Hire this team · `Chief`: Cyrus · `Reviewer`: Vito · `Builder`: Bram |
| `Write files` | (open the gate) Write and open the PR |
| "type `/add-dir ...`" | type it, then "done" |

## The run must

1. **Preflight**: row 7 passes (WRITE); records owner `maple-st` (not you), PRIVATE, default
   branch `master`. Row 8: `.protected` is `true` and the rulesets call answers 403, so
   "protected: yes", with the warning "This repo may require an approving review before
   merge. ..." Call 1 marks "Existing, shared or someone else's".
2. **The scan** uses `origin/master` everywhere (listing, `git show`, `git shortlog`). It
   lists `.github/CODEOWNERS` and `.github/pull_request_template.md` (a review process and
   the owners' PR template) and finds no deploy, so it asks `Deploys?` and runs
   `gh api repos/maple-st/acme/pages --jq .source` (404).
3. **What it found**: someone else's repo (maple-st; you can write, not admin), `master`
   protected, Jordan's commits and open PR, CODEOWNERS and the owners' PR template.
4. **Call 2**: `Deploys?`, `Next`, `Stakes`; no `Use these?` (beside-repo).
5. **Roster**: "Standard (3 chats)": Chief, Reviewer and Builder; Fewer chats names "Small: the
   Chief and the Builder; a fresh reviewer helper checks each PR".
6. **The write screen**: storage "Beside-repo, because it's someone else's repo
   (`maple-st/acme`), and `master` is protected: notes never go there."; switching to
   in-repo is not offered. Actions and files as in `deploys-on-main` (notes repo with this
   repo's identity, private `priya-acme/acme-team`, setup PR there, exclude line), plus
   `team/PROPOSALS.md`, and no `team/RUNBOOK.md` (nothing live). Warnings: the
   required-review warning; Jordan Example committed here in 90 days.
7. **After "Write and open the PR"**: as `deploys-on-main` step 7, with `{{DEFAULT_BRANCH}}`
   `master` and `{{NOTES_BRANCH}}` `main`; flags `IF_BESIDE_REPO`, `IF_SHARED`,
   `IF_PUBLIC_OR_SHARED`, `IF_REVIEWER`. `team/CHATS.md` says the owners merge and
   that PR comments on `maple-st/acme` carry technical findings only, while PRs in the notes
   repo may carry rulings; `team/roles/reviewer.md` leaves "Needs Priya" and decision text
   off PRs in `maple-st/acme`; `team/pr-template.md` starts with "If the project repo has its
   own PR template, fill that one ...".
8. **Hand-off**: Cyrus's and Vito's lines both carry `--add-dir "<acme>"`; Bram's line (after
   the setup PR merges) starts `cd "<acme>" && claude -w bram`; the closing message
   adds "Work PRs go on `maple-st/acme`; review comments there carry technical findings
   only, and its owners merge."

## Check after the run (with `env.sh` loaded)

- **Zero committed footprint in `maple-st/acme`:** its bare repo's refs and `gh pr list
  --repo maple-st/acme --state all` (only Jordan's #1) are as before; `acme/` is unchanged.
- The setup PR is #1 on `priya-acme/acme-team`; `scripts/check-output.sh
  "<fixture>/acme-team"` passes; no REFUSED line.

## Later, a work PR (the fresh-chat check)

After the setup PR merges (`tests/lib/fake-gh-merge "<fixture>" 1 --repo
priya-acme/acme-team`), open Bram and have Cyrus give him a first task. Bram's step 0 cuts his
branch `bram/T1-<slug>` from `origin/master` of `maple-st/acme` in his own worktree, and he
opens the PR on `maple-st/acme` with a body that is the owners' template plus the Reviewer
handoff section. Vito's verdict comment there carries technical findings only: no quote from
Priya, no `Needs Priya` section, no decision text (those go to Cyrus by message). Cyrus checks
the head against the reviewed commit and tells Priya it's ready **for the owners** to merge; no
chat runs `gh pr merge`.

## The run must not

- create a branch, a PR, a comment or a repo under `maple-st` during setup (the fake gh
  refuses `gh repo create maple-st/...` anyway);
- offer in-repo, or ask `Use these?`;
- put Priya's words, a ruling or a `Needs Priya` section in any comment on `maple-st/acme`.

## Cancel

As in `small-node-app`: nothing written, `tests/check-untouched.sh "<fixture>"` exits 0.
