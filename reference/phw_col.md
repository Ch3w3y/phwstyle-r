# Get PHW colours by name

Works like `phw_colours[c(...)]` but gives a clear error for unknown
names and returns unnamed values when `names = FALSE`, which is what
most plotting functions want.

## Usage

``` r
phw_col(..., names = TRUE)
```

## Arguments

- ...:

  Colour names (see
  [phw_colours](https://ch3w3y.github.io/phwstyle-r/reference/phw_colours.md)).
  Leave empty to get all.

- names:

  Keep the names on the result?

## Value

A character vector of hex codes.

## Examples

``` r
phw_col("navy", "teal")
#>      navy      teal 
#> "#285087" "#24A2B5" 
```
