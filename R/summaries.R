# Summary tables: build a data frame once, then render it with
# phw_flextable() or phw_reactable(). The data frame carries row types
# (variable headings, levels, totals) and an optional column spanner as
# attributes, which the renderers turn into indents, bold rows and header
# groups.

new_phw_summary <- function(df, row_type, spanner = NULL, note = NULL, first_col = names(df)[1]) {
  rownames(df) <- NULL
  structure(df, class = c("phw_summary", "data.frame"), row_type = row_type,
            spanner = spanner, note = note, first_col = first_col)
}

#' @export
print.phw_summary <- function(x, ...) {
  y <- x
  types <- attr(x, "row_type")
  depth <- attr(x, "depth") %||% as.integer(types == "level")
  if (isTRUE(attr(x, "indent") %||% TRUE)) {
    y[[1]] <- paste0(strrep("  ", depth), y[[1]])
  }
  print(as.data.frame(unclass(y)[names(y)], check.names = FALSE), row.names = FALSE, ...)
  if (!is.null(attr(x, "note"))) cat(attr(x, "note"), "\n")
  invisible(x)
}

fmt_n <- function(x) format(x, big.mark = ",", trim = TRUE, scientific = FALSE)
fmt_num <- function(x, digits) {
  out <- formatC(x, format = "f", digits = digits, big.mark = ",")
  out[is.na(x)] <- ""
  out
}
fmt_pct <- function(n, d, digits) {
  p <- ifelse(d > 0, 100 * n / d, NA)
  ifelse(is.na(p), fmt_n(n), sprintf("%s (%s%%)", fmt_n(n), fmt_num(p, digits)))
}

var_label <- function(data, v, labels) {
  if (!is.null(labels[[v]])) return(labels[[v]])
  l <- attr(data[[v]], "label")
  if (is.character(l) && length(l) == 1) return(l)
  v
}

as_levels <- function(x, missing) {
  if (is.logical(x)) x <- factor(x, levels = c(TRUE, FALSE), labels = c("Yes", "No"))
  if (!is.factor(x)) x <- factor(x)
  if (anyNA(x) && !is.null(missing)) {
    levels(x) <- c(levels(x), missing)
    x[is.na(x)] <- missing
  }
  x
}

