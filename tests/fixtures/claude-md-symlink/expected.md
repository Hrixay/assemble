# Fixture: claude-md-symlink

**Simulates:** Priya's own small private repo `priya-acme/acme` (admin, `main` not protected,
only she commits, 9 files on `main`). Its `CLAUDE.md` is a **symlink to `AGENTS.md`**, which
other tools read; `AGENTS.md` holds two project rules (2-space indentation; run the tests
before pushing), neither of which conflicts with the method. The repo has its own git name,
email and gh credential helper. Writes are allowed after the write screen, against local
bare repos under `remotes/`.

**Where the run must go:** the Existing path, **Small** (Chief and Builder), **in-repo**, with one "needs your
call" item: where the team block goes. The safe default leaves `CLAUDE.md` and `AGENTS.md`
untouched and puts the block in `.claude/CLAUDE.md`, whose import line is
`@../team/CHATS.md` (templates/PLACEHOLDERS.md rule 6).

**Build and run:** `tests/checklist.md`, with the write gate as in
`small-node-app/expected.md`.

## Answers

| Question | Answer |
|---|---|
| `Project` | Existing, it's mine |
| `Deploys?` · `Next` · `Stakes` | No · Fixing and tidying · None of these |
| The ask (paste) | `Tidy up the booking page and make it work on phones.` |
| `Team` · Names | Hire this team · `Chief`: Cyrus · `Builder`: Bram |
| `Write files` call | `CLAUDE.md`: .claude/CLAUDE.md · `Write files`: (open the gate) Write and open the PR |
| "type `/add-dir ...`" | type it, then "done" |

## The run must

1. **The scan**: the listing with `origin/main` prints `path CLAUDE.md  (a link)` and
   `path AGENTS.md`; it reads `git show origin/main:AGENTS.md` (the link's target, for the
   rules) and finds no conflict: both rules are project matters.
2. **What it found** names the link: "CLAUDE.md is a link to AGENTS.md".
3. **Roster**: Small (small, no stakes, only Priya): a Chief of Staff and a Builder, with a
   reviewer helper on every PR.
4. **The write screen**: in-repo; files `.claude/CLAUDE.md` (create) in place of `CLAUDE.md`
   ("needs your call (question 1)", with both outcomes), `.gitignore` (append),
   `.github/pull_request_template.md` (create), the `team/` files, `team/roles/chief.md`,
   `team/roles/builder.md`, `team/roles/reviewer.md` (helper), the handover; precious extras include `AGENTS.md`. One
   call with two questions: `CLAUDE.md` ("CLAUDE.md is a link to AGENTS.md, which other
   tools read too. The team block can't go through the link. Put it in .claude/CLAUDE.md?",
   options **.claude/CLAUDE.md** and **Stop here**) and `Write files`.
5. **After "Write and open the PR"**: `acme-team/.claude/CLAUDE.md` holds the block with
   `@../team/CHATS.md`; `acme-team/CLAUDE.md` is still a link to `AGENTS.md`; DECISIONS has
   D3 "Put the team block in .claude/CLAUDE.md; CLAUDE.md and AGENTS.md stay as they are"
   with `(clicked) ".claude/CLAUDE.md"`. Setup PR #1 on `priya-acme/acme`.

## Check after the run (with `env.sh` loaded)

- `gh pr diff 1 --repo priya-acme/acme --name-only` has `.claude/CLAUDE.md` and no
  `CLAUDE.md` or `AGENTS.md`.
- `readlink acme-team/CLAUDE.md` prints `AGENTS.md`; `git -C acme-team diff origin/main --
  CLAUDE.md AGENTS.md` prints nothing.
- `scripts/check-output.sh "<fixture>/acme-team"` passes: it skips the linked `CLAUDE.md` and
  finds the block once, in `.claude/CLAUDE.md`, importing `@../team/CHATS.md`.
- In `acme/`: nothing changed (`git status --porcelain` empty, still on `main`).
- Whether Claude Code loads `.claude/CLAUDE.md` next to a linked root `CLAUDE.md` is test T12;
  until it passes, a fresh chat's kickoff still points it at `team/CHATS.md`.

## The run must not

- write through the link (appending to `CLAUDE.md` would change `AGENTS.md`), replace the
  link with a file, or touch `AGENTS.md`.

A third run answers **Stop here** to the `CLAUDE.md` question (without the gate):
"Nothing was written. ..."; `tests/check-untouched.sh "<fixture>"` exits 0.

## Cancel

As in `small-node-app`: nothing written, `tests/check-untouched.sh "<fixture>"` exits 0.
