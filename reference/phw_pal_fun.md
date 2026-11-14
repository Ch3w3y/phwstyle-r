# Palette functions for scales

Returns a function of `n`, as the scales package expects.

## Usage

``` r
phw_pal_fun(palette = phw_default_palette(), reverse = FALSE)
```

## Arguments

- palette:

  A palette name (see
  [phw_palettes](https://ch3w3y.github.io/phwstyle-r/reference/phw_palettes.md)),
  a character vector of colours, or a function that takes `n` and
  returns colours.

- reverse:

  Reverse the order?

## Value

A function.

## Examples

``` r
pal <- phw_pal_fun("blues")
pal(3)
#> [1] "#E7ECF3" "#7890B3" "#1A355F"
```
