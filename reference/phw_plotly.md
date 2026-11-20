# Apply PHW styling to a plotly chart

Restyles a plotly figure with the PHW font, colour order, light
gridlines, a horizontal legend under the chart, and hover labels in
navy. It also trims the mode bar. You can pass it a plotly object, or a
ggplot, which is converted with
[`plotly::ggplotly()`](https://rdrr.io/pkg/plotly/man/ggplotly.html)
first. A ggplot's subtitle goes under its title. A ggplot that maps the
`text` aesthetic shows only that text on hover, as
`ggplotly(tooltip = "text")` does.

## Usage

``` r
phw_plotly(
  p,
  source = NULL,
  date = NULL,
  ...,
  legend = c("bottom", "right", "none"),
  palette = phw_default_palette(),
  font_size = 13,
  caption_args = list(),
  modebar = TRUE
)
```

## Arguments

- p:

  A plotly object or a ggplot. For several charts in one figure, combine
  them with
  [`plotly::subplot()`](https://rdrr.io/pkg/plotly/man/subplot.html): a
  patchwork, such as one from
  [`phw_arrange()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_arrange.md),
  is not accepted.

- source, date:

  Passed to
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  and shown under the chart. When they and `caption_args` give no source
  line, a ggplot shows its own caption there, such as one from
  `labs(caption = phw_caption(...))`.

- ...:

  Extra arguments for `plotly::layout()`. They override the PHW
  defaults; lists are merged, so `title = list(text = "My title")` keeps
  the PHW title style. `annotations` are added after the caption.

- legend:

  Where the legend goes: `"bottom"`, `"right"` or `"none"`. As in
  plotly, a chart with one trace has no legend; pass `showlegend = TRUE`
  to show one.

- palette:

  Colours for traces that don't set their own: a palette name, a vector
  of colours or a function of `n`, as in
  [`phw_pal()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pal.md).
  A trace that maps `color` to groups without giving `colors` takes them
  from this palette too, as do the groups of a ggplot with no colour or
  fill scale of its own.

- font_size:

  Base font size in px.

- caption_args:

  List of other
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  arguments.

- modebar:

  Show the plotly tool bar?

## Value

A plotly object.

## Details

A ggplot's secondary axis, such as one from
[`phw_sec_axis()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_sec_axis.md),
is drawn on the right (or the top), as in the static chart. Hover shows
the second measure in the units of the main axis, so map the `text`
aesthetic to show it in its own. A faceted chart can't show a secondary
axis: `phw_plotly()` warns, and the series is read against the main
axis. To combine charts that have one with
[`plotly::subplot()`](https://rdrr.io/pkg/plotly/man/subplot.html), pass
the combined figure to `phw_plotly()` too, so each axis stays on its own
chart.

Any plotly chart type works: scatter and lines, bars, pies and donuts
(given the PHW colours and white slice borders), box and violin plots,
histograms, heatmaps, contours and choropleth maps, and markers coloured
by a number (which start at the same blue as the ggplot2 charts, not the
palest one, unless you set `colorscale` or `colors`, and draw a missing
number in light grey), and figures combined with
[`plotly::subplot()`](https://rdrr.io/pkg/plotly/man/subplot.html). Use
[`phw_plotly_colorscale()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_plotly_colorscale.md)
to set a PHW scale on a trace yourself.

In a [`plotly::subplot()`](https://rdrr.io/pkg/plotly/man/subplot.html)
figure, a group has the same colour in every panel. If a panel sets its
own colours with `colors` or [`I()`](https://rdrr.io/r/base/AsIs.html),
the group colours and colour scales stay as each panel was built. To
give the other panels PHW colours, style each panel with `phw_plotly()`
before combining them. Groups of a ggplot in ggplot2's default colours
take the PHW colours too; a ggplot that sets its own colours with a
scale, such as
[`ggplot2::scale_colour_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html),
keeps them.

For colours that stay with a group across charts, pass a colour key to
plotly yourself, e.g.
`plot_ly(df, x = ~week, y = ~rate, color = ~age, colors = phw_colour_key(df$age, "age"))`.
ggplots keep the colours of their `scale_colour_phw_d(key = ...)`.

## Examples

``` r
if (requireNamespace("plotly", quietly = TRUE)) {
  df <- data.frame(week = rep(1:10, 2),
                   cases = c(3, 5, 9, 14, 20, 18, 13, 9, 6, 4,
                             2, 4, 6, 9, 11, 13, 12, 10, 7, 5),
                   group = rep(c("Group A", "Group B"), each = 10))

  # A chart built with plot_ly()
  p <- plotly::plot_ly(df, x = ~week, y = ~cases, color = ~group,
                       type = "scatter", mode = "lines")
  w1 <- phw_plotly(p, source = "Example data")

  # A ggplot, converted for you
  g <- ggplot2::ggplot(df, ggplot2::aes(week, cases, colour = group)) +
    ggplot2::geom_line()
  w2 <- phw_plotly(g, source = "Example data", hovermode = "x")

  # Printing shows the chart in the Viewer or a browser.
  if (interactive()) print(w1)
}
```
