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
#' without extra code: don't repeat those calls in the document, and add
#' `theme_phw()` or a PHW scale to a plot only to change something for that
#' plot. If one of these steps fails, the document still renders and a
#' warning says what was left unstyled.
#'
#' **Accessible colours.** `palette = "accessible"` switches every chart,
#' table and widget in the document to the colour-blind safe palette. To
#' make both versions of a report, leave the document alone and set it when
#' you render:
#'
#' ```r
#' word <- "phwstyle::phw_word_document"
#' rmarkdown::render("report.Rmd", word, output_file = "report.docx")
#' rmarkdown::render("report.Rmd", word, output_file = "report-accessible.docx",
#'                   output_options = list(palette = "accessible"))
#' ```
#'
#' Or set it for good in the YAML header:
#'
#' ```yaml
#' output:
#'   phwstyle::phw_word_document:
#'     palette: accessible
#' ```
#'
#' See [phw_default_palette()] for the other ways to switch. For larger
#' text and thicker lines as well, call `use_phw_ggplot(accessible = TRUE)`
#' in the setup chunk.
#'
#' @param ... Passed to the underlying rmarkdown format. Your own `css`,
#'   `includes` and `pandoc_args` are added to the PHW ones, and other
#'   arguments such as `toc_float`, `dev` or `fig_caption` replace the PHW
#'   defaults. The arguments that make the PHW look (`theme` for HTML,
#'   `reference_docx` for Word and `latex_engine` for PDF) can't be changed
#'   here: use the plain rmarkdown format for your own.
#' @param toc Include a table of contents?
#' @param number_sections Number the headings (1, 1.1, ...) like PHW reports?
#' @param fig_width,fig_height Default figure size in inches.
#' @param style_plots Apply [use_phw_ggplot()] and [use_phw_flextable()]
#'   while knitting?
#' @param palette Qualitative palette for the whole document, e.g.
#'   `"accessible"`. `NULL` uses [phw_default_palette()]. The palette is put
#'   back as it was when the render finishes.
#' @return An R Markdown output format.
#' @examples
#' # Use a format in the YAML header of an .Rmd file:
#' #
#' #   output: phwstyle::phw_word_document
#' #
#' # or give it to rmarkdown::render(). Making the format object is quick:
#' if (requireNamespace("rmarkdown", quietly = TRUE)) {
#'   fmt <- phw_word_document(toc = TRUE)
#' }
#' \donttest{
#' # Render one document twice: default colours, then accessible colours
#' if (requireNamespace("rmarkdown", quietly = TRUE) && rmarkdown::pandoc_available() &&
#'     interactive()) {
#'   rmd <- file.path(tempdir(), "report.Rmd")
#'   writeLines(c("---", "title: Example report", "---", "",
#'                "```{r, echo = FALSE}",
#'                "library(ggplot2)",
#'                "ggplot(mpg, aes(class, fill = drv)) + geom_bar()",
#'                "```"), rmd)
#'   rmarkdown::render(rmd, phw_word_document(), output_file = "report.docx")
#'   rmarkdown::render(rmd, phw_word_document(palette = "accessible"),
#'                     output_file = "report-accessible.docx")
#' }
#' }
#' @name phw_formats
NULL

# Style charts and tables before knitting. Each step is tried on its own:
# a problem in one (say, a ggplot2 or flextable version that phwstyle
# doesn't know) shouldn't stop the whole document, but it shouldn't pass
# unnoticed either.
phw_knitr_setup <- function(palette = NULL) {
  force(palette)
  function(...) {
    if (!is.null(palette)) options(phwstyle.palette = palette)
    try_setup("charts", "use_phw_ggplot", use_phw_ggplot())
    if (requireNamespace("flextable", quietly = TRUE)) {
      try_setup("flextable tables", "use_phw_flextable", use_phw_flextable())
    }
    invisible()
  }
}

try_setup <- function(what, fn, expr) {
  tryCatch(expr, error = function(e) {
    cli::cli_warn(c(
      "The PHW style could not be set up for {what}, so they keep their default look.",
      x = "{.fn {fn}} failed: {conditionMessage(e)}",
      i = "The rest of the document is not affected."
    ))
  })
  invisible()
}

#' @rdname phw_formats
#' @export
phw_html_document <- function(..., toc = TRUE, number_sections = FALSE,
                              fig_width = 7.5, fig_height = 4.5, style_plots = TRUE,
                              palette = NULL) {
  rlang::check_installed(c("rmarkdown", "bslib"))
  check_true_false(style_plots)
  dots <- list(...)
  args <- format_args(list(toc = toc, toc_float = toc, number_sections = number_sections,
                           fig_width = fig_width, fig_height = fig_height,
                           dev = if (requireNamespace("ragg", quietly = TRUE)) "ragg_png" else "png"),
                      dots, fixed = "theme", base = "html_document")
  band <- tempfile(fileext = ".html")
  writeLines(html_band(), band)
  args$theme <- phw_bs_theme()
  args$css <- c(phw_file("css", "phw-html-document.css"), dots$css)
  args$includes <- merge_includes(rmarkdown::includes(before_body = band), dots$includes)
  fmt <- do.call(rmarkdown::html_document, args)
  add_setup(fmt, style_plots, palette)
}

