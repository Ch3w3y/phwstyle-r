# Add in-cell bars to a flextable

Draws a small horizontal bar before each value, scaled to the largest
value in the column, so readers can compare sizes at a glance (as in
many PHW summary tables).

## Usage

``` r
phw_flextable_bars(
  x,
  j,
  colour = phw_colours[["light_teal"]],
  width = 0.9,
  height = 0.1,
  digits = 0
)
```

## Arguments

- x:

  A flextable.

- j:

  Columns, chosen from the columns the table shows as in
  [`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html):
  unquoted names, positions or strings.

- colour:

  Bar colour.

- width, height:

  Bar size in inches.

- digits:

  Decimal places for the value.

## Value

A flextable.

## Details

On a summary table from
[`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md),
only the level rows get bars. Headings, subtotals and totals show the
number only and do not count towards the scale, so a total does not
shrink every other bar.

The bars are small pictures. They show in HTML and PDF reports, and in
Word reports made with
[`phw_word_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md).
Other Word formats, the Quarto `phw-docx` format included, cannot hold
pictures in a table, so a table with bars stops there with a message.
PowerPoint tables cannot show pictures either, so
[`phw_add_slide()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pptx.md)
and a slide deck stop with a message for a table with bars.

## Examples

``` r
if (requireNamespace("flextable", quietly = TRUE)) {
  df <- data.frame(Area = paste("Area", LETTERS[1:4]), Cases = c(120, 85, 64, 19))
  phw_flextable_bars(phw_flextable(df), Cases)
}


.cl-d8bad469{}.cl-2083cb38{font-family:'Ubuntu';font-size:10pt;font-weight:bold;font-style:normal;text-decoration:none;color:rgba(40, 80, 135, 1.00);background-color:transparent;}.cl-cfb12614{font-family:'Ubuntu';font-size:10pt;font-weight:normal;font-style:normal;text-decoration:none;color:rgba(33, 43, 50, 1.00);background-color:transparent;}.cl-4a2dc108{margin:0;text-align:left;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:5pt;padding-right:5pt;line-height: 1.149;background-color:transparent;}.cl-da1de7c7{width:0.712in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-7e131143{width:1.458in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-e6365039{width:0.712in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-79379543{width:1.458in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-f81f35df{width:0.712in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-4962efc8{width:1.458in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}


Area
```
