test_that("graphics and reference document are available", {
  for (g in c("band", "cover", "cover_wide")) expect_true(file.exists(phw_graphic(g)))
  docx <- phw_reference_docx()
  expect_true(file.exists(docx))
  dir <- withr::local_tempdir()
  utils::unzip(docx, exdir = dir)
  footer <- paste(readLines(list.files(file.path(dir, "word"), "^footer", full.names = TRUE)[1], warn = FALSE), collapse = "")
  expect_match(footer, "Page")
})

test_that("the reference document has no text for officer to keep", {
  skip_if_not_installed("officer")
  doc <- officer::read_docx(phw_reference_docx())
  expect_equal(NROW(officer::docx_summary(doc)), 0L)
  doc <- officer::body_add_par(doc, "My report", style = "Heading 1")
  out <- withr::local_tempfile(fileext = ".docx")
  print(doc, target = out)
  saved <- officer::read_docx(out)
  expect_equal(officer::docx_summary(saved)$text, "My report")
  expect_length(xml2::xml_find_all(officer::docx_body_xml(saved), "//w:headerReference"), 1)
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

test_that("captioned figures in a Quarto Word document fit their cells without rules", {
  skip_on_cran()
  skip_if_not_installed("knitr")
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("xml2")
  quarto <- Sys.which("quarto")
  skip_if(!nzchar(quarto), "Quarto is not installed")
  dir <- withr::local_tempdir()
  suppressMessages(use_phw_quarto(dir, "report"))
  # A wide picture with no resolution set, which pandoc shrinks to the text width.
  grDevices::png(file.path(dir, "wide.png"), width = 1200, height = 500)
  graphics::plot(1)
  grDevices::dev.off()
  extra <- c("", "```{r}", "#| label: fig-wide", "#| fig-cap: Wide chart", "#| fig-width: 9", "plot(1)", "```",
             "", "![Saved chart](wide.png){#fig-saved}", "",
             "| a | b |", "|---|---|", "| 1 | 2 |", "", ": Data table {#tbl-data}")
  write(extra, file.path(dir, "report.qmd"), append = TRUE)
  log <- withr::with_dir(dir, withr::with_envvar(
    c(QUARTO_R = R.home("bin")),
    suppressWarnings(system2(quarto, c("render", "report.qmd", "--to", "phw-docx"), stdout = TRUE, stderr = TRUE))))
  docx <- file.path(dir, "report.docx")
  if (!file.exists(docx)) fail(paste(c("quarto render failed:", utils::tail(log, 15)), collapse = "\n"))
  utils::unzip(docx, c("word/document.xml", "word/styles.xml"), exdir = dir)
  doc <- xml2::read_xml(file.path(dir, "word", "document.xml"))
  styles <- xml2::read_xml(file.path(dir, "word", "styles.xml"))
  page <- function(el, side) as.numeric(xml2::xml_attr(xml2::xml_find_first(doc, paste0("//w:body/w:sectPr/", el)), side))
  text_width <- (page("w:pgSz", "w") - page("w:pgMar", "left") - page("w:pgMar", "right")) / 1440
  pictures <- xml2::xml_find_all(doc, "//wp:inline")
  expect_length(pictures, 4)
  for (pic in pictures) {
    # Quarto 1.5's pandoc cannot style the table, so there the figure is left out of it.
    padding <- 0
    layout <- xml2::xml_find_first(pic, "ancestor::w:tbl[1]")
    if (!inherits(layout, "xml_missing")) {
      id <- xml2::xml_attr(xml2::xml_find_first(layout, "w:tblPr/w:tblStyle"), "val")
      style <- xml2::xml_find_first(styles, sprintf("//w:style[@w:styleId='%s']/w:tblPr", id))
      padding <- sum(as.numeric(xml2::xml_attr(
        xml2::xml_find_all(style, "w:tblCellMar/*[self::w:left or self::w:right]"), "w"))) / 1440
      rules <- xml2::xml_attr(xml2::xml_find_all(style, "w:tblBorders/*"), "val")
      expect_true(all(rules %in% c("nil", "none")), info = id)
    }
    width <- as.numeric(xml2::xml_attr(xml2::xml_find_first(pic, "wp:extent"), "cx")) / 914400
    expect_lte(width, text_width - padding + 0.001)
  }
  # The knitr figures are drawn at the Word size, so their text isn't shrunk.
  line <- xml2::xml_find_first(doc, "//w:bookmarkStart[@w:name='fig-line']/following::wp:extent[1]")
  expect_equal(as.numeric(xml2::xml_attr(line, "cx")) / 914400, 6.3, tolerance = 0.02)
  # A data table keeps its own rules inside the table Quarto lays it out in.
  data <- xml2::xml_find_first(doc, "//w:bookmarkStart[@w:name='tbl-data']/following::w:tbl[1]/w:tblPr/w:tblStyle")
  expect_equal(xml2::xml_attr(data, "val"), "Table")
})

test_that("a phw_flextable caption shows in Quarto HTML, Word and PDF", {
  skip_on_cran()
  skip_if_not_installed("knitr")
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("flextable")
  quarto <- Sys.which("quarto")
  skip_if(!nzchar(quarto), "Quarto is not installed")
  dir <- withr::local_tempdir()
  suppressMessages(use_phw_quarto(dir, "none"))
  writeLines(c("---", "title: Tables", "keep-tex: true", "---", "",
               "```{r}", "#| echo: false", "library(phwstyle)",
               "phw_flextable(head(mtcars[, 1:3]), caption = 'Cases by board', number = 1, source = 'mtcars')",
               "```", "",
               "```{r}", "#| echo: false",
               "phw_flextable_heat(phw_flextable(head(mtcars[, 1:3]), caption = 'Heat caption'), mpg)",
               "```", "",
               "```{r}", "#| echo: false", "#| label: tbl-chunk", "#| tbl-cap: Chunk caption",
               "phw_flextable(head(mtcars[, 1:3]), caption = 'Chunk caption')",
               "```"), file.path(dir, "tables.qmd"))
  render <- function(fmt, out) {
    withr::local_dir(dir)
    withr::local_envvar(QUARTO_R = R.home("bin"))
    log <- suppressWarnings(system2(quarto, c("render", "tables.qmd", "--to", fmt), stdout = TRUE, stderr = TRUE))
    if (!file.exists(out)) fail(paste(c("quarto render failed:", utils::tail(log, 15)), collapse = "\n"))
    file.path(dir, out)
  }
  read <- function(file) paste(readLines(file, warn = FALSE, encoding = "UTF-8"), collapse = " ")
  count <- function(text, pattern) lengths(regmatches(text, gregexpr(pattern, text, fixed = TRUE)))
  docx <- render("phw-docx", "tables.docx")
  outputs <- list(html = gsub("<[^>]+>", " ", read(render("phw-html", "tables.html"))),
                  docx = docx_text(docx))
  # Word draws the table's top rule under the caption row from that row's own
  # bottom border.
  utils::unzip(docx, "word/document.xml", exdir = dir)
  xml <- read(file.path(dir, "word", "document.xml"))
  first_row <- regmatches(xml, regexpr("<w:tr\\b.*?</w:tr>", xml, perl = TRUE))
  expect_match(first_row, "Table 1 Cases by board", fixed = TRUE)
  expect_match(first_row, "<w:bottom w:val=\"single\"", fixed = TRUE)
  if (nzchar(Sys.which("xelatex"))) outputs$pdf <- gsub("\\\\ ", " ", read(render("phw-pdf", "tables.tex")))
  for (fmt in names(outputs)) {
    text <- outputs[[fmt]]
    expect_match(text, "Table 1 Cases by board", fixed = TRUE, info = fmt)
    expect_match(text, "Heat caption", fixed = TRUE, info = fmt)
    # A chunk's tbl-cap is Quarto's caption, so the table doesn't repeat it.
    expect_equal(count(text, "Chunk caption"), 1, info = fmt)
  }
})

test_that("a phw_flextable wider than the page fits the text width in Quarto Typst", {
  skip_on_cran()
  skip_if_not_installed("knitr")
  skip_if_not_installed("rmarkdown")
  # Before 0.10.0, flextable puts a table in Typst as an image, not a #table().
  skip_if_not_installed("flextable", "0.10.0")
  quarto <- Sys.which("quarto")
  skip_if(!nzchar(quarto), "Quarto is not installed")
  dir <- withr::local_tempdir()
  suppressMessages(use_phw_quarto(dir, "none"))
  writeLines(c("---", "title: Tables", "format: phw-typst", "keep-typ: true", "---", "",
               "```{r}", "#| echo: false", "library(phwstyle)", "set.seed(1)",
               "boards <- c('Cardiff and Vale', 'Aneurin Bevan', 'Betsi Cadwaladr', 'Swansea Bay')",
               "df <- data.frame(age_group = sample(c('0-14', '15-44', '45-64', '65+'), 200, TRUE),",
               "                 sex = sample(c('Female', 'Male'), 200, TRUE),",
               "                 hb = sample(boards, 200, TRUE))",
               "phw_flextable(phw_summary_table(df, by = hb), caption = 'Cases by health board',",
               "              source = 'PHW surveillance')",
               "```"), file.path(dir, "tables.qmd"))
  log <- withr::with_dir(dir, withr::with_envvar(
    c(QUARTO_R = R.home("bin")),
    suppressWarnings(system2(quarto, c("render", "tables.qmd"), stdout = TRUE, stderr = TRUE))))
  typ <- file.path(dir, "tables.typ")
  if (!file.exists(file.path(dir, "tables.pdf"))) fail(paste(c("quarto render failed:", utils::tail(log, 15)), collapse = "\n"))
  typ <- paste(readLines(typ, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  table <- regmatches(typ, regexpr("(?s)#table\\(\\s*columns: \\([^)]*\\).*?Source: PHW surveillance", typ, perl = TRUE))
  expect_match(table, "Total (n \\= 200)", fixed = TRUE)
  columns <- regmatches(table, regexpr("columns: \\([^)]*\\)", table))
  widths <- as.numeric(regmatches(columns, gregexpr("[0-9.]+(?=in)", columns, perl = TRUE))[[1]])
  expect_length(widths, 6)
  # A4 less the 2 cm side margins of phw-typst. The table starts at the left
  # margin, so within this width the Total column and the right-aligned source
  # line are on the page.
  expect_lte(sum(widths), (210 - 2 * 20) / 25.4 + 0.005)
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

test_that("a PDF document with two authors renders", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  skip_if(!nzchar(Sys.which("xelatex")), "XeLaTeX is not installed")
  local_ggplot_state()
  dir <- withr::local_tempdir()
  rmd <- file.path(dir, "authors.Rmd")
  writeLines(c("---", "title: Report", 'author: ["Jane Smith", "Alan Jones"]', "---", "", "Hello."), rmd)
  pdf <- rmarkdown::render(rmd, phw_pdf_document(), quiet = TRUE)
  expect_true(file.exists(pdf))
})

test_that("a captioned chart in a PDF document stays under its heading", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  skip_if(!nzchar(Sys.which("xelatex")), "XeLaTeX is not installed")
  local_ggplot_state()
  withr::local_options(tinytex.clean = FALSE)
  dir <- withr::local_tempdir()
  rmd <- file.path(dir, "charts.Rmd")
  chart <- function(cap) c(sprintf("```{r, echo = FALSE, fig.cap = '%s'}", cap),
                           "ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()", "```", "")
  text <- paste(rep("Cases rose in every health board this week.", 60), collapse = " ")
  writeLines(c("---", "title: Weekly report", "---", "",
               "## Epidemic curve", "", chart("First chart"),
               "## Bar chart", "", chart("Second chart"),
               "## Summary", "", text, "", "## Notes", "", text), rmd)
  rmarkdown::render(rmd, phw_pdf_document(), quiet = TRUE)
  # The .aux file lists figures and sections in the order they are printed.
  aux <- readLines(file.path(dir, "charts.aux"), warn = FALSE)
  at <- function(what) grep(what, aux, fixed = TRUE)
  expect_lt(at("First chart"), at("{2}Bar chart"))
  expect_gt(at("Second chart"), at("{2}Bar chart"))
  expect_lt(at("Second chart"), at("{3}Summary"))
})

test_that("a PDF document draws the shapes in red, amber and green cells", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not_installed("flextable")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  skip_if(!nzchar(Sys.which("xelatex")), "XeLaTeX is not installed")
  local_ggplot_state()
  withr::local_options(tinytex.clean = FALSE)
  dir <- withr::local_tempdir()
  rmd <- file.path(dir, "rag.Rmd")
  writeLines(c("---", "title: Uptake", "---", "",
               "```{r, echo = FALSE}",
               "u <- data.frame(Area = c('Powys', 'Hywel Dda', 'Cardiff'), Uptake = c(.91, .94, .96))",
               "phwstyle::phw_flextable(u, digits = 2) |>",
               "  phwstyle::phw_flextable_heat(Uptake, palette = 'rag', breaks = c(.92, .95))",
               "```"), rmd)
  pdf <- rmarkdown::render(rmd, phw_pdf_document(), quiet = TRUE)
  expect_true(file.exists(pdf))
  log <- readLines(file.path(dir, "rag.log"), warn = FALSE)
  expect_false(any(grepl("Missing character", log, fixed = TRUE)))
})

test_that("a phw_flextable caption in a PDF document is numbered once", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not_installed("flextable")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  local_ggplot_state()
  dir <- withr::local_tempdir()
  rmd <- file.path(dir, "report.Rmd")
  writeLines(c("---", "title: Tables", "---", "",
               "```{r, echo = FALSE}",
               "phwstyle::phw_flextable(head(mtcars[, 1:4]), caption = 'Counts by board', number = 1)",
               "```", "",
               "```{r, echo = FALSE}",
               "phwstyle::phw_flextable(head(mtcars[, 1:3]), caption = 'No number')",
               "```"), rmd)
  tex <- readLines(rmarkdown::render(rmd, phw_pdf_document(), output_file = "report.tex",
                                     quiet = TRUE), warn = FALSE)
  captions <- grep("\\\\caption\\*?(\\[\\])?\\{", tex, value = TRUE)
  expect_length(grep("Table\\ 1\\ Counts", captions, fixed = TRUE), 2)
  expect_length(grep("No\\ number", captions, fixed = TRUE), 2)
  # LaTeX adds its own "Table N." label to every \caption{} but not to \caption*{}.
  expect_false(any(grepl("\\caption{", tex, fixed = TRUE) | grepl("\\caption[]{", tex, fixed = TRUE)))
})

test_that("a PDF document numbers its top heading level from 1", {
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  local_ggplot_state()
  dir <- withr::local_tempdir()
  rmd <- file.path(dir, "report.Rmd")
  sections <- function(lines, ...) {
    writeLines(c("---", "title: Report", "---", "", lines), rmd)
    tex <- readLines(rmarkdown::render(rmd, phw_pdf_document(...), output_file = "report.tex",
                                       quiet = TRUE), warn = FALSE)
    unlist(regmatches(tex, gregexpr("\\\\(sub)*section\\{[^}]*\\}", tex)))
  }
  expect_equal(sections(c("## Summary", "", "### Detail", "", "## Weekly cases")),
               c("\\section{Summary}", "\\subsection{Detail}", "\\section{Weekly cases}"))
  expect_equal(sections(c("# Summary", "", "## Detail")),
               c("\\section{Summary}", "\\subsection{Detail}"))
  expect_equal(sections(c("## Summary"), number_sections = FALSE), "\\subsection{Summary}")
})

test_that("a phw_flextable in a plain HTML document brings the Ubuntu web font", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not_installed("flextable")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  dir <- withr::local_tempdir()
  rmd <- file.path(dir, "report.Rmd")
  writeLines(c("---", "title: Tables", "---", "",
               "```{r, echo = FALSE}",
               "phwstyle::phw_flextable(data.frame(area = c('Conwy', 'Gwynedd'), cases = c(1234, 56)))",
               "```"), rmd)
  html <- readLines(rmarkdown::render(rmd, rmarkdown::html_document(self_contained = FALSE),
                                      quiet = TRUE), warn = FALSE)
  expect_true(any(grepl("phw-ubuntu-font", html, fixed = TRUE)))
})

test_that("a phw_flextable shown in the Viewer brings the Ubuntu web font", {
  skip_if_not_installed("flextable")
  ft <- phw_flextable(data.frame(area = c("Conwy", "Gwynedd"), cases = c(1234, 56)))
  deps <- htmltools::findDependencies(htmltools::as.tags(ft))
  expect_true("phw-ubuntu-font" %in% vapply(deps, `[[`, "", "name"))
  shown <- NULL
  rlang::local_interactive()
  withr::local_options(viewer = function(url, ...) shown <<- url)
  print(ft)
  expect_true(any(grepl("phw-ubuntu-font", readLines(shown, warn = FALSE), fixed = TRUE)))
})

test_that("a phw_flextable caption shows above the table in a PowerPoint deck", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not_installed("flextable")
  skip_if_not(rmarkdown::pandoc_available("2.4"), "pandoc 2.4 or later is not available")
  dir <- withr::local_tempdir()
  rmd <- file.path(dir, "deck.Rmd")
  writeLines(c("---", "title: Deck", "---", "", "## Table", "",
               "```{r, echo = FALSE}",
               "phwstyle::phw_flextable(head(mtcars[, 1:4]), caption = 'Cars by model', number = 1, source = 'mtcars')",
               "```"), rmd)
  pptx <- rmarkdown::render(rmd, rmarkdown::powerpoint_presentation(reference_doc = phw_reference_pptx()),
                            quiet = TRUE)
  unzipped <- withr::local_tempdir()
  utils::unzip(pptx, exdir = unzipped)
  slides <- list.files(file.path(unzipped, "ppt", "slides"), pattern = "\\.xml$", full.names = TRUE)
  xml <- paste(unlist(lapply(slides, readLines, warn = FALSE)), collapse = "")
  caption <- regexpr("Table 1 Cars by model", xml, fixed = TRUE)
  expect_gt(caption, 0)
  expect_lt(caption, regexpr(">mpg<", xml, fixed = TRUE))
  expect_match(xml, "Source: mtcars", fixed = TRUE)
})

