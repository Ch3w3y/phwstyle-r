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

trace_colours <- function(p) {
  d <- built(phw_plotly(p))$data
  stats::setNames(vapply(d, function(t) t$marker$color, ""), vapply(d, function(t) t$name, ""))
}
ggplot_colours <- function(df) {
  g <- ggplot2::ggplot(df, ggplot2::aes(x, y, colour = grp)) + ggplot2::geom_point() + scale_colour_phw_d()
  cols <- ggplot2::layer_data(g)$colour
  grp <- as.character(df$grp)
  grp[is.na(grp)] <- "NA"
  stats::setNames(plotly::toRGB(cols), grp)
}

test_that("plot_ly groups take the colours the ggplot2 scales give them", {
  na <- data.frame(x = 1:4, y = 1:4, grp = c("A", "B", NA, "C"))
  p <- plotly::plot_ly(na, x = ~x, y = ~y, color = ~grp, type = "scatter", mode = "markers")
  cols <- trace_colours(p)
  expect_equal(cols[["NA"]], plotly::toRGB(phw_colours[["grey_light"]]))
  expect_equal(cols, ggplot_colours(na)[names(cols)])

  unused <- data.frame(x = 1:2, y = 1:2, grp = factor(c("Low", "High"), levels = c("Low", "Mid", "High")))
  p <- plotly::plot_ly(unused, x = ~x, y = ~y, color = ~grp, type = "bar")
  cols <- trace_colours(p)
  expect_equal(cols, ggplot_colours(unused)[names(cols)])
  expect_equal(cols[["High"]], plotly::toRGB(phw_colours[["teal"]]))
})

test_that("plot_ly gives each of many groups its own colour, with a warning", {
  withr::local_options(rlib_warning_verbosity = "verbose")
  many <- data.frame(x = 1:14, y = 1:14, grp = sprintf("G%02d", 1:14))
  p <- plotly::plot_ly(many, x = ~x, y = ~y, color = ~grp, type = "scatter", mode = "markers")
  expect_match(testthat::capture_warnings(cols <- trace_colours(p)), "run out")
  expect_equal(cols[["G02"]], plotly::toRGB(phw_colours[["teal"]]))
  expect_equal(cols, suppressWarnings(ggplot_colours(many))[names(cols)])
  expect_length(unique(cols), 14)
})

test_that("pie slices are coloured by group, as in the other charts", {
  df <- data.frame(lab = factor(c("Zeta", "Alpha", "Mid"), levels = c("Alpha", "Mid", "Zeta")), n = c(5, 3, 2))
  tr <- built(phw_plotly(plotly::plot_ly(df, labels = ~lab, values = ~n, type = "pie")))$data[[1]]
  bars <- trace_colours(plotly::plot_ly(df, x = ~lab, y = ~n, color = ~lab, type = "bar"))
  expect_equal(plotly::toRGB(tr$marker$colors), unname(bars[as.character(tr$labels)]))
  expect_equal(tr$marker$colors[as.character(tr$labels) == "Alpha"], phw_colours[["navy"]])
})

test_that("traces with their own data share one set of group colours", {
  d1 <- data.frame(x = 1:2, y = 1:2, grp = c("A", "B"))
  d2 <- data.frame(x = 3:4, y = 3:4, grp = c("C", NA))
  p <- plotly::plot_ly() |>
    plotly::add_trace(data = d1, x = ~x, y = ~y, color = ~grp, type = "scatter", mode = "markers") |>
    plotly::add_trace(data = d2, x = ~x, y = ~y, color = ~grp, type = "scatter", mode = "markers")
  cols <- trace_colours(p)
  expect_equal(cols, ggplot_colours(rbind(d1, d2))[names(cols)])
})
