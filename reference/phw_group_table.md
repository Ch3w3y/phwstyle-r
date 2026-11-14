# Grouped table with nested row and column groups

Turns a raw data frame (one row per record, or with a value column) into
a table with a hierarchy of row groups and, optionally, of column
groups. For example, counts by group (A, B, C) and then by type within
each group (1, 2, 3), split into columns by year. Each group row can
carry the total for its group, and you can add a total for the whole
table and totals of the innermost groups across all groups. Render it
with
[`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md)
or
[`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md):
main groups are highlighted and separated with space or a rule, and the
groups inside them are indented, or shifted into their own column with
`layout = "columns"`.

## Usage

``` r
phw_group_table(
  data,
  rows,
  cols = NULL,
  value = NULL,
  fun = sum,
  totals = c("group", "table"),
  total_position = c("bottom", "top"),
  subtotal_position = c("header", "below"),
  col_totals = "table",
  percent = c("none", "parent", "column", "row"),
  layout = c("indent", "columns"),
  separate = c("space", "line", "both", "none"),
  highlight = TRUE,
  labels = list(),
  value_label = NULL,
  label_header = NULL,
  total_label = "Total",
  subtotal_label = "{group} total",
  missing = "Unknown",
  drop = TRUE,
  digits = 1
)
```

## Arguments

- data:

  A data frame.

