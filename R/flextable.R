#' Apply PHW styling to a flextable
#'
#' Styles an existing flextable the way PHW and its Communicable Disease
#' Surveillance Centre (CDSC) present tables in reports. Four styles are available:
#'
#' * `"booktabs"` (default): horizontal rules only, as in printed journal
#'   tables: a navy rule above and below the header and along the bottom, a
#'   bold header, no vertical lines and no fill.
#' * `"header"`: a navy header band with white bold text.
#' * `"light"`: a light-teal header band with dark text (as in the weekly acute
#'   respiratory infection report).
#' * `"zebra"`: `"booktabs"` plus light grey banding on alternate rows.
#'
#' Numbers are right-aligned and text is left-aligned. In every style the
#' font is Ubuntu (or the [phw_font()] fallback).
#'
#' @param x A flextable.
#' @param style `"booktabs"`, `"header"`, `"light"` or `"zebra"`.
#' @param font_size Body font size in points. Header uses the same size.
#' @param font_family Font family.
#' @param bold_first_col Bold the first column? (Area names in many PHW tables.)
#' @param total_row Treat the last row as a total row (bold with a rule
#'   above)?
#' @param accent Colour of the rules and header (navy by default).
#' @param header_bg,header_colour Override the header fill and text colour.
#' @param text_colour Body text colour.
#' @param stripe_colour Fill for alternate rows in `"zebra"`.
#' @param padding Cell padding in points: one number, or
#'   `c(top_bottom, left_right)`, or `NULL` to keep the existing padding
#'   (for tables that use padding for indents, such as gtsummary output).
#' @param align Align numbers right and text left automatically? Set to
#'   `FALSE` to keep your own alignment.
#' @return A flextable.
#' @examples
#' if (requireNamespace("flextable", quietly = TRUE)) {
#'   ft <- flextable::flextable(head(airquality))
#'   phw_flextable_theme(ft)
#' }
#' @export
phw_flextable_theme <- function(x, style = c("booktabs", "header", "light", "zebra"),
                                font_size = 10, font_family = phw_font(),
                                bold_first_col = FALSE, total_row = FALSE,
                                accent = phw_colours[["navy"]], header_bg = NULL,
                                header_colour = NULL, text_colour = phw_colours[["text"]],
                                stripe_colour = phw_colours[["grey_bg"]],
                                padding = c(3, 5), align = TRUE) {
  rlang::check_installed(c("flextable", "officer"))
  style <- rlang::arg_match(style)
  col <- phw_colours
  col[["navy"]] <- accent
  col[["text"]] <- text_colour
  col[["grey_bg"]] <- stripe_colour
  ft <- flextable::font(x, fontname = font_family, part = "all")
  ft <- flextable::fontsize(ft, size = font_size, part = "all")
  ft <- flextable::color(ft, color = col[["text"]], part = "all")
  ft <- flextable::border_remove(ft)
  ft <- flextable::bg(ft, bg = "transparent", part = "all")
  ft <- flextable::bold(ft, part = "header")
  ft <- flextable::valign(ft, valign = "center", part = "all")
  if (!is.null(padding)) {
    pad <- rep_len(padding, 2)
    ft <- flextable::padding(ft, padding.top = pad[1], padding.bottom = pad[1],
                             padding.left = pad[2], padding.right = pad[2], part = "all")
  }
  ft <- flextable::line_spacing(ft, space = 1, part = "all")

  navy <- officer::fp_border(color = col[["navy"]], width = 1.5)
  thin <- officer::fp_border(color = col[["grey_border"]], width = 0.75)
  nb <- flextable::nrow_part(ft, "body")

  if (style %in% c("booktabs", "zebra")) {
    ft <- flextable::hline_top(ft, border = navy, part = "header")
    ft <- flextable::hline_bottom(ft, border = navy, part = "header")
    ft <- flextable::hline_bottom(ft, border = navy, part = "body")
    ft <- flextable::color(ft, color = col[["navy"]], part = "header")
  }
  if (style == "header") {
    ft <- flextable::bg(ft, bg = col[["navy"]], part = "header")
    ft <- flextable::color(ft, color = "#FFFFFF", part = "header")
    ft <- flextable::hline(ft, border = thin, part = "body")
    ft <- flextable::hline_bottom(ft, border = navy, part = "body")
  }
  if (style == "light") {
    ft <- flextable::bg(ft, bg = col[["light_teal"]], part = "header")
    ft <- flextable::color(ft, color = col[["text"]], part = "header")
    ft <- flextable::border_outer(ft, border = thin, part = "all")
    ft <- flextable::border_inner(ft, border = thin, part = "all")
  }
  if (style == "zebra" && nb > 1) {
    even <- seq(2, nb, by = 2)
    ft <- flextable::bg(ft, i = even, bg = col[["grey_bg"]], part = "body")
  }
  if (bold_first_col) ft <- flextable::bold(ft, j = 1, part = "body")
  if (total_row && nb > 0) {
    ft <- flextable::bold(ft, i = nb, part = "body")
    if (nb > 1) ft <- flextable::hline(ft, i = nb - 1, border = navy, part = "body")
  }

  if (!is.null(header_bg)) ft <- flextable::bg(ft, bg = header_bg, part = "header")
  if (!is.null(header_colour)) ft <- flextable::color(ft, color = header_colour, part = "header")
  if (align) ft <- align_by_type(ft)
  ft
}