#' Summary table of characteristics by group
#'
#' The "Table 1" of a report: counts and percentages for categorical
#' variables (age group, sex, risk factors...) and a median (IQR) or mean
#' (SD) for numeric ones, optionally split by a grouping variable with a
#' total column. Render it with [phw_flextable()] or [phw_reactable()]:
#' variable names become bold headings with their levels indented, and the
#' grouping variable becomes a header spanning its columns.
#'
#' @param data A data frame with one row per person (or case, episode...).
#' @param vars Columns to summarise. Defaults to every column except `by`.
#' @param by Optional column to split by (e.g. outcome or year).
#' @param labels Named list of display names, e.g.
#'   `list(age_group = "Age group")`. Variable `label` attributes are used
#'   otherwise.
#' @param percent For categorical variables, percentages of each `"column"`
#'   (the default), of each `"row"`, or `"none"`.
#' @param numeric How to summarise numeric variables: `"median_iqr"` or
#'   `"mean_sd"`.
#' @param total Add a total column when `by` is given?
#' @param missing Label for missing values, or `NULL` to leave them out.
#' @param digits Decimal places for percentages and statistics.
#' @param n_in_header Show "(n = ...)" under each column heading?
#' @param label_header Heading of the first column.
#' @return A `phw_summary` data frame.
#' @examples
#' df <- data.frame(
#'   age_group = sample(c("0-14", "15-44", "45-64", "65+"), 200, TRUE),
#'   sex = sample(c("Female", "Male", NA), 200, TRUE, prob = c(.49, .49, .02)),
#'   days = rpois(200, 6),
#'   group = sample(c("Group A", "Group B"), 200, TRUE)
#' )
#' tab <- phw_summary_table(df, by = "group",
#'                          labels = list(age_group = "Age group", sex = "Sex",
#'                                        days = "Days"))
#' tab
#' if (requireNamespace("flextable", quietly = TRUE)) phw_flextable(tab)
#' @export
phw_summary_table <- function(data, vars = NULL, by = NULL, labels = list(),
                              percent = c("column", "row", "none"),
                              numeric = c("median_iqr", "mean_sd"), total = TRUE,
                              missing = "Unknown", digits = 1, n_in_header = TRUE,
                              label_header = "Characteristic") {
  percent <- rlang::arg_match(percent)
  numeric <- rlang::arg_match(numeric)
  data <- as.data.frame(data)
  vars <- vars %||% setdiff(names(data), by)
  groups <- if (is.null(by)) list(All = rep(TRUE, nrow(data))) else {
    g <- as_levels(data[[by]], missing)
    out <- lapply(levels(g), function(l) g == l)
    names(out) <- levels(g)
    if (total) out$Total <- rep(TRUE, nrow(data))
    out
  }
  col_names <- names(groups)
  if (n_in_header) {
    col_names <- sprintf("%s (n = %s)", if (is.null(by)) "All" else names(groups),
                         vapply(groups, function(i) fmt_n(sum(i)), ""))
  }
  rows <- list(); types <- character()
  for (v in vars) {
    x <- data[[v]]
    lab <- var_label(data, v, labels)
    if (is.numeric(x) && !is.factor(x)) {
      stat <- vapply(groups, function(i) {
        xi <- x[i]
        if (numeric == "median_iqr") {
          q <- stats::quantile(xi, c(.5, .25, .75), na.rm = TRUE, names = FALSE)
          sprintf("%s (%s to %s)", fmt_num(q[1], digits), fmt_num(q[2], digits), fmt_num(q[3], digits))
        } else {
          sprintf("%s (%s)", fmt_num(mean(xi, na.rm = TRUE), digits), fmt_num(stats::sd(xi, na.rm = TRUE), digits))
        }
      }, "")
      rows[[length(rows) + 1]] <- c(lab, stat); types <- c(types, "stat")
      nmiss <- vapply(groups, function(i) sum(is.na(x[i])), 0)
      if (!is.null(missing) && any(nmiss > 0)) {
        rows[[length(rows) + 1]] <- c(missing, fmt_n(nmiss)); types <- c(types, "level")
      }
    } else {
      f <- as_levels(x, missing)
      rows[[length(rows) + 1]] <- c(lab, rep("", length(groups))); types <- c(types, "variable")
      row_tot <- table(f)
      for (l in levels(f)) {
        cells <- vapply(groups, function(i) {
          n <- sum(f[i] == l, na.rm = TRUE)
          switch(percent,
                 column = fmt_pct(n, sum(i & !is.na(f)), digits),
                 row = fmt_pct(n, row_tot[[l]], digits),
                 none = fmt_n(n))
        }, "")
        rows[[length(rows) + 1]] <- c(l, cells); types <- c(types, "level")
      }
    }
  }
  df <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(df) <- c(label_header, col_names)
  note <- paste(c(if (percent != "none") "n (%)",
                  if (any(types == "stat")) if (numeric == "median_iqr") "median (IQR)" else "mean (SD)"),
                collapse = "; ")
  new_phw_summary(df, types, spanner = if (!is.null(by)) var_label(data, by, labels),
                  note = if (nzchar(note)) note else NULL)
}

#' Cross-tabulation of counts
#'
#' Counts by two variables (e.g. cases by week and age group, or organism
#' by health board), with totals and optional row or column percentages.
#' Render it with [phw_flextable()] or [phw_reactable()], or colour it with
#' [phw_flextable_heat()].
#'
#' @param data A data frame with one row per case, or with a count column.
#' @param rows,cols Column names for the rows and columns of the table.
#' @param count Optional column of counts (for aggregated data).
#' @param percent `"none"`, `"row"`, `"column"` or `"total"`.
#' @param totals Add a total row and column?
#' @param missing Label for missing values, or `NULL` to drop them.
#' @param digits Decimal places for percentages.
#' @param labels Named list of display names for `rows` and `cols`.
#' @return A `phw_summary` data frame. With `percent = "none"`, count
#'   columns are numeric, so they sort and right-align properly.
#' @examples
#' df <- data.frame(period = sample(1:6, 300, TRUE),
#'                  group = sample(c("Group A", "Group B", "Group C"), 300, TRUE))
#' phw_crosstab(df, "period", "group")
#' phw_crosstab(df, "group", "period", percent = "row")
#' @export
phw_crosstab <- function(data, rows, cols, count = NULL,
                         percent = c("none", "row", "column", "total"), totals = TRUE,
                         missing = "Unknown", digits = 1, labels = list()) {
  percent <- rlang::arg_match(percent)
  data <- as.data.frame(data)
  r <- as_levels(data[[rows]], missing)
  k <- as_levels(data[[cols]], missing)
  w <- if (is.null(count)) rep(1, nrow(data)) else data[[count]]
  tab <- stats::xtabs(w ~ r + k)
  m <- matrix(as.numeric(tab), nrow = nrow(tab), dimnames = dimnames(tab))
  if (totals) {
    m <- cbind(m, Total = rowSums(m))
    m <- rbind(m, Total = colSums(m))
  }
  body <- if (percent == "none") {
    as.data.frame(m, check.names = FALSE)
  } else {
    row_tot <- if (totals) m[, ncol(m)] else rowSums(m)
    col_tot <- if (totals) m[nrow(m), ] else colSums(m)
    grand <- if (totals) m[nrow(m), ncol(m)] else sum(m)
    den <- switch(percent,
      row = matrix(row_tot, nrow(m), ncol(m)),
      column = matrix(col_tot, nrow(m), ncol(m), byrow = TRUE),
      total = matrix(grand, nrow(m), ncol(m)))
    out <- matrix(fmt_pct(m, den, digits), nrow(m), dimnames = dimnames(m))
    as.data.frame(out, check.names = FALSE, stringsAsFactors = FALSE)
  }
  df <- cbind(stats::setNames(data.frame(rownames(m), check.names = FALSE), var_label(data, rows, labels)), body)
  types <- rep("level0", nrow(df))
  if (totals) types[nrow(df)] <- "total"
  new_phw_summary(df, types, spanner = var_label(data, cols, labels),
                  note = if (percent != "none") sprintf("n (%% of %s)", percent) else NULL)
}

