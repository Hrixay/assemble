# Re-runs (Step 6)

Preflight sends you here in two cases: an **open setup PR** (part A) or a **team that is already
set up** (parts B to F). When there is no team, preflight part C (check 3) lists leftovers from an
unfinished setup, asks, and cleans them up before the run gets this far. Beside a team, a setup
branch that was left behind is found by check E2b.

- **A. Continue an open setup PR**
- **B. A team is here:** read it, the menu, and the rules every re-run follows
- **C. Add** a chat (a catalogue role, a role of the user's own, a standing Reviewer)
- **D. Retire or replace** a chat
- **E. Check and repair**
- **F. After a merge:** the notes, the doorbell, the opening steps

Run each command in its own Bash call, as preflight does. Paths in commands are full paths,
quoted. `<MAIN>` and `<NB>` are built as git-model.md part C says, from `git worktree list
--porcelain`, whichever folder this chat runs in. `<owner>/<name>`, `<you>` and the default
branch `<default>` are in the preflight notes. **With no preflight notes** (the notebook writer
entering part F from a pasted message): `<owner>/<name>` is read from `git remote get-url origin`,
`<default>` from the manifest's `defaultBranch`, and the surface with `printenv
CLAUDE_CODE_REMOTE`, then `printenv CLAUDE_CODE_ENTRYPOINT`, read as preflight part A reads them
(`<you>` is only needed by part A, which always has preflight notes). Every `gh ... --repo`
takes `<owner>/<name>` from here, never the manifest's `remote`: that field is a record of setup
and can be out of date.

Three read-only git commands, `git show`, `git ls-files` and `git check-ignore`, are pre-approved
when they start with `git` and the subcommand, so run them in the folder you are in: every folder
of the project shares its repository. Any other command asks permission once per kind of command,
like `git fetch`: `git -C "<path>"` (a command about another folder), `git ls-tree`, `git rev-list
--count`, `git grep`, `gh pr view`, `gh api`. Say in one line why before the first (the notebook
writer runs in `<NB>`, so for it `<NB>` commands are plain). `git ls-tree`, `git rev-list` and
`git grep` are read-only but stay off the pre-approved list on purpose: `git grep -O<command>`
runs a program and `git rev-list --output=<file>` writes a file. Never pass `-O`,
`--open-files-in-pager` or `--output` to any git command here.

## A. Continue an open setup PR

Preflight part C (check 1) found setup PR `#<N>` and the user chose **Continue it**. Never open
a second setup PR. The only things you may change are the notebook folder and the local exclude
line below.

1. Which repo did preflight find the PR in? If it is `<you>/<repo>-team`, a separate notes repo,
   not the project: say "This version of /assemble can't yet continue a setup whose notes live in
   a separate notes repo isn't written yet. Nothing was changed." and stop. Run no `gh pr view`
   first: `#<N>` is a different PR in the project repo, or none. Otherwise run
   `gh pr view <N> --repo <owner>/<name> --json state,headRefName,headRefOid,author`.
   - `state` must be `OPEN`. If it is `MERGED` or `CLOSED`, say so and run preflight part C
     again from the top: the situation changed.
2. Look at the notebook folder: `git -C "<MAIN>" worktree list --porcelain`, and whether the
   folder `<NB>` exists. The user's **Continue it** covers the one thing you may create here;
   say what you are about to do before you do it.
   - **Listed, its folder exists, and `git -C "<NB>" branch --show-current` prints the PR's
     `headRefName`:** nothing to build. `git -C "<NB>" status --short` should be empty
     (otherwise say what is there and leave it alone).
   - **Listed and `prunable`** (its folder was deleted by hand): run
     `git -C "<MAIN>" worktree prune`, then do the "not there" bullet.
   - **Not listed, and no folder** (deleted, a fresh clone, or another computer): if
     `git -C "<MAIN>" branch --list "<headRefName>"` prints the branch, run
     `git -C "<MAIN>" worktree add "<NB>" <headRefName>`. Otherwise run
     `git -C "<MAIN>" worktree add --no-track -b <headRefName> "<NB>" origin/<headRefName>`
     (`--no-track`: the branch must not track `origin/<default>`).
   - **Anything else** (listed on another branch or detached, or a folder that isn't a worktree
     of this project): say what you found and stop. Never delete, switch or overwrite it.
3. `git -C "<NB>" rev-parse HEAD` must equal `headRefOid`. If it doesn't (a local commit that
   was never pushed, or a newer push), show both and stop. Never reset or force anything.
4. The local exclude line, once (git-model.md D4: it keeps doer worktrees out of `git add -A`).
   Run the D4 command; it adds the line only if it is missing.
5. Print the opening steps, read from the PR's files in `<NB>` (`team/ROSTER.md` for the names,
   titles and models, `team/handovers/` for what setup knew): launch.md parts B, C and D, for the
   surface you detected, in opening order (the notebook writer, the Reviewer; doers wait for the
   merge). Say: "Setup PR #<N> is still open. Open the chats with the steps above; the notebook
   writer's first job is to get it reviewed. I changed nothing except <what you recreated, or
   'nothing'>." Then stop: this chat is not on the team.

## B. A team is here

### B1. Read the team

Preflight found a manifest on a default branch. `<folder>` is the folder it was in (`team`, or
`_team` when the project already had its own `team/` folder): use it wherever this file says
`team/`. Read, from the default branch and not from a checkout (`git show
origin/<default>:<folder>/<file>`):

- `assemble.json`: `version`, `mode`, `notebook`, `project`, `human`, `defaultBranch`,
  `separator`, `remote` (fills `{{REMOTE}}` only; never use it for `gh --repo`, see the top),
  `precious` (the full-tier paths) and `adopted` (job → path).
  **`mode` is `beside-repo`, or the manifest was found only in `<you>/<repo>-team`:** say
  "This version of /assemble doesn't yet do re-runs for a team whose notes live in a separate notes repo
  aren't written yet. Nothing was changed." and stop.
- `ROSTER.md`: the first table (before the first `##` heading). Each row with a title in the
  Address column is a chat: name, title, model, status. The **notebook writer** is the Chief, the
  row whose title ends in `Chief`; a **standing Reviewer** is a row whose title ends in
  `Reviewer`; every other row is a doer. The line "Reviewer: helper, no standing chat" means
  there is no standing Reviewer.
