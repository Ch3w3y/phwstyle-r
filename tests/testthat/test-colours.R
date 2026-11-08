test_that("brand colours are valid hex codes", {
  expect_true(all(grepl("^#[0-9A-F]{6}$", phw_colours)))
  expect_equal(phw_col("navy", names = FALSE), "#285087")
  expect_error(phw_col("not_a_colour"), "Unknown PHW colour")
})

test_that("official NHS Wales logo colours match the 2022 guidelines", {
  expect_equal(grDevices::col2rgb(phw_colours[["blue_534"]])[, 1], c(red = 50, green = 90, blue = 138))
  expect_equal(grDevices::col2rgb(phw_colours[["gold_465"]])[, 1], c(red = 207, green = 171, blue = 122))
})

test_that("qualitative palettes refuse to invent colours", {
  expect_length(phw_pal(4), 4)
  expect_error(phw_pal(5, "main"), "has 4 colours")
  expect_length(phw_pal(8, "extended"), 8)
})

test_that("sequential palettes interpolate", {
  expect_length(phw_pal(11, "blues"), 11)
  expect_equal(rev(phw_pal(5, "teals")), phw_pal(5, "teals", reverse = TRUE))
})

test_that("text colours meet WCAG AA on white", {
  for (k in c("navy", "blue_534", "text", "text_secondary", "blue", "green", "magenta")) {
    expect_gte(phw_contrast(phw_colours[[k]], "#FFFFFF"), 4.5)
  }
})

test_that("chart and RAG colours meet the 3:1 non-text contrast rule", {
  for (k in c(phw_palettes$main, phw_palettes$rag, phw_palettes$accessible, phw_palettes$rag_accessible)) {
    expect_gte(phw_contrast(k, "#FFFFFF"), 3)
  }
})

test_that("phw_text_on picks readable text", {
  expect_equal(phw_text_on("#285087"), "#FFFFFF")
  expect_equal(phw_text_on("#F0F4F5"), phw_colours[["text"]])
})
