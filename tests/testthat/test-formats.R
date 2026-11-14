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

# A small report that writes down the colours it used, so a render can be
# checked without looking at the pictures.
report_lines <- function(header, setup = character()) {
  c("---", "title: Palette check", header, "---", "",
    "```{r, include = FALSE}",
    "library(ggplot2)",
    "library(phwstyle)",
    setup,
    "d <- function(n) data.frame(g = factor(paste('Group', seq_len(n))), v = seq_len(n))",
    "bars <- function(n) ggplot(d(n), aes(g, v, fill = g)) + geom_col()",
    "used <- function(p) paste(unique(layer_data(p)$fill), collapse = ' ')",
    "```", "",
    "PALETTE `r phw_default_palette()`", "",
    "FOUR `r used(bars(4))`", "",
    "SIX `r used(bars(6))`", "",
    "KEYED `r used(bars(6) + scale_fill_phw_d(key = 'report_test'))`", "",
    "PLAIN `r used(ggplot(d(3), aes(g, v)) + geom_col())`", "",
    "```{r, echo = FALSE, fig.cap = 'Six groups'}",
    "bars(6)",
    "```", "",
    "```{r, echo = FALSE}",
    "if (requireNamespace('flextable', quietly = TRUE)) phw_flextable_groups(phw_flextable(d(6)), 'g')",
    "```")
}

expect_report_colours <- function(text, palette) {
  cols <- if (palette == "accessible") phw_palettes$accessible else phw_palettes$extended
  expect_match(text, paste("PALETTE", palette), fixed = TRUE)
  expect_match(text, paste("FOUR", paste(cols[1:4], collapse = " ")), fixed = TRUE)
  expect_match(text, paste("SIX", paste(cols[1:6], collapse = " ")), fixed = TRUE)
  expect_match(text, paste("KEYED", paste(cols[1:6], collapse = " ")), fixed = TRUE)
  expect_match(text, paste("PLAIN", phw_colours[["navy"]]), fixed = TRUE)
}

test_that("every R Markdown format styles charts and tables before knitting", {
  skip_if_not_installed("rmarkdown")
  formats <- list(word = phw_word_document, pdf = phw_pdf_document)
  if (requireNamespace("bslib", quietly = TRUE)) formats$html <- phw_html_document
  for (nm in names(formats)) {
    local({
      local_ggplot_state()
      ggplot2::theme_set(ggplot2::theme_grey())
      if (requireNamespace("flextable", quietly = TRUE)) {
        old_ft <- flextable::get_flextable_defaults()
        withr::defer(do.call(flextable::set_flextable_defaults, old_ft))
      }
      fmt <- formats[[nm]]()
      expect_true(is.function(fmt$pre_knit))
      # This is the step that runs at the start of every render.
      expect_no_warning(fmt$pre_knit(input = "report.Rmd"))
      expect_equal(ggplot2::theme_get()$plot.title$colour, phw_colours[["navy"]], info = nm)
      p <- ggplot2::ggplot(groups(6), ggplot2::aes(g, v, fill = g)) + ggplot2::geom_col()
      expect_equal(plot_colours(p), phw_palettes$extended[1:6], info = nm)
      expect_equal(plot_colours(ggplot2::ggplot(groups(2), ggplot2::aes(g, v)) + ggplot2::geom_col()),
                   phw_colours[["navy"]], info = nm)
      if (requireNamespace("flextable", quietly = TRUE)) {
        expect_equal(flextable::get_flextable_defaults()$font.family, phw_font(), info = nm)
      }
      fmt$on_exit()
    })
  }
})

test_that("the palette argument applies for one render and is then put back", {
  skip_if_not_installed("rmarkdown")
  local_ggplot_state()
  expect_error(phw_word_document(palette = "no_such_palette"), "Unknown palette")
  fmt <- phw_word_document(palette = "accessible")
  expect_null(getOption("phwstyle.palette"))
  fmt$pre_knit(input = "report.Rmd")
  expect_equal(phw_default_palette(), "accessible")
  p <- ggplot2::ggplot(groups(6), ggplot2::aes(g, v, fill = g)) + ggplot2::geom_col()
  expect_equal(plot_colours(p), phw_palettes$accessible[1:6])
  fmt$on_exit()
  expect_null(getOption("phwstyle.palette"))
  expect_equal(plot_colours(p), phw_palettes$extended[1:6])
  # A palette someone set themselves comes back too.
  options(phwstyle.palette = "extended")
  fmt$pre_knit(input = "report.Rmd")
  fmt$on_exit()
  expect_equal(getOption("phwstyle.palette"), "extended")
  # style_plots = FALSE leaves the theme alone but still sets the palette.
  options(phwstyle.palette = NULL)
  ggplot2::theme_set(ggplot2::theme_grey())
  plain <- phw_word_document(style_plots = FALSE, palette = "accessible")
  plain$pre_knit(input = "report.Rmd")
  expect_equal(phw_default_palette(), "accessible")
  expect_null(ggplot2::theme_get()$plot.title$colour)
  plain$on_exit()
  expect_null(phw_word_document(style_plots = FALSE)$pre_knit)
})

