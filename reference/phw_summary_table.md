# Summary table of characteristics by group

The "Table 1" of a report: counts and percentages for categorical
variables (age group, sex, risk factors...) and a median (IQR) or mean
(SD) for numeric ones, optionally split by a grouping variable with a
total column. Render it with
[`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md)
or
[`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md):
variable names become bold headings with their levels indented, and the
grouping variable becomes a header spanning its columns.

## Usage

``` r
phw_summary_table(
  data,
  vars = NULL,
  by = NULL,
  labels = list(),
  percent = c("column", "row", "none"),
  numeric = c("median_iqr", "mean_sd"),
  total = TRUE,
  missing = "Unknown",
  digits = 1,
  n_in_header = TRUE,
  label_header = "Characteristic"
)
```

## Arguments

- data:

  A data frame with one row per person (or case, episode...).

- vars:

  Columns to summarise, chosen as in
  [`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html),
  e.g. `c(age_group, sex)` or `starts_with("sym")`. Defaults to every
  column except `by`.

- by:

  Optional column to split by (e.g. outcome or year), unquoted as in
  dplyr. A string works too.

- labels:

  Named list of display names, e.g. `list(age_group = "Age group")`.
  Variable `label` attributes are used otherwise.

- percent:

  For categorical variables, percentages of each `"column"` (the
  default), of each `"row"`, or `"none"`.

- numeric:

  How to summarise numeric variables: `"median_iqr"` or `"mean_sd"`.

- total:

  Add a total column when `by` is given?

- missing:

  Label for missing values, or `NULL` to leave them out.

- digits:

  Decimal places for percentages and statistics.

- n_in_header:

  Show "(n = ...)" under each column heading?

- label_header:

  Heading of the first column.

## Value

A `phw_summary` data frame.

## Examples

``` r
df <- data.frame(
  age_group = sample(c("0-14", "15-44", "45-64", "65+"), 200, TRUE),
  sex = sample(c("Female", "Male", NA), 200, TRUE, prob = c(.49, .49, .02)),
  days = rpois(200, 6),
  group = sample(c("Group A", "Group B"), 200, TRUE)
)
tab <- phw_summary_table(df, by = group,
                         labels = list(age_group = "Age group", sex = "Sex",
                                       days = "Days"))
tab
#>  Characteristic Group A (n = 103) Group B (n = 97)  Total (n = 200)
#>       Age group                                                    
#>            0-14        26 (25.2%)       29 (29.9%)       55 (27.5%)
#>           15-44        26 (25.2%)       29 (29.9%)       55 (27.5%)
#>           45-64        25 (24.3%)       12 (12.4%)       37 (18.5%)
#>             65+        26 (25.2%)       27 (27.8%)       53 (26.5%)
#>             Sex                                                    
#>          Female        49 (47.6%)       51 (52.6%)      100 (50.0%)
#>            Male        49 (47.6%)       42 (43.3%)       91 (45.5%)
#>         Unknown          5 (4.9%)         4 (4.1%)         9 (4.5%)
#>            Days  6.0 (4.0 to 8.0) 6.0 (5.0 to 8.0) 6.0 (4.0 to 8.0)
#> n (%); median (IQR) 
if (requireNamespace("flextable", quietly = TRUE)) phw_flextable(tab)


.cl-d8bad469{}.cl-2083cb38{font-family:'Ubuntu';font-size:10pt;font-weight:bold;font-style:normal;text-decoration:none;color:rgba(40, 80, 135, 1.00);background-color:transparent;}.cl-4acae8cd{font-family:'Ubuntu';font-size:10pt;font-weight:bold;font-style:normal;text-decoration:none;color:rgba(33, 43, 50, 1.00);background-color:transparent;}.cl-cfb12614{font-family:'Ubuntu';font-size:10pt;font-weight:normal;font-style:normal;text-decoration:none;color:rgba(33, 43, 50, 1.00);background-color:transparent;}.cl-a62db28e{font-family:'DejaVu Sans';font-size:8.5pt;font-weight:normal;font-style:italic;text-decoration:none;color:rgba(76, 98, 114, 1.00);background-color:transparent;}.cl-56907d49{margin:0;text-align:left;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:5pt;padding-right:5pt;line-height: 1;background-color:transparent;}.cl-6a6ee646{margin:0;text-align:center;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:5pt;padding-right:5pt;line-height: 1;background-color:transparent;}.cl-f3e8aa49{margin:0;text-align:right;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:5pt;padding-right:5pt;line-height: 1;background-color:transparent;}.cl-d77387b5{margin:0;text-align:left;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:16pt;padding-right:5pt;line-height: 1;background-color:transparent;}.cl-6477613b{margin:0;text-align:left;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:5pt;padding-top:5pt;padding-left:5pt;padding-right:5pt;line-height: 1;background-color:transparent;}.cl-065f1923{width:1.219in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-c123227d{width:1.421in;background-color:transparent;vertical-align: middle;border-bottom: 0.75pt solid rgba(118, 134, 146, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-4ebd5118{width:1.335in;background-color:transparent;vertical-align: middle;border-bottom: 0.75pt solid rgba(118, 134, 146, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-bc434610{width:1.233in;background-color:transparent;vertical-align: middle;border-bottom: 0.75pt solid rgba(118, 134, 146, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-fdae5106{width:1.421in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0.75pt solid rgba(118, 134, 146, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-0cd462fb{width:1.335in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0.75pt solid rgba(118, 134, 146, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-56c30a23{width:1.233in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0.75pt solid rgba(118, 134, 146, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-541dd881{width:1.219in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-24e97569{width:1.421in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-3f6c5bee{width:1.335in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-f8cc3908{width:1.233in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-fc5e4e78{width:1.219in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-3966f3f3{width:1.421in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-23643f6d{width:1.335in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-3a779bcf{width:1.233in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-edaec62f{width:1.219in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(255, 255, 255, 0.00);border-top: 0 solid rgba(255, 255, 255, 0.00);border-left: 0 solid rgba(255, 255, 255, 0.00);border-right: 0 solid rgba(255, 255, 255, 0.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-5cffe9a7{width:1.421in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(255, 255, 255, 0.00);border-top: 0 solid rgba(255, 255, 255, 0.00);border-left: 0 solid rgba(255, 255, 255, 0.00);border-right: 0 solid rgba(255, 255, 255, 0.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-ed39cd0b{width:1.335in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(255, 255, 255, 0.00);border-top: 0 solid rgba(255, 255, 255, 0.00);border-left: 0 solid rgba(255, 255, 255, 0.00);border-right: 0 solid rgba(255, 255, 255, 0.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-01d0458d{width:1.233in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(255, 255, 255, 0.00);border-top: 0 solid rgba(255, 255, 255, 0.00);border-left: 0 solid rgba(255, 255, 255, 0.00);border-right: 0 solid rgba(255, 255, 255, 0.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}


```
