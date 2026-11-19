# Development environment on this machine

```sh
RB=~/.uvr/r-versions/4.5.3/bin                       # R is not on PATH
D=~/.cache/phwstyle-dev                               # shared, READ-ONLY
export R_LIBS="<your own lib>:$D/rlib"                # every dependency, testthat, roxygen2, pkgload, rcmdcheck
export PATH="$D/tools/pandoc-3.6.4/bin:$PATH"         # Pandoc
```

- Install the package under test into a NEW library of your own (`$RB/R CMD INSTALL --no-docs --library=<your lib> <dir>`), first on `R_LIBS`. Never write into `$D`. If a package is missing, install it into your own library from `https://packagemanager.posit.co/cran/__linux__/manylinux_2_28/latest`.
- ggplot2 3.5.1, the oldest version CI tests, is in `$D/gg35`. Put it first (`R_LIBS="$D/gg35:<your lib>:$D/rlib"`) to test old-ggplot2 behaviour. patchwork does not load there, so `phw_arrange()` tests skip.
- There is no devtools. Use `pkgload::load_all()`, `testthat::test_local()` and `roxygen2::roxygenise()`.
- To wait for a run you started in the background, keep its PID (`cmd & pid=$!`) and `wait "$pid"`. `wait` only works in the shell that started the run. To wait from a later command, save the PID when you start the run (`cmd & echo $! > <scratch>/run.pid`), then poll it: `pid=$(cat <scratch>/run.pid); while kill -0 "$pid" 2>/dev/null; do sleep 10; done`. Never poll `pgrep -f "<part of its command>"`: the polling shell's own command line contains that text too, so the loop never ends and the stage hangs after its work is done (this happened in #236 and #305).
- Every R process prints Fontconfig noise on stderr: filter with `2>&1 | grep -v Fontconfig`.
- `R CMD check --as-cran` on a clean `git archive` tarball gives 5 WARNINGs and 6 NOTEs from fontconfig noise on main. Anything beyond that list is new. A seventh NOTE, "unable to verify current time", appears when the time server is unreachable and is not from the code. CI on GitHub is the real gate and fails on any WARNING.
- Rendering outputs: [[codebase/render-pptx-with-libreoffice]] (PowerPoint, Word, Excel); HTML via `firefox --headless -profile "$(mktemp -d)" --screenshot /abs/out.png --window-size=1280,1200 file:///abs/page.html`.
- The user's boundaries cache is in `tools::R_user_dir("phwstyle", "cache")`. Never delete it: set `R_USER_CACHE_DIR` to a scratch folder for any probe that clears caches.
- Tests that build bslib pages warn "problem copying ... bootstrap.bundle.min.js: Permission denied": bslib copies files from the read-only shared library and keeps their read-only mode. These are warnings, not failures, and happen on main too.
- Quarto 1.11.9 is installed in `~/.cache/phwstyle-dev/tools/quarto-1.11.9`, linked from `~/.local/bin/quarto`, and TinyTeX's `xelatex`, `lualatex`, `pdflatex` and `tlmgr` are on `~/.local/bin` too. So the PDF and Quarto render tests run: set `NOT_CRAN=true` or they skip as "On CRAN". Render Quarto decks and documents (`phw-pptx`, `phw-docx`, `phw-html`, `phw-pdf`) when a change touches them; do not call that path untested.
