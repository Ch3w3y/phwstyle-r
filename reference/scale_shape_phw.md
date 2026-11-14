# Shape and linetype scales for colour-blind readers

Colour should never be the only way to tell groups apart. These scales
add a second cue: point shapes that differ in outline as well as fill,
and line types that stay distinct in print. Use them on the same
variable as the colour, and ggplot2 merges the legends.

## Usage

``` r
scale_shape_phw(..., values = c(16, 17, 15, 18, 1, 2, 0, 5))

scale_linetype_phw(
  ...,
  values = c("solid", "22", "42", "13", "1343", "73", "2262", "12223242")
)
```

## Arguments

- ...:

  Passed to
  [`ggplot2::scale_shape_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html)
  or
  [`ggplot2::scale_linetype_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html).

- values:

  Override the shapes or line types.

## Value

A ggplot2 scale.

## Examples

``` r
library(ggplot2)
ggplot(mpg, aes(displ, hwy, colour = drv, shape = drv)) +
  geom_point() +
  scale_shape_phw() +
  theme_phw()
```
