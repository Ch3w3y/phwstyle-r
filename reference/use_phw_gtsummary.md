# PHW theme for gtsummary

Sets a [gtsummary](https://www.danieldsjoberg.com/gtsummary/) theme so
every gtsummary table (`tbl_summary()`, `tbl_regression()`,
`tbl_cross()`...) uses the PHW style when printed with gt or converted
with `as_flex_table()`. Call it once at the start of a script or in your
setup chunk.

## Usage

``` r
use_phw_gtsummary(style = "booktabs", font_size = 10, ...)
```

## Arguments

- style:

  Passed to
  [`phw_flextable_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_theme.md)
  for flextable output.

- font_size:

  Body font size (points for flextable, pixels for gt).

- ...:

  Other gtsummary theme elements, e.g.
  `"tbl_summary-str:default_con_type" = "continuous2"`.

## Value

The theme list, invisibly (it is also applied).

## Examples

``` r
if (requireNamespace("gtsummary", quietly = TRUE)) {
  use_phw_gtsummary()
  gtsummary::reset_gtsummary_theme()
}
```
