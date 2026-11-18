# Entry checks for the table renderers and the cell colouring helpers, on top
# of the shared ones in checks.R.

# A data frame with one name per column. A table() or a matrix stops here,
# since the renderers would each fail on it in their own way. A difftime,
# such as a length of stay, becomes a plain number in its own units so every
# renderer formats and aligns it as one; hms times of day keep their class.
check_table_data <- function(data, arg = "data", call = rlang::caller_env()) {
  data <- check_data_frame(data, as_data_frame_hint, arg, call)
  for (j in which(vapply(data, function(v) inherits(v, "difftime") && !inherits(v, "hms"), logical(1)))) {
    data[[j]] <- as.numeric(data[[j]])
  }
  nms <- names(data)
  dup <- unique(nms[duplicated(nms)])
  if (length(dup)) {
    cli::cli_abort(c("{.arg {arg}} has more than one column named {.val {dup}}.",
                     i = "Give each column its own name."), call = call)
  }
  data
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
