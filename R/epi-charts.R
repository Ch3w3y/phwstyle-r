# Ready-made public health charts. Each returns an ordinary ggplot, so you
# can add layers, labels and themes as usual.

# The ready-made charts carry their own theme, so they are styled with no
# setup. When use_phw_ggplot() has set the session theme, they follow the
# settings it was given (say `base_size = 14` or `accessible = TRUE`)
# rather than going back to the defaults.
chart_theme <- function(...) {
  args <- if (identical(ggplot2::theme_get(), phw_session$theme)) phw_session$args else list()
  new <- list(...)
  args[names(new)] <- new
  do.call(theme_phw, args)
}

floor_period <- function(x, interval, week_start = 1) {
  x <- as.Date(x)
  switch(interval,
    day = x,
    week = x - ((as.integer(format(x, "%u")) - week_start) %% 7),
    month = as.Date(format(x, "%Y-%m-01")),
    quarter = as.Date(sprintf("%s-%02d-01", format(x, "%Y"), (as.integer(format(x, "%m")) - 1) %/% 3 * 3 + 1)),
    year = as.Date(format(x, "%Y-01-01")))
}

period_step <- function(interval) {
  switch(interval, day = "day", week = "week", month = "month", quarter = "3 months", year = "year")
}

#' Epidemic curve
#'
#' Counts of cases (or any events) by day, week, month, quarter or year,
#' as columns, optionally stacked or side by side by group. Periods with
#' no cases are shown as zero, so the time axis has no gaps.
#'
#' @param data A data frame with one row per case, or with a count column.
#' @param date The date column, unquoted as in dplyr (`onset`). A string
#'   (`"onset"`) works too.
#' @param group Optional column to colour and stack by (e.g. age group or
#'   organism).
#' @param count Optional column of counts (for aggregated data).
#' @param interval `"day"`, `"week"`, `"month"`, `"quarter"` or `"year"`.
#' @param week_start First day of the week, 1 = Monday (ISO weeks) to 7 =
#'   Sunday.
#' @param position `"stack"` or `"dodge"` for grouped columns.
#' @param palette,key Colours for groups, as in [scale_fill_phw_d()].
#'   `key` keeps each group's colour across charts.
#' @param fill Column colour when there is no `group`.
#' @param date_labels,date_breaks Passed to [ggplot2::scale_x_date()].
#' @param range Optional two dates for the start and end of the axis,
#'   e.g. to show a full year even when the first weeks have no cases.
#' @param average Optional whole number of periods, `k`, for a rolling
#'   average line. It is the mean of the total count (all groups added
#'   together) over the latest `k` periods, drawn at the centre of each
#'   period's column. The first `k - 1` periods have no average and draw
#'   nothing.
#' @param average_label Legend text for the average line. Defaults to, for
#'   example, `"7-day average"` or `"4-week average"`.
#' @param ... Passed to [ggplot2::geom_col()].
#' @return A ggplot. The counts by period are in `$data` (columns `period`,
#'   `group` and `n`, plus `average` when `average` is set, the same on
#'   every group row of a period).
#' @examples
#' set.seed(1)
#' cases <- data.frame(
#'   onset = as.Date("2025-01-01") + round(rgamma(300, 6, 0.15)),
#'   group = sample(c("Group A", "Group B"), 300, TRUE))
#' phw_epicurve(cases, onset, group = group) +
#'   ggplot2::labs(title = "Cases by week of onset", x = "Week beginning", y = "Cases")
#'
#' # A four-week rolling average of the total
#' phw_epicurve(cases, onset, group = group, average = 4)
#' @export
phw_epicurve <- function(data, date, group = NULL, count = NULL,
                         interval = c("week", "day", "month", "quarter", "year"), week_start = 1,
                         position = c("stack", "dodge"), palette = NULL, key = NULL,
                         fill = phw_colours[["navy"]], date_labels = NULL, date_breaks = NULL,
                         range = NULL, average = NULL, average_label = NULL, ...) {
  interval <- rlang::arg_match(interval)
  position <- rlang::arg_match(position)
  if (!is.null(average) &&
      !(is.numeric(average) && length(average) == 1 && !is.na(average) && average >= 1 && average == round(average))) {
    cli::cli_abort("{.arg average} must be a whole number of periods, 1 or more.")
  }
  date <- pick_col(rlang::enquo(date), data, "date")
  group <- pick_col(rlang::enquo(group), data, "group", null_ok = TRUE)
  count <- pick_col(rlang::enquo(count), data, "count", null_ok = TRUE)
  data <- as.data.frame(data)
  period <- floor_period(data[[date]], interval, week_start)
  w <- if (is.null(count)) rep(1, nrow(data)) else data[[count]]
  g <- if (is.null(group)) factor(rep("All", nrow(data))) else as_levels(data[[group]], "Unknown")
  keep <- !is.na(period)
  agg <- stats::aggregate(list(n = w[keep]), list(period = period[keep], group = g[keep]), sum)
  lims <- if (is.null(range)) base::range(agg$period) else floor_period(as.Date(range), interval, week_start)
  all_p <- seq(lims[1], lims[2], by = period_step(interval))
  full <- expand.grid(period = all_p, group = levels(g), stringsAsFactors = FALSE)
  full$group <- factor(full$group, levels(g))
  full <- merge(full, agg, all.x = TRUE)
  full$n[is.na(full$n)] <- 0
  if (!is.null(average)) {
    total <- tapply(full$n, full$period, sum)
    roll <- as.numeric(stats::filter(as.numeric(total), rep(1 / average, average), sides = 1))
    full$average <- roll[match(as.character(full$period), names(total))]
  }
  width <- switch(interval, day = 0.9, week = 6.3, month = 27, quarter = 82, year = 330)
  p <- ggplot2::ggplot(full, ggplot2::aes(x = .data$period, y = .data$n))
  pos <- if (position == "stack") ggplot2::position_stack(reverse = TRUE) else ggplot2::position_dodge()
  if (is.null(group)) {
    p <- p + ggplot2::geom_col(fill = fill, width = width, just = 0, ...)
  } else {
    p <- p + ggplot2::geom_col(ggplot2::aes(fill = .data$group), width = width, just = 0, position = pos, ...) +
      scale_fill_phw_d(palette = palette %||% phw_default_palette(), key = key, name = NULL)
  }
  if (!is.null(average)) {
    unit <- switch(interval, day = "day", week = "week", month = "month", quarter = "quarter", year = "year")
    label <- average_label %||% paste0(average, "-", unit, " average")
    p <- p +
      ggplot2::geom_line(ggplot2::aes(x = .data$period + width / 2, y = .data$average, colour = label),
                         data = full[!duplicated(full$period), ], linewidth = 1, na.rm = TRUE) +
      ggplot2::scale_colour_manual(values = stats::setNames(phw_colours[["black"]], label), name = NULL)
  }
  xargs <- list(expand = ggplot2::expansion(mult = c(0.01, 0.02)))
  if (!is.null(date_labels)) xargs$date_labels <- date_labels
  if (!is.null(date_breaks)) xargs$date_breaks <- date_breaks
  p + do.call(ggplot2::scale_x_date, xargs) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.05))) +
    ggplot2::labs(x = NULL, y = "Count") +
    chart_theme(grid = "y")
}

