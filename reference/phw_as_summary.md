# Turn a table you built into a summary table

Marks a data frame as a `phw_summary` so
[`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md),
[`phw_gt()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_gt_theme.md),
[`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md),
[`phw_datatable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_datatable.md)
and
[`phw_write_xlsx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_write_xlsx.md)
give it the same bold variable rows, indented levels and total rows as
the tables phwstyle builds. Use it for a table of your own, made with
dplyr or by hand.

## Usage

``` r
phw_as_summary(data, row_type = NULL, note = NULL)
```

## Arguments

- data:

  A data frame whose first column holds the row labels.

- row_type:

  Optional column saying what each row is, chosen as in
  [`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html).
  Each value is one of `"variable"` (a bold heading), `"level"` (an
  indented row), `"subtotal"`, `"group"` or `"total"`. The column is not
  kept in the result. `NULL` treats every row as a `"level"`.

- note:

  Optional footnote shown under the table.

## Value

A `phw_summary` data frame.

## Examples

``` r
tab <- data.frame(
  label = c("Age group", "0-14", "15-64", "65+", "All ages"),
  cases = c(NA, 12, 48, 30, 90),
  kind = c("variable", "level", "level", "level", "total")
)
tab <- phw_as_summary(tab, row_type = kind, note = "Simulated counts.")
tab
#>      label cases
#>  Age group    NA
#>       0-14    12
#>      15-64    48
#>        65+    30
#>   All ages    90
#> Simulated counts. 
if (requireNamespace("flextable", quietly = TRUE)) phw_flextable(tab)


.cl-d8bad469{}.cl-2083cb38{font-family:'Ubuntu';font-size:10pt;font-weight:bold;font-style:normal;text-decoration:none;color:rgba(40, 80, 135, 1.00);background-color:transparent;}.cl-4acae8cd{font-family:'Ubuntu';font-size:10pt;font-weight:bold;font-style:normal;text-decoration:none;color:rgba(33, 43, 50, 1.00);background-color:transparent;}.cl-cfb12614{font-family:'Ubuntu';font-size:10pt;font-weight:normal;font-style:normal;text-decoration:none;color:rgba(33, 43, 50, 1.00);background-color:transparent;}.cl-a62db28e{font-family:'DejaVu Sans';font-size:8.5pt;font-weight:normal;font-style:italic;text-decoration:none;color:rgba(76, 98, 114, 1.00);background-color:transparent;}.cl-4a2dc108{margin:0;text-align:left;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:5pt;padding-right:5pt;line-height: 1.149;background-color:transparent;}.cl-a124faa2{margin:0;text-align:right;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:5pt;padding-right:5pt;line-height: 1.149;background-color:transparent;}.cl-8581a5c6{margin:0;text-align:left;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:16pt;padding-right:5pt;line-height: 1.149;background-color:transparent;}.cl-0e7c069b{margin:0;text-align:left;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:5pt;padding-top:5pt;padding-left:5pt;padding-right:5pt;line-height: 1.164;background-color:transparent;}.cl-e8c3fc8d{width:0.973in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-8dbfb72e{width:0.75in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-9db429f6{width:0.973in;background-color:rgba(240, 244, 245, 1.00);vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-97dc80e7{width:0.75in;background-color:rgba(240, 244, 245, 1.00);vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-ded103a6{width:0.973in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-52f95773{width:0.75in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-f9d9ba99{width:0.973in;background-color:transparent;vertical-align: middle;border-bottom: 1pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-b3815e18{width:0.75in;background-color:transparent;vertical-align: middle;border-bottom: 1pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-07c1c79f{width:0.973in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-05a88085{width:0.75in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-46316315{width:0.973in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(255, 255, 255, 0.00);border-top: 0 solid rgba(255, 255, 255, 0.00);border-left: 0 solid rgba(255, 255, 255, 0.00);border-right: 0 solid rgba(255, 255, 255, 0.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-eec4dc53{width:0.75in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(255, 255, 255, 0.00);border-top: 0 solid rgba(255, 255, 255, 0.00);border-left: 0 solid rgba(255, 255, 255, 0.00);border-right: 0 solid rgba(255, 255, 255, 0.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}


label
```
