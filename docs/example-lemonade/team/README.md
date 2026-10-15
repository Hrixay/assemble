# Where this stands (2026-10-16)
*Rewritten, never appended: the picture now. The summary, the stage table and "On hold" stay under 40 lines together; "Facts we rely on" and "Traps" are kept whole. History is in LOG.md; lessons are in LESSONS.md.*
Pre-order research has a first answer (demand is partly shown; nothing is decided). The new flavours page is in review on the stand's repo. The go-live runbook is in place.  ·  Now, Next and who we're waiting on: [TASKS.md](TASKS.md)

| Stage (from PLAN.md, or "No plan yet") | Status | Link |
|---|---|---|
| 1. Pre-order research | Q1 answered; Q2 and Q3 open | [research/START-HERE.md](research/START-HERE.md) |
| 2. New flavours page | In review: maple-st/lemonade PR #31 | TASKS T4 |
| 3. Committee decision on pre-orders | Not started: a proposal is drafted, not sent | [PROPOSALS.md](PROPOSALS.md) |

## On hold, to resume
*Optional: what we were doing, where it stopped, the first step to restart.*
Nothing on hold.

## Facts we rely on
*Facts, not decisions. A fact Priya gave says "from Priya, <date>".*
| Fact | Source and date | Checked by |
|---|---|---|
| Pushing to master publishes the site (no staging copy) | `.github/workflows/pages.yml`, 2026-10-12 | setup scan |
| The committee owns the repo, reviews every PR and merges by its own process | CONTRIBUTING.md, 2026-10-12 | setup scan |
| The two favourite flavours sold out before 2 pm on 5 of the last 8 Saturdays | from Priya's photos of the order notebook, 2026-10-13 | Rhea, preorders-findings.md F2, fact-checked 2026-10-14 |

### Traps
*Things that fail silently here. A mistake someone made is a lesson in LESSONS.md instead.*
- Every push to master publishes the site at once. Nothing in this team pushes there; the committee's merge does.
- The notes folder `lemonade-team` is its own repo. Nothing from `team/` goes into the stand's repo.

---
*Kept by Cyrus, the same turn as any merge, hire, retirement, block or stage change, so nobody has to ask for status.*
