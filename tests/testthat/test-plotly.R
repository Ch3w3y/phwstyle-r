skip_if_not_installed("plotly")

built <- function(p) plotly::plotly_build(p)$x
groups_df <- data.frame(week = rep(1:3, 2), cases = 1:6, group = rep(c("A", "B"), each = 3))

test_that("a trace that maps color to groups takes the palette", {
  p <- plotly::plot_ly(groups_df, x = ~week, y = ~cases, color = ~group, type = "scatter", mode = "lines")
  cols <- vapply(built(phw_plotly(p))$data, function(t) t$line$color, "")
  expect_equal(cols, c("rgba(40,80,135,1)", "rgba(36,162,181,1)"))
  fn <- vapply(built(phw_plotly(p, palette = function(n) c("#000000", "#FF0000")[seq_len(n)]))$data,
               function(t) t$line$color, "")
  expect_equal(fn, c("rgba(0,0,0,1)", "rgba(255,0,0,1)"))
})

test_that("heatmaps get the PHW sequential scale unless one is set", {
  hm <- built(phw_plotly(plotly::plot_ly(z = volcano, type = "heatmap")))$data[[1]]$colorscale
  expect_equal(hm[1, 2], "rgba(232,237,244,1)")
  own <- built(phw_plotly(plotly::plot_ly(z = volcano, type = "heatmap", colorscale = "Greys")))$data[[1]]
  expect_equal(own$colorscale, "Greys")
})

test_that("user annotations are added after the caption", {
  p <- plotly::plot_ly(groups_df, x = ~week, y = ~cases, type = "scatter", mode = "lines")
  note <- list(text = "note", x = 1, y = 1, showarrow = FALSE)
  texts <- vapply(built(phw_plotly(p, source = "S", annotations = list(note)))$layout$annotations,
                  function(a) a$text, "")
  expect_equal(texts, c("<b>Source: S</b>", "note"))
  one <- built(phw_plotly(p, annotations = note))$layout$annotations
  expect_equal(one[[1]]$text, "note")
})

test_that("a sequential palette leaves out its near-white steps for traces", {
  p <- plotly::plot_ly(groups_df, x = ~week, y = ~cases, type = "scatter", mode = "lines")
  way <- unlist(built(phw_plotly(p, palette = "blues"))$layout$colorway)
  expect_equal(way[1], phw_palettes$blues[2])
})

test_that("a missing pie label shows as NA in grey", {
  pie <- plotly::plot_ly(data.frame(l = c("a", NA, "b"), v = 1:3), labels = ~l, values = ~v, type = "pie")
  tr <- built(phw_plotly(pie))$data[[1]]
  expect_equal(as.character(tr$labels), c("a", "NA", "b"))
  expect_equal(tr$marker$colors[2], phw_colours[["grey_light"]])
})

test_that("p and caption_args are checked at entry", {
  p <- plotly::plot_ly(groups_df, x = ~week, y = ~cases, type = "scatter", mode = "lines")
  expect_error(phw_plotly(data.frame()), "must be a plotly chart or a ggplot")
  expect_error(phw_plotly(p, caption_args = list(nope = 1)), "Not `phw_caption\\(\\)` argument")
})

test_that("phw_plotly_colorscale takes a function and checks n", {
  sc <- phw_plotly_colorscale(function(n) rep("#123456", n), n = 3)
  expect_equal(sc[[3]][[2]], "#123456")
  expect_error(phw_plotly_colorscale(n = 0), "2 or more")
})