bars_rmd <- function(dir) {
  rmd <- file.path(dir, "bars.Rmd")
  writeLines(c("---", "title: Bars", "---", "", "## Bars", "",
               "```{r, echo = FALSE}",
               "df <- data.frame(Area = paste('Area', LETTERS[1:4]), Cases = c(120, 85, 64, 19))",
               "phwstyle::phw_flextable_bars(phwstyle::phw_flextable(df), Cases)",
               "```"), rmd)
  rmd
}

test_that("bars from phw_flextable_bars() are pictures in the Word report", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not_installed("flextable")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  local_ggplot_state()
  dir <- withr::local_tempdir()
  docx <- rmarkdown::render(bars_rmd(dir), phw_word_document(), quiet = TRUE)
  doc <- xml2::read_xml(unz(docx, "word/document.xml"))
  embed <- xml2::xml_attr(xml2::xml_find_all(doc, "//a:blip"), "embed")
  expect_length(embed, 4)
  rels <- xml2::read_xml(unz(docx, "word/_rels/document.xml.rels"))
  targets <- xml2::xml_attr(xml2::xml_find_all(rels, "//*[local-name() = 'Relationship']"), "Target",
                            ns = character())
  ids <- xml2::xml_attr(xml2::xml_find_all(rels, "//*[local-name() = 'Relationship']"), "Id")
  media <- targets[match(embed, ids)]
  expect_true(all(grepl("^media/", media)))
  expect_true(all(file.path("word", media) %in% utils::unzip(docx, list = TRUE)$Name))
  expect_no_match(xml2::xml_text(doc), "officedown", fixed = TRUE)
})

