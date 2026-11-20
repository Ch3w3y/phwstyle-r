# Colour flextable cells by group

Colours cells by the group they contain, using the same colours as your
charts. With a `key`, each group keeps its colour across tables, charts
and reports (see
[`phw_colour_key()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_colour_key.md)).

## Usage

``` r
phw_flextable_groups(
  x,
  j,
  key = NULL,
  palette = phw_default_palette(),
  values = NULL,
  what = c("background", "text"),
  rows = FALSE
)
```

## Arguments

- x:

  A flextable.

- j:

  Column that holds the groups, unquoted as in dplyr. A string or a
  position works too.

- key, palette, values:

  Passed to
  [`phw_colour_key()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_colour_key.md)
  as `name`, `palette` and `fixed`.

- what:

  Colour the cell `"background"` or the `"text"`?

- rows:

  Colour the whole row (`TRUE`) or only column `j`?

## Value

A flextable. Rows with a missing (`NA`) group are left uncoloured.

## Details

On a summary table from
[`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md),
only the level rows are coloured. Headings, subtotals and totals keep
their own styling and are not added to the key.

## Examples

``` r
if (requireNamespace("flextable", quietly = TRUE)) {
  df <- data.frame(Group = c("Group A", "Group B", "Group C", "Unknown"),
                   Cases = c(120, 85, 64, 9))
  phw_flextable(df) |>
    phw_flextable_groups(Group)

  # Colour the text instead, across the whole row
  phw_flextable(df) |>
    phw_flextable_groups(Group, what = "text", rows = TRUE)
}


.cl-d8bad469{}.cl-2083cb38{font-family:'Ubuntu';font-size:10pt;font-weight:bold;font-style:normal;text-decoration:none;color:rgba(40, 80, 135, 1.00);background-color:transparent;}.cl-f495acb4{font-family:'Ubuntu';font-size:10pt;font-weight:normal;font-style:normal;text-decoration:none;color:rgba(40, 80, 135, 1.00);background-color:transparent;}.cl-387c564a{font-family:'Ubuntu';font-size:10pt;font-weight:normal;font-style:normal;text-decoration:none;color:rgba(36, 162, 181, 1.00);background-color:transparent;}.cl-497a2270{font-family:'Ubuntu';font-size:10pt;font-weight:normal;font-style:normal;text-decoration:none;color:rgba(255, 93, 12, 1.00);background-color:transparent;}.cl-36582957{font-family:'Ubuntu';font-size:10pt;font-weight:normal;font-style:normal;text-decoration:none;color:rgba(118, 134, 146, 1.00);background-color:transparent;}.cl-4a2dc108{margin:0;text-align:left;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:5pt;padding-right:5pt;line-height: 1.149;background-color:transparent;}.cl-a124faa2{margin:0;text-align:right;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:5pt;padding-right:5pt;line-height: 1.149;background-color:transparent;}.cl-699d55ec{width:0.882in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-e926708c{width:0.668in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-27896185{width:0.882in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-ac5c6fd4{width:0.668in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-f67c32bf{width:0.882in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-5268f966{width:0.668in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}


Group
```
