test_that("theme_phw builds and applies to plots, including facets", {
  library(ggplot2)
  p <- ggplot(mpg, aes(displ, hwy, colour = drv)) + geom_point() + facet_wrap(~year) + theme_phw()
  expect_s3_class(theme_phw(), "theme")
  g <- ggplotGrob(p)
  expect_s3_class(g, "gtable")
  for (grid in c("x", "y", "xy", "none")) expect_s3_class(theme_phw(grid = grid), "theme")
  for (strip in c("light", "navy", "plain")) expect_s3_class(theme_phw(strip = strip), "theme")
  expect_s3_class(theme_phw_map(), "theme")
})

test_that("default discrete colours are PHW colours", {
  skip_if(utils::packageVersion("ggplot2") < "4.0.0")
  library(ggplot2)
  p <- ggplot(mpg, aes(displ, hwy, colour = drv)) + geom_point() + theme_phw()
  cols <- unique(layer_data(p)$colour)
  expect_setequal(cols, phw_pal(3))
})

test_that("PHW scales work", {
  library(ggplot2)
  base <- ggplot(mpg, aes(class, fill = drv)) + geom_bar()
  expect_setequal(unique(layer_data(base + scale_fill_phw_d())$fill), phw_pal(3))
  expect_s3_class(scale_fill_phw_c(), "ScaleContinuous")
  expect_s3_class(scale_fill_phw_b(), "ScaleBinned")
  expect_s3_class(scale_fill_phw_div(midpoint = 10), "ScaleContinuous")
  expect_error(scale_fill_phw_c("main"), "qualitative")
})

test_that("diverging scales take midpoint in data units on a log scale", {
  library(ggplot2)
  r <- data.frame(x = 1:5, rr = c(0.25, 0.5, 1, 2, 4))
  logged <- layer_data(ggplot(r, aes(x, 1, fill = log10(rr))) + geom_tile() +
                         scale_fill_phw_div(midpoint = 0))$fill
  fill <- layer_data(ggplot(r, aes(x, 1, fill = rr)) + geom_tile() +
                       scale_fill_phw_div(midpoint = 1, transform = "log10"))$fill
  colour <- layer_data(ggplot(r, aes(x, 1, colour = rr)) + geom_point() +
                         scale_colour_phw_div(midpoint = 1, transform = "log2"))$colour
  expect_equal(fill, logged)
  expect_equal(colour, logged)
  expect_error(scale_fill_phw_div(transform = "log10"), "outside")
  expect_error(scale_colour_phw_div(midpoint = c(0, 1)), "single number")
})

test_that("phw_finalise adds a footer and saves", {
  skip_if_not_installed("png")
  library(ggplot2)
  p <- ggplot(mpg, aes(displ, hwy)) + geom_point() + theme_phw()
  f <- phw_finalise(p, source = "test", team = "Team", source_prefix = "Data: ")
  expect_true("phw-footer" %in% f$layout$name)
  out <- withr::local_tempfile(fileext = ".png")
  phw_save(f, out, dpi = 72)
  expect_true(file.exists(out))
})

test_that("phw_save bg sets the saved background", {
  skip_if_not_installed("png")
  library(ggplot2)
  p <- ggplot(mpg, aes(displ, hwy)) + geom_point() + theme_phw()
  saved <- function(plot, ...) {
    out <- withr::local_tempfile(fileext = ".png", .local_envir = parent.frame())
    png::readPNG(phw_save(plot, out, width = 8, height = 5, dpi = 72, ...))
  }
  opaque <- function(img) mean(img[, , 4] == 1)
  red <- function(img) mean(img[, , 1] > 0.9 & img[, , 2] < 0.1 & img[, , 3] < 0.1)
  f <- phw_finalise(p, source = "test", logo = FALSE)
  expect_lt(opaque(saved(p, bg = "transparent")), 0.5)
  expect_lt(opaque(saved(f, bg = "transparent")), 0.5)
  expect_gt(red(saved(p, bg = "red")), 0.5)
  expect_gt(red(saved(f, bg = "red")), 0.5)
  grey <- saved(p + theme_phw(background = "#EEEEEE"))
  expect_equal(grey[2, 2, 1:3], rep(0xEE / 255, 3))
})

test_that("phw_save writes EPS and PostScript", {
  skip_if_not(cairo_loads(), "Cairo cannot be loaded")
  library(ggplot2)
  p <- ggplot(mpg, aes(displ, hwy)) + geom_point() + theme_phw()
  for (ext in c(".eps", ".ps")) {
    out <- withr::local_tempfile(fileext = ext)
    phw_save(p, out)
    expect_match(readLines(out, n = 1), "^%!PS-Adobe")
  }
})

test_that("phw_save stops before EPS when Cairo cannot be loaded", {
  local_mocked_bindings(cairo_loads = function() FALSE)
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  out <- withr::local_tempfile(fileext = ".eps")
  open <- grDevices::dev.cur()
  expect_error(phw_save(p, out), "needs Cairo")
  expect_false(file.exists(out))
  expect_identical(grDevices::dev.cur(), open)
})

