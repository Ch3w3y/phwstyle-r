setup_packages <- list(
  "PNG charts in the bundled font (knitr, phw_save)" = c("ragg"),
  "Word and PowerPoint tables and slides" = c("flextable", "officer", "rvg"),
  "gt and gtsummary tables" = c("gt", "gtsummary"),
  "Interactive tables" = c("reactable", "DT"),
  "Interactive charts and maps" = c("plotly", "leaflet"),
  "Maps and boundaries" = c("sf", "jsonlite"),
  "Excel workbooks" = c("openxlsx2"),
  "Shiny apps and HTML themes" = c("bslib", "sass", "shiny"),
  "R Markdown documents" = c("rmarkdown", "knitr"),
  "Multi-plot figures" = c("patchwork"),
  "Logos on charts and slides" = c("png", "jpeg", "rsvg")
)

#' Check what phwstyle needs on this computer
#'
#' phwstyle works straight after installation, but some outputs need extra
#' packages or tools. R can't ask questions while installing a package, so
#' run this once afterwards. It lists what is ready, what is missing, and
#' the command that fixes each item:
#'
#' * the Ubuntu font, for Word, LaTeX and base R devices on your computer
#'   (charts made with 'ragg', HTML and Office tables already use the
#'   bundled copy)
#' * the logo
#' * optional R packages for each type of output
#' * external tools: Pandoc (R Markdown), Quarto, and XeLaTeX (PDF via
#'   LaTeX; Typst PDFs don't need it)
#'
#' Functions that need an optional package also offer to install it the
#' first time you use them.
#'
#' @param install In an interactive session, offer to install missing R
#'   packages and the font?
#' @return A data frame of checks, invisibly.
#' @examples
#' phw_setup_check(install = FALSE)
#' @export
phw_setup_check <- function(install = interactive()) {
  rows <- list()
  # Each fix is code to run, a note in words, or code followed by a note.
  add <- function(item, ok, code = "", note = "") {
    rows[[length(rows) + 1]] <<- data.frame(item = item, ok = ok, code = code, note = note)
  }

  font_sys <- tryCatch("Ubuntu" %in% systemfonts::system_fonts()$family, error = function(e) FALSE)
  add("Ubuntu font installed on this computer", font_sys, "phw_install_fonts()")
  add("PHW logo available", phw_has_logo(), "phw_download_logos()",
      "or set the phwstyle.logo_dir option to a folder of logos")
  for (what in names(setup_packages)) {
    pk <- setup_packages[[what]]
    have <- vapply(pk, requireNamespace, logical(1), quietly = TRUE)
    add(what, all(have), if (all(have)) "" else
      sprintf("install.packages(c(%s))", paste0('"', pk[!have], '"', collapse = ", ")))
  }
  pandoc <- requireNamespace("rmarkdown", quietly = TRUE) && rmarkdown::pandoc_available()
  add("Pandoc (R Markdown)", pandoc, note = "install RStudio, or Pandoc from https://pandoc.org")
  add("Quarto", nzchar(Sys.which("quarto")), note = "install it from https://quarto.org")
  add("XeLaTeX (PDF via LaTeX)", nzchar(Sys.which("xelatex")), "tinytex::install_tinytex()",
      "or use the phw-typst format instead")
  res <- do.call(rbind, rows)
  joined <- function(code) {
    paste0(code, ifelse(nzchar(res$code) & nzchar(res$note), ", ", ""), res$note)
  }
  shown <- joined(ifelse(nzchar(res$code), paste0("run {.code ", res$code, "}"), ""))
  msgs <- stats::setNames(ifelse(res$ok, res$item, paste0(res$item, ": ", shown)),
                          ifelse(res$ok, "v", "x"))
  res <- data.frame(item = res$item, ok = res$ok, fix = joined(res$code))
  cli::cli_h2("phwstyle setup")
  cli::cli_bullets(msgs)
  if (all(res$ok)) cli::cli_alert_success("Everything is ready.")

  if (install) {
    missing_pk <- unlist(lapply(setup_packages, function(pk) pk[!vapply(pk, requireNamespace, logical(1), quietly = TRUE)]))
    if (length(missing_pk)) {
      ok <- utils::askYesNo(sprintf("Install the missing R packages (%s)?", paste(unique(missing_pk), collapse = ", ")))
      if (isTRUE(ok)) utils::install.packages(unique(missing_pk))
    }
    if (!font_sys) phw_install_fonts(ask = TRUE)
  }
  invisible(res)
}

startup_needs_setup <- function() {
  font_sys <- tryCatch("Ubuntu" %in% systemfonts::system_fonts()$family, error = function(e) TRUE)
  !font_sys || !requireNamespace("ragg", quietly = TRUE) || !phw_has_logo()
}
