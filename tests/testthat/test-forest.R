units <- data.frame(
  area = c("A", "B", "C", "D"),
  est = c(70, 50, 60, 40),
  lo = c(65, 45, 52, 35),
  hi = c(75, 55, 68, 44))

test_that("phw_forest compares each interval with the target", {
  p <- phw_forest(units, est, lo, hi, label = area, target = 60)
  expect_s3_class(p, "ggplot")
  expect_equal(levels(p$data$compared), c("Higher", "Similar", "Lower"))
  got <- stats::setNames(as.character(p$data$compared), p$data$area)
  expect_equal(got[c("A", "B", "C", "D")], c(A = "Higher", B = "Lower", C = "Similar", D = "Lower"))
  expect_silent(ggplot2::ggplot_build(p))
})

test_that("phw_forest sorts units by value", {
  p <- phw_forest(units, "est", "lo", "hi", "area", target = 60)
  expect_equal(p$data$area, c("D", "B", "C", "A"))
})

test_that("phw_forest renames the comparison levels", {
  p <- phw_forest(units, est, lo, hi, area, target = 60, labels = c(Higher = "Above Wales", Lower = "Below Wales"))
  expect_equal(levels(p$data$compared), c("Above Wales", "Similar", "Below Wales"))
  expect_equal(as.character(p$data$compared[p$data$area == "A"]), "Above Wales")
  expect_error(phw_forest(units, est, lo, hi, area, target = 60, labels = c(Bigger = "x")), "Bigger")
})

test_that("phw_forest without a target draws every unit alike", {
  p <- phw_forest(units, est, lo, hi, area)
  expect_false("compared" %in% names(p$data))
  b <- ggplot2::ggplot_build(p)
  expect_equal(unique(b$data[[2]]$colour), phw_colours[["navy"]])
  expect_equal(p$labels$x, "est")
})

test_that("phw_forest rejects intervals that do not contain the value", {
  bad <- units
  bad$lo[2] <- 52
  expect_error(phw_forest(bad, est, lo, hi, area), "between")
})

test_that("phw_forest leaves out units with a missing estimate or interval", {
  d <- units
  d$lo[2] <- NA
  expect_message(p <- phw_forest(d, est, lo, hi, label = area, target = 60), "Left out 1 row")
  expect_equal(sort(p$data$area), c("A", "C", "D"))
  expect_false(anyNA(p$data$compared))
  expect_error(phw_forest(units[0, ], est, lo, hi, label = area), "no rows")
  expect_error(phw_forest(units, est, lo, hi, label = area, target = NA), "one number")
})

test_that("phw_forest needs numeric columns, labels and one target", {
  expect_error(phw_forest(transform(units, est = as.character(est)), est, lo, hi, label = area), "numeric column")
  expect_error(phw_forest(transform(units, area = c(NA, "B", "C", "D")), est, lo, hi, label = area), "missing")
  expect_error(phw_forest(units, est, lo, hi, label = area, target = c(50, 60)), "one number")
})

test_that("phw_forest repeats units across facets quietly, but says when a unit repeats in a panel", {
  d <- data.frame(area = rep(c("A", "B", "C"), 2), yr = rep(c(2024, 2025), each = 3),
                  v = c(50, 60, 70, 55, 65, 75))
  d$lo <- d$v - 5
  d$hi <- d$v + 5
  p <- phw_forest(d, v, lo, hi, area, target = 60) + ggplot2::facet_wrap(~yr)
  expect_silent(b <- ggplot2::ggplot_build(p))
  expect_equal(nrow(ggplot2::layer_data(p, 2)), 6)
  expect_message(ggplot2::ggplot_build(phw_forest(d, v, lo, hi, area, target = 60)),
                 "more than one row")
})

test_that("units left off the y axis are not reported as repeats", {
  d <- data.frame(area = c("A", "B", "C", "D"), v = c(50, 60, 70, 80))
  d$lo <- d$v - 5
  d$hi <- d$v + 5
  p <- phw_forest(d, v, lo, hi, area, target = 60) + ggplot2::scale_y_discrete(limits = c("A", "B"))
  msgs <- character()
  withCallingHandlers(suppressWarnings(ggplot2::ggplot_build(p)),
                      message = function(m) { msgs <<- c(msgs, conditionMessage(m)); invokeRestart("muffleMessage") })
  expect_false(any(grepl("more than one row", msgs)))
})
