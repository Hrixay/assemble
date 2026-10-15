# Runbook: Lemonade
*How we take the steps that touch something live or can't be undone. A chat takes a step only if it is written here and Priya has said yes to it. The doer fills this in by PR before the first irreversible step. Anything touching this file is full tier. Nothing here is a decision (DECISIONS.md).*
*Status: Filled in 2026-10-16 (PR #4) by Dara, for publishing the new flavours page. No step has been taken yet.*

## What this covers
- The live thing: the stand's public site, maple-st/lemonade. Every push to `master` publishes it through `.github/workflows/pages.yml`, and the `CNAME` file sets its address. The committee holds the hosting and domain accounts.
- The steps that can't be taken back: a merge into `master` publishes at once, and any change to `CNAME` or `pages.yml` can take the site down or point it somewhere else.

## Roles for this procedure
*One row per person or chat with a part. Priya takes every step that needs an account, a password or money.*
| Who | Part in this procedure | Never |
|---|---|---|
| Priya | Says yes to each step. Asks the committee to review and to merge. | |
| Dara (Designer) | Prepares the change, a local preview and the PR on maple-st/lemonade. | Merges; touches `CNAME`, `pages.yml` or any account |
| Vito (Reviewer) | Full-tier check of this file and of every PR that carries out a step. | |
| Cyrus (Chief) | Checks the PR head is the reviewed commit before telling Priya it is ready for the committee. Logs "Checked live". | Runs `gh pr merge` |
| A committee member | Reviews and merges, by the committee's own process. | |

## Before the first step
- **Backup:** before step 1, Dara saves the live `flavours.html` and `css/` folder into a folder named `lemonade-before-flavours-redesign` on Priya's computer (not committed anywhere), and writes that folder name and the full id of the current `master` commit in the PR description. Restore with: the committee reverts the merge commit through a PR, or re-runs the pages workflow on the id written in the PR. Restore tried by: not tried yet.
- **Dry run first:** Dara serves the site locally (`python3 -m http.server 8123` in the project folder; her readiness note is in the description of notes repo PR #4) and opens the new page at phone and desktop widths. The PR's "Files changed" tab shows exactly what would go live. Vito reads that diff and runs the preview in a throwaway worktree. Nothing is published until a committee member merges.
- **Worst case:** customers see a broken flavours page until a revert is merged. A revert is one PR plus one workflow run, but only a committee member can merge it.
- **Who needs to know first:** the committee. Priya tells them which day the page changes; it is never a Saturday morning, while the stand is open.

## The steps
*In order. Stop at the first surprise. A step is "prepared" when its dry run is shown and "done live" only when it has been taken, by whoever the table names, and the live result is checked.*
| # | Step | Dry run: what we look at first | Taken by | If it goes wrong, undo with | Done when (checked live) |
|---|---|---|---|---|---|
| 1 | Back up the live page (see "Before the first step") | The folder exists and its `flavours.html` opens in a browser | Dara | Nothing to undo | The folder name and the commit id are in the PR description |
| 2 | Open the PR on maple-st/lemonade | "Files changed" lists only the flavours page files, with no `CNAME` and no `pages.yml` | Dara | Close the PR | Vito's verdict is READY at one commit, and Cyrus has checked the PR head is that commit |
| 3 | Committee review and merge | The preview notes in the PR, read by the reviewing committee member | A committee member, by their own process | A revert PR (Dara prepares it, a committee member merges it) | The workflow run is green and the live page shows the new design on a phone and a desktop |

## If it goes wrong
1. Stop. Don't try another route. Tell Priya, through Cyrus, what happened and what is still intact (CHATS.md rule 16).
2. Dara prepares the revert PR. Priya asks a committee member to merge it.
3. Cyrus logs a "Correction" entry in LOG.md and updates TASKS.

## After each step
- Cyrus logs "Checked live: <what, how>". Until then TASKS says "taken, not yet checked live".
- If it cost money, the actual cost, read from the provider, becomes a LOG "Spent" line.
