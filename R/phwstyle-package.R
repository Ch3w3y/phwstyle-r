#' phwstyle: Public Health Wales styling for R outputs
#'
#' phwstyle gives the outputs you already make one consistent, accessible
#' house style. Write your analysis as usual, then add one function to
#' style the result.
#'
#' @section Getting started:
#' * [phw_setup_check()] lists the fonts, packages and tools each output
#'   needs, and offers to install what is missing.
#' * [use_phw_ggplot()] styles every ggplot in the session.
#' * `vignette("phwstyle")` explains how the pieces fit together (what is
#'   set once for a document, what is added to one chart, and how your own
#'   changes take priority), then walks through each output type. The script
#'   `examples/phwstyle-demo.R` in the source repository runs them all from
#'   one raw data frame.
#'
#' @section Charts:
#' [theme_phw()], [theme_phw_map()], the `scale_*_phw_*()` colour and fill
#' scales, [scale_shape_phw()], [scale_linetype_phw()], [phw_sec_axis()], [phw_finalise()],
#' [phw_save()], [phw_arrange()], [phw_style_extensions()], and public
#' health charts: [phw_epicurve()], [phw_pyramid()], [phw_funnel()] and
#' [phw_spc()].
#'
#' @section Colours and accessibility:
#' [phw_colours], [phw_pal()], [phw_colour_key()] (colours that stay with
#' their groups across reports), [phw_check_colours()], [phw_cvd()] and the
#' `accessible` and `rag_accessible` palettes.
#'
#' @section Tables:
#' Build with [phw_summary_table()], [phw_crosstab()], [phw_rate_table()],
#' [phw_risk_table()] or [phw_group_table()], then render with
#' [phw_flextable()] (Word, PDF), [phw_gt()], [phw_reactable()],
#' [phw_datatable()] or [phw_write_xlsx()] (Excel). [use_phw_gtsummary()]
#' styles gtsummary tables.
#'
#' @section Maps:
#' [phw_boundaries()] downloads boundaries for every level of Welsh
#' geography; [phw_leaflet()] makes interactive maps.
#'
#' @section Documents, slides and apps:
#' R Markdown formats ([phw_html_document()], [phw_word_document()],
#' [phw_pdf_document()]), the Quarto extension ([use_phw_quarto()]),
#' PowerPoint ([phw_pptx()], [phw_add_slide()]), and Shiny
#' ([phw_bs_theme()], [phw_page_navbar()], [phw_header()]).
#'
#' @section Options:
#' * `phwstyle.palette`: default palette name, e.g. `"accessible"` for the
#'   colour-blind safe palette in every chart, table and widget. The
#'   environment variable `PHWSTYLE_PALETTE` and `phw-palette` in a
#'   document's YAML header do the same; see [phw_default_palette()].
#' * `phwstyle.font`: font family to use instead of Ubuntu.
#' * `phwstyle.logo_dir`: folder with your own logo files.
#' * `phwstyle.boundary_dir`: where downloaded boundaries are cached.
#' * `phwstyle.quiet`: `TRUE` hides the startup reminder.
#'
#' @keywords internal
#' @importFrom rlang .data
"_PACKAGE"

.onLoad <- function(libname, pkgname) {
  phw_register_fonts()
  register_device_fonts()
  invisible()
}

.onAttach <- function(libname, pkgname) {
  if (isTRUE(getOption("phwstyle.quiet")) || !interactive()) return(invisible())
  if (startup_needs_setup()) {
    packageStartupMessage(
      "phwstyle: some outputs need a one-off setup (font, logo or optional packages).\n",
      "Run phw_setup_check() to see what's missing. Hide this with options(phwstyle.quiet = TRUE).")
  }
  invisible()
}

# Base R devices keep their own font tables and error on unknown families.
# Map "Ubuntu" to Helvetica on pdf()/postscript() (the Arial-like fallback the
# NHS Wales guidelines allow) and to the Windows font of the same name, which
# Windows swaps for Arial when Ubuntu isn't installed. ragg, svglite and
# cairo devices use the real Ubuntu font.
register_device_fonts <- function() {
  try({
    if (!"Ubuntu" %in% names(grDevices::pdfFonts())) {
      grDevices::pdfFonts(Ubuntu = grDevices::pdfFonts()$Helvetica)
    }
    if (!"Ubuntu" %in% names(grDevices::postscriptFonts())) {
      grDevices::postscriptFonts(Ubuntu = grDevices::postscriptFonts()$Helvetica)
    }
    if (.Platform$OS.type == "windows") {
      wf <- get("windowsFonts", envir = asNamespace("grDevices"))
      wfont <- get("windowsFont", envir = asNamespace("grDevices"))
      if (!"Ubuntu" %in% names(wf())) wf(Ubuntu = wfont("Ubuntu"))
    }
  }, silent = TRUE)
}
