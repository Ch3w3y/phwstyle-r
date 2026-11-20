# Tables

This page shows how to build a table, style it and render it for the
output you need. phwstyle’s table builders count, group and total your
records. Each one returns a data frame that remembers its layout, so you
can render the same object in Word, HTML, Excel or a Shiny app. You can
also style a table you built yourself, with dplyr or by hand.

All data on this page is made up.

| Output | Function |
|----|----|
| Word, PDF, PowerPoint | [`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md) |
| HTML, Quarto | [`phw_gt()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_gt_theme.md) |
| Interactive HTML, Shiny | [`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md) and [`phw_datatable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_datatable.md) |
| Excel | [`phw_write_xlsx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_write_xlsx.md) |

``` r

library(phwstyle)
library(dplyr)
set.seed(1)
dat <- tibble(
  group = sample(paste("Group", LETTERS[1:5]), 4000, replace = TRUE, prob = c(0.3, 0.25, 0.2, 0.15, 0.1)),
  type = factor(sample(paste("Type", 1:4), 4000, replace = TRUE, prob = c(0.4, 0.3, 0.2, 0.1)),
                levels = paste("Type", 1:4)),
  year = sample(2024:2025, 4000, replace = TRUE),
  quarter = sample(paste0("Q", 1:4), 4000, replace = TRUE),
  days = rpois(4000, 3)
)
col_labels <- list(group = "Group", type = "Type", year = "Year", quarter = "Quarter")

cases <- tibble(
  age_group = sample(c("0-14", "15-24", "25-44", "45-64", "65-79", "80+"), 3000, replace = TRUE,
                     prob = c(0.06, 0.09, 0.25, 0.28, 0.2, 0.12)),
  sex = sample(c("Female", "Male"), 3000, replace = TRUE),
  setting = sample(paste("Setting", 1:6), 3000, replace = TRUE, prob = c(0.35, 0.2, 0.15, 0.12, 0.1, 0.08)),
  days = rpois(3000, 4),
  outcome = sample(c("Outcome X", "Outcome Y"), 3000, replace = TRUE, prob = c(0.85, 0.15))
)
```

## Summary tables

### Characteristics by group

[`phw_summary_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_summary_table.md)
describes each variable in one table. Categories show a count and a
percentage, and numbers show a median and interquartile range. Give `by`
to split the columns by a group.

``` r

phw_summary_table(cases, by = outcome,
                  labels = list(age_group = "Age group", sex = "Sex", setting = "Setting",
                                days = "Days to recovery")) |>
  phw_flextable(caption = "Characteristics by outcome")
```

|  | outcome |  |  |
|----|----|----|----|
| Characteristic | Outcome X (n = 2,548) | Outcome Y (n = 452) | Total (n = 3,000) |
| Age group |  |  |  |
| 0-14 | 132 (5.2%) | 25 (5.5%) | 157 (5.2%) |
| 15-24 | 233 (9.1%) | 47 (10.4%) | 280 (9.3%) |
| 25-44 | 639 (25.1%) | 106 (23.5%) | 745 (24.8%) |
| 45-64 | 723 (28.4%) | 131 (29.0%) | 854 (28.5%) |
| 65-79 | 512 (20.1%) | 87 (19.2%) | 599 (20.0%) |
| 80+ | 309 (12.1%) | 56 (12.4%) | 365 (12.2%) |
| Sex |  |  |  |
| Female | 1,301 (51.1%) | 210 (46.5%) | 1,511 (50.4%) |
| Male | 1,247 (48.9%) | 242 (53.5%) | 1,489 (49.6%) |
| Setting |  |  |  |
| Setting 1 | 923 (36.2%) | 134 (29.6%) | 1,057 (35.2%) |
| Setting 2 | 515 (20.2%) | 104 (23.0%) | 619 (20.6%) |
| Setting 3 | 378 (14.8%) | 72 (15.9%) | 450 (15.0%) |
| Setting 4 | 302 (11.9%) | 59 (13.1%) | 361 (12.0%) |
| Setting 5 | 234 (9.2%) | 44 (9.7%) | 278 (9.3%) |
| Setting 6 | 196 (7.7%) | 39 (8.6%) | 235 (7.8%) |
| Days to recovery | 4.0 (3.0 to 5.0) | 4.0 (3.0 to 5.0) | 4.0 (3.0 to 5.0) |
| n (%); median (IQR) |  |  |  |

Characteristics by outcome {.table .cl-d8bad469
quarto-disable-processing="true"}

### A table you built yourself

