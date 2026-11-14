# PHW colour and fill scales

- `_d` scales are discrete and use the qualitative palettes (`main`,
  `extended`, `accessible`, `highlight`, `rag`, `strategy`).

- `_c` scales are continuous, `_b` scales are binned. Both use
  sequential or diverging palettes (`blues`, `teals`, `greens`,
  `gradient`, `orange_navy`).

- `scale_*_phw_div()` centres the diverging palette on `midpoint`.

## Usage

``` r
scale_colour_phw_d(
  palette = phw_default_palette(),
  reverse = FALSE,
  key = NULL,
  values = NULL,
  neutral = default_neutral,
  aesthetics = "colour",
  na.value = phw_colours[["grey_light"]],
  ...
)

scale_fill_phw_d(
  palette = phw_default_palette(),
  reverse = FALSE,
  key = NULL,
  values = NULL,
  neutral = default_neutral,
  aesthetics = "fill",
  na.value = phw_colours[["grey_light"]],
  ...
)

scale_color_phw_d(
  palette = phw_default_palette(),
  reverse = FALSE,
  key = NULL,
  values = NULL,
  neutral = default_neutral,
  aesthetics = "colour",
  na.value = phw_colours[["grey_light"]],
  ...
)

scale_colour_phw_c(
  palette = "blues",
  reverse = FALSE,
  aesthetics = "colour",
  na.value = phw_colours[["grey_light"]],
  ...
)

scale_fill_phw_c(
  palette = "blues",
  reverse = FALSE,
  aesthetics = "fill",
  na.value = phw_colours[["grey_light"]],
  ...
)

scale_color_phw_c(
  palette = "blues",
  reverse = FALSE,
  aesthetics = "colour",
  na.value = phw_colours[["grey_light"]],
  ...
)

scale_colour_phw_b(
  palette = "blues",
  reverse = FALSE,
  aesthetics = "colour",
  na.value = phw_colours[["grey_light"]],
  ...
)

scale_fill_phw_b(
  palette = "blues",
  reverse = FALSE,
  aesthetics = "fill",
  na.value = phw_colours[["grey_light"]],
  ...
)

scale_color_phw_b(
  palette = "blues",
  reverse = FALSE,
  aesthetics = "colour",
  na.value = phw_colours[["grey_light"]],
  ...
)

scale_fill_phw_div(
  midpoint = 0,
  palette = "orange_navy",
  reverse = FALSE,
  aesthetics = "fill",
  na.value = phw_colours[["grey_light"]],
  ...
)

scale_colour_phw_div(
  midpoint = 0,
  palette = "orange_navy",
  reverse = FALSE,
  aesthetics = "colour",
  na.value = phw_colours[["grey_light"]],
  ...
)

scale_color_phw_div(
  midpoint = 0,
  palette = "orange_navy",
  reverse = FALSE,
  aesthetics = "colour",
  na.value = phw_colours[["grey_light"]],
  ...
)
```

## Arguments

- palette:

  Palette name (see
  [phw_palettes](https://ch3w3y.github.io/phwstyle-r/reference/phw_palettes.md)),
  a vector of colours, or a function of `n`.

- reverse:

  Reverse the palette?

- key:

  Name of a colour key, so each group keeps its colour across charts and
  reports.

- values:

  Named vector of colours to pin to particular groups.

- neutral:

  Group names to draw in grey, see
  [`phw_colour_key()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_colour_key.md).

- aesthetics:

  Aesthetics this scale works with, e.g. `c("colour", "fill")` to colour
  both with one scale.

- na.value:

  Colour for missing values.

- ...:

  Passed to the underlying ggplot2 scale constructor.

- midpoint:

  Value at the centre of a diverging scale.

## Value

A ggplot2 scale.

## Details

Every scale takes a palette name, your own vector of colours, or (for
`_d` scales) a function of `n`. Everything else goes to the ggplot2
scale, so `name`, `labels`, `breaks`, `limits`, `guide`, `na.value` and
so on work as usual.

**Do you need one?** After
[`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md),
or inside a `phw_*_document()`, plots already use these palettes, so a
scale adds nothing unless you give it something to change: another
`palette`, a colour `key`, pinned `values`, or a legend `name`. In a
plain script with no setup, add one to each plot. A scale added to a
plot always replaces the default for that aesthetic, whether it is one
of these or a ggplot2 scale such as
[`ggplot2::scale_fill_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html).

**More than four groups.** `"main"` has four colours and carries on into
`"extended"` (twelve), so a chart with six groups starts with the same
four colours as a chart with four. The first seven have a published
source; see
[phw_palettes](https://ch3w3y.github.io/phwstyle-r/reference/phw_palettes.md)
for where the rest come from. Past the end of a palette you get colours
from the other PHW palettes and a warning.

**Colours that stick to groups.** By default a `_d` scale colours groups
in the order they appear. To keep the same colour for a group in every
chart and every report, give a `key`, e.g. `key = "age_group"`. New
groups get the next free colour and old ones never move (see
[`phw_colour_key()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_colour_key.md)).
You can also pin colours with `values`, a named vector such as
`c(Wales = "#285087")`. Groups named "Other" or "Unknown" are drawn in
grey. (Only these scales know the group names, so a plot left on the
default colours gives "Other" an ordinary colour.)

**Colour-blind readers.** Use `palette = "accessible"` for one chart, or
switch every chart, table and widget at once: see
[`phw_default_palette()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_default_palette.md).
Add
[`scale_shape_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/scale_shape_phw.md)
or
[`scale_linetype_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/scale_shape_phw.md)
so groups differ by more than colour.

## Examples

``` r
library(ggplot2)
ggplot(mpg, aes(class, fill = drv)) + geom_bar() + scale_fill_phw_d() + theme_phw()


# The same colour for each group in every chart:
ggplot(mpg, aes(displ, hwy, colour = drv)) +
  geom_point() +
  scale_colour_phw_d(key = "drive_example") +
  theme_phw()

phw_key_reset("drive_example")
```
