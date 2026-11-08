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
  x <- gt::tab_options(
    x,
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
    data_row.padding = gt::px(5),
    ...
  )
  x <- gt::tab_style(x, gt::cell_text(color = accent),
                     locations = list(gt::cells_title(), gt::cells_column_labels(), gt::cells_column_spanners(),
                                      gt::cells_row_groups()))
  x <- gt::tab_style(x, gt::cell_text(weight = "bold"), locations = gt::cells_title("title"))
  x
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
#' @param digits Decimal places for non-integer numbers.
#' @param gt_args List of arguments for [gt::gt()], e.g.
#'   `list(groupname_col = "region")`.
#' @param theme_args List of arguments for `phw_gt_theme()`.
#' @export
phw_gt <- function(data, caption = NULL, subtitle = NULL, number = NULL, source = NULL, date = NULL,
                   digits = 1, number_prefix = "Table", caption_args = list(), gt_args = list(),
                   theme_args = list()) {
  rlang::check_installed("gt")
  is_sum <- inherits(data, "phw_summary")
  df <- as.data.frame(unclass(data)[names(data)], check.names = FALSE)
  if (is_sum) {
    ch <- attr(data, "col_header")
    nl <- attr(data, "label_cols") %||% 1L
    # gt needs unique, syntactic-enough ids; keep display names as labels.
    ids <- paste0("c", seq_along(df))
    labels <- stats::setNames(as.list(names(df)), ids)
    if (!is.null(ch)) labels[ids[-seq_len(nl)]] <- as.list(ch[nrow(ch), ])
    names(df) <- ids
  }
  x <- do.call(gt::gt, c(list(df), gt_args))
  num <- names(df)[vapply(df, is.numeric, logical(1))]
  is_int <- vapply(df[num], function(v) all(v == round(v), na.rm = TRUE), logical(1))
  if (any(is_int)) x <- gt::fmt_integer(x, columns = gt::all_of(num[is_int]))
  if (any(!is_int)) x <- gt::fmt_number(x, columns = gt::all_of(num[!is_int]), decimals = digits)
  x <- gt::sub_missing(x, missing_text = "")
  if (is_sum) x <- style_summary_gt(x, data, ids, labels)
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

style_summary_gt <- function(x, s, ids, labels) {
  types <- attr(s, "row_type")
  depth <- attr(s, "depth") %||% as.integer(types == "level")
  nl <- attr(s, "label_cols") %||% 1L
  indent <- attr(s, "indent") %||% TRUE
  col <- phw_colours
  lab_ids <- ids[seq_len(nl)]
  data_ids <- ids[-seq_len(nl)]
  x <- gt::cols_label(x, .list = labels)
  x <- gt::cols_align(x, "left", columns = gt::all_of(lab_ids))
  if (length(data_ids)) x <- gt::cols_align(x, "right", columns = gt::all_of(data_ids))
  bold <- which(types %in% c("variable", "total", "subtotal"))
  if (length(bold)) x <- gt::tab_style(x, gt::cell_text(weight = "bold"), gt::cells_body(rows = bold))
  top <- which(types == "variable" & depth == 0)
  if (length(top)) {
    x <- gt::tab_style(x, gt::cell_text(color = col[["navy"]]), gt::cells_body(columns = gt::all_of(lab_ids), rows = top))
    if (isTRUE(attr(s, "highlight") %||% TRUE)) x <- gt::tab_style(x, gt::cell_fill(col[["grey_bg"]]), gt::cells_body(rows = top))
  }
  if (indent) {
    for (d in setdiff(unique(depth), 0)) {
      x <- gt::tab_style(x, gt::cell_text(indent = gt::px(14 * d)),
                         gt::cells_body(columns = gt::all_of(lab_ids[1]), rows = which(depth == d)))
    }
  }
  tot <- which(types == "total")
  if (length(tot)) x <- gt::tab_style(x, gt::cell_borders(sides = "top", color = col[["navy"]], weight = gt::px(2)),
                                      gt::cells_body(rows = tot))
  starts <- attr(s, "group_start") %||% integer()
  sep <- attr(s, "separate") %||% "none"
  starts <- setdiff(starts, tot)
  if (length(starts) && sep %in% c("line", "both")) {
    x <- gt::tab_style(x, gt::cell_borders(sides = "top", color = col[["grey_mid"]], weight = gt::px(1)),
                       gt::cells_body(rows = starts))
  }
  if (length(starts) && sep %in% c("space", "both")) {
    x <- gt::tab_style(x, "padding-top: 14px;", gt::cells_body(rows = starts))
  }
  ch <- attr(s, "col_header")
  sp <- attr(s, "spanner")
  if (!is.null(ch) && nrow(ch) > 1) {
    for (l in seq_len(nrow(ch) - 1)) {
      key <- apply(ch[seq_len(l), , drop = FALSE], 2, paste, collapse = "\r")
      r <- rle(key)
      ends <- cumsum(r$lengths)
      for (g in seq_along(ends)) {
        idx <- (ends[g] - r$lengths[g] + 1):ends[g]
        lab <- ch[l, idx[1]]
        if (all(ch[, idx] == ch[nrow(ch), idx[1]])) next
        x <- gt::tab_spanner(x, label = lab, columns = gt::all_of(data_ids[idx]), level = nrow(ch) - l,
                             id = paste0("sp", l, "_", g))
      }
    }
  } else if (!is.null(sp) && length(data_ids)) {
    x <- gt::tab_spanner(x, label = sp, columns = gt::all_of(data_ids))
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
  force(style); force(font_size)
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
