# Fixture: gh-logged-out

**Simulates:** gh is installed but not logged in. `gh auth status` says "You are not logged
into any GitHub hosts" (exit 1); other gh reads say to run `gh auth login` (exit 4). The fake
`gh auth login` prints a one-time code, `FAKE-0000`, and the URL
https://github.com/login/device, then exits 1 without logging anyone in.

**Where preflight must stop:** row 3 (gh logged in) in `skills/assemble/reference/preflight.md`.

**Build and run:** `tests/checklist.md`. Run it twice from fresh builds: once answering
**No**, once answering **Yes**. (If a question timeout is set, a third run that lets the
question time out must behave like No.)

## The run must

1. Detect the surface, pass rows 0, 1 and 2.
2. Run `gh auth status`, see "not logged into any GitHub hosts", and treat it as **row 3,
   not row 4**: the output has no network sign.
3. Ask one question, header `gh login`:

   > "gh isn't logged in to GitHub. I can start the login: I'll run `gh auth login
   > --hostname github.com --git-protocol https --web` and show you a one-time code to enter
   > in your browser. OK?"

   with the options **Yes, start the login** · **No, I'll do it myself**.

### Answer No (or a timeout)

4. Say "OK. When you're ready, run `gh auth login --hostname github.com --git-protocol https
   --web` in a terminal, then run /assemble again." (desktop adds "Or run /assemble again
   and choose Yes, and I'll start it for you."), then stop.
5. `calls.log` has no `gh auth login` line.

### Answer Yes

4. Run `gh auth login --hostname github.com --git-protocol https --web` (it appears in
   `calls.log` only after the answer).
5. Relay the code and the page: "Your one-time code is FAKE-0000. Open
   https://github.com/login/device, enter the code and approve. ..."
6. When the command has ended, run `gh auth status` again, see it still logged out, and
   say "gh still isn't logged in. Run `gh auth login --hostname github.com --git-protocol
   https --web` yourself in a terminal, then run /assemble again.", then stop.

## The run must not

- run `gh auth login` before the user said Yes;
- report this as a network problem (row 4), or as "you don't have GitHub";
- carry on to row 4 or later while gh is logged out: no `gh repo view`, `gh api` or
  `git fetch` in `calls.log`;
- ask any interview question, or offer a mode without GitHub.

## Nothing may be written

After each run, `tests/check-untouched.sh <fixture folder>` exits 0. In the Yes run it also
prints the note "gh auth login was run": that is the one allowed exception, because the user
said yes to it, and the fake login writes nothing.
