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

test_that("phw_epicurve draws a trailing average of the total count", {
  d <- data.frame(onset = as.Date("2025-01-01") + c(0, 1, 1, 2, 2, 2, 3, 3, 3, 3), g = rep(c("A", "B"), 5))
  p <- phw_epicurve(d, "onset", group = "g", interval = "day", average = 3)
  # Daily totals 1, 2, 3, 4.
  expect_equal(unique(p$data[c("period", "average")])$average, c(NA, NA, 2, 3))
  expect_equal(p$data$average[p$data$period == as.Date("2025-01-03")], c(2, 2))
  expect_equal(names(p$data), c("period", "group", "n", "average"))
  b <- ggplot2::ggplot_build(p)
  line <- b$data[[length(b$data)]]
  expect_equal(line$y, c(NA, NA, 2, 3))
  line <- line[!is.na(line$y), ]
  expect_equal(line$y, c(2, 3))
  expect_equal(line$x, as.numeric(as.Date(c("2025-01-03", "2025-01-04"))) + 0.45)
  expect_equal(b$plot$scales$get_scales("colour")$get_labels(), "3-day average")
})

test_that("phw_epicurve names the average line from the interval or average_label", {
  d <- data.frame(onset = as.Date("2025-01-06") + 7 * 0:5)
  label <- function(p) ggplot2::ggplot_build(p)$plot$scales$get_scales("colour")$get_labels()
  expect_equal(label(phw_epicurve(d, "onset", average = 4)), "4-week average")
  expect_equal(label(phw_epicurve(d, "onset", average = 2, average_label = "Moving mean")), "Moving mean")
})

test_that("phw_epicurve rejects an average that is not a whole number of periods", {
  d <- data.frame(onset = as.Date("2025-01-06"))
  expect_error(phw_epicurve(d, "onset", average = 2.5), "whole number")
  expect_error(phw_epicurve(d, "onset", average = 0), "whole number")
  expect_error(phw_epicurve(d, "onset", average = "7"), "whole number")
})

test_that("phw_epicurve without average keeps its columns", {
  d <- data.frame(onset = as.Date("2025-01-06") + 0:20, g = rep(c("A", "B"), length.out = 21))
  p <- phw_epicurve(d, "onset", group = "g")
  expect_equal(names(p$data), c("period", "group", "n"))
  expect_length(p$layers, 1)
})

test_that("phw_funnel and phw_spc levels can be renamed and keep their colours", {
  set.seed(1)
  d <- data.frame(u = letters[1:30], n = round(runif(30, 100, 4000)))
  d$e <- rbinom(30, d$n, 0.2)
  d$e[1] <- d$n[1]
  points <- function(p) ggplot2::get_layer_data(p, which(vapply(p$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))[1])
  def <- phw_funnel(d, e, n)
  p <- phw_funnel(d, e, n, labels = c("Within limits" = "Gerllaw'r terfynau"), size = 4)
  expect_true("Gerllaw'r terfynau" %in% levels(p$data$zone))
  expect_false("Within limits" %in% levels(p$data$zone))
  expect_equal(points(p)$colour, points(def)$colour)
  expect_equal(points(p)$shape, points(def)$shape)
  expect_true(all(points(p)$size == 4))
  expect_error(phw_funnel(d, e, n, labels = c(Nope = "x")), "Nope")

  t <- data.frame(t = 1:12, v = c(5, 6, 5, 6, 5, 6, 5, 6, 5, 6, 5, 40))
  s0 <- phw_spc(t, t, v, improvement = "decrease")
  s1 <- phw_spc(t, t, v, improvement = "decrease", size = 5,
                labels = c("Common cause" = "Achos cyffredin", Concern = "Pryder"))
  expect_equal(levels(s1$data$signal), c("Achos cyffredin", "Special cause", "Improvement", "Pryder"))
  expect_equal(as.character(s1$data$signal[12]), "Pryder")
  expect_equal(points(s1)$colour, points(s0)$colour)
  expect_equal(points(s1)$shape, points(s0)$shape)
  expect_true(all(points(s1)$size == 5))
  expect_error(phw_spc(t, t, v, labels = c(Bad = "x")), "Bad")
  expect_error(phw_spc(t, t, v, labels = c("Common cause" = "Same", "Concern" = "Same")), "same text")
})
