#' PHW style for gt tables
#'
#' `phw_gt_theme()` restyles an existing [gt::gt()] table: PHW font, navy
#' title and column labels with a navy rule, light row lines and a bold
#' source note. `phw_gt()` builds the table from a data frame (or a
#' [phw_summary_table()] and friends) and adds the title, number formats
#' and source line in one call.
#'
#' In a PDF document from R Markdown, the table stays where it is in the
#' text, a table longer than the page carries on over the next pages with
#' its title and column labels repeated, and a table wider than the text
#' shrinks to fit it.
#'
#' Use gt tables in HTML and PDF. In a Word document they get the PHW font
#' and colours, but gt can't make the column labels bold or indent the levels
#' of a summary table, so use [phw_flextable()] for Word. Quarto shows them
#' in Typst and PowerPoint too, but an R Markdown PowerPoint deck can't show
#' gt tables, so use [phw_flextable()] for slides.
#'
#' @param x A gt table.
#' @param font_size Body font size in pixels.
#' @param accent Colour of the title, column labels and rules.
#' @param stripe Shade alternate rows?
#' @param ... Passed to [gt::tab_options()], to change any other setting.
#' @return A gt table.
#' @examples
#' if (requireNamespace("gt", quietly = TRUE)) {
#'   phw_gt(head(mtcars[, 1:4]), caption = "Example table", source = "mtcars")
#'   phw_gt_theme(gt::gt(head(iris)))
#' }
#' @export
phw_gt_theme <- function(x, font_size = 14, accent = phw_colours[["navy"]], stripe = FALSE, ...) {
  rlang::check_installed("gt")
  col <- phw_colours
  x <- gt::opt_table_font(x, font = c(phw_font(), "Arial", "sans-serif"))
  args <- list(
    table.font.size = gt::px(font_size),
    table.font.color = col[["text"]],
    table.border.top.color = accent,
    table.border.top.width = gt::px(2),
    table.border.bottom.color = accent,
    table.border.bottom.width = gt::px(2),
    heading.align = "left",
    heading.title.font.size = gt::px(font_size + 3),
    heading.title.font.weight = "bold",
    heading.subtitle.font.size = gt::px(font_size),
    heading.border.bottom.color = "transparent",
    column_labels.font.weight = "bold",
    column_labels.border.top.color = accent,
    column_labels.border.bottom.color = accent,
    column_labels.border.bottom.width = gt::px(2),
    row_group.font.weight = "bold",
    row_group.border.top.color = accent,
    row_group.border.bottom.color = col[["grey_border"]],
    row_group.background.color = col[["grey_bg"]],
    table_body.hlines.color = col[["grey_border"]],
    table_body.border.bottom.color = accent,
    grand_summary_row.border.color = accent,
    summary_row.border.color = col[["grey_border"]],
    source_notes.font.size = gt::px(font_size - 2),
    footnotes.font.size = gt::px(font_size - 2),
    row.striping.include_table_body = stripe,
    row.striping.background_color = col[["grey_bg"]],
    data_row.padding = gt::px(5)
  )
  dots <- list(...)
  args[names(dots)] <- dots
  x <- do.call(gt::tab_options, c(list(x), args))
  x <- gt::tab_style(x, gt::cell_text(color = accent),
                     locations = list(gt::cells_title(), gt::cells_stubhead(), gt::cells_column_labels(),
                                      gt::cells_column_spanners(), gt::cells_row_groups()))
  x <- gt::tab_style(x, gt::cell_text(weight = "bold"), locations = gt::cells_title("title"))
  # gt's Word writer reads cell styles, not tab_options(), so the spanner and
  # row group settings are repeated as styles.
  x <- gt::tab_style(x, gt::cell_text(weight = args$column_labels.font.weight),
                     locations = gt::cells_column_spanners())
  x <- gt::tab_style(x, list(gt::cell_text(weight = args$row_group.font.weight),
                             gt::cell_fill(args$row_group.background.color)),
                     locations = gt::cells_row_groups())
  if (!inherits(x, "phw_gt")) class(x) <- c("phw_gt", class(x))
  x
}