test_that("a styling step that fails warns and lets the document render", {
  skip_if_not_installed("rmarkdown")
  local_ggplot_state()
  if (requireNamespace("flextable", quietly = TRUE)) {
    old_ft <- flextable::get_flextable_defaults()
    withr::defer(do.call(flextable::set_flextable_defaults, old_ft))
  }
  local_mocked_bindings(use_phw_ggplot = function(...) stop("ggplot2 changed something"))
  fmt <- phw_word_document(palette = "accessible")
  expect_warning(fmt$pre_knit(input = "report.Rmd"), "could not be set up for charts")
  w <- tryCatch(fmt$pre_knit(input = "report.Rmd"), warning = function(w) conditionMessage(w))
  expect_match(w, "use_phw_ggplot")
  expect_match(w, "ggplot2 changed something")
  # The palette was still set, so tables and widgets follow it.
  expect_equal(phw_default_palette(), "accessible")
  fmt$on_exit()
})

test_that("a Word document renders in default and in accessible colours", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  local_ggplot_state()
  phw_key_reset("report_test")
  withr::defer(phw_key_reset("report_test"))
  dir <- withr::local_tempdir()
  rmd <- file.path(dir, "report.Rmd")
  writeLines(report_lines("output: phwstyle::phw_word_document"), rmd)
  # The same document, three times in one session.
  default <- rmarkdown::render(rmd, output_file = "default.docx", quiet = TRUE)
  access <- rmarkdown::render(rmd, output_file = "accessible.docx", quiet = TRUE,
                              output_options = list(palette = "accessible"))
  again <- rmarkdown::render(rmd, output_file = "again.docx", quiet = TRUE)
  expect_report_colours(docx_text(default), "main")
  expect_report_colours(docx_text(access), "accessible")
  expect_report_colours(docx_text(again), "main")
  expect_null(getOption("phwstyle.palette"))
  # The chart is in the document.
  expect_true(any(grepl("^word/media/.*\\.png$", utils::unzip(default, list = TRUE)$Name)))

  # The switch can also live in the YAML header, for the format or the document.
  writeLines(report_lines(c("output:", "  phwstyle::phw_word_document:", "    palette: accessible")), rmd)
  expect_report_colours(docx_text(rmarkdown::render(rmd, output_file = "yaml-format.docx", quiet = TRUE)),
                        "accessible")
  writeLines(report_lines(c("output: phwstyle::phw_word_document", "phw-palette: accessible")), rmd)
  expect_report_colours(docx_text(rmarkdown::render(rmd, output_file = "yaml-key.docx", quiet = TRUE)),
                        "accessible")
  # Once the render is over, that document's palette no longer applies.
  expect_equal(phw_default_palette(), "main")
})

test_that("an HTML document renders in default and in accessible colours", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not_installed("bslib")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  local_ggplot_state()
  phw_key_reset("report_test")
  withr::defer(phw_key_reset("report_test"))
  dir <- withr::local_tempdir()
  rmd <- file.path(dir, "report.Rmd")
  writeLines(report_lines("output: phwstyle::phw_html_document"), rmd)
  text <- function(f) gsub("\\s+", " ", gsub("<[^>]+>", " ", paste(readLines(f, warn = FALSE), collapse = " ")))
  html <- rmarkdown::render(rmd, output_file = "default.html", quiet = TRUE)
  expect_report_colours(text(html), "main")
  expect_match(paste(readLines(html, warn = FALSE), collapse = " "), "phw-band", fixed = TRUE)
  withr::local_envvar(PHWSTYLE_PALETTE = "accessible")
  expect_report_colours(text(rmarkdown::render(rmd, output_file = "accessible.html", quiet = TRUE)),
                        "accessible")
})

