# Show PHW palettes

Draws every palette as a strip of swatches. Handy for checking colours.

## Usage

``` r
show_phw_palettes(
  palettes = names(phw_palettes),
  cvd = c("none", "deutan", "protan", "tritan")
)
```

## Arguments

- palettes:

  Palette names to draw.

- cvd:

  Show the palettes as someone with a colour vision deficiency would see
  them: `"none"`, `"deutan"`, `"protan"` or `"tritan"`. See
  [`phw_cvd()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_cvd.md).

## Value

A ggplot object.

## Examples

``` r
show_phw_palettes()

show_phw_palettes(c("main", "accessible"), cvd = "deutan")
```
