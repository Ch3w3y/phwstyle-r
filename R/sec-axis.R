#' Secondary axis for a second measure
#'
#' Draws a second measure against its own axis on the right (or top) of a
#' chart, for example a rate as a line over counts as columns. ggplot2 has
#' one scale per axis, so the second measure has to be rescaled into the
#' units of the first and the secondary axis has to undo that rescaling.
#' `phw_sec_axis()` works both out from the data, for linear and log axes,
#' so you don't have to find the multiplier by hand.
#'
#' It returns an ordinary [ggplot2::sec_axis()] with one extra function,
#' `$rescale()`. Use them together:
#'
#' 1. wrap the second measure in `$rescale()` inside `aes()`
#' 2. give the object to `sec.axis` in the scale for that axis
#'
#' Set `scale` to match the scale you add it to: `"linear"` for
#' [ggplot2::scale_y_continuous()], `"log"` for [ggplot2::scale_y_log10()].
#' On a log axis the two measures are lined up on the log scale, so both
#' axes show log-spaced breaks.
#'
#' The secondary axis can also use a different scale from the main one.
#' `scale = "linear", sec_scale = "log"` puts a log axis on the right of a
#' linear chart, and `scale = "log", sec_scale = "linear"` does the reverse.
#'
#' Two axes on one chart are easy to misread, because where the two series
#' cross depends only on how the axes are lined up. Name both axes, and
#' consider colouring the secondary axis to match its series (see the
#' examples).
#'
#' @param primary,secondary The values on the main axis and on the secondary
#'   axis, or just the range of each as `c(min, max)`. For stacked columns
#'   give the range of the stack totals, e.g. `c(0, 500)`.
#' @param name Title of the secondary axis.
#' @param scale Scale of the main axis: `"linear"` or `"log"`.
#' @param sec_scale Scale of the secondary axis. Defaults to `scale`.
#' @param zero Line up zero on both axes? This is the default for two
#'   linear axes, and what charts with columns need. `FALSE` stretches the
#'   range of `secondary` over the range of `primary` instead, which uses
#'   the whole panel. Log axes have no zero, so they always line up the two
#'   ranges.
#' @param breaks,labels,guide Passed to [ggplot2::sec_axis()], e.g.
#'   `labels = phw_percent()`.
#' @return A secondary axis for the `sec.axis` argument of a continuous
#'   position scale, with a `$rescale()` function that converts `secondary`
#'   values to the main axis.
#' @examples
#' library(ggplot2)
#' d <- data.frame(week = 1:20)
#' d$cases <- round(180 * exp(-((d$week - 9) / 4)^2) + 4)
#' d$positivity <- 2 + 28 * exp(-((d$week - 10) / 5)^2)
#'
#' # Linear: columns for counts, a line for the second measure.
#' sec <- phw_sec_axis(d$cases, d$positivity, name = "Positivity (%)")
#' ggplot(d, aes(week)) +
#'   geom_col(aes(y = cases), fill = phw_col("navy")) +
#'   geom_line(aes(y = sec$rescale(positivity)), colour = phw_col("orange"), linewidth = 1) +
#'   scale_y_continuous("Cases", sec.axis = sec) +
#'   theme_phw(axis.title.y.right = element_text(colour = phw_col("orange")),
#'             axis.text.y.right = element_text(colour = phw_col("orange")))
#'
#' # Log: the same idea on a log axis.
#' sec <- phw_sec_axis(d$cases, d$positivity, name = "Positivity (%)", scale = "log")
#' ggplot(d, aes(week)) +
#'   geom_line(aes(y = cases), colour = phw_col("navy")) +
#'   geom_line(aes(y = sec$rescale(positivity)), colour = phw_col("orange")) +
#'   scale_y_log10("Cases", sec.axis = sec) +
#'   theme_phw()
#' @export
phw_sec_axis <- function(primary, secondary, name = ggplot2::waiver(),
                         scale = c("linear", "log"), sec_scale = scale,
                         zero = TRUE, breaks = ggplot2::waiver(),
                         labels = ggplot2::waiver(), guide = ggplot2::waiver()) {
  scale <- rlang::arg_match(scale)
  sec_scale <- rlang::arg_match(sec_scale, c("linear", "log"))
  p <- sec_axis_range(primary, scale, "primary")
  s <- sec_axis_range(secondary, sec_scale, "secondary")
  tp <- sec_axis_trans(scale)
  ts <- sec_axis_trans(sec_scale)

  # On the transformed scales the two measures are related by a straight
  # line: tp(primary) = a + b * ts(secondary).
  a <- 0
  b <- 1
  if (zero && scale == "linear" && sec_scale == "linear") {
    if (max(abs(p)) > 0 && max(abs(s)) > 0) b <- max(abs(p)) / max(abs(s))
  } else {
    tpr <- tp$transform(p)
    tsr <- ts$transform(s)
    if (diff(tpr) > 0 && diff(tsr) > 0) b <- diff(tpr) / diff(tsr)
    a <- tpr[1] - b * tsr[1]
  }
  rescale <- function(x) tp$inverse(a + b * ts$transform(x))
  unscale <- function(x) ts$inverse((tp$transform(x) - a) / b)

  # ggplot2 picks secondary breaks the way the main axis does. When the two
  # scales differ, pick them to suit the secondary axis instead.
  if (sec_scale != scale) {
    if (inherits(labels, "waiver") && inherits(breaks, "waiver") && sec_scale == "log") {
      labels <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE, drop0trailing = TRUE)
    }
    if (inherits(breaks, "waiver")) {
      breaks <- if (sec_scale == "log") scales::breaks_log() else scales::breaks_extended()
    }
  }
  axis <- ggplot2::sec_axis(transform = unscale, name = name, breaks = breaks,
                            labels = labels, guide = guide)
  ggplot2::ggproto("PhwAxisSecondary", axis, rescale = rescale)
}

sec_axis_range <- function(x, scale, arg, call = rlang::caller_env()) {
  if (!is.numeric(x)) {
    cli::cli_abort("{.arg {arg}} must be numeric, not {.cls {class(x)}}.", call = call)
  }
  x <- x[is.finite(x)]
  if (scale == "log") x <- x[x > 0]
  if (!length(x)) {
    cli::cli_abort(c(
      "{.arg {arg}} has no values to work out the axis from.",
      i = if (scale == "log") "A log axis needs values above zero."
    ), call = call)
  }
  range(x)
}

# Zero and negative values can't be drawn on a log axis. Turn them into
# missing values so ggplot2 drops them with its usual message.
sec_axis_trans <- function(scale) {
  if (scale == "linear") return(list(transform = identity, inverse = identity))
  list(
    transform = function(x) {
      x[!is.na(x) & x <= 0] <- NA
      log10(x)
    },
    inverse = function(x) 10^x
  )
}
