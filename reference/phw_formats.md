# PHW R Markdown output formats

Branded versions of the standard R Markdown formats. Use them in the
YAML header of an `.Rmd` file:

## Usage

``` r
phw_html_document(
  ...,
  toc = TRUE,
  number_sections = FALSE,
  fig_width = 7.5,
  fig_height = 4.5,
  style_plots = TRUE,
  palette = NULL
)

phw_word_document(
  ...,
  toc = FALSE,
  number_sections = FALSE,
  fig_width = 6.3,
  fig_height = 3.9,
  style_plots = TRUE,
  palette = NULL
)

phw_pdf_document(
  ...,
  toc = FALSE,
  number_sections = TRUE,
  fig_width = 6.3,
  fig_height = 3.9,
  cover = TRUE,
  team = NULL,
  style_plots = TRUE,
  palette = NULL
)
```

## Arguments

- ...:

  Passed to the underlying rmarkdown format.

- toc:

  Include a table of contents?

- number_sections:

  Number the headings (1, 1.1, ...) like PHW reports?

- fig_width, fig_height:

  Default figure size in inches.

- style_plots:

  Apply
  [`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md)
  and
  [`use_phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_flextable.md)
  while knitting?

- palette:

  Qualitative palette for the whole document, e.g. `"accessible"`.
  `NULL` uses
  [`phw_default_palette()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_default_palette.md).
  The palette is put back as it was when the render finishes.

- cover:

  Draw the full-page gradient cover when the document has a title?

- team:

  Team line on the cover, e.g.
  `"Communicable Disease Surveillance Centre"`.

## Value

An R Markdown output format.

## Details

    output: phwstyle::phw_html_document

- `phw_html_document()`: Bootstrap 5 with
  [`phw_bs_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_bs_theme.md),
  the gradient header band with the white logo, and PHW styles for the
  title, headings, tables and captions. Works offline because the fonts
  are embedded.

- `phw_word_document()`: uses a reference document with Ubuntu, navy
  headings, booktabs tables, a gradient band and logo header, and a
  "Page x of y" footer.

- `phw_pdf_document()`: XeLaTeX with Ubuntu, a full-page gradient cover,
  a running header band and a branded footer.

All three call
[`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md)
(and
[`use_phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_flextable.md)
when flextable is installed) before knitting, so charts and tables match
without extra code: don't repeat those calls in the document, and add
[`theme_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw.md)
or a PHW scale to a plot only to change something for that plot. If one
of these steps fails, the document still renders and a warning says what
was left unstyled.

**Accessible colours.** `palette = "accessible"` switches every chart,
table and widget in the document to the colour-blind safe palette. To
make both versions of a report, leave the document alone and set it when
you render:

    word <- "phwstyle::phw_word_document"
    rmarkdown::render("report.Rmd", word, output_file = "report.docx")
    rmarkdown::render("report.Rmd", word, output_file = "report-accessible.docx",
                      output_options = list(palette = "accessible"))

Or set it for good in the YAML header:

    output:
      phwstyle::phw_word_document:
        palette: accessible

See
[`phw_default_palette()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_default_palette.md)
for the other ways to switch. For larger text and thicker lines as well,
call `use_phw_ggplot(accessible = TRUE)` in the setup chunk.

## Examples

``` r
# Use a format in the YAML header of an .Rmd file:
#
#   output: phwstyle::phw_word_document
#
# or give it to rmarkdown::render(). Making the format object is quick:
if (requireNamespace("rmarkdown", quietly = TRUE)) {
  fmt <- phw_word_document(toc = TRUE)
}
# \donttest{
# Render one document twice: default colours, then accessible colours
if (requireNamespace("rmarkdown", quietly = TRUE) && rmarkdown::pandoc_available() &&
    interactive()) {
  rmd <- file.path(tempdir(), "report.Rmd")
  writeLines(c("---", "title: Example report", "---", "",
               "```{r, echo = FALSE}",
               "library(ggplot2)",
               "ggplot(mpg, aes(class, fill = drv)) + geom_bar()",
               "```"), rmd)
  rmarkdown::render(rmd, phw_word_document(), output_file = "report.docx")
  rmarkdown::render(rmd, phw_word_document(palette = "accessible"),
                    output_file = "report-accessible.docx")
}
# }
```
