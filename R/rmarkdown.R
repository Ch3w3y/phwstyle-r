#' PHW R Markdown output formats
#'
#' Branded versions of the standard R Markdown formats. Use them in the YAML
#' header of an `.Rmd` file:
#'
#' ```yaml
#' output: phwstyle::phw_html_document
#' ```
#'
#' * `phw_html_document()`: Bootstrap 5 with [phw_bs_theme()], the gradient
#'   header band with the white logo, and PHW styles for the title, headings,
#'   tables and captions. Works offline because the fonts are embedded.
#' * `phw_word_document()`: uses a reference document with Ubuntu, navy
#'   headings, booktabs tables, a gradient band and logo header, and a
#'   "Page x of y" footer.
#' * `phw_pdf_document()`: XeLaTeX with Ubuntu, a full-page gradient cover,
#'   a running header band and a branded footer.
#'
#' All three call [use_phw_ggplot()] (and [use_phw_flextable()] when
#' flextable is installed) before knitting, so charts and tables match
#' without extra code.
#'
#' @param ... Passed to the underlying rmarkdown format.
#' @param toc Include a table of contents?
#' @param number_sections Number the headings (1, 1.1, ...) like PHW reports?
#' @param fig_width,fig_height Default figure size in inches.
#' @param style_plots Apply [use_phw_ggplot()] and [use_phw_flextable()]
#'   while knitting?
#' @return An R Markdown output format.
#' @name phw_formats
NULL

phw_knitr_setup <- function() {
  function(...) {
    use_phw_ggplot()
    if (requireNamespace("flextable", quietly = TRUE)) use_phw_flextable()
  }
}

#' @rdname phw_formats
#' @export
phw_html_document <- function(..., toc = TRUE, number_sections = FALSE,
                              fig_width = 7.5, fig_height = 4.5, style_plots = TRUE) {
  rlang::check_installed(c("rmarkdown", "bslib"))
  band <- tempfile(fileext = ".html")
  writeLines(html_band(), band)
  fmt <- rmarkdown::html_document(
    ...,
    theme = phw_bs_theme(),
    toc = toc, toc_float = toc,
    number_sections = number_sections,
    fig_width = fig_width, fig_height = fig_height,
    dev = if (requireNamespace("ragg", quietly = TRUE)) "ragg_png" else "png",
    css = phw_file("css", "phw-html-document.css"),
    includes = rmarkdown::includes(before_body = band)
  )
  add_setup(fmt, style_plots)
}

#' @rdname phw_formats
#' @export
phw_word_document <- function(..., toc = FALSE, number_sections = FALSE,
                              fig_width = 6.3, fig_height = 3.9, style_plots = TRUE) {
  rlang::check_installed("rmarkdown")
  fmt <- rmarkdown::word_document(
    ...,
    toc = toc,
    number_sections = number_sections,
    fig_width = fig_width, fig_height = fig_height,
    fig_caption = TRUE,
    reference_docx = phw_reference_docx()
  )
  if (requireNamespace("ragg", quietly = TRUE)) fmt$knitr$opts_chunk$dev <- "ragg_png"
  fmt$knitr$opts_chunk$dpi <- 300
  add_setup(fmt, style_plots)
}


#' @rdname phw_formats
#' @param cover Draw the full-page gradient cover when the document has a
#'   title?
#' @param team Team line on the cover, e.g.
#'   `"Communicable Disease Surveillance Centre"`.
#' @export
phw_pdf_document <- function(..., toc = FALSE, number_sections = TRUE,
                             fig_width = 6.3, fig_height = 3.9, cover = TRUE,
                             team = NULL, style_plots = TRUE) {
  rlang::check_installed("rmarkdown")
  header <- phw_latex_header(team = team, cover = cover)
  fmt <- rmarkdown::pdf_document(
    ...,
    toc = toc,
    number_sections = number_sections,
    fig_width = fig_width, fig_height = fig_height,
    fig_caption = TRUE,
    latex_engine = "xelatex",
    includes = rmarkdown::includes(in_header = header),
    pandoc_args = c("--variable", "geometry:a4paper,top=3.2cm,bottom=2.6cm,left=2cm,right=2cm",
                    "--variable", "documentclass:article",
                    "--variable", "fontsize:11pt",
                    "--variable", "colorlinks:true")
  )
  if (requireNamespace("ragg", quietly = TRUE)) fmt$knitr$opts_chunk$dev <- "ragg_png"
  fmt$knitr$opts_chunk$dpi <- 300
  add_setup(fmt, style_plots)
}

#' Write the PHW LaTeX header to a file
#'
#' Fills in the font, logo and image paths in the bundled LaTeX header.
#' [phw_pdf_document()] calls this for you. Use it directly to brand other
#' LaTeX-based formats, e.g. `includes: in_header:` in bookdown.
#'
#' @param file Where to write the header.
#' @param team Optional team line for the cover.
#' @param cover Keep the full-page cover?
#' @return The file path.
#' @export
phw_latex_header <- function(file = tempfile(fileext = ".tex"), team = NULL, cover = TRUE) {
  slash <- function(p) gsub("\\", "/", normalizePath(p, winslash = "/"), fixed = TRUE)
  logo <- phw_logo("white", "png")
  paths <- list(
    fontdir = paste0(slash(phw_file("fonts")), "/"),
    band = slash(band_with_logo()),
    cover = slash(phw_graphic("cover")),
    logo = if (is.null(logo)) "" else slash(logo),
    logo_ok = !is.null(logo)
  )
  writeLines(fill_latex_header(paths, team, cover), file, useBytes = TRUE)
  file
}

add_setup <- function(fmt, style_plots) {
  if (!style_plots) return(fmt)
  setup <- phw_knitr_setup()
  prev <- fmt$pre_knit
  fmt$pre_knit <- function(...) {
    if (is.function(prev)) prev(...)
    setup()
  }
  fmt
}
