test_that("phw_epicurve fills empty periods and stacks groups", {
  d <- data.frame(onset = as.Date(c("2025-01-06", "2025-01-07", "2025-01-27", "2025-01-28")),
                  g = c("A", "B", "A", "A"))
  p <- phw_epicurve(d, "onset", group = "g")
  expect_s3_class(p, "ggplot")
  # Weeks of 6, 13, 20 and 27 January, two groups each.
  expect_equal(nrow(p$data), 8)
  expect_equal(sum(p$data$n), 4)
  expect_equal(p$data$n[p$data$period == as.Date("2025-01-13")], c(0, 0))
  m <- phw_epicurve(d, "onset", interval = "month")
  expect_equal(m$data$n, 4)
  expect_equal(floor_period(as.Date("2025-05-17"), "quarter"), as.Date("2025-04-01"))
  expect_silent(ggplot2::ggplot_build(p))
})

test_that("phw_pyramid puts one sex on each side", {
  pop <- expand.grid(age = factor(c("0-14", "15+"), c("0-14", "15+")), sex = c("F", "M"))
  pop$n <- c(10, 30, 20, 40)
  p <- phw_pyramid(pop, "age", "sex", value = "n", percent = TRUE, left = "M", compare = pop)
  expect_true(all(p$data$x[p$data$sex == "M"] < 0))
  expect_equal(sum(abs(p$data$x)), 100)
  expect_error(phw_pyramid(transform(pop, sex = "F"), "age", "sex"), "exactly two")
  expect_silent(ggplot2::ggplot_build(p))
})

test_that("phw_funnel flags units outside the limits", {
  d <- data.frame(u = letters[1:5], n = c(1000, 1000, 1000, 1000, 1000), e = c(100, 100, 100, 100, 300))
  p <- phw_funnel(d, "e", "n", label = "u")
  expect_equal(as.character(p$data$zone[5]), "Above 99.8%")
  expect_true(all(p$data$zone[1:4] %in% c("Within limits", "Below 95%", "Below 99.8%")))
  expect_equal(phw_funnel(d, "e", "n", type = "rate", target = 10000)$data$value[1], 10000)
  expect_silent(ggplot2::ggplot_build(p))
})

test_that("phw_spc finds limits, shifts and trends", {
  v <- c(10, 11, 9, 10, 11, 9, 10, 30, 10, 11, 12, 12, 12, 12, 12, 12, 12)
  d <- data.frame(t = seq_along(v), v = v)
  p <- phw_spc(d, "t", "v", improvement = "decrease")
  expect_equal(as.character(p$data$signal[8]), "Concern")
  tr <- data.frame(t = 1:10, v = c(5, 5, 1, 2, 3, 4, 5, 6, 5, 5))
  expect_true(all(phw_spc(tr, "t", "v", type = "run")$data$signal[3:8] == "Special cause"))
  expect_silent(ggplot2::ggplot_build(p))
})

test_that("ready-made charts follow the settings given to use_phw_ggplot()", {
  library(ggplot2)
  local_ggplot_state()
  d <- data.frame(onset = as.Date("2025-01-06") + 0:20, g = rep(c("A", "B", "C"), 7))
  # With no setup they use the theme_phw() defaults.
  expect_equal(phw_epicurve(d, "onset")$theme$text$size, 11)
  use_phw_ggplot(base_size = 15, strip = "navy")
  p <- phw_epicurve(d, "onset", group = "g")
  expect_equal(p$theme$text$size, 15)
  expect_equal(p$theme$strip.background$fill, phw_colours[["navy"]])
  # Each chart still chooses its own gridlines.
  expect_s3_class(p$theme$panel.grid.major.y, "element_line")
  expect_s3_class(p$theme$panel.grid.major.x, "element_blank")
  pop <- data.frame(age = c("0-39", "40+", "0-39", "40+"), sex = c("F", "F", "M", "M"), n = 1:4)
  expect_s3_class(phw_pyramid(pop, "age", "sex", value = "n")$theme$panel.grid.major.x, "element_line")
  # Once the session theme is something else, they go back to the defaults.
  theme_set(theme_grey())
  expect_equal(phw_epicurve(d, "onset")$theme$text$size, 11)
})
