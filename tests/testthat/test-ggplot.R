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
