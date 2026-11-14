# PHW colour scale for plotly

Turns a PHW palette into the colour scale format plotly expects, for
heatmaps, choropleths and markers coloured by a number, e.g.
`plot_ly(z = volcano, type = "heatmap", colorscale = phw_plotly_colorscale("teals"))`.

## Usage

``` r
phw_plotly_colorscale(palette = "blues", reverse = FALSE, n = 9)
```

## Arguments

- palette:

  A sequential or diverging palette name, or a vector of colours.

- reverse:

  Reverse the scale?

- n:

  Number of steps.

## Value

A list of `list(position, colour)` pairs.

## Examples

``` r
phw_plotly_colorscale("blues", n = 3)
#> [[1]]
#> [[1]][[1]]
#> [1] 0
#> 
#> [[1]][[2]]
#> [1] "#E7ECF3"
#> 
#> 
#> [[2]]
#> [[2]][[1]]
#> [1] 0.5
#> 
#> [[2]][[2]]
#> [1] "#7890B3"
#> 
#> 
#> [[3]]
#> [[3]][[1]]
#> [1] 1
#> 
#> [[3]][[2]]
#> [1] "#1A355F"
#> 
#> 
```
