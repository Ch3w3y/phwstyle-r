---
name: sweep
description: >-
  Finds the next round of defects: probes phwstyle's exported functions the
  way users call them and files each proven defect as a GitHub issue with the
  `noodle` label. When a round files nothing, it records that the package has
  converged, which ends the loop.
schedule: "Only when the backlog has no open items and no order is active, and .noodle/converged.json does not match the current origin/main commit. One sweep order at a time, as a standalone order with the id sweep-<n>."
---

# Sweep for defects

Work autonomously and never ask the user. You report and file issues. You change no code.

## 1. Round bookkeeping

```sh
git -C <project dir> fetch -q origin
SHA=$(git -C <project dir> rev-parse origin/main)
mkdir -p <project dir>/.noodle
```

Read the round count from `<project dir>/.noodle/sweep-rounds` (0 if missing) and add one. If this would be round 6 or more, do not sweep: write `.noodle/converged.json` as `{"sha": "<SHA>", "reason": "round cap", "rounds": <n-1>}`, yield `round cap reached`, and stop. Otherwise write the new count back.

## 2. What counts as a defect

File an issue only for a defect you have reproduced with a real call on `origin/main`, of one of these kinds:

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

Severity must be high or medium. Leave out cosmetic problems that need an unusual input to show.

## 3. Avoid duplicates

List every issue, open and closed, with `gh issue list --state all --label noodle --limit 500 --json number,title,state,body`. Do not file anything already covered. If a closed issue's defect is back, file a new issue that links the old one.

## 4. Probe

Read `brain/codebase/dev-environment.md` and install `origin/main` into your own library from a detached worktree under `~/.cache/phwstyle-dev/wt/`. Then split the exported functions (`NAMESPACE`) into four slices: slides and documents; charts and maps; tables; interactive outputs, colours and the rest. Probe them in parallel with subagents. Give each subagent the defect bar above and these instructions: reproduce every finding with a call, and return one line per finding with function, file:line, the repro call, what happened and what should happen. Also run the full test suite on both ggplot2 versions and `R CMD check --as-cran --no-manual` on a clean `git archive` tarball.

Set `R_USER_CACHE_DIR` to a scratch folder for every probe. Never delete the user's cache.

## 5. File

Check each finding yourself before filing it, by running its repro. Group findings that share one root cause into one issue. For each issue:

```sh
gh issue create --label noodle --title "<function>: <what goes wrong>" --body-file <file>
```

The body gives the repro call, what happens, what should happen, file:line, and the fix the finding suggests at the entry point. Create the `noodle` label first if it is missing.

## 6. Converge or continue

- **Filed nothing:** write `.noodle/converged.json` as `{"sha": "<SHA>", "reason": "no defects found", "rounds": <n>}`.
- **Filed issues:** delete `.noodle/converged.json` if it exists.

Remove your worktree, then yield:

```bash
noodle event emit --session "$NOODLE_SESSION_ID" stage_yield --payload '{"message": "sweep round <n>: filed <k> issues"}'
```