#' Rates with confidence intervals by group
#'
#' Rates per population (e.g. per 100,000) with exact Poisson confidence
#' intervals, for one or more grouping variables such as age group, sex,
#' deprivation quintile or risk factor. With several grouping variables,
#' each one becomes a section with its own heading, as in a demographic
#' breakdown of infection rates.
#'
#' @param data Aggregated data: one row per group (or finer), with columns
#'   of case counts and population. Rows are summed within each group.
#' @param groups Grouping columns. Each gets its own section.
#' @param cases,population Columns holding counts and denominators.
#' @param per Rate multiplier, e.g. `1e5` for per 100,000.
#' @param conf_level Confidence level for the intervals.
#' @param digits Decimal places for rates.
#' @param labels Named list of display names for the grouping columns.
#' @param total Add an overall row at the top?
#' @param rate_label Heading for the rate column. Defaults to "Rate per
#'   100,000" (or whatever `per` is).
#' @return A `phw_summary` data frame with numeric Cases, Population and
#'   Rate columns and a text confidence interval column.
#' @details Intervals use the exact (Garwood) method based on the chi-square
#'   distribution, which works for small counts, including zero.
#' @examples
#' d <- expand.grid(age_group = c("0-14", "15-44", "45-64", "65+"),
#'                  sex = c("Female", "Male"))
#' d$cases <- c(12, 30, 41, 66, 10, 28, 45, 70)
#' d$pop <- c(250, 600, 400, 300, 260, 590, 390, 260) * 1000
#' phw_rate_table(d, c("age_group", "sex"), "cases", "pop",
#'                labels = list(age_group = "Age group", sex = "Sex"))
#' @export
phw_rate_table <- function(data, groups, cases, population, per = 1e5, conf_level = 0.95,
                           digits = 1, labels = list(), total = TRUE, rate_label = NULL) {
  data <- as.data.frame(data)
  rate_label <- rate_label %||% paste("Rate per", fmt_n(per))
  ci_label <- sprintf("%s%% CI", 100 * conf_level)
  one <- function(lab, cs, pop, type) {
    ci <- phw_poisson_ci(cs, conf_level)
    data.frame(label = lab, cases = cs, population = pop, rate = round(per * cs / pop, digits),
               ci = sprintf("%s to %s", fmt_num(per * ci$lower / pop, digits), fmt_num(per * ci$upper / pop, digits)),
               type = type, stringsAsFactors = FALSE)
  }
  out <- list()
  if (total) out[[1]] <- one("Total", sum(data[[cases]]), sum(data[[population]]), "total")
  for (g in groups) {
    f <- as_levels(data[[g]], "Unknown")
    cs <- tapply(data[[cases]], f, sum)
    pop <- tapply(data[[population]], f, sum)
    out[[length(out) + 1]] <- data.frame(label = var_label(data, g, labels), cases = NA, population = NA,
                                         rate = NA, ci = "", type = "variable")
    out[[length(out) + 1]] <- one(names(cs), as.numeric(cs), as.numeric(pop), "level")
  }
  df <- do.call(rbind, out)
  types <- df$type
  df <- df[, c("label", "cases", "population", "rate", "ci")]
  names(df) <- c("Group", "Cases", "Population", rate_label, ci_label)
  new_phw_summary(df, types, note = "Confidence intervals use the exact Poisson method.")
}

