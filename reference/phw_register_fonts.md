# Register the bundled Ubuntu fonts

Called automatically when the package loads. It registers Ubuntu with
'systemfonts', so ragg, svglite and the Word/PowerPoint outputs in
'officer'/'flextable' can find it without the font being installed.

## Usage

``` r
phw_register_fonts()
```

## Value

`TRUE` invisibly if the fonts were registered.

## Details

The base [`pdf()`](https://rdrr.io/r/grDevices/pdf.html) device and
LaTeX can't see registered fonts. For those, run
[`phw_install_fonts()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_install_fonts.md)
once.

## Examples

``` r
# Runs when phwstyle loads; call it again only if fonts were reset.
phw_register_fonts()
```