`%||%` <- function(x, y) if (is.null(x)) y else x

align_by_type <- function(ft) {
  data <- ft$body$dataset
  keys <- ft$col_keys
  num <- keys[vapply(keys, function(k) k %in% names(data) && is.numeric(data[[k]]), logical(1))]
  txt <- setdiff(keys, num)
  if (length(num)) ft <- flextable::align(ft, j = num, align = "right", part = "all")
  if (length(txt)) ft <- flextable::align(ft, j = txt, align = "left", part = "all")
  ft
}

#' Make a PHW-styled flextable from a data frame
#'
#' One call that builds a flextable, formats numbers with thousands
#' separators, applies [phw_flextable_theme()] and adds the PHW caption and
#' source line. The caption ("Table 1 ...") goes above and the bold source
#' goes below, right-aligned.
#'
#' @param data A data frame, or a summary table from [phw_summary_table()],
#'   [phw_crosstab()], [phw_rate_table()] or [phw_risk_table()]. Summary
#'   tables get bold variable headings, indented levels, a header spanning
#'   the group columns and a note on the statistics shown.
#' @param caption Table title, e.g. `"Counts by health board, 2020-2024"`.
#'   In a Quarto chunk that sets the `tbl-cap` option, Quarto's caption is
#'   shown instead.
#' @param number Optional table number. Gives "Table 1 ...".
#' @param number_prefix Word before the number.
#' @param source,date Passed to [phw_caption()] and shown under the table.
#' @param caption_args List of other [phw_caption()] arguments, e.g.
#'   `list(note = "Provisional")`.
#' @param flextable_args List of arguments for [flextable::flextable()],
#'   e.g. `list(col_keys = c("area", "rate"))`. For a summary table,
#'   `col_keys` must start with its label columns.
#' @param style Passed to [phw_flextable_theme()].
#' @param digits Decimal places for non-integer numbers. Defaults to the
#'   `digits` of a [phw_group_table()], or 1.
#'   Whole numbers show with a thousands separator, except in a year
#'   column: whole numbers from 1800 to 2200 in a column whose name has the
#'   word "year", "yr" or "blwyddyn" in it, such as `Year`, `year_of_onset`
#'   or `Blwyddyn`. These show as 2021, not 2,021.
#' @param col_labels Optional named list of display names, as in
#'   [flextable::set_header_labels()].
#' @param autofit Fit column widths to their content? In a Word or PDF
#'   document, a table wider than the page is narrowed to fit the text width
#'   either way: its headings wrap first, then its cells, and its text
#'   shrinks to no less than 8 pt if the words alone are still too wide.
#'
#'   In a PowerPoint deck made with R Markdown or Quarto, or with
#'   [phw_add_slide()], text is never smaller than 12 pt, so the table can
#'   be read when projected: smaller text, such as the 10 pt default, is
#'   shown at 12 pt. A table with room to spare grows to fill the slide's
#'   content area, with its text up to 18 pt (see the `table_fit` argument
#'   of [phw_add_slide()]). A table wider than the slide's content area
#'   wraps its headings, then its cells. A table too long for the slide
#'   tightens its row spacing, and if it still does not fit, its rows
#'   continue on further slides. Each slide repeats the header row, the
#'   caption is marked with `continued` after the first slide, and the source
#'   goes on the last slide. A table too wide to fit even with its text
#'   wrapped gives a warning.
#' @param continued Text added after the caption on the slides a long table
#'   continues on, in a PowerPoint deck. Give your own wording, for example
#'   in Welsh.
#' @param ... Passed to [phw_flextable_theme()].
#' @return A flextable.
#' @examples
#' if (requireNamespace("flextable", quietly = TRUE)) {
#'   phw_flextable(head(mtcars[, 1:4]), caption = "Example", source = "mtcars")
#' }
#' @export
phw_flextable <- function(data, caption = NULL, number = NULL, source = NULL,
                          date = NULL, style = "booktabs", digits = 1,
                          col_labels = NULL, autofit = TRUE, number_prefix = "Table",
                          caption_args = list(), flextable_args = list(),
                          continued = "(continued)", ...) {
  rlang::check_installed(c("flextable", "officer"))
  check_one_string(continued)
  data <- check_table_data(data)
  data <- blank_non_finite(data)
  if (missing(digits)) digits <- attr(data, "digits") %||% digits
  if (inherits(data, "phw_summary")) check_summary_keys(data, flextable_args$col_keys)
  ft <- do.call(flextable::flextable, c(list(as.data.frame(data)), flextable_args))
  shown <- names(data) %in% ft$col_keys
  is_int <- vapply(data, is_whole, logical(1)) & shown
  is_dbl <- vapply(data, is.numeric, logical(1)) & shown & !is_int
  is_year <- year_cols(data) & shown
  if (any(is_year)) ft <- flextable::colformat_num(ft, j = names(data)[is_year], big.mark = "", na_str = "")
  if (any(is_int & !is_year)) ft <- flextable::colformat_double(ft, j = names(data)[is_int & !is_year], digits = 0, big.mark = ",", na_str = "")
  if (any(is_dbl)) ft <- flextable::colformat_double(ft, j = names(data)[is_dbl], digits = digits, big.mark = ",", na_str = "")
  if (!is.null(col_labels)) ft <- do.call(flextable::set_header_labels, c(list(ft), col_labels))
  ft <- phw_flextable_theme(ft, style = style, ...)
  if (inherits(data, "phw_summary")) {
    ft <- style_summary_ft(ft, data, names(col_labels))
    attr(ft, "phw_keep") <- summary_rows(data)$keep
  }

  if (!is.null(caption)) {
    title <- if (is.null(number)) caption else paste(number_prefix, number, caption)
    ft <- flextable::set_caption(
      ft,
      caption = flextable::as_paragraph(flextable::as_chunk(
        title,
        props = officer::fp_text(font.family = phw_font(), bold = TRUE,
                                 color = phw_colours[["navy"]], font.size = 11))),
      fp_p = officer::fp_par(text.align = "left", padding.bottom = 4),
      align_with_table = FALSE)
  }
  cap <- caption_from(source, date, caption_args)
  if (!is.null(cap)) {
    ft <- flextable::add_footer_lines(ft, values = cap)
    k <- flextable::nrow_part(ft, "footer")
    ft <- flextable::style(ft, i = k, part = "footer",
                           pr_t = officer::fp_text(bold = TRUE, italic = FALSE, font.size = 8.5,
                                                   font.family = phw_font(), color = phw_colours[["text"]]))
    ft <- flextable::align(ft, i = k, align = "right", part = "footer")
  }
  if (autofit) ft <- flextable::autofit(ft)
  attr(ft, "phw_continued") <- continued
  class(ft) <- c("phw_flextable", class(ft))
  ft
}