#' Population pyramid
#'
#' Horizontal bars by age group, with one sex on each side of a central
#' axis. Optionally overlays a comparison population (e.g. Wales overall,
#' or a previous year) as outlines.
#'
#' @param data A data frame with one row per person, or with a value
#'   column.
#' @param age,sex The age and sex columns, unquoted as in dplyr (strings
#'   work too). `age` should be a factor in age order (or
#'   will be sorted as text).
#' @param value Optional column of counts or populations.
#' @param percent Show each bar as a percentage of the total, so
#'   populations of different sizes can be compared?
#' @param left Which `sex` value goes on the left. Defaults to the first
#'   level.
#' @param compare Optional data frame with the same columns, drawn as
#'   outlines.
#' @param palette Two colours, or a palette name.
#' @param compare_colour Outline colour for `compare`.
#' @param ... Passed to [ggplot2::geom_col()].
#' @return A ggplot.
#' @examples
#' ages <- c("0-14", "15-29", "30-44", "45-64", "65-79", "80+")
#' pop <- expand.grid(age = factor(ages, ages), sex = c("Female", "Male"))
#' pop$n <- c(240, 280, 300, 410, 260, 90, 250, 290, 295, 400, 240, 60) * 1000
#' phw_pyramid(pop, age, sex, value = n, percent = TRUE)
#' @export
phw_pyramid <- function(data, age, sex, value = NULL, percent = FALSE, left = NULL, compare = NULL,
                        palette = NULL, compare_colour = phw_colours[["black"]], ...) {
  age <- pick_col(rlang::enquo(age), data, "age")
  sex <- pick_col(rlang::enquo(sex), data, "sex")
  value <- pick_col(rlang::enquo(value), data, "value", null_ok = TRUE)
  prep <- function(d) {
    d <- as.data.frame(d)
    w <- if (is.null(value)) rep(1, nrow(d)) else d[[value]]
    a <- if (is.factor(d[[age]])) d[[age]] else factor(d[[age]], sort(unique(d[[age]])))
    out <- stats::aggregate(list(n = w), list(age = a, sex = as.character(d[[sex]])), sum)
    if (percent) out$n <- 100 * out$n / sum(out$n)
    out
  }
  d <- prep(data)
  sexes <- unique(c(left, if (is.factor(data[[sex]])) levels(data[[sex]]) else sort(unique(d$sex))))
  sexes <- sexes[sexes %in% d$sex]
  if (length(sexes) != 2) cli::cli_abort("{.arg sex} must have exactly two values, not {length(sexes)}.")
  d$sex <- factor(d$sex, sexes)
  d$x <- ifelse(d$sex == sexes[1], -d$n, d$n)
  cols <- if (is.null(palette)) unname(phw_colours[c("navy", "teal")]) else phw_pal(2, palette = palette)
  lab_fun <- function(x) {
    if (percent) paste0(format(abs(x), trim = TRUE), "%") else format(abs(x), big.mark = ",", trim = TRUE, scientific = FALSE)
  }
  lim <- max(abs(d$x))
  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data$x, y = .data$age)) +
    ggplot2::geom_col(ggplot2::aes(fill = .data$sex), width = 0.85, ...)
  if (!is.null(compare)) {
    cd <- prep(compare)
    cd$sex <- factor(cd$sex, sexes)
    cd$x <- ifelse(cd$sex == sexes[1], -cd$n, cd$n)
    lim <- max(lim, abs(cd$x))
    p <- p + ggplot2::geom_col(data = cd, fill = NA, colour = compare_colour, width = 0.85, linewidth = 0.5)
  }
  p + ggplot2::geom_vline(xintercept = 0, colour = phw_colours[["text"]], linewidth = 0.4) +
    ggplot2::scale_fill_manual(values = cols, name = NULL) +
    ggplot2::scale_x_continuous(labels = lab_fun, limits = c(-lim, lim) * 1.05) +
    ggplot2::labs(x = if (percent) "Percentage of population" else "Count", y = NULL) +
    chart_theme(grid = "x")
}

