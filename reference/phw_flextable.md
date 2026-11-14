# Make a PHW-styled flextable from a data frame

One call that builds a flextable, formats numbers with thousands
separators, applies
[`phw_flextable_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_theme.md)
and adds the PHW caption and source line. The caption ("Table 1 ...")
goes above and the bold source goes below, right-aligned.

## Usage

``` r
phw_flextable(
  data,
  caption = NULL,
  number = NULL,
  source = NULL,
  date = NULL,
  style = "booktabs",
  digits = 1,
  col_labels = NULL,
  autofit = TRUE,
  number_prefix = "Table",
  caption_args = list(),
  flextable_args = list(),
  ...
)
```

## Arguments

- data:

  A data frame, or a summary table from
  [`phw_summary_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_summary_table.md),
  [`phw_crosstab()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_crosstab.md),
  [`phw_rate_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_rate_table.md)
  or
  [`phw_risk_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_risk_table.md).
  Summary tables get bold variable headings, indented levels, a header
  spanning the group columns and a note on the statistics shown.

- caption:

  Table title, e.g. `"Counts by health board, 2020-2024"`.

- number:

  Optional table number. Gives "Table 1 ...".

- source, date:

  Passed to
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  and shown under the table.

- style:

  Passed to
  [`phw_flextable_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_theme.md).

- digits:

  Decimal places for non-integer numbers.

- col_labels:

  Optional named list of display names, as in
  [`flextable::set_header_labels()`](https://davidgohel.github.io/flextable/reference/set_header_labels.html).

- autofit:

  Fit column widths to their content?

- number_prefix:

  Word before the number.

- caption_args:

  List of other
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  arguments, e.g. `list(note = "Provisional")`.

- flextable_args:

  List of arguments for
  [`flextable::flextable()`](https://davidgohel.github.io/flextable/reference/flextable.html),
  e.g. `list(col_keys = c("area", "rate"))`.

- ...:

  Passed to
  [`phw_flextable_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_theme.md).

## Value

A flextable.

## Examples

``` r
if (requireNamespace("flextable", quietly = TRUE)) {
  phw_flextable(head(mtcars[, 1:4]), caption = "Example", source = "mtcars")
}


.cl-d8bad469{}.cl-2083cb38{font-family:'Ubuntu';font-size:10pt;font-weight:bold;font-style:normal;text-decoration:none;color:rgba(40, 80, 135, 1.00);background-color:transparent;}.cl-cfb12614{font-family:'Ubuntu';font-size:10pt;font-weight:normal;font-style:normal;text-decoration:none;color:rgba(33, 43, 50, 1.00);background-color:transparent;}.cl-3df57ff2{font-family:'Ubuntu';font-size:8.5pt;font-weight:bold;font-style:normal;text-decoration:none;color:rgba(33, 43, 50, 1.00);background-color:transparent;}.cl-f3e8aa49{margin:0;text-align:right;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:5pt;padding-right:5pt;line-height: 1;background-color:transparent;}.cl-a1958ec5{margin:0;text-align:right;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:5pt;padding-top:5pt;padding-left:5pt;padding-right:5pt;line-height: 1;background-color:transparent;}.cl-8e9e6e73{width:0.75in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-bde9186f{width:0.75in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-677ca460{width:0.75in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-05612544{width:0.75in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(255, 255, 255, 0.00);border-top: 0 solid rgba(255, 255, 255, 0.00);border-left: 0 solid rgba(255, 255, 255, 0.00);border-right: 0 solid rgba(255, 255, 255, 0.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-dc1c8a78{font-family:'Ubuntu';font-size:11pt;font-weight:bold;font-style:normal;text-decoration:none;color:rgba(40, 80, 135, 1.00);background-color:transparent;}

Example

mpg
```
