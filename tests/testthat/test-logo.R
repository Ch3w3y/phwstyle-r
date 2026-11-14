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
