# Fixture: no-gh

**Simulates:** git works and the repo is a normal github.com repo (`priya-acme/acme`), but the
GitHub CLI isn't installed. The fake `gh` on PATH answers "gh: command not found" (exit 127).

**Where preflight must stop:** row 2 (the GitHub CLI) in `skills/assemble/reference/preflight.md`.

**Build and run:** `tests/checklist.md`.

## The run must

1. Detect the surface with two separate `printenv` calls (a terminal run: Terminal, from
   `CLAUDE_CODE_ENTRYPOINT=cli`).
2. Pass row 0 (the folder) and row 1 (`git --version`, 2.28 or newer).
3. Run `gh --version`, see "command not found", and say this message, with the steps for
   the tester's computer and surface in the middle, then stop:

   > "The GitHub CLI (gh) isn't installed. /assemble v1 reviews every change through GitHub
   > pull requests, so it needs gh.
   > <steps>
   > A later version may add a no-GitHub mode."

   followed by "Next time, I'll help you log gh in to GitHub."

   | Computer and surface | `<steps>` |
   |---|---|
   | Mac, terminal | "Run `brew install gh`, then run /assemble again. (No Homebrew? Use the macOS installer (.pkg) from cli.github.com.)" |
   | Mac, desktop app | "Download the macOS installer (.pkg) from cli.github.com, open it, click Continue until it says installed, then run /assemble again." |
   | Windows, terminal | "Run `winget install --id GitHub.cli` (or use the installer from cli.github.com), open a new terminal, then run /assemble again." |
   | Windows, desktop app | "Download the installer from cli.github.com, run it, then restart the Claude app and run /assemble again." |
   | Linux | "Follow the steps for your distribution at cli.github.com/manual/installation, then run /assemble again." |

## The run must not

- run any later row: no `gh auth status`, `gh repo view`, `gh api`, `git fetch` (in
  `calls.log`, nothing comes after `gh --version`);
- ask any question: no interview, no "Where" question (the surface was detected);
- offer a way to carry on without gh (no "local only" or "no GitHub" mode), or try to
  install gh itself;
- give a desktop user a terminal command as the install route.

## Nothing may be written

After the run, `tests/check-untouched.sh <fixture folder>` exits 0: "nothing changed since
setup" and "no write was attempted through gh or git".
