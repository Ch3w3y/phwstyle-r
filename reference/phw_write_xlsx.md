# Write tables to a styled Excel workbook

Writes one or more data frames to an `.xlsx` file in the PHW style, one
sheet each: a title row, a navy header, thousands separators, ISO dates,
sensible column widths, frozen header row and a bold source line under
the table. Summary tables from
[`phw_summary_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_summary_table.md),
[`phw_group_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_group_table.md)
and friends look as they do in the other renderers: the header spanning
the group columns, shaded variable rows with navy labels, indented
levels, italic subtotals and a navy rule above the total.

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
  names become the sheet names). Characters Excel does not allow in a
  sheet name become spaces and names are cut to 31 characters. The names
  must still differ after that, ignoring case.

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

  Decimal places for non-integer numbers. Defaults to the `digits` of a
  [`phw_group_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_group_table.md),
  or 1. Whole numbers show with a thousands separator, except in a year
  column: whole numbers from 1800 to 2200 in a column whose name has the
  word "year", "yr" or "blwyddyn" in it, such as `Year`, `year_of_onset`
  or `Blwyddyn`. These show as 2021, not 2,021.

- header_fill:

  Header fill colour: a colour, or a name from
  [phw_colours](https://ch3w3y.github.io/phwstyle-r/reference/phw_colours.md)
  such as `"navy"`.

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
