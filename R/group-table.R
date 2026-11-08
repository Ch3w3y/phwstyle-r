#' Grouped table with nested row and column groups
#'
#' Turns a raw data frame (one row per record, or with a value column) into
#' a table with a hierarchy of row groups and, optionally, of column
#' groups. For example, counts by group (A, B, C) and then by type within each
#' group (1, 2, 3), split into columns by year. Each group
#' row can carry the total for its group, and you can add a total for the
#' whole table and totals of the innermost groups across all groups.
#' Render it with [phw_flextable()] or [phw_reactable()]: main groups are
#' highlighted and separated with space or a rule, and the groups inside
#' them are indented, or shifted into their own column with
#' `layout = "columns"`.
#'
#' @param data A data frame.
#' @param rows Row grouping columns, outermost first, e.g.
#'   `c("group", "type")`. Any number of levels.
#' @param cols Optional column grouping columns, outermost first, e.g.
#'   `"year"` or `c("year", "quarter")`. Outer levels become headers
#'   spanning their columns.
#' @param value Optional numeric column to summarise. Without it, rows are
#'   counted.
#' @param fun Function applied to `value` within each cell. Defaults to
#'   `sum` (so `value` can hold counts of aggregated data). Use e.g.
#'   `function(x) median(x, na.rm = TRUE)` for other statistics; group and
#'   total rows are then computed from the records in the group, not by
#'   adding up the rows below.
#' @param totals Which row totals to show. Any of:
#'   * `"group"`: each group row shows the total for its group (e.g. Group A
#'     shows the total for all of group A), at every level that has groups inside.
#'   * `"subgroup"`: a block with each innermost category summed across all
#'     groups (e.g. all Type 1, all Type 2, all Type 3).
#'   * `"table"`: one total row for the whole table.
#'
#'   Use `character()` or `"none"` for no totals.
#' @param total_position Put the table total and the subgroup block at the
#'   `"bottom"` or the `"top"` of the table.
#' @param subtotal_position Show group totals on the group's own heading
#'   row (`"header"`), or leave the heading blank and add a total row after
#'   the group (`"below"`).
#' @param col_totals Which column totals to show when `cols` is given: any
#'   of `"table"` (one total column) and `"group"` (a total column for each
#'   outermost column group, when `cols` has two or more levels).
#' @param percent Add percentages to the counts: `"parent"` (share of the
#'   group above, e.g. Type 1 as a share of all of Group A),
#'   `"column"` (share of the column total), `"row"` (share of the row
#'   total) or `"none"`. Only for counts and sums.
#' @param layout `"indent"` puts all row labels in one column, indented by
#'   level. `"columns"` gives each level its own column, so each group's
#'   label sits in its own column and the groups inside it are shifted to
#'   the right.
#' @param separate How to separate the outermost groups: `"space"`,
#'   `"line"`, `"both"` or `"none"`.
#' @param highlight Shade the outermost group rows?
#' @param labels Named list of display names for the grouping columns.
#' @param value_label Heading for the value column when there is no `cols`.
#' @param label_header Heading of the label column in the `"indent"` layout.
#'   Defaults to the row variable labels joined with " / ".
#' @param total_label Label for total rows and columns.
#' @param subtotal_label Label for group totals below the group, with
#'   `{group}` replaced by the group name.
#' @param missing Label for missing grouping values, or `NULL` to drop them.
#' @param drop Leave out categories that have no records in a group?
#' @param digits Decimal places for percentages and non-integer values.
#' @return A `phw_summary` data frame. Without `percent`, value columns are
#'   numeric (blank group rows are `NA`).
#' @examples
#' set.seed(1)
#' dat <- data.frame(
#'   group = sample(c("Group A", "Group B", "Group C"), 300, TRUE),
#'   type = sample(c("Type 1", "Type 2", "Type 3"), 300, TRUE, prob = c(.45, .45, .1)),
#'   year = sample(2023:2024, 300, TRUE)
#' )
#' phw_group_table(dat, rows = c("group", "type"), cols = "year",
#'                 labels = list(group = "Group", type = "Type", year = "Year"))
#'
#' # Group totals in their own row, and totals by type across all groups
#' phw_group_table(dat, c("group", "type"), totals = c("group", "subgroup", "table"),
#'                 subtotal_position = "below", layout = "columns")
#'
#' if (requireNamespace("flextable", quietly = TRUE)) {
#'   phw_flextable(phw_group_table(dat, c("group", "type"), "year", percent = "parent"))
#' }
#' @export
phw_group_table <- function(data, rows, cols = NULL, value = NULL, fun = sum,
                            totals = c("group", "table"),
                            total_position = c("bottom", "top"),
                            subtotal_position = c("header", "below"),
                            col_totals = "table",
                            percent = c("none", "parent", "column", "row"),
                            layout = c("indent", "columns"),
                            separate = c("space", "line", "both", "none"),
                            highlight = TRUE, labels = list(), value_label = NULL,
                            label_header = NULL, total_label = "Total",
                            subtotal_label = "{group} total", missing = "Unknown",
                            drop = TRUE, digits = 1) {
  total_position <- rlang::arg_match(total_position)
  subtotal_position <- rlang::arg_match(subtotal_position)
  percent <- rlang::arg_match(percent)
  layout <- rlang::arg_match(layout)
  separate <- rlang::arg_match(separate)
  totals <- setdiff(totals, "none")
  bad <- setdiff(totals, c("group", "subgroup", "table"))
  if (length(bad)) cli::cli_abort("{.arg totals} must be any of {.val group}, {.val subgroup} and {.val table}, not {.val {bad}}.")
  bad <- setdiff(col_totals, c("table", "group", "none"))
  if (length(bad)) cli::cli_abort("{.arg col_totals} must be any of {.val table} and {.val group}, not {.val {bad}}.")
  fun <- rlang::as_function(fun)
  data <- as.data.frame(data)
  miss <- setdiff(c(rows, cols, value), names(data))
  if (length(miss)) cli::cli_abort("Column{?s} {.val {miss}} not found in {.arg data}.")
  if (!length(rows)) cli::cli_abort("{.arg rows} needs at least one column.")
  x <- if (is.null(value)) rep(1, nrow(data)) else data[[value]]
  if (!is.numeric(x)) cli::cli_abort("{.arg value} must be a numeric column.")

  # Missing grouping values: relabel, or drop the records.
  grp <- lapply(c(rows, cols), function(v) as_levels(data[[v]], missing))
  names(grp) <- c(rows, cols)
  keep <- Reduce(`&`, lapply(grp, function(g) !is.na(g)), rep(TRUE, nrow(data)))
  grp <- lapply(grp, function(g) droplevels(g[keep]))
  x <- x[keep]
  n <- length(x)
  all_rows <- rep(TRUE, n)
  cell <- function(idx) {
    v <- fun(x[idx])
    if (length(v) != 1) cli::cli_abort("{.arg fun} must return a single value.")
    as.numeric(v)
  }

  # ---- Columns ---------------------------------------------------------
  col_masks <- list(); col_head <- list()
  if (is.null(cols)) {
    col_masks[[1]] <- all_rows
    col_head[[1]] <- value_label %||% if (is.null(value)) "n" else var_label(data, value, labels)
  } else {
    cg <- grp[cols]
    combos <- unique(as.data.frame(cg))
    if (!drop) combos <- expand.grid(lapply(cg, levels), stringsAsFactors = FALSE)
    combos <- as.data.frame(lapply(seq_along(cols), function(i) factor(combos[[i]], levels(cg[[i]]))),
                            col.names = cols)
    combos <- combos[do.call(order, unname(as.list(combos))), , drop = FALSE]
    match_combo <- function(r) {
      Reduce(`&`, lapply(seq_along(cols), function(i) cg[[i]] == as.character(combos[r, i])))
    }
    tops <- unique(as.character(combos[[1]]))
    for (t in tops) {
      for (r in which(as.character(combos[[1]]) == t)) {
        col_masks[[length(col_masks) + 1]] <- match_combo(r)
        col_head[[length(col_head) + 1]] <- vapply(combos[r, ], as.character, "")
      }
      if ("group" %in% col_totals && length(cols) > 1) {
        col_masks[[length(col_masks) + 1]] <- cg[[1]] == t
        col_head[[length(col_head) + 1]] <- c(t, rep(total_label, length(cols) - 1))
      }
    }
    if ("table" %in% col_totals) {
      col_masks[[length(col_masks) + 1]] <- all_rows
      col_head[[length(col_head) + 1]] <- rep(total_label, length(cols))
    }
  }
  col_header <- matrix(unlist(lapply(col_head, unname)), ncol = length(col_head))
  col_names <- make.unique(apply(col_header, 2, paste, collapse = " / "))
  # Column used as the row total for percent = "row".
  row_total_col <- if (is.null(cols)) 1L else if ("table" %in% col_totals) length(col_masks) else NA_integer_
  if (percent == "row" && is.na(row_total_col)) {
    cli::cli_abort("{.code percent = \"row\"} needs a total column: keep {.val table} in {.arg col_totals}.")
  }

  # ---- Rows ------------------------------------------------------------
  k <- length(rows)
  out <- list()
  add <- function(label, depth, type, idx, parent, blank = FALSE) {
    out[[length(out) + 1]] <<- list(label = label, depth = depth, type = type,
                                    idx = idx, parent = parent, blank = blank)
  }
  levels_in <- function(g, idx) {
    if (drop) levels(g)[levels(g) %in% as.character(g[idx])] else levels(g)
  }
  walk <- function(idx, d) {
    g <- grp[[rows[d]]]
    for (lv in levels_in(g, idx)) {
      sub <- idx & g == lv
      if (d == k) {
        add(lv, d - 1, "level", sub, idx)
      } else {
        on_header <- "group" %in% totals && subtotal_position == "header"
        add(lv, d - 1, "variable", sub, idx, blank = !on_header)
        walk(sub, d + 1)
        if ("group" %in% totals && subtotal_position == "below") {
          add(gsub("{group}", lv, subtotal_label, fixed = TRUE), d - 1, "subtotal", sub, idx)
        }
      }
    }
  }
  walk(all_rows, 1)
  body <- out; out <- list()
  if ("subgroup" %in% totals && k > 1) {
    g <- grp[[rows[k]]]
    add(paste(total_label, "by", tolower(var_label(data, rows[k], labels))), 0, "variable",
        all_rows, all_rows, blank = TRUE)
    for (lv in levels_in(g, all_rows)) add(lv, 1, "level", g == lv, all_rows)
  }
  if ("table" %in% totals) add(total_label, 0, "total", all_rows, all_rows)
  extra <- out
  rows_out <- if (total_position == "top") {
    # The table total first, then the subgroup block, then the groups.
    c(Filter(function(r) r$type == "total", extra),
      Filter(function(r) r$type != "total", extra), body)
  } else {
    c(body, extra)
  }

  # ---- Values ----------------------------------------------------------
  nc <- length(col_masks)
  vals <- matrix(NA_real_, length(rows_out), nc)
  dens <- matrix(NA_real_, length(rows_out), nc)
  col_tot <- vapply(col_masks, cell, 0)
  for (i in seq_along(rows_out)) {
    r <- rows_out[[i]]
    if (r$blank) next
    for (j in seq_len(nc)) {
      vals[i, j] <- cell(r$idx & col_masks[[j]])
      dens[i, j] <- switch(percent,
        parent = cell(r$parent & col_masks[[j]]),
        column = col_tot[j],
        row = cell(r$idx & col_masks[[row_total_col]]),
        none = NA_real_)
    }
  }
  vals[is.nan(vals)] <- NA
  body_df <- if (percent == "none") {
    as.data.frame(vals)
  } else {
    is_whole <- all(vals == round(vals), na.rm = TRUE)
    fmt <- matrix(ifelse(is.na(vals), "",
                         ifelse(dens > 0,
                                sprintf("%s (%s%%)", if (is_whole) fmt_n(vals) else fmt_num(vals, digits),
                                        fmt_num(100 * vals / dens, digits)),
                                fmt_n(vals))),
                  nrow(vals))
    as.data.frame(fmt, stringsAsFactors = FALSE)
  }
  names(body_df) <- col_names

  # ---- Labels ----------------------------------------------------------
  depth <- vapply(rows_out, `[[`, 0, "depth")
  types <- vapply(rows_out, `[[`, "", "type")
  lab <- vapply(rows_out, `[[`, "", "label")
  row_labels <- vapply(rows, function(v) var_label(data, v, labels), "")
  if (layout == "indent") {
    lab_df <- stats::setNames(data.frame(lab, stringsAsFactors = FALSE),
                              label_header %||% paste(row_labels, collapse = " / "))
    n_label <- 1L
  } else {
    m <- matrix("", length(lab), k)
    m[cbind(seq_along(lab), pmin(depth + 1, k))] <- lab
    # Subtotal rows and the subgroup block sit under their group's column.
    lab_df <- stats::setNames(as.data.frame(m, stringsAsFactors = FALSE), make.unique(row_labels))
    n_label <- k
  }
  df <- cbind(lab_df, body_df)

  # Rows that start an outermost group (for spacing), skipping the first.
  starts <- setdiff(which(depth == 0 & types %in% c("variable", "total")), 1L)
  note <- switch(percent,
    parent = "n (% of the group above)", column = "n (% of column total)",
    row = "n (% of row total)", none = NULL)
  res <- new_phw_summary(df, types,
                         spanner = if (length(cols) == 1) var_label(data, cols, labels),
                         note = note)
  attr(res, "depth") <- depth
  attr(res, "label_cols") <- n_label
  attr(res, "indent") <- layout == "indent"
  attr(res, "group_start") <- if (separate == "none") integer() else starts
  attr(res, "separate") <- separate
  attr(res, "highlight") <- highlight
  if (length(cols) > 1) attr(res, "col_header") <- col_header
  res
}
