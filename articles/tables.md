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
  group = sample(c("Group A", "Group B", "Group C"), 400, replace = TRUE, prob = c(0.45, 0.4, 0.15)),
  type = factor(sample(c("Type 1", "Type 2", "Type 3"), 400, replace = TRUE, prob = c(0.45, 0.45, 0.1)),
                levels = c("Type 1", "Type 2", "Type 3")),
  year = sample(2024:2025, 400, replace = TRUE),
  quarter = sample(paste0("Q", 1:4), 400, replace = TRUE),
  days = rpois(400, 3)
)
col_labels <- list(group = "Group", type = "Type", year = "Year", quarter = "Quarter")

cases <- tibble(
  age_group = sample(c("0-14", "15-44", "45-64", "65+"), 300, replace = TRUE),
  sex = sample(c("Female", "Male"), 300, replace = TRUE),
  setting = sample(c("Setting 1", "Setting 2", "Setting 3"), 300, replace = TRUE),
  days = rpois(300, 4),
  outcome = sample(c("Outcome X", "Outcome Y"), 300, replace = TRUE, prob = c(0.8, 0.2))
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

|                     | outcome             |                    |                  |
|---------------------|---------------------|--------------------|------------------|
| Characteristic      | Outcome X (n = 232) | Outcome Y (n = 68) | Total (n = 300)  |
| Age group           |                     |                    |                  |
| 0-14                | 57 (24.6%)          | 15 (22.1%)         | 72 (24.0%)       |
| 15-44               | 72 (31.0%)          | 16 (23.5%)         | 88 (29.3%)       |
| 45-64               | 46 (19.8%)          | 20 (29.4%)         | 66 (22.0%)       |
| 65+                 | 57 (24.6%)          | 17 (25.0%)         | 74 (24.7%)       |
| Sex                 |                     |                    |                  |
| Female              | 113 (48.7%)         | 37 (54.4%)         | 150 (50.0%)      |
| Male                | 119 (51.3%)         | 31 (45.6%)         | 150 (50.0%)      |
| Setting             |                     |                    |                  |
| Setting 1           | 89 (38.4%)          | 20 (29.4%)         | 109 (36.3%)      |
| Setting 2           | 74 (31.9%)          | 21 (30.9%)         | 95 (31.7%)       |
| Setting 3           | 69 (29.7%)          | 27 (39.7%)         | 96 (32.0%)       |
| Days to recovery    | 4.0 (3.0 to 5.0)    | 4.0 (3.0 to 5.0)   | 4.0 (3.0 to 5.0) |
| n (%); median (IQR) |                     |                    |                  |

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
#>            0-14    72    24.0
#>           15-44    88    29.3
#>           45-64    66    22.0
#>             65+    74    24.7
#>             Sex    NA      NA
#>          Female   150    50.0
#>            Male   150    50.0
#>       All cases   300   100.0
#> Example data. Percentages are of all cases.
```

The same object works in every renderer.

``` r

phw_flextable(mine, caption = "Cases by age group and sex")
```

| Characteristic                              | Cases | Percent |
|---------------------------------------------|-------|---------|
| Age group                                   |       |         |
| 0-14                                        | 72    | 24.0    |
| 15-44                                       | 88    | 29.3    |
| 45-64                                       | 66    | 22.0    |
| 65+                                         | 74    | 24.7    |
| Sex                                         |       |         |
| Female                                      | 150   | 50.0    |
| Male                                        | 150   | 50.0    |
| All cases                                   | 300   | 100.0   |
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
  phw_flextable_heat(j = 2:5)
```

|           | age_group |       |       |     |       |
|-----------|-----------|-------|-------|-----|-------|
| setting   | 0-14      | 15-44 | 45-64 | 65+ | Total |
| Setting 1 | 26        | 29    | 28    | 26  | 109   |
| Setting 2 | 21        | 31    | 18    | 25  | 95    |
| Setting 3 | 25        | 28    | 20    | 23  | 96    |
| Total     | 72        | 88    | 66    | 74  | 300   |

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

agg <- tidyr::expand_grid(sex = c("Female", "Male"), age_group = c("0-14", "15-44", "45-64", "65+")) |>
  mutate(cases = rpois(n(), c(10, 25, 35, 50)),
         population = round(runif(n(), 60, 140)) * 1000)
phw_rate_table(agg, c(age_group, sex), cases, population,
               labels = list(age_group = "Age group", sex = "Sex")) |>
  phw_flextable(caption = "Rate per 100,000 by age group and sex")
```

| Group | Cases | Population | Rate per 100,000 | 95% CI |
|----|----|----|----|----|
| Total | 240 | 904,000 | 26.5 | 23.3 to 30.1 |
| Age group |  |  |  |  |
| 0-14 | 21 | 239,000 | 8.8 | 5.4 to 13.4 |
| 15-44 | 50 | 274,000 | 18.2 | 13.5 to 24.1 |
| 45-64 | 70 | 202,000 | 34.7 | 27.0 to 43.8 |
| 65+ | 99 | 189,000 | 52.4 | 42.6 to 63.8 |
| Sex |  |  |  |  |
| Female | 117 | 469,000 | 24.9 | 20.6 to 29.9 |
| Male | 123 | 435,000 | 28.3 | 23.5 to 33.7 |
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

ob <- tibble(exposure_a = sample(c("Yes", "No"), 120, replace = TRUE),
             exposure_b = sample(c("Yes", "No"), 120, replace = TRUE)) |>
  mutate(ill = rbinom(n(), 1, if_else(exposure_a == "Yes", 0.6, 0.15)))
phw_risk_table(ob, c(exposure_a, exposure_b), ill,
               labels = list(exposure_a = "Exposure A", exposure_b = "Exposure B")) |>
  phw_flextable(caption = "Attack rate and relative risk by exposure")
```

| Exposure | People | Cases | Attack rate (%) | Relative risk | 95% CI | p-value |
|----|----|----|----|----|----|----|
| Exposure A |  |  |  |  |  |  |
| No | 52 | 5 | 9.6 | 1 (reference) |  |  |
| Yes | 68 | 45 | 66.2 | 6.88 | 2.94 to 16.11 | \<0.001 |
| Exposure B |  |  |  |  |  |  |
| No | 60 | 30 | 50.0 | 1 (reference) |  |  |
| Yes | 60 | 20 | 33.3 | 0.67 | 0.43 to 1.03 | 0.095 |
| p-values from Fisher's exact test. |  |  |  |  |  |  |

Attack rate and relative risk by exposure {.table .cl-d8bad469
quarto-disable-processing="true"}

## Nested groups

[`phw_group_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_group_table.md)
nests row groups inside each other. Give the row groups outermost first.
Each group row (Group A, B, C) shows the total for its group, the groups
inside are indented, and the main groups are shaded and separated with
space.

``` r

tab <- phw_group_table(dat, rows = c(group, type), cols = year, labels = col_labels)
phw_flextable(tab, caption = "Counts by group and type", source = "Example data")
```

|                      | Year |      |       |
|----------------------|------|------|-------|
| Group / Type         | 2024 | 2025 | Total |
| Group A              | 100  | 88   | 188   |
| Type 1               | 46   | 36   | 82    |
| Type 2               | 38   | 42   | 80    |
| Type 3               | 16   | 10   | 26    |
| Group B              | 64   | 91   | 155   |
| Type 1               | 34   | 38   | 72    |
| Type 2               | 25   | 45   | 70    |
| Type 3               | 5    | 8    | 13    |
| Group C              | 24   | 33   | 57    |
| Type 1               | 12   | 15   | 27    |
| Type 2               | 9    | 13   | 22    |
| Type 3               | 3    | 5    | 8     |
| Total                | 188  | 212  | 400   |
| Source: Example data |      |      |       |

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

| Group / Type  | n   |
|---------------|-----|
| Total         | 400 |
| Total by type |     |
| Type 1        | 181 |
| Type 2        | 172 |
| Type 3        | 47  |
| Group A       |     |
| Type 1        | 82  |
| Type 2        | 80  |
| Type 3        | 26  |
| Group A total | 188 |
| Group B       |     |
| Type 1        | 72  |
| Type 2        | 70  |
| Type 3        | 13  |
| Group B total | 155 |
| Group C       |     |
| Type 1        | 27  |
| Type 2        | 22  |
| Type 3        | 8   |
| Group C total | 57  |

### Layout and percentages

`layout = "columns"` gives each level its own column, so the inner
groups shift to the right. `percent = "parent"` shows each row as a
share of the group above it. `"column"` and `"row"` are also available.

``` r

phw_group_table(dat, c(group, type), labels = col_labels, layout = "columns",
                percent = "parent", separate = "both") |>
  phw_flextable()
```

| Group                    | Type   | n            |
|--------------------------|--------|--------------|
| Group A                  |        | 188 (47.0%)  |
|                          | Type 1 | 82 (43.6%)   |
|                          | Type 2 | 80 (42.6%)   |
|                          | Type 3 | 26 (13.8%)   |
| Group B                  |        | 155 (38.8%)  |
|                          | Type 1 | 72 (46.5%)   |
|                          | Type 2 | 70 (45.2%)   |
|                          | Type 3 | 13 (8.4%)    |
| Group C                  |        | 57 (14.2%)   |
|                          | Type 1 | 27 (47.4%)   |
|                          | Type 2 | 22 (38.6%)   |
|                          | Type 3 | 8 (14.0%)    |
| Total                    |        | 400 (100.0%) |
| n (% of the group above) |        |              |

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
| Group A      | 2.9  | 2.9  | 2.9   |
| Type 1       | 3.3  | 2.7  | 3.0   |
| Type 2       | 2.7  | 3.1  | 2.9   |
| Type 3       | 2.4  | 3.2  | 2.7   |
| Group B      | 3.5  | 3.0  | 3.2   |
| Type 1       | 3.4  | 3.1  | 3.2   |
| Type 2       | 3.6  | 2.9  | 3.1   |
| Type 3       | 3.4  | 4.0  | 3.8   |
| Group C      | 2.6  | 2.4  | 2.5   |
| Type 1       | 2.3  | 2.1  | 2.2   |
| Type 2       | 3.2  | 2.1  | 2.5   |
| Type 3       | 1.7  | 4.0  | 3.1   |
| Total        | 3.1  | 2.9  | 3.0   |

Mean days {.table .cl-d8bad469 quarto-disable-processing="true"}

## Render the same table anywhere

### flextable

[`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md)
builds a flextable from a data frame or any table above. It adds the
caption, the number formats and the source line. `style` chooses the
look. The default is `"booktabs"`, with horizontal rules only.

``` r

small <- tibble(Area = paste("Area", LETTERS[1:4]), Cases = c(120, 85, 64, 19),
                Rate = c(48.2, 39.5, 27.1, 12.9))
phw_flextable(small, caption = "booktabs", style = "booktabs")
```

| Area   | Cases | Rate |
|--------|-------|------|
| Area A | 120   | 48.2 |
| Area B | 85    | 39.5 |
| Area C | 64    | 27.1 |
| Area D | 19    | 12.9 |

booktabs {.table .cl-d8bad469 quarto-disable-processing="true"}

`"header"` gives a navy header band with white text.

``` r

phw_flextable(small, caption = "header", style = "header")
```

| Area   | Cases | Rate |
|--------|-------|------|
| Area A | 120   | 48.2 |
| Area B | 85    | 39.5 |
| Area C | 64    | 27.1 |
| Area D | 19    | 12.9 |

header {.table .cl-d8bad469 quarto-disable-processing="true"}

`"zebra"` adds grey banding to alternate rows.

``` r

phw_flextable(small, caption = "zebra", style = "zebra")
```

| Area   | Cases | Rate |
|--------|-------|------|
| Area A | 120   | 48.2 |
| Area B | 85    | 39.5 |
| Area C | 64    | 27.1 |
| Area D | 19    | 12.9 |

zebra {.table .cl-d8bad469 quarto-disable-processing="true"}

`"light"` gives a light-teal header band with dark text.

``` r

phw_flextable(small, caption = "light", style = "light")
```

| Area   | Cases | Rate |
|--------|-------|------|
| Area A | 120   | 48.2 |
| Area B | 85    | 39.5 |
| Area C | 64    | 27.1 |
| Area D | 19    | 12.9 |

light {.table .cl-d8bad469 quarto-disable-processing="true"}

Other arguments, such as `bold_first_col`, `total_row` and `accent`, go
to
[`phw_flextable_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_theme.md).

``` r

phw_flextable(small, style = "header", bold_first_col = TRUE, accent = phw_colours[["teal"]])
```

| Area   | Cases | Rate |
|--------|-------|------|
| Area A | 120   | 48.2 |
| Area B | 85    | 39.5 |
| Area C | 64    | 27.1 |
| Area D | 19    | 12.9 |

### Heat, bars and group colours

[`phw_flextable_heat()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_heat.md)
fills the cells of the columns you choose with a sequential palette. It
picks white or dark text for each cell. Choose columns the way you do in
dplyr, and use `palette` and `domain` to change the colours and the
range they span.

``` r

phw_flextable(small) |>
  phw_flextable_heat(j = c(Cases, Rate), palette = "blues")
```

| Area   | Cases | Rate |
|--------|-------|------|
| Area A | 120   | 48.2 |
| Area B | 85    | 39.5 |
| Area C | 64    | 27.1 |
| Area D | 19    | 12.9 |

With `palette = "rag"`, the cells are red, amber or green and a shape
comes before each value, so the meaning survives black-and-white print.
Give two cut points in `breaks`, and set `higher_is_better = FALSE` when
a low value is good. `"rag_accessible"` uses navy in place of green.

``` r

phw_flextable(small) |>
  phw_flextable_heat(j = Rate, palette = "rag", breaks = c(20, 40))
```

| Area   | Cases | Rate   |
|--------|-------|--------|
| Area A | 120   | ▲ 48.2 |
| Area B | 85    | ■ 39.5 |
| Area C | 64    | ■ 27.1 |
| Area D | 19    | ▼ 12.9 |

[`phw_flextable_bars()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_bars.md)
draws a small bar before each value, scaled to the largest value in the
column.

``` r

phw_flextable(small) |>
  phw_flextable_bars(Cases)
```

| Area | Cases | Rate |
|----|----|----|
| Area A | ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQ4AAAAeCAYAAADdEPCKAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAfklEQVR4nO3UQQ3AIADAQED3/CEAQZuGvsiSOwV9dT77vAMgWLcDgP8xDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiAzDiD7ANSUA1HBCZHKAAAAAElFTkSuQmCC) 120 | 48.2 |
| Area B | ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQ4AAAAeCAYAAADdEPCKAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAiElEQVR4nO3UMRGAMADAQIofBOCNEW8IQBBoyNTj+FeQKeO47meBnzn3bcxu+LJ1dgDwPcYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZMYBZC9p0wQ8np3PMwAAAABJRU5ErkJggg==) 85 | 39.5 |
| Area C | ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQ4AAAAeCAYAAADdEPCKAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAiElEQVR4nO3UMQ2AQADAQB4/CMAbI94QgCDQUJYPyZ2CTh3HdT8LfHDu25jdwBzr7ADgf4wDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyIwDyF4WdgQ8TmurngAAAABJRU5ErkJggg==) 64 | 27.1 |
| Area D | ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQ4AAAAeCAYAAADdEPCKAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAC4jAAAuIwF4pT92AAAAiUlEQVR4nO3UMQ2AQADAQB4/CMAbI94QgCAYUNDpQ3KnoFPHcd3P8gPnvo3ZDcBnnR0A/I9xAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxAJlxANkLiWEEPBiQXSgAAAAASUVORK5CYII=) 19 | 12.9 |

[`phw_flextable_groups()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_groups.md)
colours cells by the group they contain, using the colours of your
charts. Give a colour key with `key` and the group keeps its colour
across tables and charts (see [colour
keys](https://ch3w3y.github.io/phwstyle-r/articles/colours.html#colours-that-stay-with-their-groups)).
Set `what = "text"` to colour the text, and `rows = TRUE` to colour the
whole row.

``` r

by_group <- tibble(Group = c("Group A", "Group B", "Group C", "Unknown"),
                   Cases = c(120, 85, 64, 9))
phw_flextable(by_group) |>
  phw_flextable_groups(Group)
```

| Group   | Cases |
|---------|-------|
| Group A | 120   |
| Group B | 85    |
| Group C | 64    |
| Unknown | 9     |

``` r

phw_flextable(by_group) |>
  phw_flextable_groups(Group, what = "text", rows = TRUE)
```

| Group   | Cases |
|---------|-------|
| Group A | 120   |
| Group B | 85    |
| Group C | 64    |
| Unknown | 9     |

### A flextable you made yourself

[`phw_flextable_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_theme.md)
styles a flextable you built with the flextable package. It takes the
same `style` choices.

``` r

flextable::flextable(head(small, 3)) |>
  phw_flextable_theme(style = "zebra")
```

| Area   | Cases | Rate |
|--------|-------|------|
| Area A | 120   | 48.2 |
| Area B | 85    | 39.5 |
| Area C | 64    | 27.1 |

[`use_phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_flextable.md)
sets the defaults for every new flextable in your session, so put it in
a setup chunk. It returns your earlier defaults, so you can put them
back.

``` r

old <- use_phw_flextable()
flextable::flextable(head(small, 3))
```

| Area   | Cases | Rate |
|--------|-------|------|
| Area A | 120   | 48.2 |
| Area B | 85    | 39.5 |
| Area C | 64    | 27.1 |

``` r

do.call(flextable::set_flextable_defaults, old)
```

### gt

[`phw_gt()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_gt_theme.md)
builds a gt table with the same caption, number formats and source line.
It understands summary tables and group tables.

``` r

phw_gt(small, caption = "Cases by area", source = "Example data")
```

| Cases by area        |       |      |
|----------------------|-------|------|
| Area                 | Cases | Rate |
| Area A               | 120   | 48.2 |
| Area B               | 85    | 39.5 |
| Area C               | 64    | 27.1 |
| Area D               | 19    | 12.9 |
| Source: Example data |       |      |

[`phw_gt_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_gt_theme.md)
styles a gt table you built yourself. Set `stripe = TRUE` to shade
alternate rows.

``` r

gt::gt(small) |>
  gt::tab_header(title = "Cases by area") |>
  phw_gt_theme(stripe = TRUE)
```

| Cases by area |       |      |
|---------------|-------|------|
| Area          | Cases | Rate |
| Area A        | 120   | 48.2 |
| Area B        | 85    | 39.5 |
| Area C        | 64    | 27.1 |
| Area D        | 19    | 12.9 |

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
