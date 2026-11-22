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
  continued = "(continued)",
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

  Table title, e.g. `"Counts by health board, 2020-2024"`. In a Quarto
  chunk that sets the `tbl-cap` option, Quarto's caption is shown
  instead.

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

  Decimal places for non-integer numbers. Defaults to the `digits` of a
  [`phw_group_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_group_table.md),
  or 1. Whole numbers show with a thousands separator, except in a year
  column: whole numbers from 1800 to 2200 in a column whose name has the
  word "year", "yr" or "blwyddyn" in it, such as `Year`, `year_of_onset`
  or `Blwyddyn`. These show as 2021, not 2,021.

- col_labels:

  Optional named list of display names, as in
  [`flextable::set_header_labels()`](https://davidgohel.github.io/flextable/reference/set_header_labels.html).

- autofit:

  Fit column widths to their content? In a Word or PDF document, a table
  wider than the page is narrowed to fit the text width either way: its
  headings wrap first, then its cells, and its text shrinks to no less
  than 8 pt if the words alone are still too wide.

  In a PowerPoint deck made with R Markdown or Quarto, or with
  [`phw_add_slide()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pptx.md),
  text is never smaller than 12 pt, so the table can be read when
  projected: smaller text, such as the 10 pt default, is shown at 12 pt.
  A table with room to spare grows to fill the slide's content area,
  with its text up to 18 pt (see the `table_fit` argument of
  [`phw_add_slide()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pptx.md)).
  A table wider than the slide's content area wraps its headings, then
  its cells. A table too long for the slide tightens its row spacing,
  and if it still does not fit, its rows continue on further slides.
  Each slide repeats the header row, the caption is marked with
  `continued` after the first slide, and the source goes on the last
  slide. A table too wide to fit even with its text wrapped gives a
  warning. A table starts below room for two lines of text above it,
  such as a key message or two bullets; set the chunk option `ft.top`,
  in inches from the top of the slide, to place it yourself. Tables on
  the slides of a Quarto `phw-revealjs` deck are sized and split in the
  same way, with the same room above them.

- number_prefix:

  Word before the number.

- caption_args:

  List of other
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  arguments, e.g. `list(note = "Provisional")`.

- flextable_args:

  List of arguments for
  [`flextable::flextable()`](https://davidgohel.github.io/flextable/reference/flextable.html),
  e.g. `list(col_keys = c("area", "rate"))`. For a summary table,
  `col_keys` must start with its label columns.

- continued:

  Text added after the caption on the slides a long table continues on,
  in a PowerPoint deck. Give your own wording, for example in Welsh.

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


.cl-d8bad469{}.cl-2083cb38{font-family:'Ubuntu';font-size:10pt;font-weight:bold;font-style:normal;text-decoration:none;color:rgba(40, 80, 135, 1.00);background-color:transparent;}.cl-cfb12614{font-family:'Ubuntu';font-size:10pt;font-weight:normal;font-style:normal;text-decoration:none;color:rgba(33, 43, 50, 1.00);background-color:transparent;}.cl-3df57ff2{font-family:'Ubuntu';font-size:8.5pt;font-weight:bold;font-style:normal;text-decoration:none;color:rgba(33, 43, 50, 1.00);background-color:transparent;}.cl-4a2dc108{margin:0;text-align:left;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:5pt;padding-right:5pt;line-height: 1.149;background-color:transparent;}.cl-a124faa2{margin:0;text-align:right;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:5pt;padding-right:5pt;line-height: 1.149;background-color:transparent;}.cl-fcf8c496{margin:0;text-align:right;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:5pt;padding-top:5pt;padding-left:5pt;padding-right:5pt;line-height: 1.149;background-color:transparent;}.cl-691443da{width:1.483in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-8dbfb72e{width:0.75in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-441ff722{width:1.483in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-52f95773{width:0.75in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-0065567e{width:1.483in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-8d809b44{width:0.75in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-d6f9e881{width:1.483in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(255, 255, 255, 0.00);border-top: 0 solid rgba(255, 255, 255, 0.00);border-left: 0 solid rgba(255, 255, 255, 0.00);border-right: 0 solid rgba(255, 255, 255, 0.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-05612544{width:0.75in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(255, 255, 255, 0.00);border-top: 0 solid rgba(255, 255, 255, 0.00);border-left: 0 solid rgba(255, 255, 255, 0.00);border-right: 0 solid rgba(255, 255, 255, 0.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-dc1c8a78{font-family:'Ubuntu';font-size:11pt;font-weight:bold;font-style:normal;text-decoration:none;color:rgba(40, 80, 135, 1.00);background-color:transparent;}

Example

 
```
