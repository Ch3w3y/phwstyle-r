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

## 2. Worktree first

Never edit files on the main checkout. Several sessions run at once, and edits on main cause conflicts and lost work.

- If your working directory is already inside `.worktrees/`, use it.
- Otherwise run `noodle worktree create <descriptive-name>`.

Use absolute paths, or `noodle worktree exec <name> <command...>`. Do not `cd` into a worktree: if it is removed while your shell is inside it, the session dies.

When the work is committed and verified, run `noodle worktree merge <name>`.

## 3. Implement

Break the scope into changes that each compile and pass on their own, one commit each. A single change needs no breakdown.

Use subagents only for two or more independent changes that touch different files. Anything sharing a type, schema, or API contract stays sequential.

## 4. Verify

Run the project's checks before every commit.

<!-- noodle-init:verify:start -->
This is an R package (`phwstyle`). CI is `.github/workflows/R-CMD-check.yaml`: `R CMD check --no-manual --as-cran` across a version matrix, failing on warnings.

Environment on this machine:

- R is not on `PATH`. Use `RB=~/.uvr/r-versions/4.5.3/bin` and call `$RB/R` / `$RB/Rscript`.
- The base library has no packages. Install what you need (Imports, Suggests, `testthat`, `roxygen2`, `rcmdcheck`) into a NEW library under your scratch dir from Posit Package Manager binaries (`repos = "https://packagemanager.posit.co/cran/__linux__/manylinux_2_28/latest"`), and point `R_LIBS` at it. Never modify existing libraries.
- Every R process prints `Fontconfig warning/error` lines on stderr. They are noise: filter with `grep -v Fontconfig`.

Run, in this order:

1. If you changed roxygen comments (`#'`) or exports: `$RB/Rscript -e 'roxygen2::roxygenise()'`, and commit the regenerated `man/` and `NAMESPACE`.
2. Tests: `$RB/R CMD INSTALL --no-docs --library=<pkg lib> .` then `$RB/Rscript -e 'testthat::test_dir("tests/testthat", package = "phwstyle", load_package = "installed")'`. Quarto, Pandoc and LaTeX tests skip when those tools are missing; say which ones skipped.
3. Full check: `$RB/R CMD build .` then `_R_CHECK_FORCE_SUGGESTS_=false $RB/R CMD check --no-manual --as-cran phwstyle_*.tar.gz`. No ERRORs or WARNINGs; explain any NOTE.
4. If you changed a vignette, article or `_pkgdown.yml`: build the site into a scratch folder, never into the repo (`pkgdown::build_site(override = list(destination = "<scratch>"))`).

Project rules agents have been corrected on:

- Keep the package CRAN-suitable. `vignettes/phwstyle.Rmd` is the only shipped vignette and must build with optional packages missing; `vignettes/articles/` is pkgdown-only.
- Column arguments are tidyverse-style (unquoted names, `c(a, b)`, tidyselect helpers). Keep new functions consistent.
- No development material in anything public: no mention of how it was tested, internal scripts, machines, or personal details.
- Do not touch `dev/` (untracked, local only). Add a `NEWS.md` entry for user-visible changes; do not bump the version.
<!-- noodle-init:verify:end -->

Run what CI runs, not a subset. If the repo has no checks yet, say so in your yield message rather than claiming the work is tested, and prove the change works by running it.

Never commit failing code. Fix it and re-run.

## 5. Commit

Conventional commits: `<type>(<scope>): <description>`, with `type` one of `feat`, `fix`, `refactor`, `test`, `docs`, `chore`. One commit per logical change. If the order ID is an issue number, add a `Refs: #<id>` footer so the tracker links the commit once it is pushed. End each message with:

```
Co-Authored-By: Claude <noreply@anthropic.com>
```

## 6. Yield

After everything is committed, verified, and merged, tell the loop the stage is done:

```bash
noodle event emit --session "$NOODLE_SESSION_ID" stage_yield --payload '{"message": "Implemented: <one-line summary>"}'
```

Without this the stage only completes on a clean process exit, and interrupted work is lost to the pipeline.

## Scope discipline

- Change only what is in scope. No speculative features, defensive code for cases that cannot happen, or compatibility shims nobody asked for.
- Note out-of-scope problems in your yield message; do not fix them here.
- If the plan or prompt is wrong or incomplete, say so in the yield message instead of quietly doing something different.
- When finishing a plan phase, tick its `- [ ]` box in the plan file as part of the last commit.
