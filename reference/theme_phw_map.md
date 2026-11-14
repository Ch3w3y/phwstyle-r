# PHW map theme

[`theme_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw.md)
without axes or gridlines, with the legend on the right. Use it for
choropleth maps of health boards or local authorities, with
[`scale_fill_phw_c()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
or
[`scale_fill_phw_b()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md).

## Usage

``` r
theme_phw_map(base_size = 11, base_family = phw_font(), legend = "right", ...)
```

## Arguments

- base_size:

  Base font size in points. Reports use 11 for body text.

- base_family:

  Font family. Defaults to
  [`phw_font()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_font.md)
  (Ubuntu).

- legend:

  Legend position: `"bottom"`, `"top"`, `"right"`, `"left"`, `"inside"`
  or `"none"`, or a numeric `c(x, y)` inside the panel.

- ...:

  Passed to
  [`theme_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw.md).

## Value

A ggplot2 theme.

## Examples

``` r
library(ggplot2)
# Any filled grid works the same way as a map
ggplot(faithfuld, aes(waiting, eruptions, fill = density)) +
  geom_raster() +
  scale_fill_phw_c() +
  theme_phw_map()

# \donttest{
# Health boards, downloaded the first time and cached after that
if (requireNamespace("sf", quietly = TRUE) && interactive()) {
  hb <- phw_boundaries("health_board")
  hb$rate <- runif(nrow(hb), 20, 80)
  ggplot(hb) +
    geom_sf(aes(fill = rate), colour = "white") +
    scale_fill_phw_b(name = "Rate per\n100,000") +
    theme_phw_map()
}
# }
```
