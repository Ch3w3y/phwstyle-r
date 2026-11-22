# Make a PHW-styled reactable

Calls
[`reactable::reactable()`](https://glin.github.io/reactable/reference/reactable.html)
with the PHW theme, compact rows and number formatting with thousands
separators. Rows are not striped, as in the other PHW tables; pass
`striped = TRUE` to stripe them. It also attaches the Ubuntu web font.
You can add a title above and a source line below.

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
  replace the PHW defaults. For a summary table, `columns` change only
  the settings you give, so the table keeps its indents, alignment and
  headings.

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
  A column of whole numbers shows none. Whole numbers show with a
  thousands separator, except in a year column: whole numbers from 1800
  to 2200 in a column whose name has the word "year", "yr" or "blwyddyn"
  in it, such as `Year`, `year_of_onset` or `Blwyddyn`. These show as
  2021, not 2,021. A column you format yourself in `columns` keeps your
  format, and a `format` in `defaultColDef` applies to every column.

- group_col, key, palette:

  Colour the cells of the column `group_col` (unquoted as in dplyr, or a
  string) by group, with the same colours as your charts. `key` and
  `palette` are passed to
  [`phw_colour_key()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_colour_key.md).
  On a summary table, only the level rows are coloured: headings,
  subtotals and totals are left as they are and are not added to the
  key.

## Value

An htmlwidget. When a caption, a source line or a summary table's note
is shown, the widget is wrapped in an htmltools tag list with them. In
Shiny, show a tag list with `renderUI()` and `uiOutput()`, not
[`reactable::renderReactable()`](https://glin.github.io/reactable/reference/reactable-shiny.html).

## Details

On the slides of a Quarto `phw-revealjs` deck, the text is sized to the
slide for one page of rows: never smaller than 12 pt at the slide's
scale, and up to 18 pt when the table has room, which leaves room above
it for two lines of text. The title and source line are in proportion to
it. A `theme` you pass keeps its own sizes.

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
