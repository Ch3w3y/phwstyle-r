# Apply PHW styling to a plotly chart

Restyles a plotly figure with the PHW font, colour order, light
gridlines, a horizontal legend under the chart, and hover labels in
navy. It also trims the mode bar. You can pass it a plotly object, or a
ggplot, which is converted with
[`plotly::ggplotly()`](https://rdrr.io/pkg/plotly/man/ggplotly.html)
first.

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

  A plotly object or a ggplot.

- source, date:

  Passed to
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  and shown under the chart.

- ...:

  Extra arguments for `plotly::layout()`. They override the PHW
  defaults; lists are merged, so `title = list(text = "My title")` keeps
  the PHW title style.

- legend:

  `"bottom"`, `"right"` or `"none"`.

- palette:

  Colour order for traces that don't set their own colour: a palette
  name or a vector of colours.

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

Any plotly chart type works: scatter and lines, bars, pies and donuts
(given the PHW colours and white slice borders), box and violin plots,
histograms, heatmaps and choropleth maps (which pick up the PHW
sequential colour scale unless you set `colorscale`), and figures
combined with
[`plotly::subplot()`](https://rdrr.io/pkg/plotly/man/subplot.html). Use
[`phw_plotly_colorscale()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_plotly_colorscale.md)
to set a PHW scale on a trace yourself.

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
