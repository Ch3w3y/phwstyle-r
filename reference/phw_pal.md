# Get a vector of colours from a PHW palette

Qualitative palettes return their colours in order (and refuse to make
up extra ones). Sequential and diverging palettes are interpolated to
any length. Asking `"main"` for more than four colours carries on into
`"extended"`, as the charts do.

## Usage

``` r
phw_pal(
  n = NULL,
  palette = phw_default_palette(),
  reverse = FALSE,
  type = c("qualitative", "sequential")
)
```

## Arguments

- n:

  Number of colours. Defaults to the palette length.

- palette:

  A palette name (see
  [phw_palettes](https://ch3w3y.github.io/phwstyle-r/reference/phw_palettes.md)),
  a character vector of colours, or a function that takes `n` and
  returns colours.

- reverse:

  Reverse the order?

- type:

  For a vector of colours: `"qualitative"` (use in order) or
  `"sequential"` (interpolate). Names are always qualitative.

## Value

A character vector of hex colours.

## Details

`palette` can be a PHW palette name, your own vector of colours, or a
function of `n`. So any scale or table function in phwstyle accepts a
custom palette as easily as a built-in one.

## Examples

``` r
phw_pal(3)
#> [1] "#285087" "#24A2B5" "#FF5D0C"
phw_pal(9, "blues")
#> [1] "#E7ECF3" "#D4DCE8" "#BBC7D9" "#99ACC6" "#7890B3" "#5675A1" "#365A8E"
#> [8] "#234678" "#1A355F"
phw_pal(2, c("#285087", "#FF5D0C"))
#> [1] "#285087" "#FF5D0C"
```
