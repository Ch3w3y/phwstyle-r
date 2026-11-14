# Use PHW styling for every ggplot in the session

Call it once at the top of a script, or in the setup chunk of a Quarto
document, and every plot after it is in the PHW style with no further
code. The R Markdown formats
([`phw_html_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md)
and friends) call it for you. It sets:

## Usage

``` r
use_phw_ggplot(..., palette = NULL)
```

## Arguments

- ...:

  Passed to
  [`theme_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw.md),
  e.g. `base_size = 14` or `accessible = TRUE` (larger text and thicker
  lines).

- palette:

  Default qualitative palette for every chart, table and widget, e.g.
  `"accessible"` for the colour-blind safe palette. Sets
  `options(phwstyle.palette)`; see
  [`phw_default_palette()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_default_palette.md).
  `NULL` leaves the palette as it is.

## Value

The previous theme, invisibly.

## Details

- [`theme_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw.md)
  as the default theme

- the PHW palette for groups (colour and fill), and PHW blues for
  continuous and binned colours

- default colours for layers that don't map a colour: navy bars, areas,
  lines and points, with text and reference lines in the PHW text colour

- the PHW font for text and labels

- the same for geoms from extension packages that are already loaded
  (see
  [`phw_style_extensions()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_style_extensions.md)),
  so load ggrepel, ggridges and the like first

The result is the same on ggplot2 3.5 and 4.0.

After this, add
[`theme_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw.md)
or a `scale_*_phw_*()` to a plot only to change something for that plot,
such as `theme_phw(grid = "x")` or
`scale_fill_phw_d(key = "age_group")`. Anything you add to a plot wins
over these defaults.

## Examples

``` r
library(ggplot2)
old <- use_phw_ggplot()
ggplot(mpg, aes(class)) + geom_bar()

ggplot(mpg, aes(displ, hwy, colour = drv)) + geom_point()

theme_set(old)
```
