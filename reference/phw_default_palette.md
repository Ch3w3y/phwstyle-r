# The default qualitative palette

The palette that charts, tables and widgets use for groups when you
don't name one. Out of the box it is `"main"` (navy, teal, orange,
pink), carrying on into `"extended"` past four groups, so every chart in
a report draws from one set of colours however many groups it has.

## Usage

``` r
phw_default_palette()
```

## Value

A palette name or vector.

## Details

The colour-blind safe `"accessible"` palette is a switch you turn on
once, and it then applies to every chart, table and widget, for any
number of groups. The first of these that is set wins:

1.  `options(phwstyle.palette = "accessible")`, which is also what
    `use_phw_ggplot(palette = "accessible")` and the `palette` argument
    of
    [`phw_html_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md),
    [`phw_word_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md)
    and
    [`phw_pdf_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md)
    set.

2.  The environment variable `PHWSTYLE_PALETTE`, for switching one
    render from the command line without editing the document, e.g.
    `PHWSTYLE_PALETTE=accessible quarto render report.qmd`.

3.  `phw-palette: accessible` in the YAML header of a Quarto or R
    Markdown document.

The option can also be any other palette name from
[phw_palettes](https://ch3w3y.github.io/phwstyle-r/reference/phw_palettes.md),
or your own vector of colours.

This switch changes colours only. Larger text and thicker lines are a
separate setting, `accessible = TRUE` in
[`theme_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw.md)
or
[`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md);
neither turns the other on.

## Examples

``` r
phw_default_palette()
#> [1] "main"
phw_pal(6)
#> [1] "#285087" "#24A2B5" "#FF5D0C" "#F43882" "#231F20" "#338276"

old <- options(phwstyle.palette = "accessible")
phw_pal(6)
#> [1] "#285087" "#24A2B5" "#FF5D0C" "#000000" "#9D5659" "#8478CF"
options(old)
```