test_that("phw_finalise can put the logo on the right with no rule", {
  library(ggplot2)
  p <- ggplot(mpg, aes(displ, hwy)) + geom_point() + labs(caption = "kept")
  f <- phw_finalise(p, logo = FALSE, logo_position = "right", rule = FALSE)
  expect_true("phw-footer" %in% f$layout$name)
})

test_that("phw_finalise adds a note under the caption already on the plot", {
  library(ggplot2)
  footer_label <- function(fp) {
    fp$grobs[[which(fp$layout$name == "phw-footer")]]$children$text$label
  }
  p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() +
    labs(caption = phw_caption("Example system"))
  expect_equal(footer_label(phw_finalise(p, note = "Provisional figures", logo = FALSE)),
               "Source: Example system\nProvisional figures")
  expect_equal(footer_label(phw_finalise(p, note = "Provisional", sep = " | ", team = "CDSC", logo = FALSE)),
               "Source: Example system | Provisional\nCDSC")
  expect_equal(footer_label(phw_finalise(p, source = "New", note = "Provisional", logo = FALSE)),
               "Source: New\nProvisional")
  bare <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  expect_equal(footer_label(phw_finalise(bare, note = "Provisional", logo = FALSE)), "Provisional")
  skip_if_not_installed("patchwork")
  pw <- phw_arrange(bare, bare, source = "S")
  expect_equal(footer_label(phw_finalise(pw, note = "Provisional", logo = FALSE)),
               "Source: S\nProvisional")
})

test_that("theme_phw takes overrides and extra options", {
  library(ggplot2)
  th <- theme_phw(legend = c(0.9, 0.9), grid_minor = TRUE, axis_ticks = TRUE,
                  background = "transparent", accessible = TRUE,
                  plot.title = element_text(colour = "red"), text = element_text(size = 14))
  expect_equal(th$plot.title$colour, "red")
  expect_equal(th$legend.position, "inside")
  expect_gte(th$text$size, 13)
  expect_s3_class(th$panel.grid.minor.y, "element_line")
})

test_that("discrete scales accept custom palettes, values and keys", {
  library(ggplot2)
  phw_key_reset("test_drv")
  withr::defer(phw_key_reset("test_drv"))
  p <- ggplot(mpg, aes(displ, hwy, colour = drv)) + geom_point()
  b <- ggplot_build(p + scale_colour_phw_d(palette = c("#111111", "#222222", "#333333")))
  expect_setequal(unique(b$data[[1]]$colour), c("#111111", "#222222", "#333333"))
  b <- ggplot_build(p + scale_colour_phw_d(values = c(r = "#000000")))
  expect_true("#000000" %in% b$data[[1]]$colour)
  b1 <- ggplot_build(p + scale_colour_phw_d(key = "test_drv"))
  sub <- mpg[mpg$drv != "4", ]
  b2 <- ggplot_build(ggplot(sub, aes(displ, hwy, colour = drv)) + geom_point() +
                       scale_colour_phw_d(key = "test_drv"))
  # "f" and "r" keep the colours they had when "4" was present.
  c1 <- unique(b1$data[[1]][mpg$drv == "f", "colour"])
  c2 <- unique(b2$data[[1]][sub$drv == "f", "colour"])
  expect_equal(c1, c2)
  expect_s3_class(scale_colour_phw_d(aesthetics = c("colour", "fill")), "ScaleDiscrete")
})

# use_phw_ggplot() reaches the same result two ways: through the theme from
# ggplot2 4.0, and through options and geom defaults before that. These
# tests have no version switches, so each one checks whichever route the
# installed ggplot2 takes.

test_that("use_phw_ggplot styles histograms on every supported ggplot2", {
  library(ggplot2)
  local_ggplot_state()
  # ggplot2 has no "histogram" geom class to look up by name;
  # geom_histogram() draws with GeomBar.
  expect_no_error(use_phw_ggplot())
  expect_silent(set_geom_defaults("no_such_geom", list(fill = "red")))
  p <- ggplot(mpg, aes(hwy)) + geom_histogram(bins = 10)
  expect_s3_class(ggplotGrob(p), "gtable")
  expect_equal(plot_colours(p), phw_colours[["navy"]])
})

test_that("geom defaults are only skipped for geoms this ggplot2 lacks", {
  local_ggplot_state()
  set_geom_defaults(c("no_such_geom", "point"), list(colour = "#123456"))
  expect_equal(ggplot2::GeomPoint$default_aes$colour, "#123456")
})

