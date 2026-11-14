# Write tables to a styled Excel workbook

Writes one or more data frames to an `.xlsx` file in the PHW style, one
sheet each: a title row, a navy header, thousands separators, sensible
column widths, frozen header row and a source note under the table.
Summary tables from
[`phw_summary_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_summary_table.md),
[`phw_group_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_group_table.md)
and friends keep their bold group rows and indented levels.

## Usage

``` r
phw_write_xlsx(
  x,
  file,
  title = NULL,
  source = NULL,
  date = NULL,
  caption_args = list(),
  digits = 1,
  header_fill = phw_colours[["navy"]],
  font = "Arial",
  overwrite = TRUE
)
```

## Arguments

- x:

  A data frame, or a named list of data frames (one sheet each; the
  names become the sheet names).

- file:

  Path of the `.xlsx` file.

- title:

  Title for the first row of each sheet: one string, or one per sheet.
  `NULL` for none.

- source, date:

  Passed to
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  and written under each table.

- caption_args:

  List of other
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  arguments.

- digits:

  Decimal places for non-integer numbers.

- header_fill:

  Header fill colour.

- font:

  Font name. Excel uses it if it is installed on the reader's computer,
  so Arial is the safe default.

- overwrite:

  Replace `file` if it exists?

## Value

The path to the file, invisibly.

## Examples

``` r
if (requireNamespace("openxlsx2", quietly = TRUE)) {
  f <- tempfile(fileext = ".xlsx")
  phw_write_xlsx(list(Cars = head(mtcars), Iris = head(iris)), f,
                 title = "Example tables", source = "Example data")
}
```
