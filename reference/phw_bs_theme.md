# PHW Bootstrap theme for Shiny, R Markdown and Quarto HTML

A
[`bslib::bs_theme()`](https://rstudio.github.io/bslib/reference/bs_theme.html)
with PHW colours and the Ubuntu font. The mapping follows phw.nhs.wales:

## Usage

``` r
phw_bs_theme(version = 5, ...)
```

## Arguments

- version:

  Bootstrap version.

- ...:

  Extra variables passed to
  [`bslib::bs_theme()`](https://rstudio.github.io/bslib/reference/bs_theme.html).
  They override the PHW values, e.g. `primary = "#24A2B5"` or
  `"navbar-bg" = "#1B3660"`.

## Value

A bslib theme.

## Details

- navy is `primary`

- the website green is `success`

- `danger`, `warning` and `info` use the red and amber of the `rag`
  palette (red, amber, green status colours) and teal

- links are the website blue, with magenta on hover

Navbars are navy, and focus outlines are the NHS yellow.

Use it in `bslib::page_navbar(theme = phw_bs_theme())`,
`fluidPage(theme = phw_bs_theme())`, or as the `theme` of
[`phw_html_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md).

## Examples

``` r
if (requireNamespace("bslib", quietly = TRUE)) {
  theme <- phw_bs_theme()
  # Teal as the main colour instead of navy
  theme_teal <- phw_bs_theme(primary = "#24A2B5")
}
if (requireNamespace("bslib", quietly = TRUE) && requireNamespace("shiny", quietly = TRUE) &&
    interactive()) {
  ui <- bslib::page_fluid(theme = phw_bs_theme(), shiny::h2("A styled page"))
  shiny::shinyApp(ui, function(input, output) {})
}
```
