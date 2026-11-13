## Submission

This is an update of phwstyle, from 0.1.2 to 0.2.0.

Main changes (details in NEWS.md):

* Functions that take columns accept unquoted column names, as dplyr does
  (via tidyselect, a new import). Column names as strings still work.
* The default colour palette is the same however many groups a chart has,
  and a colour-blind safe palette can be switched on for a whole document.
* Fixes for ggplot2 older than 4.0 and for older versions of gt, bslib and
  Quarto.
* The minimum version of R is now 4.3.

## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

* Local, R 4.6.2 on Ubuntu 24.04: R CMD check --as-cran with every
  suggested package installed, and R CMD check with no suggested packages
  installed (_R_CHECK_FORCE_SUGGESTS_=false). Both give Status: OK.
* Local, R 4.3.3, 4.4.3, 4.5.3 and 4.6.0 on Linux with current packages, and
  R 4.3 to 4.5 with CRAN as it was on six dates from June 2024 to April
  2026: the test suite passes on each.

## Notes for CRAN

* The package bundles the Ubuntu font family (Ubuntu Font Licence 1.0) so
  that outputs render the same way offline. The licence and copyright holder
  are listed in inst/COPYRIGHTS and inst/fonts/UFL.txt.
* No organisation logos are bundled. phw_download_logos() downloads the
  Public Health Wales logo only when the user asks, and asks for
  confirmation in interactive sessions.
* phw_boundaries() downloads public boundary files from the ONS Open
  Geography Portal or DataMapWales, but only when the user calls it.
  Nothing is downloaded at install time. Downloads are cached in
  tools::R_user_dir("phwstyle", "cache"). If the service is unavailable,
  the function either uses the cached copy with a warning or stops with an
  informative error, as the CRAN policy asks. Examples that need the
  internet are wrapped in \donttest{} and interactive(), and the tests that
  need it use skip_on_cran() and skip_if_offline().
* The functions that write files (use_phw_quarto(), phw_save(),
  phw_write_xlsx(), phw_install_fonts(), phw_download_logos(),
  phw_boundaries()) write only where the user asks, or to the user cache
  directory. Examples and tests write only to tempdir().
* Tests that render documents with Quarto or XeLaTeX use skip_on_cran().