test_that("a table with bars stops a PowerPoint deck rather than losing them", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not_installed("flextable")
  skip_if_not(rmarkdown::pandoc_available("2.4"), "pandoc 2.4 or later is not available")
  dir <- withr::local_tempdir()
  expect_error(rmarkdown::render(bars_rmd(dir), rmarkdown::powerpoint_presentation(), quiet = TRUE),
               "cannot show images")
})

board_table_rmd <- function(dir) {
  rmd <- file.path(dir, "boards.Rmd")
  writeLines(c("---", "title: Tables", "---", "",
               "```{r, echo = FALSE}",
               "boards <- c('Aneurin Bevan', 'Betsi Cadwaladr', 'Cardiff and Vale', 'Cwm Taf Morgannwg',",
               "            'Hywel Dda', 'Powys', 'Swansea Bay')",
               "ll <- data.frame(age = rep(c('0-4', '5-14', '15-44', '45-64', '65+'), length.out = 700),",
               "                 board = rep(boards, each = 100), sex = rep(c('Female', 'Male'), 350))",
               "phwstyle::phw_flextable(phwstyle::phw_summary_table(ll, vars = c(age, sex), by = board))",
               "```", "", "Text.", "",
               "```{r, echo = FALSE}",
               "phwstyle::phw_flextable(head(mtcars[, 1:4]))",
               "```"), rmd)
  rmd
}

