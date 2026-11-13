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

test_that("phw_finalise can put the logo on the right with no rule", {
  library(ggplot2)
  p <- ggplot(mpg, aes(displ, hwy)) + geom_point() + labs(caption = "kept")
  f <- phw_finalise(p, logo = FALSE, logo_position = "right", rule = FALSE)
  expect_true("phw-footer" %in% f$layout$name)
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
