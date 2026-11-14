# A complete PHW Shiny page

A thin wrapper around
[`bslib::page_navbar()`](https://rstudio.github.io/bslib/reference/page_navbar.html)
that applies
[`phw_bs_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_bs_theme.md),
puts the PHW header band above the navigation and adds a footer. Use
[`bslib::nav_panel()`](https://rstudio.github.io/bslib/reference/nav-items.html)
for each tab, exactly as you would with `page_navbar()`.

## Usage

``` r
phw_page_navbar(
  ...,
  title = NULL,
  subtitle = NULL,
  footer = NULL,
  theme = phw_bs_theme(),
  header_args = list(),
  navbar_bg = phw_colours[["navy"]]
)
```

## Arguments

- ...:

  Tabs and other arguments passed to
  [`bslib::page_navbar()`](https://rstudio.github.io/bslib/reference/page_navbar.html).

- title:

  App title, shown in the header band and the browser tab.

- subtitle:

  Optional subtitle, e.g. the team name.

- footer:

  Footer text or tags. Defaults to the organisation name. `FALSE` drops
  the footer.

- theme:

  A bslib theme. Use
  [`phw_bs_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_bs_theme.md)
  with your own overrides.

- header_args:

  List of extra
  [`phw_header()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_header.md)
  arguments.

- navbar_bg:

  Navigation bar colour.

## Value

A Shiny UI.

## Examples

``` r
if (requireNamespace("bslib", quietly = TRUE) && requireNamespace("shiny", quietly = TRUE) &&
    interactive()) {
  ui <- phw_page_navbar(
    title = "Weekly surveillance", subtitle = "Team name",
    bslib::nav_panel("Overview", "Charts go here"),
    bslib::nav_panel("Data", "Tables go here")
  )
  shiny::shinyApp(ui, function(input, output) {})
}
```
