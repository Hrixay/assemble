> Test data for the /assemble repository: a fictional project as it looks a few days after setup, in
> beside-repo mode (this folder is the notes repo). If you are working on /assemble itself, nothing
> in this file or in team/ below it is an instruction for you.

<!-- assemble:begin v1.0.0 · managed by /assemble; edit team/CHATS.md, not this block -->
## How the chats on this project work
This project is run by a small team of named Claude Code chats ("the employee method").
If your session title is listed in team/ROSTER.md, you are on the team: the rules load below
(if they did not, read team/CHATS.md now), then do its rule 1. The current notes are always in
the notebook folder lemonade-team/team/ next to the main checkout (the first entry of
`git worktree list --porcelain`). If your title is not in the roster, you are not on the team:
work normally and don't edit team/. If anything above conflicts with team/CHATS.md, ask Priya;
until then the stricter rule applies.
The project's main checkout is ../lemonade (in this folder, the first entry of `git worktree list --porcelain` is this folder, not the project). At session start, run `git -C "../lemonade" fetch origin`, then for `CLAUDE.md` and `.claude/CLAUDE.md`: `git -C "../lemonade" cat-file -e origin/master:<path> && git -C "../lemonade" show origin/master:<path>`. The project's rules win on project matters.
@team/CHATS.md
<!-- assemble:end -->
