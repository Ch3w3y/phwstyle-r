# Add the PHW footer (logo and source) to a ggplot

Adds a branded footer under a chart: a thin navy rule, the PHW logo on
one side and the source text on the other. Use it for charts that stand
alone, such as slides, social media, briefings or images sent by email.
Charts inside a branded report don't need it, because the report already
carries the logo.

## Usage

``` r
phw_finalise(
  plot,
  source = NULL,
  date = NULL,
  logo = "blue",
  team = NULL,
  logo_height = 1.1,
  logo_position = c("left", "right"),
  text_size = 8.5,
  text_colour = phw_colours[["text"]],
  rule_colour = phw_colours[["navy"]],
  rule = TRUE,
  margin = 4,
  ...
)
```

## Arguments

- plot:

  A ggplot, a patchwork (e.g. from
  [`phw_arrange()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_arrange.md)),
  a cowplot figure, or any grob or gtable (e.g. from
  [`gridExtra::arrangeGrob()`](https://rdrr.io/pkg/gridExtra/man/arrangeGrob.html)).

- source, date:

  Passed to
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md).
  Leave both `NULL` to keep any caption already on the plot.

- logo:

  Logo variant (see
  [`phw_logo()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_logo.md)),
  a path to your own PNG, or `FALSE` for none.

- team:

  Optional line under the source, e.g.
  `"Communicable Disease Surveillance Centre"`.

- logo_height:

  Logo height in cm.

- logo_position:

  `"left"` or `"right"`. The text goes on the other side.

- text_size:

  Footer text size in points.

- text_colour, rule_colour:

  Colours of the footer text and rule.

- rule:

  Draw the rule above the footer?

- margin:

  Space at each side, in mm.

- ...:

  Passed to
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md),
  e.g. `source_prefix = "Data: "` or `note = "Provisional"`.

## Value

A gtable that prints like a plot. Save it with
[`phw_save()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_save.md).

## Examples

``` r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  labs(title = "Weight and fuel economy", x = "Weight (1,000 lbs)",
       y = "Miles per gallon")

# Source and date under the chart, with the logo if you have one
# (see phw_download_logos()); otherwise the organisation name is shown.
fp <- phw_finalise(p, source = "mtcars", date = as.Date("2025-06-30"))
phw_save(fp, tempfile(fileext = ".png"))

# A team line, and no logo
fp <- phw_finalise(p, source = "mtcars", team = "Team name", logo = FALSE)
```
