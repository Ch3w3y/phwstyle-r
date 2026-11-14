# PHW theme for reactable

A
[`reactable::reactableTheme()`](https://glin.github.io/reactable/reference/reactableTheme.html)
that uses the PHW font and colours: a navy header rule, light grey
striping and hover, and the yellow keyboard focus outline used on
phw.nhs.wales.

## Usage

``` r
phw_reactable_theme(
  font_size = 14,
  header = c("booktabs", "navy", "light"),
  accent = phw_colours[["navy"]],
  ...
)
```

## Arguments

- font_size:

  Base font size in px.

- header:

  Header style: `"booktabs"` (navy text and rules), `"navy"` (navy band,
  white text) or `"light"` (light teal band).

- accent:

  Colour used for the header, rules and current page button.

- ...:

  Other
  [`reactable::reactableTheme()`](https://glin.github.io/reactable/reference/reactableTheme.html)
  arguments. They override the PHW defaults.

## Value

A reactable theme.

## Examples

``` r
if (requireNamespace("reactable", quietly = TRUE)) {
  tbl <- reactable::reactable(head(mtcars),
                              theme = phw_reactable_theme(header = "navy"))
  if (interactive()) print(tbl)
}
```
