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

test_that("traces without a colour mapping spread over a sequential or diverging palette without its near-white steps", {
  d <- data.frame(week = rep(1:3, 3), cases = 1:9, g = rep(c("A", "B", "C"), each = 3))
  split <- plotly::plot_ly(d, x = ~week, y = ~cases, split = ~g, type = "scatter", mode = "lines")
  added <- plotly::plot_ly(d[1:3, ], x = ~week, y = ~cases, type = "scatter", mode = "lines") |>
    plotly::add_lines(y = ~ cases * 2) |>
    plotly::add_lines(y = ~ cases * 3)
  visible <- list(blues = phw_palettes$blues[-1], orange_navy = phw_palettes$orange_navy[-4])
  for (pal in names(visible)) {
    want <- plotly::toRGB(phw_pal(3, visible[[pal]], type = "sequential"))
    for (p in list(split, added, plotly::subplot(added))) {
      cols <- vapply(built(phw_plotly(p, palette = pal))$data, function(t) unclass(t$line$color), "")
      expect_equal(cols, want)
    }
  }
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
  expect_error(phw_plotly(p, caption_args = list(nope = 1)), "unknown name")
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

test_that("a sequential or diverging palette spreads over plot_ly groups, as in the ggplot2 scales", {
  d <- data.frame(x = 1:3, y = 1:3, g = c("a", "b", "c"))
  for (pal in c("blues", "orange_navy")) {
    gg <- ggplot2::ggplot(d, ggplot2::aes(g, y, fill = g)) + ggplot2::geom_col() + scale_fill_phw_d(palette = pal)
    want <- plotly::toRGB(ggplot2::layer_data(gg)$fill)
    expect_equal(want, plotly::toRGB(phw_pal(3, pal)))
    bars <- plotly::plot_ly(d, x = ~x, y = ~y, color = ~g, type = "bar")
    tr <- built(phw_plotly(bars, palette = pal))$data
    expect_equal(vapply(tr, function(t) t$marker$color, ""), want)
    tr <- built(phw_plotly(plotly::subplot(bars), palette = pal))$data
    expect_equal(vapply(tr, function(t) unclass(t$marker$color), ""), want)
    pie <- built(phw_plotly(plotly::plot_ly(d, labels = ~g, values = ~y, type = "pie"), palette = pal))$data[[1]]
    expect_equal(plotly::toRGB(pie$marker$colors), want)
  }
})

test_that("a colour key keeps missing groups visible in grey", {
  na <- data.frame(x = 1:4, y = 1:4, grp = c("A", "B", NA, "A"))
  key <- phw_colour_key(na$grp, "grp")
  p <- plotly::plot_ly(na, x = ~x, y = ~y, color = ~grp, colors = key, type = "scatter", mode = "markers")
  cols <- trace_colours(p)
  expect_equal(cols, stats::setNames(plotly::toRGB(c(key, phw_colours[["grey_light"]])), c(names(key), "NA")))
  expect_equal(cols, ggplot_colours(na)[names(cols)])

  own <- c(key, "NA" = "#000000")
  p <- plotly::plot_ly(na, x = ~x, y = ~y, color = ~grp, colors = own, type = "scatter", mode = "markers")
  expect_equal(trace_colours(p)[["NA"]], plotly::toRGB("#000000"))
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

test_that("a ggplot without a colour scale draws the same colours static and in plotly", {
  local_ggplot_state()
  use_phw_ggplot()
  df <- data.frame(x = 1:5, y = 1:5, v = c(0, 25, 50, 75, 100), g = c("A", "Other", "B", NA, "A"))
  static <- function(p, aes) {
    g <- as.character(df$g)
    g[is.na(g)] <- "NA"
    stats::setNames(plotly::toRGB(ggplot2::layer_data(p)[[aes]]), g)
  }

  ramp <- ggplot2::ggplot(df, ggplot2::aes(x, y, colour = v)) + ggplot2::geom_point()
  drawn <- unlist(lapply(built(phw_plotly(ramp))$data, function(t) t$marker$color))
  expect_equal(drawn[seq_len(nrow(df))], unname(static(ramp, "colour")))

  points <- ggplot2::ggplot(df, ggplot2::aes(x, y, colour = g)) + ggplot2::geom_point()
  cols <- trace_colours(points)
  expect_equal(cols, static(points, "colour")[names(cols)])

  bars <- ggplot2::ggplot(df, ggplot2::aes(x, y, fill = g)) + ggplot2::geom_col()
  cols <- trace_colours(bars)
  expect_equal(cols, static(bars, "fill")[names(cols)])
})

test_that("a ggplot without a colour scale takes `palette`, as plot_ly() does", {
  df <- data.frame(x = rep(1:2, 5), y = 1:10, g = rep(LETTERS[1:5], each = 2))
  drawn <- function(p, palette, part) {
    vapply(built(phw_plotly(p, palette = palette))$data, function(t) t[[part]]$color, "")
  }
  lines <- ggplot2::ggplot(df, ggplot2::aes(x, y, colour = g)) + ggplot2::geom_line()
  bars <- ggplot2::ggplot(df, ggplot2::aes(x, y, fill = g)) + ggplot2::geom_col()
  plotly_lines <- plotly::plot_ly(df, x = ~x, y = ~y, color = ~g, type = "scatter", mode = "lines")
  plotly_bars <- plotly::plot_ly(df, x = ~x, y = ~y, color = ~g, type = "bar")
  for (pal in list("accessible", c("#000000", "#FF0000", "#00FF00", "#0000FF", "#FFFF00"))) {
    expect_equal(drawn(lines, pal, "line"), drawn(plotly_lines, pal, "line"))
    expect_equal(drawn(bars, pal, "marker"), drawn(plotly_bars, pal, "marker"))
  }

  own <- lines + scale_colour_phw_d(palette = "main")
  expect_equal(drawn(own, "accessible", "line"), drawn(plotly_lines, "main", "line"))
})

test_that("subplot() panels take the PHW colours, and a group keeps its colour across panels", {
  d <- data.frame(week = rep(1:3, 3), y = 1:9, g = rep(c("a", "b", "c"), each = 3))
  s <- plotly::subplot(
    plotly::plot_ly(d, x = ~week, y = ~y, color = ~g, type = "bar"),
    plotly::plot_ly(d[d$g != "a", ], x = ~week, y = ~y, color = ~g, type = "scatter", mode = "lines", fill = "tozeroy"),
    plotly::plot_ly(d, x = ~week, y = ~y, type = "scatter", mode = "lines"),
    plotly::plot_ly(z = volcano, type = "heatmap")
  )
  expect_no_warning(tr <- built(phw_plotly(s))$data)
  key <- phw_colour_key(c("a", "b", "c"))
  key <- stats::setNames(plotly::toRGB(key), names(key))
  expect_equal(vapply(tr[1:3], function(t) t$marker$color, ""), unname(key))
  expect_equal(vapply(tr[4:5], function(t) t$line$color, ""), unname(key[c("b", "c")]))
  expect_equal(unclass(tr[[4]]$fillcolor), plotly::toRGB(phw_colour_key(c("a", "b", "c"))[["b"]], 0.5))
  expect_equal(unclass(tr[[6]]$line$color), plotly::toRGB(phw_pal(6)[6]))
  alone <- built(phw_plotly(plotly::plot_ly(z = volcano, type = "heatmap")))$data[[1]]$colorscale
  expect_equal(tr[[7]]$colorscale[, 2], alone[, 2])
})

test_that("subplot() draws a missing group in grey, as each panel alone does", {
  d <- data.frame(week = rep(1:2, 4), y = 1:8, g = rep(c("a", "b", "c", NA), each = 2))
  lines <- plotly::plot_ly(d, x = ~week, y = ~y, color = ~g, type = "scatter", mode = "lines",
                           fill = "tozeroy", alpha = 0.6)
  bars <- plotly::plot_ly(d, x = ~week, y = ~y, color = ~g, type = "bar")
  colours <- function(t) unlist(lapply(list(t$line$color, t$fillcolor, t$marker$color), unclass))
  expect_no_warning(tr <- built(phw_plotly(plotly::subplot(lines, bars)))$data)
  missing <- tr[vapply(tr, function(t) identical(t$name, "NA"), logical(1))]
  expect_equal(colours(missing[[1]]), colours(built(phw_plotly(lines))$data[[4]]))
  expect_equal(colours(missing[[2]]), colours(built(phw_plotly(bars))$data[[4]]))
  grey <- phw_colours[["grey_light"]]
  expect_equal(colours(missing[[1]])[1:2], c(plotly::toRGB(grey), plotly::toRGB(grey, 0.6)))
})

test_that("subplot() keeps colours a panel sets, and says how to colour the rest", {
  d <- data.frame(week = rep(1:3, 2), y = 1:6, g = rep(c("a", "b"), each = 3))
  own <- plotly::plot_ly(d, x = ~week, y = ~y, color = ~g, colors = c("red", "blue"), type = "bar")
  mapped <- plotly::plot_ly(d, x = ~week, y = ~y, color = ~g, type = "bar")
  expect_no_message(tr <- built(phw_plotly(plotly::subplot(own)))$data)
  expect_equal(vapply(tr, function(t) t$marker$color, ""), c("rgba(255,0,0,1)", "rgba(0,0,255,1)"))
  expect_message(phw_plotly(plotly::subplot(own, mapped)), "Style each panel")
  styled <- built(phw_plotly(plotly::subplot(phw_plotly(own), phw_plotly(mapped))))$data
  expect_equal(vapply(styled[3:4], function(t) t$marker$color, ""),
               unname(plotly::toRGB(phw_colour_key(c("a", "b")))))
})

title_text <- function(t) unclass(if (is.list(t)) t$text else t)

test_that("plot_ly titles keep their text and take the PHW style", {
  p <- plotly::plot_ly(data.frame(week = 1:10, cases = 1:10), x = ~week, y = ~cases, type = "bar")
  titled <- plotly::layout(p, title = "Cases by week", xaxis = list(title = "Week of onset"),
                           yaxis = list(title = "Cases"))
  l <- built(phw_plotly(titled))$layout
  expect_equal(title_text(l$title), "Cases by week")
  expect_equal(l$title$font$color, phw_colours[["navy"]])
  expect_equal(title_text(l$xaxis$title), "Week of onset")
  expect_equal(title_text(l$yaxis$title), "Cases")
  expect_equal(l$xaxis$color, phw_colours[["text_secondary"]])
  auto <- built(phw_plotly(p))$layout
  expect_equal(title_text(auto$xaxis$title), "week")
  expect_equal(title_text(auto$yaxis$title), "cases")
})

test_that("ggplot axis titles keep their text in the PHW colour", {
  g <- ggplot2::ggplot(groups_df, ggplot2::aes(week, cases, colour = group)) +
    ggplot2::geom_line() + ggplot2::labs(title = "Cases", x = "Week")
  l <- built(phw_plotly(g))$layout
  expect_equal(title_text(l$title), "Cases")
  expect_equal(l$title$font$color, phw_colours[["navy"]])
  expect_equal(l$xaxis$title$text, "Week")
  expect_equal(l$xaxis$title$font$color, phw_colours[["text_secondary"]])
})

test_that("legend sets where a legend goes, not whether one trace gets one", {
  one <- plotly::plot_ly(groups_df, x = ~week, y = ~cases, type = "bar")
  expect_false(built(phw_plotly(one))$layout$showlegend)
  two <- plotly::plot_ly(groups_df, x = ~week, y = ~cases, color = ~group, type = "bar")
  expect_true(built(phw_plotly(two))$layout$showlegend)
  expect_false(built(phw_plotly(two, legend = "none"))$layout$showlegend)
})

test_that("a bottom legend is stacked under the axis title, and the source under it, when drawn", {
  p <- plotly::plot_ly(groups_df, x = ~week, y = ~cases, color = ~group, type = "scatter", mode = "lines")
  hook <- function(w) w$jsHooks$render
  with_source <- hook(phw_plotly(p, source = "S", margin = list(b = 150)))
  expect_length(with_source, 1)
  expect_match(with_source[[1]]$code, "plotly_afterplot", fixed = TRUE)
  expect_equal(with_source[[1]]$data, list(margin = 150))
  expect_equal(hook(phw_plotly(p))[[1]]$data, list(margin = 0))
  expect_null(hook(phw_plotly(p, source = "S", legend = "right")))
  expect_null(hook(phw_plotly(p, legend = "none")))
})

test_that("the source line is the one annotation the legend hook moves, wherever it lands", {
  source_of <- function(w) {
    anns <- built(w)$layout$annotations
    vapply(Filter(function(a) identical(a$name, "phw_source"), anns), function(a) a$text, "")
  }
  note <- list(text = "Note", x = 2, y = 3, showarrow = FALSE)
  earlier <- plotly::layout(plotly::plot_ly(groups_df, x = ~week, y = ~cases, color = ~group,
                                            type = "scatter", mode = "lines"), annotations = list(note))
  expect_equal(source_of(phw_plotly(earlier, source = "S")), "<b>Source: S</b>")
  skip_if_not_installed("ggplot2")
  faceted <- ggplot2::ggplot(groups_df, ggplot2::aes(week, cases, colour = group)) +
    ggplot2::geom_line() + ggplot2::facet_wrap(~group)
  expect_equal(source_of(phw_plotly(faceted, source = "S")), "<b>Source: S</b>")
  expect_length(source_of(phw_plotly(faceted)), 0)
})
