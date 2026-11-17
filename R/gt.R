#' PHW style for gt tables
#'
#' `phw_gt_theme()` restyles an existing [gt::gt()] table: PHW font, navy
#' title and column labels with a navy rule, light row lines and a bold
#' source note. `phw_gt()` builds the table from a data frame (or a
#' [phw_summary_table()] and friends) and adds the title, number formats
#' and source line in one call.
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
  if (!inherits(x, "phw_gt")) class(x) <- c("phw_gt", class(x))
  x
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
    # gt needs unique, syntactic-enough ids; keep display names as labels.
    ids <- paste0("c", seq_along(df))
    labels <- stats::setNames(as.list(c(names(df)[seq_len(nl)], summary_header(data, nl)$bottom)), ids)
    gt_args <- gt_args_to_ids(gt_args, names(df), ids)
    names(df) <- ids
  }
  x <- do.call(gt::gt, c(list(df), gt_args))
  num <- names(df)[vapply(df, is.numeric, logical(1))]
  is_int <- vapply(df[num], function(v) all(v == round(v), na.rm = TRUE), logical(1))
  is_year <- num %in% names(df)[years]
  if (any(is_year)) x <- gt::fmt_integer(x, columns = gt_cols(num[is_year]), use_seps = FALSE)
  if (any(is_int & !is_year)) x <- gt::fmt_integer(x, columns = gt_cols(num[is_int & !is_year]))
  if (any(!is_int)) x <- gt::fmt_number(x, columns = gt_cols(num[!is_int]), decimals = digits)
  dates <- names(df)[vapply(df, inherits, logical(1), c("Date", "POSIXt"))]
  if (length(dates)) x <- gt::cols_align(x, "left", columns = gt_cols(dates))
  x <- gt::sub_missing(x, missing_text = "")
  if (is_sum) x <- style_summary_gt(x, data, ids, labels, stub = gt_args$rowname_col)
  if (!is.null(caption) || !is.null(subtitle)) {
    title <- if (is.null(number) || is.null(caption)) caption else paste(number_prefix, number, caption)
    x <- gt::tab_header(x, title = title %||% "", subtitle = subtitle)
  }
  x <- do.call(phw_gt_theme, c(list(x), theme_args))
  cap <- caption_from(source, date, caption_args)
  if (!is.null(cap)) {
    x <- gt::tab_source_note(x, gt::html(gsub("\n", "<br>", htmltools::htmlEscape(cap))))
    x <- gt::tab_style(x, gt::cell_text(weight = "bold", align = "right"), locations = gt::cells_source_notes())
  }
  x
}

# A summary table reaches gt::gt() with ids for column names, so the name
# given as gt's `rowname_col` becomes an id too. A summary table's label
# columns hold a group's name on its first row only, so gt would put the
# other rows under a blank heading: `groupname_col` stops instead.
gt_args_to_ids <- function(gt_args, cols, ids, call = rlang::caller_env()) {
  if (!is.null(gt_args$groupname_col)) {
    cli::cli_abort(c("{.code gt_args$groupname_col} does not work on a summary table.",
                     i = "Use gt row groups on a data frame, not on a summary table."), call = call)
  }
  v <- gt_args$rowname_col
  if (is.null(v)) return(gt_args)
  bad <- if (is.character(v)) setdiff(v, cols) else v
  if (length(bad)) {
    cli::cli_abort(c("{.code gt_args$rowname_col} must name a column of the table.",
                     x = "{cli::qty(length(bad))}No column{?s} called {.val {bad}}.",
                     i = "The columns are {.val {cols}}."), call = call)
  }
  gt_args$rowname_col <- ids[match(v, cols)]
  gt_args
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
    # label made unique.
    sp_ids <- if (multi) paste0("sp", l, "_", seq_len(nrow(level))) else make.unique(level$label)
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
