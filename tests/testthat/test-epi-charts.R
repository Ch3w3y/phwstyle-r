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
  points <- function(p) ggplot2::layer_data(p, which(vapply(p$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))[1])
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

test_that("phw_epicurve keeps its default date labels within the data", {
  d <- data.frame(day = seq(as.Date("2025-03-01"), by = "day", length.out = 60), n = 1)
  p <- phw_epicurve(d, day, count = n, interval = "day")
  b <- stats::na.omit(ggplot2::ggplot_build(p)$layout$panel_params[[1]]$x$get_breaks())
  expect_gt(length(b), 2)
  expect_true(all(b >= as.numeric(min(d$day)) & b <= as.numeric(max(d$day))))
})

test_that("phw_epicurve stops on dates written as text in another format", {
  d <- data.frame(onset = c("01/02/2025", "03/02/2025"))
  expect_error(phw_epicurve(d, onset), "must hold dates")
  iso <- phw_epicurve(data.frame(onset = c("2025-02-03", "2025-02-04")), onset)
  expect_equal(iso$data$period, as.Date("2025-02-03"))
})

test_that("phw_epicurve leaves out rows with a missing count and says so", {
  d <- data.frame(onset = as.Date(c("2025-01-06", "2025-01-07", "2025-01-13")), n = c(5, NA, 3))
  expect_message(p <- phw_epicurve(d, onset, count = n), "Left out 1 row")
  expect_equal(p$data$n, c(5, 3))
})

test_that("phw_epicurve checks its data, range, count and average at entry", {
  d <- data.frame(onset = as.Date("2025-01-06") + 7 * 0:2, n = 1:3)
  expect_error(phw_epicurve(d[0, ], onset), "no rows")
  expect_error(phw_epicurve(transform(d, onset = as.Date(NA)), onset), "Every row")
  expect_error(phw_epicurve(d, onset, range = as.Date(c(NA, "2025-02-01"))), "start first")
  expect_error(phw_epicurve(d, onset, range = as.Date(c("2025-02-01", "2025-01-01"))), "start first")
  expect_error(phw_epicurve(d, onset, range = as.Date("2025-01-01")), "two dates")
  expect_error(phw_epicurve(transform(d, n = as.character(n)), onset, count = n), "numeric column")
  expect_message(p <- phw_epicurve(d, onset, average = 50), "No average line")
  expect_true(all(is.na(p$data$average)))
  expect_length(p$layers, 1)
})

test_that("phw_epicurve says how many rows have no date or fall outside range", {
  d <- data.frame(onset = as.Date("2025-01-06") + c(NA, NA, 0, 7, 70))
  expect_message(phw_epicurve(d, onset), "Left out 2 rows with a missing value")
  r <- as.Date(c("2025-01-06", "2025-01-31"))
  expect_message(expect_message(p <- phw_epicurve(d, onset, range = r), "missing value"),
                 "Left out 1 row dated outside")
  expect_equal(sum(p$data$n), 2)
})

test_that("phw_epicurve drops empty groups unless keyed, and refuses negative counts", {
  d <- data.frame(onset = as.Date("2025-01-06") + 0:1,
                  g = factor(c("A", "B"), c("A", "B", "Unused")), n = c(2, 3))
  expect_equal(levels(phw_epicurve(d, onset, group = g)$data$group), c("A", "B"))
  withr::defer(phw_key_reset("epi_unused_test"))
  expect_equal(levels(phw_epicurve(d, onset, group = g, key = "epi_unused_test")$data$group),
               c("A", "B", "Unused"))
  expect_error(phw_epicurve(transform(d, n = c(2, -1)), onset, count = n), "negative")
})

test_that("width in ... changes the bars of phw_epicurve and phw_pyramid", {
  d <- data.frame(onset = as.Date("2025-01-06") + 7 * 0:2)
  b <- ggplot2::layer_data(phw_epicurve(d, onset, width = 3))
  expect_equal(unique(b$xmax - b$xmin), 3)
  pop <- data.frame(age = c("0-39", "40+", "0-39", "40+"), sex = c("F", "F", "M", "M"), n = 1:4)
  b <- ggplot2::layer_data(phw_pyramid(pop, age, sex, value = n, width = 0.4))
  expect_equal(unique(round(b$ymax - b$ymin, 6)), 0.4)
})

