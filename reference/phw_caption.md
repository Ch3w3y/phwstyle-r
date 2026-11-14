# Build a PHW source caption

PHW reports put a bold, right-aligned line under each chart and table,
such as "Source: Example system, 2024". Surveillance reports add "Data
correct as of dd/mm/yyyy". Use the result in `labs(caption = ...)` or
pass the same arguments to
[`phw_finalise()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_finalise.md),
[`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md),
[`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md)
or
[`phw_plotly()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_plotly.md).

## Usage

``` r
phw_caption(
  source = NULL,
  date = NULL,
  source_prefix = "Source: ",
  date_prefix = "Data correct as of ",
  date_format = "short",
  note = NULL,
  sep = "\n"
)
```

## Arguments

- source:

  Data source, e.g. `"Example system, 2024"`. Can be `NULL`.

- date:

  Optional extraction date. Adds "Data correct as of ...". A Date is
  formatted with `date_format`; a string is used as it is.

- source_prefix, date_prefix:

  Text before the source and the date.

- date_format:

  Passed to
  [`phw_date()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_date.md)
  as `style`.

- note:

  Optional extra lines, e.g. a footnote or a team name.

- sep:

  How the lines are joined. Use `" | "` for a single line.

## Value

A string, or `NULL` if there is nothing to show.

## Details

Every piece of wording can be changed, so the line can say anything your
output needs, in any language.

## Examples

``` r
phw_caption("Example system, 2024")
#> [1] "Source: Example system, 2024"
phw_caption("Sentinel GP network", date = as.Date("2026-11-03"))
#> [1] "Source: Sentinel GP network\nData correct as of 03/11/2026"
phw_caption("Example system", source_prefix = "Data: ", note = "Provisional figures")
#> [1] "Data: Example system\nProvisional figures"
```