- `DECISIONS.md` and the briefing file names, `git ls-tree --name-only origin/<default> --
  <folder>/briefings/` (nothing listed is fine). The next decision ID is one more than the
  highest `D<n>` in either: a briefing holds its ID before the user rules (roles/chief.md,
  Decisions 4). Also `CHATS.md` when a repair needs it.

The same values fill a template later: `{{PROJECT}}`, `{{HUMAN}}`, `{{DEFAULT_BRANCH}}` (also
`{{NOTES_BRANCH}}`, in-repo) and `{{REMOTE}}` from the manifest, `{{REPO}}` from `notebook`
(`../acme-team` → `acme`), `{{WRITER}}` and `{{REVIEWER}}` from the roster, and the flags from
`mode` and the roster (`IF_IN_REPO`, `IF_REVIEWER` or `IF_NO_REVIEWER`). Re-runs exist only for
in-repo teams on a repo the user owns, so `IF_BESIDE_REPO`, `IF_SHARED` and
`IF_PUBLIC_OR_SHARED` are never on. A few more values are in the team's own files, for part C6:
`{{DATE}}` and `{{VERSION}}` in CHATS.md's second line ("Set up <date> with /assemble
<version>"), `{{STAMP}}` and `{{SETUP_PR}}` in the first LOG entry ("on assemble/setup-<STAMP>
(PR #<n>)"), and the duty flags and `{{PAID_SERVICE}}` in CHATS.md "Duties for this project".

### B2. The menu

**The release lookup** (the menu and E5 both use it; run it once): read `VERSION` in this skill's
folder, then `gh api repos/Hrixay/assemble/releases/latest --jq .tag_name` (it asks permission
once; any failure, or a 404, means "can't tell": no Upgrade option, and E5 says so). The tag is
newer when its numbers (x.y.z, `v` left off) are higher than `VERSION`'s.

If the user typed `add`, `retire` or `check` (with `add <role>` or `retire <name>`), go straight
to part C, D or E with that word: no menu, so no lookup yet (E5 runs it). Otherwise run the
lookup and ask one question:

| Header | Question | Options |
|---|---|---|
| `Team` | "This project already has a team (<the names>). What now?" | **Add someone**: "A new role, or another chat in a role you have" · **Retire or replace someone**: "Retire a chat, or swap in a fresh one with the same title" · **Check & repair**: "Look for problems; nothing changes until you say yes" · **Upgrade to <tag>**: "Prints the update steps; changes nothing" (only when a newer release exists) |

**Upgrade** prints the update steps (E5) and stops. A timed-out or empty answer is "not
answered": ask once more, then stop with "Nothing was changed."

### B3. Rules every re-run follows

1. **Read-only until the approval screen.** Each flow ends in one approval screen (C4, D3, E6).
   SKILL.md hard rules 1 and 2 apply to it exactly as they do to Step 4's write screen: nothing
   is created, edited, committed or pushed until the user picks its **Go ahead** option, and
   then only what it listed. `git fetch` (retried once) stays allowed.
2. **Work files by PR, notes by the notebook writer** (git-model.md part A). Every file a
   re-run PR changes is a work file. The PR is **full tier** when any of its files matches the
   manifest's `precious` list (a role file always does), otherwise quick.
3. **One maintenance PR at a time.** Before you show the approval screen, run `gh pr list --repo
   <owner>/<name> --state open --json number,headRefName,url --limit 100`. A head starting
   `assemble/` is open: say "PR #<n> (<branch>) is still open. Finish or close it first." and stop.
4. **Never touch the user's checkout or `<NB>`** beyond what A, B4, E6 and F say. No switch,
   stash, pull or commit in the checkout; the PR is built in its own worktree.
5. **Who writes the notes.** This chat is the notebook writer's if it was started with the
   writer's kickoff (launch.md part B). Then it does part F itself. Any other chat builds the
   PR and then stops with the hand-off message of part F, in a copyable block, for the user to
   paste to the notebook writer.
6. **Adopted files.** A note goes to the manifest's `adopted` path for that job (`log`,
   `decisions`, `tasks`) when there is one, otherwise to `<folder>/<file>`.
7. **Access to `<MAIN>`.** B4 builds, and F removes, a working copy under
   `<MAIN>/.claude/worktrees/`, a folder outside the notebook folder where the writer runs. This
   chat needs access to `<MAIN>`. Nothing to do if it runs in `<MAIN>` or was started with
   `--add-dir "<MAIN>"` (in-repo, a Chief's and a Reviewer's launch lines don't have it).
   Otherwise, right after the user's yes (before B4 step 3, or F step 2), say "Please type
   `/add-dir <MAIN>` and press Enter, then tell me 'done'." (the full path; on the desktop,
   approve the folder when asked) and wait. Each approval screen (C4, D3, E6) lists it. If the
   user skips it, every write there asks one by one, or a sandbox blocks it: stop and say so
   (SKILL.md hard rule 8).
8. **Notes commits made before the merge are listed too.** They are the follow-up line in
   TASKS (C5, D4, E6) and a Retire's handover (D2). Each approval screen lists them, so the
   user's yes covers them: hard rule 2 allows only what the screen listed.

### B4. Build a re-run PR (Add, Retire, repair)

`<kind>` is `add`, `retire` or `repair`; `<handle>` is the chat's lowercase name (a repair has
none: leave `-<handle>` out of the branch and the folder); `<STAMP>` is `date +%Y%m%d-%H%M`.
`<branch>` is `assemble/<kind>-<handle>-<STAMP>` and `<WT>` is
`<MAIN>/.claude/worktrees/assemble-<kind>-<handle>-<STAMP>`: the branch name with `/` as `-`, so
every run has a folder of its own and a leftover can never block a retry. Steps 1 and 2 only
read, so they run **before the approval screen**: the screen then shows the branch name that will
really be used. Steps 3 to 9 run after the user's yes.

1. `git -C "<MAIN>" fetch origin` (run it once more if it fails with "cannot lock ref").
2. Take `<STAMP>`, then `git -C "<MAIN>" ls-remote --heads origin "assemble/<kind>-*"`,
   `git branch --list "assemble/<kind>-*"` and `git worktree list --porcelain`. While `<branch>`
   is listed on GitHub or on this computer, or the folder `<WT>` exists, add a minute to `<STAMP>`
   and look again. If the list shows another `assemble-*` working copy under
   `<MAIN>/.claude/worktrees/` (an earlier run stopped, or its PR was closed unmerged), say in one
   line "an earlier run left <folder> behind; the check (E2b) can remove it" and go on: it never
   blocks this run, and you never reuse it.