test_that("a table by health board fits the page width of a Word document", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not_installed("flextable")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  local_ggplot_state()
  dir <- withr::local_tempdir()
  docx <- rmarkdown::render(board_table_rmd(dir), phw_word_document(), quiet = TRUE)
  ref <- xml2::read_xml(unz(phw_reference_docx(), "word/document.xml"))
  twips <- function(node, attr) as.numeric(xml2::xml_attr(xml2::xml_find_first(ref, node), attr))
  text_width <- twips("//w:sectPr/w:pgSz", "w") - twips("//w:sectPr/w:pgMar", "left") -
    twips("//w:sectPr/w:pgMar", "right")
  doc <- xml2::read_xml(unz(docx, "word/document.xml"))
  grids <- lapply(xml2::xml_find_all(doc, "//w:tbl/w:tblGrid"), function(g) {
    as.numeric(xml2::xml_attr(xml2::xml_find_all(g, "w:gridCol"), "w"))
  })
  expect_length(grids, 2)
  # Each column's width is rounded to a whole twip.
  expect_lte(sum(grids[[1]]), text_width + length(grids[[1]]))
  # A table that already fits keeps the widths it was given.
  small <- phw_flextable(head(mtcars[, 1:4]))
  expect_equal(grids[[2]] / 1440, small$body$colwidths, tolerance = 0.01, ignore_attr = TRUE)
})

test_that("a table by health board fits the text width of a PDF document", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not_installed("flextable")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  local_ggplot_state()
  dir <- withr::local_tempdir()
  tex <- rmarkdown::render(board_table_rmd(dir), phw_pdf_document(), output_file = "boards.tex", quiet = TRUE)
  tex <- paste(readLines(tex, warn = FALSE), collapse = "\n")
  specs <- regmatches(tex, gregexpr("\\\\begin\\{longtable\\}\\[[a-z]\\]\\{[^\n]*\\}", tex))[[1]]
  widths <- lapply(specs, function(s) as.numeric(regmatches(s, gregexpr("(?<=p\\{)[0-9.]+(?=in\\})", s, perl = TRUE))[[1]]))
  expect_length(widths, 2)
  sep <- as.numeric(regmatches(tex, regexpr("(?<=\\\\setlength\\{\\\\tabcolsep\\}\\{)[0-9.]+(?=pt\\})", tex, perl = TRUE)))
  # A4 less the 2 cm side margins; LaTeX adds \tabcolsep either side of each column.
  used <- sum(widths[[1]]) + length(widths[[1]]) * 2 * sep / 72
  expect_lte(used, 170 / 25.4 + 0.02)
})

# A table by health board, wider than the text, and a year of weekly
# counts, longer than a page.
gt_pdf_rmd <- function(dir) {
  rmd <- file.path(dir, "gt.Rmd")
  writeLines(c("---", "title: Report", "---", "", "Text before the tables.", "",
               "```{r, echo = FALSE}",
               "set.seed(1)",
               "ll <- data.frame(",
               "  board = sample(c('Aneurin Bevan UHB', 'Betsi Cadwaladr UHB', 'Cardiff and Vale UHB'), 300, TRUE),",
               "  sex = sample(c('Female', 'Male'), 300, TRUE))",
               "phwstyle::phw_gt(phwstyle::phw_summary_table(ll, vars = sex, by = board))",
               "```", "",
               "```{r, echo = FALSE}",
               "wk <- data.frame(Week = as.Date('2025-01-06') + 7 * 0:59, Cases = 100:159)",
               "phwstyle::phw_gt(wk, caption = 'Weekly cases', source = 'PHW surveillance')",
               "```", "", "Text after the tables."), rmd)
  rmd
}

