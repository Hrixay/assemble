# Handover: setup → {{WRITER}} ({{DATE}})
*From the /assemble setup chat, which is not on the team. Committed with setup PR #{{SETUP_PR}}.*

## Who you are
{{WRITER}}, the Chief of Staff on {{PROJECT}}: the only chat {{HUMAN}} talks to, {{HUMAN}}'s thinking partner, and the only one that writes the notes. The heavy work goes to the other chats. Your job description is roles/chief.md.
{{IF_NO_REVIEWER}}No standing Reviewer: you run a fresh reviewer helper on every PR (roles/reviewer.md, "How {{WRITER}} starts you").

## The team
| Name | Job | Address | Model |
|---|---|---|---|
{{TEAM_ROWS}}

## Open tracks
From TASKS "Who's on what": {{OPEN_TRACKS}}

## Decisions waiting on {{HUMAN}}
{{OWED_SUMMARY}}

## Things only {{HUMAN}} can do
{{ONLY_YOU_SUMMARY}} Steps in TASKS "Things only you can do".

## How {{HUMAN}} likes to work
See ROSTER "How {{HUMAN}} likes to work".

## Where this stands
See README.md.

## Tried and dropped
Nothing yet. See TRIED-AND-DROPPED.md.

## Key places
- Notes: this folder, `{{REPO}}-team/team/`, next to the main checkout.
- Project: the `{{REPO}}` folder next to this one; its GitHub repo is `{{REMOTE}}`.
- Precious list: `team/assemble.json`.
{{KEY_PLACE_LINES}}

## Recent context not in the files
{{CONTEXT_LINES}}

## First things to do
1. Read this, then do "First session" in roles/chief.md.
2. Give {{HUMAN}} the five-line summary and the three proposed tasks in TASKS "Now" and "Next".
{{IF_REVIEWER}}3. When {{REVIEWER}}'s verdict on PR #{{SETUP_PR}} is READY TO MERGE, follow the merge gate. If {{HUMAN}} already merged it, "Every session" in your role file has run "After the setup PR merges" already; don't run it twice.
{{IF_NO_REVIEWER}}3. Run the reviewer helper on PR #{{SETUP_PR}} (full tier) and post its verdict; when it is READY TO MERGE, follow the merge gate. If {{HUMAN}} already merged it, "Every session" in your role file has run "After the setup PR merges" already; don't run it twice.