# The caption text already holds any table number, so in LaTeX it goes in an
# unnumbered \caption* rather than one LaTeX labels "Table N." again.
#' @exportS3Method knitr::knit_print
knit_print.phw_flextable <- function(x, ...) {
  if (knitr::pandoc_to("pptx")) return(knit_slide_table(x, ...))
  # Under Quarto, flextable leaves the caption to the chunk's tbl-cap and drops
  # one set with set_caption(), so it goes in the table's top row instead.
  if (!is.null(knitr::opts_knit$get("quarto.version")) && is.null(knitr::opts_current$get("tbl-cap"))) {
    x <- caption_as_header(x)
  }
  if (knitr::pandoc_to("docx")) x <- fit_table_to_width(x, page_text_width)
  if (knitr::is_latex_output()) {
    # LaTeX adds \tabcolsep points either side of each column's width.
    sep <- knitr::opts_current$get("ft.tabcolsep") %||% x$properties$opts_pdf$tabcolsep
    x <- fit_table_to_width(x, page_text_width - length(x$col_keys) * 2 * sep / 72)
  }
  out <- NextMethod()
  if (knitr::is_latex_output()) out[] <- gsub("\\\\caption(\\[\\])?\\{", "\\\\caption*{", out)
  # flextable's CSS names Ubuntu but brings no font file, so a browser without
  # Ubuntu installed draws the table in its default serif font.
  if (knitr::is_html_output(excludes = "gfm")) {
    attr(out, "knit_meta") <- c(attr(out, "knit_meta"), list(phw_font_dependency()))
  }
  out
}