pyr <- data.frame(age = rep(c("0-39", "40+"), 2), sex = rep(c("Female", "Male"), each = 2), n = c(10, 20, 30, 40))

test_that("phw_pyramid leaves out rows with a missing value and keeps percentages", {
  d <- rbind(pyr, data.frame(age = "40+", sex = "Male", n = NA))
  expect_message(p <- phw_pyramid(d, age, sex, value = n, percent = TRUE), "Left out 1 row")
  expect_equal(sum(abs(p$data$x)), 100)
  d <- rbind(pyr, data.frame(age = NA, sex = "Male", n = 5), data.frame(age = "40+", sex = NA, n = 5))
  expect_message(phw_pyramid(d, age, sex, value = n), "Left out 2 rows")
})

test_that("phw_pyramid stops on negative values", {
  expect_error(phw_pyramid(transform(pyr, n = c(-50, 20, 30, 40)), age, sex, value = n), "negative")
})

test_that("phw_pyramid stops when left is not a sex value", {
  expect_error(phw_pyramid(pyr, age, sex, value = n, left = "male"), "must be one of")
  expect_true(all(phw_pyramid(pyr, age, sex, value = n, left = "Male")$data$x[3:4] < 0))
})

test_that("phw_pyramid checks data and compare at entry", {
  expect_error(phw_pyramid(pyr[0, ], age, sex, value = n), "no rows")
  expect_error(phw_pyramid(transform(pyr, n = as.character(n)), age, sex, value = n), "numeric column")
  expect_error(phw_pyramid(pyr, age, sex, value = n, compare = pyr[c("age", "sex")]), "no n column")
  expect_error(phw_pyramid(pyr, age, sex, value = n, compare = transform(pyr, sex = rep(c("F", "M"), each = 2))),
               "same sex values")
})

fun <- data.frame(u = letters[1:6], n = c(500, 800, 1000, 1500, 2000, 3000), e = c(40, 90, 100, 160, 190, 330))

test_that("phw_funnel leaves out unusable rows and stops when the target is 0", {
  expect_message(p <- phw_funnel(transform(fun, e = c(NA, e[-1])), e, n), "Left out 1 row with a missing")
  expect_equal(nrow(p$data), 5)
  expect_message(p <- phw_funnel(transform(fun, n = c(0, n[-1])), e, n), "Left out 1 row where n is 0")
  expect_equal(nrow(p$data), 5)
  expect_error(phw_funnel(transform(fun, e = 0), e, n), "overall value is 0")
  expect_error(phw_funnel(fun[0, ], e, n), "no rows")
})

test_that("phw_funnel checks limits, target and the columns", {
  expect_error(phw_funnel(fun, e, n, limits = 0.95), "two confidence levels")
  expect_error(phw_funnel(fun, e, n, limits = c(95, 99.8)), "two confidence levels")
  expect_error(phw_funnel(fun, e, n, target = NA), "target")
  expect_error(phw_funnel(fun, e, n, target = 150), "below 100")
  expect_error(phw_funnel(fun, e, n, target = 0), "above 0")
  expect_error(phw_funnel(transform(fun, e = as.character(e)), e, n), "numeric column")
})

test_that("phw_spc needs dates or numbers for x", {
  d <- data.frame(m = c("Jan 2023", "Feb 2023", "Mar 2023"), v = 1:3)
  expect_error(phw_spc(d, m, v), "dates, date-times or numbers")
  expect_s3_class(phw_spc(transform(d, m = as.Date("2023-01-01") + 0:2), m, v), "ggplot")
})

test_that("phw_spc leaves out missing values and needs at least two points", {
  d <- data.frame(t = 1:10, v = c(5, NA, 6, 5, Inf, 6, 5, 6, 5, 6))
  expect_message(p <- phw_spc(d, t, v), "Left out 2 rows")
  expect_equal(nrow(p$data), 8)
  expect_no_warning(ggplot2::ggplot_build(p))
  expect_error(phw_spc(d[1, ], t, v), "at least 2 points")
  expect_error(phw_spc(d[0, ], t, v), "no rows")
  expect_error(phw_spc(d, t, v, baseline = 1), "2 or more")
  expect_error(phw_spc(transform(d, v = as.character(v)), t, v), "numeric column")
})
