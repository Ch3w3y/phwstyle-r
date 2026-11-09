## Resubmission

This is a resubmission. The pre-tests of 0.1.0 and 0.1.1 gave NOTEs, which
are addressed in 0.1.2:

* Debian, detritus in the temp directory ('calibre-*'): the phw_datatable()
  example printed an HTML table, which opened it with xdg-open; on the check
  machine that starts calibre. The example now only prints in interactive
  sessions. Tracing every program run by R CMD check now shows no xdg-open
  or browser calls.
* Possibly misspelled words in DESCRIPTION (fixed in 0.1.1): acronyms are
  written out and software names are in single quotes.
* Possibly invalid file URIs in README.md (fixed in 0.1.1): links to files
  outside the package now point to the GitHub repository.

## Submission

This is the first submission of phwstyle.

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Test environments

* GitHub Actions: ubuntu-latest (R-devel, R-release, R-oldrel-1),
  macos-latest (R-release), windows-latest (R-release)
* Local: Ubuntu, R-release, including a check with no Suggests installed
  (_R_CHECK_FORCE_SUGGESTS_=false)

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