# flextable puts the table ft.left inches from the slide's left edge and
# ft.top inches from its top. A table too long for the slide continues on
# slides that a horizontal rule starts.
knit_slide_table <- function(x, ...) {
  check_no_images(x)
  # Quarto's PowerPoint writer shows no tbl-cap, so it becomes the caption row.
  cap <- knitr::opts_current$get("tbl-cap")
  if (is.character(cap) && length(cap) == 1) x <- flextable::set_caption(x, cap)
  left <- knitr::opts_current$get("ft.left") %||% 1
  top <- knitr::opts_current$get("ft.top") %||% 2
  size <- knit_slide_size()
  pages <- slide_table_pages(x, size[["width"]] - left - slide_margins[["side"]],
                             size[["height"]] - top - slide_margins[["bottom"]], grow = TRUE)
  out <- lapply(pages, function(page) {
    class(page) <- setdiff(class(page), "phw_flextable")
    knitr::knit_print(page, ...)
  })
  knitr::asis_output(paste(unlist(out), collapse = "\n\n---\n\n"))
}

#' @exportS3Method htmltools::as.tags
as.tags.phw_flextable <- function(x, ...) {
  htmltools::attachDependencies(flextable::htmltools_value(x, ...), phw_font_dependency(), append = TRUE)
}

#' @export
print.phw_flextable <- function(x, preview = "html", align = "center", ...) {
  if (!identical(preview, "html") || !rlang::is_interactive()) return(NextMethod())
  print(htmltools::browsable(htmltools::as.tags(x, ft.align = align)))
  invisible(x)
}

# A4 less the 2 cm side margins of the PHW Word reference document and PDF
# format, in inches.
page_text_width <- (210 - 2 * 20) / 25.4

# The size of a slide in the PHW reference deck, in inches, taken for a
# knitted deck whose own size can't be read.
slide_width <- 13.333
slide_height <- 7.5

# The slide size, in inches, of the deck being knitted: that of its reference
# deck, or of pandoc's own reference deck when it names none.
knit_slide_size <- function() {
  size <- tryCatch({
    deck <- knit_reference_deck()
    if (!is.null(deck)) unlist(officer::slide_size(officer::read_pptx(deck)))
  }, error = function(e) NULL)
  size %||% c(width = slide_width, height = slide_height)
}

# The reference deck of the format being knitted, a copy of pandoc's own when
# the format names none, or NULL when Quarto's format can't be found. Quarto
# gives its path from the document's folder, and R Markdown from the folder it
# knits in.
knit_reference_deck <- function() {
  if (is.null(knitr::opts_knit$get("quarto.version"))) {
    args <- knitr::opts_knit$get("rmarkdown.pandoc.args")
    i <- match("--reference-doc", args)
    deck <- if (!is.na(i)) args[[i + 1]]
    base <- knitr::opts_knit$get("output.dir") %||% "."
  } else {
    format <- quarto_format()
    if (is.null(format)) return(NULL)
    deck <- format$pandoc[["reference-doc"]]
    base <- dirname(knitr::current_input(dir = TRUE))
  }
  if (is.null(deck)) return(pandoc_reference_deck())
  if (file.exists(file.path(base, deck))) file.path(base, deck) else deck
}

# The format Quarto is rendering. Recent versions name a file holding it in
# QUARTO_EXECUTE_INFO; older ones keep it only in their own R function that
# runs the knit.
quarto_format <- function() {
  info <- Sys.getenv("QUARTO_EXECUTE_INFO")
  if (nzchar(info)) return(jsonlite::read_json(info)$format)
  for (env in rev(sys.frames())) {
    format <- get0("format", envir = env, inherits = FALSE)
    if (is.list(format) && is.list(format$pandoc)) return(format)
  }
}

# Written once a session. Under Quarto this is the deck of the pandoc
# rmarkdown finds, which may not be Quarto's own.
pandoc_reference_deck <- function() {
  deck <- file.path(tempdir(), "pandoc-reference.pptx")
  if (!file.exists(deck)) {
    status <- system2(rmarkdown::pandoc_exec(), c("--print-default-data-file", "reference.pptx"), stdout = deck)
    if (!identical(status, 0L)) unlink(deck)
  }
  deck
}

