# Funnel plot

Compares areas, providers or practices of different sizes against a
target (by default the overall value), with control limits that narrow
as the denominator grows. Points outside the limits are coloured and
shaped, so unusual values stand out without over-reading small areas.

## Usage

``` r
phw_funnel(
  data,
  numerator,
  denominator,
  label = NULL,
  type = c("proportion", "rate"),
  multiplier = if (type[1] == "proportion") 100 else 1e+05,
  target = NULL,
  limits = c(0.95, 0.998),
  point_colour = phw_colours[["grey_mid"]],
  labels = NULL,
  ...
)
```

## Arguments

- data:

  A data frame with one row per unit (area, practice...).

- numerator, denominator:

  Columns of events and of population (or patients, tests...), unquoted
  as in dplyr. Strings work too. Rows with a missing value or a
  denominator of 0 are left out, with a message.

- label:

  Optional column of unit names; units outside the outer limits are
  labelled.

- type:

  `"proportion"` (e.g. uptake) or `"rate"` (e.g. incidence).

- multiplier:

  Scale for the y axis: 100 for a percentage, 1e5 for a rate per
  100,000.

- target:

  The target value on the multiplied scale. Defaults to the overall
  value (sum of numerators over sum of denominators). It must be above 0
  (and below `multiplier` for a proportion), since otherwise the limits
  have no width.

- limits:

  Two confidence levels for the inner and outer limits.

- point_colour:

  Colour of points within the limits.

- labels:

  Optional named character vector that renames the zones in the legend
  and in `$data`, e.g. `c("Within limits" = "Gerllaw'r terfynau")`.
  Names are the default zone text and values the replacement. Each zone
  keeps its colour and shape.

- ...:

  Passed to
  [`ggplot2::geom_point()`](https://ggplot2.tidyverse.org/reference/geom_point.html),
  e.g. `size = 3`.

## Value

A ggplot. The units are in `$data`, with two added columns: `value` (the
percentage or rate) and `zone` ("Within limits", "Above 95%"...). If
`data` already has a column with one of those names, the added column
gets a dot in front (`.value`, `.zone`), so your columns are never
replaced.

## Details

Limits use the normal approximation to the binomial (for proportions) or
Poisson (for rates) distribution around the target.

## Examples

``` r
set.seed(2)
units <- data.frame(unit = paste("Unit", 1:40), n = round(runif(40, 200, 5000)))
units$events <- rbinom(40, units$n, 0.12)
phw_funnel(units, events, n, label = unit) +
  ggplot2::labs(title = "Proportion by unit", x = "Population", y = "Proportion (%)")
```