3. Access (B3 rule 7), then
   `git -C "<MAIN>" worktree add --no-track -b <branch> "<WT>" origin/<default>`.
4. Write the files in `<WT>` by full path, then `git -C "<WT>" add -- <paths>` (explicit paths).
5. Self-check, after the add, so a new file shows up in it: no `{{` left in what you wrote; no
   home-folder path (search with the patterns `/Us[e]rs/`, `/ho[m]e/` and a drive letter, a
   backslash and `Us[e]rs`); and `git -C "<WT>" status --short` lists exactly the files the
   approval screen showed, each staged (`A ` or `M `), with no `??` or ` M` line. A file the
   screen didn't show, or one it did that is missing, means stop and say which: change nothing
   more.
6. `git -C "<WT>" commit -m "<message>" -- <paths>`, then `git -C "<WT>" push -u origin HEAD`.
   Never a bare `git push`.
7. Write the body to a temporary file outside both folders (the system temp folder). Fill every
   heading of the repo's PR template (`<WT>/.github/pull_request_template.md`; the headings below
   when it has none): What this PR does · Why (the user's request and its date; for an Add or a
   Retire also the Shown, We recommended and chose lines and the user's words of the F hand-off
   message, so they sit on GitHub too) · How it was tested (the self-check, item by item) ·
   Reviewer handoff (Tier; Focus here first, which must name every rule file the PR touches;
   Risk; Deploy dependencies: none; Manual actions after merge; Out of scope, which names the
   notes written after the merge) · Checklist (tick its three boxes once they are true). The
   body goes to GitHub, so before `gh pr create`: search it with step 5's patterns and for `{{`
   (write `<WT>` in it as "the working copy", never as a path); and when the preflight notes say
   the repo is now PUBLIC, leave the user's own words and the Shown, We recommended and chose
   lines out of it (they stay in the hand-off message and the notes) and say so in one line. Then
   `gh pr create --repo <owner>/<name> --base <default> --head <branch> --title "<title>"
   --body-file <file>`.
8. Post `gh pr comment <n> --repo <owner>/<name> --body-file <file>`:
   - the heading `## Ready for review: round 1 (<writer>)`, always with the writer's name: the
     Reviewer's lane check reads the chat named there, and `assemble/*` is in lane only for the
     writer;
   - when this chat is not the writer, the line "Built by the /assemble skill in a session started
     for <writer>; <writer> writes the notes after the merge", so the comment says who really
     posted it;
   - the tier and "Focus here first: <the files>".

   Then tell the Reviewer: ListAgents, and SendMessage to the exact title if it is listed: "PR
   #<n> is ready for review. Waiting on: your verdict (<Reviewer>)". Send only to a title that
   matches exactly: ListAgents also lists sessions that aren't on this team, and they get
   nothing. **If the Reviewer isn't listed,** it isn't open: say so, print its ROSTER "How to
   open each chat" line for your surface (launch.md parts B and C), and name PR #<n> as waiting
   for its verdict. With no standing Reviewer, start the reviewer helper as
   `team/roles/reviewer.md` "How <writer> starts you" says and post its verdict unchanged.

   A chat that isn't the writer also sends the writer one doorbell the same way: "PR #<n> (<what>)
   is open; its notes (part F) are yours after the merge; the user will paste the details." A
   writer that receives it adds a TASKS "Now" line like C5's, so a forgotten paste still leaves
   a trigger.
9. Tell the user the PR number and that they merge it themselves, after the verdict is READY TO
   MERGE and the writer says it is safe to click. A chat that isn't the writer ends with the
   hand-off message (part F) in a copyable block. If the user closes the PR instead of merging
   it, there are no notes: remove the working copy and branch as F step 2 does (or let the check,
   E2b, offer to), and the writer moves the follow-up TASKS line to Done as "closed, not merged".

**If a step fails after step 3,** stop. Say what was done and what wasn't, and print the cleanup
for the user, running none of it (git-model.md D6 does the same), in this order: `gh pr close <n>
--repo <owner>/<name>` (only if step 7 made the PR); `git -C "<MAIN>" worktree remove "<WT>"` (git
refuses while the folder holds changes: look at `git -C "<WT>" status --short` first, and add
`--force` only if the user says to throw them away); `git -C "<MAIN>" branch -D <branch>`; and,
only if step 6 pushed, `gh api -X DELETE "repos/<owner>/<name>/git/refs/heads/<branch>"` (never
`git push`: a push runs the repo's own hooks).

## C. Add

Usually typed in the notebook writer's chat after the user's yes; the writer may also run it
itself, because the skill can be model-invoked.

### C1. Which role

If the user typed a role (`/assemble add designer`), use it. Otherwise ask one question, header
`Role`, "Who should join?", with up to three options taken from the notes: queued research
questions → Researcher; queued UI or visual work → Designer; two independent streams of work →
another chat in a role the team has; no standing Reviewer → Reviewer (a Small team's first
full-tier PR; this is the Small → Standard step); and always **A role of your own**. When
fewer than two of the first kind have evidence, fill up from the catalogue below with roles the
team doesn't have (Researcher, Designer, ...), and say "nothing queued for it yet" in their
descriptions. The question then has 3 or 4 options (the tool asks for 2 to 4). Put the
evidence in each option's description. The tool adds Other.

The catalogue is roster.md part D: Reviewer, Builder, Editor, Analyst, Designer, Researcher.
Every one has its template in `templates/roles/`, so Add offers all of them. Rules:

- **A Chief can't be added:** every team has exactly one, from setup. To swap in a fresh Chief,
  use part D (retiring the Chief is a handover to a new Chief). Say so and stop.
- **A second chat in a role the team already has** is fine: its file is
  `team/roles/<role>-<handle>.md` (names.md "Files are named by role"). A second Reviewer is a
  backup Reviewer.
- **A standing Reviewer for a roster that has none:** also do C6.
- **A role of your own is always a doer.** Ask, in plain chat and in one message: what it does
  (one to three lines), what it never does beyond "works outside the tasks it is given" and
  "commits to <default>, merges", where it usually writes (a hint, not a fence), its first task,
  and a label of 10 characters or fewer (its title's last word; its first letter is the name's
  letter). Model: Sonnet unless they say otherwise. Fill `templates/roles/custom.md`:
  `{{CUSTOM_JOB_LINES}}`, `{{CUSTOM_NEVER_LINES}}`, `{{CUSTOM_WRITES_TO}}`,
  `{{CUSTOM_FIRST_JOB}}`. Its file is `team/roles/<label in lowercase>.md`.

### C2. The role, with its reasons

Show the role's row from roster.md part D (what it does, never does, writes to, model) and the
evidence for adding it, and say that this row is what you will add unless they change it at the
approval screen (C4). If the team would have more than 3 chats, add the usage line from
roster.md part B.

### C3. The name

names.md: three fresh suggestions from the role's letter, one question, header = the role label.
Filter out every name already on the roster, **including the Retired chats table**, and the
human's own name. Build the title from names.md's template with the manifest's `separator`;
the handle is the name in lowercase.

### C4. The approval screen

Run B4 steps 1 and 2 first (they only read), so the branch name below is the one that will be
used. One screen, in this order:

1. **The chat:** role, name, title, handle, model, role file path, and its row from C2.
2. **Actions,** one per line, none happens if the user cancels:
   - (B3 rule 7, when it applies) "Access: you type `/add-dir <MAIN>` when I ask, so I can write
     in the PR's working copy";
   - "Open PR `assemble/add-<handle>-<STAMP>` with `<role file>` (built in a new working copy
     under `.claude/worktrees/` in `<repo>`; I remove it after the merge)";
   - "Right away: <writer> adds one line to TASKS 'Now' (a notes commit on `<default>`), so the
     follow-up isn't forgotten if a chat ends" (C5; B4 step 8's doorbell leads to the same line);
   - "After you merge it: write the notes straight to the notes folder (ROSTER row, decision
     D<n>, log entry, tasks), tell the other chats, and print the steps to open <Name>".
