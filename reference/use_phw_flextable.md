# Set PHW defaults for every new flextable

Sets
[`flextable::set_flextable_defaults()`](https://davidgohel.github.io/flextable/reference/set_flextable_defaults.html)
so all new flextables use the PHW font, colours and padding, and applies
[`phw_flextable_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_theme.md)
automatically. Put it in your setup chunk.

## Usage

``` r
use_phw_flextable(style = "booktabs", font_size = 10, ...)
```

## Arguments

- style:

  Passed to
  [`phw_flextable_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_theme.md).

- font_size:

  Body font size.

- ...:

  Other
  [`phw_flextable_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_theme.md)
  arguments, e.g. `accent`.

## Value

The previous defaults, invisibly.

## Examples

``` r
if (requireNamespace("flextable", quietly = TRUE)) {
  old <- use_phw_flextable()
  flextable::flextable(head(airquality))

  # Put back the defaults you had before
  do.call(flextable::set_flextable_defaults, old)
}
```
