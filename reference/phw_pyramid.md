# Population pyramid

Horizontal bars by age group, with one sex on each side of a central
axis. Optionally overlays a comparison population (e.g. Wales overall,
or a previous year) as outlines.

## Usage

``` r
phw_pyramid(
  data,
  age,
  sex,
  value = NULL,
  percent = FALSE,
  left = NULL,
  compare = NULL,
  palette = NULL,
  compare_colour = phw_colours[["black"]],
  ...
)
```

## Arguments

- data:

  A data frame with one row per person, or with a value column.

- age, sex:

  The age and sex columns, unquoted as in dplyr (strings work too).
  `age` should be a factor in age order (or will be sorted as text).

- value:

  Optional column of counts or populations, 0 or more. Rows with a
  missing age, sex or value are left out, with a message.

- percent:

  Show each bar as a percentage of the total, so populations of
  different sizes can be compared?

- left:

  Which `sex` value goes on the left. Defaults to the first level.

- compare:

  Optional data frame with the same columns and the same two `sex`
  values, drawn as outlines. Without `value`, it is counted as one row
  per person too, so to compare cases with a population, count `data` by
  age and sex first and give `value`.

- palette:

  Two colours, or a palette name. Name the colours after the `sex`
  values, as in `c(Female = "#24A2B5", Male = "#285087")`, to choose
  which sex takes which colour.

- compare_colour:

  Outline colour for `compare`.

- ...:

  Passed to
  [`ggplot2::geom_col()`](https://ggplot2.tidyverse.org/reference/geom_bar.html).

## Value

A ggplot.

## Examples

``` r
ages <- c("0-14", "15-29", "30-44", "45-64", "65-79", "80+")
pop <- expand.grid(age = factor(ages, ages), sex = c("Female", "Male"))
pop$n <- c(240, 280, 300, 410, 260, 90, 250, 290, 295, 400, 240, 60) * 1000
phw_pyramid(pop, age, sex, value = n, percent = TRUE)
```
