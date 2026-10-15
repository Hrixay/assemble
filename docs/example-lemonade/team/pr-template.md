<!-- If the project repo has its own PR template, fill that one, then add the "Reviewer handoff" and "Checklist" sections below it. -->
## What this PR does
<!-- Task IDs (T<n>) and one or two plain sentences. -->

## Why
<!-- D-links: the decisions or tasks this follows from. -->
<!-- On maple-st/lemonade (public or someone else's): give the technical reason only. No decision text and no quotes from Priya; those stay in the notes. A PR in a private notes repo may give them. -->

## How it was tested
<!-- Commands and their results. Mark the ones the Reviewer can safely re-run. -->

## Reviewer handoff
- **Tier:** quick | full <!-- full = touches the precious list (team/assemble.json), a live system, or money -->
- **Focus here first:** <!-- must name any edit to a rule file: team/CHATS.md, team/roles/**, the CLAUDE.md block -->
- **Risk:**
- **Deploy dependencies:** <!-- new secrets or settings · migrations · new packages · services or jobs to redeploy; for each, the verify command and the expected output. Or "none". -->
- **Manual actions after merge (Priya):**
- **Out of scope / known gaps:**

## Checklist
- [ ] Branch cut from the latest `origin/master`
- [ ] Nothing committed to `master` directly
- [ ] No secrets, keys or `.env` files
