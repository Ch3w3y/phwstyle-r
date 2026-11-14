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

# Single TRUE or FALSE, and single non-NA string, for arguments.
check_true_false <- function(x, arg = rlang::caller_arg(x), call = rlang::caller_env()) {
  if (!isTRUE(x) && !isFALSE(x)) {
    cli::cli_abort("{.arg {arg}} must be {.code TRUE} or {.code FALSE}, not {.obj_type_friendly {x}}.", call = call)
  }
  invisible(x)
}

check_one_string <- function(x, arg = rlang::caller_arg(x), allow_null = FALSE, call = rlang::caller_env()) {
  if (allow_null && is.null(x)) return(invisible(x))
  if (!is.character(x) || length(x) != 1 || is.na(x)) {
    cli::cli_abort("{.arg {arg}} must be a single string, not {.obj_type_friendly {x}}.", call = call)
  }
  invisible(x)
}
