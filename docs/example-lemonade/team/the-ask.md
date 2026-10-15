# The ask
*Written once on 2026-10-12, word for word from Priya. It never changes. Changes of direction go in LOG.md and DECISIONS.md (a decision that overrides this file says so; this file stays as is).*

## In Priya's words
> the lemonade stand is run by a few of us volunteers and i do the website bit. people keep asking
> if they can order ahead for saturdays and the flavours page is a mess on a phone. i want to find
> out if pre orders are even worth doing, and make the flavours page nicer. done when the committee
> says yes or no to pre orders and the new flavours page is live

## What we understood
*Claude's summary, not Priya's words.*
- Making: an answer on whether pre-orders are worth offering, and a phone-friendly flavours page
- For: the stand's customers, and the committee that runs the stand
- Done when: the committee has said yes or no to pre-orders, and the new flavours page is live

## Stakes and constraints
- Money: none named.
- Live: the stand's public site. Pushing to master publishes it (pages.yml).
- Hard to undo: none named. A published change can be reverted, but customers see it first.
- Sign-off: the committee, on any pre-order plan and before the new page goes live.

## What was here already
*Claude's reading, not Priya's words.*
- A small static site (about 60 files) published from master by `.github/workflows/pages.yml`; the address comes from a `CNAME` file.
- The repo belongs to the committee's organisation (maple-st). Priya can push; the committee reviews. Three people committed in the last 90 days.
- Public repo. A CONTRIBUTING.md asks for changes by PR.
- No CLAUDE.md and no notes files.

## Open questions we noticed
*Written once at setup. Claude's reading, not Priya's words. Later questions go to TASKS "Decisions you owe" or research/START-HERE.md.*
- Are there enough customers who would order ahead for it to be worth doing?
- How could a customer pay ahead without the stand handling card details?
- What does the committee allow when it comes to changing how the stand takes orders?
