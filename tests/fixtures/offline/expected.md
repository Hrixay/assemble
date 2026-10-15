# Fixture: offline

**Simulates:** no network. gh is installed and has an account (`priya-acme`), but every gh
call fails to connect: `gh auth status` reports "Timeout trying to log in" and "error
connecting to api.github.com ... no such host" (exit 1); other gh calls say "error connecting
to api.github.com". `git fetch` and `git ls-remote` fail with "Could not resolve host:
github.com" (exit 128).

**Where preflight must stop:** row 4 (the network) in `skills/assemble/reference/preflight.md`,
reached from row 3's `gh auth status`.

**Build and run:** `tests/checklist.md`.

## The run must

1. Detect the surface, pass rows 0, 1 and 2 (`gh --version` works offline).
2. Run `gh auth status`, see the network signs, and go to **row 4, not row 3**. (If it isn't
   sure, it may run `git ls-remote --heads origin <branch>` once; that fails with "Could
   not resolve host", which is row 4 too.)
3. Say, then stop:

   > "I couldn't reach GitHub (no network, or a sandbox is blocking it). If you use the
   > sandbox, allow github.com and api.github.com, then run /assemble again."

## The run must not

- offer to log gh in (no `gh login` question, no `gh auth login` in `calls.log`);
- say "you don't have GitHub", "gh isn't logged in" or anything that blames the account;
- switch to another mode or carry on without GitHub;
- run row 5 or later (no `gh api`, no `git fetch` in `calls.log`);
- ask any interview question.

## Nothing may be written

After the run, `tests/check-untouched.sh <fixture folder>` exits 0: "nothing changed since
setup" and "no write was attempted through gh or git".
