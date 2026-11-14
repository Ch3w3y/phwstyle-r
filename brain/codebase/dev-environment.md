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
- Every R process prints Fontconfig noise on stderr: filter with `2>&1 | grep -v Fontconfig`.
- `R CMD check --as-cran` on a clean `git archive` tarball gives 5 WARNINGs and 6 NOTEs from fontconfig noise on main. Anything beyond that list is new. CI on GitHub is the real gate and fails on any WARNING.
- Rendering outputs: [[codebase/render-pptx-with-libreoffice]] (PowerPoint, Word, Excel); HTML via `firefox --headless -profile "$(mktemp -d)" --screenshot /abs/out.png --window-size=1280,1200 file:///abs/page.html`.
- The user's boundaries cache is in `tools::R_user_dir("phwstyle", "cache")`. Never delete it: set `R_USER_CACHE_DIR` to a scratch folder for any probe that clears caches.
