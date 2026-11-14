#' Add the PHW Quarto extension to a project
#'
#' Copies the `phw` Quarto extension into `_extensions/phw` inside `path`.
#' This is the same as running `quarto add`, but it works offline. You can
#' also write a starter document.
#'
#' The extension provides these formats:
#'
#' | Format          | Output                                                        |
#' |-----------------|---------------------------------------------------------------|
#' | `phw-html`      | Web report with the gradient header band and logo             |
#' | `phw-docx`      | Word report built from the PHW reference document             |
#' | `phw-typst`     | PDF via Typst (fast, no LaTeX needed) with cover and band     |
#' | `phw-pdf`       | PDF via XeLaTeX with cover and band                           |
#' | `phw-revealjs`  | 16:9 slides with gradient title slide, logo and footer        |
#' | `phw-dashboard` | Quarto dashboard with gradient navbar and PHW cards           |
#'
#' Use them in the document's YAML:
#'
#' ```yaml
#' format:
#'   phw-html: default
#'   phw-docx: default
#'   phw-typst: default
#' ```
#'
#' Typst options: `phw-team: "Communicable Disease Surveillance Centre"`
#' adds a team line to the cover, and `phw-no-cover: true` drops the cover.
#' `phw-org`, `phw-page-label` and `phw-of-label` change the footer wording
#' ("Public Health Wales", "Page", "of").
#'
#' The extension styles the document. The charts and tables your R code
#' makes are styled by phwstyle itself, so call [use_phw_ggplot()] (and
#' [use_phw_flextable()] for flextable) once in the setup chunk, as the
#' starter documents do.
#'
#' **Accessible colours.** Add `phw-palette: accessible` to the document's
#' YAML header and every chart, table and widget made with phwstyle uses the
#' colour-blind safe palette:
#'
#' ```yaml
#' title: "Report title"
#' phw-palette: accessible
#' format: phw-docx
#' ```
#'
#' To make both versions from one unchanged document, set the environment
#' variable `PHWSTYLE_PALETTE` for the second render instead:
#'
#' ```
#' quarto render report.qmd --to phw-docx
#' PHWSTYLE_PALETTE=accessible quarto render report.qmd --to phw-docx -o report-accessible.docx
#' ```
#'
#' In PowerShell, set it first with `$env:PHWSTYLE_PALETTE = "accessible"`
#' (and clear it afterwards with `Remove-Item Env:PHWSTYLE_PALETTE`). From
#' R, use `Sys.setenv(PHWSTYLE_PALETTE = "accessible")` before rendering and
#' `Sys.unsetenv("PHWSTYLE_PALETTE")` after. The key has to be in the
#' document itself: Quarto doesn't pass `-M` values or `_quarto.yml`
#' settings on to R. See [phw_default_palette()].
#'
#' @param path Project folder.
#' @param template Also write a starter document: `"report"`, `"slides"`,
#'   `"dashboard"`, or `"none"`.
#' @param overwrite Replace an existing extension or template?
#' @return The extension path, invisibly.
#' @examples
#' project <- file.path(tempdir(), "phw-quarto-example")
#' use_phw_quarto(project, template = "report")
#' list.files(project)
#' # Then render report.qmd with Quarto, e.g. the Render button in RStudio.
#' unlink(project, recursive = TRUE)
#' @export
use_phw_quarto <- function(path = ".", template = c("report", "slides", "dashboard", "none"),
                           overwrite = FALSE) {
  template <- rlang::arg_match(template)
  dest <- file.path(path, "_extensions", "phw")
  if (dir.exists(dest) && !overwrite) {
    cli::cli_inform("{.path {dest}} already exists. Use {.code overwrite = TRUE} to update it.")
  } else {
    unlink(dest, recursive = TRUE)
    build_quarto_extension(dest)
    cli::cli_inform(c(v = "Added the PHW Quarto extension to {.path {dest}}."))
    if (!phw_has_logo()) {
      cli::cli_inform(c(i = "No PHW logo found, so outputs won't show one. See {.fn phw_download_logos}."))
    }
  }
  if (template != "none") {
    tfile <- file.path(path, paste0(template, ".qmd"))
    if (file.exists(tfile) && !overwrite) {
      cli::cli_inform("{.path {tfile}} already exists, not overwritten.")
    } else {
      file.copy(phw_file("quarto", "templates", paste0(template, ".qmd")), tfile, overwrite = TRUE)
      cli::cli_inform(c(v = "Wrote {.path {tfile}}."))
    }
  }
  invisible(dest)
}

build_quarto_extension <- function(dest) {
  dir.create(file.path(dest, "fonts"), recursive = TRUE, showWarnings = FALSE)
  src <- phw_file("quarto", "ext")
  file.copy(list.files(src, full.names = TRUE), dest, overwrite = TRUE)
  file.copy(list.files(phw_file("fonts"), full.names = TRUE), file.path(dest, "fonts"), overwrite = TRUE)
  file.copy(phw_file("css", "phw-fonts-embedded.css"), file.path(dest, "phw-fonts.css"), overwrite = TRUE)
  file.copy(phw_graphic("cover"), file.path(dest, "cover-a4.jpg"), overwrite = TRUE)
  cover_wide_with_logo(file.path(dest, "cover-wide.jpg"))
  band_with_logo(file.path(dest, "header-band-logo.png"))
  phw_reference_docx(file.path(dest, "phw-reference.docx"))
  writeLines(html_band(), file.path(dest, "phw-band.html"))

  # Logos: real files if available, otherwise blank placeholders so the
  # Typst, LaTeX, dashboard and slide formats still render.
  for (v in c("white", "blue")) {
    svg <- phw_logo(v, "svg")
    out <- file.path(dest, sprintf("phw-logo-%s.svg", v))
    if (is.null(svg)) writeLines(blank_svg, out) else file.copy(svg, out, overwrite = TRUE)
  }
  png_logo <- phw_logo("white", "png")
  out <- file.path(dest, "phw-logo-white.png")
  if (is.null(png_logo)) write_blank_png(out) else file.copy(png_logo, out, overwrite = TRUE)

  paths <- list(fontdir = "./_extensions/phw/fonts/", band = "header-band-logo.png",
                cover = "cover-a4.jpg", logo = "phw-logo-white.png", logo_ok = !is.null(png_logo))
  writeLines(fill_latex_header(paths), file.path(dest, "phw-header.tex"))
  invisible(dest)
}
