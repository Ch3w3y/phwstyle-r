---
name: ship-pr
description: >-
  Lands a reviewed pull request: merges it into main on GitHub only when the
  latest verdict is PASS or PASS+NOTES for the exact head commit and every CI
  check is green, then brings the local main up to date. On a FAIL verdict or
  red CI it records a retry so the next execute round fixes it.
schedule: "Final stage of every issue order, in the group after verify-pr."
---

# Ship a pull request

Work autonomously and never ask the user. Never use `--admin`, never arm auto-merge, never change branch protection, never force-push.

## 1. Read the state

`$P` below is the main checkout, wherever this session runs. Set it first:

```sh
P=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
```

The order ID is the GitHub issue number.

```sh
gh pr list --head noodle/issue-<id> --state open --json number,headRefOid,mergeStateStatus
```

No open PR: the issue was declined or already landed. Yield saying which, and stop.

Read the PR's latest comment whose first line is `PASS`, `PASS+NOTES` or `FAIL`, and its `Head:` line.

## 2. Decide

- **Verdict for an older head, or no verdict:** do not merge. Go to step 4 (this counts as a retry, so it cannot repeat without end).
- **FAIL:** do not merge. Go to step 4.
- **PASS or PASS+NOTES for the current head:** wait for CI with `gh pr checks <n> --watch --interval 60`, then read `gh pr checks <n>`.
  - All green: go to step 3. Green means every reported check passed AND the `R-CMD-check` jobs are among them. "no checks reported", pending checks or a missing R-CMD-check job are not green: wait again, and after 60 minutes treat it as a failure.
  - Any failure: post a comment on the PR whose first line is `FAIL`, second line `Head: <sha>`, then the failing jobs and the key error lines from `gh run view <run> --log-failed` (at most 15 lines). Go to step 4.

## 3. Merge

```sh
gh pr merge <n> --merge --match-head-commit <verified sha>
gh pr view <n> --json state,mergeCommit
```

Confirm `MERGED`. If the issue is still open, close it (`gh issue close <id> --comment "Fixed by #<n>."`). Then update the local checkout, which the loop reads skills from, only if it is on `main` with no local changes:

```sh
test "$(git -C "$P" branch --show-current)" = main && git -C "$P" diff --quiet HEAD \
  && git -C "$P" pull -q --ff-only origin main
git push origin --delete noodle/issue-<id>
```

If the fast-forward fails, say so in the yield message and change nothing else. Yield `merged PR #<n> as <merge sha>`.

## 4. Record a retry

- The repository is public. Issues, PRs and comments must not contain local paths, machine names or personal details.

Count the issue's labels `noodle-retry-1` and `noodle-retry-2`.

- Fewer than two: add the next one (`gh issue edit <id> --add-label noodle-retry-<k>`, creating the label first if needed) and comment on the issue: `Review or CI failed on PR #<n>; the next round fixes the findings on the same branch.`
- Already two: add `noodle-blocked` and comment that the issue needs a person. Leave the PR open.

Yield `not merged: <reason>`.

```bash
noodle event emit --session "$NOODLE_SESSION_ID" stage_yield --payload '{"message": "<result>"}'
```
