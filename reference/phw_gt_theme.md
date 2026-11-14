# PHW style for gt tables

`phw_gt_theme()` restyles an existing
[`gt::gt()`](https://gt.rstudio.com/reference/gt.html) table: PHW font,
navy title and column labels with a navy rule, light row lines and a
bold source note. `phw_gt()` builds the table from a data frame (or a
[`phw_summary_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_summary_table.md)
and friends) and adds the title, number formats and source line in one
call.

## Usage

``` r
phw_gt_theme(
  x,
  font_size = 14,
  accent = phw_colours[["navy"]],
  stripe = FALSE,
  ...
)

phw_gt(
  data,
  caption = NULL,
  subtitle = NULL,
  number = NULL,
  source = NULL,
  date = NULL,
  digits = 1,
  number_prefix = "Table",
  caption_args = list(),
  gt_args = list(),
  theme_args = list()
)
```

## Arguments

- x:

  A gt table.

- font_size:

  Body font size in pixels.

- accent:

  Colour of the title, column labels and rules.

- stripe:

  Shade alternate rows?

- ...:

  Passed to
  [`gt::tab_options()`](https://gt.rstudio.com/reference/tab_options.html),
  to change any other setting.

- data:

  A data frame, or a summary table from
  [`phw_summary_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_summary_table.md),
  [`phw_crosstab()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_crosstab.md),
  [`phw_rate_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_rate_table.md),
  [`phw_risk_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_risk_table.md)
  or
  [`phw_group_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_group_table.md).
  Summary tables get bold group rows, indented levels and header
  spanners, as in
  [`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md).

- caption:

  Table title.

- subtitle:

  Optional subtitle.

- number:

  Optional table number, giving "Table 1 ...".

- source, date:

  Passed to
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  and shown under the table.

- digits:

  Decimal places for non-integer numbers.

- number_prefix:

  Word before the number.

- caption_args:

  List of other
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  arguments.

- gt_args:

  List of arguments for
  [`gt::gt()`](https://gt.rstudio.com/reference/gt.html), e.g.
  `list(groupname_col = "region")`.

- theme_args:

  List of arguments for `phw_gt_theme()`.

## Value

A gt table.

## Examples

``` r
if (requireNamespace("gt", quietly = TRUE)) {
  phw_gt(head(mtcars[, 1:4]), caption = "Example table", source = "mtcars")
  phw_gt_theme(gt::gt(head(iris)))
}


  

Sepal.Length
```
