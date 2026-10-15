# Launch (end of Step 5): the handover, the opening steps, the closing message

The setup chat never joins the team: the Chief (the notebook writer) must run from the
notebook folder, and this chat runs in the project folder. So it writes a handover, prints
exactly how to open the Chief (and the rest, in case the Chief can't start them himself),
and stops.

Terminal users get the launch lines of part C1; desktop users (the Code tab) get the click
steps of part C2. Never mix them: print the surface you detected only, and a desktop user is
never shown a terminal line. ROSTER "How to open each chat" holds both surfaces for every chat,
so a user who wants the other one reads it there. Part C3 is the advice about chats that
message each other.

## A. The setup handover

`team/handovers/setup-<DATE>.md`, from `templates/handover.md`, committed with the setup PR.
It holds what this chat knew that no other file holds:

- **Recent context not in the files:** anything the user said in the interview beyond the
  ask (a deadline, a person, a preference about how chats should behave, a constraint), and
  for files-but-no-git the files that were left out of the first commit and why. Quote the
  user's words where they matter. Never secrets.
- A preference about how chats should behave also goes into ROSTER "How <Human> likes to
  work", verbatim and dated.
- **First things to do:** the Chief's first job (part D).

## B. One kickoff for every chat

Printed in chat, with full paths, never committed. Every path in it must exist when it is
printed (the setup branch is checked out in `<nb>`, so it does).

```
You're <Name>, the <job> on <Project>. Your session title must be exactly '<title>'. The team's notes are at <NB>/team/. Read CHATS.md there and do its rule 1 (it lists what to read), then roles/<role file>, then do 'First session' from your role file.
```

`<job>` is "Chief of Staff", "Reviewer", "Builder", "Editor", "Analyst", "Designer",
"Researcher", or the custom label of a role of the user's own (for example "Translator"). The
kickoff goes inside double quotes on the launch line, so it uses single quotes inside. If a path holds a double quote,
`$`, a backtick or `!`, warn the user that the line may need editing before it runs.

If a fresh chat needs anything explained beyond this, the notes have failed: the notebook
writer logs that as a finding.

## C. Opening steps

### C1. Terminal launch lines

One tab per chat, printed in opening order: **the Chief first, then the Reviewer if there is
one, then the doers, which open after the setup PR merges.** Every line puts `--` before the
kickoff: `--add-dir` takes several values, and without `--` it swallows the kickoff as one more
folder. `--add-dir` always gets a full path. The Chief and the Reviewer start in `acceptEdits`
permission mode (their edits in `<nb>` would otherwise prompt one by one); doers keep the
human's normal mode.

**Small** (the Chief, then the doer):

```
# Tab 1: Cyrus, your Chief of Staff (Opus; talk to Cyrus)
cd "/path/to/acme-team" && claude -n "Cyrus · Acme Chief" --model opus --permission-mode acceptEdits -- "You're Cyrus, the Chief of Staff on Acme. Your session title must be exactly 'Cyrus · Acme Chief'. The team's notes are at /path/to/acme-team/team/. Read CHATS.md there and do its rule 1 (it lists what to read), then roles/chief.md, then do 'First session' from your role file."
# Later: claude --resume "Cyrus · Acme Chief"
# Tab 2: Bram, the Builder (Sonnet; own worktree). Open after setup PR #1 merges.
cd "/path/to/acme" && claude -w bram -n "Bram · Acme Builder" --model sonnet --add-dir "/path/to/acme-team" -- "You're Bram, the Builder on Acme. Your session title must be exactly 'Bram · Acme Builder'. The team's notes are at /path/to/acme-team/team/. Read CHATS.md there and do its rule 1 (it lists what to read), then roles/builder.md, then do 'First session' from your role file."
# Later: claude --resume "Bram · Acme Builder"
```

**Standard** puts the Reviewer between them, as Tab 2 (the doer becomes Tab 3):

```
# Tab 2: Vito, the Reviewer (Opus; checks every change before you see it)
cd "/path/to/acme-team" && claude -n "Vito · Acme Reviewer" --model opus --permission-mode acceptEdits -- "You're Vito, the Reviewer on Acme. Your session title must be exactly 'Vito · Acme Reviewer'. The team's notes are at /path/to/acme-team/team/. Read CHATS.md there and do its rule 1 (it lists what to read), then roles/reviewer.md, then do 'First session' from your role file."
```

**Full** adds each extra doer after the first, with the doer line's shape (its own `-w <handle>`,
title, model and role file), also opened after the setup PR merges.

