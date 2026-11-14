# Check colours for colour-blind readers and contrast

Tests a set of colours, such as a palette or the fills in a chart. For
normal vision and each colour vision deficiency, it finds the two
colours that are hardest to tell apart. It also checks each colour's
contrast against the background.

## Usage

``` r
phw_check_colours(
  colours,
  background = "#FFFFFF",
  min_distance = 10,
  min_contrast = 3
)
```

## Arguments

- colours:

  Colours to check. A palette name also works.

- background:

  Background colour.

- min_distance:

  Smallest acceptable delta E.

- min_contrast:

  Smallest acceptable contrast ratio for marks.

## Value

A data frame with one row per vision type, invisibly. It prints a
summary.

## Details

Distances are delta E in CIELAB, a colour space built so that equal
distances look about equally different; under about 10 is hard to tell
apart in a legend. The Web Content Accessibility Guidelines (WCAG 2.2)
ask for 3:1 contrast for chart marks and 4.5:1 for text.

## Examples

``` r
phw_check_colours("main")
#> ✔ normal: closest pair #24A2B5 / #285087 (distance 44.5)
#> ✔ deuteranopia: closest pair #24A2B5 / #285087 (distance 30.4)
#> ✔ protanopia: closest pair #F43882 / #24A2B5 (distance 17.9)
#> ✖ tritanopia: closest pair #F43882 / #FF5D0C (distance 8.9)
#> ✔ All colours have at least 3:1 contrast on #FFFFFF.
phw_check_colours(c("#D50B5C", "#338276"))
#> ✔ normal: closest pair #338276 / #D50B5C (distance 100)
#> ✔ deuteranopia: closest pair #338276 / #D50B5C (distance 23.7)
#> ✔ protanopia: closest pair #338276 / #D50B5C (distance 18)
#> ✔ tritanopia: closest pair #338276 / #D50B5C (distance 116.5)
#> ✔ All colours have at least 3:1 contrast on #FFFFFF.
```