# Narrows a table wider than `width` by letting its text wrap at spaces: the
# headings first, then the body cells. Each column gives up a share of the
# width it can lose, and keeps at least its widest word. If the words alone
# are too wide, the text shrinks as well, down to `min_size` points for the
# largest text, or with `floor = "all"`, as on slides, for all of it.
fit_table_to_width <- function(ft, width, min_size = 8, where = "the page", floor = "largest") {
  if (sum(ft$body$colwidths) <= width) return(ft)
  parts <- c("header", "body", "footer")
  wrapped <- function(ft, parts) {
    for (part in parts) {
      ft[[part]]$content$data[] <- lapply(ft[[part]]$content$data, function(chunks) {
        chunks$txt <- gsub(" ", "\n", chunks$txt, fixed = TRUE)
        chunks
      })
    }
    flextable::dim_pretty(ft)$widths
  }
  steps <- list(flextable::dim_pretty(ft)$widths, wrapped(ft, "header"), wrapped(ft, parts))
  fits <- which(vapply(steps, sum, numeric(1)) <= width)
  if (length(fits)) {
    k <- fits[1]
    widths <- if (k == 1) steps[[1]] else squeeze(steps[[k - 1]], steps[[k]], width)
    return(flextable::width(ft, j = seq_along(widths), width = widths))
  }
  resize <- function(ft, scale) {
    for (part in parts) ft[[part]]$styles$text$font.size$data[] <- ft[[part]]$styles$text$font.size$data * scale
    ft
  }
  sizes <- unlist(lapply(parts, function(part) ft[[part]]$styles$text$font.size$data))
  least <- min(min_size / if (floor == "all") min(sizes, na.rm = TRUE) else max(sizes, na.rm = TRUE), 1)
  smallest <- sum(wrapped(resize(ft, least), parts))
  if (smallest > width) {
    cli::cli_warn(c("The table's {length(ft$col_keys)} columns are too wide for {where}, even with their text wrapped and at {min_size} pt, so the table runs past the margin.",
                    i = "Show fewer columns, or split the table in two."))
    scale <- least
  } else {
    # Column widths are linear in the text size, so the size that fits is
    # read off the widths at full and smallest size.
    full <- sum(steps[[3]])
    scale <- 1 - (1 - least) * (full - width) / (full - smallest)
  }
  ft <- resize(ft, scale)
  widths <- wrapped(ft, parts)
  flextable::width(ft, j = seq_along(widths), width = widths)
}

# Widths between `wide` and `narrow` that add up to `width`.
squeeze <- function(wide, narrow, width) {
  narrow + (wide - narrow) * (width - sum(narrow)) / (sum(wide) - sum(narrow))
}

#' Set PHW defaults for every new flextable
#'
#' Sets [flextable::set_flextable_defaults()] so all new flextables use the
#' PHW font, colours and padding, and applies [phw_flextable_theme()]
#' automatically. Put it in your setup chunk.
#'
#' @param style Passed to [phw_flextable_theme()].
#' @param font_size Body font size.
#' @param ... Other [phw_flextable_theme()] arguments, e.g. `accent`.
#' @return The previous defaults, invisibly.
#' @examples
#' if (requireNamespace("flextable", quietly = TRUE)) {
#'   old <- use_phw_flextable()
#'   flextable::flextable(head(airquality))
#'
#'   # Put back the defaults you had before
#'   do.call(flextable::set_flextable_defaults, old)
#' }
#' @export
use_phw_flextable <- function(style = "booktabs", font_size = 10, ...) {
  rlang::check_installed(c("flextable", "officer"))
  style <- rlang::arg_match(style, c("booktabs", "header", "light", "zebra"))
  theme_args <- list(...)
  old <- flextable::set_flextable_defaults(
    font.family = phw_font(), font.size = font_size,
    font.color = phw_colours[["text"]],
    border.color = phw_colours[["grey_border"]],
    padding.top = 3, padding.bottom = 3, padding.left = 5, padding.right = 5,
    big.mark = ",", decimal.mark = ".", digits = 1, na_str = "",
    theme_fun = function(x) do.call(phw_flextable_theme, c(list(x, style = style, font_size = font_size), theme_args))
  )
  invisible(old)
}

