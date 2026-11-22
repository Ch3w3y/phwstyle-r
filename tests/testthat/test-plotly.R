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

test_that("heatmaps get the PHW continuous colours unless a scale is set", {
  hm <- built(phw_plotly(plotly::plot_ly(z = volcano, type = "heatmap")))$data[[1]]$colorscale
  expect_equal(hm[c(1, nrow(hm)), 2], plotly::toRGB(phw_continuous_auto[c(1, 5)]))
  own <- built(phw_plotly(plotly::plot_ly(z = volcano, type = "heatmap", colorscale = "Greys")))$data[[1]]
  expect_equal(own$colorscale, "Greys")
})

test_that("plot_ly charts coloured by a number start at the blue ggplot charts use", {
  d <- data.frame(x = 1:4, y = 1:4, v = c(0, 10, 50, 100))
  gg <- built(phw_plotly(ggplot2::ggplot(d, ggplot2::aes(x, y, colour = v)) + ggplot2::geom_point()))
  start <- gg$data[[1]]$marker$color[[1]]
  pts <- plotly::plot_ly(d, x = ~x, y = ~y, color = ~v, type = "scatter", mode = "markers")
  expect_equal(built(phw_plotly(pts))$data[[1]]$marker$colorscale[1, 2], start)
  both <- built(phw_plotly(plotly::subplot(pts, plotly::plot_ly(d, x = ~x, y = ~y, type = "bar"))))
  expect_equal(both$data[[1]]$marker$colorscale[1, 2], start)
  own <- plotly::plot_ly(d, x = ~x, y = ~y, marker = list(color = ~v), type = "scatter", mode = "markers")
  first <- built(phw_plotly(own))$layout$colorscale$sequential[[1]][[2]]
  expect_lte(max(abs(grDevices::col2rgb(first) - grDevices::col2rgb(phw_continuous_auto[[1]]))), 1)
})

test_that("a missing number is drawn in grey, alone or in a subplot", {
  d <- data.frame(x = 1:3, y = 1:3, rate = c(2, NA, 8))
  grey <- phw_colours[["grey_light"]]
  want <- list(2, grey, 8)
  pts <- plotly::plot_ly(d, x = ~x, y = ~y, color = ~rate, type = "scatter", mode = "markers")
  big <- plotly::plot_ly(d, x = ~x, y = ~y, color = ~rate, size = I(30), type = "scatter", mode = "markers")
  marker <- built(phw_plotly(pts))$data[[1]]$marker
  expect_equal(unclass(marker$color), want, ignore_attr = TRUE)
  expect_equal(unclass(marker$line$color), want, ignore_attr = TRUE)
  # The page plotly.js draws from: a plotly widget, with the grey in its data.
  tags <- htmltools::as.tags(phw_plotly(pts))
  html <- as.character(tags)
  expect_match(html, 'class="plotly html-widget', fixed = TRUE)
  expect_match(html, '"color":[2,"#AEB7BD",8]', fixed = TRUE)
  expect_true("plotly-binding" %in% vapply(htmltools::findDependencies(tags), `[[`, "", "name"))
  combined <- list(plotly::subplot(phw_plotly(pts), phw_plotly(big)), phw_plotly(plotly::subplot(pts, big)))
  for (s in combined) {
    tr <- built(s)$data
    expect_equal(lapply(tr[c(1, 3)], function(t) unclass(t$marker$color)), list(want, want), ignore_attr = TRUE)
  }
})

