# Checks on what an exported function is given. Each one stops with a clear
# message at the entry point, or drops rows and says so, so that a
# dependency never raises its own error and no row goes missing silently.
# Pass `call = rlang::caller_env()` through, as the pick_col() helpers do, so
# the message names the user's function.

check_has_rows <- function(data, arg = "data", call = rlang::caller_env()) {
  if (!NROW(data)) cli::cli_abort("{.arg {arg}} has no rows.", call = call)
  invisible(data)
}

check_numeric_col <- function(data, col, arg = col, call = rlang::caller_env()) {
  x <- data[[col]]
  if (!is.numeric(x)) {
    cli::cli_abort(c("{.arg {arg}} must be a numeric column.",
                     x = "Column {.field {col}} is {.cls {class(x)[1]}}."), call = call)
  }
  invisible(x)
}

# Dates as Date, POSIXct or ISO 8601 text ("2026-11-14"). Text in another
# format, such as "14/11/2026", stops instead of being guessed at. NA stays
# NA. as_date_col() reads a data column, as_date_value() an argument.
as_date_col <- function(data, col, arg = col, call = rlang::caller_env()) {
  as_date_value(data[[col]], arg = arg, call = call)
}

# Drops rows with a missing value in any of `cols`, or an infinite one in a
# numeric column, with one message saying how many went. Stops when no row
# is left, since an empty chart or table would only hide the problem.
drop_missing <- function(data, cols, call = rlang::caller_env()) {
  bad <- rep(FALSE, NROW(data))
  for (col in cols) {
    x <- data[[col]]
    bad <- bad | if (is.numeric(x)) !is.finite(x) else is.na(x)
  }
  n <- sum(bad)
  if (!n) return(data)
  fn <- call_label(call)
  if (n == NROW(data)) {
    cli::cli_abort("Every row has a missing value in {.field {cols}}.", call = call)
  }
  cli::cli_inform("{fn}Left out {n} row{?s} with a missing value in {.or {.field {cols}}}.")
  data[!bad, , drop = FALSE]
}

check_colours <- function(x, arg, call = rlang::caller_env()) {
  bad <- is.na(x) | !is_colour(x)
  if (any(bad)) {
    cli::cli_abort("{.arg {arg}} must be colours: {.val {as.character(x[bad])}} {?is/are} not.", call = call)
  }
  invisible(x)
}

call_label <- function(call) {
  fn <- tryCatch(rlang::call_name(rlang::frame_call(call)), error = function(e) NULL)
  if (is.null(fn)) "" else paste0(fn, "(): ")
}

as_date_value <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x, tz = attr(x, "tzone") %||% ""))
  if (is.logical(x) && all(is.na(x))) return(as.Date(x))
  if (is.character(x) || is.factor(x)) {
    x <- as.character(x)
    iso <- !is.na(x) & grepl("^\\d{4}-\\d{2}-\\d{2}", x)
    out <- as.Date(ifelse(iso, substr(x, 1, 10), NA_character_), format = "%Y-%m-%d", optional = TRUE)
    bad <- !is.na(x) & is.na(out)
    if (!any(bad)) return(out)
    example <- 'as.Date(x, format = "%d/%m/%Y")'
    cli::cli_abort(c("{.arg {arg}} must be a date.",
                     x = "{.val {x[bad][1]}} is not an ISO date.",
                     i = "Use ISO dates like {.val 2026-11-14}, or convert it first with {.code {example}}."),
                   call = call)
  }
  cli::cli_abort("{.arg {arg}} must be a Date, a date-time or ISO text such as {.val 2026-11-14}, not {.obj_type_friendly {x}}.",
                 call = call)
}

# Single TRUE or FALSE, single non-NA string, single finite number, single
# positive number and single whole number, for arguments.
check_true_false <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (!isTRUE(x) && !isFALSE(x)) {
    cli::cli_abort("{.arg {arg}} must be {.code TRUE} or {.code FALSE}, not {.obj_type_friendly {x}}.", call = call)
  }
  invisible(x)
}

check_ramp_palette <- function(palette, groups_hint = "For groups use a {.code _d} scale.",
                               call = rlang::caller_env()) {
  if (is_palette_name(palette) && palette_type(palette) == "qualitative") {
    cli::cli_abort(c("{.val {palette}} is a qualitative palette for groups, not for numbers.",
                     i = "For numbers use a sequential palette such as {.val blues}, or {.val orange_navy} to diverge.",
                     i = groups_hint), call = call)
  }
  invisible(palette)
}

check_one_string <- function(x, arg = rlang::caller_arg(x), allow_null = FALSE, allow_empty = TRUE,
                             hint = NULL, call = rlang::caller_env()) {
  if (allow_null && is.null(x)) return(invisible(x))
  if (!is.character(x) || length(x) != 1 || is.na(x) || (!allow_empty && !nzchar(x))) {
    what <- if (allow_empty) "a single string" else "a single non-empty string"
    cli::cli_abort(c("{.arg {arg}} must be {what}, not {.obj_type_friendly {x}}.", i = hint), call = call)
  }
  invisible(x)
}

check_positive_number <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x <= 0) {
    cli::cli_abort("{.arg {arg}} must be a single positive number, not {.val {x}}.", call = call)
  }
  invisible(x)
}

check_number <- function(x, arg = rlang::caller_arg(x), allow_null = FALSE, call = rlang::caller_env()) {
  if (allow_null && is.null(x)) return(invisible(x))
  if (!is.numeric(x) || length(x) != 1 || !is.finite(x)) {
    cli::cli_abort("{.arg {arg}} must be a single number, not {.obj_type_friendly {x}}.", call = call)
  }
  invisible(x)
}

check_whole_number <- function(x, min, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (!is.numeric(x) || length(x) != 1 || !is.finite(x) || x < min || x != round(x)) {
    cli::cli_abort("{.arg {arg}} must be a whole number, {min} or more, not {.val {x}}.", call = call)
  }
  invisible(x)
}

# `bins` for phw_map() and phw_leaflet_polygons(): NULL, a number of bins
# (2 or more), or a vector of breaks.
check_bins <- function(bins, call = rlang::caller_env()) {
  if (is.null(bins)) return(invisible())
  if (!is.numeric(bins) || length(bins) == 0 || anyNA(bins) ||
      (length(bins) == 1 && !(is.finite(bins) && bins >= 2))) {
    cli::cli_abort("{.arg bins} must be a number of bins (2 or more) or a vector of breaks.", call = call)
  }
  invisible()
}
