# Changelog

Notable changes to /assemble. Versions follow [Semantic Versioning](https://semver.org/).

## 1.0.0 (2026-10-15)

First release.

### The skill

- `/assemble` sets up the employee method for a project: a Chief of Staff you talk to, the
  employee chats the project needs (Small, Standard or Full team, up to six), and a `team/`
  notebook every chat reads at the start of every session.
- Preflight checks git, gh, login, identity and push access before asking anything; nothing is
  written before one approval screen, and the setup lands as a pull request.
- New projects (empty folder, or files with no git) and existing repos (read-only scan, adopts
  existing notes files in place, at most three "needs your call" conflicts). Notes stay in the
  repo only when it is private, yours, not deploying from main and nobody else commits;
  otherwise they go in a separate private notes repo. Shared repos get findings-only review
  comments.
- The Chief is a thinking partner: options with a recommendation, decision briefings, reports by
  track. Employees may talk to each other directly; anything that matters reaches the Chief.
- One lessons list every chat reads; repeating a recorded lesson is a serious review finding.
  Log archive, glossary, and a "where this stands" page rewritten, never appended.
- Terminal launch lines and desktop app steps; on the desktop app the Chief can start his own
  team when the app offers it.
- Re-runs: `/assemble add <role>`, `retire <name>`, `check`.

### The repo

- Repository skeleton: README stub, LICENSE (MIT, plus a CC0 section for files the skill
  generates), CONTRIBUTING (inbound = outbound), this changelog, `.gitignore`.
- `skills/assemble/SKILL.md` with the v1 frontmatter; `metadata.version` and
  `skills/assemble/VERSION` are kept equal by `validate.sh`.
- Checks: `scripts/validate.sh` (frontmatter keys, name, description, line count, VERSION,
  plus a real YAML parse of the frontmatter), `scripts/leak-scan.sh` (generic patterns with an
  exact-string allowlist) and `scripts/denylist-scan.sh` (private denylist, fails closed, prints
  only file:line, matches phrases that wrap across lines, with `scripts/denylist-allow.txt` for
  reviewed one-line exceptions). Both scanners check file names too, fail on binary files unless
  listed in `scripts/binary-allow.txt`, and take an optional folder so a trusted copy can scan
  someone else's branch.
- `scripts/install-hooks.sh`: a pre-push hook that runs trusted copies of both scanners on every
  commit a push would send, as committed.
- CI on push and pull request: validate (YAML parse required), leak scan and a denylist job that
  fails closed when its secret is empty.
- `.github/pull_request_template.md` with the inbound = outbound licence checkbox, and
  `.gitattributes` so scripts check out with LF line endings on Windows.