- rows:

  Row grouping columns, outermost first, chosen as in
  [`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html),
  e.g. `c(group, type)`. Any number of levels. Strings work too.

- cols:

  Optional column grouping columns, outermost first, e.g. `year` or
  `c(year, quarter)`. Outer levels become headers spanning their
  columns.

- value:

  Optional numeric column to summarise. Without it, rows are counted.

- fun:

  Function applied to `value` within each cell. Defaults to `sum` (so
  `value` can hold counts of aggregated data). Use e.g.
  `function(x) median(x, na.rm = TRUE)` for other statistics; group and
  total rows are then computed from the records in the group, not by
  adding up the rows below.

- totals:

  Which row totals to show. Any of:

  - `"group"`: each group row shows the total for its group (e.g. Group
    A shows the total for all of group A), at every level that has
    groups inside.

  - `"subgroup"`: a block with each innermost category summed across all
    groups (e.g. all Type 1, all Type 2, all Type 3).

  - `"table"`: one total row for the whole table.

  Use [`character()`](https://rdrr.io/r/base/character.html) or `"none"`
  for no totals.

- total_position:

  Put the table total and the subgroup block at the `"bottom"` or the
  `"top"` of the table.

- subtotal_position:

  Show group totals on the group's own heading row (`"header"`), or
  leave the heading blank and add a total row after the group
  (`"below"`).

- col_totals:

  Which column totals to show when `cols` is given: any of `"table"`
  (one total column) and `"group"` (a total column for each outermost
  column group, when `cols` has two or more levels).

- percent:

  Add percentages to the counts: `"parent"` (share of the group above,
  e.g. Type 1 as a share of all of Group A), `"column"` (share of the
  column total), `"row"` (share of the row total) or `"none"`. Only for
  counts and sums.

- layout:

  `"indent"` puts all row labels in one column, indented by level.
  `"columns"` gives each level its own column, so each group's label
  sits in its own column and the groups inside it are shifted to the
  right.

- separate:

  How to separate the outermost groups: `"space"`, `"line"`, `"both"` or
  `"none"`.

- highlight:

  Shade the outermost group rows?

- labels:

  Named list of display names for the grouping columns.

- value_label:

  Heading for the value column when there is no `cols`.

- label_header:

  Heading of the label column in the `"indent"` layout. Defaults to the
  row variable labels joined with " / ".

- total_label:

  Label for total rows and columns.

- subtotal_label:

  Label for group totals below the group, with `{group}` replaced by the
  group name.

- missing:

  Label for missing grouping values, or `NULL` to drop them.

- drop:

  Leave out categories that have no records in a group?

- digits:

  Decimal places for percentages and non-integer values.

## Value

A `phw_summary` data frame. Without `percent`, value columns are numeric
(blank group rows are `NA`).

## Examples

``` r
set.seed(1)
dat <- data.frame(
  group = sample(c("Group A", "Group B", "Group C"), 300, TRUE),
  type = sample(c("Type 1", "Type 2", "Type 3"), 300, TRUE, prob = c(.45, .45, .1)),
  year = sample(2023:2024, 300, TRUE)
)
phw_group_table(dat, rows = c(group, type), cols = year,
                labels = list(group = "Group", type = "Type", year = "Year"))
#>  Group / Type 2023 2024 Total
#>       Group A   46   61   107
#>        Type 1   23   28    51
#>        Type 2   12   31    43
#>        Type 3   11    2    13
#>       Group B   48   53   101
#>        Type 1   16   23    39
#>        Type 2   23   25    48
#>        Type 3    9    5    14
#>       Group C   51   41    92
#>        Type 1   25   20    45
#>        Type 2   22   16    38
#>        Type 3    4    5     9
#>         Total  145  155   300

# Group totals in their own row, and totals by type across all groups
phw_group_table(dat, c(group, type), totals = c("group", "subgroup", "table"),
                subtotal_position = "below", layout = "columns")
#>          group   type   n
#>        Group A         NA
#>                Type 1  51
#>                Type 2  43
#>                Type 3  13
#>  Group A total        107
#>        Group B         NA
#>                Type 1  39
#>                Type 2  48
#>                Type 3  14
#>  Group B total        101
#>        Group C         NA
#>                Type 1  45
#>                Type 2  38
#>                Type 3   9
#>  Group C total         92
#>  Total by type         NA
#>                Type 1 135
#>                Type 2 129
#>                Type 3  36
#>          Total        300

if (requireNamespace("flextable", quietly = TRUE)) {
  phw_flextable(phw_group_table(dat, c(group, type), year, percent = "parent"))
}


.cl-d8bad469{}.cl-2083cb38{font-family:'Ubuntu';font-size:10pt;font-weight:bold;font-style:normal;text-decoration:none;color:rgba(40, 80, 135, 1.00);background-color:transparent;}.cl-4acae8cd{font-family:'Ubuntu';font-size:10pt;font-weight:bold;font-style:normal;text-decoration:none;color:rgba(33, 43, 50, 1.00);background-color:transparent;}.cl-cfb12614{font-family:'Ubuntu';font-size:10pt;font-weight:normal;font-style:normal;text-decoration:none;color:rgba(33, 43, 50, 1.00);background-color:transparent;}.cl-a62db28e{font-family:'DejaVu Sans';font-size:8.5pt;font-weight:normal;font-style:italic;text-decoration:none;color:rgba(76, 98, 114, 1.00);background-color:transparent;}.cl-56907d49{margin:0;text-align:left;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:5pt;padding-right:5pt;line-height: 1;background-color:transparent;}.cl-6a6ee646{margin:0;text-align:center;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:5pt;padding-right:5pt;line-height: 1;background-color:transparent;}.cl-f3e8aa49{margin:0;text-align:right;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:5pt;padding-right:5pt;line-height: 1;background-color:transparent;}.cl-d77387b5{margin:0;text-align:left;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:16pt;padding-right:5pt;line-height: 1;background-color:transparent;}.cl-3edc390e{margin:0;text-align:left;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:10pt;padding-left:5pt;padding-right:5pt;line-height: 1;background-color:transparent;}.cl-70d0fdf8{margin:0;text-align:right;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:10pt;padding-left:5pt;padding-right:5pt;line-height: 1;background-color:transparent;}.cl-6477613b{margin:0;text-align:left;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:5pt;padding-top:5pt;padding-left:5pt;padding-right:5pt;line-height: 1;background-color:transparent;}.cl-69bbbd2d{width:1.106in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-4ac12467{width:1.131in;background-color:transparent;vertical-align: middle;border-bottom: 0.75pt solid rgba(118, 134, 146, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-9252ac6b{width:1.131in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0.75pt solid rgba(118, 134, 146, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-a8b266c2{width:1.106in;background-color:rgba(240, 244, 245, 1.00);vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-a89b2273{width:1.131in;background-color:rgba(240, 244, 245, 1.00);vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-a884f210{width:1.106in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-bba919c4{width:1.131in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-4080c369{width:1.106in;background-color:rgba(240, 244, 245, 1.00);vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-9dabd444{width:1.131in;background-color:rgba(240, 244, 245, 1.00);vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-4513b214{width:1.106in;background-color:transparent;vertical-align: middle;border-bottom: 1pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-3602d2ba{width:1.131in;background-color:transparent;vertical-align: middle;border-bottom: 1pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-eef13de7{width:1.106in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-7f93e10c{width:1.131in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-ca31517b{width:1.106in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(255, 255, 255, 0.00);border-top: 0 solid rgba(255, 255, 255, 0.00);border-left: 0 solid rgba(255, 255, 255, 0.00);border-right: 0 solid rgba(255, 255, 255, 0.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-91b2510a{width:1.131in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(255, 255, 255, 0.00);border-top: 0 solid rgba(255, 255, 255, 0.00);border-left: 0 solid rgba(255, 255, 255, 0.00);border-right: 0 solid rgba(255, 255, 255, 0.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}


```