test_that("use_phw_ggplot gives unmapped layers the same colours on every ggplot2", {
  library(ggplot2)
  local_ggplot_state()
  use_phw_ggplot()
  navy <- phw_colours[["navy"]]
  text <- phw_colours[["text"]]
  base <- ggplot(mpg, aes(displ, hwy))
  expect_equal(plot_colours(ggplot(mpg, aes(class)) + geom_bar()), navy)
  expect_equal(plot_colours(ggplot(groups(3), aes(g, v)) + geom_col()), navy)
  expect_equal(plot_colours(base + geom_area()), navy)
  expect_equal(plot_colours(base + geom_line(), "colour"), navy)
  expect_equal(plot_colours(base + geom_point(), "colour"), navy)
  expect_equal(plot_colours(base + geom_step(), "colour"), navy)
  expect_equal(plot_colours(ggplot(mpg, aes(hwy)) + geom_density(), "colour"), navy)
  # Text, reference lines and box outlines stay dark.
  expect_equal(plot_colours(base + geom_text(aes(label = cyl)), "colour"), text)
  expect_equal(plot_colours(base + geom_hline(yintercept = 20), "colour"), text)
  expect_equal(plot_colours(base + geom_vline(xintercept = 3), "colour"), text)
  box <- layer_data(ggplot(mpg, aes(drv, hwy)) + geom_boxplot())
  expect_equal(toupper(unique(box$fill)), "#FFFFFF")
  expect_equal(unique(box$colour), text)
  # An explicit colour still wins over the default.
  expect_equal(plot_colours(ggplot(mpg, aes(class)) + geom_bar(fill = "#FF5D0C")), "#FF5D0C")
  expect_equal(unique(layer_data(base + geom_text(aes(label = cyl)))$family), phw_font())
})

test_that("use_phw_ggplot sets PHW default scales on every ggplot2", {
  library(ggplot2)
  local_ggplot_state()
  d <- data.frame(x = 1:6, y = c(1, 3, 5, 7, 9, 11))
  before <- plot_colours(ggplot(d, aes(x, y, fill = y)) + geom_col() + scale_fill_binned())
  use_phw_ggplot()
  # Groups: a plain plot is drawn in the PHW palette, for colour and fill.
  expect_setequal(plot_colours(ggplot(mpg, aes(displ, hwy, colour = drv)) + geom_point(), "colour"),
                  phw_pal(3))
  expect_equal(plot_colours(ggplot(groups(4), aes(g, v, fill = g)) + geom_col()), phw_pal(4))
  p <- ggplot(mpg, aes(class, fill = drv)) + geom_bar()
  expect_s3_class(ggplotGrob(p), "gtable")
  # Numbers: PHW blues, without the palest one.
  ends <- phw_continuous_auto[c(1, length(phw_continuous_auto))]
  expect_equal(plot_colours(ggplot(d, aes(x, y, colour = y)) + geom_point(), "colour")[c(1, 6)], ends)
  expect_equal(plot_colours(ggplot(d, aes(x, y, fill = y)) + geom_col())[c(1, 6)], ends)
  # Binned scales follow the same palette, not ggplot2's own blues.
  binned <- ggplot(d, aes(x, y, fill = y)) + geom_col() + scale_fill_binned()
  expect_s3_class(ggplotGrob(binned), "gtable")
  expect_false(any(plot_colours(binned) %in% before))
  # A scale added to the plot replaces the default.
  manual <- ggplot(groups(2), aes(g, v, fill = g)) + geom_col() +
    scale_fill_manual(values = c("#111111", "#222222"))
  expect_equal(plot_colours(manual), c("#111111", "#222222"))
  # So do ggplot2's own default scales when given their own arguments.
  own <- ggplot(d, aes(x, y, fill = y)) + geom_col() +
    scale_fill_continuous(low = "#FFFFFF", high = "#000000")
  expect_equal(plot_colours(own)[c(1, 6)], c("#FFFFFF", "#000000"))
  hue <- ggplot(groups(3), aes(g, v, colour = g)) + geom_point() + scale_colour_discrete(l = 40)
  expect_false(any(plot_colours(hue, "colour") %in% phw_palettes$extended))
  named <- ggplot(groups(3), aes(g, v, fill = g)) + geom_col() +
    scale_fill_discrete(name = "Group", na.value = "#ABCDEF")
  expect_equal(plot_colours(named), phw_pal(3))
})

test_that("use_phw_ggplot gives ordered factors the PHW palette on every ggplot2", {
  library(ggplot2)
  local_ggplot_state()
  d <- data.frame(g = factor(c("0-14", "15-64", "65+", NA)), v = 1:4)
  ordered <- transform(d, g = factor(g, ordered = TRUE))
  same_as_unordered <- function(aesthetic, geom) {
    draw <- function(data) {
      plot_colours(ggplot(data, aes(g, v, !!rlang::sym(aesthetic) := g)) + geom(), aesthetic)
    }
    expect_equal(draw(ordered), draw(d))
  }
  use_phw_ggplot()
  expect_equal(plot_colours(ggplot(ordered, aes(g, v, fill = g)) + geom_col())[1:3], phw_pal(3))
  same_as_unordered("fill", geom_col)
  same_as_unordered("colour", geom_point)
  use_phw_ggplot(palette = "accessible")
  same_as_unordered("fill", geom_col)
  # ggplot2's own ordinal scale still answers to its own arguments.
  magma <- ggplot(ordered, aes(g, v, fill = g)) + geom_col()
  expect_equal(plot_colours(magma + scale_fill_ordinal(option = "magma")),
               plot_colours(magma + scale_fill_viridis_d(option = "magma")))
})

