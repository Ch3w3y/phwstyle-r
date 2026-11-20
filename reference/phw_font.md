# PHW font family

PHW publications and the phw.nhs.wales website use **Ubuntu**. The NHS
Wales logo guidelines (2022) name Frutiger, with Arial or Verdana as a
fallback. This package defaults to Ubuntu, which ships with the package,
and falls back to Arial and then to `"sans"` when Ubuntu can't be used.

## Usage

``` r
phw_font()
```

## Value

A font family name.

## Details

Set `options(phwstyle.font = "Arial")` to force a different family
everywhere, for example to follow the NHS Wales Frutiger/Arial rule.

## Examples

``` r
phw_font()
#> [1] "Ubuntu"
```
