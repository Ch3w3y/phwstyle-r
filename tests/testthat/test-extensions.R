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

test_that("phw_arrange figure text follows the settings given to use_phw_ggplot()", {
  skip_if_not_installed("patchwork")
  library(ggplot2)
  local_ggplot_state()
  p <- ggplot(mpg, aes(drv)) + geom_bar()
  ann_size <- function(...) phw_arrange(p, p, title = "T", source = "S", ...)$patches$annotation$theme$text$size
  expect_equal(ann_size(), 11)
  use_phw_ggplot(base_size = 16)
  expect_equal(ann_size(), 16)
  use_phw_ggplot(accessible = TRUE)
  expect_equal(ann_size(), 13)
  expect_equal(ann_size(theme = theme_phw(base_size = 9)), 9)
  theme_set(theme_grey())
  expect_equal(ann_size(), 11)
})

test_that("phw_finalise and phw_title_grob text follow the settings given to use_phw_ggplot()", {
  library(ggplot2)
  local_ggplot_state()
  p <- ggplot(mpg, aes(class)) + geom_bar() + labs(title = "Panel")
  footer_size <- function(...) {
    fp <- phw_finalise(p, source = "mpg", logo = FALSE, ...)
    fp$grobs[[which(fp$layout$name == "phw-footer")]]$children$text$gp$fontsize
  }
  title_size <- function(...) phw_title_grob("Figure", "Sub", ...)$grobs[[1]]$children[[1]]$gp$fontsize
  expect_equal(footer_size(), 8.5)
  expect_equal(title_size(), 14)
  use_phw_ggplot(base_size = 16, accessible = TRUE)
  expect_equal(footer_size(), 8.5 * 16 / 11)
  expect_gte(title_size(), calc_element("plot.title", theme_get())$size)
  use_phw_ggplot(accessible = TRUE)
  expect_equal(footer_size(), 8.5 * 13 / 11)
  expect_equal(footer_size(text_size = 9), 9)
  expect_equal(title_size(size = 12), 12)
  theme_set(theme_grey())
  expect_equal(footer_size(), 8.5)
  expect_equal(title_size(), 14)
})

test_that("phw_save bg sets the background of a phw_arrange figure", {
  skip_if_not_installed("patchwork")
  skip_if_not_installed("png")
  library(ggplot2)
  p <- ggplot(mpg, aes(displ, hwy)) + geom_point()
  pw <- phw_arrange(p, p, title = "T", source = "S")
  for (plot in list(pw, phw_finalise(pw, logo = FALSE))) {
    out <- withr::local_tempfile(fileext = ".png")
    img <- png::readPNG(phw_save(plot, out, width = 8, height = 5, dpi = 72, bg = "transparent"))
    expect_lt(mean(img[, , 4] == 1), 0.5)
  }
})

test_that("phw_finalise keeps every panel, the title and the tags of a phw_arrange figure", {
  skip_if_not_installed("patchwork")
  library(ggplot2)
  p1 <- ggplot(mpg, aes(displ, hwy)) + geom_point() + labs(title = "P1")
  p2 <- ggplot(mpg, aes(drv)) + geom_bar() + labs(title = "P2")
  f <- phw_finalise(phw_arrange(p1, p2, title = "FIG", source = "S", tag_levels = "A"),
                    logo = FALSE)
  labels <- function(g) {
    own <- if (inherits(g, "text")) g$label
    c(own, unlist(lapply(c(g$grobs, g$children), labels)))
  }
  expect_true(all(c("P1", "P2", "FIG", "A", "B") %in% labels(f)))
  expect_true("phw-footer" %in% f$layout$name)
})

test_that("phw_finalise draws a phw_arrange figure of plots that keep their shape", {
  skip_if_not_installed("patchwork")
  skip_if_not_installed("png")
  library(ggplot2)
  p <- ggplot(mpg, aes(displ, hwy)) + geom_point() + coord_fixed()
  f <- phw_finalise(phw_arrange(p, p), source = "S", logo = FALSE)
  out <- withr::local_tempfile(fileext = ".png")
  expect_no_error(phw_save(f, out, width = 8, height = 5, dpi = 72))
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

test_that("phw_title_grob makes room for every title and subtitle line", {
  skip_if_not_installed("gridExtra")
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  top_row <- function(title, subtitle = NULL) {
    g <- gridExtra::arrangeGrob(grid::nullGrob(), top = phw_title_grob(title, subtitle))
    grid::convertHeight(g$heights[1], "pt", valueOnly = TRUE)
  }
  one <- top_row("Title", "Sub")
  expect_gt(top_row("Title\nsecond line", "Sub") - one, 14)
  expect_gt(top_row("Title", "Sub\nsecond line") - one, 11)
  expect_gt(top_row("Title\nsecond line") - top_row("Title"), 14)

  kids <- phw_title_grob("Title\nsecond line", "Sub")$grobs[[1]]$children
  title_bottom <- grid::unit(1, "mm") + grid::grobHeight(kids[[1]])
  sub_top <- grid::unit(1, "npc") - kids[[2]]$y
  expect_gt(grid::convertHeight(sub_top - title_bottom, "pt", valueOnly = TRUE), 0)
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