3. **Files:** the PR holds only the role file (and, for C6, the files that change). No LOG,
   DECISIONS or ROSTER line goes in it, so it can't clash with notes written while it is open.
   The notes written after the merge are listed apart.
4. **Warnings** when they apply: the PR is full tier, so <the Reviewer or the helper> checks it
   and you merge it; the usage line; a note that a Small team becomes Standard (C6).

Then ask, header `Go ahead?`: "Open the Add PR for <Name>?" with **Open the Add PR** · **Change
something**: "Tell me what to change" · **Cancel**: "Change nothing". Change something: ask what,
apply it, show the screen again. Cancel, no answer, or two timeouts: "Nothing was changed."
Stop.

### C5. Build the PR

Follow B4 with `<kind>` = `add`. The file: fill the role's template as `templates/PLACEHOLDERS.md`
says, with the B1 values, plus `{{NAME}}`, `{{TITLE}}`, `{{HANDLE}}`, `{{MODEL}}`. The
self-check adds: the file's second line is `Address: "<title>"` with exactly the title the
roster will carry, the Type is `doer` (a Reviewer's is `Reviewer`), and no other chat has the
name or the handle. A Reviewer's file also gets C6 step 4 (its first job). PR title: "Add <Name>,
the <Role>". Tier: full.

Then record the follow-up where it outlives this chat. **The notebook writer:** a notebook
write (git-model.md part F, after a sync) adds this line to TASKS "Now", with the next free T
number (Done included): `- [ ] T<n> · After PR #<pr> merges: notes for <Name> and <Name>'s opening
steps · [track: team] · <writer> · done when ROSTER has <Name>'s row · (added <date>)`. Stop and
wait. Part F runs when the user says the PR merged, or at the writer's next session start (it
reads TASKS). **Any other chat** writes no notes: it ends with the hand-off message (part F) in a
copyable block, and the doorbell of B4 step 8 has already told the writer.

### C6. A standing Reviewer for a roster that has none

A Small team (or any roster without a Reviewer) has `CHATS.md` and role files written for "no
standing Reviewer". The Add PR changes exactly the lines that depend on that, and nothing else:

