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
