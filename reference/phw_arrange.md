# Arrange several plots in one PHW-styled figure

Puts plots side by side or in a grid, with one PHW title, subtitle and
source line for the whole figure. Use it when facets can't do the job,
for example to combine a map, a bar chart and a table-like chart. It is
a thin wrapper around the patchwork package, so the result can be
changed further with patchwork operators (`+`, `|`, `/`, `&`).

## Usage

``` r
phw_arrange(
  ...,
  plots = NULL,
  ncol = NULL,
  nrow = NULL,
  widths = NULL,
  heights = NULL,
  design = NULL,
  title = NULL,
  subtitle = NULL,
  source = NULL,
  date = NULL,
  caption_args = list(),
  guides = c("collect", "keep"),
  legend = "bottom",
  tag_levels = NULL,
  theme = theme_phw()
)
```

## Arguments

- ...:

  ggplots (or other patchwork-compatible objects).

- plots:

  A list of plots, instead of or as well as `...`.

- ncol, nrow, widths, heights, design:

  Layout, passed to
  [`patchwork::plot_layout()`](https://patchwork.data-imaginist.com/reference/plot_layout.html).

- title, subtitle:

  Figure title and subtitle.

- source, date, caption_args:

  Passed to
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  for the figure's source line.

- guides:

  `"collect"` merges identical legends from all panels into one, at
  `legend`; `"keep"` leaves each legend with its plot.

- legend:

  Position of collected legends.

- tag_levels:

  Panel tags, e.g. `"A"` for A, B, C or `"1"`. `NULL` for none.

- theme:

  The theme used for the figure title and source line.

## Value

A patchwork object. Add
[`phw_finalise()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_finalise.md)
for the logo footer, or save with
[`phw_save()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_save.md).

## Details

To keep the same colour for a group in every panel, give each plot the
same colour key, e.g. `scale_fill_phw_d(key = "area")`. With
`guides = "collect"`, matching legends are then merged into one.

## Examples

``` r
if (requireNamespace("patchwork", quietly = TRUE)) {
  library(ggplot2)
  p1 <- ggplot(mpg, aes(displ, hwy, colour = drv)) + geom_point() + theme_phw()
  p2 <- ggplot(mpg, aes(drv, fill = drv)) + geom_bar() + theme_phw()
  phw_arrange(p1, p2, title = "Two charts", source = "ggplot2::mpg", tag_levels = "A")
}
```
