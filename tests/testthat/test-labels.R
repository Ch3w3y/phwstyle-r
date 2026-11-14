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

test_that("a missing or empty source, date or note is left out of the caption", {
  expect_null(phw_caption(NA))
  expect_null(phw_caption(""))
  expect_null(phw_caption(character(0)))
  expect_null(phw_caption(date = as.Date(NA)))
  expect_equal(phw_caption("X", date = NA, note = ""), "Source: X")
})

test_that("caption_args with a misspelt name stops, naming it", {
  expect_error(caption_from("X", NULL, list(sorce_prefix = "D: ")), "sorce_prefix")
  expect_error(caption_from("X", NULL, "note"), "must be a list")
  expect_equal(caption_from("X", NULL, list(source_prefix = "D: ")), "D: X")
})

test_that("phw_date takes dates and ISO text, stops on other text and keeps NA", {
  expect_equal(phw_date("2026-11-03"), "03/11/2026")
  expect_equal(phw_date(as.POSIXct("2026-11-03 10:00", tz = "UTC")), "03/11/2026")
  expect_error(phw_date("03/11/2026"), "not an ISO date")
  expect_error(phw_date(46000), "must be a Date")
  expect_identical(phw_date(NA, "long"), NA_character_)
  expect_identical(phw_date(as.Date(c("2026-11-03", NA)), "long"), c("3 November 2026", NA))
  expect_identical(phw_date(NA), NA_character_)
})
