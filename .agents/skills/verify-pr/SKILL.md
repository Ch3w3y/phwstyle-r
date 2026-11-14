---
name: verify-pr
description: >-
  Independent review of the pull request an execute stage opened for a GitHub
  issue. Runs the change the way a user would and posts a PASS, PASS+NOTES or
  FAIL verdict tied to the PR's head commit. The ship stage merges only on a
  PASS verdict for the exact head.
schedule: "Follow-up stage after every execute stage, in the next group of the same order. Runs as a separate session from the one that wrote the change."
---

# Verify a pull request

You did not write this change. Your verdict decides whether it lands. Work autonomously and never ask the user.

## Find the PR

The order ID is the GitHub issue number. The PR is the open one from branch `noodle/issue-<id>`:

```sh
gh pr list --head noodle/issue-<id> --state open --json number,headRefOid
```

If there is none, the execute stage decided not to open one: read the issue's latest comment, yield saying so, and stop.

Pin the review to the head SHA you read now. If the head changes while you review, start again on the new head.

## Review

1. Read the issue, the PR description and the full diff from `main` to the head SHA.
2. Check, in this order:
   - Does it fix the issue, proven by running the issue's repro on the PR head?
   - Does it change behaviour on ordinary inputs? Run the help-page examples of every function it touches and compare the output and messages with `main`.
   - Breaking changes that NEWS.md does not call out.
   - CRAN suitability, and nothing from `.agents`, `brain`, `adapters` or `.noodle*` in the build tarball.
   - The project rules in `.agents/skills/execute/SKILL.md` (styling-only scope, replaceable Welsh text, no development material in public docs).
3. Run it as a user would: install it into your own library (see `brain/codebase/dev-environment.md`), make real calls, and look at rendered outputs for anything visual.
4. Run the full test suite on both ggplot2 versions, and `R CMD check --as-cran --no-manual` on a clean `git archive` tarball of the head.

Work in your own detached worktree under `~/.cache/phwstyle-dev/wt/` and remove it when done. Never edit, commit or push.

Block only on real defects: wrong behaviour, a broken install or check, a regression, a scope breach or a leak of private data. Do not block on style preferences.

## Verdict

Post one comment on the PR with `gh pr comment <n> --body-file <file>`:

- First line: exactly `PASS`, `PASS+NOTES` or `FAIL`.
- Second line: `Head: <full SHA>`.
- Then at most 15 lines of findings. A FAIL names each blocking defect with file:line and how to reproduce it. NOTES are non-blocking.

Then yield:

```bash
noodle event emit --session "$NOODLE_SESSION_ID" stage_yield --payload '{"message": "<verdict> on PR #<n> at <short sha>"}'
```