test_that("use_phw_ggplot default scales give groups named after the palette's colours those colours", {
  library(ggplot2)
  local_ggplot_state()
  use_phw_ggplot(palette = "rag")
  d <- data.frame(x = 1:3, y = 1:3, status = c("Red", "Amber", "Green"))
  want <- unname(phw_palettes$rag[c("red", "amber", "green")])
  expect_equal(plot_colours(ggplot(d, aes(x, y, colour = status)) + geom_point(), "colour"), want)
  expect_equal(plot_colours(ggplot(d, aes(x, y, fill = status)) + geom_point(shape = 21)), want)
  ordered <- transform(d, status = factor(status, levels = c("Green", "Amber", "Red"), ordered = TRUE))
  expect_equal(plot_colours(ggplot(ordered, aes(x, y, fill = status)) + geom_point(shape = 21)), want)
  # The same with a theme_phw() of the plot's own, with no warnings.
  themed <- ggplot(d, aes(x, y, colour = status)) + geom_point() + theme_phw(grid = "x")
  expect_no_warning(expect_equal(plot_colours(themed, "colour"), want))
  expect_no_warning(ggplotGrob(themed))
  skip_if_not(ggplot2_v4(), "Theme palettes need ggplot2 4.0")
  own <- c("#111111", "#222222", "#333333")
  expect_no_warning(mine <- themed + theme(palette.colour.discrete = own))
  expect_equal(plot_colours(mine, "colour"), own[rank(d$status)])
})

test_that("accessible = TRUE makes lines, points and text bigger on every ggplot2", {
  library(ggplot2)
  local_ggplot_state()
  sizes <- function() {
    base <- ggplot(mpg, aes(displ, hwy))
    c(line = unique(layer_data(base + geom_line())$linewidth),
      point = unique(layer_data(base + geom_point())$size),
      text = unique(layer_data(base + geom_text(aes(label = cyl)))$size))
  }
  use_phw_ggplot()
  normal <- sizes()
  expect_equal(normal[["line"]], 0.7)
  expect_equal(normal[["point"]], 1.8)
  expect_equal(normal[["text"]], 11 * 0.8 / .pt)
  use_phw_ggplot(accessible = TRUE)
  big <- sizes()
  expect_equal(big[["line"]], 1.1)
  expect_equal(big[["point"]], 2.6)
  expect_gt(big[["text"]], normal[["text"]])
  expect_gte(theme_get()$text$size, 13)
  # Bigger text doesn't touch the colours.
  expect_equal(phw_default_palette(), "main")
})

test_that("use_phw_ggplot returns the old theme and checks the palette", {
  library(ggplot2)
  local_ggplot_state()
  theme_set(theme_grey())
  old <- use_phw_ggplot(base_size = 14, grid = "x")
  expect_equal(old$text$size, 11)
  expect_equal(theme_get()$text$size, 14)
  expect_error(use_phw_ggplot(palette = "no_such_palette"), "Unknown palette")
  expect_null(getOption("phwstyle.palette"))
  use_phw_ggplot(palette = "accessible")
  expect_equal(getOption("phwstyle.palette"), "accessible")
})

test_that("phw_sec_axis lines up a second measure on linear axes", {
  library(ggplot2)
  d <- data.frame(x = 1:10, n = seq(20, 200, length.out = 10), rate = seq(1, 50, length.out = 10))
  sec <- phw_sec_axis(d$n, d$rate, name = "Rate")
  expect_s3_class(sec, "AxisSecondary")
  # Zero stays at zero and the largest values meet.
  expect_equal(sec$rescale(c(0, 50)), c(0, 200))
  p <- ggplot(d, aes(x)) + geom_col(aes(y = n)) + geom_line(aes(y = sec$rescale(rate))) +
    scale_y_continuous("Count", sec.axis = sec)
  b <- ggplot_build(p)
  expect_equal(max(b$data[[2]]$y), 200)
  expect_s3_class(ggplotGrob(p), "gtable")
  expect_equal(p$scales$get_scales("y")$secondary.axis$name, "Rate")

  # zero = FALSE stretches one range over the other.
  sec <- phw_sec_axis(d$n, d$rate, zero = FALSE)
  expect_equal(sec$rescale(c(1, 50)), c(20, 200))
  # A range works as well as the values.
  expect_equal(phw_sec_axis(c(0, 400), c(0, 50))$rescale(25), 200)
})