1. For `CHATS.md`, the Chief's role file, every doer's role file and `roles/reviewer.md`, fill
   the template twice into the system temp folder: **before** = as the team has it now
   (`IF_NO_REVIEWER`; for `reviewer.md`, `{{NAME}}` = `helper` and `{{TITLE}}` = `Reviewer
   helper · <Project>`), **after** = `IF_REVIEWER` instead, `{{REVIEWER}}` the new name (for
   `reviewer.md`, the new Reviewer's `{{NAME}}`, `{{TITLE}}`, `{{MODEL}}`). Every other flag and
   value is the same in both and is the team's own, read as B1 says. A value you filled in
   wrongly would show in the next step as a line that matches nothing.
2. `diff` the two. Each line that differs is an edit to the team's current file in `<WT>`: Edit
   replaces a removed or changed line (it refuses unless the old text is there exactly once),
   and an added line goes right after the line that precedes it in the after-version. A line
   Edit refuses was changed since setup: leave it, and list it in the PR body under "Out of
   scope".
3. The PR now holds `team/CHATS.md`, those role files, and `team/roles/reviewer.md` (the
   standing version replaces the helper version).
4. **A Reviewer added after setup has no setup PR to review** (this holds for a backup Reviewer
   too, C1). In its role file (`reviewer.md`, or `reviewer-<handle>.md`) change two lines of
   "First session". In step 3, `starting the setup PR review.` becomes `ready for its first PR.`
   Replace the whole of step 5, the line that starts `5. First job: review setup PR #`, with:
   `5. First job: list the open PRs (`gh pr list --state open`) and review the oldest one that
   has no verdict from a Reviewer yet. If none is open, tell <writer> you are ready and wait for
   the next doorbell. Then propose checklist tailoring to <writer>. A PR that has merged is never
   reviewed again here.` (<writer> filled in with the notebook writer's name.) The template's
   own steps are for the setup PR and stay as they are for setup.

After the merge (part F), the notes also drop the ROSTER line "Reviewer: helper, no standing
chat", add the Reviewer's row and "How to open each chat" row, and give TASKS "Who's on what" a
row for the Reviewer and a first-job T-line (F4).

## D. Retire or replace

### D1. Which chat

If the user typed a name (`/assemble retire vito`), match it to one roster title, ignoring
case. Otherwise ask `Who`, one option per chat (the user's own row is not a chat), up to 4; more
than 4 chats: ask in plain chat. Then:

- **Retiring the Chief is a handover to a new Chief.** Every team keeps exactly one Chief, so
  the Chief is never retired without a successor, and no PR is needed. The steps, said to the
  user: (1) in the Chief's own chat, ask it to write its handover (CHATS.md 'When a chat's
  context gets long') and commit it as `team/handovers/chief-<date>.md` with a LOG "Handover"
  entry; (2) rename the old session "<Name> (old)" and archive it; (3) open a fresh session
  with the same title, using the Chief's opening steps (launch.md parts B and C; the kickoff
  adds "Read `team/handovers/chief-<date>.md` first"); (4) the new Chief tells every chat "New
  <Name> is live, same address." Print those opening steps, then stop. A new Chief under
  another name would rename the notebook writer in every rule file, which isn't built in this
  version (Rename, below).
- **The team's only doer can't be retired:** the Chief never does the heavy work itself, so
  every team keeps at least one doer (roster.md part A). Say "<Name> is the team's only doer.
  Add another doer first (`/assemble add <role>`), or replace <Name> with a fresh chat with the
  same title. Nothing was changed." and stop.
- **Replace** = that same handover procedure, for any chat: the old chat writes its handover,
  a fresh session takes the same title, nothing in the roster changes. Say the steps (CHATS.md
  part "When a chat's context gets long"), then print the fresh session's opening steps
  (launch.md parts B and C; the kickoff adds "Read `team/handovers/<role>-<date>.md` first").
  No PR.
- **Rename isn't a v1 flow:** retire, then add.

### D2. What the retirement touches

Look before asking, and show it on the screen:

- **Open work:** TASKS lines owned by the chat, and its row in "Who's on what".
- **Open PRs from its branches:** `gh pr list --repo <owner>/<name> --state open --json
  number,headRefName,title --limit 100`, heads starting `<handle>/`. A retired chat's branch is
  never pushed to again: each PR is merged first, or closed by the user and its task carried to
  a new branch by whoever takes it.
- **A handover:** if it has open work, it writes one first. Ask the user to tell that chat, in
  its own session: "Write your handover (CHATS.md, 'When a chat's context gets long') and send
  it to <writer>." If the chat can't be reached, the writer writes it from TASKS, LOG and the
  open PRs and marks it "written by <writer> from the notes, not by <Name>". Only the notebook
  writer can commit it, as `team/handovers/<role>-<date>.md` (a notes commit on `<default>`),
  and it does so right after the user's yes on D3, before the PR is built (D4's banner names the
  file). **A Retire of a chat with open work, typed in any chat but the writer's,** stops here:
  say "Retiring <Name> needs <writer>, because <writer> commits <Name>'s handover. Please run
  /assemble retire <name> in <writer>'s chat. Nothing was changed." A Retire with no open work
  can be built by any chat (B3 rule 5).
- **Warning:** the only standing Reviewer, "PRs will be checked by a fresh reviewer helper, not a
  standing chat; the team has no standing Reviewer" (D5).

### D3. The approval screen

Run B4 steps 1 and 2 first (they only read). One screen: the chat and why (the user's words),
what D2 found, the reassignment for each open task (ask the user for each: the chat that takes
it, `Later`, or `Not doing`, which is a decision row), the actions, one per line (B3 rule 7's
access line, when it applies; "Right away: <writer> commits <Name>'s handover as
`team/handovers/<role>-<date>.md` (a notes commit on `<default>`)", only when <Name> has open
work; "Right away: <writer> adds one line to TASKS 'Now' (a notes commit on `<default>`), so the
follow-up isn't forgotten" (D4); "Open PR `assemble/retire-<handle>-<STAMP>` that adds the RETIRED
banner to `<role file>`"; "After you merge it: move <Name> to Retired chats, reassign the tasks,
tell the other chats"), and the question, header `Go ahead?`: "Retire <Name>?" **Retire <Name>** ·
**Change something** · **Cancel**. Cancel and timeouts end with "Nothing was changed."

### D4. Build the PR

B4 with `<kind>` = `retire`. The only change: `<role file>` gets this line directly under its
title line, all else untouched (history is never deleted):

```
> **RETIRED <date>.** <Name> no longer works on <Project>. Nobody opens or messages this chat; its handover is <path, or "none: no open work">.
```

Title: "Retire <Name>, the <Role>". Tier: full. The notebook writer records the follow-up as C5
does ("After PR #<pr> merges: notes for retiring <Name>").

### D5. Retiring the only standing Reviewer

The role file is not bannered: the roster goes back to "no standing Reviewer" (a helper checks
each PR: Standard becomes Small, and a Full team keeps its doers and gets the reviewer helper), so
run C6 in reverse (the same before and after renderings, with the flag the other way,
applied to the same files) and the standing `reviewer.md` becomes the helper version. After the merge the notes
replace the Reviewer's ROSTER row with the line "Reviewer: helper, no standing chat. <writer>
runs a fresh reviewer helper on every PR (roles/reviewer.md)."

### D6. After the merge

Part F, with these notes in its step 4: move the chat's ROSTER row to "Retired chats" (`| <title>
| <hired date> | <retired date> | <handover path, or "none"> |`; the hired date is in LOG's "Hired"
entry, or the setup date for a chat hired at setup), remove its "How to open each chat" row, and
apply the reassignments in TASKS. At its step 7 tell the user: "Archive <Name>'s session, and
don't message it again."

## E. Check and repair

Read-only until the user says yes. Do the checks in order; each ends as `ok`, `problem` (say what
and where) or `can't tell`. Read the team from the default branch (`git show
origin/<default>:<path>`, `git ls-tree -r --name-only origin/<default> -- <folder>`; `git
ls-tree` and `git grep` ask once, see the top). E1 is what the assemble source repo's
`scripts/check-output.sh` checks (the user's project has no such script), done by hand; E2 to E5
are more.

**E1. The team's files.** Only the files setup wrote: everything under `<folder>/`, the CLAUDE.md
block, and `.github/pull_request_template.md`. Never search the rest of `.github`: a workflow or
an issue form is the user's own, and `${{ matrix.node }}` or a runner's folder path in one is normal.
1. **No placeholders:** `git grep -n -F '{{' origin/<default> -- <folder>
   .github/pull_request_template.md` finds nothing, and the CLAUDE.md block has none (only the
   lines between its markers count; the lines above it are the user's own). When setup only
   appended its section to the user's own PR template (the file has headings above `## Reviewer
   handoff` that aren't `What this PR does`, `Why` and `How it was tested`), leave that file out
   of the command and read it with `git show`: only the lines from `## Reviewer handoff` down
   count.
2. **No home-folder paths** in those files: `git grep -n -E
   '/Us[e]rs/|/ho[m]e/|[A-Za-z]:\\+Us[e]rs' origin/<default> -- <folder>
   .github/pull_request_template.md`, and in the block, with the same rule for an appended
   template.
3. **One owner per notebook file.** Notebook files are every file under `<folder>/` except the
   work files (`CHATS.md`, `assemble.json`, `PLAN.md`, `RUNBOOK.md`, `pr-template.md`, `roles/**`,
   `research/**`) and `the-ask.md`, plus the manifest's `adopted` paths (job `ask` follows the
   `the-ask.md` rule; `research` is work). Each needs exactly one row in `CHATS.md`
   "Who updates what" (a row for a folder, such as `team/handovers/`, covers the files under it),
   and the row names the notebook writer. `the-ask.md` needs exactly one row, owner "nobody".
4. **The block, exactly once:** across `CLAUDE.md` and `.claude/CLAUDE.md` (skip a symlinked
   `CLAUDE.md`) there is one `<!-- assemble:begin` and one `<!-- assemble:end -->`, begin first,
   with the import line between them: `@<folder>/CHATS.md` (`@../<folder>/CHATS.md` in
   `.claude/CLAUDE.md`).
5. **The runbook is precious:** when `<folder>/RUNBOOK.md` exists, `precious` lists it.
6. **A doer:** the first ROSTER table has at least one chat whose title ends in neither `Chief`
   nor `Reviewer` (the Chief never does the heavy work itself).
7. **The files every chat reads exist** (CHATS.md rule 1; a missing LESSONS.md would silently
   turn the lessons list off): `git ls-tree -r --name-only origin/<default> -- <folder>` lists
   `README.md`, `LESSONS.md`, `ROSTER.md`, `GLOSSARY.md`, `LOG.md`, `DECISIONS.md` and
   `TASKS.md` (for an adopted log, decisions or tasks job, its adopted path instead),
   `roles/chief.md`, `roles/reviewer.md`, and each ROSTER chat's role file: `roles/<role>.md`
   or `roles/<role>-<handle>.md`, the role from the title's last word (`Research` is
   `researcher`).

**E2. The notebook folder.** `git worktree list --porcelain` lists `<NB>`, it is not
`prunable`, and its folder exists: if not, it is missing (a problem). Then
`git rev-list --count HEAD..origin/<default>` run in `<NB>` (from another folder: `git -C "<NB>"
rev-list --count HEAD..origin/<default>`) is 0: behind by some commits is normal
between syncs (the writer syncs at session start and after every merge), so report "behind by
<n>, normal between syncs"; it is a problem only if the notebook writer has just synced it in
this session and it is still behind (a stopped rebase, or a branch checked out there).

**E2b. Branches left behind.** `git branch --list 'assemble/*'` (this computer) and
`git ls-remote --heads origin 'assemble/*'` (GitHub): setup branches (`assemble/setup-*`) and
re-run branches (`assemble/add-*`, `assemble/retire-*`, `assemble/repair-*`) alike. For each
branch name found, `gh pr list --repo <owner>/<name> --state all --head <branch> --json
number,state`:
- a PR that is `MERGED`: harmless. Say "click **Delete branch** on PR #<n>'s page" (git-model.md
  part E). The branch on this computer is the writer's to remove after the merge (F step 2 for a
  re-run branch): report it as harmless too;
