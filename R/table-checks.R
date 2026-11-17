# Entry checks for the table renderers and the cell colouring helpers, on top
# of the shared ones in checks.R.

# A data frame with one name per column. A table() or a matrix stops here,
# since the renderers would each fail on it in their own way.
check_table_data <- function(data, arg = "data", call = rlang::caller_env()) {
  if (!is.data.frame(data)) {
    cli::cli_abort(c("{.arg {arg}} must be a data frame, not {.obj_type_friendly {data}}.",
                     i = as_data_frame_hint), call = call)
  }
  nms <- names(data)
  dup <- unique(nms[duplicated(nms)])
  if (length(dup)) {
    cli::cli_abort(c("{.arg {arg}} has more than one column named {.val {dup}}.",
                     i = "Give each column its own name."), call = call)
  }
  invisible(data)
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