test_that("phw_sec_axis works on log axes and mixed axes", {
  library(ggplot2)
  d <- data.frame(x = 1:10, n = 10^seq(1, 4, length.out = 10), rate = 10^seq(-1, 1, length.out = 10))
  sec <- phw_sec_axis(d$n, d$rate, scale = "log")
  expect_equal(sec$rescale(c(0.1, 1, 10)), c(10, 10^2.5, 10^4))
  p <- ggplot(d, aes(x)) + geom_line(aes(y = n)) + geom_line(aes(y = sec$rescale(rate))) +
    scale_y_log10(sec.axis = sec)
  expect_s3_class(ggplotGrob(p), "gtable")
  # The secondary axis reads back the original values, with log-spaced breaks.
  br <- as.numeric(ggplot_build(p)$layout$panel_params[[1]]$y.sec$get_labels())
  br <- br[!is.na(br)]
  expect_true(all(c(0.1, 1, 10) %in% br))

  # Linear main axis with a log secondary axis, and the reverse.
  lin <- data.frame(x = 1:10, n = seq(0, 90, length.out = 10))
  sec <- phw_sec_axis(lin$n, d$rate, sec_scale = "log")
  expect_equal(sec$rescale(c(0.1, 1, 10)), c(0, 45, 90))
  p <- ggplot(lin, aes(x)) + geom_col(aes(y = n)) + geom_line(aes(y = sec$rescale(d$rate))) +
    scale_y_continuous(sec.axis = sec)
  expect_s3_class(ggplotGrob(p), "gtable")
  sec <- phw_sec_axis(d$n, lin$n, scale = "log", sec_scale = "linear")
  expect_equal(sec$rescale(c(0, 45, 90)), c(10, 10^2.5, 10^4))
  p <- ggplot(d, aes(x)) + geom_line(aes(y = n)) + geom_line(aes(y = sec$rescale(lin$n))) +
    scale_y_log10(sec.axis = sec)
  expect_s3_class(ggplotGrob(p), "gtable")

  # Values a log axis can't show become missing rather than errors.
  expect_true(is.na(phw_sec_axis(d$n, d$rate, scale = "log")$rescale(0)))
  expect_error(phw_sec_axis(d$n, c(-1, 0), scale = "log"), "above zero")
  expect_error(phw_sec_axis("a", 1:3), "numeric")
})

test_that("scale_shape_phw and scale_linetype_phw stop clearly past eight groups", {
  d <- data.frame(x = 1:9, y = 1:9, g = paste("G", 1:9))
  p <- ggplot2::ggplot(d, ggplot2::aes(x, y, shape = g)) + ggplot2::geom_point() + scale_shape_phw()
  expect_error(ggplot2::ggplot_build(p), "9 groups but only 8 shapes")
  p <- ggplot2::ggplot(d, ggplot2::aes(x, y, linetype = g)) + ggplot2::geom_line() + scale_linetype_phw()
  expect_error(ggplot2::ggplot_build(p), "9 groups but only 8 line types")
})

test_that("scale_shape_phw and scale_linetype_phw keep a missing group on the chart", {
  d <- data.frame(x = c(1, 2, 1, 2), y = c(1, 1, 2, 2), g = c("A", "A", NA, NA))
  p <- ggplot2::ggplot(d, ggplot2::aes(x, y, shape = g)) + ggplot2::geom_point() + scale_shape_phw()
  expect_no_warning(b <- ggplot2::layer_data(p))
  expect_equal(b$shape, c(16, 16, 4, 4))
  p <- ggplot2::ggplot(d, ggplot2::aes(x, y, linetype = g, group = g)) + ggplot2::geom_line() + scale_linetype_phw()
  expect_equal(unique(ggplot2::layer_data(p)$linetype), c("solid", "16"))
})

test_that("na.translate = FALSE leaves missing groups off the chart", {
  d <- data.frame(x = c("A", "B", NA), y = 1:3)
  p <- ggplot2::ggplot(d, ggplot2::aes(x, y, fill = x)) + ggplot2::geom_col()
  expect_equal(ggplot2::layer_data(p + scale_fill_phw_d())$fill[3], phw_colours[["grey_light"]])
  p <- p + scale_fill_phw_d(na.translate = FALSE)
  expect_equal(ggplot2::layer_data(p)$fill, c(unname(phw_pal(2)), NA))
  p <- ggplot2::ggplot(d, ggplot2::aes(y, y, colour = x)) + ggplot2::geom_point() +
    scale_colour_phw_d(na.translate = FALSE)
  expect_equal(ggplot2::layer_data(p)$colour, c(unname(phw_pal(2)), NA))
  expect_warning(ggplot2::ggplotGrob(p), "Removed 1 row")
})