test_that("a phw_gt table in a PDF document breaks across pages with its header repeated", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not_installed("gt")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  local_ggplot_state()
  dir <- withr::local_tempdir()
  tex <- readLines(rmarkdown::render(gt_pdf_rmd(dir), phw_pdf_document(), output_file = "gt.tex",
                                     quiet = TRUE), warn = FALSE)
  expect_length(grep("\\begin{table}", tex, fixed = TRUE), 0)
  expect_length(grep("\\begin{longtable}", tex, fixed = TRUE), 2)
  expect_length(grep("\\endhead", tex, fixed = TRUE), 2)
})

test_that("phw_gt tables fit the text width and page length of a PDF document", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not_installed("gt")
  skip_if(!rmarkdown::pandoc_available(), "pandoc is not available")
  skip_if(!nzchar(Sys.which("xelatex")), "XeLaTeX is not installed")
  local_ggplot_state()
  withr::local_options(tinytex.clean = FALSE)
  dir <- withr::local_tempdir()
  pdf <- rmarkdown::render(gt_pdf_rmd(dir), phw_pdf_document(), quiet = TRUE)
  log <- readLines(sub("\\.pdf$", ".log", pdf), warn = FALSE)
  expect_false(any(grepl("Overfull \\\\[hv]box", log)))
  expect_false(any(grepl("too large", log, fixed = TRUE)))
})

test_that("a table by health board fits the content area of a PowerPoint deck", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not_installed("flextable")
  skip_if_not(rmarkdown::pandoc_available("2.4"), "pandoc 2.4 or later is not available")
  local_ggplot_state()
  dir <- withr::local_tempdir()
  ref <- phw_reference_pptx()
  pptx <- rmarkdown::render(board_table_rmd(dir), rmarkdown::powerpoint_presentation(reference_doc = ref),
                            quiet = TRUE)
  layout <- officer::layout_properties(officer::read_pptx(ref), "Title and Content")
  body <- layout[layout$type == "body", ]
  unzipped <- withr::local_tempdir()
  utils::unzip(pptx, exdir = unzipped)
  slides <- list.files(file.path(unzipped, "ppt", "slides"), pattern = "\\.xml$", full.names = TRUE)
  frames <- unlist(lapply(slides, function(s) xml2::xml_find_all(xml2::read_xml(s), "//p:graphicFrame")),
                   recursive = FALSE)
  expect_length(frames, 2)
  inches <- function(x) as.numeric(x) / 914400
  left <- vapply(frames, function(f) inches(xml2::xml_attr(xml2::xml_find_first(f, ".//a:off"), "x")), 0)
  widths <- lapply(frames, function(f) inches(xml2::xml_attr(xml2::xml_find_all(f, ".//a:gridCol"), "w")))
  expect_lte(left[1] + sum(widths[[1]]), body$offx + body$cx + 0.01)
  # A small table grows to fill the space, up to 18 pt, and stays inside it.
  sizes <- as.numeric(xml2::xml_attr(xml2::xml_find_all(frames[[2]], ".//a:rPr[@sz]"), "sz")) / 100
  expect_equal(unique(sizes), 18)
  expect_lte(left[2] + sum(widths[[2]]), body$offx + body$cx + 0.01)
  top <- inches(xml2::xml_attr(xml2::xml_find_first(frames[[2]], ".//a:off"), "y"))
  heights <- inches(xml2::xml_attr(xml2::xml_find_all(frames[[2]], ".//a:tr"), "h"))
  expect_lte(top + sum(heights), 7.5 - 0.95 + 0.001)
})

test_that("a table too long for a slide continues on the next slide of a knitted deck", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not_installed("flextable")
  skip_if_not(rmarkdown::pandoc_available("2.4"), "pandoc 2.4 or later is not available")
  local_ggplot_state()
  dir <- withr::local_tempdir()
  rmd <- file.path(dir, "weeks.Rmd")
  writeLines(c("---", "title: Weeks", "---", "", "## Cases", "",
               "```{r, echo = FALSE}",
               "set.seed(1)",
               "wk <- data.frame(Week = 30:45, Cases = rpois(16, 40),",
               "                 `Rate per 100,000` = round(rnorm(16, 12, 2), 1), check.names = FALSE)",
               "phwstyle::phw_flextable(wk, caption = 'Cases by week', source = 'Example data')",
               "```", "", "## Next", "", "Text"), rmd)
  pptx <- rmarkdown::render(rmd, rmarkdown::powerpoint_presentation(reference_doc = phw_reference_pptx()),
                            quiet = TRUE)
  unzipped <- withr::local_tempdir()
  utils::unzip(pptx, exdir = unzipped)
  slides <- file.path(unzipped, "ppt", "slides", paste0("slide", 2:4, ".xml"))
  tables <- lapply(slides[1:2], function(s) xml2::xml_find_first(xml2::read_xml(s), "//p:graphicFrame"))
  rows <- lapply(tables, function(t) {
    lapply(xml2::xml_find_all(t, ".//a:tr"), function(r) xml2::xml_text(xml2::xml_find_all(r, "a:tc")))
  })
  expect_equal(rows[[1]][[1]][1], "Cases by week")
  expect_equal(rows[[2]][[1]][1], "Cases by week (continued)")
  for (r in rows) expect_equal(r[[2]], c("Week", "Cases", "Rate per 100,000"))
  weeks <- unlist(lapply(rows, function(r) vapply(r[-(1:2)], `[`, "", 1)))
  expect_equal(weeks[weeks != "Source: Example data"], as.character(30:45))
  expect_false(any(grepl("Source", unlist(rows[[1]]))))
  expect_equal(rows[[2]][[length(rows[[2]])]][1], "Source: Example data")
  inches <- function(x) as.numeric(x) / 914400
  # Both slides of the table grow to the same size.
  sizes <- lapply(tables, function(t) unique(as.numeric(xml2::xml_attr(xml2::xml_find_all(t, ".//a:rPr[@sz]"), "sz"))))
  expect_length(sizes[[1]], 1)
  expect_equal(sizes[[2]], sizes[[1]])
  expect_gt(sizes[[1]], 1200)
  expect_lte(sizes[[1]], 1800)
  for (t in tables) {
    top <- inches(xml2::xml_attr(xml2::xml_find_first(t, ".//a:off"), "y"))
    expect_lte(top + sum(inches(xml2::xml_attr(xml2::xml_find_all(t, ".//a:tr"), "h"))), 7.5 - 0.95 + 0.001)
  }
  expect_match(paste(readLines(slides[3], warn = FALSE), collapse = ""), ">Next<")
})

