# Placeholders

Setup fills each template itself (Read, substitute, Write). No other tool is needed.

## How to fill a template
1. **Line flags first.** A line that starts with `{{IF_<CONDITION>}}` is kept only when the condition holds. Keep it: delete just the flag. Otherwise: delete the whole line.
2. **Values.** Replace every `{{NAME}}` with its value.
3. **Blocks.** A `{{NAME}}` alone on its line becomes zero or more generated lines. With nothing to write, use the "if none" text; a blank "if none" means delete the line.
4. `<like this>` is not a placeholder. It shows chats the shape of a later entry and stays as written.
5. If the notes folder is `_team/` (an unrelated `team/` already exists), every `team/` that names the notes folder becomes `_team/`. That covers paths starting `team/` (including `@team/CHATS.md`), the `team/` inside `{{REPO}}-team/team/` (it becomes `{{REPO}}-team/_team/`), and `"folder"` in assemble.json (it becomes `"_team"`). The `{{REPO}}-team` folder itself keeps its name.
6. If the CLAUDE.md block goes into `.claude/CLAUDE.md`, its import line is `@../team/CHATS.md` (`@../_team/CHATS.md` with `_team/`), not `@team/CHATS.md`: an import resolves from the file that holds it, and `.claude/team/CHATS.md` doesn't exist. Test T12 confirms the rules load from there.
7. When done, no `{{` is left and no absolute path is written. Absolute paths appear only in kickoffs and launch lines printed in chat. At runtime the self-check (reference/interview.md part F3) checks this with Read and Grep; maintainers also check a filled folder with `scripts/check-output.sh`, which is in the skill's repo, not in an installed copy.

