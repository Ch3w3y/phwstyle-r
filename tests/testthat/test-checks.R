user_fn <- function(data, col) {
  check_has_rows(data)
  data <- drop_missing(data, col)
  as_date_col(data, col)
}

test_that("dates are read only from Date, POSIXct or ISO text", {
  d <- data.frame(when = c("2026-11-14", NA, "2026-11-15T10:00:00"))
  expect_equal(as_date_col(d, "when"), as.Date(c("2026-11-14", NA, "2026-11-15")))
  expect_equal(as_date_col(data.frame(when = as.POSIXct("2026-11-14 23:30", tz = "UTC")), "when"),
               as.Date("2026-11-14"))
  expect_error(as_date_col(data.frame(when = "05/01/2026"), "when"), "05/01/2026")
  expect_error(as_date_col(data.frame(when = 1:2), "when"), "must be a Date, a date-time or ISO text")
})

test_that("drop_missing says how many rows went and stops when none are left", {
  d <- data.frame(when = as.Date("2026-01-01") + 0:2, n = c(1, NA, Inf))
  expect_message(out <- drop_missing(d, c("when", "n")), "Left out 2 rows")
  expect_equal(nrow(out), 1)
  expect_silent(drop_missing(d[1, ], "n"))
  expect_error(drop_missing(d[2:3, ], "n"), "Every row")
})

test_that("the messages name the user's function", {
  d <- data.frame(when = as.Date(c("2026-01-01", NA)))
  expect_message(user_fn(d, "when"), "user_fn\\(\\): Left out 1 row")
  cnd <- expect_error(user_fn(d[0, , drop = FALSE], "when"), "has no rows")
  expect_equal(rlang::call_name(cnd$call), "user_fn")
})

test_that("numeric columns and colours are checked", {
  expect_error(check_numeric_col(data.frame(v = "1"), "v", "value"), "must be a numeric column")
  expect_silent(check_numeric_col(data.frame(v = 1), "v"))
  expect_error(check_colours(c("#285087", NA, "nope"), "fixed"), "NA.*nope")
  expect_silent(check_colours(c("#285087", "navy"), "fixed"))
})