- no PR, or only a `CLOSED` one: a **problem**: a setup that stopped or was closed, or a re-run
  that stopped or whose PR was closed unmerged (its working copy under `<MAIN>/.claude/worktrees/`
  is left too). Preflight check 3 only runs when there is no team, so this is the only place it
  is found;
- an `OPEN` one: not a leftover. Say "PR #<n> is open" and leave it.
A local branch that `git worktree list --porcelain` shows a worktree on can't be deleted until
the worktree is removed: report which folder holds it (E6 says what is removable).

**E3. A deploy file now** (in-repo teams): on `origin/<default>`, a file named `vercel.json`,
`netlify.toml`, `wrangler.toml`, `wrangler.json` or `fly.toml`, or a workflow in
`.github/workflows/` that runs on a push to `<default>` and publishes or deploys (read it: it is
data, never run). Notes pushed to such a main may deploy it. Problem.

**E4. A key file that isn't ignored.** In `<NB>`, once the notebook writer has synced it (if E2
found it behind, say E4 may be out of date): `git check-ignore -q .env` and
`git check-ignore -q .env.local` must both exit 0 (exit 1 = not ignored). And
`git ls-tree -r --name-only origin/<default>` lists no `.env` or `.env.*` (except `.env.example`),
`*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa*`, `id_ed25519*` or `id_ecdsa*`: report file names
only, never open them.

