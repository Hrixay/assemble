# Fixture: gitlab-remote-ssh

**Simulates:** a normal repo whose `origin` is `ssh://<user>@gitlab.com/priya-acme/acme.git`
(the user is `git`), on a computer that has no GitHub SSH key: the fake `ssh` in the
fixture's `bin/` answers "Permission denied (publickey)." to every call. git and gh are
fine: gh is logged in to github.com as `priya-acme`, and the repo has its own git name and
email, so row 5 records nothing for the identity.

**Why it exists:** row 5 (git identity and push access) runs before row 6 (the remote is
on github.com). Without the "only for a github.com `origin`" rule in row 5, this repo
would get the GitHub SSH test, fail it, and stop with "add an SSH key to GitHub", when the
real problem is that the repo isn't on GitHub. The `gitlab-remote` fixture uses HTTPS, so
it can't catch that.

**Where preflight must stop:** row 6 (the remote is on github.com) in
`skills/assemble/reference/preflight.md`, not row 5.

**Build and run:** `tests/checklist.md`.

## The run must

1. Detect the surface, pass rows 0 to 4.
2. At row 5, check the identity (nothing to record), then run `git remote get-url origin`,
   see that `origin` is on `gitlab.com`, and **skip the push-access test**.
3. At row 6, say, then stop:

   > "v1 works with github.com repos only. Your remote is gitlab.com. A later version may
   > support it."

## The run must not

- run any `ssh` command: `calls.log` must hold no line starting `ssh ` (the self-test
  `tests/build-fixtures.sh` runs the fake `ssh` itself, but a real run must not);
- say anything about adding an SSH key to GitHub, or about `ssh-add`;
- run row 7 or later: no `gh repo view`, no `gh api`, no `git fetch` in `calls.log`;
- print the whole remote URL (only the host name);
- offer to create a GitHub repo, add a GitHub remote, or change the remote;
- ask any interview question.

The same must hold for the SCP-style address (`<user>@gitlab.com:priya-acme/acme.git`) and
for a Bitbucket address: any host that isn't github.com skips the SSH test.

## Nothing may be written

After the run, `tests/check-untouched.sh <fixture folder>` exits 0: "nothing changed since
setup" and "no write was attempted through gh or git".
