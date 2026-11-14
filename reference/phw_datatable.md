# Interactive tables with DT

Builds a [`DT::datatable()`](https://rdrr.io/pkg/DT/man/datatable.html)
in the PHW style: PHW font, navy header, light row lines, thousands
separators, and a title and source line. Useful in Shiny apps and HTML
reports when readers need to search, sort or page through a long table.
A summary table (see
[`phw_summary_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_summary_table.md)
and
[`phw_as_summary()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_as_summary.md))
keeps its bold variable and total rows and indented levels, and is shown
whole, without sorting or paging.

## Usage

``` r
phw_datatable(
  data,
  caption = NULL,
  source = NULL,
  date = NULL,
  digits = 1,
  page_length = 10,
  options = list(),
  caption_args = list(),
  ...
)
```

## Arguments

- data:

  A data frame, or a `phw_summary` table.

- caption:

  Title shown above the table.

- source, date:

  Passed to
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  and shown under the table.

- digits:

  Decimal places for non-integer numbers.

- page_length:

  Rows per page.

- options:

  List of DataTables options, merged with the defaults.

- caption_args:

  List of other
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  arguments.

- ...:

  Passed to
  [`DT::datatable()`](https://rdrr.io/pkg/DT/man/datatable.html), e.g.
  `filter = "top"`.

## Value

A DT htmlwidget (wrapped with the title and source when given).

## Examples

``` r
if (requireNamespace("DT", quietly = TRUE)) {
  tbl <- phw_datatable(mtcars, caption = "Example table", source = "mtcars")
  # Printing shows the table in the Viewer or a browser.
  if (interactive()) print(tbl)
}
```