#' Colour flextable cells by value
#'
#' Fills cells in the given columns with a PHW sequential palette, the way
#' PHW heat tables do, and picks white or dark text automatically so values
#' stay readable.
#'
#' For `palette = "rag"`, colour alone doesn't work for colour-blind
#' readers or in black-and-white print, so `symbols = TRUE` (the default)
#' adds a shape before each value as well.
#'
#' On a summary table from [phw_flextable()], only the level rows are
#' coloured. Headings, subtotals and totals keep their own styling and do
#' not count towards the colour scale, so a total does not make every other
#' cell pale. The same goes for the total columns of a [phw_crosstab()] or
#' [phw_group_table()], so `j = -1` colours every column but the totals.
#' Choose only total columns to colour them on a scale of their own.
#'
#' @param x A flextable.
#' @param j Columns to colour, chosen from the columns the table shows as
#'   in [dplyr::select()]: unquoted names such as `c(rate, cases)`, positions
#'   such as `2:5`, or strings.
#' @param palette A sequential or diverging palette name, a vector of
#'   colours, `"rag"` or `"rag_accessible"` (navy instead of green).
#' @param domain Range of values the palette spans. Defaults to the range of
#'   the coloured cells. Set it to keep one scale across several tables:
#'   values beyond it take the colour at the nearer end.
#' @param breaks For `palette = "rag"`: two cut points (red below the first,
#'   green at or above the second).
#' @param higher_is_better For `"rag"`: is a high value good (green)?
#' @param symbols For `"rag"`: add a shape before each value (a down
#'   triangle for red, a square for amber, an up triangle for green)?
#' @return A flextable.
#' @examples
#' if (requireNamespace("flextable", quietly = TRUE)) {
#'   rates <- data.frame(Area = paste("Area", LETTERS[1:4]),
#'                       `2024` = c(3.2, 1.5, 3.8, 2.3), `2025` = c(4.4, 0.7, 4.2, 0.2),
#'                       check.names = FALSE)
#'   phw_flextable(rates) |>
#'     phw_flextable_heat(j = 2:3)
#'
#'   # Red, amber and green, with a shape in each cell as a second cue
#'   uptake <- data.frame(Area = paste("Area", LETTERS[1:4]),
#'                        Uptake = c(0.96, 0.93, 0.91, 0.95))
#'   phw_flextable(uptake, digits = 2) |>
#'     phw_flextable_heat(Uptake, palette = "rag_accessible", breaks = c(0.92, 0.95))
#' }
#' @export
phw_flextable_heat <- function(x, j, palette = "teals", domain = NULL, breaks = NULL,
                               higher_is_better = TRUE, symbols = TRUE) {
  rlang::check_installed("flextable")
  check_flextable(x)
  data <- x$body$dataset
  # Choose among the columns shown: `col_keys` can hide some.
  j <- pick_cols(rlang::enquo(j), data[intersect(names(data), x$col_keys)], "j")
  rows <- heat_rows(data)
  j <- value_cols(data[rows, , drop = FALSE], heat_cols(data, j), "j")
  if (!length(j)) return(x)
  vals <- unlist(data[rows, j])
  rag <- identical(palette, "rag") || identical(palette, "rag_accessible")
  if (rag) {
    check_breaks(breaks)
    fill_fun <- function(v) {
      out <- unname(phw_palettes[[palette]][rag_status(v, breaks, higher_is_better)])
      out[is.na(v)] <- "transparent"
      out
    }
  } else {
    fill_fun <- heat_fill(palette, domain %||% range(vals, na.rm = TRUE))
  }
  shapes <- c(red = "\u25BC", amber = "\u25A0", green = "\u25B2")
  for (col in j) {
    v <- data[[col]][rows]
    fills <- fill_fun(v)
    x <- flextable::bg(x, i = rows, j = col, bg = fills, part = "body")
    txt <- ifelse(fills == "transparent", phw_colours[["text"]], phw_text_on(sub("transparent", "#FFFFFF", fills)))
    x <- flextable::color(x, i = rows, j = col, color = txt, part = "body")
    if (rag && symbols) {
      i <- rows[!is.na(v)]
      if (length(i)) {
        x <- flextable::prepend_chunks(x, i = i, j = col, part = "body",
                                       flextable::as_chunk(paste0(shapes[rag_status(v[!is.na(v)], breaks, higher_is_better)], " ")))
      }
    }
  }
  x
}

# "red", "amber" or "green" for each value: below the first break, from the
# first up to the second, or at or above the second.
rag_status <- function(v, breaks, higher_is_better) {
  band <- ifelse(v < breaks[1], 1L, ifelse(v < breaks[2], 2L, 3L))
  status <- if (higher_is_better) c("red", "amber", "green") else c("green", "amber", "red")
  status[band]
}

# Colour function for a heat scale over the range of `domain`, in any order
# or pooled from several tables. Values beyond it take the end colour, as on
# a chart with `oob = scales::squish`, so a fixed domain shared across tables
# never leaves a cell blank.
heat_fill <- function(palette, domain) {
  domain <- range(domain, na.rm = TRUE)
  pal <- scales::col_numeric(seq_cols(palette, FALSE), domain = domain, na.color = "transparent")
  function(v) pal(scales::oob_squish(v, domain))
}