#' Funnel plot
#'
#' Compares areas, providers or practices of different sizes against a
#' target (by default the overall value), with control limits that narrow
#' as the denominator grows. Points outside the limits are coloured and
#' shaped, so unusual values stand out without over-reading small areas.
#'
#' @param data A data frame with one row per unit (area, practice...).
#' @param numerator,denominator Columns of events and of population (or
#'   patients, tests...), unquoted as in dplyr. Strings work too.
#' @param label Optional column of unit names; units outside the outer
#'   limits are labelled.
#' @param type `"proportion"` (e.g. uptake) or `"rate"` (e.g. incidence).
#' @param multiplier Scale for the y axis: 100 for a percentage, 1e5 for a
#'   rate per 100,000.
#' @param target The target value on the multiplied scale. Defaults to the
#'   overall value (sum of numerators over sum of denominators).
#' @param limits Two confidence levels for the inner and outer limits.
#' @param point_colour Colour of points within the limits.
#' @return A ggplot. The units, with a `zone` column ("Within limits",
#'   "Above 95%"...), are in `$data`.
#' @details Limits use the normal approximation to the binomial (for
#'   proportions) or Poisson (for rates) distribution around the target.
#' @examples
#' set.seed(2)
#' units <- data.frame(unit = paste("Unit", 1:40), n = round(runif(40, 200, 5000)))
#' units$events <- rbinom(40, units$n, 0.12)
#' phw_funnel(units, events, n, label = unit) +
#'   ggplot2::labs(title = "Proportion by unit", x = "Population", y = "Proportion (%)")
#' @export
phw_funnel <- function(data, numerator, denominator, label = NULL, type = c("proportion", "rate"),
                       multiplier = if (type[1] == "proportion") 100 else 1e5, target = NULL,
                       limits = c(0.95, 0.998), point_colour = phw_colours[["grey_mid"]]) {
  type <- rlang::arg_match(type)
  numerator <- pick_col(rlang::enquo(numerator), data, "numerator")
  denominator <- pick_col(rlang::enquo(denominator), data, "denominator")
  label <- pick_col(rlang::enquo(label), data, "label", null_ok = TRUE)
  data <- as.data.frame(data)
  num <- data[[numerator]]
  den <- data[[denominator]]
  p0 <- if (is.null(target)) sum(num) / sum(den) else target / multiplier
  se <- function(n) if (type == "proportion") sqrt(p0 * (1 - p0) / n) else sqrt(p0 / n)
  z <- stats::qnorm(1 - (1 - sort(limits)) / 2)
  data$value <- multiplier * num / den
  dev <- (num / den - p0) / se(den)
  data$zone <- factor(ifelse(dev > z[2], paste0("Above ", limits[2] * 100, "%"),
                      ifelse(dev > z[1], paste0("Above ", limits[1] * 100, "%"),
                      ifelse(dev < -z[2], paste0("Below ", limits[2] * 100, "%"),
                      ifelse(dev < -z[1], paste0("Below ", limits[1] * 100, "%"), "Within limits")))),
                      levels = c(paste0("Above ", rev(limits) * 100, "%"), "Within limits",
                                 paste0("Below ", limits * 100, "%")))
  grid_n <- exp(seq(log(max(1, min(den) * 0.8)), log(max(den) * 1.1), length.out = 200))
  lines <- do.call(rbind, lapply(seq_along(z), function(k) {
    rbind(data.frame(n = grid_n, y = multiplier * (p0 + z[k] * se(grid_n)), limit = k, side = "upper"),
          data.frame(n = grid_n, y = multiplier * pmax(0, p0 - z[k] * se(grid_n)), limit = k, side = "lower"))
  }))
  lines$grp <- paste(lines$limit, lines$side)
  zone_cols <- stats::setNames(c(phw_colours[["magenta"]], phw_colours[["amber"]], point_colour,
                                 phw_colours[["navy"]], phw_colours[["teal"]]), levels(data$zone))
  zone_shapes <- stats::setNames(c(17, 17, 16, 15, 15), levels(data$zone))
  p <- ggplot2::ggplot(data, ggplot2::aes(x = .data[[denominator]], y = .data$value)) +
    ggplot2::geom_hline(yintercept = multiplier * p0, colour = phw_colours[["text"]], linewidth = 0.5) +
    ggplot2::geom_line(data = lines, ggplot2::aes(x = .data$n, y = .data$y, group = .data$grp,
                                                  linetype = factor(.data$limit)),
                       colour = phw_colours[["text_secondary"]], linewidth = 0.4, inherit.aes = FALSE) +
    ggplot2::geom_point(ggplot2::aes(colour = .data$zone, shape = .data$zone), size = 2.4) +
    ggplot2::scale_colour_manual(values = zone_cols, name = NULL, drop = TRUE) +
    ggplot2::scale_shape_manual(values = zone_shapes, name = NULL, drop = TRUE) +
    ggplot2::scale_linetype_manual(values = c("dashed", "solid"), guide = "none") +
    ggplot2::scale_x_continuous(labels = function(x) format(x, big.mark = ",", trim = TRUE, scientific = FALSE)) +
    ggplot2::labs(x = denominator, y = if (type == "proportion") "Percentage" else "Rate") +
    chart_theme(grid = "y")
  if (!is.null(label)) {
    out <- data[grepl(paste0(limits[2] * 100, "%"), data$zone), , drop = FALSE]
    if (nrow(out)) {
      geom <- if (requireNamespace("ggrepel", quietly = TRUE)) ggrepel::geom_text_repel else ggplot2::geom_text
      p <- p + geom(data = out, ggplot2::aes(label = .data[[label]]), size = 3, colour = phw_colours[["text"]],
                    family = phw_font(),
                    vjust = -0.8)
    }
  }
  p
}