test_that("a Quarto Word document renders in default and in accessible colours", {
  skip_on_cran()
  skip_if_not_installed("knitr")
  skip_if_not_installed("rmarkdown")
  quarto <- Sys.which("quarto")
  skip_if(!nzchar(quarto), "Quarto is not installed")
  dir <- withr::local_tempdir()
  suppressMessages(use_phw_quarto(dir, "none"))
  writeLines(report_lines(c("format: phw-docx"), setup = "use_phw_ggplot()"), file.path(dir, "report.qmd"))
  render <- function(out, palette = NA, file = "report.qmd") {
    withr::local_dir(dir)
    withr::local_envvar(PHWSTYLE_PALETTE = palette, QUARTO_R = R.home("bin"))
    log <- suppressWarnings(system2(quarto, c("render", file, "--to", "phw-docx", "-o", out),
                                    stdout = TRUE, stderr = TRUE))
    if (!file.exists(out)) fail(paste(c("quarto render failed:", utils::tail(log, 15)), collapse = "\n"))
    file.path(dir, out)
  }
  default <- render("default.docx")
  skip_if_not(file.exists(default))
  expect_report_colours(docx_text(default), "main")
  # One render switched from the command line, with the document unchanged.
  expect_report_colours(docx_text(render("accessible.docx", palette = "accessible")), "accessible")
  # Or switched for good in the document's YAML header.
  writeLines(report_lines(c("format: phw-docx", "phw-palette: accessible"), setup = "use_phw_ggplot()"),
             file.path(dir, "keyed.qmd"))
  expect_report_colours(docx_text(render("keyed.docx", file = "keyed.qmd")), "accessible")
})

test_that("every Quarto format renders its starter document", {
  skip_on_cran()
  skip_if_not_installed("knitr")
  skip_if_not_installed("rmarkdown")
  quarto <- Sys.which("quarto")
  skip_if(!nzchar(quarto), "Quarto is not installed")
  # format, starter document, output file, packages the starter document uses
  cases <- list(
    list("phw-html", "report", "html", "flextable"),
    list("phw-docx", "report", "docx", "flextable"),
    list("phw-typst", "report", "pdf", "flextable"),
    list("phw-revealjs", "slides", "html", character()),
    list("phw-dashboard", "dashboard", "html", c("plotly", "reactable"))
  )
  for (case in cases) {
    fmt <- case[[1]]
    need <- case[[4]]
    if (!all(vapply(need, requireNamespace, logical(1), quietly = TRUE))) next
    dir <- withr::local_tempdir()
    suppressMessages(use_phw_quarto(dir, case[[2]]))
    out <- paste0("out.", case[[3]])
    log <- withr::with_dir(dir, withr::with_envvar(
      c(QUARTO_R = R.home("bin")),
      suppressWarnings(system2(quarto, c("render", paste0(case[[2]], ".qmd"), "--to", fmt, "-o", out),
                               stdout = TRUE, stderr = TRUE))))
    made <- file.exists(file.path(dir, out)) && file.size(file.path(dir, out)) > 1000
    expect_true(made, info = paste(c(fmt, utils::tail(log, 12)), collapse = "\n"))
  }
})

test_that("a PDF document renders with XeLaTeX", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  skip_if(!nzchar(Sys.which("xelatex")), "XeLaTeX is not installed")
  local_ggplot_state()
  phw_key_reset("report_test")
  withr::defer(phw_key_reset("report_test"))
  dir <- withr::local_tempdir()
  rmd <- file.path(dir, "report.Rmd")
  writeLines(report_lines(c("output:", "  phwstyle::phw_pdf_document:", "    keep_tex: true")), rmd)
  pdf <- rmarkdown::render(rmd, output_file = "default.pdf", quiet = TRUE)
  expect_true(file.exists(pdf))
  expect_gt(file.size(pdf), 5000)
  # The colours the document reports are in the LaTeX source it was built from.
  tex <- paste(readLines(file.path(dir, "default.tex"), warn = FALSE), collapse = " ")
  expect_report_colours(gsub("\\\\#", "#", tex), "main")
})

test_that("use_phw_quarto copies the extension and a template", {
  dir <- withr::local_tempdir()
  suppressMessages(use_phw_quarto(dir, "report"))
  expect_true(file.exists(file.path(dir, "_extensions", "phw", "_extension.yml")))
  expect_true(file.exists(file.path(dir, "_extensions", "phw", "fonts", "Ubuntu-Regular.ttf")))
  expect_true(file.exists(file.path(dir, "report.qmd")))
})

test_that("use_phw_quarto ships the PowerPoint template for the pptx format", {
  dir <- withr::local_tempdir()
  suppressMessages(use_phw_quarto(dir, "none"))
  ext <- file.path(dir, "_extensions", "phw")
  expect_true(file.exists(file.path(ext, "phw-reference.pptx")))
  cfg <- paste(readLines(file.path(ext, "_extension.yml")), collapse = "\n")
  expect_match(cfg, "pptx:\\s+reference-doc: phw-reference.pptx")
  deck <- officer::read_pptx(file.path(ext, "phw-reference.pptx"))
  expect_equal(unique(officer::layout_summary(deck)$master), "PHW")
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
