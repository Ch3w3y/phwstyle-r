---
name: sweep
description: >-
  Finds the next round of work once the backlog is empty, in three phases:
  major defects and cleanup, then the docs, then a check that the website is
  deployed. Each proven problem becomes a GitHub issue with the `noodle`
  label. When the deploy check passes, it records that the package has
  converged, which ends the loop.
schedule: "Only when the backlog has no open items and no order is active, and .noodle/converged.json does not match the current origin/main commit. One sweep order at a time, as a standalone order with the id sweep-<n>."
---

# Sweep for defects

Work autonomously and never ask the user. You report and file issues. You change no code.

## 1. Round bookkeeping

```sh
P=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")   # the main checkout
git -C "$P" fetch -q origin
SHA=$(git -C "$P" rev-parse origin/main)
mkdir -p "$P/.noodle"
```

Every `.noodle/` path below means `$P/.noodle/`, never the `.noodle/` of the worktree this session runs in.

Read the round count from `$P/.noodle/sweep-rounds` (0 if missing) and add one. If this would be round 41 or more, do not sweep: write `$P/.noodle/converged.json` as `{"sha": "<SHA>", "reason": "round cap", "rounds": <n-1>}`, yield `round cap reached`, and stop. Otherwise write the new count back.

Read the phase from `$P/.noodle/sweep-phase`: `major`, `docs` or `deploy` (`major` if missing). Also read how many rounds this phase has run from `$P/.noodle/sweep-phase-rounds` (0 if missing), add one and write it back. Run that phase's section (2, 3 or 4), then the shared sections 5 to 8. Each phase ends by setting the next phase:

| Phase | Files | Moves on when |
|---|---|---|
| `major` | major defects and cleanup | a round files no major defect, or after its 30th round |
| `docs` | documentation that is wrong, missing or out of date | always, after one round |
| `deploy` | a deploy that failed or is out of date | the deploy is current, which converges the loop |

To move on, write the next phase to `$P/.noodle/sweep-phase` and `0` to `$P/.noodle/sweep-phase-rounds`. Issues filed in a round are fixed before the next sweep runs, because a sweep only runs on an empty backlog.

## 2. Phase `major`: major defects and cleanup

This phase looks only for problems worth stopping for, and for cleanup. Do not file minor problems: list them in the yield message instead.

**Major defects.** File an issue only for a defect you have reproduced with a real call on `origin/main`, that a user would hit in normal use, of one of these kinds:

- **Wrong output with no warning.** Data misread, a value or row lost or misplaced, the wrong colour, a blank chart or table.
- **Content in the wrong place or dropped.** An argument accepted and then ignored, or content landing in the wrong place.
- **A raw error from a dependency** on an input a user would plausibly pass, where phwstyle should check it at the entry point and say what to change.
- **Styling that differs between renderers** for the same input, which a reader would notice.
- **A failing check:** a test, an example, a vignette, or `R CMD check --as-cran` beyond the fontconfig baseline.

Do not file:
- style preferences;
- new features;
- anything that adds a statistical method, reference data or data preparation (the scope rules in `.agents/skills/execute/SKILL.md`);
- behaviour that NEWS.md or the help pages document as deliberate;
- the decided skips:
  - rounding differences between renderers for x.x5 values;
  - `phw_as_summary()` row type "group" having no style;
  - bullet overflow in LibreOffice;
  - `phw_page_navbar(bg=)`;
  - the navy header fill in xlsx.

Severity must be high: the output is wrong, missing or crashes for an ordinary input, a check fails, or the package or website does not build. Leave out anything cosmetic.

**Normal use only.** The maintainer asked that the loop fix only defects a general user hits in normal use. Before filing a defect in the user's output, ask: would a typical public health analyst hit this in an ordinary report, using typical data (counts, rates, dates, durations, factors, area codes and missing values, in a data frame, a `table()`, a matrix or an sf object, including one a filter has left with no rows) and the function's default or documented arguments, alone or together? File it only if the answer is clearly yes. List everything else as minor in the yield message. These are edge cases, so do not file them:
- a column with an unusual name that clashes with a name phwstyle uses inside the function, such as `signal`. Common names such as `value`, `n`, `group`, `label`, `date`, `x` or `y` are normal use, so a clash with one of them is filed;
- a class the help pages do not mention and analysts rarely pass, such as `units`;
- `NaN` or `Inf`;
- arguments combined in a way that contradicts the help pages or relies on undocumented behaviour;
- global ggplot2 settings changed outside phwstyle, such as `theme_update()`. The documented `phwstyle.*` options and everyday options such as `scipen` are normal use;
- input contrived so that it could not come from real data.

This bar does not apply to a failing check, or to a package or website that does not build. File those whatever the input.

**Priority.** Rank the defects you will file by how many users would hit them, most first, and file them in that order, before any cleanup issue. The loop fixes the lowest issue number first, so the most common defects are fixed first.

**Cleanup.** Also file cleanup that makes the code simpler without changing what users see: dead or unused internal code, duplicated helpers that should use the shared ones in `R/checks.R`, stale comments, and files in the repo that nothing uses. Check each one is safe by finding every caller. Group cleanup into at most three issues, each titled `Cleanup: <area>`. Do not file renames, reformatting or style changes. Leave out the loop's own files (`.agents/`, `adapters/`, `.noodle.toml`, `brain/`), `data-raw/`, `dev/`, and the legacy `phw_rate_table()`, `phw_risk_table()` and `phw_poisson_ci()`, which get crash fixes only.

