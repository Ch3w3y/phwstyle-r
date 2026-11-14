# Exact Poisson confidence interval for a count

Exact Poisson confidence interval for a count

## Usage

``` r
phw_poisson_ci(x, conf_level = 0.95)
```

## Arguments

- x:

  Counts.

- conf_level:

  Confidence level.

## Value

A data frame with `lower` and `upper`.

## Examples

``` r
phw_poisson_ci(c(0, 5, 120))
#>       lower      upper
#> 1  0.000000   3.688879
#> 2  1.623486  11.668332
#> 3 99.491926 143.490585
```