[`phw_as_summary()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_as_summary.md)
styles a table made elsewhere. Every row of a plain data frame looks the
same to a renderer. Mark it as a summary table and the renderers show
bold variable rows, indented levels and a bold total row.

Name the column that says what each row is with `row_type`. Its values
are `"variable"`, `"level"`, `"subtotal"`, `"group"` and `"total"`. The
column is not kept in the result. Add a footnote with `note`.

This example builds a table with dplyr. Each block is a heading row
followed by its levels, and a total row closes the table.

``` r

block <- function(data, var, heading) {
  counts <- data |> count(level = .data[[var]], name = "cases")
  bind_rows(
    tibble(Characteristic = heading, Cases = NA, Percent = NA, kind = "variable"),
    counts |> transmute(Characteristic = level, Cases = cases,
                        Percent = round(100 * cases / sum(cases), 1), kind = "level")
  )
}

mine <- bind_rows(
  block(cases, "age_group", "Age group"),
  block(cases, "sex", "Sex"),
  tibble(Characteristic = "All cases", Cases = nrow(cases), Percent = 100, kind = "total")
) |>
  phw_as_summary(row_type = kind, note = "Example data. Percentages are of all cases.")
```

Printed, the table is still a data frame. The `kind` column has gone,
and the row layout travels with the table.

``` r

mine
#>  Characteristic Cases Percent
#>       Age group    NA      NA
#>            0-14   157     5.2
#>           15-24   280     9.3
#>           25-44   745    24.8
#>           45-64   854    28.5
#>           65-79   599    20.0
#>             80+   365    12.2
#>             Sex    NA      NA
#>          Female  1511    50.4
#>            Male  1489    49.6
#>       All cases  3000   100.0
#> Example data. Percentages are of all cases.
```

The same object works in every renderer.

``` r

phw_flextable(mine, caption = "Cases by age group and sex")
```

| Characteristic                              | Cases | Percent |
|---------------------------------------------|-------|---------|
| Age group                                   |       |         |
| 0-14                                        | 157   | 5.2     |
| 15-24                                       | 280   | 9.3     |
| 25-44                                       | 745   | 24.8    |
| 45-64                                       | 854   | 28.5    |
| 65-79                                       | 599   | 20.0    |
| 80+                                         | 365   | 12.2    |
| Sex                                         |       |         |
| Female                                      | 1,511 | 50.4    |
| Male                                        | 1,489 | 49.6    |
| All cases                                   | 3,000 | 100.0   |
| Example data. Percentages are of all cases. |       |         |

Cases by age group and sex {.table .cl-d8bad469
quarto-disable-processing="true"}

``` r

phw_gt(mine, caption = "Cases by age group and sex")
```

[TABLE]

``` r

phw_reactable(mine, caption = "Cases by age group and sex")
```

Cases by age group and sex

Example data. Percentages are of all cases.

[`phw_datatable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_datatable.md)
and
[`phw_write_xlsx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_write_xlsx.md)
read the same layout. See [the Excel
section](https://ch3w3y.github.io/phwstyle-r/articles/exporting.html#excel)
to save it as a workbook.

### Cross-tabulations

[`phw_crosstab()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_crosstab.md)
counts by two variables and adds totals. Set `percent` to `"row"`,
`"column"` or `"total"` to show percentages as well.
[`phw_flextable_heat()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_heat.md)
then colours the counts.

``` r

phw_crosstab(cases, setting, age_group) |>
  phw_flextable() |>
  phw_flextable_heat(j = 2:7)
```

|           | age_group |       |       |       |       |     |       |
|-----------|-----------|-------|-------|-------|-------|-----|-------|
| setting   | 0-14      | 15-24 | 25-44 | 45-64 | 65-79 | 80+ | Total |
| Setting 1 | 54        | 96    | 268   | 299   | 212   | 128 | 1,057 |
| Setting 2 | 37        | 61    | 156   | 190   | 112   | 63  | 619   |
| Setting 3 | 25        | 41    | 119   | 122   | 89    | 54  | 450   |
| Setting 4 | 15        | 34    | 82    | 90    | 82    | 58  | 361   |
| Setting 5 | 18        | 32    | 66    | 81    | 51    | 30  | 278   |
| Setting 6 | 8         | 16    | 54    | 72    | 53    | 32  | 235   |
| Total     | 157       | 280   | 745   | 854   | 599   | 365 | 3,000 |

### Rates

[`phw_rate_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_rate_table.md)
takes aggregated counts and populations. It divides cases by population,
multiplies by `per` (100,000 by default) and gives confidence limits for
each rate. The limits come from the Poisson distribution, using the
exact (Garwood) method. Each variable in `groups` becomes its own
section, and `total` adds an overall row. See
[`?phw_rate_table`](https://ch3w3y.github.io/phwstyle-r/reference/phw_rate_table.md)
for the details.

``` r

bands <- c(paste(seq(0, 80, 5), seq(4, 84, 5), sep = "-"), "85+")
agg <- tidyr::expand_grid(sex = c("Female", "Male"), age_group = factor(bands, levels = bands)) |>
  mutate(population = round(runif(n(), 40, 110)) * 1000,
         cases = rpois(n(), population / 1000 * (1 + 0.6 * as.integer(age_group))))
phw_rate_table(agg, c(age_group, sex), cases, population,
               labels = list(age_group = "Age group", sex = "Sex")) |>
  phw_flextable(caption = "Rate per 100,000 by age group and sex")
```

| Group | Cases | Population | Rate per 100,000 | 95% CI |
|----|----|----|----|----|
| Total | 18,493 | 2,776,000 | 666.2 | 656.6 to 675.8 |
| Age group |  |  |  |  |
| 0-4 | 270 | 172,000 | 157.0 | 138.8 to 176.9 |
| 5-9 | 323 | 156,000 | 207.1 | 185.1 to 230.9 |
| 10-14 | 332 | 122,000 | 272.1 | 243.6 to 303.0 |
| 15-19 | 514 | 152,000 | 338.2 | 309.6 to 368.7 |
| 20-24 | 653 | 163,000 | 400.6 | 370.5 to 432.6 |
| 25-29 | 537 | 125,000 | 429.6 | 394.0 to 467.5 |
| 30-34 | 641 | 132,000 | 485.6 | 448.7 to 524.7 |
| 35-39 | 1,209 | 208,000 | 581.2 | 548.9 to 615.0 |
| 40-44 | 858 | 144,000 | 595.8 | 556.6 to 637.1 |
| 45-49 | 1,228 | 177,000 | 693.8 | 655.5 to 733.7 |
| 50-54 | 988 | 126,000 | 784.1 | 736.0 to 834.6 |
| 55-59 | 1,286 | 149,000 | 863.1 | 816.6 to 911.6 |
| 60-64 | 1,597 | 184,000 | 867.9 | 825.9 to 911.6 |
| 65-69 | 1,397 | 145,000 | 963.4 | 913.6 to 1,015.3 |
| 70-74 | 1,552 | 159,000 | 976.1 | 928.1 to 1,025.9 |
| 75-79 | 1,416 | 136,000 | 1,041.2 | 987.6 to 1,096.9 |
| 80-84 | 2,289 | 205,000 | 1,116.6 | 1,071.3 to 1,163.3 |
| 85+ | 1,403 | 121,000 | 1,159.5 | 1,099.6 to 1,221.8 |
| Sex |  |  |  |  |
| Female | 8,950 | 1,336,000 | 669.9 | 656.1 to 683.9 |
| Male | 9,543 | 1,440,000 | 662.7 | 649.5 to 676.1 |
| Confidence intervals use the exact Poisson method. |  |  |  |  |

Rate per 100,000 by age group and sex {.table .cl-d8bad469
quarto-disable-processing="true"}

Use
[`phw_poisson_ci()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_poisson_ci.md)
when you only need the limits for a vector of counts, for example to
draw your own intervals. It returns a data frame with `lower` and
`upper`, for the same calculation that
[`phw_rate_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_rate_table.md)
uses. Change `conf_level` to change the level.

``` r

phw_poisson_ci(c(0, 5, 40))
#>       lower     upper
#> 1  0.000000  3.688879
#> 2  1.623486 11.668332
#> 3 28.576586 54.468647
phw_poisson_ci(c(0, 5, 40), conf_level = 0.99)
#>       lower     upper
#> 1  0.000000  5.298317
#> 2  1.077928 14.149759
#> 3 25.585966 59.363067
```

### Risks by exposure

[`phw_risk_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_risk_table.md)
takes one row per person. For each level of each exposure, it gives the
number of people, the number of cases and the attack rate, which is
cases divided by people. It compares each level with the reference
level, giving a relative risk with a confidence interval and a p-value
from Fisher’s exact test. Set `p_value = FALSE` to leave the p-value
out. See
[`?phw_risk_table`](https://ch3w3y.github.io/phwstyle-r/reference/phw_risk_table.md)
for the details.

``` r

ob <- tibble(exposure_a = sample(c("Yes", "No"), 800, replace = TRUE),
             exposure_b = sample(c("Yes", "No"), 800, replace = TRUE),
             exposure_c = sample(paste("Level", 1:3), 800, replace = TRUE)) |>
  mutate(ill = rbinom(n(), 1, if_else(exposure_a == "Yes", 0.6, 0.15) *
                        c(`Level 1` = 1, `Level 2` = 0.8, `Level 3` = 0.5)[exposure_c]))
phw_risk_table(ob, c(exposure_a, exposure_b, exposure_c), ill,
               labels = list(exposure_a = "Exposure A", exposure_b = "Exposure B",
                             exposure_c = "Exposure C")) |>
  phw_flextable(caption = "Attack rate and relative risk by exposure")
```

| Exposure | People | Cases | Attack rate (%) | Relative risk | 95% CI | p-value |
|----|----|----|----|----|----|----|
| Exposure A |  |  |  |  |  |  |
| No | 380 | 41 | 10.8 | 1 (reference) |  |  |
| Yes | 420 | 197 | 46.9 | 4.35 | 3.20 to 5.91 | \<0.001 |
| Exposure B |  |  |  |  |  |  |
| No | 414 | 118 | 28.5 | 1 (reference) |  |  |
| Yes | 386 | 120 | 31.1 | 1.09 | 0.88 to 1.35 | 0.44 |
| Exposure C |  |  |  |  |  |  |
| Level 1 | 280 | 108 | 38.6 | 1 (reference) |  |  |
| Level 2 | 256 | 81 | 31.6 | 0.82 | 0.65 to 1.04 | \<0.001 |
| Level 3 | 264 | 49 | 18.6 | 0.48 | 0.36 to 0.64 | \<0.001 |
| p-values from Fisher's exact test. |  |  |  |  |  |  |

Attack rate and relative risk by exposure {.table .cl-d8bad469
quarto-disable-processing="true"}

## Nested groups

[`phw_group_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_group_table.md)
nests row groups inside each other. Give the row groups outermost first.
Each group row (Group A to Group E) shows the total for its group, the
groups inside are indented, and the main groups are shaded and separated
with space.

``` r

tab <- phw_group_table(dat, rows = c(group, type), cols = year, labels = col_labels)
phw_flextable(tab, caption = "Counts by group and type", source = "Example data")
```

|                      | Year  |       |       |
|----------------------|-------|-------|-------|
| Group / Type         | 2024  | 2025  | Total |
| Group A              | 623   | 618   | 1,241 |
| Type 1               | 262   | 233   | 495   |
| Type 2               | 187   | 207   | 394   |
| Type 3               | 117   | 118   | 235   |
| Type 4               | 57    | 60    | 117   |
| Group B              | 518   | 492   | 1,010 |
| Type 1               | 198   | 189   | 387   |
| Type 2               | 144   | 151   | 295   |
| Type 3               | 120   | 98    | 218   |
| Type 4               | 56    | 54    | 110   |
| Group C              | 344   | 360   | 704   |
| Type 1               | 124   | 133   | 257   |
| Type 2               | 109   | 113   | 222   |
| Type 3               | 72    | 69    | 141   |
| Type 4               | 39    | 45    | 84    |
| Group D              | 325   | 300   | 625   |
| Type 1               | 128   | 125   | 253   |
| Type 2               | 97    | 87    | 184   |
| Type 3               | 66    | 54    | 120   |
| Type 4               | 34    | 34    | 68    |
| Group E              | 228   | 192   | 420   |
| Type 1               | 90    | 82    | 172   |
| Type 2               | 71    | 50    | 121   |
| Type 3               | 41    | 43    | 84    |
| Type 4               | 26    | 17    | 43    |
| Total                | 2,038 | 1,962 | 4,000 |
| Source: Example data |       |       |       |

Counts by group and type {.table .cl-d8bad469
quarto-disable-processing="true"}

### Totals

`totals` takes any of `"group"` (totals on each group row), `"subgroup"`
(a block with each type summed across all groups) and `"table"` (a grand
total). `total_position` puts the table total at the top or bottom, and
`subtotal_position = "below"` moves group totals to their own row.

``` r

phw_group_table(dat, c(group, type), labels = col_labels,
                totals = c("group", "subgroup", "table"),
                subtotal_position = "below", total_position = "top") |>
  phw_flextable()
```

| Group / Type  | n     |
|---------------|-------|
| Total         | 4,000 |
| Total by Type |       |
| Type 1        | 1,564 |
| Type 2        | 1,216 |
| Type 3        | 798   |
| Type 4        | 422   |
| Group A       |       |
| Type 1        | 495   |
| Type 2        | 394   |
| Type 3        | 235   |
| Type 4        | 117   |
| Group A total | 1,241 |
| Group B       |       |
| Type 1        | 387   |
| Type 2        | 295   |
| Type 3        | 218   |
| Type 4        | 110   |
| Group B total | 1,010 |
| Group C       |       |
| Type 1        | 257   |
| Type 2        | 222   |
| Type 3        | 141   |
| Type 4        | 84    |
| Group C total | 704   |
| Group D       |       |
| Type 1        | 253   |
| Type 2        | 184   |
| Type 3        | 120   |
| Type 4        | 68    |
| Group D total | 625   |
| Group E       |       |
| Type 1        | 172   |
| Type 2        | 121   |
| Type 3        | 84    |
| Type 4        | 43    |
| Group E total | 420   |

### Layout and percentages

`layout = "columns"` gives each level its own column, so the inner
groups shift to the right. `percent = "parent"` shows each row as a
share of the group above it. `"column"` and `"row"` are also available.

``` r

phw_group_table(dat, c(group, type), labels = col_labels, layout = "columns",
                percent = "parent", separate = "both") |>
  phw_flextable()
```

| Group                    | Type   | n              |
|--------------------------|--------|----------------|
| Group A                  |        | 1,241 (31.0%)  |
|                          | Type 1 | 495 (39.9%)    |
|                          | Type 2 | 394 (31.7%)    |
|                          | Type 3 | 235 (18.9%)    |
|                          | Type 4 | 117 (9.4%)     |
| Group B                  |        | 1,010 (25.2%)  |
|                          | Type 1 | 387 (38.3%)    |
|                          | Type 2 | 295 (29.2%)    |
|                          | Type 3 | 218 (21.6%)    |
|                          | Type 4 | 110 (10.9%)    |
| Group C                  |        | 704 (17.6%)    |
|                          | Type 1 | 257 (36.5%)    |
|                          | Type 2 | 222 (31.5%)    |
|                          | Type 3 | 141 (20.0%)    |
|                          | Type 4 | 84 (11.9%)     |
| Group D                  |        | 625 (15.6%)    |
|                          | Type 1 | 253 (40.5%)    |
|                          | Type 2 | 184 (29.4%)    |
|                          | Type 3 | 120 (19.2%)    |
|                          | Type 4 | 68 (10.9%)     |
| Group E                  |        | 420 (10.5%)    |
|                          | Type 1 | 172 (41.0%)    |
|                          | Type 2 | 121 (28.8%)    |
|                          | Type 3 | 84 (20.0%)     |
|                          | Type 4 | 43 (10.2%)     |
| Total                    |        | 4,000 (100.0%) |
| n (% of the group above) |        |                |

### Nested columns

Columns can nest too, here quarters within years, with a total for each
year and overall.

``` r

nested <- phw_group_table(dat, c(group, type), c(year, quarter), labels = col_labels,
                          col_totals = c("group", "table"))
phw_gt(nested, caption = "Counts by quarter")
```

[TABLE]

### Other statistics

By default rows are counted. Give `value` and `fun` for anything else.
Group and total rows are calculated from their records, not by adding up
rows.

``` r

phw_group_table(dat, c(group, type), year, value = days,
                fun = function(x) round(mean(x), 1), labels = col_labels) |>
  phw_flextable(caption = "Mean days")
```

|              | Year |      |       |
|--------------|------|------|-------|
| Group / Type | 2024 | 2025 | Total |
| Group A      | 3.0  | 2.9  | 2.9   |
| Type 1       | 3.0  | 2.9  | 3.0   |
| Type 2       | 2.8  | 2.9  | 2.9   |
| Type 3       | 2.9  | 2.9  | 2.9   |
| Type 4       | 3.0  | 2.9  | 3.0   |
| Group B      | 3.0  | 3.0  | 3.0   |
| Type 1       | 3.0  | 3.0  | 3.0   |
| Type 2       | 3.1  | 3.2  | 3.2   |
| Type 3       | 2.9  | 2.9  | 2.9   |
| Type 4       | 3.2  | 2.9  | 3.0   |
| Group C      | 3.0  | 2.9  | 2.9   |
| Type 1       | 3.0  | 2.6  | 2.8   |
| Type 2       | 3.1  | 3.1  | 3.1   |
| Type 3       | 3.0  | 3.1  | 3.1   |
| Type 4       | 2.6  | 2.6  | 2.6   |
| Group D      | 3.1  | 3.1  | 3.1   |
| Type 1       | 3.0  | 3.3  | 3.1   |
| Type 2       | 3.4  | 2.9  | 3.2   |
| Type 3       | 3.3  | 2.9  | 3.1   |
| Type 4       | 2.3  | 3.0  | 2.6   |
| Group E      | 3.1  | 3.1  | 3.1   |
| Type 1       | 3.3  | 3.3  | 3.3   |
| Type 2       | 2.9  | 2.8  | 2.9   |
| Type 3       | 3.3  | 2.9  | 3.1   |
| Type 4       | 2.8  | 3.4  | 3.0   |
| Total        | 3.0  | 3.0  | 3.0   |

Mean days {.table .cl-d8bad469 quarto-disable-processing="true"}

## Render the same table anywhere

### flextable

[`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md)
builds a flextable from a data frame or any table above. It adds the
caption, the number formats and the source line. `style` chooses the
look. The default is `"booktabs"`, with horizontal rules only.

``` r

small <- tibble(Area = sprintf("Area %02d", 1:8), Cases = rpois(8, 150),
                Deaths = rpois(8, 12), Rate = round(runif(8, 8, 55), 1))
phw_flextable(small, caption = "booktabs", style = "booktabs")
```

| Area    | Cases | Deaths | Rate |
|---------|-------|--------|------|
| Area 01 | 154   | 6      | 9.1  |
| Area 02 | 134   | 12     | 15.1 |
| Area 03 | 159   | 17     | 19.9 |
| Area 04 | 139   | 7      | 19.3 |
| Area 05 | 139   | 11     | 10.3 |
| Area 06 | 150   | 16     | 24.7 |
| Area 07 | 144   | 10     | 48.2 |
| Area 08 | 148   | 12     | 47.6 |

booktabs {.table .cl-d8bad469 quarto-disable-processing="true"}

`"header"` gives a navy header band with white text.

``` r

phw_flextable(small, caption = "header", style = "header")
```

| Area    | Cases | Deaths | Rate |
|---------|-------|--------|------|
| Area 01 | 154   | 6      | 9.1  |
| Area 02 | 134   | 12     | 15.1 |
| Area 03 | 159   | 17     | 19.9 |
| Area 04 | 139   | 7      | 19.3 |
| Area 05 | 139   | 11     | 10.3 |
| Area 06 | 150   | 16     | 24.7 |
| Area 07 | 144   | 10     | 48.2 |
| Area 08 | 148   | 12     | 47.6 |

header {.table .cl-d8bad469 quarto-disable-processing="true"}

`"zebra"` adds grey banding to alternate rows.

``` r

phw_flextable(small, caption = "zebra", style = "zebra")
```

| Area    | Cases | Deaths | Rate |
|---------|-------|--------|------|
| Area 01 | 154   | 6      | 9.1  |
| Area 02 | 134   | 12     | 15.1 |
| Area 03 | 159   | 17     | 19.9 |
| Area 04 | 139   | 7      | 19.3 |
| Area 05 | 139   | 11     | 10.3 |
| Area 06 | 150   | 16     | 24.7 |
| Area 07 | 144   | 10     | 48.2 |
| Area 08 | 148   | 12     | 47.6 |

zebra {.table .cl-d8bad469 quarto-disable-processing="true"}

`"light"` gives a light-teal header band with dark text.

``` r

phw_flextable(small, caption = "light", style = "light")
```

| Area    | Cases | Deaths | Rate |
|---------|-------|--------|------|
| Area 01 | 154   | 6      | 9.1  |
| Area 02 | 134   | 12     | 15.1 |
| Area 03 | 159   | 17     | 19.9 |
| Area 04 | 139   | 7      | 19.3 |
| Area 05 | 139   | 11     | 10.3 |
| Area 06 | 150   | 16     | 24.7 |
| Area 07 | 144   | 10     | 48.2 |
| Area 08 | 148   | 12     | 47.6 |

light {.table .cl-d8bad469 quarto-disable-processing="true"}

Other arguments, such as `bold_first_col`, `total_row` and `accent`, go
to
[`phw_flextable_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_theme.md).

``` r

phw_flextable(small, style = "header", bold_first_col = TRUE, accent = phw_colours[["teal"]])
```

| Area    | Cases | Deaths | Rate |
|---------|-------|--------|------|
| Area 01 | 154   | 6      | 9.1  |
| Area 02 | 134   | 12     | 15.1 |
| Area 03 | 159   | 17     | 19.9 |
| Area 04 | 139   | 7      | 19.3 |
| Area 05 | 139   | 11     | 10.3 |
| Area 06 | 150   | 16     | 24.7 |
| Area 07 | 144   | 10     | 48.2 |
| Area 08 | 148   | 12     | 47.6 |

### Heat, bars and group colours

[`phw_flextable_heat()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_heat.md)
fills the cells of the columns you choose with a sequential palette. It
picks white or dark text for each cell. Choose columns the way you do in
dplyr, and use `palette` and `domain` to change the colours and the
range they span.

``` r

phw_flextable(small) |>
  phw_flextable_heat(j = c(Cases, Deaths, Rate), palette = "blues")
```

| Area    | Cases | Deaths | Rate |
|---------|-------|--------|------|
| Area 01 | 154   | 6      | 9.1  |
| Area 02 | 134   | 12     | 15.1 |
| Area 03 | 159   | 17     | 19.9 |
| Area 04 | 139   | 7      | 19.3 |
| Area 05 | 139   | 11     | 10.3 |
| Area 06 | 150   | 16     | 24.7 |
| Area 07 | 144   | 10     | 48.2 |
| Area 08 | 148   | 12     | 47.6 |

With `palette = "rag"`, the cells are red, amber or green and a shape
comes before each value, so the meaning survives black-and-white print.
Give two cut points in `breaks`, and set `higher_is_better = FALSE` when
a low value is good. `"rag_accessible"` uses navy in place of green.

``` r

phw_flextable(small) |>
  phw_flextable_heat(j = Rate, palette = "rag", breaks = c(20, 40))
```

| Area    | Cases | Deaths | Rate   |
|---------|-------|--------|--------|
| Area 01 | 154   | 6      | ▼ 9.1  |
| Area 02 | 134   | 12     | ▼ 15.1 |
| Area 03 | 159   | 17     | ▼ 19.9 |
| Area 04 | 139   | 7      | ▼ 19.3 |
| Area 05 | 139   | 11     | ▼ 10.3 |
| Area 06 | 150   | 16     | ■ 24.7 |
| Area 07 | 144   | 10     | ▲ 48.2 |
| Area 08 | 148   | 12     | ▲ 47.6 |

[`phw_flextable_bars()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_bars.md)
draws a small bar before each value, scaled to the largest value in the
column.

``` r

phw_flextable(small) |>
  phw_flextable_bars(Cases)
```

| Area | Cases | Deaths | Rate |
|----|----|----|----|
| Area 01 | ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQ4AAAAeCAYAAADdEPCKAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAiElEQVR4nO3UMRGAQAADQR4/CMAbJd5eAIJAwxU0sNtnJtWNY173AvzWuW+jbtY3jgDfJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxAJhxA9gBzwAQ8UQIfmAAAAABJRU5ErkJggg==) 154 | 6 | 9.1 |
| Area 02 | ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQ4AAAAeCAYAAADdEPCKAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAiElEQVR4nO3UMQ2AQADAQB4/CMAbI94QgCDQUJYPyZ2CTh3HdT8LMMW5b2N2wxfr7ADgf4wDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyF7s7AQ8UWiN2QAAAABJRU5ErkJggg==) 134 | 12 | 15.1 |
| Area 03 | ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQ4AAAAeCAYAAADdEPCKAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAfklEQVR4nO3UQQ3AIADAQED3/CEAQZuGvsiSOwV9dT77vAMgWLcDgP8xDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiD7ANSUA1HBCZHKAAAAAElFTkSuQmCC) 159 | 17 | 19.9 |
| Area 04 | ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQ4AAAAeCAYAAADdEPCKAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAiUlEQVR4nO3UQRVAUAAAQV8fAXRz1E0AgSjgsie8N5NgTzu247wm4JP2dRlvNzyZ3w4A/sc4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gOwGz4wEPOaIYpIAAAAASUVORK5CYII=) 139 | 7 | 19.3 |
| Area 05 | ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQ4AAAAeCAYAAADdEPCKAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAiUlEQVR4nO3UQRVAUAAAQV8fAXRz1E0AgSjgsie8N5NgTzu247wm4JP2dRlvNzyZ3w4A/sc4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gMw4gOwGz4wEPOaIYpIAAAAASUVORK5CYII=) 139 | 11 | 10.3 |
| Area 06 | ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQ4AAAAeCAYAAADdEPCKAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAiElEQVR4nO3UMRGAQAADQR4/CMAbJd4QgCDQcAPd7wrIpLpxXPezANM492183Vj/OALMRTiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiATDiA7AWCcAQ8n5C4LwAAAABJRU5ErkJggg==) 150 | 16 | 24.7 |
| Area 07 | ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQ4AAAAeCAYAAADdEPCKAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAh0lEQVR4nO3UMQ2AMAAAQYofBOCNEW8IQBBo+Klpcmfgtx/X834bsKT7PMaM7j4jCqzNOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDsB7IsBDwzBzu8AAAAAElFTkSuQmCC) 144 | 10 | 48.2 |
| Area 08 | ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQ4AAAAeCAYAAADdEPCKAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAh0lEQVR4nO3UMQ2AMAAAQYofBOCNEW8IQBBo+KRTcyfgxx/X834bsKz7PMbs5j47CKzPOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDMOIDsB5EgBDy/aUSPAAAAAElFTkSuQmCC) 148 | 12 | 47.6 |

