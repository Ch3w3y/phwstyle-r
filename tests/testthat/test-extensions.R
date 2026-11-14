test_that("extension geoms pick up PHW defaults", {
  skip_if_not_installed("ggrepel")
  skip_if_not_installed("treemapify")
  loadNamespace("ggrepel"); loadNamespace("treemapify")
  changed <- phw_style_extensions(c("ggrepel", "treemapify"))
  expect_true("ggrepel::GeomTextRepel" %in% changed)
  expect_equal(ggrepel::GeomTextRepel$default_aes$family, phw_font())
  expect_equal(ggrepel::GeomTextRepel$default_aes$colour, phw_colours[["text"]])
  # Older versions of treemapify don't export their geoms.
  treemap_text <- get("GeomTreemapText", asNamespace("treemapify"))
  expect_equal(treemap_text$default_aes$colour, "#FFFFFF")
})

test_that("extension rules leave theme-based defaults alone", {
  da <- list(colour = quote(from_theme(ink)), fill = "grey70", family = "")
  new <- phwstyle:::extension_defaults("GeomX", da)
  expect_null(new$colour)
  expect_equal(new$family, phw_font())
  new2 <- phwstyle:::extension_defaults("GeomY", list(colour = "black", fill = "grey70"))
  expect_equal(new2, list(colour = "#FFFFFF", fill = phw_colours[["navy"]]))
})

test_that("phw_arrange builds a patchwork with a PHW caption", {
  skip_if_not_installed("patchwork")
  library(ggplot2)
  p1 <- ggplot(mpg, aes(displ, hwy, colour = drv)) + geom_point()
  p2 <- ggplot(mpg, aes(drv, fill = drv)) + geom_bar()
  pw <- phw_arrange(p1, p2, title = "T", source = "S", tag_levels = "A")
  expect_s3_class(pw, "patchwork")
  expect_equal(pw$patches$annotation$caption, "Source: S")
  f <- phw_finalise(pw, logo = FALSE)
  expect_true("phw-footer" %in% f$layout$name)
  out <- withr::local_tempfile(fileext = ".png")
  phw_save(pw, out, dpi = 72)
  expect_true(file.exists(out))
})

test_that("phw_finalise and phw_title_grob work with gridExtra", {
  skip_if_not_installed("gridExtra")
  library(ggplot2)
  p <- ggplot(mpg, aes(displ, hwy)) + geom_point()
  g <- gridExtra::arrangeGrob(p, p, ncol = 2, top = phw_title_grob("Title", "Sub"))
  f <- phw_finalise(g, source = "S", logo = FALSE)
  expect_true("phw-footer" %in% f$layout$name)
  expect_s3_class(phw_title_grob("Only a title"), "gtable")
})

test_that("phw_arrange checks legend, each plot and caption_args", {
  skip_if_not_installed("patchwork")
  p1 <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_error(phw_arrange(p1, p1, legend = "bottm"), "bottom")
  expect_error(phw_arrange(p1, mtcars), "Plot 2 is <data.frame>")
  expect_error(phw_arrange(plots = list(p1, NULL)), "Plot 2 is <NULL>")
  expect_error(phw_arrange(p1, source = "S", caption_args = "x"), "named list")
})

test_that("phw_style_extensions stops on a package that is not installed", {
  expect_error(phw_style_extensions("notapkg"), "not installed")
})
