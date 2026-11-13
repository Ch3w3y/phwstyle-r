# Column arguments work as in dplyr::select(): bare names, c(a, b), strings,
# positions and helpers such as starts_with(). These helpers turn one into
# column names, so the rest of each function can go on using names.
#
# In an exported function:
#   date <- pick_col(rlang::enquo(date), data, "date")
#   rows <- pick_cols(rlang::enquo(rows), data, "rows")

pick_cols <- function(quo, data, arg, null_ok = FALSE, call = rlang::caller_env()) {
  missing_arg <- rlang::quo_is_missing(quo)
  if (missing_arg || rlang::quo_is_null(quo)) {
    if (null_ok && !missing_arg) return(NULL)
    cli::cli_abort("{.arg {arg}} is needed: give the column{?s} to use.", call = call)
  }
  expr <- rlang::quo_get_expr(quo)
  # A name that isn't a column is a variable holding the selection, such as
  # column names built in code or NULL passed on by another function.
  if (rlang::is_symbol(expr) && !rlang::as_string(expr) %in% names(data)) {
    val <- tryCatch(rlang::eval_tidy(quo), error = function(e) quo)
    if (is.null(val)) {
      if (null_ok) return(NULL)
      cli::cli_abort("{.arg {arg}} is needed: give the column{?s} to use.", call = call)
    }
    if (is.character(val) || is.numeric(val)) {
      quo <- rlang::new_quosure(rlang::expr(tidyselect::all_of(!!val)), rlang::quo_get_env(quo))
    }
  }
  pos <- tidyselect::eval_select(quo, data, allow_rename = FALSE, error_call = call)
  names(data)[pos]
}

pick_col <- function(quo, data, arg, null_ok = FALSE, call = rlang::caller_env()) {
  out <- pick_cols(quo, data, arg, null_ok = null_ok, call = call)
  if (length(out) > 1) {
    cli::cli_abort("{.arg {arg}} must be one column, not {length(out)}.", call = call)
  }
  if (!length(out)) {
    if (null_ok) return(NULL)
    cli::cli_abort("{.arg {arg}} must be one column, but none was selected.", call = call)
  }
  out
}

# Text for each row, for map labels and popups: a column (bare or as a
# string), an expression using the columns, or a vector with a value per row.
pick_text <- function(quo, data) {
  if (rlang::quo_is_null(quo)) return(NULL)
  val <- rlang::eval_tidy(quo, data = as.list(as.data.frame(data)))
  if (is.null(val)) return(NULL)
  if (is.character(val) && length(val) == 1 && val %in% names(data)) val <- data[[val]]
  as.character(val)
}