[`phw_flextable_groups()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_groups.md)
colours cells by the group they contain, using the colours of your
charts. Give a colour key with `key` and the group keeps its colour
across tables and charts (see [colour
keys](https://ch3w3y.github.io/phwstyle-r/articles/colours.html#colours-that-stay-with-their-groups)).
Set `what = "text"` to colour the text, and `rows = TRUE` to colour the
whole row.

``` r

by_group <- tibble(Group = c(paste("Group", LETTERS[1:6]), "Unknown"),
                   Cases = c(420, 385, 264, 190, 120, 85, 29))
phw_flextable(by_group) |>
  phw_flextable_groups(Group)
```

| Group   | Cases |
|---------|-------|
| Group A | 420   |
| Group B | 385   |
| Group C | 264   |
| Group D | 190   |
| Group E | 120   |
| Group F | 85    |
| Unknown | 29    |

``` r

phw_flextable(by_group) |>
  phw_flextable_groups(Group, what = "text", rows = TRUE)
```

| Group   | Cases |
|---------|-------|
| Group A | 420   |
| Group B | 385   |
| Group C | 264   |
| Group D | 190   |
| Group E | 120   |
| Group F | 85    |
| Unknown | 29    |

### A flextable you made yourself

[`phw_flextable_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_theme.md)
styles a flextable you built with the flextable package. It takes the
same `style` choices.