test_that("scale_*_phw_d checks palette and values when it is made", {
  expect_error(scale_colour_phw_d(values = c("red", "blue")), "values.*named")
  expect_error(scale_colour_phw_d(values = c(A = "notacolour")), "notacolour")
  expect_error(scale_colour_phw_d(palette = "nope"), "Unknown palette")
  # Verbose warnings leave cli's once-every-8-hours record untouched for test-keys.R.
  withr::local_options(rlib_warning_verbosity = "verbose")
  d <- data.frame(x = 1:80, y = 1, g = sprintf("G%02d", 1:80))
  p <- ggplot2::ggplot(d, ggplot2::aes(x, y, colour = g)) + ggplot2::geom_point() + scale_colour_phw_d()
  expect_error(suppressWarnings(ggplot2::ggplot_build(p)), "80 groups.*facets")
})

test_that("theme_phw_map stops on grid and lets legend_title through", {
  expect_error(theme_phw_map(grid = "y"), "no gridlines")
  expect_s3_class(theme_phw_map(legend_title = FALSE)$legend.title, "element_blank")
})

test_that("theme_phw checks a numeric legend and base_size", {
  expect_error(theme_phw(legend = 0.5), "two numbers")
  expect_error(theme_phw(legend = c(0.5, 2)), "two numbers")
  expect_error(theme_phw(base_size = "11"), "base_size")
  expect_equal(theme_phw(legend = c(0.9, 0.9))$legend.position.inside, c(0.9, 0.9))
})

test_that("reverse flips a function palette and keeps its order", {
  d <- data.frame(x = 1:3, y = 1:3, g = c("A", "B", "C"))
  fill_of <- function(...) {
    p <- ggplot2::ggplot(d, ggplot2::aes(x, y, colour = g)) + ggplot2::geom_point() +
      scale_colour_phw_d(palette = function(n) grDevices::hcl.colors(n), ...)
    ggplot2::layer_data(p)$colour
  }
  expect_equal(toupper(fill_of()), toupper(grDevices::hcl.colors(3)))
  expect_equal(toupper(fill_of(reverse = TRUE)), toupper(rev(grDevices::hcl.colors(3))))
})

test_that("sequential and diverging palettes spread over the groups as phw_pal() does", {
  fill_of <- function(groups, ...) {
    d <- data.frame(x = seq_along(groups), y = 1, g = groups)
    p <- ggplot2::ggplot(d, ggplot2::aes(x, y, fill = g)) + ggplot2::geom_col() +
      scale_fill_phw_d(...)
    ggplot2::layer_data(p)$fill
  }
  expect_equal(fill_of(c("a", "b", "c"), "blues"), phw_pal(3, "blues"))
  expect_equal(fill_of(c("a", "b", "c"), "orange_navy"), phw_pal(3, "orange_navy"))
  expect_equal(fill_of(c("a", "b", "c"), "blues", reverse = TRUE), phw_pal(3, "blues", reverse = TRUE))
  expect_equal(fill_of(c("a", "b", "Unknown"), "blues"),
               c(phw_pal(2, "blues"), phw_colours[["grey_mid"]]))
  expect_equal(fill_of("Unknown", "blues"), phw_colours[["grey_mid"]])
  expect_equal(fill_of("Unknown", "blues", reverse = TRUE), phw_colours[["grey_mid"]])
})

test_that("reverse carries \"main\" on into \"extended\" as phw_pal() does", {
  fill_of <- function(groups) {
    d <- data.frame(x = seq_along(groups), y = 1, g = groups)
    p <- ggplot2::ggplot(d, ggplot2::aes(x, y, fill = g)) + ggplot2::geom_col() +
      scale_fill_phw_d(palette = "main", reverse = TRUE)
    ggplot2::layer_data(p)$fill
  }
  expect_no_warning(eight <- fill_of(LETTERS[1:8]))
  expect_equal(eight, phw_pal(8, "main", reverse = TRUE))
  expect_equal(fill_of(LETTERS[1:3]), phw_pal(3, "main", reverse = TRUE))
  expect_equal(fill_of(c(LETTERS[1:4], "Other")),
               c(phw_pal(4, "main", reverse = TRUE), phw_colours[["grey_mid"]]))
})

# A weekly chart of `k` health boards, the commonest long legend labels.
board_chart <- function(k = 4) {
  boards <- c("Aneurin Bevan UHB", "Betsi Cadwaladr UHB", "Cardiff and Vale UHB",
              "Cwm Taf Morgannwg UHB", "Hywel Dda UHB", "Powys THB", "Swansea Bay UHB")[seq_len(k)]
  d <- data.frame(week = rep(as.Date("2026-09-07") + 7 * 0:9, k),
                  board = rep(boards, each = 10), cases = rep(seq(30, 48, by = 2), k))
  ggplot2::ggplot(d, ggplot2::aes(week, cases, colour = board)) + ggplot2::geom_line()
}

# Opens a device of the given size in cm for the rest of the calling test.
local_size <- function(width = 16, height = 10, env = parent.frame()) {
  ragg::agg_png(tempfile(fileext = ".png"), width = width, height = height, units = "cm", res = 72)
  withr::defer(grDevices::dev.off(), envir = env)
}