# Notes about gt in a format are for the author, so they go straight to the
# console: knitr writes any message condition raised while printing into the
# document.
gt_format_note <- function(msg, id) {
  withCallingHandlers(
    cli::cli_inform(msg, .frequency = "once", .frequency_id = id),
    message = function(m) {
      cat(conditionMessage(m), "\n", sep = "", file = stderr())
      invokeRestart("muffleMessage")
    }
  )
}

# gt's Word writer ignores the table font and takes a single font name, not
# the CSS list phw_gt_theme() sets, so the PHW font goes on every cell for Word.
# It cannot bold column labels or indent cells.
#' @exportS3Method knitr::knit_print
knit_print.phw_gt <- function(x, ...) {
  if (knitr::pandoc_to("docx")) {
    gt_format_note(c("gt tables in Word lose some PHW styling: column labels are not bold and the levels of a summary table are not indented.",
                     i = "Use {.fn phw_flextable} for tables in Word documents."), "phw_gt_word")
    x <- gt::tab_style(x, gt::cell_text(font = phw_font()), locations = list(
      gt::cells_title(), gt::cells_stubhead(), gt::cells_column_spanners(), gt::cells_column_labels(),
      gt::cells_row_groups(), gt::cells_stub(), gt::cells_body(), gt::cells_footnotes(),
      gt::cells_source_notes()
    ))
    return(knitr::asis_output(paste("```{=openxml}", gt_word_xml(x), "```\n\n", sep = "\n")))
  }
  if (is.null(knitr::pandoc_to()) || knitr::is_html_output()) return(NextMethod())
  if (!knitr::is_latex_output()) {
    # gt writes HTML here, which Quarto turns into a table for Typst and
    # PowerPoint. The web font is an HTML dependency, which pandoc formats
    # other than HTML refuse.
    if (knitr::pandoc_to("pptx") && is.null(knitr::opts_knit$get("quarto.version"))) {
      gt_format_note(c("gt tables don't show on R Markdown PowerPoint slides.",
                       i = "Use {.fn phw_flextable} for tables on slides."), "phw_gt_pptx")
    }
    class(x) <- setdiff(class(x), "phw_gt")
    return(NextMethod())
  }
  # From gt 0.11.1 a LaTeX table is a float, which can't break across pages,
  # so it is set as a longtable, as it was before. gt repeats the header on
  # each page from 1.1.0; before that, \endhead goes after the header's rule.
  opts <- intersect(c("latex.use_longtable", "latex.header_repeat"), names(formals(gt::tab_options)))
  x <- do.call(gt::tab_options, c(list(x), stats::setNames(as.list(rep(TRUE, length(opts))), opts)))
  out <- NextMethod()
  if (!"latex.header_repeat" %in% opts) out[] <- sub("\\midrule", "\\midrule\\endhead", out, fixed = TRUE)
  out[] <- fit_gt_latex(out)
  out
}

# A longtable can't be shrunk as a whole, so LaTeX measures the table at its
# natural width and, when that is wider than the text, sets it in a smaller
# font with narrower column gaps.
fit_gt_latex <- function(tex) {
  re <- paste0("(?s)\\\\begin\\{longtable\\}\\{([^\n]*)\\}\n(\\\\caption\\*\\{\n.*?\n\\} \\\\\\\\ \n)?",
               "(.*?)\\\\end\\{longtable\\}\n")
  m <- regmatches(tex, regexec(re, tex, perl = TRUE))[[1]]
  if (!length(m)) return(tex)
  body <- sub("\\endhead", "", m[4], fixed = TRUE)
  scale <- "*\\linewidth/\\wd0\\relax"
  fit <- paste0("\\sbox0{\\begin{tabular}{", m[2], "}\n", body, "\\end{tabular}}\n",
                "\\ifdim\\wd0>\\linewidth\n",
                "\\fontsize{\\dimexpr\\csname f@size\\endcsname pt", scale, "}",
                "{\\dimexpr\\baselineskip", scale, "}\\selectfont\n",
                "\\setlength{\\tabcolsep}{\\dimexpr\\tabcolsep", scale, "}\n",
                "\\fi\n",
                "\\setlength{\\LTleft}{0pt plus 1fil}\n\\setlength{\\LTright}{0pt plus 1fil}\n",
                "\\begin{longtable}{@{\\extracolsep{\\fill}}", m[2], "}\n")
  start <- paste0("\\begin{longtable}{", m[2], "}\n")
  paste0("\\begingroup\n", sub(start, fit, tex, fixed = TRUE), "\\endgroup\n")
}

