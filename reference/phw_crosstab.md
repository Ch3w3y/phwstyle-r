# Cross-tabulation of counts

Counts by two variables (e.g. cases by week and age group, or organism
by health board), with totals and optional row or column percentages.
Render it with
[`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md)
or
[`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md),
or colour it with
[`phw_flextable_heat()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_heat.md).

## Usage

``` r
phw_crosstab(
  data,
  rows,
  cols,
  count = NULL,
  percent = c("none", "row", "column", "total"),
  totals = TRUE,
  missing = "Unknown",
  digits = 1,
  labels = list()
)
```

## Arguments

- data:

  A data frame with one row per case, or with a count column.

- rows, cols:

  The columns that make the rows and the columns of the table, unquoted
  as in dplyr. Strings work too.

- count:

  Optional column of counts (for aggregated data).

- percent:

  `"none"`, `"row"`, `"column"` or `"total"`.

- totals:

  Add a total row and column?

- missing:

  Label for missing values, or `NULL` to drop them.

- digits:

  Decimal places for percentages.

- labels:

  Named list of display names for `rows` and `cols`.

## Value

A `phw_summary` data frame. With `percent = "none"`, count columns are
numeric, so they sort and right-align properly.

## Examples

``` r
df <- data.frame(period = sample(1:6, 300, TRUE),
                 group = sample(c("Group A", "Group B", "Group C"), 300, TRUE))
phw_crosstab(df, period, group)
#>  period Group A Group B Group C Total
#>       1      20      12      17    49
#>       2      15      21      21    57
#>       3      20      18      10    48
#>       4      16      22      16    54
#>       5      18      15      15    48
#>       6      20      14      10    44
#>   Total     109     102      89   300
phw_crosstab(df, group, period, percent = "row")
#>    group          1          2          3          4          5          6
#>  Group A 20 (18.3%) 15 (13.8%) 20 (18.3%) 16 (14.7%) 18 (16.5%) 20 (18.3%)
#>  Group B 12 (11.8%) 21 (20.6%) 18 (17.6%) 22 (21.6%) 15 (14.7%) 14 (13.7%)
#>  Group C 17 (19.1%) 21 (23.6%) 10 (11.2%) 16 (18.0%) 15 (16.9%) 10 (11.2%)
#>    Total 49 (16.3%) 57 (19.0%) 48 (16.0%) 54 (18.0%) 48 (16.0%) 44 (14.7%)
#>         Total
#>  109 (100.0%)
#>  102 (100.0%)
#>   89 (100.0%)
#>  300 (100.0%)
#> n (% of row) 
```