legend_cm <- function(g) {
  box <- g$grobs[[which(g$layout$name %in% c("guide-box-bottom", "guide-box"))[1]]]
  grid::convertWidth(gtable::gtable_width(box), "cm", valueOnly = TRUE)
}

test_that("phw_save wraps a bottom legend of health boards to fit the default size", {
  skip_if_not_installed("ragg")
  library(ggplot2)
  local_ggplot_state()
  use_phw_ggplot()
  saved <- NULL
  local_mocked_bindings(ggsave = function(filename, plot, ...) saved <<- plot, .package = "ggplot2")
  for (k in c(4, 7)) {
    phw_save(board_chart(k), "cases.png")
    local_size()
    expect_lte(legend_cm(ggplotGrob(saved)), 16)
  }
  # The same with colours of the user's own.
  phw_save(board_chart() + scale_colour_manual(values = unname(phw_palettes$main[1:4])), "cases.png")
  local_size()
  expect_lte(legend_cm(ggplotGrob(saved)), 16)
})

test_that("legends that fit and a set number of rows are left as they are", {
  skip_if_not_installed("ragg")
  library(ggplot2)
  local_ggplot_state()
  use_phw_ggplot()
  local_size()
  rows <- function(p) {
    g <- ggplotGrob(wrap_legends(p))
    box <- g$grobs[[which(g$layout$name == "guide-box-bottom")]]
    labels <- grepl("^label", box$grobs[[1]]$layout$name)
    length(unique(box$grobs[[1]]$layout$t[labels]))
  }
  expect_equal(rows(board_chart()), 2)
  expect_equal(rows(board_chart() + guides(colour = guide_legend(nrow = 1))), 1)
  expect_equal(rows(ggplot(mpg, aes(displ, hwy, colour = drv)) + geom_point()), 1)
  wide <- board_chart() + theme(legend.position = "right")
  expect_identical(wrap_legends(wide), wide)
})

# Room in cm between neighbouring labels of the colour bar across the bottom
# of `g`, and between the end labels and the edges of the legend.
bar_label_room <- function(g) {
  cm <- function(u) grid::convertWidth(u, "cm", valueOnly = TRUE)
  box <- g$grobs[[which(g$layout$name == "guide-box-bottom")]]
  guide <- box$grobs[[which(box$layout$name == "guides")]]
  bar <- guide$layout[guide$layout$name == "bar", ]
  text <- guide$grobs[[grep("^label", guide$layout$name)]]$children[[1]]
  width <- vapply(text$label, function(l) cm(grid::grobWidth(grid::textGrob(l, gp = text$gp))), numeric(1))
  centre <- sum(cm(guide$widths[seq_len(bar$l - 1)])) + as.numeric(text$x) * cm(sum(guide$widths[bar$l:bar$r]))
  n <- length(centre)
  list(between = (centre[-1] - width[-1] / 2) - (centre[-n] + width[-n] / 2),
       ends = c(centre[1] - width[1] / 2, sum(cm(guide$widths)) - centre[n] - width[n] / 2))
}

test_that("a colour bar or steps across the bottom has room for its labels", {
  skip_if_not_installed("ragg")
  library(ggplot2)
  local_ggplot_state()
  d <- expand.grid(week = 1:10, hb = c("Cardiff", "Swansea", "Powys"))
  d$rate <- seq(600, 1600, length.out = 30)
  d$change <- seq(-25, 25, length.out = 30)
  tiles <- ggplot(d, aes(week, hb, fill = rate)) + geom_tile() + theme_phw()
  saved <- NULL
  local_mocked_bindings(ggsave = function(filename, plot, ...) saved <<- plot, .package = "ggplot2")
  phw_save(tiles, "heat.png")
  plots <- list(
    tiles + scale_fill_phw_c(),
    tiles + scale_fill_phw_b(),
    tiles + scale_fill_phw_c(labels = scales::label_comma(scale = 1000)),
    ggplot(d, aes(week, hb, fill = change)) + geom_tile() + scale_fill_phw_div() + theme_phw(),
    ggplot(d, aes(week, rate, colour = rate)) + geom_point() + scale_colour_phw_c() + theme_phw(),
    saved
  )
  use_phw_ggplot()
  phw_save(ggplot(d, aes(week, hb, fill = rate)) + geom_tile(), "heat.png")
  plots <- c(plots, list(saved))
  local_size()
  for (p in plots) {
    room <- bar_label_room(ggplotGrob(p))
    expect_gt(min(room$between), 0)
    expect_gte(min(room$ends), -1e-9)
  }
})

