<!-- assemble:begin v{{VERSION}} · managed by /assemble; edit team/CHATS.md, not this block -->
## How the chats on this project work
This project is run by a small team of named Claude Code chats ("the employee method").
If your session title is listed in team/ROSTER.md, you are on the team: the rules load below
(if they did not, read team/CHATS.md now), then do its rule 1. The current notes are always in
the notebook folder {{REPO}}-team/team/ next to the main checkout (the first entry of
`git worktree list --porcelain`). If your title is not in the roster, you are not on the team:
work normally and don't edit team/. If anything above conflicts with team/CHATS.md, ask {{HUMAN}};
until then the stricter rule applies.
{{IF_BESIDE_REPO}}The project's main checkout is ../{{REPO}} (in this folder, the first entry of `git worktree list --porcelain` is this folder, not the project). At session start, run `git -C "../{{REPO}}" fetch origin`, then for `CLAUDE.md` and `.claude/CLAUDE.md`: `git -C "../{{REPO}}" cat-file -e origin/{{DEFAULT_BRANCH}}:<path> && git -C "../{{REPO}}" show origin/{{DEFAULT_BRANCH}}:<path>`. The project's rules win on project matters.
@team/CHATS.md
<!-- assemble:end -->
