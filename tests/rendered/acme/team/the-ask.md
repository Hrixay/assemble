# The ask
*Written once on 2026-10-12, word for word from Priya. It never changes. Changes of direction go in LOG.md and DECISIONS.md (a decision that overrides this file says so; this file stays as is).*

## In Priya's words
> acme is the booking site for my friends pottery studio. right now people book classes by
> texting her and she loses track of who is coming. i want students to pick a class, book a seat
> and get a confirmation email, and she sees the list. done when a student can book on there own
> and the studio owner says its good to go live.

## What we understood
*Claude's summary, not Priya's words.*
- Making: online class booking with a confirmation email, and a booking list for the studio
- For: the studio's students, and the studio owner who checks the list
- Done when: a student can book a seat alone and the studio owner says it's good to go live

## Stakes and constraints
- Money: confirmation emails go through a paid email service.
- Live: nothing yet. Pushing to main deploys nothing (from Priya, 2026-10-12).
- Hard to undo: none named.
- Sign-off: the studio owner, before it goes live.

## What was here already
*Claude's reading, not Priya's words.*
- A small web app (about 180 files, Node), tests with `npm test` (package.json).
- No deploy file; Priya says pushing to main deploys nothing.
- Only Priya committed in the last 90 days; private repo; main not protected.
- A CLAUDE.md with build notes (kept; the team block is added at the end). No existing notes files.

## Open questions we noticed
*Written once at setup. Claude's reading, not Priya's words. Later questions go to TASKS "Decisions you owe" or research/START-HERE.md.*
- Is a seat confirmed straight away, or does the studio owner approve each booking?
- Which email service, and what monthly limit?
- Do students pay when they book, or at the studio?
