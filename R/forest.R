#' Forest plot
#'
#' Estimates with their intervals for a set of units (areas, practices,
#' groups), sorted by value. With a `target`, such as the overall value, each
#' unit is coloured and shaped by whether its interval lies above the target,
#' overlaps it or lies below it. You supply the estimates and intervals, and
#' nothing is calculated from them.
#'
#' @param data A data frame with one row per unit.
#' @param value,lower,upper Columns of the estimate and of the lower and
#'   upper ends of its interval, unquoted as in dplyr. Strings work too.
#'   Units with a missing estimate or interval are left out, with a message.
#' @param label Column of unit names, one per row and none missing.
#' @param target Optional reference value on the same scale as `value`,
#'   drawn as a dashed line. One number.
#' @param labels Optional named character vector to rename the three
#'   comparison levels. The names are the default text (`"Higher"`,
#'   `"Similar"`, `"Lower"`) and the values are the replacements, e.g.
#'   `c(Higher = "Above Wales")`.
#' @param ... Passed to [ggplot2::geom_point()].
#' @return A ggplot. The units, sorted by value and with a `compared` column
#'   (a factor of `"Higher"`, `"Similar"` and `"Lower"`, absent without a
#'   `target`), are in `$data`.
#' @details A unit is "Higher" when its whole interval is above the target
#'   and "Lower" when its whole interval is below it. Otherwise it is
#'   "Similar". Without a `target` every unit is drawn in navy, with no
#'   legend.
#' @examples
#' set.seed(4)
#' areas <- data.frame(area = paste("Area", LETTERS[1:8]), value = round(runif(8, 40, 80), 1))
#' areas$lower <- areas$value - round(runif(8, 4, 10), 1)
#' areas$upper <- areas$value + round(runif(8, 4, 10), 1)
#' phw_forest(areas, value, lower, upper, label = area, target = 60) +
#'   ggplot2::labs(title = "Rate by area", x = "Rate per 100,000")
#' @export
phw_forest <- function(data, value, lower, upper, label, target = NULL, labels = NULL, ...) {
  value <- pick_col(rlang::enquo(value), data, "value")
  lower <- pick_col(rlang::enquo(lower), data, "lower")
  upper <- pick_col(rlang::enquo(upper), data, "upper")
  label <- pick_col(rlang::enquo(label), data, "label")
  data <- as.data.frame(data)
  check_has_rows(data)
  check_numeric_col(data, value, "value")
  check_numeric_col(data, lower, "lower")
  check_numeric_col(data, upper, "upper")
  if (!is.null(target) && !(is.numeric(target) && length(target) == 1 && is.finite(target))) {
    cli::cli_abort("{.arg target} must be one number.")
  }
  data <- drop_missing(data, c(value, lower, upper))
  units <- data[[label]]
  if (anyNA(units)) cli::cli_abort("Every unit needs a {.arg label}: {.field {label}} has a missing value.")
  if (any(data[[lower]] > data[[value]] | data[[value]] > data[[upper]], na.rm = TRUE)) {
    cli::cli_abort("Each {.arg value} must lie between its {.arg lower} and {.arg upper}.")
  }
  levs <- c("Higher", "Similar", "Lower")
  levs <- levels(relabel_levels(factor(levs, levs), labels))
  data <- data[order(data[[value]]), , drop = FALSE]
  rows <- ggplot2::aes(x = .data[[value]], y = factor(.data[[label]], unique(.data[[label]])))
  if (!is.null(target)) {
    data$compared <- factor(levs[ifelse(data[[lower]] > target, 1, ifelse(data[[upper]] < target, 3, 2))], levs)
  }
  p <- ggplot2::ggplot(data, rows)
  if (is.null(target)) {
    navy <- phw_colours[["navy"]]
    return(p +
      ggplot2::geom_errorbar(ggplot2::aes(xmin = .data[[lower]], xmax = .data[[upper]]), colour = navy,
                             width = 0.25, linewidth = 0.8, orientation = "y", stat = StatPhwForestUnits) +
      signal_points(NULL, ..., .defaults = list(colour = navy, size = 3)) +
      ggplot2::labs(x = value, y = NULL) +
      chart_theme(grid = "x"))
  }
  cols <- stats::setNames(unname(phw_colours[c("magenta", "grey_mid", "navy")]), levs)
  shapes <- stats::setNames(c(17, 16, 15), levs)
  p +
    ggplot2::geom_vline(xintercept = target, linetype = "dashed", colour = phw_colours[["text_secondary"]]) +
    ggplot2::geom_errorbar(ggplot2::aes(xmin = .data[[lower]], xmax = .data[[upper]], colour = .data$compared),
                           width = 0.25, linewidth = 0.8, orientation = "y", stat = StatPhwForestUnits) +
    signal_points(ggplot2::aes(colour = .data$compared, shape = .data$compared), ..., .defaults = list(size = 3)) +
    ggplot2::scale_colour_manual(values = cols, breaks = levs, drop = TRUE) +
    ggplot2::scale_shape_manual(values = shapes, breaks = levs, drop = TRUE) +
    ggplot2::labs(x = value, y = NULL, colour = NULL, shape = NULL) +
    chart_theme(grid = "x")
}

# Checks for a unit drawn twice on one row at build time, once the facets
# are known: one row per unit and period is fine when faceted by period.
StatPhwForestUnits <- ggplot2::ggproto("StatPhwForestUnits", ggplot2::StatIdentity,
  compute_layer = function(self, data, params, layout) {
    twice <- unique(unlist(lapply(split(data, data$PANEL), function(d) {
      pos <- unique(as.integer(d$y[duplicated(d$y)]))
      if (length(pos)) as.character(layout$get_scales(d$PANEL[1])$y$get_limits()[pos])
    })))
    if (length(twice)) {
      cli::cli_inform(c("phw_forest(): {.val {twice}} {?has/have} more than one row, so {?its intervals share a row/their intervals share rows}.",
                        i = "Give one row per unit, or facet by period with {.fn ggplot2::facet_wrap}."))
    }
    data
  })
