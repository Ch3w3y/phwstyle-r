# Simulate colour vision deficiency

Shows how colours look to someone with one of the three common colour
vision deficiencies, using the Machado et al. (2009) model at full
severity. About 1 in 12 men and 1 in 200 women have red-green colour
blindness (deuteranopia or protanopia). Tritanopia is rare.

## Usage

``` r
phw_cvd(colours, type = c("deutan", "protan", "tritan"))
```

## Arguments

- colours:

  Colours (any form
  [`grDevices::col2rgb()`](https://rdrr.io/r/grDevices/col2rgb.html)
  accepts).

- type:

  `"deutan"` (green-blind, the most common), `"protan"` (red-blind) or
  `"tritan"` (blue-blind).

## Value

Hex colours as they would be seen.

## References

Machado, G. M., Oliveira, M. M. and Fernandes, L. A. F. (2009). A
physiologically-based model for simulation of color vision deficiency.
IEEE Transactions on Visualization and Computer Graphics, 15(6),
1291-1298.
[doi:10.1109/TVCG.2009.113](https://doi.org/10.1109/TVCG.2009.113)

## Examples

``` r
phw_cvd(phw_pal(4), "deutan")
#> [1] "#284C86" "#7F8EB5" "#B5A000" "#98937E"
```
