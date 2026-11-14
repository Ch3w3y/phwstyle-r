# Attack rates and relative risks by exposure

The standard outbreak investigation table: for each exposure (a food, a
setting, a risk factor) and each of its levels, the number of people,
the number who became cases, the attack rate, and the relative risk
against the reference level with a confidence interval and Fisher's
exact p-value.

## Usage

``` r
phw_risk_table(
  data,
  exposures,
  outcome,
  labels = list(),
  conf_level = 0.95,
  digits = 1,
  p_value = TRUE
)
```

## Arguments

- data:

  A data frame with one row per person.

- exposures:

  Exposure columns, chosen as in
  [`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html),
  e.g. `c(item_a, item_b)`. Logical or yes/no columns work best; the
  first level (or `FALSE`/"No") is the reference.

- outcome:

  Outcome column: logical, 0/1 or yes/no (case = `TRUE`, 1 or "Yes").

- labels:

  Named list of display names for exposures.

- conf_level:

  Confidence level.

- digits:

  Decimal places.

- p_value:

  Add a p-value column?

## Value

A `phw_summary` data frame.

## Examples

``` r
set.seed(1)
d <- data.frame(item_a = sample(c("Yes", "No"), 120, TRUE),
                item_b = sample(c("Yes", "No"), 120, TRUE))
d$ill <- rbinom(120, 1, ifelse(d$item_a == "Yes", 0.5, 0.15))
phw_risk_table(d, c(item_a, item_b), ill,
               labels = list(item_a = "Item A", item_b = "Item B"))
#>  Exposure People Cases Attack rate (%) Relative risk       95% CI p-value
#>    Item A     NA    NA              NA                                   
#>        No     61     7            11.5 1 (reference)                     
#>       Yes     59    27            45.8          3.99 1.88 to 8.45  <0.001
#>    Item B     NA    NA              NA                                   
#>        No     58    14            24.1 1 (reference)                     
#>       Yes     62    20            32.3          1.34 0.75 to 2.39    0.42
#> p-values from Fisher's exact test. 
```
