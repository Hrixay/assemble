# Fixture: gitlab-remote

**Simulates:** a normal repo whose `origin` is `https://gitlab.com/priya-acme/acme.git`.
git and gh are fine: gh is logged in to github.com as `priya-acme`, and the repo has its own
git name, email and credential helper, so row 5 records nothing.

**Where preflight must stop:** row 6 (the remote is on github.com) in
`skills/assemble/reference/preflight.md`.

**Build and run:** `tests/checklist.md`.

## The run must

1. Detect the surface, pass rows 0 to 5.
2. At row 6, run `git remote get-url origin`, see the host `gitlab.com`, and say, then stop:

   > "v1 works with github.com repos only. Your remote is gitlab.com. A later version may
   > support it."

## The run must not

- run row 7 or later: no `gh repo view`, no `gh api`, no `git fetch` in `calls.log`;
- print the whole remote URL (only the host name);
- offer to create a GitHub repo, add a GitHub remote, or change the remote;
- ask any interview question.

## Nothing may be written

After the run, `tests/check-untouched.sh <fixture folder>` exits 0: "nothing changed since
setup" and "no write was attempted through gh or git".
