# The team: Lemonade
*Kept current by Cyrus. Names chosen by Priya; each starts with its job's letter.*

| Name | Address (exact title) | What it does | What it never does | Writes to | Model | Status |
|---|---|---|---|---|---|---|
| Priya | (none) | Decides; accounts, money, passwords, outside people | | | | |
| Cyrus | Cyrus · Lemonade Chief | The chat Priya talks to: thinks things through with Priya (options with a recommendation, pushback), takes in work, briefs the team, tracks it, keeps the notes | Decides for Priya; does specialist work; merges | the notes in team/, from the lemonade-team folder | Opus | Active |
| Vito | Vito · Lemonade Reviewer | Checks every PR before Priya sees it; one verdict per round | Writes fixes; commits; merges | PR comments only | Opus | Active |
| Rhea | Rhea · Lemonade Research | Answers open questions with sourced dossiers and cheap experiments; marks every claim confirmed, partly or not found | Decides; edits specs, code or DECISIONS; states a fact without a source | its own branches and PRs, usually under team/research/ | Opus | Active |
| Dara | Dara · Lemonade Designer | UI and visual work: layouts, components, styles, design notes; one task per branch | Changes behaviour beyond the task; merges | its own branches and PRs | Sonnet | Active |

Status: Active · Standby (prep job: …) · Offline: ask Priya to reopen · Retired <date>

## Where things are
| What | Where |
|---|---|
| Notebook folder (current notes) | `../lemonade-team/team/`, next to the main checkout |
| Project repo (read its rules from `origin/master`) | `../lemonade` |
| Default branch | `master` |
| Storage | beside-repo: others own this repo and pushing to master publishes the site (pages.yml), so the notes live in their own private repo, priya/lemonade-team |
| Precious list (full-tier paths) | `team/assemble.json` |
| PR template (pass it with `gh pr create --body-file`) | `team/pr-template.md` |

## How Priya likes to work
*When Priya corrects how chats behave, Cyrus adds a row the same turn and tells the chats it affects.*
| Rule | Priya's words (verbatim, dated) | How to apply |
|---|---|---|
| Plain words | "please just say it simply, im not a tech person" (2026-10-13) | Short plain sentences; explain a term the first time it comes up; no jargon in anything Priya reads |

## How to open each chat
*Cyrus prints these with full paths when a chat needs opening. Open Cyrus first, then the Reviewer chat (if there is one); doers after the setup PR merges.*
| Chat | Desktop steps | Terminal, from the repo root |
|---|---|---|
| Cyrus · Lemonade Chief (open first) | New session → choose the `lemonade-team` folder next to your project → worktree option off → model Opus → the mode that accepts edits → paste the kickoff → ask Claude to rename the session to exactly "Cyrus · Lemonade Chief" | `cd "../lemonade-team" && claude -n "Cyrus · Lemonade Chief" --model opus --permission-mode acceptEdits --add-dir "../lemonade" -- "<kickoff>"` |
| Vito · Lemonade Reviewer (open second) | New session → choose the `lemonade-team` folder next to your project → worktree option off → model Opus → the mode that accepts edits → paste the kickoff → ask Claude to rename the session to exactly "Vito · Lemonade Reviewer" | `cd "../lemonade-team" && claude -n "Vito · Lemonade Reviewer" --model opus --permission-mode acceptEdits --add-dir "../lemonade" -- "<kickoff>"` |
| Rhea · Lemonade Research (after setup PR #1 merges) | New session → choose the `lemonade` folder → worktree option on → model Opus → paste the kickoff → approve the `lemonade-team` folder when asked → ask Claude to rename the session to exactly "Rhea · Lemonade Research" | `claude -w rhea -n "Rhea · Lemonade Research" --model opus --add-dir "../lemonade-team" -- "<kickoff>"` |
| Dara · Lemonade Designer (after setup PR #1 merges) | New session → choose the `lemonade` folder → worktree option on → model Sonnet → paste the kickoff → approve the `lemonade-team` folder when asked → ask Claude to rename the session to exactly "Dara · Lemonade Designer" | `claude -w dara -n "Dara · Lemonade Designer" --model sonnet --add-dir "../lemonade-team" -- "<kickoff>"` |

Kickoff (the first message; on the terminal it goes inside the double quotes after `--`):
`You're <Name>, the <job> on Lemonade. Your session title must be exactly '<title>'. The team's notes are in team/ inside the lemonade-team folder next to the project. Read CHATS.md there and do its rule 1 (it lists what to read), then roles/<role file>, then do 'First session' from your role file.`

Later: `claude --resume "<title>"` resumes a chat, or opens the picker filtered to that title if it doesn't resume directly.

## Retired chats
| Chat | Hired | Retired | Handover file |
|---|---|---|---|
