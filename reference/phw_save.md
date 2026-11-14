# Save a PHW chart

A wrapper around
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
with sensible defaults for PHW outputs. It saves at 16 x 10 cm and 300
dpi, uses 'ragg' for PNG so the bundled Ubuntu font works, and accepts
plots made with
[`phw_finalise()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_finalise.md).

## Usage

``` r
phw_save(
  plot = ggplot2::last_plot(),
  filename,
  width = 16,
  height = 10,
  units = "cm",
  dpi = 300,
  bg = "white",
  device = NULL,
  ...
)
```

## Arguments

- plot:

  A ggplot or the result of
  [`phw_finalise()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_finalise.md).

- filename:

  File name. The extension (`.png`, `.svg`, `.pdf`, `.jpeg`) picks the
  format.

- width, height, units:

  Size. Defaults to 16 x 10 cm, which fits an A4 Word page with standard
  margins.

- dpi:

  Resolution for raster formats.

- bg:

  Background colour. Use `"transparent"` for overlays.

- device:

  Override the graphics device that the extension picks.

- ...:

  Passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

## Value

The file name, invisibly.

## Examples

``` r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  theme_phw()
f <- phw_save(p, tempfile(fileext = ".png"))
file.exists(f)
#> [1] TRUE

# Wider, for a slide
phw_save(p, tempfile(fileext = ".png"), width = 25, height = 12)
```
