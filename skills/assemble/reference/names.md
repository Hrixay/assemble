# Names (Step 3, and `/assemble add` later)

How to suggest a name for each chat, and how a name becomes the chat's session title, its
handle and its file names. Ask the names question only after the user approved the team
(interview.md part D).

## Rules

1. **The first letter is the job's letter:** C (Chief of Staff), V (Reviewer, V for Verify),
   B (Builder), E (Editor), A (Analyst), D (Designer), R (Researcher), or a custom role's topic
   letter. Two roles never share a letter; two chats in the same role (a second
   Builder) share it.
2. **Three fresh suggestions per role.** Take them from that letter's pool below, in order:
   the three "Suggested first" names, and when rule 3 removes one, the next name from "More
   in the pool". Every name here is short (10 characters or fewer, so titles fit), easy to
   say for voice typing, and the pools mix cultures.
3. **Filter out:** every name on the avoid list below, the human's own first name, and any
   name already in the team or sounding like one (Eli and Ellis, Remy and Rumi).
4. **A letter without a pool** (a custom role): propose 3 fresh names that start with that
   letter, in the same style as rule 2, and check them against rule 3.
5. **A typed name always wins** (the question's Other row). Accept letters and hyphens, up to
   10 characters, not already used in the team (ignoring case). If it breaks one of those
   limits, say which one and ask again. If it doesn't start with the job's letter, say once:
   "Fine, the letter hint just won't work for this one."

## Pools (8 or 9 names per letter)

| Letter | Role | Suggested first | More in the pool |
|---|---|---|---|
| C | Chief of Staff | Cyrus · Celia · Cormac | Chen, Cosmo, Calla, Cato, Citlali |
| V | Reviewer | Vito · Vanya · Viggo | Vashti, Valentin, Vinny, Vidya, Vusi |
| B | Builder | Bram · Bilal · Bea | Bruno, Bex, Bodhi, Birgit, Bastian |
| E | Editor | Esme · Ezra · Eli | Emil, Ena, Ellis, Eshan, Elif |
| A | Analyst | Ada · Arjun · Alma | Abe, Anya, Aziz, Ama, Anouk |
| D | Designer | Dara · Dev · Dita | Dagny, Dario, Duc, Della, Dov |
| R | Researcher | Rhea · Ravi · Remy | Rafe, Rina, Rumi, Reza, Runa |

## Avoid list (never suggested; a typed name is still allowed)

- The author's six original names, reserved (only the maintainer writes them, on this one line, which the release denylist allows): none listed yet. Close sound-alikes: Clare, Cara, Veera, Benny, Rose, Sami, Norah.
- Other products' persona names: BMAD (Mary, John, Winston, Amelia, Sally, Paige, Bob, James,
  Quinn, Sarah), Marblism (Eva, Penny, Sonny, Cara, Walter, Alisson), Sintra (Buddy, Cassie,
  Dexter, Penn, and others).

## The names question

One question per role, at most 4 per AskUserQuestion call. The header is the role label (as
in the title below), the options are the three suggestions, and the tool adds Other. Example:

- Header `Reviewer`: "Name your Reviewer, who checks every change before you see it.
  Suggestions start with V for Verify." Options: **Vito** · **Vanya** · **Viggo**, each with
  its title as the description ("Vito · Acme Reviewer").
- Header `Chief`: "Name your Chief of Staff, the chat you'll talk to. Suggestions start
  with C." Options: **Cyrus** · **Celia** · **Cormac** ("Cyrus · Acme Chief").
- Header `Builder`: "Name your Builder, who builds and tests one task at a time.
  Suggestions start with B." Options: **Bram** · **Bilal** · **Bea** ("Bram · Acme
  Builder").

Ask the Chief's name first. A Small team gets two questions (the Chief and its doer); the
reviewer helper has no name. The project name in these titles is from the folder name
(you can change it on the write screen); if it changes there, rebuild every title.

## Session title (also the chat's address)

`<Name> · <Project> <Role label>`, for example `Vito · Acme Reviewer`.

- Role labels: Chief, Reviewer, Builder, Editor, Analyst, Designer, Research, or a
  custom label of 10 characters or fewer. Name (10 or fewer) + project (12 or fewer) + label
  (10 or fewer) keeps every title at 40 characters or fewer. A longer name the user types
  is refused, never cut (interview.md part E); the name taken from the folder is shortened
  openly, and shown as shortened (preflight row 10).
- **Build every title from this one template**, everywhere it appears: the ROSTER row, the
  role file, the kickoff, the launch line and any `/rename` line. A send between chats fails
  on one mismatched word.
- The project name in the title keeps titles from clashing across projects.
- Nobody types the `·`. Print every launch, resume and `@` string already quoted, for
  example `claude --resume "Vito · Acme Reviewer"` or `@"Vito · Acme Reviewer"`.
- The separator is recorded in `team/assemble.json` (`"separator": "·"`).

## Handle

The name in lowercase, for example `bram`. It names task branches (`bram/T2-login`) and a
terminal doer's worktree (`claude -w bram` makes `<repo>/.claude/worktrees/bram` on a branch
named `worktree-bram`).

## Files are named by role, not by person

`team/roles/reviewer.md`, never `team/roles/vito.md`. A rename or a replacement chat never
moves a file. A second chat in the same role gets `team/roles/<role>-<handle>.md`, for
example `team/roles/builder-bilal.md`.
