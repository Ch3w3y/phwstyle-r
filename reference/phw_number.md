# Number formatting in PHW style

Thousands separated with commas and a fixed number of decimals.

## Usage

``` r
phw_number(accuracy = 1, ...)

phw_percent(accuracy = 0.1, ...)
```

## Arguments

- accuracy:

  Rounding, as in
  [`scales::label_number()`](https://scales.r-lib.org/reference/label_number.html).

- ...:

  Passed to
  [`scales::label_number()`](https://scales.r-lib.org/reference/label_number.html)
  or
  [`scales::label_percent()`](https://scales.r-lib.org/reference/label_percent.html).

## Value

A labelling function.

## Examples

``` r
phw_number()(c(1234.5, 98765))
#> [1] "1,234"  "98,765"
phw_percent()(0.432)
#> [1] "43.2%"
```