#' Colour flextable cells by group
#'
#' Colours cells by the group they contain, using the same colours as your
#' charts. With a `key`, each group keeps its colour across tables, charts
#' and reports (see [phw_colour_key()]).
#'
#' On a summary table from [phw_flextable()], only the level rows are
#' coloured. Headings, subtotals and totals keep their own styling and are
#' not added to the key.
#'
#' @param x A flextable.
#' @param j Column that holds the groups, unquoted as in dplyr. A string or
#'   a position works too.
#' @param key,palette,values Passed to [phw_colour_key()] as `name`,
#'   `palette` and `fixed`.
#' @param what Colour the cell `"background"` or the `"text"`?
#' @param rows Colour the whole row (`TRUE`) or only column `j`?
#' @return A flextable. Rows with a missing (`NA`) group are left uncoloured.
#' @examples
#' if (requireNamespace("flextable", quietly = TRUE)) {
#'   df <- data.frame(Group = c("Group A", "Group B", "Group C", "Unknown"),
#'                    Cases = c(120, 85, 64, 9))
#'   phw_flextable(df) |>
#'     phw_flextable_groups(Group)
#'
#'   # Colour the text instead, across the whole row
#'   phw_flextable(df) |>
#'     phw_flextable_groups(Group, what = "text", rows = TRUE)
#' }
#' @export
phw_flextable_groups <- function(x, j, key = NULL, palette = phw_default_palette(),
                                 values = NULL, what = c("background", "text"), rows = FALSE) {
  rlang::check_installed("flextable")
  what <- rlang::arg_match(what)
  check_flextable(x)
  data <- x$body$dataset
  j <- pick_col(rlang::enquo(j), data, "j")
  lv <- heat_rows(data)
  groups <- table_groups(data, j)
  cols <- phw_colour_key(table_group_levels(groups, data), name = key, palette = palette, fixed = values)
  fill <- unname(cols[as.character(groups)])
  # A missing group has no colour: leave its row as it is.
  i <- lv[!is.na(fill)]
  if (!length(i)) return(x)
  fill <- fill[!is.na(fill)]
  target <- if (rows) x$col_keys else j
  for (k in target) {
    if (what == "background") {
      x <- flextable::bg(x, i = i, j = k, bg = fill, part = "body")
      x <- flextable::color(x, i = i, j = k, color = phw_text_on(fill), part = "body")
    } else {
      x <- flextable::color(x, i = i, j = k, color = fill, part = "body")
    }
  }
  x
}

style_summary_ft <- function(ft, x, relabelled = character()) {
  r <- summary_rows(x)
  nl <- attr(x, "label_cols") %||% 1L
  shown <- match(ft$col_keys[-seq_len(nl)], names(x))
  nd <- length(shown)
  data_j <- nl + seq_len(nd)
  navy <- officer::fp_border(color = phw_colours[["navy"]], width = 1)
  grey <- officer::fp_border(color = phw_colours[["grey_mid"]], width = 0.75)
  lab_j <- seq_len(nl)
  ft <- flextable::align(ft, j = lab_j, align = "left", part = "all")
  if (any(r$bold)) ft <- flextable::bold(ft, i = which(r$bold), part = "body")
  if (any(r$navy)) ft <- flextable::color(ft, i = which(r$navy), j = lab_j, color = phw_colours[["navy"]], part = "body")
  if (any(r$shade)) ft <- flextable::bg(ft, i = which(r$shade), bg = phw_colours[["grey_bg"]], part = "body")
  if (any(r$italic)) ft <- flextable::italic(ft, i = which(r$italic), j = lab_j, part = "body")
  for (d in setdiff(unique(r$indent), 0)) {
    ft <- flextable::padding(ft, i = which(r$indent == d), j = 1, padding.left = 4 + 12 * d, part = "body")
  }
  tot <- which(r$rule)
  above <- tot[tot > 1] - 1
  if (length(above)) ft <- flextable::hline(ft, i = above, border = navy, part = "body")
  if (1 %in% tot && nrow(x) > 1) ft <- flextable::hline(ft, i = 1, border = navy, part = "body")
  if (any(r$space)) ft <- flextable::padding(ft, i = which(r$space), padding.top = 10, part = "body")
  line <- setdiff(which(r$line) - 1, 0)
  if (length(line)) ft <- flextable::hline(ft, i = line, border = grey, part = "body")
  # Numbers and statistics right-aligned, whatever their type.
  if (nd) ft <- flextable::align(ft, j = data_j, align = "right", part = "all")
  multi <- !is.null(attr(x, "col_header"))
  hd <- summary_header(x, nl, shown - nl)
  # Spanner rows copy the column labels' colours. On a dark header band
  # their rule is white so it stays visible.
  fill <- ft$header$styles$cells$background.color$data[1, data_j[1]]
  dark <- nd && fill != "transparent" && phw_text_on(fill) == "#FFFFFF"
  rule <- if (dark) officer::fp_border(color = "#FFFFFF", width = 0.75) else grey
  if (length(hd$upper)) {
    if (multi) {
      labs <- stats::setNames(as.list(hd$bottom), names(x)[shown])
      labs <- labs[setdiff(names(labs), relabelled)]
      if (length(labs)) ft <- do.call(flextable::set_header_labels, c(list(ft), labs))
    }
    # A grand total keeps its label at every level, so merge_v() joins it
    # into one cell.
    for (level in rev(hd$upper)) {
      ft <- flextable::add_header_row(ft, values = c(rep("", nl), level$label), colwidths = c(rep(1, nl), level$n))
      ft <- flextable::hline(ft, i = 1, j = data_j, border = rule, part = "header")
    }
    # add_header_row() copies the label row's rules into the new rows, so
    # clear them over the label columns and under empty cells (a column
    # added to the table): the table's top rule stays on top.
    for (l in seq_along(hd$upper)) {
      blank <- data_j[!nzchar(rep(hd$upper[[l]]$label, hd$upper[[l]]$n))]
      ft <- flextable::hline(ft, i = l, j = c(lab_j, blank),
                             border = officer::fp_border(width = 0), part = "header")
    }
    if (multi) ft <- flextable::merge_v(ft, j = data_j, part = "header")
    ft <- flextable::align(ft, i = seq_along(hd$upper), j = data_j, align = "center", part = "header")
    ft <- flextable::bold(ft, part = "header")
  }
  note <- attr(x, "note")
  if (!is.null(note)) {
    ft <- flextable::add_footer_lines(ft, values = note)
    ft <- flextable::italic(ft, i = flextable::nrow_part(ft, "footer"), part = "footer")
    ft <- flextable::fontsize(ft, i = flextable::nrow_part(ft, "footer"), size = 8.5, part = "footer")
    ft <- flextable::color(ft, i = flextable::nrow_part(ft, "footer"), color = phw_colours[["text_secondary"]], part = "footer")
  }
  ft
}