#' Statistical process control (SPC) chart
#'
#' An XmR chart or a run chart for a measure over time, as used for
#' quality improvement. An XmR chart plots individual values (X) with
#' limits worked out from the moving range (mR), the change from one point
#' to the next. Points that show special cause variation
#' are coloured: outside the process limits, a shift of `shift` or more
#' points on one side of the centre line, or a trend of `trend` or more
#' points going the same way. With `improvement`, special causes in the
#' good direction are blue and in the bad direction orange, as in NHS
#' "Making Data Count" charts.
#'
#' @param data A data frame with one row per time point.
#' @param x,y The time column (date or number) and the measure, unquoted as
#'   in dplyr (strings work too).
#' @param type `"xmr"` (centre line at the mean, limits at 2.66 times the
#'   mean moving range) or `"run"` (median line, no limits).
#' @param improvement Which direction is better: `"none"`, `"increase"` or
#'   `"decrease"`.
#' @param baseline Number of points to calculate the centre line and limits
#'   from (e.g. the first 20). `NULL` uses all points.
#' @param shift,trend Run lengths that count as special causes.
#' @return A ggplot. The points, with a `signal` column, are in `$data`.
#' @examples
#' set.seed(3)
#' spc <- data.frame(month = seq(as.Date("2023-01-01"), by = "month", length.out = 30),
#'                   value = c(rnorm(20, 50, 4), rnorm(10, 58, 4)))
#' phw_spc(spc, month, value, improvement = "increase", baseline = 20)
#' @export
phw_spc <- function(data, x, y, type = c("xmr", "run"), improvement = c("none", "increase", "decrease"),
                    baseline = NULL, shift = 7, trend = 6) {
  type <- rlang::arg_match(type)
  improvement <- rlang::arg_match(improvement)
  x <- pick_col(rlang::enquo(x), data, "x")
  y <- pick_col(rlang::enquo(y), data, "y")
  data <- as.data.frame(data)
  data <- data[order(data[[x]]), , drop = FALSE]
  v <- data[[y]]
  n <- length(v)
  base <- if (is.null(baseline)) seq_len(n) else seq_len(min(baseline, n))
  centre <- if (type == "xmr") mean(v[base], na.rm = TRUE) else stats::median(v[base], na.rm = TRUE)
  mr <- mean(abs(diff(v[base])), na.rm = TRUE)
  ucl <- centre + 2.66 * mr
  lcl <- centre - 2.66 * mr
  high <- rep(FALSE, n); low <- rep(FALSE, n)
  if (type == "xmr") {
    high <- high | v > ucl
    low <- low | v < lcl
  }
  # Shifts: runs of `shift` or more points on one side of the centre line.
  side <- sign(v - centre)
  r <- rle(side)
  ends <- cumsum(r$lengths)
  for (k in which(r$lengths >= shift & r$values != 0)) {
    idx <- (ends[k] - r$lengths[k] + 1):ends[k]
    if (r$values[k] > 0) high[idx] <- TRUE else low[idx] <- TRUE
  }
  # Trends: `trend` or more points each higher (or lower) than the last.
  d <- sign(diff(v))
  r <- rle(d)
  ends <- cumsum(r$lengths)
  for (k in which(r$lengths >= trend - 1 & r$values != 0)) {
    idx <- (ends[k] - r$lengths[k] + 1):(ends[k] + 1)
    if (r$values[k] > 0) high[idx] <- TRUE else low[idx] <- TRUE
  }
  data$signal <- factor(
    ifelse(!(high | low), "Common cause",
           switch(improvement,
                  none = "Special cause",
                  increase = ifelse(high, "Improvement", "Concern"),
                  decrease = ifelse(low, "Improvement", "Concern"))),
    levels = c("Common cause", "Special cause", "Improvement", "Concern"))
  cols <- c("Common cause" = phw_colours[["grey_mid"]], "Special cause" = phw_colours[["orange"]],
            "Improvement" = phw_colours[["navy"]], "Concern" = phw_colours[["orange"]])
  shapes <- c("Common cause" = 16, "Special cause" = 17, "Improvement" = 15, "Concern" = 17)
  p <- ggplot2::ggplot(data, ggplot2::aes(x = .data[[x]], y = .data[[y]])) +
    ggplot2::geom_hline(yintercept = centre, colour = phw_colours[["text"]], linewidth = 0.5)
  if (type == "xmr") {
    p <- p + ggplot2::geom_hline(yintercept = c(lcl, ucl), colour = phw_colours[["text_secondary"]],
                                 linetype = "dashed", linewidth = 0.4)
  }
  if (!is.null(baseline) && baseline < n) {
    p <- p + ggplot2::geom_vline(xintercept = data[[x]][baseline], colour = phw_colours[["grey_light"]],
                                 linetype = "dotted")
  }
  p + ggplot2::geom_line(colour = phw_colours[["grey_mid"]], linewidth = 0.5) +
    ggplot2::geom_point(ggplot2::aes(colour = .data$signal, shape = .data$signal), size = 2.4) +
    ggplot2::scale_colour_manual(values = cols, name = NULL, drop = TRUE) +
    ggplot2::scale_shape_manual(values = shapes, name = NULL, drop = TRUE) +
    ggplot2::labs(x = NULL, y = y) +
    chart_theme(grid = "y")
}