``` r

flextable::flextable(head(small, 5)) |>
  phw_flextable_theme(style = "zebra")
```

| Area    | Cases | Deaths | Rate |
|---------|-------|--------|------|
| Area 01 | 154   | 6      | 9.1  |
| Area 02 | 134   | 12     | 15.1 |
| Area 03 | 159   | 17     | 19.9 |
| Area 04 | 139   | 7      | 19.3 |
| Area 05 | 139   | 11     | 10.3 |

[`use_phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_flextable.md)
sets the defaults for every new flextable in your session, so put it in
a setup chunk. It returns your earlier defaults, so you can put them
back.

``` r

old <- use_phw_flextable()
flextable::flextable(head(small, 5))
```

| Area    | Cases | Deaths | Rate |
|---------|-------|--------|------|
| Area 01 | 154   | 6      | 9.1  |
| Area 02 | 134   | 12     | 15.1 |
| Area 03 | 159   | 17     | 19.9 |
| Area 04 | 139   | 7      | 19.3 |
| Area 05 | 139   | 11     | 10.3 |

``` r

do.call(flextable::set_flextable_defaults, old)
```

### gt

[`phw_gt()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_gt_theme.md)
builds a gt table with the same caption, number formats and source line.
It understands summary tables and group tables. Use it for HTML and PDF.
In Word, gt can’t make the column labels bold or indent the levels of a
summary table, so use
[`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md)
there.

``` r

phw_gt(small, caption = "Cases by area", source = "Example data")
```

| Cases by area        |       |        |      |
|----------------------|-------|--------|------|
| Area                 | Cases | Deaths | Rate |
| Area 01              | 154   | 6      | 9.1  |
| Area 02              | 134   | 12     | 15.1 |
| Area 03              | 159   | 17     | 19.9 |
| Area 04              | 139   | 7      | 19.3 |
| Area 05              | 139   | 11     | 10.3 |
| Area 06              | 150   | 16     | 24.7 |
| Area 07              | 144   | 10     | 48.2 |
| Area 08              | 148   | 12     | 47.6 |
| Source: Example data |       |        |      |

[`phw_gt_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_gt_theme.md)
styles a gt table you built yourself. Set `stripe = TRUE` to shade
alternate rows.