deck_table_lines <- function() {
  c("## Cases", "", "```{r, echo = FALSE}",
    "hb <- c('Betsi Cadwaladr', 'Powys', 'Hywel Dda', 'Aneurin Bevan', 'Cardiff and Vale',",
    "        'Cwm Taf Morgannwg', 'Swansea Bay')",
    "phwstyle::phw_flextable(data.frame(Board = hb, Cases = 1:7 * 10, Rate = 1:7 + 0.5))",
    "```", "", "## Months", "", "```{r, echo = FALSE}",
    "ll <- data.frame(board = rep(hb, each = 120), month = factor(rep(month.abb, 70), levels = month.abb))",
    "phwstyle::phw_flextable(phwstyle::phw_crosstab(ll, board, month))",
    "```", "", "## Weeks", "", "```{r, echo = FALSE}",
    "wk <- data.frame(Week = 1:20, Cases = 101:120, Rate = round(1:20 * 1.37, 1))",
    "phwstyle::phw_flextable(wk, caption = 'Cases by week', source = 'Example data')",
    "```", "", "## Outbreaks", "", "```{r, echo = FALSE}",
    "ob <- data.frame(board = 'Powys', cases = 3)",
    "phwstyle::phw_flextable(ob[ob$cases > 10, ], caption = 'Outbreaks over 10 cases', source = 'PHW')",
    "```")
}

# The slide size of a deck and where each table on its slides ends, in inches.
deck_tables <- function(pptx) {
  inches <- function(x) as.numeric(x) / 914400
  size <- xml2::xml_find_first(xml2::read_xml(unz(pptx, "ppt/presentation.xml")), "//p:sldSz")
  slides <- grep("^ppt/slides/slide[0-9]+\\.xml$", utils::unzip(pptx, list = TRUE)$Name, value = TRUE)
  frames <- unlist(lapply(slides, function(s) xml2::xml_find_all(xml2::read_xml(unz(pptx, s)), "//p:graphicFrame")),
                   recursive = FALSE)
  ends <- vapply(frames, function(f) {
    off <- inches(xml2::xml_attrs(xml2::xml_find_first(f, ".//a:off")))
    c(right = off[[1]] + sum(inches(xml2::xml_attr(xml2::xml_find_all(f, ".//a:gridCol"), "w"))),
      bottom = off[[2]] + sum(inches(xml2::xml_attr(xml2::xml_find_all(f, ".//a:tr"), "h"))))
  }, numeric(2))
  list(width = inches(xml2::xml_attr(size, "cx")), height = inches(xml2::xml_attr(size, "cy")),
       right = ends["right", ], bottom = ends["bottom", ],
       text = unlist(lapply(frames, function(f) xml2::xml_text(xml2::xml_find_all(f, ".//a:tc")))))
}

expect_tables_on_slides <- function(deck) {
  expect_gt(length(deck$right), 0)
  expect_true(all(deck$right <= deck$width + 0.001))
  expect_true(all(deck$bottom <= deck$height + 0.001))
  expect_true(all(c("Rate", "Dec", "Total", "20", "Source: Example data") %in% deck$text))
  # A table a filter left with no rows keeps its caption, header and source.
  expect_true(all(c("Outbreaks over 10 cases", "board", "cases", "Source: PHW") %in% deck$text))
}

test_that("tables knitted into a deck fit the slide size of that deck", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not_installed("flextable")
  skip_if_not(rmarkdown::pandoc_available("2.4"), "pandoc 2.4 or later is not available")
  local_ggplot_state()
  dir <- withr::local_tempdir()
  rmd <- file.path(dir, "deck.Rmd")
  writeLines(c("---", "title: Weekly", "---", "", deck_table_lines()), rmd)
  # pandoc's own deck, which is smaller than the PHW one.
  plain <- deck_tables(rmarkdown::render(rmd, rmarkdown::powerpoint_presentation(), quiet = TRUE))
  expect_lt(plain$width, 13)
  expect_tables_on_slides(plain)
  # A 4:3 deck named from the document's folder: the tables use its taller slides.
  file.copy(system.file("template", "template.pptx", package = "officer"), file.path(dir, "tall.pptx"))
  tall <- deck_tables(rmarkdown::render(rmd, rmarkdown::powerpoint_presentation(reference_doc = "tall.pptx"),
                                        output_file = "tall-deck.pptx", quiet = TRUE))
  expect_equal(tall$height, 7.5)
  expect_tables_on_slides(tall)
  expect_gt(max(tall$bottom), plain$height)
})

test_that("tables knitted into a Quarto deck fit the slide size of that deck", {
  skip_on_cran()
  skip_if_not_installed("knitr")
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("flextable")
  quarto <- Sys.which("quarto")
  skip_if(!nzchar(quarto), "Quarto is not installed")
  dir <- withr::local_tempdir()
  writeLines(c("---", "title: Weekly", "format: pptx", "---", "", deck_table_lines()), file.path(dir, "deck.qmd"))
  withr::local_dir(dir)
  withr::local_envvar(QUARTO_R = R.home("bin"))
  log <- suppressWarnings(system2(quarto, c("render", "deck.qmd"), stdout = TRUE, stderr = TRUE))
  if (!file.exists("deck.pptx")) fail(paste(c("quarto render failed:", utils::tail(log, 15)), collapse = "\n"))
  deck <- deck_tables(file.path(dir, "deck.pptx"))
  expect_lt(deck$width, 13)
  expect_tables_on_slides(deck)
})