test_that("a missing heat map cell is drawn in grey, not left white", {
  d <- expand.grid(week = 1:4, age = c("0-14", "15-64", "65+"))
  d$rate <- c(5, 8, NA, 12, 6, 9, 11, 15, 7, NA, 10, 14)
  grey <- phw_colours[["grey_light"]]
  # Each heat map has a grey heat map under it, covering only its missing cells.
  check <- function(tr) {
    heat <- which(vapply(tr, function(t) identical(t$type, "heatmap"), logical(1)))
    expect_length(heat, 2)
    under <- tr[[heat[1]]]
    expect_equal(as.vector(!is.na(under$z)), as.vector(is.na(tr[[heat[2]]]$z)))
    expect_equal(unlist(under$colorscale), c("0", grey, "1", grey), ignore_attr = TRUE)
    expect_false(under$showscale)
    expect_equal(under$hoverinfo, "skip")
    expect_equal(under[c("x", "y")], tr[[heat[2]]][c("x", "y")])
  }
  check(built(phw_plotly(plotly::plot_ly(d, x = ~week, y = ~age, z = ~rate, type = "heatmap")))$data)
  skip_if_not_installed("ggplot2")
  for (geom in list(ggplot2::geom_tile(), ggplot2::geom_raster())) {
    g <- ggplot2::ggplot(d, ggplot2::aes(week, age, fill = rate)) + geom + scale_fill_phw_c()
    check(built(phw_plotly(g))$data)
  }
  # Styling a subplot() of styled heat maps again keeps one grey layer each.
  tr <- built(suppressMessages(phw_plotly(plotly::subplot(phw_plotly(g), phw_plotly(g)))))$data
  under <- Filter(function(t) identical(t$name, "phw_missing"), tr)
  expect_equal(vapply(under, function(t) t$xaxis, ""), c("x", "x2"))
  full <- d
  full$rate[is.na(full$rate)] <- 1
  tr <- built(phw_plotly(plotly::plot_ly(full, x = ~week, y = ~age, z = ~rate, type = "heatmap")))$data
  expect_length(tr, 1)
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

test_that("a patchwork stops and points to subplot()", {
  skip_if_not_installed("patchwork")
  g1 <- ggplot2::ggplot(groups_df, ggplot2::aes(week, cases)) + ggplot2::geom_col()
  g2 <- ggplot2::ggplot(groups_df, ggplot2::aes(week, cases)) + ggplot2::geom_line()
  expect_error(phw_plotly(phw_arrange(g1, g2, title = "Two charts")), "plotly::subplot")
  expect_error(phw_plotly(g1 + g2), "draws one chart")
  expect_error(phw_plotly(g1 / g2), "draws one chart")
})

test_that("the recipe a patchwork error suggests gives a group one colour in every panel", {
  skip_if_not_installed("patchwork")
  g1 <- ggplot2::ggplot(groups_df, ggplot2::aes(week, cases, fill = group)) + ggplot2::geom_col()
  g2 <- ggplot2::ggplot(subset(groups_df, group != "A"), ggplot2::aes(week, cases, colour = group)) +
    ggplot2::geom_line()
  err <- tryCatch(phw_plotly(phw_arrange(g1, g2)), error = identity)
  recipe <- regmatches(err$body, regexpr("phw_plotly\\(plotly::subplot.*\\)", err$body))
  b <- built(eval(parse(text = recipe)))
  expect_equal(b$layout$title$font$color, phw_colours[["navy"]])
  expect_equal(b$layout$title$x, 0)
  tr <- b$data
  colour <- vapply(tr, function(t) t$marker$color %||% t$line$color, "")
  by_group <- tapply(colour, vapply(tr, function(t) t$name, ""), function(x) length(unique(x)))
  expect_true(all(by_group == 1))
  expect_length(by_group, length(unique(groups_df$group)))
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

test_that("highlight greys every plot_ly trace after the first", {
  withr::local_options(phwstyle.palette = "highlight")
  d <- data.frame(x = 1:5, y = 1:5, g = c("a", "b", "c", "d", "e"))
  rgb <- plotly::toRGB(phw_pal(5, "highlight"))
  mapped <- plotly::plot_ly(d, x = ~x, y = ~y, color = ~g, type = "scatter", mode = "markers")
  expect_equal(unname(trace_colours(mapped)), rgb)
  p <- plotly::plot_ly(d, x = ~x)
  for (i in 1:5) p <- plotly::add_lines(p, y = d$y + i, name = letters[i])
  colorway <- built(phw_plotly(p))$layout$colorway
  expect_equal(toupper(unlist(colorway))[1:5], phw_pal(5, "highlight"))
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

test_that("unnamed colors keep missing groups visible in grey", {
  na <- data.frame(x = 1:4, y = 1:4, grp = c("A", "B", NA, "A"))
  grey <- plotly::toRGB(phw_colours[["grey_light"]])
  p <- plotly::plot_ly(na, x = ~x, y = ~y, color = ~grp, colors = phw_pal(2), type = "scatter", mode = "markers")
  expect_equal(trace_colours(p), c(A = plotly::toRGB(phw_pal(2)[[1]]), B = plotly::toRGB(phw_pal(2)[[2]]), "NA" = grey))
  short <- plotly::plot_ly(na, x = ~x, y = ~y, color = ~factor(grp, c("A", "B", "C")), colors = c("#000000", "#FFFFFF"),
                           type = "scatter", mode = "markers")
  full <- plotly::plot_ly(na[!is.na(na$grp), ], x = ~x, y = ~y, color = ~factor(grp, c("A", "B", "C")),
                          colors = c("#000000", "#FFFFFF"), type = "scatter", mode = "markers")
  expect_equal(trace_colours(short), c(trace_colours(full), "NA" = grey))
  brewer <- plotly::plot_ly(na, x = ~x, y = ~y, color = ~grp, colors = "Set1", type = "scatter", mode = "markers")
  expect_equal(trace_colours(brewer)[["NA"]], grey)
  later <- plotly::add_markers(plotly::plot_ly(na, x = ~x, y = ~y, colors = phw_pal(2)), color = ~grp)
  expect_equal(trace_colours(later), trace_colours(p))
  line_colours <- function(d) {
    tr <- built(phw_plotly(plotly::add_lines(plotly::plot_ly(d, x = ~x, y = ~y, colors = phw_pal(2)), color = ~grp)))$data
    stats::setNames(vapply(tr, function(t) t$line$color, ""), vapply(tr, function(t) t$name, ""))
  }
  expect_equal(line_colours(na), c(line_colours(na[!is.na(na$grp), ]), "NA" = grey))
})

test_that("a colour scale on one trace leaves missing groups on another grey", {
  grey <- plotly::toRGB(phw_colours[["grey_light"]])
  tiles <- data.frame(x = rep(1:2, 2), y = rep(1:2, each = 2), z = 1:4)
  pts <- data.frame(x = 1:3, y = 1:3, grp = c("A", "B", NA))
  for (scale in list(phw_plotly_colorscale("teals"), "Viridis")) {
    p <- plotly::add_heatmap(plotly::plot_ly(), data = tiles, x = ~x, y = ~y, z = ~z, colorscale = scale)
    tr <- built(phw_plotly(plotly::add_markers(p, data = pts, x = ~x, y = ~y, color = ~grp)))$data
    expect_equal(tr[[1]]$colorscale, scale)
    expect_equal(tr[[4]]$name, "NA")
    expect_equal(tr[[4]]$marker$color, grey, ignore_attr = TRUE)
  }
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

test_that("pies in one figure give a label the same colour", {
  a <- data.frame(g = c("Cardiff", "Aneurin", "Betsi", "Unknown"), n = c(10, 20, 30, 5))
  b <- data.frame(g = c("Cardiff", "Betsi", NA), n = c(15, 25, 5))
  p <- plotly::plot_ly() |>
    plotly::add_pie(data = a, labels = ~g, values = ~n, domain = list(x = c(0, .45))) |>
    plotly::add_pie(data = b, labels = ~g, values = ~n, domain = list(x = c(.55, 1)))
  tr <- built(phw_plotly(p))$data
  cols <- lapply(tr, function(t) stats::setNames(as.character(unlist(t$marker$colors)), t$labels))
  key <- phw_colour_key(sort(a$g))
  expect_equal(cols[[1]], key[a$g])
  expect_equal(cols[[2]], c(key[c("Cardiff", "Betsi")], "NA" = phw_colours[["grey_light"]]))
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

test_that("groups take the PHW colours after a trace that maps no colour, which keeps its own", {
  wales <- data.frame(week = 1:3, cases = 2:4)
  line <- function(p) plotly::add_lines(p, data = wales, x = ~week, y = ~cases, name = "Wales")
  hb <- function(p, ...) plotly::add_lines(p, data = groups_df, x = ~week, y = ~cases, ...)
  colours <- function(p) {
    tr <- built(phw_plotly(p))$data
    stats::setNames(vapply(tr, function(t) t$line$color, ""), vapply(tr, function(t) t$name, ""))
  }
  after <- colours(plotly::plot_ly() |> line() |> hb(color = ~group))
  before <- colours(plotly::plot_ly() |> hb(color = ~group) |> line())
  expect_equal(after[c("A", "B")], c(A = "rgba(40,80,135,1)", B = "rgba(36,162,181,1)"))
  expect_equal(after[c("A", "B")], before[c("A", "B")])
  expect_false(after[["Wales"]] %in% after[c("A", "B")])
  expect_false(before[["Wales"]] %in% before[c("A", "B")])
  num <- built(phw_plotly(plotly::plot_ly() |> line() |>
                            plotly::add_markers(data = groups_df, x = ~week, y = ~cases, color = ~cases)))
  scale <- num$data[[2]]$marker$colorscale
  expect_equal(scale[c(1, nrow(scale)), 2], plotly::toRGB(phw_continuous_auto[c(1, 5)]))
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

test_that("ggplot groups named in `palette` take their own colour in plotly", {
  df <- data.frame(x = rep(1:2, 3), y = 1:6, status = rep(c("Red", "Amber", "Green"), each = 2))
  drawn <- function(p, palette, part) {
    b <- built(phw_plotly(p, palette = palette))$data
    stats::setNames(vapply(b, function(t) t[[part]]$color, ""), vapply(b, function(t) t$name, ""))
  }
  rag <- plotly::toRGB(phw_palettes$rag[c("red", "amber", "green")])
  named <- c(Red = "#FF0000", Amber = "#FFBF00", Green = "#00FF00")
  lines <- ggplot2::ggplot(df, ggplot2::aes(x, y, colour = status)) + ggplot2::geom_line()
  bars <- ggplot2::ggplot(df, ggplot2::aes(x, y, fill = status)) + ggplot2::geom_col()
  for (pal in list("rag", named)) {
    want <- stats::setNames(if (identical(pal, "rag")) rag else plotly::toRGB(named), c("Red", "Amber", "Green"))
    expect_equal(drawn(lines, pal, "line")[names(want)], want)
    expect_equal(drawn(bars, pal, "marker")[names(want)], want)
  }
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
  expect_equal(unclass(tr[[6]]$line$color), plotly::toRGB(phw_pal(9)[9]))
  alone <- built(phw_plotly(plotly::plot_ly(z = volcano, type = "heatmap")))$data[[1]]$colorscale
  expect_equal(tr[[7]]$colorscale[, 2], alone[, 2])
})

test_that("a subplot() trace that maps no colour never takes a group's colour", {
  wales <- data.frame(week = 1:3, cases = 2:4)
  line <- plotly::plot_ly(wales, x = ~week, y = ~cases, name = "Wales", type = "scatter", mode = "lines")
  hb <- function(...) plotly::plot_ly(groups_df, x = ~week, y = ~cases, type = "scatter", mode = "lines", ...)
  gg <- plotly::ggplotly(ggplot2::ggplot(groups_df, ggplot2::aes(week, cases, colour = group)) + ggplot2::geom_line())
  colours <- function(s) {
    tr <- built(phw_plotly(s))$data
    stats::setNames(vapply(tr, function(t) t$line$color, ""), vapply(tr, function(t) t$name, ""))
  }
  key <- plotly::toRGB(phw_colour_key(c("A", "B")))
  for (s in list(plotly::subplot(line, hb(color = ~group)),
                 plotly::subplot(hb(color = ~group), line),
                 # plotly warns that both figures have a config.
                 suppressWarnings(plotly::subplot(line, gg)),
                 plotly::subplot(line, hb(color = ~group, colors = phw_colour_key(c("A", "B")))),
                 plotly::subplot(phw_plotly(line), phw_plotly(hb(color = ~group))))) {
    cols <- colours(s)
    expect_equal(unname(cols[c("A", "B")]), unname(key))
    expect_false(cols[["Wales"]] %in% key)
  }
})

test_that("subplot() colours groups from the data when a column shares a name with an object", {
  withr::local_options(rlib_warning_verbosity = "verbose")
  d <- data.frame(week = rep(1:3, 2), y = 1:6, class = rep(c("a", "b"), each = 3))
  d$g <- d$class
  g <- letters
  for (col in c("class", "g")) {
    f <- stats::as.formula(paste0("~", col))
    s <- plotly::subplot(
      plotly::plot_ly(d, x = ~week, y = ~y, color = f, type = "bar"),
      plotly::plot_ly(d, x = ~week, y = ~y, color = f, type = "scatter", mode = "lines")
    )
    expect_no_warning(tr <- built(phw_plotly(s))$data)
    key <- plotly::toRGB(phw_colour_key(c("a", "b")))
    expect_equal(vapply(tr[1:2], function(t) t$marker$color, ""), unname(key))
    expect_equal(vapply(tr[3:4], function(t) t$line$color, ""), unname(key))
  }
  pies <- plotly::subplot(
    plotly::plot_ly(data.frame(labels = c("a", "b"), n = 1:2), labels = ~labels, values = ~n, type = "pie")
  )
  # plotly itself warns about the layout of a subplot() of pies.
  expect_no_error(suppressWarnings(built(phw_plotly(pies))))
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

test_that("subplot() draws a missing group in grey when the panels set their own colours", {
  d <- data.frame(week = rep(1:2, 3), y = 1:6, g = rep(c("a", "b", NA), each = 2))
  colours <- function(t) unlist(lapply(list(t$line$color, t$fillcolor, t$marker$color), unclass))
  for (cols in list(phw_colour_key(d$g), phw_pal())) {
    lines <- plotly::plot_ly(d, x = ~week, y = ~y, color = ~g, colors = cols, type = "scatter",
                             mode = "lines", fill = "tozeroy", alpha = 0.6)
    bars <- plotly::plot_ly(d, x = ~week, y = ~y, color = ~g, colors = cols, type = "bar")
    tr <- built(phw_plotly(plotly::subplot(lines, bars)))$data
    na <- vapply(tr, function(t) identical(t$name, "NA"), logical(1))
    expect_equal(lapply(tr[na], colours),
                 list(colours(built(phw_plotly(lines))$data[[3]]), colours(built(phw_plotly(bars))$data[[3]])))
    expect_equal(lapply(tr[!na], colours),
                 lapply(c(built(phw_plotly(lines))$data[1:2], built(phw_plotly(bars))$data[1:2]), colours))
  }
})

test_that("subplot() of ggplots gives groups the PHW colours, the same in every panel", {
  skip_if_not_installed("ggplot2")
  d <- data.frame(x = rep(1:3, 3), y = 1:9, g = rep(c("A", "B", "C"), each = 3))
  lines <- ggplot2::ggplot(d, ggplot2::aes(x, y, colour = g)) + ggplot2::geom_line()
  bars <- ggplot2::ggplot(d[d$g != "A", ], ggplot2::aes(x, y, fill = g)) + ggplot2::geom_col()
  key <- phw_colour_key(c("A", "B", "C"))
  key <- stats::setNames(plotly::toRGB(key), names(key))
  colours <- function(tr) {
    stats::setNames(vapply(tr, function(t) unclass(t$line$color %||% t$marker$color), ""),
                    vapply(tr, function(t) t$name, ""))
  }
  tr <- built(phw_plotly(plotly::subplot(lines, bars)))$data
  expect_equal(colours(tr), key[c("A", "B", "C", "B", "C")])
  expect_equal(colours(built(phw_plotly(plotly::ggplotly(lines)))$data), key)

  points <- ggplot2::ggplot(d, ggplot2::aes(x, y, colour = g, shape = factor(x))) + ggplot2::geom_point()
  tr <- built(phw_plotly(plotly::subplot(points, lines)))$data
  expect_equal(unname(colours(tr)), unname(key[c(rep(c("A", "B", "C"), each = 3), "A", "B", "C")]))

  own <- lines + ggplot2::scale_colour_manual(values = c("red", "blue", "black"))
  expect_equal(unname(colours(built(phw_plotly(plotly::subplot(own, bars)))$data)[1:3]),
               c("rgba(255,0,0,1)", "rgba(0,0,255,1)", "rgba(0,0,0,1)"))
})

test_that("subplot() lists each group once in the legend, and its entry shows and hides every panel", {
  skip_if_not_installed("ggplot2")
  d <- data.frame(week = rep(1:4, 3), v = 1:12, hb = rep(c("Cardiff", "Swansea", "Powys"), each = 4))
  legend_of <- function(w) {
    tr <- built(suppressMessages(w))$data
    shown <- Filter(function(t) !isFALSE(t$showlegend), tr)
    group <- vapply(tr, function(t) t$legendgroup %||% NA_character_, "")
    list(names = vapply(shown, function(t) t$name, ""),
         panels = vapply(shown, function(t) sum(group == t$legendgroup, na.rm = TRUE), 1))
  }
  g1 <- ggplot2::ggplot(d, ggplot2::aes(week, v, colour = hb)) + ggplot2::geom_line()
  g2 <- ggplot2::ggplot(d, ggplot2::aes(week, v * 2, colour = hb)) + ggplot2::geom_line()
  pl <- function(y) plotly::plot_ly(d, x = ~week, y = y, color = ~hb, type = "scatter", mode = "lines")
  bars <- ggplot2::ggplot(d, ggplot2::aes(hb, v, fill = hb)) + ggplot2::geom_col()
  for (s in list(plotly::subplot(g1, g2), plotly::subplot(plotly::ggplotly(g1), plotly::ggplotly(g2)),
                 plotly::subplot(pl(~v), pl(~v * 2)), plotly::subplot(g1, bars))) {
    expect_equal(legend_of(phw_plotly(s)), list(names = c("Cardiff", "Powys", "Swansea"), panels = c(2, 2, 2)))
  }

  # Lines that share a name but not a colour are told apart in the legend.
  target <- function(y) plotly::plot_ly(d, x = ~week, y = y, name = "Target", type = "scatter", mode = "lines")
  expect_equal(legend_of(phw_plotly(plotly::subplot(target(~v), target(~v * 2))))$names, c("Target", "Target"))
})

test_that("subplot() of ggplots with an average line keeps plain legend names and one colour per group", {
  skip_if_not_installed("ggplot2")
  names_colours <- function(w) {
    tr <- built(w)$data
    stats::setNames(vapply(tr, function(t) unclass(t$marker$color %||% t$line$color), ""),
                    vapply(tr, function(t) t$name, ""))
  }
  cases <- data.frame(onset = as.Date("2026-01-01") + rep(0:20, 3), area = rep(c("A", "B", "C"), each = 21))
  e <- phw_epicurve(cases, onset, group = area, average = 3)
  bars <- ggplot2::ggplot(cases, ggplot2::aes(onset, fill = area)) + ggplot2::geom_histogram(bins = 5)
  alone <- names_colours(phw_plotly(e))
  both <- names_colours(phw_plotly(plotly::subplot(e, bars)))
  expect_equal(names(both), c("A", "B", "C", "3-week average", "A", "B", "C"))
  expect_equal(both[1:4], alone)
  expect_equal(both[5:7], alone[1:3])

  # The average maps a colour of its own, which ggplot2 gives the hue of the
  # first fill group.
  tot <- data.frame(onset = unique(cases$onset), n = 3)
  hand <- ggplot2::ggplot(cases, ggplot2::aes(onset)) + ggplot2::geom_bar(ggplot2::aes(fill = area)) +
    ggplot2::geom_line(data = tot, ggplot2::aes(onset, n, colour = "Average"))
  both <- names_colours(phw_plotly(plotly::subplot(hand, bars)))
  expect_equal(names(both), c("A", "B", "C", "Average", "A", "B", "C"))
  expect_equal(both[5:7], both[1:3])
  expect_false(both[["Average"]] %in% both[1:3])

  two <- data.frame(x = 1:4, y = 1:4, a = c("A", "A", "B", "B"), s = c("1", "2", "1", "2"))
  shapes <- ggplot2::ggplot(two, ggplot2::aes(x, y, colour = a, shape = s)) + ggplot2::geom_point()
  expect_equal(names(names_colours(phw_plotly(plotly::subplot(shapes, shapes))))[1:4],
               c("(A,1)", "(A,2)", "(B,1)", "(B,2)"))

  # A line named "A" and points named "(A,1)" are one group.
  two$s <- c("a", "b", "a", "b")
  lined <- ggplot2::ggplot(two, ggplot2::aes(x, y, colour = a)) + ggplot2::geom_point(ggplot2::aes(shape = s)) +
    ggplot2::geom_line()
  joined <- names_colours(phw_plotly(plotly::ggplotly(lined)))
  expect_equal(names(joined), c("(a,A)", "(a,B)", "(b,A)", "(b,B)", "A", "B"))
  expect_equal(unname(joined[5:6]), unname(joined[1:2]))
})

test_that("ggplotly() charts coloured by a number take the PHW blues, as phw_plotly(g) does", {
  skip_if_not_installed("ggplot2")
  d <- expand.grid(week = 1:4, area = c("A", "B", "C"))
  d$rate <- 1:12
  rgb <- function(x) {
    vapply(x, function(v) {
      if (startsWith(v, "#")) as.numeric(grDevices::col2rgb(v))
      else as.numeric(strsplit(gsub("^rgba\\(|\\)$", "", v), ",")[[1]][1:3])
    }, numeric(3), USE.NAMES = FALSE)
  }
  tiles <- ggplot2::ggplot(d, ggplot2::aes(week, area, fill = rate)) + ggplot2::geom_tile()
  scale <- built(phw_plotly(plotly::ggplotly(tiles)))$data[[1]]$colorscale
  expect_equal(scale[[2]][c(1, 12)], c(phw_palettes$blues[[2]], phw_palettes$blues[[6]]), ignore_attr = TRUE)
  expect_lte(max(abs(rgb(scale[[2]]) - rgb(built(phw_plotly(tiles))$data[[1]]$colorscale[[2]]))), 1)

  points <- ggplot2::ggplot(d, ggplot2::aes(week, rate, colour = rate)) + ggplot2::geom_point() +
    ggplot2::geom_hline(yintercept = 3, colour = "steelblue")
  tr <- built(phw_plotly(plotly::ggplotly(points)))$data
  expect_lte(max(abs(rgb(tr[[1]]$marker$color) - rgb(built(phw_plotly(points))$data[[1]]$marker$color))), 1)
  expect_equal(tr[[2]]$line$color, plotly::toRGB("steelblue"), ignore_attr = TRUE)
})

test_that("a ggplot's own continuous scale keeps its colours where it crosses ggplot2's default gradient", {
  skip_if_not_installed("ggplot2")
  d <- data.frame(x = seq(0, 100, length.out = 400), y = 1)
  g <- ggplot2::ggplot(d, ggplot2::aes(x, y, colour = x)) + ggplot2::geom_point() +
    scale_colour_phw_c(palette = "gradient")
  own <- built(plotly::ggplotly(g))$data[[1]]$marker$color
  expect_equal(built(phw_plotly(g))$data[[1]]$marker$color, own, ignore_attr = TRUE)
  expect_equal(built(phw_plotly(plotly::ggplotly(g)))$data[[1]]$marker$color, own, ignore_attr = TRUE)
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

test_that("a ggplot's subtitle goes under its title and its caption becomes the source line", {
  g <- ggplot2::ggplot(groups_df, ggplot2::aes(week, cases, colour = group)) + ggplot2::geom_line() +
    ggplot2::labs(title = "Cases", subtitle = "Wales\n2026", caption = phw_caption("Example data"))
  l <- built(phw_plotly(g))$layout
  lines <- strsplit(title_text(l$title), "<br>", fixed = TRUE)[[1]]
  expect_match(lines[1], "Cases", fixed = TRUE)
  expect_match(lines[2], "Wales", fixed = TRUE)
  expect_match(lines[3], "2026</span>", fixed = TRUE)
  expect_equal(l$title$font$color, phw_colours[["navy"]])
  src <- Filter(function(a) identical(a$name, "phw_source"), l$annotations)
  expect_equal(src[[1]]$text, "<b>Source: Example data</b>")
  given <- built(phw_plotly(g, source = "Other data"))$layout$annotations
  expect_equal(vapply(given, function(a) a$text, ""), "<b>Source: Other data</b>")
  untitled <- built(phw_plotly(g + ggplot2::labs(title = NULL)))$layout$title
  expect_match(title_text(untitled), "^<span[^>]*>Wales<br>2026</span>$")
})

test_that("the top margin makes room for every title line and the facet strips", {
  g <- ggplot2::ggplot(groups_df, ggplot2::aes(week, cases)) + ggplot2::geom_line() +
    ggplot2::labs(title = "Cases", subtitle = "Wales")
  top <- function(p) built(phw_plotly(p))$layout$margin$t
  faceted <- built(phw_plotly(g + ggplot2::facet_wrap(~group)))$layout
  strips <- Filter(function(s) identical(s$ysizemode, "pixel"), faceted$shapes)
  expect_gt(strips[[1]]$y1, 0)
  expect_equal(faceted$margin$t, top(g) + strips[[1]]$y1)
  expect_equal(top(g + ggplot2::labs(subtitle = "Wales\n2026")), top(g) + 22)
  expect_equal(top(g + ggplot2::labs(title = "Cases\nby week")), top(g) + 22)
  expect_equal(top(g + ggplot2::labs(title = NULL, subtitle = NULL)), top(g) - 22)
})

test_that("every panel of a subplot() or a faceted ggplot gets the PHW axes", {
  bars <- plotly::plot_ly(data.frame(week = 1:5, rate = 1:5), x = ~week, y = ~rate, type = "bar")
  g <- ggplot2::ggplot(groups_df, ggplot2::aes(week, cases)) + ggplot2::geom_line() +
    ggplot2::facet_wrap(~group, scales = "free")
  for (p in list(plotly::subplot(bars, bars), g)) {
    l <- built(phw_plotly(p))$layout
    for (a in c("xaxis", "yaxis", "xaxis2", "yaxis2")) {
      expect_equal(l[[a]]$gridcolor, phw_colours[["grey_border"]], label = a)
      expect_equal(l[[a]]$linecolor, phw_colours[["grey_mid"]], label = a)
      expect_equal(l[[a]]$tickfont$color, phw_colours[["text_secondary"]], label = a)
    }
  }
})

test_that("legend sets where a legend goes, not whether one trace gets one", {
  one <- plotly::plot_ly(groups_df, x = ~week, y = ~cases, type = "bar")
  expect_false(built(phw_plotly(one))$layout$showlegend)
  two <- plotly::plot_ly(groups_df, x = ~week, y = ~cases, color = ~group, type = "bar")
  expect_true(built(phw_plotly(two))$layout$showlegend)
  expect_false(built(phw_plotly(two, legend = "none"))$layout$showlegend)
})

test_that("a right legend sits to the right of the plot, for a ggplot too", {
  where <- function(w) built(phw_plotly(w, legend = "right"))$layout$legend[c("orientation", "x", "y", "xanchor", "yanchor")]
  right <- list(orientation = "v", x = 1.02, y = 1, xanchor = "left", yanchor = "top")
  p <- plotly::plot_ly(groups_df, x = ~week, y = ~cases, color = ~group, type = "scatter", mode = "lines")
  expect_equal(where(p), right)
  skip_if_not_installed("ggplot2")
  g <- ggplot2::ggplot(groups_df, ggplot2::aes(week, cases, colour = group)) + ggplot2::geom_line()
  expect_equal(where(g + theme_phw()), right)
})

test_that("the legend has a title only where the chart sets or shows one", {
  title_of <- function(w) built(w)$layout$legend$title$text
  p <- plotly::plot_ly(groups_df, x = ~week, y = ~cases, color = ~group, type = "scatter", mode = "lines")
  titled <- plotly::layout(p, legend = list(title = list(text = "Age group")))
  expect_equal(title_of(phw_plotly(titled)), "Age group")
  expect_equal(title_of(phw_plotly(titled, legend = "right")), "Age group")
  expect_null(title_of(phw_plotly(p)))
  skip_if_not_installed("ggplot2")
  g <- ggplot2::ggplot(groups_df, ggplot2::aes(week, cases, colour = group)) + ggplot2::geom_line() +
    ggplot2::labs(colour = "Age group")
  expect_equal(title_of(phw_plotly(g + theme_phw(legend_title = TRUE))), "Age group")
  expect_null(title_of(phw_plotly(g + theme_phw())))
  expect_null(title_of(phw_plotly(g + ggplot2::theme(legend.title = ggplot2::element_blank()))))
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

test_that("a ggplot with a second layer in the legend lists each group once, by name", {
  legend_of <- function(p) {
    traces <- built(phw_plotly(p))$data
    shown <- vapply(traces, function(t) isTRUE(t$showlegend), logical(1))
    vapply(traces[shown], function(t) t$name, "")
  }
  cases <- data.frame(onset = as.Date("2025-01-01") + rep(0:20, 3), grp = rep(c("A", "B", "C"), each = 21))
  expect_equal(legend_of(phw_epicurve(cases, onset, group = grp, average = 3)),
               c("A", "B", "C", "3-week average"))
  areas <- data.frame(area = c("X", "Y", "Z"), value = c(70, 60, 50), lower = c(65, 55, 45), upper = c(75, 65, 55))
  forest <- built(phw_plotly(phw_forest(areas, value, lower, upper, area, target = 60)))$data
  keys <- Filter(function(t) isTRUE(t$showlegend), forest)
  expect_equal(vapply(keys, function(t) t$name, ""), c("Higher", "Similar", "Lower"))
  expect_true(all(vapply(keys, function(t) !is.null(t$marker$symbol), logical(1))))

  d <- data.frame(x = rep(1:3, 4), y = 1:12, f = rep(c("A", "B"), each = 3), pan = rep(c("p", "q"), each = 6))
  faceted <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_col(ggplot2::aes(fill = f)) +
    ggplot2::geom_line(ggplot2::aes(colour = "Average")) + ggplot2::facet_wrap(~pan)
  expect_equal(legend_of(faceted), c("A", "B", "Average"))

  two <- data.frame(x = 1:4, y = 1:4, a = c("A", "A", "B", "B"), s = c("1", "2", "1", "2"))
  both <- ggplot2::ggplot(two, ggplot2::aes(x, y, colour = a, shape = s)) + ggplot2::geom_point()
  expect_equal(legend_of(both), c("(A,1)", "(A,2)", "(B,1)", "(B,2)"))
})

test_that("ggrepel labels show as text in plotly, placed by their hjust and vjust", {
  skip_if_not_installed("ggrepel")
  text_traces <- function(w) Filter(function(t) identical(t$mode, "text"), built(w)$data)
  set.seed(1)
  u <- data.frame(unit = paste("Unit", 1:20), events = c(rpois(19, 10), 40), n = rep(1000, 20))
  g <- phw_funnel(u, events, n, label = unit)
  expect_no_warning(w <- phw_plotly(g))
  lab <- text_traces(w)
  expect_length(lab, 1)
  expect_equal(lab[[1]]$text, "Unit 20")
  expect_equal(lab[[1]]$textposition, "top center")
  expect_s3_class(g$layers[[length(g$layers)]]$geom, "GeomTextRepel")

  d <- data.frame(x = 1:2, y = 1:2, l = c("a", "b"))
  boxed <- ggplot2::ggplot(d, ggplot2::aes(x, y, label = l)) + ggplot2::geom_point() +
    ggrepel::geom_label_repel(hjust = 0)
  expect_no_warning(lab <- text_traces(phw_plotly(boxed)))
  expect_equal(as.vector(lab[[1]]$text), c("a", "b"))
  expect_equal(unique(lab[[1]]$textposition), "middle right")
})

test_that("a funnel's 95% limits stay dashed and its 99.8% limits solid in plotly", {
  set.seed(6)
  d <- data.frame(den = round(runif(20, 500, 5000)))
  d$num <- rbinom(20, d$den, 0.1)
  lines <- Filter(function(t) identical(t$mode, "lines"), built(phw_plotly(phw_funnel(d, num, den)))$data)
  # the target line, then the 95% and 99.8% limits
  expect_equal(lapply(lines, function(t) t$line$dash), list("solid", "dash", "solid"))
})

test_that("a pyramid's hover shows each bar's unsigned value, as on the axis", {
  hover <- function(g) unlist(lapply(built(phw_plotly(g))$data, function(t) as.vector(t$text)))
  py <- data.frame(age = factor(rep(c("0-4", "5-9"), 2)), sex = rep(c("Female", "Male"), each = 2),
                   n = c(240000, 230000, 250000, 220000))
  expect_equal(hover(phw_pyramid(py, age, sex, value = n)),
               c("Female, 0-4: 240,000", "Female, 5-9: 230,000", "Male, 0-4: 250,000", "Male, 5-9: 220,000", ""))
  pct <- hover(phw_pyramid(py, age, sex, value = n, percent = TRUE, compare = py))
  expect_equal(pct[1:4], c("Female, 0-4: 25.5%", "Female, 5-9: 24.5%", "Male, 0-4: 26.6%", "Male, 5-9: 23.4%"))
  expect_equal(pct[5:8], pct[1:4])
})

test_that("a layer added to a pyramid with its own data draws, and in plotly", {
  py <- data.frame(age = factor(rep(c("0-4", "5-9"), 2)), sex = rep(c("Female", "Male"), each = 2),
                   n = c(240000, 230000, 250000, 220000))
  tot <- data.frame(pos = c(-260000, 260000), band = factor("5-9", levels(py$age)), who = c("Female", "Male"))
  g <- phw_pyramid(py, age, sex, value = n, compare = py) +
    ggplot2::geom_text(data = tot, ggplot2::aes(x = pos, y = band, label = who))
  expect_no_warning(b <- ggplot2::ggplot_build(g))
  expect_equal(b$data[[4]]$label, c("Female", "Male"))
  expect_no_error(built(phw_plotly(g)))
})

test_that("a ggplot that maps text shows only that text on hover", {
  d <- data.frame(x = 1:2, y = 3:4, lab = c("first", "second"))
  g <- ggplot2::ggplot(d, ggplot2::aes(x, y, text = lab)) + ggplot2::geom_point()
  expect_equal(as.vector(built(phw_plotly(g))$data[[1]]$text), c("first", "second"))
  plain <- built(phw_plotly(ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_point()))
  expect_match(plain$data[[1]]$text, "^x: 1<br />y: 3$|^x: 2<br />y: 4$")
})

test_that("a chart made with ggplotly() gets the legend names and hover of its ggplot", {
  legend_of <- function(w) {
    traces <- Filter(function(t) isTRUE(t$showlegend), built(w)$data)
    vapply(traces, function(t) t$name, "")
  }
  hover_of <- function(w) unlist(lapply(built(w)$data, function(t) as.vector(t$hovertext %||% t$text)))
  d <- data.frame(week = rep(1:3, 2), cases = c(3, 5, 9, 2, 4, 6), hb = rep(c("Powys", "Cardiff"), each = 3))
  target <- ggplot2::ggplot(d, ggplot2::aes(week, cases, fill = hb)) + ggplot2::geom_col() +
    ggplot2::geom_hline(ggplot2::aes(yintercept = 15, linetype = "Target"))
  expect_equal(legend_of(phw_plotly(plotly::ggplotly(target))), c("Cardiff", "Powys", "Target"))
  areas <- data.frame(area = c("X", "Y", "Z"), value = c(70, 60, 50), lower = c(65, 55, 45), upper = c(75, 65, 55))
  forest <- phw_forest(areas, value, lower, upper, area, target = 60)
  expect_equal(legend_of(phw_plotly(plotly::ggplotly(forest))), c("Higher", "Similar", "Lower"))
  two <- data.frame(x = 1:4, y = 1:4, a = c("A", "A", "B", "B"), s = c("1", "2", "1", "2"))
  both <- ggplot2::ggplot(two, ggplot2::aes(x, y, colour = a, shape = s)) + ggplot2::geom_point()
  expect_equal(legend_of(phw_plotly(plotly::ggplotly(both))), c("(A,1)", "(A,2)", "(B,1)", "(B,2)"))

  py <- data.frame(age = factor(rep(c("0-4", "5-9"), 2)), sex = rep(c("Female", "Male"), each = 2), n = c(5, 8, 6, 7))
  pyramid <- phw_pyramid(py, age, sex, value = n, compare = py)
  expect_equal(hover_of(phw_plotly(plotly::ggplotly(pyramid))), hover_of(phw_plotly(pyramid)))
  expect_match(hover_of(phw_plotly(plotly::ggplotly(pyramid, tooltip = "x")))[1], "^x: -5$")
  labelled <- ggplot2::ggplot(two, ggplot2::aes(x, y, text = a)) + ggplot2::geom_point() +
    ggplot2::geom_text(ggplot2::aes(label = s))
  w <- built(phw_plotly(plotly::ggplotly(labelled)))$data
  expect_equal(as.vector(w[[1]]$text), c("A", "A", "B", "B"))
  expect_equal(as.vector(w[[2]]$text), c("1", "2", "1", "2"))
  expect_equal(as.vector(w[[2]]$hovertext), c("A", "A", "B", "B"))
})

test_that("a ggplot's secondary axis is drawn over the main one, with its own breaks and title", {
  d <- data.frame(week = 1:20, cases = 4 + 180 * exp(-((1:20 - 9) / 4)^2))
  d$positivity <- 2 + 28 * exp(-((d$week - 10) / 5)^2)
  sec <- phw_sec_axis(d$cases, d$positivity, name = "Positivity (%)")
  g <- ggplot2::ggplot(d, ggplot2::aes(week)) + ggplot2::geom_col(ggplot2::aes(y = cases)) +
    ggplot2::geom_line(ggplot2::aes(y = sec$rescale(positivity))) +
    ggplot2::scale_y_continuous("Cases", sec.axis = sec)
  layout <- built(phw_plotly(g))$layout
  right <- layout$yaxis2
  expect_equal(right[c("overlaying", "matches", "side")], list(overlaying = "y", matches = "y", side = "right"))
  expect_equal(right$ticktext, c("0", "10", "20", "30"))
  expect_equal(right$tickvals, sec$rescale(c(0, 10, 20, 30)))
  expect_equal(right$title$text, "Positivity (%)")
  expect_equal(layout$yaxis$title$text, "Cases")

  top <- built(phw_plotly(g + ggplot2::coord_flip()))$layout
  expect_null(top$yaxis2)
  expect_equal(top$xaxis2[c("overlaying", "side")], list(overlaying = "x", side = "top"))
  expect_equal(top$xaxis2$ticktext, c("0", "10", "20", "30"))

  g$scales$scales <- list()
  expect_null(built(phw_plotly(g))$layout$yaxis2)
})

test_that("a secondary axis stays on its own chart in subplot(), and a faceted one warns", {
  d <- data.frame(week = 1:10, cases = c(1:5, 5:1) * 10, panel = rep(c("A", "B"), 5))
  sec <- phw_sec_axis(d$cases, d$cases / 10, name = "Rate")
  g <- ggplot2::ggplot(d, ggplot2::aes(week, cases)) + ggplot2::geom_col() +
    ggplot2::scale_y_continuous(sec.axis = sec)
  plain <- ggplot2::ggplot(d, ggplot2::aes(week, cases)) + ggplot2::geom_line()
  layout <- built(phw_plotly(plotly::subplot(phw_plotly(plain), phw_plotly(g))))$layout
  own <- Filter(function(a) is.list(a) && identical(a$anchor, "x2") && is.null(a$overlaying), layout)
  over <- Filter(function(a) is.list(a) && !is.null(a$overlaying), layout)
  expect_length(over, 1)
  expect_equal(over[[1]]$overlaying, sub("axis", "", names(own)))
  expect_equal(over[[1]]$matches, over[[1]]$overlaying)

  expect_warning(w <- phw_plotly(g + ggplot2::facet_wrap(~panel)), "faceted")
  expect_false(any(vapply(built(w)$layout, function(a) is.list(a) && !is.null(a$overlaying), logical(1))))
})

test_that("a ggplot of data with no rows gives the empty chart ggplotly() gives", {
  none <- data.frame(week = integer(), cases = numeric(), hb = character())
  g <- ggplot2::ggplot(none, ggplot2::aes(week, cases, fill = hb)) + ggplot2::geom_col()
  expect_equal(built(phw_plotly(g))$data, built(plotly::ggplotly(g))$data)
  expect_equal(built(phw_plotly(plotly::ggplotly(g)))$data, built(plotly::ggplotly(g))$data)
  points <- ggplot2::ggplot(none, ggplot2::aes(week, cases, colour = hb)) + ggplot2::geom_point()
  expect_length(built(phw_plotly(points))$data, 1)
  d <- data.frame(week = 1:3, cases = c(3, 5, 9))
  mixed <- ggplot2::ggplot(d, ggplot2::aes(week, cases)) + ggplot2::geom_point() +
    ggplot2::geom_point(data = none)
  traces <- built(phw_plotly(mixed))$data
  expect_equal(as.vector(traces[[1]]$y), c(3, 5, 9))
  expect_false(traces[[2]]$visible)
})

test_that("a line, error bar or boxplot layer with no rows gives an empty chart", {
  d <- data.frame(week = 1:4, cases = c(3, 5, 9, 4), lo = 1, hi = 12, hb = c("A", "A", "B", "B"))
  none <- d[d$cases > 100, ]
  empty <- list(
    ggplot2::ggplot(none, ggplot2::aes(week, cases)) + ggplot2::geom_line(),
    ggplot2::ggplot(none, ggplot2::aes(week, cases)) + ggplot2::geom_step(),
    ggplot2::ggplot(none, ggplot2::aes(week, ymin = lo, ymax = hi)) + ggplot2::geom_errorbar(),
    ggplot2::ggplot(none, ggplot2::aes(hb, cases)) + ggplot2::geom_boxplot(),
    ggplot2::ggplot(none, ggplot2::aes(week, cases, ymin = lo, ymax = hi)) + ggplot2::geom_pointrange()
  )
  for (g in empty) {
    w <- built(phw_plotly(g + ggplot2::labs(title = "Weekly cases", x = "Week"), source = "PHW"))
    expect_false(any(vapply(w$data, function(t) !isFALSE(t$visible), logical(1))))
    expect_equal(w$layout$title$text, "Weekly cases")
    expect_equal(w$layout$xaxis$title$text, "Week")
  }
  mixed <- ggplot2::ggplot(d, ggplot2::aes(week, cases)) + ggplot2::geom_col() +
    ggplot2::geom_line(data = none) + ggplot2::geom_errorbar(ggplot2::aes(ymin = lo, ymax = hi), data = none)
  traces <- built(phw_plotly(mixed))$data
  expect_equal(as.vector(traces[[1]]$y), d$cases)
  expect_s3_class(mixed$layers[[2]]$geom, "GeomLine")
  facets <- ggplot2::ggplot(d, ggplot2::aes(week, cases)) + ggplot2::geom_line() +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = lo, ymax = hi), data = none) + ggplot2::facet_wrap(~hb)
  expect_length(Filter(function(t) identical(t$mode, "lines"), built(phw_plotly(facets))$data), 2)
})

test_that("ggplot text keeps the font fallback, so browsers lay out the legend correctly", {
  withr::local_options(phwstyle.font = "Ubuntu")
  g <- ggplot2::ggplot(groups_df, ggplot2::aes(week, cases, colour = group)) + ggplot2::geom_line() +
    ggplot2::facet_wrap(~group) + theme_phw()
  stack <- "Ubuntu, Arial, sans-serif"
  figs <- list(phw_plotly(g), phw_plotly(plotly::ggplotly(g)), phw_plotly(plotly::subplot(g, g)),
               phw_plotly(g, legend = "right"))
  for (fig in figs) {
    layout <- built(fig)$layout
    families <- unlist(rapply(layout, function(x) x, how = "unlist"))
    families <- families[grepl("(^|\\.)family$", names(families)) & !is.na(families)]
    expect_true(length(families) > 3)
    expect_setequal(unique(families), stack)
    expect_equal(layout$legend$font$family, stack)
  }
})