#' @rdname phw_formats
#' @export
phw_word_document <- function(..., toc = FALSE, number_sections = FALSE,
                              fig_width = 6.3, fig_height = 3.9, style_plots = TRUE,
                              palette = NULL) {
  rlang::check_installed("rmarkdown")
  check_true_false(style_plots)
  args <- format_args(list(toc = toc, number_sections = number_sections,
                           fig_width = fig_width, fig_height = fig_height, fig_caption = TRUE),
                      list(...), fixed = "reference_docx", base = "word_document")
  args$reference_docx <- phw_reference_docx()
  fmt <- do.call(rmarkdown::word_document, args)
  if (requireNamespace("ragg", quietly = TRUE)) fmt$knitr$opts_chunk$dev <- "ragg_png"
  fmt$knitr$opts_chunk$dpi <- 300
  add_setup(fmt, style_plots, palette)
}

# The arguments for an rmarkdown format: the PHW defaults, replaced by any
# the user gives in `...`, except the `fixed` ones that make the PHW look.
# Arguments that add to the PHW ones (css, includes, pandoc_args) are merged
# by the caller.
format_args <- function(defaults, dots, fixed, base, call = rlang::caller_env()) {
  clash <- intersect(names(dots), fixed)
  if (length(clash)) {
    cli::cli_abort(c("This format sets {.arg {clash}} itself, for the PHW look.",
                     i = "To use your own, call {.fn rmarkdown::{base}} instead."), call = call)
  }
  c(defaults[setdiff(names(defaults), rlang::names2(dots))], dots)
}

merge_includes <- function(ours, theirs) {
  rmarkdown::includes(in_header = c(ours$in_header, theirs$in_header),
                      before_body = c(ours$before_body, theirs$before_body),
                      after_body = c(ours$after_body, theirs$after_body))
}

#' @rdname phw_formats
#' @param cover Draw the full-page gradient cover when the document has a
#'   title?
#' @param team Team line on the cover, e.g.
#'   `"Communicable Disease Surveillance Centre"`.
#' @export
phw_pdf_document <- function(..., toc = FALSE, number_sections = TRUE,
                             fig_width = 6.3, fig_height = 3.9, cover = TRUE,
                             team = NULL, style_plots = TRUE, palette = NULL) {
  rlang::check_installed("rmarkdown")
  check_true_false(style_plots)
  check_true_false(cover)
  dots <- list(...)
  args <- format_args(list(toc = toc, number_sections = number_sections,
                           fig_width = fig_width, fig_height = fig_height, fig_caption = TRUE),
                      dots, fixed = "latex_engine", base = "pdf_document")
  header <- phw_latex_header(team = team, cover = cover)
  args$latex_engine <- "xelatex"
  args$includes <- merge_includes(rmarkdown::includes(in_header = header), dots$includes)
  args$pandoc_args <- c("--variable", "geometry:a4paper,top=3.2cm,bottom=2.6cm,left=2cm,right=2cm",
                        "--variable", "documentclass:article",
                        "--variable", "fontsize:11pt",
                        "--variable", "colorlinks:true", dots$pandoc_args)
  fmt <- do.call(rmarkdown::pdf_document, args)
  if (requireNamespace("ragg", quietly = TRUE)) fmt$knitr$opts_chunk$dev <- "ragg_png"
  fmt$knitr$opts_chunk$dpi <- 300
  add_setup(fmt, style_plots, palette)
}

#' Write the PHW LaTeX header to a file
#'
#' Fills in the font, logo and image paths in the bundled LaTeX header.
#' [phw_pdf_document()] calls this for you. Use it directly to brand other
#' LaTeX-based formats, e.g. `includes: in_header:` in bookdown.
#'
#' @param file Where to write the header.
#' @param team Optional team line for the cover. Characters that LaTeX
#'   treats as commands, such as `&` and `%`, are printed as written.
#' @param cover Keep the full-page cover?
#' @return The file path.
#' @examples
#' f <- phw_latex_header(team = "Team name")
#' head(readLines(f))
#' @export
phw_latex_header <- function(file = tempfile(fileext = ".tex"), team = NULL, cover = TRUE) {
  check_out_file(file)
  check_one_string(team, allow_null = TRUE)
  check_true_false(cover)
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

add_setup <- function(fmt, style_plots, palette = NULL) {
  if (!is.null(palette) && !is.function(palette)) palette_colours(palette)
  if (!style_plots && is.null(palette)) return(fmt)
  setup <- if (style_plots) phw_knitr_setup(palette) else function() options(phwstyle.palette = palette)
  prev <- fmt$pre_knit
  prev_exit <- fmt$on_exit
  state <- new.env(parent = emptyenv())
  fmt$pre_knit <- function(...) {
    if (is.function(prev)) prev(...)
    state$old <- options(phwstyle.palette = getOption("phwstyle.palette"))
    setup()
  }
  # Put the palette back, so rendering one document in accessible colours
  # doesn't change the next one rendered in the same session.
  fmt$on_exit <- function() {
    if (!is.null(state$old)) options(state$old)
    if (is.function(prev_exit)) prev_exit()
  }
  fmt
}
