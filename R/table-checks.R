# Entry checks for the table renderers and the cell colouring helpers, on top
# of the shared ones in checks.R.

# A data frame with one name per column. A table() or a matrix stops here,
# since the renderers would each fail on it in their own way. A difftime,
# such as a length of stay, becomes a plain number in its own units so every
# renderer formats and aligns it as one; hms times of day keep their class.
# Labels kept in row names, as as.data.frame() gives for a matrix, become a
# first column with a blank header, as reactable shows them, so no renderer
# drops them. The row numbers of a plain or filtered data frame are not labels,
# even when rbind() of subsets stores them as text such as "31", nor are row
# names a column already holds. A column named NA, as a crosstab made with
# table(useNA = "ifany") has, is named "NA", as R prints it. Whole numbers such
# as years are labels.
check_table_data <- function(data, arg = "data", call = rlang::caller_env()) {
  data <- check_data_frame(data, as_data_frame_hint, arg, call)
  if (is.character(attr(data, "row.names"))) {
    labels <- row.names(data)
    row.names(data) <- NULL
    if (!is_row_numbers(labels) && !labels_in_column(data, labels)) {
      data <- data.frame(labels, data, check.names = FALSE, stringsAsFactors = FALSE)
      names(data)[1] <- " "
    }
  }
  for (j in which(vapply(data, function(v) inherits(v, "difftime") && !inherits(v, "hms"), logical(1)))) {
    data[[j]] <- as.numeric(data[[j]])
  }
  names(data)[is.na(names(data))] <- "NA"
  nms <- names(data)
  dup <- unique(nms[duplicated(nms)])
  if (length(dup)) {
    cli::cli_abort(c("{.arg {arg}} has more than one column named {.val {dup}}.",
                     i = "Give each column its own name."), call = call)
  }
  data
}

# rbind() stores row numbers as text only when subsets share some, and makes
# them unique as make.unique() does: "3" again becomes "31", then "32". So
# they always hold such a copy, and are either out of order or in order but
# ending in copies. Labels from table(), tapply() or a matrix, such as years,
# are sorted as numbers or as text, or are in reverse order with no copy. A
# run with no gap, such as weeks 1 to 12, is labels, and so is anything with
# a 0 or a leading zero, which row numbers never have.
is_row_numbers <- function(x) {
  if (!all(grepl("^[1-9][0-9]*$", x))) return(FALSE)
  copy <- c(FALSE, vapply(seq_along(x)[-1], function(i) {
    s <- x[seq_len(i - 1)]
    any(startsWith(x[i], s) & grepl("^[1-9]", substring(x[i], nchar(s) + 1)))
  }, logical(1)))
  if (!any(copy)) return(FALSE)
  n <- as.numeric(x)
  if (is.unsorted(n, strictly = TRUE)) return(is.unsorted(x, strictly = TRUE))
  !all(diff(n) == 1) && all(copy[which.max(copy):length(x)])
}

# data.frame(x = names(v), n = v) for a named tapply() or sapply() result
# repeats x in the row names, and rbind() of split data gives "<label>" or
# "<label>.<n>".
labels_in_column <- function(data, labels) {
  stem <- sub("\\.[0-9]+$", "", labels)
  any(vapply(data, function(v) {
    if (!is.atomic(v)) return(FALSE)
    v <- as.character(v)
    all((labels == v | stem == v) %in% TRUE)
  }, logical(1)))
}

# NaN and Inf show as blank cells, as NA does. Left to each renderer, they
# show as "Inf", an infinity sign, blank or an Excel error that breaks a SUM.
blank_non_finite <- function(data) {
  for (j in which(vapply(data, is.numeric, logical(1)))) {
    v <- data[[j]]
    bad <- is.nan(v) | is.infinite(v)
    if (any(bad)) data[[j]][bad] <- NA
  }
  data
}

as_data_frame_hint <- "Convert a {.fn table} or a matrix with {.fn as.data.frame} first."

check_flextable <- function(x, call = rlang::caller_env()) {
  if (!inherits(x, "flextable")) {
    cli::cli_abort(c("{.arg x} must be a flextable, not {.obj_type_friendly {x}}.",
                     i = "Make one with {.fn phw_flextable} first."), call = call)
  }
  invisible(x)
}

# flextable leaves pictures, such as the bars from phw_flextable_bars(), out
# of a PowerPoint table without a word.
check_no_images <- function(ft, call = rlang::caller_env()) {
  is_image <- function(z) inherits(z, "raster") || (is.character(z) && any(!is.na(z)))
  if (!any(vapply(flextable::information_data_chunk(ft)$img_data, is_image, logical(1)))) {
    return(invisible(ft))
  }
  cli::cli_abort(c("A PowerPoint table cannot show images, so the bars or pictures in this table would be lost.",
                   i = "On a slide, leave out {.fn phw_flextable_bars}, or show the values as a bar chart."),
                 call = call)
}

check_breaks <- function(breaks, call = rlang::caller_env()) {
  if (!is.numeric(breaks) || length(breaks) != 2 || anyNA(breaks)) {
    cli::cli_abort(c("{.arg breaks} must be two numbers: the cut points between red, amber and green.",
                     i = "For example {.code breaks = c(0.9, 0.95)}."), call = call)
  }
  invisible(breaks)
}

check_bar_values <- function(v, col, arg, call = rlang::caller_env()) {
  if (any(v < 0, na.rm = TRUE)) {
    cli::cli_abort(c("{.arg {arg}} can't have bars for negative values.",
                     x = "Column {.field {col}} goes down to {.val {min(v, na.rm = TRUE)}}.",
                     i = "Bars start at zero. For values either side of zero, colour the cells instead."),
                   call = call)
  }
  invisible(v)
}

# The columns of `cols` that have numbers to colour or draw. A column with
# none (all missing, or no rows) is left as it is, with a message, rather
# than failing inside scales or drawing empty bars.
value_cols <- function(data, cols, arg, call = rlang::caller_env()) {
  keep <- vapply(cols, function(col) {
    v <- data[[col]]
    if (!all(is.na(v))) check_numeric_col(data, col, arg, call = call)
    if (any(is.finite(v))) return(TRUE)
    cli::cli_inform("{call_label(call)}Column {.field {col}} has no values, so it is left as it is.")
    FALSE
  }, logical(1))
  cols[keep]
}