**Next phase.** After filing (section 7), if this round filed no major defect (cleanup does not count), or this is the phase's 30th round, move on to `docs`.

## 3. Phase `docs`: documentation

Check that every user-facing document matches what the code on `origin/main` does now: `README.md`, `NEWS.md`, the help pages (roxygen in `R/`), `vignettes/phwstyle.Rmd`, the articles in `vignettes/articles/`, the gallery page, and `_pkgdown.yml`.

File an issue for each area where you find:
- a statement, argument or default that the code no longer matches;
- an exported function or argument with no documentation, or missing from the `_pkgdown.yml` reference index;
- an example that errors or shows something other than what the text says;
- a broken link;
- a NEWS.md entry that is missing for a merged fix, or that describes the change wrongly;
- development or project material in a public doc (agent, loop, review or planning notes). Public docs describe the package only.

Group findings by document, titled `Docs: <document or area>`. Do not file wording preferences. Then move on to `deploy`.

## 4. Phase `deploy`: deployment

The website is built by the `pkgdown` workflow and published to GitHub Pages on every push to `main`. Check, for the current `origin/main` commit `<SHA>`:

1. The full `R-CMD-check` run and the `pkgdown` run for `<SHA>` both passed. Pull requests run only part of R-CMD-check and pushes to `main` run none of it, so start the full run yourself with `gh workflow run R-CMD-check --ref main`, unless a `workflow_dispatch` or `schedule` run for `<SHA>` already exists. Find each run with `gh run list --workflow <name> --branch main --json databaseId,headSha,event,status,conclusion` and pick the run whose `headSha` is `<SHA>` (for R-CMD-check, one whose `event` is `workflow_dispatch` or `schedule`). A run you just started can take a minute to appear.
2. If either run is still queued or running, wait for it: check `gh run view <databaseId> --json status,conclusion` every 60 seconds, for up to 30 minutes in all, keeping each shell call under 10 minutes.
3. The live site at the first `URL` in `DESCRIPTION` serves the home page, the reference index, the gallery and every article, and shows the version in `DESCRIPTION`. Spot-check that a change merged since the last release tag (`gh release list --limit 1`) appears on it.

If a check fails, find the cause in the run log or the site. If a code change can fix it, file one issue titled `Deploy: <what failed>` and stay in this phase. If it needs the maintainer instead (GitHub Pages turned off, a repository setting or secret), file nothing and write `$P/.noodle/converged.json` as `{"sha": "<SHA>", "reason": "deploy needs the maintainer: <what>", "rounds": <n>}`, so the loop stops and says why.

If every check passes, write `$P/.noodle/converged.json` as `{"sha": "<SHA>", "reason": "deployed", "rounds": <n>, "blocked": [<open issues labelled noodle-blocked>]}`. The `blocked` list tells the maintainer which issues still need a person.

## 5. Avoid duplicates

List every issue, open and closed, with `gh issue list --state all --label noodle --limit 500 --json number,title,state,stateReason,body`. Do not file anything already covered, and never file again a defect from an issue closed as not planned (`stateReason` NOT_PLANNED): that was a decision. If an issue closed as completed has its defect back, file a new issue that links the old one.

## 6. Probe (phases `major` and `docs`)

Read `brain/codebase/dev-environment.md` and install `origin/main` into your own library from a detached worktree under `~/.cache/phwstyle-dev/wt/`. Then split the exported functions (`NAMESPACE`) into four slices: slides and documents; charts and maps; tables; interactive outputs, colours and the rest. Probe them in parallel with subagents. Give each subagent the defect bar above and these instructions: reproduce every finding with a call, and return one line per finding with function, file:line, the repro call, what happened and what should happen. Also run the full test suite on both ggplot2 versions and `R CMD check --as-cran --no-manual` on a clean `git archive` tarball.

In phase `docs`, install `origin/main` the same way, then run every help-page example and build the articles instead of probing the slices.

Set `R_USER_CACHE_DIR` to a scratch folder for every probe. Never delete the user's cache.

## 7. File

- The repository is public. Issues, PRs and comments must not contain local paths, machine names or personal details.

Check each finding yourself before filing it, by running its repro. Then run the repro through the neighbours in `brain/codebase/neighbour-paths.md` that apply, and put each one that fails with the same root cause, and that a user would hit in normal use (section 2), in the same issue under `Also fails in:`. A neighbour that fails for another reason is a separate finding. Group findings that share one root cause into one issue. For each issue:

```sh
gh issue create --label noodle --title "<function>: <what goes wrong>" --body-file <file>
```

The body gives the repro call, what happens, what should happen, file:line, and the fix the finding suggests at the entry point. Create the `noodle` label first if it is missing.

## 8. Finish

If you filed any issue, delete `$P/.noodle/converged.json` if it exists. Only the `deploy` phase writes it.

Remove your worktree, then yield with the phase, what you filed, and the minor problems you left out. Build the payload with `jq` so quotes in the text are escaped:

```bash
msg="sweep round <n> (<phase>): filed <k> issues; next phase <phase>; not filed: <one line each>"
noodle event emit --session "$NOODLE_SESSION_ID" stage_yield --payload "$(jq -nc --arg m "$msg" '{message: $m}')"
```