``` r

gt::gt(small) |>
  gt::tab_header(title = "Cases by area") |>
  phw_gt_theme(stripe = TRUE)
```

| Cases by area |       |        |      |
|---------------|-------|--------|------|
| Area          | Cases | Deaths | Rate |
| Area 01       | 154   | 6      | 9.1  |
| Area 02       | 134   | 12     | 15.1 |
| Area 03       | 159   | 17     | 19.9 |
| Area 04       | 139   | 7      | 19.3 |
| Area 05       | 139   | 11     | 10.3 |
| Area 06       | 150   | 16     | 24.7 |
| Area 07       | 144   | 10     | 48.2 |
| Area 08       | 148   | 12     | 47.6 |

### gtsummary

[`use_phw_gtsummary()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_gtsummary.md)
sets a theme, so every gtsummary table is styled when printed with gt or
converted with `as_flex_table()`.

``` r

use_phw_gtsummary()
cases |>
  select(age_group, sex, days, outcome) |>
  gtsummary::tbl_summary(by = outcome)
```

[TABLE]

### Interactive tables and Excel

[`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md)
and
[`phw_datatable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_datatable.md)
make tables you can sort and search. See
[reactable](https://ch3w3y.github.io/phwstyle-r/articles/interactive.html#reactable).
[`phw_write_xlsx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_write_xlsx.md)
saves any of these tables as a workbook. See
[Excel](https://ch3w3y.github.io/phwstyle-r/articles/exporting.html#excel).

For finished examples of every table, see the
[gallery](https://ch3w3y.github.io/phwstyle-r/articles/gallery.html#tables).
