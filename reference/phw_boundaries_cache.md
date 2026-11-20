# Boundary cache folder

Where
[`phw_boundaries()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundaries.md)
keeps downloaded boundaries.

## Usage

``` r
phw_boundaries_cache(clear = FALSE)
```

## Arguments

- clear:

  Delete the cached files?

## Value

The folder path, invisibly when `clear = TRUE`.

## Examples

``` r
phw_boundaries_cache()
#> [1] "/home/runner/.cache/R/phwstyle/boundaries"
```