# style_summary_ft() bolds, indents and spans the label columns by position,
# so `col_keys` may drop or reorder the other columns but not the labels.
check_summary_keys <- function(x, keys, call = rlang::caller_env()) {
  if (is.null(keys)) return(invisible())
  labels <- names(x)[seq_len(attr(x, "label_cols") %||% 1L)]
  unknown <- setdiff(keys, names(x))
  if (length(unknown)) {
    cli::cli_abort(c("{.code col_keys} must name columns of the summary table.",
                     x = "Not columns: {.val {unknown}}."), call = call)
  }
  if (!identical(keys[seq_along(labels)], labels)) {
    cli::cli_abort(c("{.code col_keys} must start with the label {cli::qty(labels)}column{?s} {.val {labels}}.",
                     i = "Drop or reorder the other columns."), call = call)
  }
  invisible()
}

#' Add in-cell bars to a flextable
#'
#' Draws a small horizontal bar before each value, scaled to the largest
#' value in the column, so readers can compare sizes at a glance (as in
#' many PHW summary tables).
#'
#' On a summary table from [phw_flextable()], only the level rows get bars.
#' Headings, subtotals and totals show the number only and do not count
#' towards the scale, so a total does not shrink every other bar.
#'
#' The bars are small pictures. They show in HTML, PDF and Word reports
#' (in Word, use [phw_word_document()]). PowerPoint tables cannot show
#' pictures, so [phw_add_slide()] and a slide deck made with R Markdown stop
#' with a message for a table with bars.
#'
#' @param x A flextable.
#' @param j Columns, chosen from the columns the table shows as in
#'   [dplyr::select()]: unquoted names, positions or strings.
#' @param colour Bar colour.
#' @param width,height Bar size in inches.
#' @param digits Decimal places for the value.
#' @return A flextable.
#' @examples
#' if (requireNamespace("flextable", quietly = TRUE)) {
#'   df <- data.frame(Area = paste("Area", LETTERS[1:4]), Cases = c(120, 85, 64, 19))
#'   phw_flextable_bars(phw_flextable(df), Cases)
#' }
#' @export
phw_flextable_bars <- function(x, j, colour = phw_colours[["light_teal"]], width = 0.9,
                               height = 0.1, digits = 0) {
  rlang::check_installed("flextable")
  check_flextable(x)
  data <- x$body$dataset
  # Choose among the columns shown: `col_keys` can hide some.
  j <- pick_cols(rlang::enquo(j), data[intersect(names(data), x$col_keys)], "j")
  rows <- heat_rows(data)
  j <- value_cols(data[rows, , drop = FALSE], j, "j")
  for (col in j) check_bar_values(data[[col]][rows], col, "j")
  for (col in j) {
    v <- data[[col]]
    mx <- max(v[rows], na.rm = TRUE)
    # Rows without a bar get an empty one, so their numbers line up.
    bar <- ifelse(is.na(v) | !seq_along(v) %in% rows, 0, v)
    x <- flextable::compose(x, j = col, part = "body", value = flextable::as_paragraph(
      flextable::minibar(value = bar, max = mx, barcol = colour,
                         bg = "transparent", width = width, height = height),
      " ", flextable::as_chunk(ifelse(is.na(v), "", fmt_num(v, digits)))))
    x <- flextable::align(x, j = col, align = "left", part = "all")
    # Room for the bar, a space, the widest number and the cell padding, so
    # the number never wraps under the bar.
    size <- x$body$styles$text$font.size$data[1, col] %||% 11
    x <- flextable::width(x, j = col, width = width + 0.3 + size * 0.62 / 72 * max(nchar(fmt_num(v, digits)), 1))
  }
  x
}
