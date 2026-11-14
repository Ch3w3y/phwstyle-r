# Fixed colours for groups that stay the same across reports

A colour key gives every group (an age band, a health board, an
organism) its own colour and remembers it. Each time you plot, groups
already in the key keep their colour. New groups get the next palette
colour that the key isn't using yet. So adding a "90+" age band next
month doesn't reshuffle the colours of the other bands.

## Usage

``` r
phw_colour_key(
  levels,
  name = NULL,
  palette = phw_default_palette(),
  fixed = NULL,
  neutral = default_neutral,
  neutral_colour = phw_colours[["grey_mid"]],
  save = TRUE
)
```

## Arguments

- levels:

  The groups: a factor (its levels are used, in order), or a character
  vector.

- name:

  Key name, e.g. `"age_group"`. `NULL` gives colours in order with no
  memory.

- palette:

  Palette for new groups: a name from
  [phw_palettes](https://ch3w3y.github.io/phwstyle-r/reference/phw_palettes.md),
  or a vector of colours.

- fixed:

  Named vector of colours to pin, e.g. `c(Wales = "#285087")`. Pinned
  colours replace any stored colour.

- neutral:

  Group names to draw in `neutral_colour`. Matching ignores case.

- neutral_colour:

  Colour for neutral groups.

- save:

  Store new colours in the key?

## Value

A named character vector of colours, one per group in `levels`.

## Details

- **In one session**, keys live in memory. Use the same `name` in every
  chart.

- **Across reports**, point phwstyle at a CSV file with
  [`phw_key_file()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_key.md).
  Keys are then read from and written to that file, which you can keep
  with the project (and in version control). The file is plain text:
  `key,level,colour`. You can edit it by hand.

The key stores the colour itself, not a position in a palette. Changing
`palette` later only affects groups that don't have a colour yet. To
move a whole key to a different palette on purpose, use
[`phw_key_recolour()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_key.md).

The one exception is the colour-blind safe `"accessible"` palette, which
can be switched on for a whole document (see
[`phw_default_palette()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_default_palette.md)).
A key then keeps a second set of colours, stored as `name@accessible`,
with the groups in the same order. So the same report can be rendered in
default and in accessible colours, and each version keeps its colours
from one run to the next.

`"main"` carries on into `"extended"` after four groups. When a palette
runs out altogether, the key carries on with unused colours from the
other PHW palettes, then lighter tints, and warns you. `"extended"`
keeps twelve colours apart, but past about eight groups a chart is hard
to read by colour alone: use facets, direct labels or
[`scale_shape_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/scale_shape_phw.md)
as well.

Groups called "Other", "Unknown", "Not known" and similar are drawn in
grey so they don't compete with real groups. Change this with `neutral`.

## See also

[`scale_colour_phw_d()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
with `key = "name"` to use a key in ggplot2. The returned vector also
works directly in plotly (`colors =`), flextable and reactable.

## Examples

``` r
ages <- c("0-4", "5-14", "15-44", "45-64", "65+")
phw_colour_key(ages, "age_example")
#>       0-4      5-14     15-44     45-64       65+ 
#> "#285087" "#24A2B5" "#FF5D0C" "#F43882" "#231F20" 
# A new band keeps the others where they were:
phw_colour_key(c(ages, "Unknown", "85+"), "age_example")
#>       0-4      5-14     15-44     45-64       65+   Unknown       85+ 
#> "#285087" "#24A2B5" "#FF5D0C" "#F43882" "#231F20" "#768692" "#338276" 
phw_key_reset("age_example")
```
