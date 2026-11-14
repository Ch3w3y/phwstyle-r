# Contrast ratio between two colours

The contrast ratio from the Web Content Accessibility Guidelines (WCAG),
the standard most public sector websites and documents are checked
against.

## Usage

``` r
phw_contrast(x, y = "#FFFFFF")
```

## Arguments

- x, y:

  Colours (any form
  [`grDevices::col2rgb()`](https://rdrr.io/r/grDevices/col2rgb.html)
  accepts).

## Value

Contrast ratios, from 1 to 21. The WCAG AA level needs 4.5 for body text
and 3 for large text and chart marks.

## Examples

``` r
phw_contrast(phw_colours["teal"], "white")
#> [1] 3.038905
```
