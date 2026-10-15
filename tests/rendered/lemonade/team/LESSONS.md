# Lessons: Lemonade
*The one list of mistakes not to repeat. Every chat reads all of it at every session start (CHATS.md rule 1). Kept by Cyrus.*
*The same turn a mistake is found, Cyrus adds a line, even for a slip listed below, and sends each open chat "Team update: re-read LESSONS.md (L<n>)". Repeating a recorded lesson is a HIGH review finding. Something that fails silently on its own goes in README.md "Traps" instead.*

## This project's lessons
*One line per lesson, oldest first. IDs are never reused.*
| ID | Date | What went wrong | The rule now | Source |
|---|---|---|---|---|
| L1 | 2026-10-15 | A finding in the pre-order dossier gave a count from the market's stall list without saying which day the list was read, so nobody could check it again | Every count names its source and the day it was read | Vito's verdict on notes repo PR #3 (For later) |

## Slips to watch for
*Known before this project began. The Reviewer checks every PR against them too: a first slip is MED and becomes a lesson (review-checklist.md §6).*
- a chat upgrades a status itself
- a vague reply read as a yes
- a condition dropped from a yes
- a generated or build-output file edited by hand instead of its source
- facts from memory
- retry paths that drop pinned settings
- checkers with bugs of their own
- a rule file edited without being named under "Focus here first"
- a ruling recorded without what was shown and what was recommended
- work on a "Not doing" item (HIGH: goes beyond the task)
- a test or check deleted, skipped or loosened in the same PR as the change it checks
- a check that can pass without running (hard-coded, or never invoked)
- an experiment whose pass/fail rule was written after the result
- a direct commit to the default branch by anyone but Cyrus, other than adopted paths listed in `team/assemble.json`
