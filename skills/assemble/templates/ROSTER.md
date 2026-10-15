# The team: {{PROJECT}}
*Kept current by {{WRITER}}. Names chosen by {{HUMAN}}; each starts with its job's letter.*

| Name | Address (exact title) | What it does | What it never does | Writes to | Model | Status |
|---|---|---|---|---|---|---|
| {{HUMAN}} | (none) | Decides; accounts, money, passwords, outside people | | | | |
{{ROSTER_ROWS}}

Status: Active · Standby (prep job: …) · Offline: ask {{HUMAN}} to reopen · Retired <date>
{{IF_NO_REVIEWER}}Reviewer: helper, no standing chat. {{WRITER}} runs a fresh reviewer helper on every PR (roles/reviewer.md).

## Where things are
| What | Where |
|---|---|
| Notebook folder (current notes) | `../{{REPO}}-team/team/`, next to the main checkout |
{{IF_BESIDE_REPO}}| Project repo (read its rules from `origin/{{DEFAULT_BRANCH}}`) | `../{{REPO}}` |
| Default branch | `{{DEFAULT_BRANCH}}` |
| Storage | {{MODE}}: {{MODE_REASON}} |
| Precious list (full-tier paths) | `team/assemble.json` |
{{IF_IN_REPO}}| PR template | `.github/pull_request_template.md` |
{{IF_BESIDE_REPO}}| PR template (pass it with `gh pr create --body-file`) | `team/pr-template.md` |
{{ADOPTED_WHERE_ROWS}}

## How {{HUMAN}} likes to work
*When {{HUMAN}} corrects how chats behave, {{WRITER}} adds a row the same turn and tells the chats it affects.*
| Rule | {{HUMAN}}'s words (verbatim, dated) | How to apply |
|---|---|---|
{{LIKES_ROWS}}

## How to open each chat
*{{WRITER}} prints these with full paths when a chat needs opening. Open {{WRITER}} first, then the Reviewer chat (if there is one); doers after the setup PR merges.*
| Chat | Desktop steps | Terminal, from the repo root |
|---|---|---|
{{OPEN_ROWS}}

Kickoff (the first message; on the terminal it goes inside the double quotes after `--`):
`You're <Name>, the <job> on {{PROJECT}}. Your session title must be exactly '<title>'. The team's notes are in team/ inside the {{REPO}}-team folder next to the project. Read CHATS.md there and do its rule 1 (it lists what to read), then roles/<role file>, then do 'First session' from your role file.`

Later: `claude --resume "<title>"` resumes a chat, or opens the picker filtered to that title if it doesn't resume directly.

## Retired chats
| Chat | Hired | Retired | Handover file |
|---|---|---|---|
