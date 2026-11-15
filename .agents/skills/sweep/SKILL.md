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

Read the round count from `$P/.noodle/sweep-rounds` (0 if missing) and add one. If this would be round 9 or more, do not sweep: write `$P/.noodle/converged.json` as `{"sha": "<SHA>", "reason": "round cap", "rounds": <n-1>}`, yield `round cap reached`, and stop. Otherwise write the new count back.

Read the phase from `$P/.noodle/sweep-phase`: `major`, `docs` or `deploy` (`major` if missing). Also read how many rounds this phase has run from `$P/.noodle/sweep-phase-rounds` (0 if missing), add one and write it back. Run only that phase's section below. Each phase ends by setting the next phase:

| Phase | Files | Moves on when |
|---|---|---|
| `major` | major defects and cleanup | a round files no major defect, or after its 3rd round |
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

Severity must be high: the output is wrong, missing or crashes for an ordinary input, a check fails, or the package or website does not build. Leave out anything cosmetic, and anything that needs an unusual input to show.

**Cleanup.** Also file cleanup that makes the code simpler without changing what users see: dead or unused internal code, duplicated helpers that should use the shared ones in `R/checks.R`, stale comments, and files in the repo that nothing uses. Check each one is safe by finding every caller. Group cleanup into at most three issues, each titled `Cleanup: <area>`. Do not file renames, reformatting or style changes. Never touch `dev/`.

**Next phase.** If this round filed no major defect (cleanup does not count), or this is the phase's 3rd round, move on to `docs`.

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

1. The latest `R-CMD-check` run on `main` passed: `gh run list --workflow R-CMD-check --branch main --limit 1`.
2. The `pkgdown` run for `<SHA>` passed: `gh run list --workflow pkgdown --branch main --json headSha,conclusion,status`. If it is still running, wait for it with `gh run watch <run-id>` (up to 30 minutes) before going on.
3. The live site at the first `URL` in `DESCRIPTION` serves the home page, the reference index, the gallery and every article, and shows the version in `DESCRIPTION`. Spot-check that a change merged since the last release appears on it.

If a check fails, find the cause in the run log or the site and file one issue titled `Deploy: <what failed>`, then stay in this phase. If every check passes, write `$P/.noodle/converged.json` as `{"sha": "<SHA>", "reason": "deployed", "rounds": <n>}`.

## 5. Avoid duplicates

List every issue, open and closed, with `gh issue list --state all --label noodle --limit 500 --json number,title,state,stateReason,body`. Do not file anything already covered, and never file again a defect from an issue closed as not planned (`stateReason` NOT_PLANNED): that was a decision. If an issue closed as completed has its defect back, file a new issue that links the old one.

## 6. Probe (phase `major`)

Read `brain/codebase/dev-environment.md` and install `origin/main` into your own library from a detached worktree under `~/.cache/phwstyle-dev/wt/`. Then split the exported functions (`NAMESPACE`) into four slices: slides and documents; charts and maps; tables; interactive outputs, colours and the rest. Probe them in parallel with subagents. Give each subagent the defect bar above and these instructions: reproduce every finding with a call, and return one line per finding with function, file:line, the repro call, what happened and what should happen. Also run the full test suite on both ggplot2 versions and `R CMD check --as-cran --no-manual` on a clean `git archive` tarball.

Set `R_USER_CACHE_DIR` to a scratch folder for every probe. Never delete the user's cache.

## 7. File

- The repository is public. Issues, PRs and comments must not contain local paths, machine names or personal details.

Check each finding yourself before filing it, by running its repro. Group findings that share one root cause into one issue. For each issue:

```sh
gh issue create --label noodle --title "<function>: <what goes wrong>" --body-file <file>
```

The body gives the repro call, what happens, what should happen, file:line, and the fix the finding suggests at the entry point. Create the `noodle` label first if it is missing.

## 8. Finish

If you filed any issue, delete `$P/.noodle/converged.json` if it exists. Only the `deploy` phase writes it.

Remove your worktree, then yield with the phase, what you filed, and the minor problems you left out:

```bash
noodle event emit --session "$NOODLE_SESSION_ID" stage_yield --payload '{"message": "sweep round <n> (<phase>): filed <k> issues; next phase <phase>; not filed: <one line each>"}'
```
