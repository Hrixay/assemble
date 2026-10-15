# Runbook: {{PROJECT}}
*How we take the steps that touch something live or can't be undone. A chat takes a step only if it is written here and {{HUMAN}} has said yes to it. The doer fills this in by PR before the first irreversible step. Anything touching this file is full tier. Nothing here is a decision (DECISIONS.md).*
*Status: skeleton, not filled in yet. Once it is, this line says "Filled in <date> (PR #<n>)". While it says skeleton, no chat takes a step that touches something live.*

## What this covers
- The live thing: <what it is, where it runs, who holds its accounts>
- The steps that can't be taken back: <each one, in one line>

## Roles for this procedure
*One row per person or chat with a part. {{HUMAN}} takes every step that needs an account, a password or money.*
| Who | Part in this procedure | Never |
|---|---|---|
| {{HUMAN}} | <says yes to each step; takes the steps that need an account> | |
| <Name> (<job>) | <prepares each step and its dry run> | <touches the live system> |
| <Name> (Reviewer) | <full-tier check of this file and of every PR that carries out a step> | |

## Before the first step
- **Backup:** <what is copied> went to <where: a branch, a folder name, a service and a name> on <date>. Restore it with <the exact command or click path>. Restore tried by <who, or "not tried yet">.
- **Dry run first:** <what a dry run looks like for this system, and what to look for in its result>.
- **Worst case:** <what is lost or broken if a step goes wrong, and how long it takes to put right>.
- **Who needs to know first:** <anyone this touches, and who tells them>.

## The steps
*In order. Stop at the first surprise. A step is "prepared" when its dry run is shown and "done live" only when it has been taken, by whoever the table names, and the live result is checked.*
| # | Step | Dry run: what we look at first | Taken by | If it goes wrong, undo with | Done when (checked live) |
|---|---|---|---|---|---|
| 1 | <step> | <what to look at> | {{HUMAN}} | <undo> | <the live check> |

## If it goes wrong
1. Stop. Don't try another route. Tell {{HUMAN}}, through {{WRITER}}, what happened and what is still intact (CHATS.md rule 16).
2. <The first undo or restore step.>
3. {{WRITER}} logs a "Correction" entry in LOG.md and updates TASKS.

## After each step
- {{WRITER}} logs "Checked live: <what, how>". Until then TASKS says "taken, not yet checked live".
- If it cost money, the actual cost, read from the provider, becomes a LOG "Spent" line.
