test_that("a logo folder with no logo files warns", {
  withr::local_options(phwstyle.logo_dir = file.path(withr::local_tempdir(), "missing"),
                       rlib_warning_verbosity = "verbose")
  expect_warning(phw_logo("blue"), "has no PHW logo file")
  dir <- withr::local_tempdir()
  writeLines("<svg/>", file.path(dir, "logo.svg"))
  withr::local_options(phwstyle.logo_dir = dir)
  expect_warning(phw_logo("blue", "svg"), "phw-logo-blue.png")
})

test_that("phw_download_logos saves nothing when the reply is not an SVG", {
  page <- withr::local_tempfile(fileext = ".html")
  writeLines("<html><body>Sign in <svg></svg></body></html>", page)
  cache <- withr::local_tempdir()
  local_mocked_bindings(logo_cache_dir = function() cache)
  expect_warning(out <- phw_download_logos(ask = FALSE, url = paste0("file://", page)), "not an SVG")
  expect_null(out)
  expect_length(list.files(cache), 0)
})

test_that("phw_finalise writes the organisation name when no logo is installed", {
  local_mocked_bindings(phw_logo = function(...) NULL)
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  footer_text <- function(fp) {
    footer <- fp$grobs[[which(fp$layout$name == "phw-footer")]]
    unlist(lapply(footer$children, function(g) if (inherits(g, "text")) g$label))
  }
  expect_true("Public Health Wales" %in% footer_text(phw_finalise(p, source = "S")))
  expect_true("Iechyd Cyhoeddus Cymru" %in% footer_text(phw_finalise(p, org = "Iechyd Cyhoeddus Cymru")))
  expect_false("Public Health Wales" %in% footer_text(phw_finalise(p, logo = FALSE)))
})

test_that("the organisation name and the source never overlap", {
  local_mocked_bindings(phw_logo = function(...) NULL)
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  src <- "Public Health Wales Observatory analysis of hospital admissions"
  boxes <- function(fp, width_cm) {
    footer <- fp$grobs[[which(fp$layout$name == "phw-footer")]]
    grid::pushViewport(grid::viewport(width = grid::unit(width_cm, "cm")))
    grid::pushViewport(grid::viewport(height = grid::grobHeight(footer)))
    on.exit(grid::popViewport(2))
    labels <- lapply(grid::forceGrob(footer)$children, function(g) if (inherits(g, "text")) g)
    labels <- Filter(Negate(is.null), labels)
    is_org <- vapply(labels, function(g) identical(g$label, phw_org), logical(1))
    lapply(list(text = labels[!is_org][[1]], logo = labels[is_org][[1]]), function(g) c(
      x0 = grid::convertX(grid::grobX(g, "west"), "cm", valueOnly = TRUE),
      x1 = grid::convertX(grid::grobX(g, "east"), "cm", valueOnly = TRUE),
      y0 = grid::convertY(grid::grobY(g, "south"), "cm", valueOnly = TRUE),
      y1 = grid::convertY(grid::grobY(g, "north"), "cm", valueOnly = TRUE)))
  }
  apart <- function(a, b) a[["x1"]] <= b[["x0"]] || b[["x1"]] <= a[["x0"]] ||
    a[["y1"]] <= b[["y0"]] || b[["y1"]] <= a[["y0"]]
  for (side in c("left", "right")) {
    fp <- phw_finalise(p, source = src, logo_position = side)
    for (w in c(6, 10, 16)) {
      b <- boxes(fp, w)
      expect_true(apart(b$text, b$logo), label = paste(side, w, "cm"))
      expect_true(b$text[["x0"]] >= 0 && b$text[["x1"]] <= w, label = paste(side, w, "cm"))
    }
    wide <- boxes(fp, 16)
    expect_equal(mean(wide$text[c("y0", "y1")]), mean(wide$logo[c("y0", "y1")]))
  }
})

test_that("phw_finalise says when a logo file is missing or logo is wrong", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_error(phw_finalise(p, logo = "my-logo.png"), "file not found")
  expect_error(phw_finalise(p, logo = "logos/phw"), "file not found")
  expect_error(phw_finalise(p, logo = TRUE), "must be \"blue\"")
  expect_error(phw_finalise(p, logo = "blu"), "Did you mean")
  expect_error(phw_finalise(p, sorce = "x"), "sorce")
})

test_that("phw_save needs a ggplot or a grob", {
  f <- withr::local_tempfile(fileext = ".png")
  expect_error(phw_save(NULL, f), "`plot` must be a ggplot or a grob")
  expect_false(file.exists(f))
})

test_that("a grey + alpha PNG logo draws like an RGBA one", {
  skip_if_not_installed("png")
  skip_if_not_installed("ragg")
  dir <- withr::local_tempdir()
  for (v in c("blue", "white", "black")) {
    png::writePNG(array(c(rep(0.2, 4800), rep(1, 4800)), c(40, 120, 2)),
                  file.path(dir, sprintf("phw-logo-%s.png", v)))
  }
  withr::local_options(phwstyle.logo_dir = dir)
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  f <- withr::local_tempfile(fileext = ".png")
  expect_no_error(phw_save(phw_finalise(p, logo = "black"), f, width = 16, height = 10))
  expect_true(file.exists(f))
  band <- png::readPNG(band_with_logo(withr::local_tempfile(fileext = ".png")))
  expect_equal(dim(band)[1:2], c(260, 2480))
  # The logo is drawn in its own grey, not dropped.
  expect_true(any(abs(band[130, 211:400, 1] - 0.2) < 0.02))
})
