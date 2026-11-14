# PHW title for gridExtra and cowplot layouts

gridExtra and cowplot draw figure titles in the default font. This
builds a PHW-styled title (bold navy, left-aligned, with an optional
subtitle) to pass as `top =` in
[`gridExtra::grid.arrange()`](https://rdrr.io/pkg/gridExtra/man/arrangeGrob.html)
or
[`gridExtra::arrangeGrob()`](https://rdrr.io/pkg/gridExtra/man/arrangeGrob.html),
or to stack above a cowplot figure.

## Usage

``` r
phw_title_grob(title, subtitle = NULL, size = 14, margin = 3)
```

## Arguments

- title:

  Title text.

- subtitle:

  Optional subtitle.

- size:

  Title size in points. The subtitle is a little smaller.

- margin:

  Left margin in mm.

## Value

A grob.

## Examples

``` r
if (requireNamespace("gridExtra", quietly = TRUE)) {
  library(ggplot2)
  p <- ggplot(mpg, aes(displ, hwy)) + geom_point() + theme_phw()
  gridExtra::grid.arrange(p, p, ncol = 2, top = phw_title_grob("Two charts", "Same data twice"))
}
```