# gt's Word caption starts with its own "Table n: " field, and phw_gt() puts
# any number in the title itself, so the field is turned off: with `autonum`
# from gt 1.1.0, and by removing it from the XML before that.
gt_word_xml <- function(x) {
  if ("autonum" %in% names(formals(gt::as_word))) return(gt::as_word(x, autonum = FALSE))
  run <- "<w:r>(?:(?!</w:r>).)*?<w:t[^>]*>%s</w:t>\\s*</w:r>\\s*"
  field <- paste0(sprintf(run, "Table "), "<w:r>\\s*<w:fldChar w:fldCharType=\"begin\"[^>]*/>\\s*</w:r>\\s*",
                  "<w:r>\\s*<w:instrText[^>]*> SEQ Table .*?w:fldCharType=\"end\"[^>]*/>\\s*</w:r>\\s*",
                  sprintf(run, ": "))
  sub(paste0("(?s)", field), "", gt::as_word(x), perl = TRUE)
}

# gt builds its HTML in as.tags(), which drops any dependency attached to the
# table, so the Ubuntu web font goes on there.
#' @exportS3Method htmltools::as.tags
as.tags.phw_gt <- function(x, ...) {
  htmltools::attachDependencies(NextMethod(), phw_font_dependency(), append = TRUE)
}