#' Exact Poisson confidence interval for a count
#'
#' @param x Counts.
#' @param conf_level Confidence level.
#' @return A data frame with `lower` and `upper`.
#' @examples
#' phw_poisson_ci(c(0, 5, 120))
#' @export
phw_poisson_ci <- function(x, conf_level = 0.95) {
  a <- (1 - conf_level) / 2
  data.frame(lower = ifelse(x == 0, 0, stats::qchisq(a, 2 * x) / 2),
             upper = stats::qchisq(1 - a, 2 * (x + 1)) / 2)
}

#' Attack rates and relative risks by exposure
#'
#' The standard outbreak investigation table: for each exposure (a food, a
#' setting, a risk factor) and each of its levels, the number of people,
#' the number who became cases, the attack rate, and the relative risk
#' against the reference level with a confidence interval and Fisher's
#' exact p-value.
#'
#' @param data A data frame with one row per person.
#' @param exposures Exposure columns. Logical or yes/no columns work best;
#'   the first level (or `FALSE`/"No") is the reference.
#' @param outcome Outcome column: logical, 0/1 or yes/no (case = `TRUE`, 1
#'   or "Yes").
#' @param labels Named list of display names for exposures.
#' @param conf_level Confidence level.
#' @param digits Decimal places.
#' @param p_value Add a p-value column?
#' @return A `phw_summary` data frame.
#' @examples
#' set.seed(1)
#' d <- data.frame(item_a = sample(c("Yes", "No"), 120, TRUE),
#'                 item_b = sample(c("Yes", "No"), 120, TRUE))
#' d$ill <- rbinom(120, 1, ifelse(d$item_a == "Yes", 0.5, 0.15))
#' phw_risk_table(d, c("item_a", "item_b"), "ill",
#'                labels = list(item_a = "Item A", item_b = "Item B"))
#' @export
phw_risk_table <- function(data, exposures, outcome, labels = list(), conf_level = 0.95,
                           digits = 1, p_value = TRUE) {
  data <- as.data.frame(data)
  y <- data[[outcome]]
  y <- if (is.logical(y)) y else if (is.numeric(y)) y == 1 else tolower(as.character(y)) %in% c("yes", "y", "true", "1", "case")
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  out <- list(); types <- character()
  for (e in exposures) {
    x <- data[[e]]
    f <- if (is.logical(x)) factor(x, c(FALSE, TRUE), c("No", "Yes")) else {
      lv <- unique(stats::na.omit(as.character(x)))
      if (all(tolower(lv) %in% c("yes", "no"))) factor(x, c(lv[tolower(lv) == "no"], lv[tolower(lv) == "yes"])) else factor(x)
    }
    keep <- !is.na(f) & !is.na(y)
    f <- droplevels(f[keep]); yy <- y[keep]
    n <- as.numeric(table(f)); c <- as.numeric(tapply(yy, f, sum))
    ar <- c / n
    ref <- 1
    rr <- ar / ar[ref]
    se <- sqrt(1 / c - 1 / n + 1 / c[ref] - 1 / n[ref])
    lo <- exp(log(rr) - z * se); hi <- exp(log(rr) + z * se)
    p <- if (p_value && nlevels(f) > 1) {
      tryCatch(stats::fisher.test(table(f, yy))$p.value, error = function(err) stats::chisq.test(table(f, yy))$p.value)
    } else NA
    out[[length(out) + 1]] <- data.frame(label = var_label(data, e, labels), n = NA, cases = NA, ar = NA,
                                         rr = "", ci = "", p = "")
    types <- c(types, "variable")
    out[[length(out) + 1]] <- data.frame(
      label = levels(f), n = n, cases = c, ar = round(100 * ar, digits),
      rr = ifelse(seq_along(n) == ref, "1 (reference)", fmt_num(rr, 2)),
      ci = ifelse(seq_along(n) == ref | !is.finite(lo) | !is.finite(hi), "",
                  sprintf("%s to %s", fmt_num(lo, 2), fmt_num(hi, 2))),
      p = c("", rep(if (is.na(p)) "" else format.pval(p, digits = 2, eps = 0.001), length(n) - 1)))
    types <- c(types, rep("level", length(n)))
  }
  df <- do.call(rbind, out)
  names(df) <- c("Exposure", "People", "Cases", "Attack rate (%)", "Relative risk",
                 sprintf("%s%% CI", 100 * conf_level), "p-value")
  if (!p_value) df[["p-value"]] <- NULL
  new_phw_summary(df, types, note = if (p_value) "p-values from Fisher's exact test." else NULL)
}