test_that("a table chunk with a tbl- label keeps its table on a Quarto slide", {
  skip_on_cran()
  skip_if_not_installed("knitr")
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("flextable")
  skip_if_not_installed("xml2")
  quarto <- Sys.which("quarto")
  skip_if(!nzchar(quarto), "Quarto is not installed")
  dir <- withr::local_tempdir()
  suppressMessages(use_phw_quarto(dir, "none"))
  chunk <- function(title, options, data = "data.frame(Area = c('Cardiff', 'Swansea'), Cases = c(105L, 63L))") {
    c(paste("##", title), "", "```{r, echo = FALSE}", options,
      paste0("phwstyle::phw_flextable(", data, ", source = 'Example')"), "```", "")
  }
  writeLines(c("---", "title: Weekly", "format: phw-pptx", "---", "",
               chunk("Labelled", c("#| label: tbl-x", "#| tbl-cap: 'Cases by area'")),
               chunk("Label only", "#| label: tbl-y"),
               chunk("Unlabelled", "#| tbl-cap: 'Cases by area'"),
               chunk("Weeks", c("#| label: tbl-weeks", "#| tbl-cap: 'Cases by week'"),
                     "data.frame(Week = 1:30, Cases = 101:130)"),
               "## Notes", "", "See @tbl-x."),
             file.path(dir, "deck.qmd"))
  withr::local_dir(dir)
  withr::local_envvar(QUARTO_R = R.home("bin"))
  log <- suppressWarnings(system2(quarto, c("render", "deck.qmd"), stdout = TRUE, stderr = TRUE))
  if (!file.exists("deck.pptx")) fail(paste(c("quarto render failed:", utils::tail(log, 15)), collapse = "\n"))
  expect_no_match(paste(log, collapse = "\n"), "FloatRefTargets")
  slides <- sprintf("ppt/slides/slide%d.xml", 2:7)
  tables <- lapply(slides, function(s) {
    xml <- xml2::read_xml(unz("deck.pptx", s))
    vapply(xml2::xml_find_all(xml, ".//a:tbl//a:tc[not(@hMerge)]"), xml2::xml_text, character(1))
  })
  expect_true(all(lengths(tables) > 0))
  expect_equal(tables[[1]][1:3], c("Cases by area", "Area", "Cases"))
  expect_equal(tables[[2]][1:2], c("Area", "Cases"))
  expect_equal(tables[[3]][1:3], c("Cases by area", "Area", "Cases"))
  expect_equal(vapply(tables[4:6], `[[`, "", 1), c("Cases by week", rep("Cases by week (continued)", 2)))
  expect_true("Source: Example" %in% tables[[6]])
  text <- xml2::xml_text(xml2::read_xml(unz("deck.pptx", "ppt/slides/slide8.xml")))
  expect_match(text, "See Table.1")
})

test_that("a table too wide for a slide even with its text wrapped gives a warning", {
  skip_if_not_installed("knitr")
  skip_if_not_installed("flextable")
  wide <- as.data.frame(matrix(1000000, 2, 20, dimnames = list(NULL, paste0("Unbreakable", 1:20))))
  ft <- phw_flextable(wide)
  withr::local_options(knitr.in.progress = TRUE)
  old <- knitr::opts_knit$get("rmarkdown.pandoc.to")
  knitr::opts_knit$set(rmarkdown.pandoc.to = "pptx")
  withr::defer(knitr::opts_knit$set(rmarkdown.pandoc.to = old))
  expect_warning(knitr::knit_print(ft), "too wide for the slide")
})

test_that("a table with no rows knits into a deck without a warning", {
  skip_if_not_installed("knitr")
  skip_if_not_installed("flextable")
  withr::local_options(knitr.in.progress = TRUE)
  old <- knitr::opts_knit$get("rmarkdown.pandoc.to")
  knitr::opts_knit$set(rmarkdown.pandoc.to = "pptx")
  withr::defer(knitr::opts_knit$set(rmarkdown.pandoc.to = old))
  expect_no_warning(knitr::knit_print(phw_flextable(mtcars[0, 1:3], caption = "None this week")))
})

test_that("a table too wide for the page even with its text wrapped gives a warning", {
  skip_if_not_installed("knitr")
  skip_if_not_installed("flextable")
  wide <- as.data.frame(matrix(1000000, 2, 14, dimnames = list(NULL, paste0("Unbreakable", 1:14))))
  ft <- phw_flextable(wide)
  withr::local_options(knitr.in.progress = TRUE)
  old <- knitr::opts_knit$get("rmarkdown.pandoc.to")
  knitr::opts_knit$set(rmarkdown.pandoc.to = "docx")
  withr::defer(knitr::opts_knit$set(rmarkdown.pandoc.to = old))
  expect_warning(knitr::knit_print(ft), "too wide for the page")
})

test_that("a Quarto PDF colours its links in PHW navy and blue", {
  skip_on_cran()
  quarto <- Sys.which("quarto")
  skip_if(!nzchar(quarto), "Quarto is not installed")
  skip_if(!nzchar(Sys.which("xelatex")), "XeLaTeX is not installed")
  dir <- withr::local_tempdir()
  suppressMessages(use_phw_quarto(dir, "none"))
  writeLines(c("---", "title: T", "keep-tex: true", "---", "", "See [a link](https://example.org) and @sec-a.",
               "", "# A {#sec-a}"), file.path(dir, "links.qmd"))
  log <- withr::with_dir(dir, suppressWarnings(system2(quarto, c("render", "links.qmd", "--to", "phw-pdf"),
                                                       stdout = TRUE, stderr = TRUE)))
  tex <- file.path(dir, "links.tex")
  if (!file.exists(tex)) fail(paste(c("quarto render failed:", utils::tail(log, 15)), collapse = "\n"))
  tex <- paste(readLines(tex, warn = FALSE), collapse = " ")
  links <- c("linkcolor={phwnavy}", "citecolor={phwnavy}", "urlcolor={phwblue}", "filecolor={phwblue}")
  for (link in links) expect_match(tex, link, fixed = TRUE)
})