#' @rdname phw_gt_theme
#' @param data A data frame, or a summary table from [phw_summary_table()],
#'   [phw_crosstab()], [phw_rate_table()], [phw_risk_table()] or
#'   [phw_group_table()]. Summary tables get bold group rows, indented
#'   levels and header spanners, as in [phw_flextable()].
#' @param caption Table title.
#' @param subtitle Optional subtitle.
#' @param number Optional table number, giving "Table 1 ...".
#' @param number_prefix Word before the number.
#' @param source,date Passed to [phw_caption()] and shown under the table.
#' @param caption_args List of other [phw_caption()] arguments.
#' @param digits Decimal places for non-integer numbers. Defaults to the
#'   `digits` of a [phw_group_table()], or 1.
#'   Whole numbers show with a thousands separator, except in a year
#'   column: whole numbers from 1800 to 2200 in a column whose name has the
#'   word "year", "yr" or "blwyddyn" in it, such as `Year`, `year_of_onset`
#'   or `Blwyddyn`. These show as 2021, not 2,021.
#' @param gt_args List of arguments for [gt::gt()], e.g.
#'   `list(groupname_col = "region")`. On a summary table, `rowname_col`
#'   takes a column name as it prints, such as `"Characteristic"`, and
#'   `groupname_col` is not allowed.
#' @param theme_args List of arguments for `phw_gt_theme()`.
#' @export
phw_gt <- function(data, caption = NULL, subtitle = NULL, number = NULL, source = NULL, date = NULL,
                   digits = 1, number_prefix = "Table", caption_args = list(), gt_args = list(),
                   theme_args = list()) {
  rlang::check_installed("gt")
  data <- check_table_data(data)
  data <- blank_non_finite(data)
  if (missing(digits)) digits <- attr(data, "digits") %||% digits
  is_sum <- inherits(data, "phw_summary")
  df <- as.data.frame(unclass(data)[names(data)], check.names = FALSE)
  years <- year_cols(df)
  if (is_sum) {
    nl <- attr(data, "label_cols") %||% 1L
    labels <- stats::setNames(as.list(c(names(df)[seq_len(nl)], summary_header(data, nl)$bottom)), names(df))
    check_summary_gt_args(gt_args, names(df))
  }
  x <- do.call(gt::gt, c(list(df), gt_args))
  num <- names(df)[vapply(df, is.numeric, logical(1))]
  is_int <- vapply(df[num], is_whole, logical(1))
  is_year <- num %in% names(df)[years]
  if (any(is_year)) x <- gt::fmt_integer(x, columns = gt_cols(num[is_year]), use_seps = FALSE)
  if (any(is_int & !is_year)) x <- gt::fmt_integer(x, columns = gt_cols(num[is_int & !is_year]))
  if (any(!is_int)) x <- gt::fmt_number(x, columns = gt_cols(num[!is_int]), decimals = digits)
  text <- setdiff(names(df), num)
  if (length(text)) x <- gt::cols_align(x, "left", columns = gt_cols(text))
  x <- gt::sub_missing(x, missing_text = "")
  if (is_sum) x <- style_summary_gt(x, data, names(df), labels, stub = gt_args$rowname_col)
  if (!is.null(caption) || !is.null(subtitle)) {
    title <- if (is.null(number) || is.null(caption)) caption else paste(number_prefix, number, caption)
    x <- gt::tab_header(x, title = title %||% "", subtitle = subtitle)
  }
  x <- do.call(phw_gt_theme, c(list(x), theme_args))
  cap <- caption_from(source, date, caption_args)
  if (!is.null(cap)) {
    for (line in strsplit(cap, "\n", fixed = TRUE)[[1]]) x <- gt::tab_source_note(x, line)
    x <- gt::tab_style(x, gt::cell_text(weight = "bold", align = "right"), locations = gt::cells_source_notes())
  }
  x
}

# A summary table's label columns hold a group's name on its first row only,
# so gt would put the other rows under a blank heading: `groupname_col`
# stops instead.
check_summary_gt_args <- function(gt_args, cols, call = rlang::caller_env()) {
  if (!is.null(gt_args$groupname_col)) {
    cli::cli_abort(c("{.code gt_args$groupname_col} does not work on a summary table.",
                     i = "Use gt row groups on a data frame, not on a summary table."), call = call)
  }
  v <- gt_args$rowname_col
  if (is.null(v)) return(invisible())
  bad <- if (is.character(v)) setdiff(v, cols) else v
  if (length(bad)) {
    cli::cli_abort(c("{.code gt_args$rowname_col} must name a column of the table.",
                     x = "{cli::qty(length(bad))}No column{?s} called {.val {bad}}.",
                     i = "The columns are {.val {cols}}."), call = call)
  }
  invisible()
}

# Column names for gt's `columns` arguments. gt only re-exports all_of()
# from version 0.11.1, and a function call that returns the names selects
# the same columns on every version.
gt_cols <- function(x) x

