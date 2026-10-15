# The team: Acme
*Kept current by Cyrus. Names chosen by Priya; each starts with its job's letter.*

| Name | Address (exact title) | What it does | What it never does | Writes to | Model | Status |
|---|---|---|---|---|---|---|
| Priya | (none) | Decides; accounts, money, passwords, outside people | | | | |
| Cyrus | Cyrus · Acme Chief | The chat Priya talks to: thinks things through with Priya (options with a recommendation, pushback), takes in work, briefs the team, tracks it, keeps the notes | Decides for Priya; does specialist work; merges | the notes in team/, from the acme-team folder | Opus | Active |
| Vito | Vito · Acme Reviewer | Checks every PR before Priya sees it; one verdict per round | Writes fixes; commits; merges | PR comments only | Opus | Active |
| Bram | Bram · Acme Builder | Builds the app: one task per branch, in its own worktree | Changes what the app does without a decision; commits to main; merges | its own branches and PRs | Sonnet | Standby (opens after setup PR #1 merges) |

Status: Active · Standby (prep job: …) · Offline: ask Priya to reopen · Retired <date>

## Where things are
| What | Where |
|---|---|
| Notebook folder (current notes) | `../acme-team/team/`, next to the main checkout |
| Default branch | `main` |
| Storage | in-repo: pushing to main deploys nothing (Priya answered No), main isn't protected, the repo is private, and only Priya committed in the last 90 days |
| Precious list (full-tier paths) | `team/assemble.json` |
| PR template | `.github/pull_request_template.md` |

## How Priya likes to work
*When Priya corrects how chats behave, Cyrus adds a row the same turn and tells the chats it affects.*
| Rule | Priya's words (verbatim, dated) | How to apply |
|---|---|---|
| Options before the pick | "list the choices first, then say which one you'd go for" (2026-10-12) | Every question to Priya lists the options first, then our leaning, labelled as ours |

## How to open each chat
*Cyrus prints these with full paths when a chat needs opening. Open Cyrus first, then the Reviewer chat (if there is one); doers after the setup PR merges.*
| Chat | Desktop steps | Terminal, from the repo root |
|---|---|---|
| Cyrus · Acme Chief (open first) | New session → choose the `acme-team` folder next to your project → worktree option off → model Opus → the mode that accepts edits → paste the kickoff → ask Claude to rename the session to exactly "Cyrus · Acme Chief" | `cd "../acme-team" && claude -n "Cyrus · Acme Chief" --model opus --permission-mode acceptEdits -- "<kickoff>"` |
| Vito · Acme Reviewer (open second) | New session → choose the `acme-team` folder next to your project → worktree option off → model Opus → the mode that accepts edits → paste the kickoff → ask Claude to rename the session to exactly "Vito · Acme Reviewer" | `cd "../acme-team" && claude -n "Vito · Acme Reviewer" --model opus --permission-mode acceptEdits -- "<kickoff>"` |
| Bram · Acme Builder (after setup PR #1 merges) | New session → choose the `acme` folder → worktree option on → model Sonnet → paste the kickoff → approve the `acme-team` folder when asked → ask Claude to rename the session to exactly "Bram · Acme Builder" | `claude -w bram -n "Bram · Acme Builder" --model sonnet --add-dir "../acme-team" -- "<kickoff>"` |

Kickoff (the first message; on the terminal it goes inside the double quotes after `--`):
`You're <Name>, the <job> on Acme. Your session title must be exactly '<title>'. The team's notes are in team/ inside the acme-team folder next to the project. Read CHATS.md there and do its rule 1 (it lists what to read), then roles/<role file>, then do 'First session' from your role file.`

Later: `claude --resume "<title>"` resumes a chat, or opens the picker filtered to that title if it doesn't resume directly.

## Retired chats
| Chat | Hired | Retired | Handover file |
|---|---|---|---|