## Where each template goes
| Template | Written to | When |
|---|---|---|
| `claude-block.md` | the end of `CLAUDE.md` (beside-repo: the notes folder's `CLAUDE.md`; a symlinked or untracked `CLAUDE.md`: `.claude/CLAUDE.md`, with the import line from rule 6) | always |
| `README.md` `CHATS.md` `ROSTER.md` `LOG.md` `DECISIONS.md` `TASKS.md` `TRIED-AND-DROPPED.md` `review-checklist.md` `LESSONS.md` `GLOSSARY.md` `assemble.json` | `team/`, same name | always |
| `the-ask.md` | `team/the-ask.md` | only from the human's own words |
| `pull_request_template.md` | in-repo: `.github/pull_request_template.md` if no PR template exists (else offer to append its "Reviewer handoff" section); beside-repo: `team/pr-template.md` | always |
| `roles/<role>.md` | `team/roles/<role>.md`; a second chat in a role: `team/roles/<role>-<handle>.md` | each hired role, plus `reviewer.md` for every roster |
| `PLAN.md` | `team/PLAN.md`, by the first doer's PR (the doer role files list its headings) | not at setup |
| `handover.md` | `team/handovers/setup-{{DATE}}.md` (the setup chat's handover to the Chief) | always |

The Chief creates two more notebook files later, with no template (roles/chief.md gives their shape): `team/briefings/D<n>-<slug>.md`, one per decision the human owes, and `team/LOG-archive.md`, once LOG.md passes about 300 lines.

## Values
| Placeholder | Meaning | Acme example |
|---|---|---|
| `{{PROJECT}}` | short project name, Title Case, 12 characters or fewer | Acme |
| `{{HUMAN}}` | the human's first name | Priya |
| `{{DATE}}` | setup date, YYYY-MM-DD | 2026-10-12 |
| `{{STAMP}}` | setup branch time, YYYYMMDD-HHMM (`assemble/setup-{{STAMP}}`) | 20261012-1435 |
| `{{SETUP_PR}}` | setup PR number | 1 |
| `{{VERSION}}` | skill version | 1.0.0 |
| `{{REPO}}` | the project folder's name; the notes folder is `../{{REPO}}-team` | acme |
| `{{DEFAULT_BRANCH}}` | the project's default branch | main |
| `{{NOTES_BRANCH}}` | the branch notes go to, in the notebook folder's own repo: the project's default branch in-repo, `main` beside-repo (the notes repo is new and its default is `main`, whatever the project uses) | main |
| `{{REMOTE}}` | the project's GitHub repo, owner/name | priya/acme |
| `{{MODE}}` | `in-repo` or `beside-repo` | in-repo |
| `{{MODE_REASON}}` | the write screen's one-line reason for the mode, without its leading "In-repo:" or "Beside-repo, because" (the row already says the mode), in the third person with {{HUMAN}}'s name instead of "you" | pushing to main deploys nothing (Priya answered No), main isn't protected, … |
| `{{SEPARATOR}}` | the title separator | · |
| `{{WRITER}}` | the Chief's name: every team's one notebook writer | Cyrus |
| `{{REVIEWER}}` | the standing Reviewer's name (used only on `{{IF_REVIEWER}}` lines) | Vito |
| `{{PAID_SERVICE}}` | what spends money, in plain words | the email service |
| `{{PRECIOUS_EXTRA}}` | extra full-tier paths from the scan, each as a comma, a new line, four spaces and `"<path>"`; if none, nothing | `"db/migrations/**"` |
| `{{ADOPTED_JSON}}` | in-repo adopted files as a JSON object, job → repo-relative path (log, decisions, tasks, ask, research); if none, `{}` | `{}` |
| `{{D1_TEXT}}` / `{{D2_TEXT}}` | the decision in plain words: the team / the names | Run Acme as a Standard team: … |
| `{{D1_WORDS}}` / `{{D2_WORDS}}` | the human's words, verbatim; a click is `(clicked) "<option>"`, a numbered-list answer `(answered "1a") "<option>"` | (clicked) "Hire this team" |
| `{{D1_SHOWN}}` `{{D1_RECOMMENDED}}` `{{D1_CHOSEN}}`, `{{D2_SHOWN}}` `{{D2_RECOMMENDED}}` `{{D2_CHOSEN}}` | for the LOG "Ruled" line: the options shown, our pick with why, the human's choice | |
| `{{MAKING}}` `{{FOR_WHOM}}` `{{DONE_WHEN}}` | Claude's one-line summary of the ask; one the ask doesn't answer is "Not said in the ask; Claude's reading: <reading>" | |
| `{{SUMMARY}}` | README, inline: one or two plain sentences on where things stand | Setup PR #1 is open: Cyrus runs a fresh reviewer helper on it, then Priya merges. |
| `{{SETUP_OPEN}}` | LOG, inline: what is open after setup | Cyrus runs the reviewer helper on PR #1; T1 to T3 proposed. |
| `{{OPEN_TRACKS}}` | handover, inline: one line, what each chat is on, from TASKS "Who's on what" | setup only. Cyrus runs the reviewer helper on setup PR #1; Bram opens after it merges. |
| `{{ONLY_YOU_SUMMARY}}` | handover, inline: the "Things only you can do" rows, in one line | Merge setup PR #1 when Cyrus says it is safe, then open Bram. |

Per role file: `{{NAME}}` (the chat's name), `{{TITLE}}` (`<Name> · <Project> <Role label>`, reference/names.md "Session title"), `{{HANDLE}}` (the name in lowercase), `{{MODEL}}` (Opus or Sonnet). With no standing Reviewer, `reviewer.md` uses NAME `helper` and TITLE `Reviewer helper · <Project>`.

## Blocks
| Placeholder | File | What goes there | If none |
|---|---|---|---|
| `{{STAGE_ROWS}}` | README | one row per PLAN.md stage | one row naming who drafts PLAN.md and when, for example `\| No plan yet \| Bram drafts PLAN.md after the setup PR merges \| TASKS T1 \|` |
| `{{ON_HOLD}}` | README | what stopped, where, the first step to restart | Nothing on hold. |
| `{{FACT_ROWS}}` | README | `\| fact \| source and date \| checked by \|` from the scan and the interview. Checked by: `setup scan` for what the scan read (a `Deploys?` answer too, since the scan found no deploy file); blank for a fact {{HUMAN}} gave that nothing has checked yet | (blank) |
| `{{TRAP_LINES}}` | README | `- <trap>`, for example the in-repo notes line when the user chose "Keep notes here" (interview.md part F2) | None found yet. |
| `{{MORE_DECISION_ROWS}}` | DECISIONS | more setup decisions, as rows like D1's, for example D3 "Keep the notes in this repo for now" (interview.md part F2) | (blank) |
| `{{MORE_RULED_LINES}}` | LOG | for each of those decisions: `Also ruled: D<n>, <what>.`, then its `D<n> · Shown: … · We recommended: … · {{HUMAN}} chose: …` line, then {{HUMAN}}'s words, verbatim | (blank) |
| `{{ROSTER_ROWS}}` | ROSTER | one row per chat, from reference/roster.md part F. The Address cell is the bare title, no quotes or backticks (SendMessage takes it as it is), for example `\| Vito \| Vito · Acme Reviewer \| Checks every PR before Priya sees it; one verdict per round \| Writes fixes; commits; merges \| PR comments only \| Opus \| Active \|` | |
| `{{ADOPTED_WHERE_ROWS}}` | ROSTER | in-repo `\| <Job> (adopted) \| <path> \|`, plus `\| <Job> (yours, not adopted; read-only) \| <path> \|` for a notes file left as it is; beside-repo `\| <Job> (in the project, read-only) \| ../{{REPO}}/<path> \|` | (blank) |
| `{{LIKES_ROWS}}` | ROSTER | what the human said about how chats should behave, verbatim and dated | (blank) |
| `{{OPEN_ROWS}}` | ROSTER | one row per chat, in opening order (see below) | |
| `{{ADOPTED_OWNER_ROWS}}` | CHATS | one row per adopted path, by job, in place of that job's `team/<FILE>` row (delete it, so each notes file has exactly one row). Log, decisions, tasks: `\| <path> \| {{WRITER}} \| <when, as for the file it replaces> \|`. Ask: `\| <path> \| nobody \| Written once from {{HUMAN}}'s own words; never changes after \|`. Research: `\| <path> \| the Researcher, by PR \| When a question is answered \|` | (blank) |
| `{{ASK_WORDS}}` | the-ask | the human's words, every line starting `> `, typos kept | |
| `{{STAKES}}` | the-ask | `- Money:` · `- Live:` · `- Hard to undo:` · `- Sign-off:` | |
| `{{FOUND}}` | the-ask | the scan summary, at most 6 bullets with evidence | Nothing yet: a new project. |
| `{{OPEN_QUESTIONS}}` | the-ask | `- <question>` | None noticed. |
| `{{OWED_LINES}}` | TASKS | decisions the human owes, one line each (setup writes no briefing; the Chief writes one before teaching each) | None yet. |
| `{{BEFORE_MERGE_ROWS}}` | TASKS | the rows needed before the setup PR merges, above its Merge row: "Open <Chief> (Chief)", then "Open <Reviewer> (Reviewer)" when there is one (reference/interview.md part F2 gives the cells) | |
| `{{ONLY_YOU_ROWS}}` | TASKS | more rows, below the Merge row: open each doer after the setup PR merges, git identity, … | (blank) |
| `{{WHO_ROWS}}` | TASKS | one row per chat. Its state agrees with the ROSTER Status (a chat not opened yet is still Active or Standby there; the "Waiting on" cell says who opens it), for example `\| Vito \| First job: review setup PR #1 (full tier) \| setup \| Priya (opens Vito after Cyrus) \| 2026-10-12 \|` | |
| `{{NOW_LINES}}` `{{NEXT_LINES}}` | TASKS | task lines in the TASKS line format; the first tasks are marked `(proposal)`: T1 in Now, T2 and T3 in Next, for example `- [ ] T1 · Build-readiness note and team/PLAN.md · [track: setup] · Bram · done when its PR has a READY verdict and Priya merged it · (proposal)` | (blank) |
| `{{TEAM_ROWS}}` | handover | `\| <Name> \| <job> \| <title> \| <model> \|`, one row per chat | |
| `{{OWED_SUMMARY}}` | handover | the decisions {{HUMAN}} owes, in a line or two | None yet. The tasks in TASKS are proposals for {{HUMAN}} to confirm. |
| `{{KEY_PLACE_LINES}}` | handover | more `- <what>: <where>` lines (build notes, starter files) | (blank) |
| `{{CONTEXT_LINES}}` | handover | `- <what the setup chat heard>`: interview details no other file holds, the user's words quoted where they matter; never secrets | - Nothing beyond the files. |

**`{{OPEN_ROWS}}` cells** (relative paths only, always quoted, since a folder name may hold a space; the notebook writer prints full paths in chat). `<kickoff>` stays as written: it points to the Kickoff line under the table. The first cell is the title plus "(open first)", "(open second)" or "(after setup PR #<n> merges)"; a chat added later by a re-run (rerun.md part F) gets "(open any time)":
- Notebook writer and Reviewer, desktop: New session → choose the `<repo>-team` folder next to your project → worktree option off → model → the mode that accepts edits → paste the kickoff → ask Claude to rename the session to exactly "<title>".
- Same, terminal: `cd "../<repo>-team" && claude -n "<title>" --model <opus|sonnet> --permission-mode acceptEdits -- "<kickoff>"`. Beside-repo: add `--add-dir "../<repo>"` before `--`.
- Doers, desktop: New session → choose the `<repo>` folder → worktree option on → model → paste the kickoff → approve the `<repo>-team` folder when asked → ask Claude to rename the session to exactly "<title>".
- Doers, terminal: `claude -w <handle> -n "<title>" --model <opus|sonnet> --add-dir "../<repo>-team" -- "<kickoff>"`.

## Line flags
| Flag | Keep the line when |
|---|---|
| `{{IF_REVIEWER}}` / `{{IF_NO_REVIEWER}}` | the roster has a standing Reviewer chat (Standard, Full) / has none (Small: the Chief runs a reviewer helper on every PR) |
| `{{IF_IN_REPO}}` / `{{IF_BESIDE_REPO}}` | the storage mode is in-repo / beside-repo |
| `{{IF_PUBLIC_OR_SHARED}}` | the repo is public, or `{{IF_SHARED}}` holds (PR comments on the project repo, `{{REMOTE}}`, carry findings only; PRs in a private notes repo don't) |
| `{{IF_SHARED}}` | the repo is shared (reference/scan.md part D): the human answered "Existing, shared or someone else's", or its owner isn't them and they aren't an admin. Others own or review it (proposals; the owners merge) |
| `{{IF_MONEY}}` | the project spends money (spend guard) |
| `{{IF_LIVE}}` | the work touches something live or hard to undo (runbook) |
| `{{IF_MIGRATION}}` | the ask (the user's own words) or the scan names a migration, a move or a redo of an existing site or app; the Kind option's "(incl. a migration)" hint doesn't count |
| `{{IF_NO_DUTIES}}` | none of MONEY, LIVE, MIGRATION, SHARED holds |
| `{{IF_SOFTWARE}}` `{{IF_WRITING}}` `{{IF_RESEARCH}}` `{{IF_DATA}}` | that kind of work is on the team (the Kind answer or the scan, plus each hired doer's kind) |

## Added in PR 7
The remaining roles and the duty files. These rows add to the tables above; nothing above changes.

### Where each template goes
| Template | Written to | When |
|---|---|---|
| `roles/editor.md` `roles/analyst.md` `roles/designer.md` `roles/researcher.md` | `team/roles/<role>.md`; a second chat in a role: `team/roles/<role>-<handle>.md` | each hired role |
| `roles/custom.md` | `team/roles/<label>.md`, the custom label in lowercase (for example `translator.md`) | each custom role, when it is added |
| `RUNBOOK.md` | `team/RUNBOOK.md` | only when `{{IF_LIVE}}` holds: a skeleton at setup (or added later by PR); the doer fills it in by PR before the first irreversible step |
| `PROPOSALS.md` | `team/PROPOSALS.md` | only when `{{IF_SHARED}}` holds, at setup; {{WRITER}} adds the entries |
| `research-START-HERE.md` | `team/research/START-HERE.md` (an adopted research folder: its `START-HERE.md`) | not at setup: the Researcher's first PR (`roles/researcher.md` lists its headings) |
| `research-dossier.md` | `team/research/<topic>.md` (an adopted research folder: there) | not at setup: one per question, by the Researcher's PR (`roles/researcher.md` lists its headings) |

Duty files use only `{{PROJECT}}`, `{{HUMAN}}` and `{{WRITER}}`. Their `<like this>` parts are filled in by the chat that writes the file, later.

**Precious list.** When `{{IF_LIVE}}` holds, `{{PRECIOUS_EXTRA}}` ends with `"team/RUNBOOK.md"`, after the scan's paths. Anything touching the runbook is full tier (CHATS.md, the runbook's own header), and `team/assemble.json` is the one home of the precious list, from which the review checklist and the PR template pick the tier. A RUNBOOK.md added later by PR adds that path to `assemble.json` in the same PR.

### Values
| Placeholder | Meaning | Example |
|---|---|---|
| `{{CUSTOM_WRITES_TO}}` | `roles/custom.md`: where the role usually writes, from the Add answers (a hint for the Reviewer, not a fence) | the translations folder |
| `{{CUSTOM_FIRST_JOB}}` | `roles/custom.md`: the first task the user named at Add, as a short phrase | the first translation pass |

### Blocks
| Placeholder | File | What goes there | If none |
|---|---|---|---|
| `{{CUSTOM_JOB_LINES}}` | custom role | what the role does, from the Add answers: `- <line>` each | (at least one line; ask again) |
| `{{CUSTOM_NEVER_LINES}}` | custom role | what the role never does, beyond the fixed first line: `- <line>` each | (blank) |

## Added in PR 5+6
The Existing path (in-repo and beside-repo) and shared repos. These rows add to the tables above; nothing above changes. Interview.md part G8 says which values and flags the Existing path uses.

### Where each template goes
| Template | Written to | When |
|---|---|---|
| `claude-block.md` | in-repo on an existing repo: appended once at the very end of the default branch's `CLAUDE.md`, after one blank line (no line above it changes); `.claude/CLAUDE.md` when the user's CLAUDE.md is a link or isn't on the default branch (interview.md part G6) | always |
| `LOG.md` (adopted log) | only its setup entry (the lines below the marker), added to the adopted file as one new entry, in that file's own style | in-repo, when a log is adopted |
| `DECISIONS.md` (adopted decisions record) | only its rows (D1, D2 and any later setup decisions), added in that file's own format, each with {{HUMAN}}'s words verbatim | in-repo, when a decisions record is adopted |
| `TASKS.md` (adopted task list) | everything from `## Waiting on {{HUMAN}}` down, added below the file's own lines | in-repo, when a task list is adopted |
| `the-ask.md` | never over an adopted ask file, which stays byte-for-byte as it is | |

### Line flags
| Flag | Keep the line when |
|---|---|
| `{{IF_ADOPTED}}` | in-repo, at least one file the project already had is adopted for a notebook job (`{{ADOPTED_JSON}}` isn't `{}`) |

`{{IF_PUBLIC_OR_SHARED}}` lines now also sit in `roles/builder.md`, `roles/reviewer.md` ("How you report") and `pull_request_template.md`; `{{IF_BESIDE_REPO}}` in `pull_request_template.md` (its first line, for a project with its own PR template).
