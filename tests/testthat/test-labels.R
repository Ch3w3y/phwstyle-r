test_that("captions are built and every word can be changed", {
  expect_equal(phw_caption("Example system, 2024"), "Source: Example system, 2024")
  expect_equal(phw_caption(date = as.Date("2026-11-03")), "Data correct as of 03/11/2026")
  expect_equal(phw_caption("X", source_prefix = "Ffynhonnell: "), "Ffynhonnell: X")
  expect_equal(phw_caption("X", note = "Provisional", sep = " | "), "Source: X | Provisional")
  expect_equal(phw_caption(date = "week 44"), "Data correct as of week 44")
  expect_null(phw_caption())
})

test_that("dates format", {
  expect_equal(phw_date(as.Date("2026-11-03"), "long"), "3 November 2026")
  expect_equal(phw_date(as.Date("2026-11-03"), "%Y"), "2026")
})

test_that("number formatters work", {
  expect_equal(phw_number()(1234.4), "1,234")
  expect_equal(phw_percent()(0.432), "43.2%")
})