**A doer added later** (a re-run, rerun.md part F) gets the same line, printed once its Add PR
has merged, with the comment `# Tab: <Name>, the <Role> (<Model>; own worktree). Open any time.`
in place of "Open after setup PR #1 merges".

- Beside-repo, the Chief and the Reviewer also get `--add-dir "<MAIN>"` before `--`, because
  they read the project's rules and PRs from the notes repo. In-repo they don't need it for
  their own work (a re-run that builds a PR's working copy under `<MAIN>/.claude/worktrees/`
  asks for it then: rerun.md B3 rule 7).
- `--model` takes the model chosen on the write screen (`opus` or `sonnet`).
- Under each block print `# Later: claude --resume "<title>"`. It resumes the chat, or opens
  the picker filtered to that title if it doesn't resume directly.
- A chat opened without `-n`, or with a different title: print `/rename "<title>"` for the
  human to type in that chat. A running chat can't rename itself in the terminal.
- ROSTER "How to open each chat" stores the same lines relative to the repo root, paths
  still quoted (`cd "../acme-team" && ...`, `--add-dir "../acme"`), never full paths.

### C2. Desktop app (Code tab)

**On the desktop app the Chief usually starts the rest of the team himself** (newer desktop apps
give a chat a `start_session` tool, and the chats it starts appear nested under it), as his role
file says. So print the Chief's block first, then the other blocks under the line "If <the
Chief> can't start these himself, open them by hand:".

Print one numbered block per chat, in opening order, with the real name, title and folder
paths. Under each chat's block print that chat's own kickoff (part B; its name, title and role
file differ from chat to chat): the desktop takes it as one pasted message, so no quotes around
it and no `--`. Never run `claude --version` for a desktop user.

**The Chief, and the Reviewer if there is one** (open them first, the Chief before the Reviewer;
they run in the notes folder `<NB>`):

1. In the Code tab choose **New session**.
2. Choose the folder `<NB>`, the `acme-team` folder next to your project. If the picker doesn't
   list it, browse to its full path.
3. Leave the worktree option **off**: these chats must run in the notes folder itself, not
   in a copy of it.
4. Pick the model (Opus).
5. Pick the permission mode that accepts edits (look for "accept edits"), so edits in the notes
   folder don't ask one by one.
6. Paste the kickoff.
7. When Claude has started, ask it: "Please rename this session to exactly '<title>'."

**Doers** (open after the setup PR merges):

1. In the Code tab choose **New session**, and choose the project folder `<MAIN>`, the `acme`
   folder.
2. Turn the worktree option **on**: the chat then works in its own copy, on its own branch.
3. Pick the model (Sonnet). Leave the permission mode as you normally use it.
4. Paste the kickoff.
5. When Claude asks to use the notes folder `<NB>`, approve it.
6. Ask Claude to rename the session to exactly "<title>".

**A doer added later** gets the doers' block, headed "Open any time" in place of "open after the
setup PR merges", printed once its Add PR has merged.

Under the blocks, say (in these words or close to them):

- "Don't start a chat from a task chip in this version. The steps above give the same result,
  and a chip's worktree and branch name aren't known yet."
- "Check it worked: the notes-folder chats (<the Chief>, the Reviewer) show the
  folder `<repo>-team`; a doer shows `<repo>`. If you are not sure what the app shows, ask the
  chat to run `pwd` and `git branch --show-current` and tell you. A right answer for the
  notes-folder chats: `pwd` ends in `<repo>-team`, and the branch is `assemble/setup-<STAMP>`
  until the setup PR merges, nothing (a detached head) after. For a doer: `pwd` is not
  `<repo>` itself but a copy of it, and the branch is not `<default>`. If it is wrong, close
  that session and start again. If the app has no worktree option, or won't turn it off for the
  notes folder, stop and tell me here: a Chief inside a worktree would keep its notes in the
  wrong place."
