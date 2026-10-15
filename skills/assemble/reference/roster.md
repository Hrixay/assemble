# Roster (Step 3)

Work out the team from the evidence, show the evidence for every role, and let the user
approve or change it. There is no default team size. Interview.md part D asks the question;
names.md names the chats.

## A. Outcomes

Every team has a **Chief of Staff**: the human talks only to the Chief, the Chief keeps the notes,
and it coordinates at least one employee chat under it. The Chief thinks things through with the
human and orchestrates; it never does the heavy work itself (anything over about 5 minutes goes
to an employee or a helper). So the smallest team is two chats.

| Outcome | Chats | The independent check |
|---|---|---|
| **Small** | 2: Chief + one doer | no standing Reviewer: the Chief starts a fresh reviewer helper for each PR (part C) |
| **Standard** | 3: Chief + Reviewer + one doer | the Reviewer chat |
| **Full** | 4 to 6: Standard plus the extra roles the evidence calls for (Researcher, Designer, Editor, Analyst, a second doer, a role of the user's own) | the Reviewer chat |

- Every outcome has exactly **one notebook writer**, the Chief: the one chat that commits notes
  straight to the default branch (git-model.md part A).
- **Small is the minimum.** Never a Chief alone, and never one chat that both keeps the notes and
  does the work. A user who asks for one chat hears once: "The smallest team is the Chief plus
  one doer: the Chief talks with you and keeps the notes, the doer does the work." Then Small.
- Watch mode (a read-only tracker for a repo the user only watches) is not in v1.

## B. Inference

Signals, each shown to the user with its evidence. On the New path they come from Call 2:

- **size:** the `Size` answer (Small = S, Medium = M, Large = L);
- **stakes:** yes when `Stakes` includes Spends money, Touches something live or Hard to undo;
- **others:** yes when `Sign-off` is "A client or boss signs off" or "Others also work on it";
- **kind:** the `Kind` answer: software, research, writing or data.

On the Existing path they come from the signal sheet (scan.md part E) and Call 2
(interview.md part G3):

- **size:** the file count on the default branch (50 or fewer S, up to 2,000 M, else L), or
  the `Size` answer when it was asked;
- **stakes:** yes when main deploys, or `Stakes` includes Spends money, Touches something
  live or Hard to undo;
- **others:** yes when 2 or more people committed to the default branch in 90 days, or the
  repo is shared (scan.md part D: the user answered "Existing, shared or someone else's",
  or the owner isn't them and they aren't an admin);
- **kind:** from the scan (mostly code: software; mostly writing or content: writing;
  notebooks and data: data; research notes: research), or the `Kind` answer.

**Extra-role evidence** (both paths): **research load** is any of 3 or more open questions in
the ask that need sourced research (not facts only the human can give, such as prices, hours or
which host they want; count them when you build the proposal), a `research/` folder in the
repo, or `Next` = Research or redesign, on a team whose doer isn't the Researcher; **design
load** is the ask or `Next` naming UI, visual work or a redesign.

Rules, first match wins:

```
size S and no stakes and no others      -> Small: Chief + one doer (a reviewer helper checks each PR)
size L, and research or design load     -> Full: Standard + the Researcher and/or Designer that load names
otherwise                               -> Standard: Chief + Reviewer + one doer
    doer by kind: software -> Builder ; writing -> Editor ; data -> Analyst ; research -> Researcher
cap 6 chats; duties are added to existing chats, never as new chats
```

Worked examples:

| Size | Stakes | Others | Outcome |
|---|---|---|---|
| Small | none | just me | Small |
| Small | spends money | just me | Standard |
| Small | none | a client signs off | Standard |
| Medium | none | just me | Standard |
| Medium | touches something live | a client signs off | Standard |
| Large | any | any | Standard; Full when there is also research or design load |
| Medium, existing code with tests | none | only you | Standard |
| Small, existing | main deploys | 2 committers | Standard |
| Small, existing, someone else's | none | (shared counts as others) | Standard |

- Extra-role evidence the rules didn't act on (below size L, or only one or two research questions)
  is named in the "Not hiring yet" line, never hired without the user's pick. From Standard or
  Full, "More chats" offers it; from Small, "More chats" offers the standing Reviewer only, and
  the user can name the extra role under Other. Say that `/assemble add <role>` hires one later.
- The user can always go smaller (down to Small) or bigger (up to 6 chats). Small is valid even
  with stakes, if the user picks it; then part C's growth trigger fires on the first full-tier PR
  after the setup PR.
- Above 3 chats, add one line under the proposal: "Each open chat uses your plan's usage and
  some memory; idle chats cost little until someone messages them."

## C. Small, spelled out (and any roster without a standing Reviewer)

- **The same flow as every team, minus the standing Reviewer.** The Chief owns every notebook
  file (CHATS.md "Who updates what"); the doer does the work, one branch per change in its own
  worktree (git-model.md part G), then a PR.
- **Independent check.** After the doer posts `## Ready for review` (the heading the lane check
  reads), and before telling the human it's safe to merge, the Chief starts a fresh-context
  reviewer helper: a sub-agent (the Agent tool) on Opus that reads only these, never the
  Chief's or the doer's conversation, summary or opinion:
  1. `team/roles/reviewer.md` (written for every roster without a standing Reviewer; ROSTER
     says "Reviewer: helper, no standing chat");
  2. `team/review-checklist.md`;
  3. the PR: its description, diff and comments;
  4. three records, read by the helper itself: DECISIONS, the TASKS "Not doing" table and
     LESSONS, with `git show origin/<default>:team/…` (before the setup PR merges, from the
     notebook folder). Records, not the Chief's account of them: in Small the helper is the only
     check against work on a "Not doing" item, a clash with a recorded decision or a repeated
     lesson.

  The Chief may also quote rows it thinks the diff touches, word for word, as an extra. The
  exact recipe, which the Chief reads at runtime, is in the helper version of
  `templates/roles/reviewer.md`, "How <writer> starts you": the Reviewed commit from
  `gh pr view <n> --json headRefOid --jq .headRefOid` just before, Opus (the one exception
  to CHATS.md rule 12's cheapest model), and the filled prompt (never edit, commit, push or
  comment; return only the verdict). The Chief posts the verdict unchanged as a PR comment
  headed `## Review of PR #<n>: round <R> (helper)`, with its **Reviewed commit**. The
  severity-to-verdict rule, the tiers and the pin to one commit all apply: a push after the
  verdict needs a new helper round.
- **The setup PR** is checked the same way: the Chief's first job is the helper round on it.
- **Merge:** the human clicks Merge on GitHub, exactly as in every team. No chat runs
  `gh pr merge`.
- **gh is required** (preflight already checked it).
- **Growth trigger:** the first full-tier PR after the setup PR (precious path, money, a
  live system, hard to undo; the setup PR itself doesn't count) makes the Chief propose a
  standing Reviewer to the human. `/assemble add reviewer` then changes nothing else: Small
  becomes Standard (rerun.md part C6).
- The same helper rule applies to any roster the user approves without a Reviewer.

## D. Roles

Every role is one of three types: **notebook writer** (commits notes to the default branch
from the notebook folder; exactly one per team), **doer** (works only in its own worktree,
one task per branch, lands everything by PR), **Reviewer** (reads and comments, never
commits).

| Role (letter, label) | Type | What it does | What it never does | Writes to | Model | Include when |
|---|---|---|---|---|---|---|
| **Chief of Staff** (C, Chief) | notebook writer | The only chat the human talks to, and their thinking partner: ideates (options with a recommendation), pushes back on risky or vague ideas, asks good questions, sends helpers to look before it recommends; then previews each task in one line, briefs the owning chat, tracks who's on what, checks, reports by track, briefs and teaches each decision, records rulings in the human's words, keeps the lessons, the glossary and "Where this stands" current, prepares opening steps, proposes hires. Runs the reviewer helper when there is no standing Reviewer | Decides for the human. Does the heavy work itself (anything over about 5 minutes goes to an employee or a helper). Edits another chat's work files. Contacts outsiders. Runs `gh pr merge` | every notebook file, from the notebook folder only; skill-maintenance PRs on `assemble/*` | Opus | always |
| **Reviewer** (V, Reviewer) | Reviewer | Checks every PR before the human sees it. One verdict per round, pinned to one commit, in plain English. Proposes checklist changes and new lessons to the Chief | Writes the fix. Commits, pushes, merges or closes. Touches another chat's branch. Names the answer to an open decision | PR comments only (`gh pr comment`) | Opus | Standard, Full |
| **Builder** (B, Builder) | doer | Builds code, site or config, one task per branch in its own worktree; PRs from the template; answers every finding; runbooks for live work | Changes *what* the project does without a decision. Commits to the default branch. Merges. Touches accounts, DNS or payments | its own branches and PRs | Sonnet | kind = software |
| **Editor** (E, Editor) | doer | Documents and content: drafts, structures, keeps facts and quotes exact | Invents facts. Changes quotes. Publishes | its own branches and PRs | Sonnet | kind = writing |
| **Analyst** (A, Analyst) | doer | Data: notebooks, models, numbers that reproduce | Reports a number it can't reproduce. Touches held-out data | its own branches and PRs | Sonnet | kind = data |
| **Designer** (D, Designer) | doer | UI and visual work, in the same files the Builder uses | Changes behaviour beyond the task. Merges | its own branches and PRs | Sonnet | design load at size L (Full), or the user adds it |
| **Researcher** (R, Research) | doer | Answers open questions with sourced dossiers in `team/research/`, every claim marked confirmed / partly / not found | Decides. Edits specs, code or DECISIONS. States facts without a source | its own branches and PRs | Opus | kind = research, research load at size L (Full), or the user adds it |
| **Custom** (its topic's letter) | doer | One named workstream the user describes | Works outside the tasks it is given | its own branches and PRs | Sonnet | the user names it |

- **Helpers are not team members.** Any chat may start short-lived sub-agents for one job
  (the Small team's reviewer helper, a research fan-out, an adversarial self-check). They are named
  by function, report only to the chat that started them, and use the cheapest model that
  can do the job (Haiku for mechanical work, Sonnet for reading and ordinary code, Opus for
  judgment and verification).
- **Role files:** every role in the table has its template in `templates/roles/` (`chief`,
  `reviewer`, `builder`, `editor`, `analyst`, `designer`, `researcher`, `custom`). A
  role of the user's own is always a doer, written from `custom.md` (rerun.md part C1 asks the
  questions). Never write a role file without its template.

## E. The proposal, as shown

Show the proposal just before the `Team` question: one line per chat with its evidence, then
the "Not hiring yet" line (or "Not hiring yet: nobody else for now").

> **Proposed for Acme: Small (2 chats)** ("Acme" is from the folder name; you can change it
> on the write screen)
> - **Chief of Staff** (Opus): the one chat you talk to. Thinks things through with you, keeps
>   the notes, briefs the Builder, and starts a fresh reviewer helper on every PR before you
>   merge. *Why:* every team has one; it never does the heavy work itself.
> - **Builder** (Sonnet): builds, one task per branch. *Why:* you said the work is software.
> - Not hiring yet: a standing Reviewer (small, no money, nothing live, nothing hard to undo,
>   only you involved; I'll suggest one at the first PR after this setup that touches something
>   risky; `/assemble add reviewer` hires one sooner).

A Standard team adds "**Reviewer** (Opus): checks every PR before you see it. *Why:* <the
stakes or the other people, or, with neither, the project's size and what the scan found (for
example "a medium app with tests and an email-service key")>, so a standing second pair of eyes
pays off." A Full team adds each
extra role with the evidence for it. On the Existing path the reasons quote the scan, for
example:

> **Proposed for Acme: Standard (3 chats)**
> - **Chief of Staff** (Opus): the one chat you talk to; thinks things through with you, keeps
>   the notes and briefs the others. *Why:* every team has one; it never does the heavy work
>   itself.
> - **Reviewer** (Opus): checks every PR before you see it. *Why:* a client signs off, and the
>   email service costs money.
> - **Builder** (Sonnet): builds and tests, one task per branch. *Why:* mostly JavaScript,
>   with `npm test` in package.json.
> - Not hiring yet: nobody else for now.

## F. What each hired chat becomes

| Chat | Role file | ROSTER "What it does" / "What it never does" / "Writes to" (short) | Title |
|---|---|---|---|
| Chief | `team/roles/chief.md` | The chat <Human> talks to: thinks things through with <Human> (options with a recommendation, pushback), takes in work, briefs the team, tracks it, keeps the notes (plus "runs a reviewer helper on every PR" with no Reviewer) / Decides for <Human>; does specialist work; merges / the notes in team/ (and any adopted file, at its own path; leave this out when nothing is adopted), from the <repo>-team folder | `<Name> · <Project> Chief` |
| Reviewer | `team/roles/reviewer.md` | Checks every PR before <Human> sees it; one verdict per round / Writes fixes; commits; merges / PR comments only | `<Name> · <Project> Reviewer` |
| Builder | `team/roles/builder.md` | Builds the project: one task per branch, in its own worktree / Changes what it does without a decision; commits to <default>; merges / its own branches and PRs | `<Name> · <Project> Builder` |
| Editor | `team/roles/editor.md` | Documents and content: drafts, structures, keeps facts and quotes exact / Invents facts; changes quotes; publishes / its own branches and PRs | `<Name> · <Project> Editor` |
| Analyst | `team/roles/analyst.md` | Data: notebooks, models, numbers that reproduce / Reports a number it can't reproduce; touches held-out data / its own branches and PRs | `<Name> · <Project> Analyst` |
| Designer | `team/roles/designer.md` | UI and visual work, in the same files the Builder uses / Changes behaviour beyond the task; merges / its own branches and PRs | `<Name> · <Project> Designer` |
| Researcher | `team/roles/researcher.md` | Answers open questions with sourced dossiers in `team/research/` / Decides; edits specs, code or DECISIONS; states facts without a source / `team/research/`, by PR | `<Name> · <Project> Research` |
| Custom | `team/roles/<label>.md` | The user's own job lines (shortened) / Works outside the tasks it is given, plus the user's extra never lines / the user's "writes to" hint | `<Name> · <Project> <Label>` |

- A roster with no standing Reviewer still gets `team/roles/reviewer.md`, written for the
  helper (`{{NAME}}` = helper, `{{TITLE}}` = `Reviewer helper · <Project>`), and the ROSTER
  line "Reviewer: helper, no standing chat".
- ROSTER Status at setup: the Chief and the Reviewer are **Active**; doers are
  **Standby (opens after setup PR #<n> merges)**.
- Every roster has exactly one Chief row and at least one doer row.
- The ROSTER cells say "its", for every added chat, whatever the other rows say.
- Models: as in the role table, unless the user changed them on the write screen.
