---
name: execute
description: >-
  How work gets done in this project: scope, worktree workflow, verification,
  commits, and handing the stage back to the loop. The order's prompt says what
  to build; this skill says how. Use for "execute", "implement", "build this".
schedule: "When backlog items, or unchecked phases of a linked plan, are ready for implementation"
---

# Execute

The order's prompt and `extra_prompt` tell you what to do. This skill is how to do it. Work autonomously and do not stop until the task is complete and verified. Never ask the user.

pstack is installed. Load `/pstack:poteto-mode` at the start and follow the playbook it picks for the task (bug fix, feature, refactoring, and so on). The steps below are the Noodle-specific rules that sit on top of it. If `brain/` exists, read the notes in its index that bear on the task before you start.

## 1. Scope

- **Plan phase:** read the plan overview under `brain/plans/` for the boundaries, then the phase you were given. Do only that phase.
- **Backlog item:** the prompt is the scope. Find the affected files before changing anything.

Write down, in one or two sentences, what changes and what does not. That is the contract for this stage.

## 2. Branch and worktree

Changes reach `main` only through a GitHub pull request, so do not commit in the noodle worktree and never run `noodle worktree merge`. Work in a plain git worktree on the issue's branch:

```sh
ID=<order id>                       # the GitHub issue number
B=noodle/issue-$ID
W=$HOME/.cache/phwstyle-dev/wt/issue-$ID
git -C <project dir> fetch -q origin
git -C <project dir> worktree add "$W" -B "$B" "origin/$B" 2>/dev/null \
  || git -C <project dir> worktree add "$W" -b "$B" origin/main
```

- **Retry:** if `gh pr list --head "$B" --state open` shows a PR, this is a fix round. Read its latest verdict comment (first line `FAIL`) and fix exactly the defects it names, on the same branch. Do not start over.
- **Fresh:** otherwise the branch starts from `origin/main`.

Use absolute paths or `git -C "$W"`. Do not `cd` into a worktree that may be removed.

## 3. Implement

Break the scope into changes that each compile and pass on their own, one commit each. A single change needs no breakdown.

Use subagents only for two or more independent changes that touch different files. Anything sharing a type, schema, or API contract stays sequential.

## 4. Verify

Run the project's checks before every commit.

<!-- noodle-init:verify:start -->
This is an R package (`phwstyle`). CI is `.github/workflows/R-CMD-check.yaml`: `R CMD check --no-manual --as-cran` across a version matrix, failing on warnings.

Environment on this machine: read `brain/codebase/dev-environment.md` and use its R, library and Pandoc setup. Never write into the shared library.

Run, in this order:

1. If you changed roxygen comments (`#'`) or exports: `$RB/Rscript -e 'roxygen2::roxygenise()'`, and commit the regenerated `man/` and `NAMESPACE`.
2. Tests: `$RB/Rscript -e 'pkgload::load_all("<W>"); testthat::test_local("<W>")'`, once with the default libraries and once with ggplot2 3.5.1 first (see the brain note). Both must show FAIL 0. Quarto and LaTeX tests skip when those tools are missing; say which ones skipped.
3. Full check: build from a clean `git archive HEAD` into a scratch folder, then `_R_CHECK_FORCE_SUGGESTS_=false $RB/R CMD check --no-manual --as-cran phwstyle_*.tar.gz`. No WARNING or NOTE beyond the fontconfig baseline in the brain note.
4. If you changed a vignette, article or `_pkgdown.yml`: build the site into a scratch folder, never into the repo (`pkgdown::build_site(override = list(destination = "<scratch>"))`).

Project rules agents have been corrected on:

- phwstyle standardises how outputs look, not their content. A fix may add input checks, clearer messages, NA handling, placement or consistent styling. It may not add statistical methods, reference data or data preparation, and never guesses a date format or recodes data. `phw_rate_table()`, `phw_risk_table()` and `phw_poisson_ci()` are legacy: fix crashes only.
- Welsh is translated by hand: any text written into an output must be replaceable by the user.
- Shared entry checks live in `R/checks.R` (`check_has_rows()`, `check_numeric_col()`, `as_date_col()`, `drop_missing()`, `check_colours()` and friends). Use them rather than writing new ones.
- Keep the package CRAN-suitable. `vignettes/phwstyle.Rmd` is the only shipped vignette and must build with optional packages missing; `vignettes/articles/` is pkgdown-only.
- Column arguments are tidyverse-style (unquoted names, `c(a, b)`, tidyselect helpers). Keep new functions consistent.
- No development material in anything public: no mention of how it was tested, internal scripts, machines, or personal details.
- Do not touch `dev/` (untracked, local only). Add a `NEWS.md` entry for user-visible changes; do not bump the version.
<!-- noodle-init:verify:end -->

Run what CI runs, not a subset. If the repo has no checks yet, say so in your yield message rather than claiming the work is tested, and prove the change works by running it.

Never commit failing code. Fix it and re-run.

## 5. Commit

Conventional commits: `<type>(<scope>): <description>`, with `type` one of `feat`, `fix`, `refactor`, `test`, `docs`, `chore`. One commit per logical change. Add a `Refs: #<id>` footer with the issue number. End each message with:

```
Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```

## 6. Open the pull request

Push the branch (`git -C "$W" push -u origin "$B"`, never `--force` on a shared branch; a fix round adds commits). On a fresh run, open the PR:

```sh
gh pr create --base main --head "$B" --title "<what changes, for users>" --body-file <file>
```

The body opens with `## Why` restating the issue in one or two sentences, then what changed and how it was checked, then `Closes #<id>` on its own line, and ends with:

```
🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Do not merge, approve or review the PR yourself: the verify and ship stages do that. Remove your git worktree when done (`git -C <project dir> worktree remove "$W"`).

## 7. Yield

```bash
noodle event emit --session "$NOODLE_SESSION_ID" stage_yield --payload '{"message": "PR #<n> for issue #<id>: <one-line summary>"}'
```

Without this the stage only completes on a clean process exit, and interrupted work is lost to the pipeline.

## Scope discipline

- Change only what is in scope. No speculative features, defensive code for cases that cannot happen, or compatibility shims nobody asked for.
- Note out-of-scope problems in your yield message; do not fix them here.
- If the plan or prompt is wrong or incomplete, say so in the yield message instead of quietly doing something different. If the issue is not a real defect, or a fix would break the scope rules, comment on the issue saying why, open no PR, and yield.
- When finishing a plan phase, tick its `- [ ]` box in the plan file as part of the last commit.