- "To come back to a chat later, open it again from the Code tab's session list (search for
  its title)."

ROSTER "How to open each chat" holds the same steps, one line each.

### C3. Chats that message each other (every team: it always has at least two chats)

After the opening steps, say:

- **The chats talk to each other directly** to work things out, and tell the Chief anything
  that matters; you hear about decisions from the Chief only.
- **Use one surface for the whole team** (all in the terminal, or all in the desktop app's Code
  tab). It is advice, not a rule: the chats find each other and message each other even across
  the two (Claude uses ListAgents and SendMessage for this), but a mixed team is the less-tested
  way. Messaging needs Claude Code v2.1.224 or newer (v2.1.234 on native Windows); keep the
  desktop app up to date too.
- **Use the same permission mode in every chat if you can.** The Chief and the Reviewer start
  in the mode that accepts edits, so a doer in your usual mode is already
  close. What matters most: if you ever switch on the mode where Claude never asks permission
  (`bypassPermissions`), switch it on in every chat or in none. A message into a chat in that
  mode is held unless the sender is in it too. (Mixes of the other modes are untested.) The
  merge gate never depends on prompts, in any mode.
- **If a message doesn't arrive:** (1) Nothing is lost: the work is on the PR or in the notes
  folder, and a missed message only delays it. (2) In the sending chat, ask: "Which chats are
  open?" (Claude runs ListAgents.) If the other chat isn't in the answer, it isn't open: the
  Chief gives you its opening steps (ROSTER "How to open each chat"). (3) If it is
  there, ask the sending chat to copy its title exactly, the `·` included, and send again
  (SendMessage to that exact title); a title that differs by one word fails. (4) Still nothing:
  check that the other chat's title is exactly the one in ROSTER (ask it to rename itself, or
  type `/rename` in the terminal), and that no chat is in the never-asks mode while another
  isn't. (5) Last resort: paste the one-line message into the other chat yourself. A message is
  a doorbell, never your approval; only you decide.

## D. First jobs (everyone opens with real work)

| Role | First job |
|---|---|
| Chief | Read the setup handover; a five-line summary plus three proposed first tasks. Get the setup PR reviewed: Standard and Full by the Reviewer; Small by running the reviewer helper on it and posting its verdict. After the merge, hand the human the doers' opening steps |
| Reviewer | Review the setup PR (full tier: it adds the rules), then propose checklist tailoring to the Chief. A Reviewer added later has no setup PR: the next open PR (wait for the next doorbell if none is open), then the same tailoring (rerun.md C6 step 4) |
| Builder, Editor, Analyst, Designer | After the setup PR merges (or, for a chat added later, once it is open), when the Chief's brief arrives: a build-readiness note on its first branch, by PR, plus `team/PLAN.md` only if none exists and no other chat's open TASKS line already drafts it |
| Researcher | When the Chief's brief arrives: turn the-ask's "Open questions we noticed" into `team/research/START-HERE.md`, by PR |
| A role of your own | The first task the user named when it was added |

