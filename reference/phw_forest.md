# Forest plot

Estimates with their intervals for a set of units (areas, practices,
groups), sorted by value. With a `target`, such as the overall value,
each unit is coloured and shaped by whether its interval lies above the
target, overlaps it or lies below it. You supply the estimates and
intervals, and nothing is calculated from them.

## Usage

``` r
phw_forest(data, value, lower, upper, label, target = NULL, labels = NULL, ...)
```

## Arguments

- data:

  A data frame with one row per unit.

- value, lower, upper:

  Columns of the estimate and of the lower and upper ends of its
  interval, unquoted as in dplyr. Strings work too.

- label:

  Column of unit names.

- target:

  Optional reference value on the same scale as `value`, drawn as a
  dashed line.

- labels:

  Optional named character vector to rename the three comparison levels.
  The names are the default text (`"Higher"`, `"Similar"`, `"Lower"`)
  and the values are the replacements, e.g. `c(Higher = "Above Wales")`.

- ...:

  Passed to
  [`ggplot2::geom_point()`](https://ggplot2.tidyverse.org/reference/geom_point.html).

## Value

A ggplot. The units, sorted by value and with a `compared` column (a
factor of `"Higher"`, `"Similar"` and `"Lower"`, absent without a
`target`), are in `$data`.

## Details

A unit is "Higher" when its whole interval is above the target and
"Lower" when its whole interval is below it. Otherwise it is "Similar".
Without a `target` every unit is drawn in navy, with no legend.

## Examples

``` r
set.seed(4)
areas <- data.frame(area = paste("Area", LETTERS[1:8]), value = round(runif(8, 40, 80), 1))
areas$lower <- areas$value - round(runif(8, 4, 10), 1)
areas$upper <- areas$value + round(runif(8, 4, 10), 1)
phw_forest(areas, value, lower, upper, label = area, target = 60) +
  ggplot2::labs(title = "Rate by area", x = "Rate per 100,000")
```
