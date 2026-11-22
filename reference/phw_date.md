# Format a date the PHW way

Reports write dates as dd/mm/yyyy in captions ("Data correct as of
03/11/2026") and as "3 November 2026" in text.

## Usage

``` r
phw_date(x, style = "short")
```

## Arguments

- x:

  A Date, a date-time, or text in ISO form (`"2026-11-03"`). Text in any
  other form, such as `"03/11/2026"`, stops with a message rather than
  being guessed at: convert it first with
  [`as.Date()`](https://rdrr.io/r/base/as.Date.html) and a `format`.
  Missing dates stay `NA`.

- style:

  `"short"` (03/11/2026) or `"long"` (3 November 2026), or a
  [`format()`](https://rdrr.io/r/base/format.html) string such as
  `"%B %Y"`.

## Value

A character vector.

## Examples

``` r
phw_date(as.Date("2026-11-03"))
#> [1] "03/11/2026"
phw_date(as.Date("2026-11-03"), "long")
#> [1] "3 November 2026"
phw_date(as.Date("2026-11-03"), "%b %Y")
#> [1] "Nov 2026"
phw_date(as.Date("03/11/2026", format = "%d/%m/%Y"))
#> [1] "03/11/2026"
```