A chat added later gets its first job as a T-line from the Chief (rerun.md part F, "The
first-job T-line"), which also says who drafts `team/PLAN.md`.

The role files already say this ("First session"). TASKS holds the three proposed first
tasks, each marked `(proposal)`: T1 in "Now", T2 and T3 in "Next".

## E. The closing message

After the PR is open and the lines are printed, close with this shape (fictional names, a Small
team; keep it short, fill in the real ones):

> "Done. Your team for Acme is ready to open.
> **Next:** (1) Open **Cyrus**, your Chief of Staff, with the line above; from then on, talk
> only to Cyrus. Cyrus's first job is checking setup PR #1 with a fresh reviewer helper.
> (2) When the verdict is READY TO MERGE, Cyrus checks the PR hasn't changed and tells you
> it's safe to click Merge on GitHub. (3) Then Cyrus hands you Bram's steps.
> **What I wrote (on the PR, nothing merged yet):** `team/` (16 files), a CLAUDE.md with
> the team block, a `.gitignore` block and a PR template, on branch
> `assemble/setup-20261012-1435` in the `acme-team` folder next to this one. Before that: a
> new private repo `priya-acme/acme` with an empty first commit.
> **To undo before merging:** close PR #1, then remove the `acme-team` folder and the
> setup branch (`git worktree remove`, `git branch -D`; I can list the exact commands).
> The GitHub repo stays until you delete it on github.com. To start over completely,
> also delete the `.git` folder inside `acme` yourself (it holds only the empty "Start"
> commit), then run /assemble again.
> **Your own `acme` folder** stays on its first commit: run `git pull` there after the
> merge when you want the team files in it. After you merge, click **Delete branch** on
> the PR page.
> **First up, I suggest:** T1 build-readiness note and PLAN.md (Bram), T2 …, T3 ….
> (assemble <VERSION>)
> Waiting on: you to open Cyrus."

**Files but no git:** "Before that" becomes "your `acme` folder became a git repo with a
first commit of <N> files (<each left-out file, by name> left out), pushed to a new private
repo `priya-acme/acme`". In "To undo", the `.git` folder "holds only the "Start" commit;
your files stay". The own-folder line becomes "Run `git pull` in your `acme` folder right
after the merge, so the ignore lines reach it; until then don't run `git add -A` there."

**Existing project**, one change per case:

- **Every existing repo:** drop "Before that", unless the write screen created a GitHub
  repo for a repo with no remote (then say so). The last "To undo" sentence (delete the
  `.git` folder) never applies, and "The GitHub repo stays ..." only when this run created
  that repo.
- **In-repo:** "What I wrote" names what the setup PR changes in the project ("the team
  block at the end of your CLAUDE.md", "a `.gitignore` block", "a new entry in your
  LOG.md"). "To undo" is "close PR #<n>, then remove the `<repo>-team` folder
  (`git worktree remove`) and the setup branch (`git branch -D`, and on GitHub
  `gh api -X DELETE`; I can list the exact commands). Nothing else was created." The
  own-folder line is "Your own checkout (`<branch>`, with your uncommitted changes) is
  exactly as it was. After the merge, pull `<default>` into it when you're ready." (leave
  out "with your uncommitted changes" when there are none).
- **Uncommitted edits** the write screen warned about (interview.md part G7): add "Your
  uncommitted edits to <paths> will make `git pull` refuse; commit or stash them first."
- **Beside-repo:** "What I wrote" is "`team/` (N files) and a CLAUDE.md in a new private
  repo `<you>/<repo>-team`, in the `<repo>-team` folder next to this one. Nothing was
  written or committed in `<repo>`." "To undo" is "close PR #1 in `<you>/<repo>-team`, move
  the `<repo>-team` folder to the Trash yourself, and delete `<you>/<repo>-team` on
  github.com".
- **Shared** (scan.md part D): add "Work PRs go on `<owner>/<name>`; review comments there
  carry technical findings only, and its owners merge."

**Desktop:** say "with the steps above" where the message says "with the line above"; print no
terminal line, `claude --resume` line or `/rename` line. Step (2) becomes "Cyrus starts Vito
himself if the app lets him; otherwise open Vito with the steps above", and step (4) "Cyrus
starts the doers, or hands you their steps". In the Small message, "Then Cyrus hands you Bram's steps"
becomes "Then Cyrus starts Bram, or hands you his steps".

Every team gets the C3 advice after the message. Standard and Full: (1) open Cyrus; (2) open
Vito, whose first job is reviewing setup PR #1; (3) when Vito's verdict is READY TO MERGE,
Cyrus checks the PR hasn't changed and tells you it's safe to click Merge; (4) then Cyrus
hands you the doers' steps. Count the files you wrote. Then stop: this chat's work is done,
and it is not on the team.