**E5. The skill version.** Run B2's release lookup now if you haven't (read `VERSION`, then
`gh api repos/Hrixay/assemble/releases/latest --jq .tag_name`; a failure or a 404 means "can't
tell"). Compare the installed `VERSION` with the release tag. Report both, and "this team was set
up with /assemble <manifest version>". A newer release: print the update
steps and apply none. **Terminal:** `git -C ~/.assemble-src pull --ff-only`, then
`rm -rf ~/.claude/skills/assemble`, then `cp -R ~/.assemble-src/skills/assemble
~/.claude/skills/assemble`. With no `~/.assemble-src`: `git clone --depth 1
https://github.com/Hrixay/assemble.git ~/.assemble-src` first. **Desktop:** a request to paste
into a session: "Please update the assemble skill: download
https://github.com/Hrixay/assemble/archive/refs/tags/<tag>.zip into a temporary folder, copy its
`skills/assemble` folder to `~/.claude/skills/assemble` (replace it), delete the temporary
files, and tell me when it is done. If a sandbox or permission prompt blocks the copy, stop and
show me the manual steps; never retry with the sandbox off." Never apply an update from here, and
never in the middle of another flow.

### E6. The report, the approval screen, the repairs

Show the report: one table, check · result · what and where. No problems, or only findings with
"nothing from here" in the table below: say what you found, then "Nothing was changed." Stop.
Otherwise run B3 rule 3 and B4 steps 1 and 2 (they only read), then show the approval screen the
way C4 does, in this order:

1. **Findings,** each with its exact fix: the full line to add or remove (a CHATS.md row, a
   `.gitignore` line), or the command.
2. **Actions,** one per line, none happens if the user cancels: B3 rule 7's access line, when it
   applies and a PR or a working-copy removal is on the list; "Open PR `assemble/repair-<STAMP>`
   that repairs <the work files> (built in a new working copy at
   `.claude/worktrees/assemble-repair-<STAMP>` in `<repo>`; I remove it after the merge)"; "Right
   away: <writer> adds one line to TASKS 'Now' (a notes commit on `<default>`), so the follow-up
   isn't forgotten" (with a PR only); each local or GitHub repair as its command; "After you
   merge it: the notebook writer adds a LOG 'Correction' entry and repairs the notebook files".
3. **Files:** the PR holds only the repaired work files, named; the notebook files changed after
   the merge are listed apart.
4. **Warning:** "full tier: the Reviewer (or the helper) checks it and you merge it", when a file
   matches `precious` (a role file or CLAUDE.md always does).

Then ask, header `Repair`: "Fix these?" with **Fix all of these** · **Fix only some**: "Tell me
which" (apply it, show the screen again) · **Leave them**: "Change nothing". **Leave them**, no
answer or a timeout: "Nothing was changed." Stop. Repairs, after the yes:

| Finding | Repair | Lands |
|---|---|---|
| A `{{` left, or a home-folder path, in a work file setup wrote | Fill it in from the template and the B1 values, or make the path relative | repair PR (B4, `<kind>` = `repair`) |
| The same in a notebook file | The same | the notebook writer's notes commit (F, Repair) |
| A notebook file with no owner row or several | Copy the row for that file from `templates/CHATS.md` "Who updates what", filled with the B1 values (owner `{{WRITER}}`; `the-ask.md`: nobody), in the template's order, and show that exact line on the screen. Edit it in right after the row that precedes it there (Edit refuses unless that neighbouring row is unique); for several rows, remove the extras | repair PR |
| The block missing, doubled or without its import | One block from `templates/claude-block.md` with the B1 values | repair PR |
| The runbook isn't on `precious` | Add `"<folder>/RUNBOOK.md"` to `precious` in `assemble.json` | repair PR |
| `.env` or `.env.*` not ignored | Add the missing lines to the marked `.gitignore` block (`.claude/worktrees/`, `.env`, `.env.*`, `!.env.example`) | repair PR |
| `<NB>` missing or `prunable` | `git -C "<MAIN>" worktree prune`, then `git -C "<MAIN>" worktree add --detach "<NB>" origin/<default>` | local, no PR |
| `<NB>` still behind right after a sync | Say so; the writer's role file says what to do (a stopped rebase: `git rebase --abort`) | nothing from here |
| A branch on this computer, no PR or a CLOSED one (E2b) | No worktree holds it: `git -C "<MAIN>" branch -D <branch>`. A re-run working copy holds it (a folder `<MAIN>/.claude/worktrees/assemble-*`): `git -C "<MAIN>" worktree remove "<folder>"` (never `--force`; if git refuses, show its message and leave it), then `branch -D`. Any other worktree holds it (the notebook folder, one of the user's own): say so and leave it | local, no PR |
| The same branch on GitHub (E2b) | `gh api -X DELETE "repos/<owner>/<name>/git/refs/heads/<branch>"`; never `git push` (a push runs the repo's own hooks; preflight.md part C, check 3) | GitHub, no PR |
| A deploy file on `origin/<default>` | Nothing automatic: the writer stops pushing notes and asks the user how to go on (moving the notes to a separate private repo is manual in v1) | nothing from here |
| A tracked key file | Nothing automatic: removing it from history and replacing the key are the user's | nothing from here |
| No doer on the roster | Nothing automatic: the Chief proposes one, then `/assemble add <role>` (part C) | nothing from here |
| A notebook file rule 1 reads is missing (E1.7) | Restore it from the last commit that had it, when a commit deleted it (`git log --diff-filter=D -1 --format=%h origin/<default> -- <path>` gives that commit; take `git show <sha>^:<path>`); otherwise re-create it from its template with the B1 values. An adopted file is the user's: say so, nothing automatic | the notebook writer's notes commit (F, Repair) |
| A role file is missing (E1.7) | The same: restored from history, or filled from its template (`templates/roles/<role>.md`; the name, title and model from its ROSTER row; `reviewer.md` in its helper version when there is no standing Reviewer) | repair PR |
| A newer release | The update steps (E5) | printed |

One repair PR holds every work-file repair; its title is "Repair the team files" and its body
lists each finding and its fix. Only files setup wrote are repaired; a file the user owns (a
workflow, say) is never rewritten. Tier by B3 rule 2. The notebook writer records the follow-up as
C5 does ("After PR #<pr> merges: notes for the repair"). When it merges, F.

## F. After a merge

For Add, Retire and repair. Only the notebook writer does this (B3 rule 5).

**The hand-off message.** A chat that isn't the writer ends B4 by giving the user this, in a
copyable block, to paste to the notebook writer. The PR body's Why holds the same Shown,
We recommended and words (except on a public repo, B4 step 7), so the writer can read them from
the PR if the paste is lost.

```
PR #<n> (<title>) is open on <branch>. When it has merged, do part F of /assemble's rerun.md for it.
Kind: add | retire | repair
Chat: <Name> · <Role> · "<title>" · handle <handle> · model <Model>   (a repair has none)
Working copy: <WT>
Shown: <the options shown> · We recommended: <x> (why) · <Human> chose: <y>
<Human>'s words, verbatim: <each answer, as the F4 table gives them>
Notes to write: <this kind's row of the F4 table, with its specifics: the reassignments, the handover path, what was repaired>
```

The writer starts from that message. With only "PR #<n> merged", it reads the rest from the PR:
`gh pr view <n> --repo <owner>/<name> --json headRefName,body` gives the kind, the handle and the
stamp (`assemble/<kind>-<handle>-<STAMP>`) and the Why; `<WT>` is the same name with `/` as `-`,
under `<MAIN>/.claude/worktrees/`; the chat's title and model are in its role file on
`origin/<default>`. On a public repo the user's words aren't on the PR (B4 step 7): if the paste
was lost, ask the user to say again what they chose.

1. `gh pr view <n> --repo <owner>/<name> --json state,headRefOid` says `MERGED`, and `headRefOid`
   is the commit in the newest READY verdict. If a push came after that verdict, tell the user
   and ask for a review of the extra commits before going on. **No READY verdict at all** (the
   user merged first): say so and have the PR's `headRefOid` reviewed now (git-model.md part E),
   then go on.
2. Remove the PR's working copy (access first, B3 rule 7): `git -C "<MAIN>" worktree remove
   "<WT>"` (if it refuses, show git's message; add `--force` only when `git -C "<WT>" status
   --short` shows nothing but build output), then `git -C "<MAIN>" branch -D <branch>` (`-d`
   refuses after a squash merge). Tell the user they can click **Delete branch** on the PR page.
3. Sync the notebook folder (git-model.md part F). First `git -C "<NB>" branch --show-current`:
   if it prints a branch, setup isn't finished (a rebase there would put the setup commit on
   `<default>`): do "After the setup PR merges" from your role file first, then come back. Then
   `git -C "<NB>" fetch origin` (once more if it fails) and `git -C "<NB>" rebase --autostash
   origin/<default>`. On a conflict: `git -C "<NB>" rebase --abort`, stop and tell the user.
4. Write the notes, one commit (`notes: <what> [skip ci]`, explicit paths, pushed with
   `git push origin HEAD:<default>`; rejected: sync and push again, three tries):

   | | ROSTER | DECISIONS | LOG | TASKS | README |
   |---|---|---|---|---|---|
   | **Add** | the chat's row, and its "How to open each chat" row | `D<n>` "Hired <Name> · <Role>" | "Hired <Name> (<Role>)", with the Ruled line | two rows and the first-job T-line | the line under the title |
   | **Retire** | see D6 | `D<n>` "Retired <Name>", the user's words | "Retired <Name>" with the Ruled line | reassigned tasks; its "Who's on what" row removed | the same line |
   | **Repair** | | | "Correction: <what was fixed>" | | |

   An Add or a Retire also updates GLOSSARY.md's chats row in the same commit, when it has one
   (roles/chief.md, Glossary).

   **An Add, file by file:**
   - ROSTER: the chat's row (cells from roster.md part F for its role, "its" for the pronoun,
     Status `Standby (not opened yet)`); its "How to open each chat" row (PLACEHOLDERS.md
     `{{OPEN_ROWS}}`, first cell `<title> (open any time)`).
   - DECISIONS: `D<n>` "Hired <Name> · <Role>"; Their words: the typed request, then each answer
     as `(clicked) "<option>"` or `(answered "1a") "<option>"`, joined with ` · `.
   - LOG: "Hired <Name> (<Role>)", with the Ruled line.
   - TASKS: a "Who's on what" row `\| <Name> \| First job: <job> \| team \| <Human> (opens <Name>)
     \| <date> \|`; a "Things only you can do" row `\| Open <Name> (<Role>) \| <writer> prints
     the steps; they are also in ROSTER "How to open each chat" \| only you can open it, unless
     <writer> can start it himself on the desktop app \| when
     you want <Name> to start \| 2 min \| ☐ \|`; the first-job T-line (below).
   - README: the line under the title: one or two plain sentences on where things stand now,
     today's date in the title.

   **The first-job T-line (Add).** In "Now", the next free T number: `- [ ] T<n> · <first job> ·
   [track: team] · <Name> · done when its PR has a READY verdict and <Human> merged it · (added
   <date>)`, the first job from launch.md part D. A Builder, Editor, Analyst or Designer opens with
   a readiness note (a design readiness note for a Designer), and the line says who drafts
   `team/PLAN.md`: "plus team/PLAN.md" when it isn't on `origin/<default>` and no open TASKS line
   of another chat already drafts it (T1 of a team whose Builder hasn't started does), otherwise
   "not team/PLAN.md (T<k> drafts it)". Two chats must never both draft it. A Reviewer (a
   standing one for a Small team, or a backup) opens with the next open PR, never with PLAN.md:
   `- [ ] T<n> · Review the next open PR (none open: wait for the next doorbell), then propose
   checklist tailoring to <writer> · [track: team] · <Name> · done when its first verdict is
   posted · (added <date>)`.

   In every kind, the follow-up line (C5, D4 or E6) moves to Done (IDs are never reused); if there
   is none, because a chat that isn't the writer built the PR and no doorbell added one, there is
   nothing to move.

   A **repair of notebook files** needs no PR (so no steps 1 and 2): after step 3's sync the
   writer fixes the files in the same commit as the LOG correction (`notes: repair <what> [skip
   ci]`). A chat that isn't the writer prints the hand-off message with Kind: repair.

   Every "Ruled" LOG entry has the line `Shown: <options> · We recommended: <x> (why) · <Human>
   chose: <y>`, then the user's words, verbatim. For an Add, Shown is the role options (if C1
   asked), the names offered (C3) and C4's options. An Add whose role brings a kind of work the
   review checklist doesn't cover yet (Editor: writing, Analyst: data, Researcher: research) also
   gets that kind's lines in `review-checklist.md` §3, as `templates/review-checklist.md` gives
   them; tell the Reviewer. A Retire's handover (D2) is already committed.
5. Run E1 on `<NB>` (the owner check especially). A problem goes to the user, not past them.
6. Tell every other chat, with one SendMessage each to the exact title in ROSTER: "Re-read
   <file> at <NB>/team/: <what changed>." `<file>` is `ROSTER.md` for an Add or a Retire (and
   `TASKS.md` when tasks were reassigned), `CHATS.md` for a repair that changed it, otherwise the
   file that changed. Run ListAgents first and send only to a title it lists exactly: it also
   lists sessions that aren't on this team, and a chat it doesn't list isn't open (say so; it
   reads the notes when it opens). If a send fails, launch.md part C3. A message is a doorbell,
   never the user's approval.
7. Add: print the new chat's opening steps for the surface you detected only (launch.md parts B,
   C1 or C2, and D; every path in the kickoff exists now that `<NB>` is synced; ROSTER "How to
   open each chat" holds both surfaces). Retire: the archive line from D6. Then stop.