test_that("a colour bar on the right is the length ggplot2 gives it", {
  library(ggplot2)
  local_ggplot_state()
  p <- ggplot(faithfuld, aes(waiting, eruptions, fill = density)) + geom_raster() +
    theme_phw(legend = "right")
  size <- function(p) {
    g <- ggplotGrob(p)
    box <- g$grobs[[which(g$layout$name == "guide-box-right")]]
    c(grid::convertWidth(gtable::gtable_width(box), "cm", valueOnly = TRUE),
      grid::convertHeight(gtable::gtable_height(box), "cm", valueOnly = TRUE))
  }
  expect_equal(size(p + scale_fill_phw_c()), size(p + scale_fill_gradientn(colours = phw_palettes$blues)))
})

test_that("a phw_finalise() chart wraps its legend to the size it is drawn at", {
  skip_if_not_installed("ragg")
  library(ggplot2)
  local_ggplot_state()
  use_phw_ggplot()
  f <- phw_finalise(board_chart(), source = "PHW", logo = FALSE)
  local_size()
  drawn <- grid::makeContext(f)
  expect_lte(legend_cm(drawn), 16)
  expect_true("phw-footer" %in% drawn$layout$name)
})

test_that("phw_arrange wraps a collected legend of health boards", {
  skip_if_not_installed("ragg")
  skip_if_not_installed("patchwork")
  library(ggplot2)
  local_ggplot_state()
  use_phw_ggplot()
  local_size(16, 16)
  g <- patchwork::patchworkGrob(phw_arrange(board_chart(), board_chart(), ncol = 1))
  expect_lte(legend_cm(g), 16)
})

test_that("phw_arrange collects only the legends its plots show", {
  skip_if_not_installed("patchwork")
  library(ggplot2)
  d <- data.frame(board = c("Cardiff", "Powys", "Hywel Dda"), cases = c(10, 20, 15))
  bars <- ggplot(d, aes(board, cases)) + geom_col() + theme_phw()
  filled <- ggplot(d, aes(board, cases, fill = board)) + geom_col() + theme_phw()
  hidden <- filled + theme(legend.position = "none")
  legend_boxes <- function(g) {
    drawn <- !vapply(g$grobs, inherits, logical(1), what = "zeroGrob")
    g$layout[grepl("^guide-box", g$layout$name) & drawn, ]
  }
  expect_equal(nrow(legend_boxes(patchwork::patchworkGrob(phw_arrange(bars, hidden)))), 0)
  g <- patchwork::patchworkGrob(phw_arrange(hidden, filled, legend = "right"))
  box <- legend_boxes(g)
  expect_equal(nrow(box), 1)
  expect_gt(box$l, max(g$layout$r[grepl("^panel", g$layout$name)]))
})

test_that("a second legend below the chart gets a row of its own and fits", {
  skip_if_not_installed("ragg")
  library(ggplot2)
  local_ggplot_state()
  use_phw_ggplot()
  saved <- NULL
  local_mocked_bindings(ggsave = function(filename, plot, ...) saved <<- plot, .package = "ggplot2")
  phw_save(board_chart(7) + geom_point(aes(shape = "4-week average")), "cases.png")
  local_size()
  expect_lte(legend_cm(ggplotGrob(saved)), 16)
})

test_that("phw_arrange fits legends that don't merge, and kept legends to their own plot", {
  skip_if_not_installed("ragg")
  skip_if_not_installed("patchwork")
  library(ggplot2)
  local_ggplot_state()
  use_phw_ggplot()
  local_size()
  drives <- ggplot(mpg, aes(displ, hwy, shape = drv)) + geom_point()
  expect_lte(legend_cm(patchwork::patchworkGrob(phw_arrange(board_chart(7), drives))), 16)
  g <- patchwork::patchworkGrob(phw_arrange(board_chart(7), board_chart(7), guides = "keep"))
  for (i in 1:2) {
    box <- g$grobs[[which(g$layout$name == paste0("guide-box-bottom-", i))]]
    expect_lte(grid::convertWidth(gtable::gtable_width(box), "cm", valueOnly = TRUE), 8)
  }
  expect_equal(column_shares(3, NULL, 2, c(3, 1)), c(0.75, 0.25, 0.75))
})

test_that("phw_finalise of a finished chart keeps both footers when drawn", {
  library(ggplot2)
  local_ggplot_state()
  use_phw_ggplot()
  twice <- phw_finalise(phw_finalise(board_chart(), source = "Inner", logo = FALSE),
                        source = "Outer", logo = FALSE)
  expect_equal(sum(grid::makeContext(twice)$layout$name == "phw-footer"), 2)
})

test_that("each panel's source line in an arranged figure stays whole and clear of the other", {
  skip_if_not_installed("patchwork")
  cap <- phw_caption("CDSC surveillance system, Public Health Wales", date = as.Date("2025-06-30"))
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point() +
    ggplot2::labs(caption = cap) + theme_phw()
  for (fig in list(phw_arrange(p, p), phw_finalise(phw_arrange(p, p), logo = FALSE))) {
    expect_captions_side_by_side(saved_caption_lines(fig, cap), cap, 16 / 2.54)
  }
})
