## Resubmission

This is a resubmission. Version 0.1.0 failed the automated pre-tests with
NOTEs, which are addressed in 0.1.1:

* Possibly misspelled words in DESCRIPTION: the acronyms "PHW" and "CDSC"
  are now written out in full, and the software names 'Typst' and
  'revealjs' are in single quotes.
* Possibly invalid file URIs in README.md: the links to two scripts that are
  not part of the package now point to the GitHub repository.
* The Debian detritus NOTE ('calibre-*' in the temp directory): phwstyle
  never calls calibre or any document converter, so this appears to come
  from another process on the check machine.

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
