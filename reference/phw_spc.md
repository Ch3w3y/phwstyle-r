# Statistical process control (SPC) chart

An XmR chart or a run chart for a measure over time, as used for quality
improvement. An XmR chart plots individual values (X) with limits worked
out from the moving range (mR), the change from one point to the next.
Points that show special cause variation are coloured: outside the
process limits, a shift of `shift` or more points on one side of the
centre line, or a trend of `trend` or more points going the same way.
With `improvement`, special causes in the good direction are blue and in
the bad direction orange, as in NHS "Making Data Count" charts.

## Usage

``` r
phw_spc(
  data,
  x,
  y,
  type = c("xmr", "run"),
  improvement = c("none", "increase", "decrease"),
  baseline = NULL,
  shift = 7,
  trend = 6,
  labels = NULL,
  ...
)
```

## Arguments

- data:

  A data frame with one row per time point.

- x, y:

  The time column (date or number) and the measure, unquoted as in dplyr
  (strings work too).

- type:

  `"xmr"` (centre line at the mean, limits at 2.66 times the mean moving
  range) or `"run"` (median line, no limits).

- improvement:

  Which direction is better: `"none"`, `"increase"` or `"decrease"`.

- baseline:

  Number of points to calculate the centre line and limits from (e.g.
  the first 20). `NULL` uses all points.

- shift, trend:

  Run lengths that count as special causes.

- labels:

  Optional named character vector that renames the signals in the legend
  and in `$data`, e.g. `c("Common cause" = "Achos cyffredin")`. Names
  are the default signal text and values the replacement. Each signal
  keeps its colour and shape.

- ...:

  Passed to
  [`ggplot2::geom_point()`](https://ggplot2.tidyverse.org/reference/geom_point.html),
  e.g. `size = 3`.

## Value

A ggplot. The points, with a `signal` column, are in `$data`.

## Examples

``` r
set.seed(3)
spc <- data.frame(month = seq(as.Date("2023-01-01"), by = "month", length.out = 30),
                  value = c(rnorm(20, 50, 4), rnorm(10, 58, 4)))
phw_spc(spc, month, value, improvement = "increase", baseline = 20)
```
