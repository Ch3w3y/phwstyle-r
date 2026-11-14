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
  expect_length(phw_pal(12, "extended"), 12)
  expect_error(phw_pal(13, "extended"), "has 12 colours")
  expect_error(phw_pal(13), "has 12 colours")
  expect_error(phw_pal(3, "highlight"), "has 2 colours")
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

test_that("extended is built from sourced colours first and stays distinguishable", {
  ext <- phw_palettes$extended
  expect_length(ext, 12)
  expect_false(anyDuplicated(toupper(ext)) > 0)
  expect_equal(ext[1:4], phw_palettes$main)
  # 5 to 7 have a published source, 8 and 9 are from the Long-Term Strategy.
  expect_equal(ext[5:7], unname(phw_colours[c("black", "green", "gold_465")]))
  expect_equal(ext[8:9], unname(phw_colours[c("mint", "green_bright")]))
  # Seven, and all twelve, keep every pair apart for colour-blind readers.
  for (n in c(7, 12)) {
    res <- suppressMessages(phw_check_colours(ext[seq_len(n)], min_distance = 15))
    expect_true(all(res$pass[res$vision != "tritanopia"]), info = paste(n, "colours"))
  }
  # The neutral grey is kept for "Other" and "Unknown", not used as a group colour.
  expect_false(phw_colours[["grey_mid"]] %in% ext)
})

test_that("the strategy and greens palettes work as extra options", {
  expect_named(phw_palettes$strategy, c("services", "system", "behaviours", "wellbeing", "determinants", "climate"))
  expect_length(phw_pal(palette = "strategy"), 6)
  expect_error(phw_pal(7, "strategy"), "6 colours")
  # Sequential: interpolates to any length and gets darker step by step.
  g <- phw_pal(9, "greens")
  expect_length(g, 9)
  ends <- grDevices::col2rgb(g[c(1, 9)]) - grDevices::col2rgb(phw_palettes$greens[c(1, 6)])
  expect_true(all(abs(ends) <= 1))
  lum <- phw_contrast(phw_palettes$greens, "#FFFFFF")
  expect_true(all(diff(lum) > 0))
  expect_equal(phw_pal(4), unname(phw_colours[c("navy", "teal", "orange", "pink")]))
})

test_that("the strategy and greens palettes work through the scales", {
  library(ggplot2)
  d <- data.frame(x = 1:6, g = letters[1:6], v = c(1, 3, 5, 7, 9, 11))
  p <- ggplot(d, aes(x, v, fill = g)) + geom_col() + scale_fill_phw_d(palette = "strategy")
  expect_setequal(layer_data(p)$fill, unname(phw_palettes$strategy))
  p <- ggplot(d, aes(x, v, fill = v)) + geom_col() + scale_fill_phw_c("greens")
  f <- layer_data(p)$fill
  ends <- grDevices::col2rgb(f[c(1, 6)]) - grDevices::col2rgb(phw_palettes$greens[c(1, 6)])
  expect_true(all(abs(ends) <= 1))
  expect_error(scale_fill_phw_c("strategy"), "qualitative")
})

test_that("palettes for groups start with the same colours in the same order", {
  navy <- phw_colours[["navy"]]
  for (nm in c("main", "extended", "accessible", "highlight")) {
    expect_equal(unname(phw_palettes[[nm]])[1], navy, info = nm)
  }
  for (nm in c("main", "extended", "accessible")) {
    expect_equal(unname(phw_palettes[[nm]])[1:3], unname(phw_colours[c("navy", "teal", "orange")]), info = nm)
  }
  # "strategy" has its own shades, in the same hue order as "main": each of
  # its first four colours is closest to the matching colour in "main".
  lab <- function(x) grDevices::convertColor(t(grDevices::col2rgb(x)) / 255, "sRGB", "Lab")
  s <- lab(phw_palettes$strategy[1:4])
  m <- lab(phw_palettes$main)
  nearest <- apply(s, 1, function(r) which.min(sqrt(colSums((t(m) - r)^2))))
  expect_equal(unname(nearest), 1:4)
  # The default single-series colour is the first palette colour.
  expect_equal(phw_pal(1), navy)
})

test_that("missing colours stay missing in the colour tools", {
  expect_equal(phw_contrast(NA), NA_real_)
  expect_equal(phw_text_on(c(NA, "#285087")), c(NA, "#FFFFFF"))
  expect_equal(phw_cvd(c(NA, "#285087"))[1], NA_character_)
  expect_error(phw_check_colours(c("#285087", NA, "#FF5D0C")), "must be colours: NA")
})

test_that("the colour tools take palette names and name bad input", {
  expect_length(phw_contrast("main"), 4)
  expect_length(phw_cvd("main"), 4)
  expect_error(phw_check_colours("nope"), "not a colour or a palette name")
  expect_error(phw_check_colours(function(n) 1:n), "must be colours or a palette name")
  expect_error(phw_check_colours(c("#285087", "notacolour")), "\"notacolour\" is not")
})

test_that("show_phw_palettes names an unknown palette", {
  expect_error(show_phw_palettes(c("main", "nope")), "must be one of")
  expect_error(show_phw_palettes(character()), "at least one palette")
})

test_that("phw_pal checks its colours, n and reverse", {
  expect_error(phw_pal(2, c("#285087", NA)), "must be a palette name")
  expect_error(phw_pal(3, function(n) 1:n), "must return colours")
  expect_error(phw_pal(NA), "`n` must be one number")
  expect_error(phw_pal(2, reverse = NA), "`reverse` must be")
})
