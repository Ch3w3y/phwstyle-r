# PHW palettes

The palettes the package uses for discrete (qualitative), sequential and
diverging scales.

## Usage

``` r
phw_palettes
```

## Format

A named list of character vectors.

## Details

- `main` (qualitative, 6): navy, teal, orange, pink, green and gold. The
  default. Every pair of the six stays apart for colour-blind readers:
  the colour difference (delta E in CIELAB, a scale where about 10 or
  more is easy to tell apart) is at least 17 under simulated
  deuteranopia and protanopia, the two red-green types, and about 9
  under tritanopia. Gold is below 3:1 contrast on white, so it suits
  filled shapes (bars, areas, map fills) better than thin lines.

- `extended` (qualitative, 12): `main` and six more. Charts with more
  than six groups carry on into it automatically, so every chart in a
  report starts with the same six colours. Its colours are:

  - 1 to 6 are `main`: the four chart colours PHW reports use, the green
    of the phw.nhs.wales website and gold (Pantone 465) from the NHS
    Wales logo guidelines.

  - 7 is wine, which is not a PHW colour. It was chosen to stay distinct
    from the others.

  - 8 and 9 are mint and bright green from the Long-Term Strategy.

  - 10 is the blue of the phw.nhs.wales website.

  - 11 is dark orange, the dark end of `orange_navy`. It is eight places
    after the bright orange, so the two oranges are never side by side.

  - 12 is black from the NHS Wales logo guidelines. It comes last so
    that a chart with a few groups does not get a black series, which
    reads like a total or a reference line.

  Every pair of the twelve has a delta E of at least 11.5 for normal
  vision, deuteranopia and protanopia. Gold, mint and bright green are
  below 3:1 contrast on white. Twelve lines on one chart are still hard
  to read: use facets or direct labels where you can.

  Lighter and darker shades of one hue (light teal beside teal, for
  example) are not used as separate groups, because colour-blind readers
  can hardly tell them apart. For ordered or nested groups, use the
  sequential `blues`, `teals` or `greens` palettes instead.

- `accessible` (qualitative, 8): chosen so every pair stays distinct
  under simulated deuteranopia, protanopia and tritanopia (minimum
  colour difference, delta E, of about 17), and every colour has at
  least 3:1 contrast on white. It starts with navy, teal and orange, so
  short series still look like PHW. Black and a dark rose-brown come
  last, for the same reason as black in `extended`. It is never used
  unless you ask for it: see
  [`phw_default_palette()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_default_palette.md)
  for how to switch a whole script or document to it.

- `highlight` (qualitative): navy for the focus series, light grey for
  every other series, however many there are.

- `rag` (qualitative, 3): red / amber / green (RAG) status colours that
  keep 3:1 contrast on white. These were chosen for phwstyle, not taken
  from a PHW source.

- `rag_accessible` (qualitative, 3): like `rag`, but "good" is navy
  instead of green, because red and green look alike to many
  colour-blind readers.

- `strategy` (qualitative, 6): the colours of the six strategic
  priorities in PHW's Long-Term Strategy 2023 to 2035, named `services`,
  `system`, `behaviours`, `wellbeing`, `determinants` and `climate`. Use
  it for work reported by priority. The order is not the strategy's own
  numbering: its first four follow the first four of `main` (blue, teal,
  orange, pink, then the rest), so the first groups in a chart look the
  same whichever palette is used. To colour by priority, match on the
  names.

- `blues`, `teals`, `greens`, `gradient` (sequential). `greens` runs
  from a pale tint to the website green and its dark shade.

- `orange_navy` (diverging).

**Colour order.** `extended` starts with the six colours of `main`, so a
chart with up to six groups looks the same whichever of the two a report
uses. `accessible` starts with the same navy, teal and orange, so a
chart with up to three groups looks the same in all three. `highlight`
starts with the same navy, then grey. `strategy` has its own shades in
the same order: blue, mint, orange, pink. The exceptions are the
palettes where colour carries a fixed meaning (`rag`, `rag_accessible`),
and the sequential and diverging palettes, which run from light to dark.

## Examples

``` r
names(phw_palettes)
#>  [1] "main"           "extended"       "accessible"     "highlight"     
#>  [5] "rag"            "rag_accessible" "strategy"       "blues"         
#>  [9] "teals"          "greens"         "gradient"       "orange_navy"   
phw_palettes$main
#> [1] "#285087" "#24A2B5" "#FF5D0C" "#F43882" "#338276" "#CFAB7A"
phw_palettes$strategy
#>     services       system   behaviours    wellbeing determinants      climate 
#>    "#215B8B"    "#5FBDAF"    "#ED6F18"    "#E05A8C"    "#5A356B"    "#50AF31" 
show_phw_palettes(c("main", "extended", "accessible"))
```
