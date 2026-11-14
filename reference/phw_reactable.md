# Make a PHW-styled reactable

Calls
[`reactable::reactable()`](https://glin.github.io/reactable/reference/reactable.html)
with the PHW theme, striping, compact rows and number formatting with
thousands separators. It also attaches the Ubuntu web font. You can add
a title above and a source line below.

## Usage

``` r
phw_reactable(
  data,
  ...,
  caption = NULL,
  source = NULL,
  date = NULL,
  header = "booktabs",
  accent = phw_colours[["navy"]],
  caption_args = list(),
  digits = 1,
  group_col = NULL,
  key = NULL,
  palette = phw_default_palette()
)
```

## Arguments

- data:

  A data frame, or a summary table from
  [`phw_summary_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_summary_table.md),
  [`phw_crosstab()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_crosstab.md),
  [`phw_rate_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_rate_table.md)
  or
  [`phw_risk_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_risk_table.md)
  (shown with bold headings, indented levels and no sorting or paging).

- ...:

  Passed to
  [`reactable::reactable()`](https://glin.github.io/reactable/reference/reactable.html).
  Any of them, including `theme`, `defaultColDef` and `language`,
  replace the PHW defaults.

- caption:

  Optional title shown above the table.

- source, date:

  Passed to
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  and shown below the table.

- header, accent:

  Passed to
  [`phw_reactable_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_theme.md).

- caption_args:

  List of other
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  arguments.

- digits:

  Decimal places for non-integer numbers, as in
  [`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md)
  and
  [`phw_gt()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_gt_theme.md).
  A column of whole numbers shows none. A column you format yourself in
  `columns` or `...` keeps your format.

- group_col, key, palette:

  Colour the cells of the column `group_col` (unquoted as in dplyr, or a
  string) by group, with the same colours as your charts. `key` and
  `palette` are passed to
  [`phw_colour_key()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_colour_key.md).

## Value

An htmlwidget (or a tag list when a caption or source is given).

## Examples

``` r
if (requireNamespace("reactable", quietly = TRUE)) {
  df <- data.frame(area = paste("Area", LETTERS[1:5]),
                   group = c("Group A", "Group B", "Group A", "Group C", "Group B"),
                   cases = c(1203, 845, 642, 190, 231))
  tbl <- phw_reactable(df, caption = "Cases by area", source = "Example data",
                       searchable = TRUE)

  # Colour the group column with the same colours as your charts
  tbl2 <- phw_reactable(df, group_col = group)

  # A summary table keeps its bold headings and indents
  ll <- data.frame(sex = rep(c("Female", "Male"), 10),
                   outcome = rep(c("Outcome X", "Outcome Y"), each = 10))
  tbl3 <- phw_reactable(phw_summary_table(ll, by = outcome))

  # Printing shows the table in the Viewer or a browser.
  if (interactive()) print(tbl)
}
```
