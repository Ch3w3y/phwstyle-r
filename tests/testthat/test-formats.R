test_that("graphics and reference document are available", {
  for (g in c("band", "cover", "cover_wide")) expect_true(file.exists(phw_graphic(g)))
  docx <- phw_reference_docx()
  expect_true(file.exists(docx))
  dir <- withr::local_tempdir()
  utils::unzip(docx, exdir = dir)
  footer <- paste(readLines(list.files(file.path(dir, "word"), "^footer", full.names = TRUE)[1], warn = FALSE), collapse = "")
  expect_match(footer, "Page")
})

test_that("logo lookup honours the option and returns NULL when absent", {
  dir <- withr::local_tempdir()
  writeLines("<svg/>", file.path(dir, "phw-logo-blue.svg"))
  withr::local_options(phwstyle.logo_dir = dir)
  expect_equal(normalizePath(phw_logo("blue", "svg")), normalizePath(file.path(dir, "phw-logo-blue.svg")))
  expect_true(is.null(phw_logo("black", "png")) || file.exists(phw_logo("black", "png")))
})

test_that("R Markdown formats construct", {
  skip_if_not_installed("rmarkdown")
  expect_s3_class(phw_html_document(), "rmarkdown_output_format")
  expect_s3_class(phw_word_document(), "rmarkdown_output_format")
  expect_s3_class(phw_pdf_document(), "rmarkdown_output_format")
  tex <- readLines(phw_latex_header(team = "Team"))
  expect_false(any(grepl("%%[A-Z]+%%", tex)))
  expect_true(any(grepl("Page", tex)))
})

test_that("use_phw_quarto copies the extension and a template", {
  dir <- withr::local_tempdir()
  suppressMessages(use_phw_quarto(dir, "report"))
  expect_true(file.exists(file.path(dir, "_extensions", "phw", "_extension.yml")))
  expect_true(file.exists(file.path(dir, "_extensions", "phw", "fonts", "Ubuntu-Regular.ttf")))
  expect_true(file.exists(file.path(dir, "report.qmd")))
})

test_that("the Word reference document renders", {
  skip_if_not(rmarkdown::pandoc_available())
  md <- withr::local_tempfile(fileext = ".md")
  writeLines(c("# Heading", "", "Text"), md)
  out <- withr::local_tempfile(fileext = ".docx")
  rmarkdown::pandoc_convert(md, to = "docx", output = out,
                            options = c("--reference-doc", phw_reference_docx()))
  expect_true(file.exists(out))
})

test_that("phw_setup_check reports every item", {
  res <- suppressMessages(phw_setup_check(install = FALSE))
  expect_s3_class(res, "data.frame")
  expect_true(all(c("item", "ok", "fix") %in% names(res)))
  expect_true(any(grepl("Ubuntu", res$item)))
  expect_true(all(nzchar(res$fix[!res$ok])))
})
