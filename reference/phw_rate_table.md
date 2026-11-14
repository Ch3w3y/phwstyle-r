# Rates with confidence intervals by group

Rates per population (e.g. per 100,000) with exact Poisson confidence
intervals, for one or more grouping variables such as age group, sex,
deprivation quintile or risk factor. With several grouping variables,
each one becomes a section with its own heading, as in a demographic
breakdown of infection rates.

## Usage

``` r
phw_rate_table(
  data,
  groups,
  cases,
  population,
  per = 1e+05,
  conf_level = 0.95,
  digits = 1,
  labels = list(),
  total = TRUE,
  rate_label = NULL
)
```

## Arguments

- data:

  Aggregated data: one row per group (or finer), with columns of case
  counts and population. Rows are summed within each group.

- groups:

  Grouping columns, chosen as in
  [`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html),
  e.g. `c(age_group, sex)`. Each gets its own section.

- cases, population:

  Columns holding counts and denominators, unquoted as in dplyr. Strings
  work too.

- per:

  Rate multiplier, e.g. `1e5` for per 100,000.

- conf_level:

  Confidence level for the intervals.

- digits:

  Decimal places for rates.

- labels:

  Named list of display names for the grouping columns.

- total:

  Add an overall row at the top?

- rate_label:

  Heading for the rate column. Defaults to "Rate per 100,000" (or
  whatever `per` is).

## Value

A `phw_summary` data frame with numeric Cases, Population and Rate
columns and a text confidence interval column.

## Details

Intervals use the exact (Garwood) method based on the chi-square
distribution, which works for small counts, including zero.

## Examples

``` r
d <- expand.grid(age_group = c("0-14", "15-44", "45-64", "65+"),
                 sex = c("Female", "Male"))
d$cases <- c(12, 30, 41, 66, 10, 28, 45, 70)
d$pop <- c(250, 600, 400, 300, 260, 590, 390, 260) * 1000
phw_rate_table(d, c(age_group, sex), cases, pop,
               labels = list(age_group = "Age group", sex = "Sex"))
#>      Group Cases Population Rate per 100,000       95% CI
#>      Total   302    3050000              9.9  8.8 to 11.1
#>  Age group    NA         NA               NA             
#>       0-14    22     510000              4.3   2.7 to 6.5
#>      15-44    58    1190000              4.9   3.7 to 6.3
#>      45-64    86     790000             10.9  8.7 to 13.4
#>        65+   136     560000             24.3 20.4 to 28.7
#>        Sex    NA         NA               NA             
#>     Female   149    1550000              9.6  8.1 to 11.3
#>       Male   153    1500000             10.2  8.6 to 12.0
#> Confidence intervals use the exact Poisson method. 
```
