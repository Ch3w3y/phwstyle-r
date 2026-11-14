test_that("header_args override the title and subtitle by name", {
  skip_if_not_installed("bslib")
  html <- as.character(phw_page_navbar(bslib::nav_panel("A", "x"), title = "T", subtitle = "s",
                                       header_args = list(subtitle = "Other")))
  expect_match(html, 'href="https://phw.nhs.wales/"', fixed = TRUE)
  expect_match(html, '<div class="phw-header-title">T</div>', fixed = TRUE)
  expect_match(html, '<div class="phw-header-subtitle">Other</div>', fixed = TRUE)
  expect_error(phw_page_navbar(header_args = "x"), "must be a list")
})

test_that("phw_bs_theme takes Bootstrap 4 or 5 only", {
  skip_if_not_installed("bslib")
  expect_s3_class(phw_bs_theme(4), "bs_theme")
  expect_error(phw_bs_theme(3), "must be one of")
  expect_error(phw_bs_theme("red"), "must be one of")
})

test_that("phw_header needs one line of text", {
  expect_error(phw_header(c("a", "b")), "one line of text")
  expect_error(phw_header(NA), "one line of text")
  expect_error(phw_header("T", subtitle = NA), "`subtitle`")
})
