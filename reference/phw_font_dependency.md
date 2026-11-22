# HTML dependency that serves the Ubuntu web font

Attach this to any HTML output (htmlwidgets, Shiny UIs, R Markdown) so
Ubuntu works even when the computer doesn't have it installed. The font
files are bundled, so nothing is fetched from the internet.

## Usage

``` r
phw_font_dependency()
```

## Value

An
[`htmltools::htmlDependency()`](https://rstudio.github.io/htmltools/reference/htmlDependency.html).

## Examples

``` r
dep <- phw_font_dependency()
dep$name
#> [1] "phw-ubuntu-font"
# Attach it to any HTML you build with htmltools
page <- htmltools::tagList(dep, htmltools::p("Text in Ubuntu"))
```
