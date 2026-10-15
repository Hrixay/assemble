# Review checklist: Lemonade
*Kept by Cyrus; the Reviewer proposes the wording. Read it together with roles/reviewer.md.*

## §1 Before every review
Read DECISIONS (on public repos, rulings are recorded only there), LESSONS, the newest LOG entries and TASKS "Not doing", from the notebook. A reviewer helper skips LOG and reads only the three records, DECISIONS, TASKS "Not doing" and LESSONS, itself, with `git show origin/main:team/…` (before the setup PR merges, from the notebook folder). Re-list ALL PR comments, including "Decision update:". Note the Reviewed commit.

## §2 Tiers
- **full**: the diff touches the precious list (`team/assemble.json`), writes to a live system, or spends money. As many rounds as needed.
- **quick**: everything else. One round, the whole diff, HIGH and MED only; LOWs go under "For later"; no wording polish.
- The Reviewer may upgrade quick to full, and says so.

## §3 What to look for, in order
- Software: does what the task says and no more · nothing that works breaks · secrets · data loss · health checks assert outcomes, not exit codes · over-engineering
- Research: every claim marked confirmed / partly / not found · claims sourced or marked [unbacked] · numbers re-counted · nothing called decided that isn't · an experiment's pass/fail rule committed before it ran

## §4 Severity → verdict
- Any open HIGH → **CHANGES NEEDED**. Any open MED → **SMALL FIXES, THEN A QUICK RE-CHECK**. Only LOWs → **READY TO MERGE**.
- HIGH covers: content or data loss · a broken live thing · a secret leak · calling something decided that isn't · misquoting Priya · going beyond the task (including work on a "Not doing" item) · repeating a lesson recorded in LESSONS.md (basis: L<n>).

## §5 Finding format
`1. [HIGH] path:line: what's wrong → what happens → fix asked for (basis: rule/Dn)`

## §6 Lessons and slips
The watch list lives in LESSONS.md, the one list every chat reads: this project's lessons, then the slips known before it began. Check every PR against both. A repeated lesson is HIGH (§4). A first occurrence of a listed slip is MED (SMALL FIXES) unless §4's HIGH list already covers its effect; Cyrus still adds an L<n> that names it, and from then on a repeat is HIGH (basis: L<n>; add the rule number when a CHATS.md rule covers it too). A new kind of slip goes to Cyrus as a proposed lesson.