test_that("a Quarto PDF with two authors renders", {
  skip_on_cran()
  quarto <- Sys.which("quarto")
  skip_if(!nzchar(quarto), "Quarto is not installed")
  skip_if(!nzchar(Sys.which("xelatex")), "XeLaTeX is not installed")
  dir <- withr::local_tempdir()
  suppressMessages(use_phw_quarto(dir, "none"))
  writeLines(c("---", "title: Report", "author: [Jane Smith, Alan Jones]", "---", "", "Hello."),
             file.path(dir, "authors.qmd"))
  log <- withr::with_dir(dir, suppressWarnings(system2(quarto, c("render", "authors.qmd", "--to", "phw-pdf"),
                                                       stdout = TRUE, stderr = TRUE)))
  expect_true(file.exists(file.path(dir, "authors.pdf")), info = paste(utils::tail(log, 15), collapse = "\n"))
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

test_that("format arguments in ... are merged with the PHW ones or refused", {
  skip_if_not_installed("rmarkdown")
  expect_error(phw_word_document(reference_docx = "mine.docx"), "sets `reference_docx` itself")
  expect_error(phw_html_document(theme = "cerulean"), "sets `theme` itself")
  expect_error(phw_pdf_document(latex_engine = "pdflatex"), "sets `latex_engine` itself")
  expect_equal(phw_html_document(dev = "svg")$knitr$opts_chunk$dev, "svg")
  expect_equal(phw_pdf_document(dev = "pdf")$knitr$opts_chunk$dev, "pdf")
  if (requireNamespace("ragg", quietly = TRUE)) {
    expect_equal(phw_pdf_document()$knitr$opts_chunk$dev, "ragg_png")
  }
  pdf <- phw_pdf_document(includes = rmarkdown::includes(in_header = "mine.tex"),
                          pandoc_args = c("--variable", "linestretch:1.2"))
  expect_equal(sum(pdf$pandoc$args == "--include-in-header"), 2)
  expect_true("mine.tex" %in% pdf$pandoc$args)
  expect_true("linestretch:1.2" %in% pdf$pandoc$args)
})

test_that("the YAML and pandoc_args replace the PHW page settings in a PDF", {
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available("2.3"))
  dir <- withr::local_tempdir()
  tex <- function(yaml = character(), ...) {
    writeLines(c("---", "title: T", yaml, "---", "", "Hello"), file.path(dir, "t.Rmd"))
    out <- rmarkdown::render(file.path(dir, "t.Rmd"), phw_pdf_document(style_plots = FALSE, ...),
                             output_file = "t.tex", quiet = TRUE)
    paste(readLines(out, warn = FALSE), collapse = " ")
  }
  default <- tex()
  expect_match(default, "\\\\documentclass\\[\\s*11pt,\\s*a4paper,\\s*\\]\\{article\\}")
  expect_match(default, "\\usepackage[top=3.2cm,bottom=2.6cm,left=2cm,right=2cm]{geometry}", fixed = TRUE)
  links <- c("linkcolor={phwnavy}", "citecolor={phwnavy}", "urlcolor={phwblue}", "filecolor={phwblue}")
  for (link in links) expect_match(default, link, fixed = TRUE)
  expect_match(tex("urlcolor: red"), "urlcolor={red}", fixed = TRUE)
  yaml <- tex(c("fontsize: 12pt", "documentclass: report", "geometry: margin=1in"))
  expect_match(yaml, "\\\\documentclass\\[\\s*12pt,\\s*a4paper,\\s*\\]\\{report\\}")
  expect_match(yaml, "\\usepackage[margin=1in]{geometry}", fixed = TRUE)
  letter <- tex("papersize: letter")
  expect_match(letter, "\\\\documentclass\\[\\s*11pt,\\s*letterpaper,\\s*\\]\\{article\\}")
  args <- tex(pandoc_args = c("-V", "fontsize=12pt"))
  expect_match(args, "\\\\documentclass\\[\\s*12pt,\\s*a4paper,\\s*\\]\\{article\\}")
})

test_that("an HTML document keeps the PHW style and adds your css and includes", {
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available())
  local_ggplot_state()
  dir <- withr::local_tempdir()
  writeLines(c("---", "title: T", "---", "", "Hello"), file.path(dir, "t.Rmd"))
  writeLines(".my-css-marker {color: red}", file.path(dir, "mine.css"))
  writeLines("<p>MY-FOOTER</p>", file.path(dir, "foot.html"))
  out <- rmarkdown::render(file.path(dir, "t.Rmd"),
                           phw_html_document(css = file.path(dir, "mine.css"), toc_float = FALSE,
                                             includes = rmarkdown::includes(after_body = file.path(dir, "foot.html"))),
                           quiet = TRUE)
  html <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_match(html, "my-css-marker", fixed = TRUE)
  expect_match(html, "MY-FOOTER", fixed = TRUE)
  expect_match(html, "phw-band", fixed = TRUE)
})

test_that("style_plots must be TRUE or FALSE", {
  skip_if_not_installed("rmarkdown")
  expect_error(phw_word_document(style_plots = "yes"), "`style_plots` must be `TRUE` or `FALSE`")
})

test_that("the LaTeX header prints a team name with LaTeX characters as written", {
  tex <- readLines(phw_latex_header(team = "R&D 50% #1 a_b"))
  expect_true(any(grepl("R\\&D 50\\% \\#1 a\\_b", tex, fixed = TRUE)))
})

test_that("a saved LaTeX header points at a band image kept beside it", {
  dir <- withr::local_tempdir()
  file <- file.path(dir, "phw-header.tex")
  tex <- readLines(phw_latex_header(file))
  band <- normalizePath(file.path(dir, "phw-header-band.png"), winslash = "/")
  expect_true(file.exists(band))
  expect_true(any(grepl(band, tex, fixed = TRUE)))
})

test_that("template writers check the folder and the extension", {
  expect_error(phw_latex_header(file.path("no-such-folder", "h.tex")), "folder not found")
  expect_error(phw_reference_docx(file.path("no-such-folder", "r.docx")), "folder not found")
  expect_error(phw_reference_pptx(file.path("no-such-folder", "t.pptx")), "folder not found")
  expect_error(phw_reference_pptx(withr::local_tempfile(fileext = ".docx")), "must end in")
})

test_that("use_phw_quarto needs a folder", {
  f <- withr::local_tempfile()
  writeLines("x", f)
  expect_error(use_phw_quarto(f), "must be a folder")
})
