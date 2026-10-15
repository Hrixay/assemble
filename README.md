# assemble: run any project with a small team of named Claude chats

**The employee method, by Hriday Jain**

Claude Code can now run several chats at once, and on the desktop app one chat can start others.
`/assemble` is how those chats work together as a team.

You talk to one chat only: your **Chief of Staff**. The Chief thinks ideas through with you,
hands the work to a few named employee chats (a doer such as a Builder, a Reviewer when the
project calls for one, and others only if needed), checks their work, and comes back to you with the research and the
decisions only you can make. Every chat reads the same shared notes at the start of every
session, so nobody needs the project explained twice and the same mistake isn't made twice.

```
            You
             │
      Chief of Staff  ── your only contact; ideates, coordinates, reports
       │      │     │
   Builder Reviewer Researcher …   (only the roles your project needs)
       └──────┴─────┘
   team/  ── the shared notebook every chat reads first:
             the ask · log · decisions · tasks · lessons · who's who
```

## What you need

- Claude Code in the **terminal** or the **desktop app** (Code tab). The browser version
  (claude.ai/code) isn't supported yet.
- `git`, and the GitHub CLI `gh`, logged in (`gh auth login`).
- A project on github.com, or an empty folder (the skill can create a private repo for it).

## Install

**Terminal:** paste these two lines.

```bash
git clone --depth 1 https://github.com/Hrixay/assemble.git ~/.assemble-src
mkdir -p ~/.claude/skills && cp -R ~/.assemble-src/skills/assemble ~/.claude/skills/assemble
```

**Desktop app only:** on this repo's Releases page, download the latest release's "Source code
(zip)", unzip it, and copy its `skills/assemble` folder into `~/.claude/skills/` (on a Mac, Finder → Go → Go to
Folder… → `~/.claude/skills`; on Windows, `%USERPROFILE%\.claude\skills`).

Type `/assemble` to check it's there; if it doesn't show up, restart Claude Code.

## Your first ten minutes

1. Open Claude Code **in your project folder** (or an empty folder for a new idea).
2. Type `/assemble`.
3. It checks your machine first, then asks whether this is a new or an existing project.
4. A few short questions, or a read-only look around your repo, and it proposes a team sized to
   the project, with three name ideas per employee. You approve the team and pick the names.
5. It shows every file it will write. **Nothing is written until you say yes**, and its own
   setup arrives as a pull request.
6. It tells you how to open your Chief. From then on, talk to the Chief. On the desktop app the
   Chief can start the rest of the team himself; otherwise you get exact steps for each chat.

Team sizes: **Small** (Chief + one doer, with a fresh helper checking each change), **Standard**
(Chief + doer + a Reviewer chat) or **Full** (Standard plus a Researcher, Designer, Editor,
Analyst or a role of your own). Up to six chats.

## What it writes

- A `team/` folder: `README.md` (where things stand), `the-ask.md` (your request, word for word,
  never edited), `LOG.md`, `DECISIONS.md` (in your own words), `TASKS.md` (with "Waiting on
  you"), `LESSONS.md`, `GLOSSARY.md`, `ROSTER.md`, `CHATS.md` (the rules every chat follows),
  a review checklist and one job description per chat.
- A short block at the end of your `CLAUDE.md` so every chat loads the rules.
- A pull request template with a reviewer handoff section.

For a live, public or shared repo, the notes go in a separate private repo next to the project,
so a note can never trigger a deploy or be seen publicly. When the notes stay in your repo,
existing files that do the same job (a `LOG.md`, a decisions file) are used where they are.

See [`docs/example-lemonade/`](docs/example-lemonade/) for a fictional project with every file
filled in.

## Why each rule exists

- **One contact.** You talk to the Chief only, so you get one clear picture instead of five chats.
- **Only you decide.** Chats propose; a decision exists only when you said yes, recorded in your
  own words.
- **The notes are the memory.** Chats forget; files don't. Every chat reads the notes first.
- **Every change is a pull request, checked by someone who didn't write it.** You click Merge.
- **The PR is the record; a chat message is only the doorbell.** Anything agreed is written down.
- **Lessons are written down the same day** and every chat reads them, so mistakes aren't repeated.

## Update and uninstall

- `/assemble check` tells you when a newer version exists and prints the update steps.
- To update by hand in the terminal: `git -C ~/.assemble-src pull --ff-only`, then
  `rm -rf ~/.claude/skills/assemble`, then run the second install line again.
- To uninstall, delete `~/.claude/skills/assemble`. Projects keep their `team/` folder.

## Good to know

- **Usage:** each open chat uses your Claude plan. Small teams are the default for small
  projects, and you pick each chat's model on the approval screen.
- **Version 1.0 gaps:** a separate notes repo for a brand-new project that is already live, and
  re-runs on teams whose notes live in a separate repo, aren't written yet; the skill says so
  and stops. No GitHub means no review loop yet, so GitHub is required for now.
- **The desktop app** path was built from the same steps as the terminal and is less
  battle-tested. Tell us what breaks.
- Unrelated projects with similar names exist (for example a `team-assemble` plugin, as of
  2026-10-12).

## Licence, in plain words

- **The skill** is under the [MIT licence](LICENSE): you can use, change and share it, as long as
  copies of the skill keep the copyright and licence notice.
- **The files it writes into your project** (for example `team/`, the CLAUDE.md block and the PR
  template) are yours. They are dedicated to the public domain under CC0 1.0, so your project
  needs no attribution and no licence notice for them.
- Contributions come in under the same terms they go out on: see [CONTRIBUTING.md](CONTRIBUTING.md).