# A column given as gt's `rowname_col` becomes the stub, which cells_body()
# and cols_label() leave alone.
style_summary_gt <- function(x, s, ids, labels, stub = NULL) {
  r <- summary_rows(s)
  nl <- attr(s, "label_cols") %||% 1L
  col <- phw_colours
  lab_ids <- ids[seq_len(nl)]
  data_ids <- ids[-seq_len(nl)]
  x <- gt::cols_label(x, .list = labels)
  if (length(stub)) x <- gt::tab_stubhead(x, labels[[stub]])
  x <- gt::cols_align(x, "left", columns = gt_cols(lab_ids))
  if (length(data_ids)) x <- gt::cols_align(x, "right", columns = gt_cols(data_ids))
  rows_where <- function(x, rows, style, columns = ids) {
    if (!any(rows)) return(x)
    body <- setdiff(columns, stub)
    loc <- if (length(body)) list(gt::cells_body(columns = gt_cols(body), rows = which(rows)))
    if (any(stub %in% columns)) loc <- c(loc, list(gt::cells_stub(rows = which(rows))))
    gt::tab_style(x, style, loc)
  }
  x <- rows_where(x, r$bold, gt::cell_text(weight = "bold"))
  x <- rows_where(x, r$navy, gt::cell_text(color = col[["navy"]]), lab_ids)
  x <- rows_where(x, r$shade, gt::cell_fill(col[["grey_bg"]]))
  x <- rows_where(x, r$italic, gt::cell_text(style = "italic"), lab_ids)
  for (d in setdiff(unique(r$indent), 0)) {
    x <- rows_where(x, r$indent == d, gt::cell_text(indent = gt::px(14 * d)), lab_ids[1])
  }
  x <- rows_where(x, r$rule, gt::cell_borders(sides = "top", color = col[["navy"]], weight = gt::px(2)))
  x <- rows_where(x, r$line, gt::cell_borders(sides = "top", color = col[["grey_mid"]], weight = gt::px(1)))
  x <- rows_where(x, r$space, "padding-top: 14px;")
  hd <- summary_header(s, nl)
  multi <- !is.null(attr(s, "col_header"))
  L <- length(hd$upper)
  for (l in seq_len(L)) {
    level <- hd$upper[[l]]
    # A column moved inside a spanner splits it, so a spanner's id is its
    # label made unique. gt also refuses a spanner id that is a column name.
    sp_ids <- if (multi) paste0("sp", l, "_", seq_len(nrow(level))) else level$label
    sp_ids <- make.unique(c(ids, sp_ids))[-seq_along(ids)]
    for (g in which(!level$total & nzchar(level$label))) {
      columns <- gt_cols(data_ids[level$start[g] + seq_len(level$n[g]) - 1])
      x <- gt::tab_spanner(x, label = level$label[g], columns = columns, level = L + 1 - l, id = sp_ids[g])
    }
  }
  note <- attr(s, "note")
  if (!is.null(note)) x <- gt::tab_footnote(x, note)
  x
}

#' PHW theme for gtsummary
#'
#' Sets a [gtsummary](https://www.danieldsjoberg.com/gtsummary/) theme so
#' every gtsummary table (`tbl_summary()`, `tbl_regression()`,
#' `tbl_cross()`...) uses the PHW style when printed with gt or converted
#' with `as_flex_table()`. Call it once at the start of a script or in your
#' setup chunk.
#'
#' @param style Passed to [phw_flextable_theme()] for flextable output.
#' @param font_size Body font size (points for flextable, pixels for gt).
#' @param ... Other gtsummary theme elements, e.g.
#'   `"tbl_summary-str:default_con_type" = "continuous2"`.
#' @return The theme list, invisibly (it is also applied).
#' @examples
#' if (requireNamespace("gtsummary", quietly = TRUE)) {
#'   use_phw_gtsummary()
#'   gtsummary::reset_gtsummary_theme()
#' }
#' @export
use_phw_gtsummary <- function(style = "booktabs", font_size = 10, ...) {
  rlang::check_installed(c("gtsummary", "gt"))
  style <- rlang::arg_match(style, c("booktabs", "header", "light", "zebra"))
  force(font_size)
  theme <- c(
    list(
      "pkgwide-str:theme_name" = "PHW",
      "as_gt-lst:addl_cmds" = list(
        cols_hide = rlang::expr(phwstyle::phw_gt_theme(font_size = !!(font_size + 4)))
      ),
      "as_flex_table-lst:addl_cmds" = list(
        valign = list(rlang::expr(phwstyle::phw_flextable_theme(style = !!style, font_size = !!font_size, padding = NULL, align = FALSE)))
      )
    ),
    list(...)
  )
  suppressMessages(gtsummary::set_gtsummary_theme(theme))
  invisible(theme)
}
