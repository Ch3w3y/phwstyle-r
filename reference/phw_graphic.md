# Path to a PHW brand graphic

The graphics are drawn by phwstyle itself and contain no logo.

## Usage

``` r
phw_graphic(name = c("band", "cover", "cover_wide"))
```

## Arguments

- name:

  `"band"` (the header gradient band), `"cover"` (the A4 portrait cover
  background) or `"cover_wide"` (the 16:9 slide background).

## Value

A file path.

## Examples

``` r
phw_graphic("band")
#> [1] "/home/runner/work/_temp/Library/phwstyle/graphics/band.png"
```
