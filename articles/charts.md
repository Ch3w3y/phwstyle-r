# Charts

``` r

library(phwstyle)
library(ggplot2)
library(dplyr)
use_phw_ggplot()
set.seed(1)
n <- 4000
days <- seq(as.Date("2023-01-02"), as.Date("2025-12-28"), by = "day")
winter <- 1 + 0.8 * cos(2 * pi * (as.integer(format(days, "%j")) - 20) / 365)
age <- round(100 * rbeta(n, 2, 1.8))
cases <- tibble(
  onset = sample(days, n, replace = TRUE, prob = winter),
  age = age,
  age_band = cut(age, c(seq(0, 90, 5), Inf), right = FALSE,
                 labels = c(paste(seq(0, 85, 5), seq(4, 89, 5), sep = "-"), "90+")),
  age_group = cut(age, c(0, 15, 25, 45, 65, 80, Inf), right = FALSE,
                  labels = c("0-14", "15-24", "25-44", "45-64", "65-79", "80+")),
  sex = sample(c("Female", "Male"), n, replace = TRUE),
  setting = sample(paste("Setting", 1:6), n, replace = TRUE, prob = c(0.35, 0.2, 0.15, 0.12, 0.1, 0.08)),
  organism = sample(paste("Type", 1:5), n, replace = TRUE, prob = c(0.4, 0.25, 0.15, 0.12, 0.08))
)
```

All data on this page is made up.

This page shows the ggplot2 helpers and the ready-made public health
charts, each with code you can copy.

## Setting the style

[`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md)
sets
[`theme_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw.md),
the PHW colours for groups and numbers, and navy for layers with no
colour of their own, for every plot in the session. It styles extension
geoms too. Everything below is plain ggplot2. A theme or scale is added
to a plot only to change something. The [getting started
guide](https://ch3w3y.github.io/phwstyle-r/articles/phwstyle.html#how-the-pieces-fit-together)
lists what is covered and what you still need to add.

[`theme_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw.md)
takes the settings you most often change. `grid` picks the gridlines,
`legend` moves or removes the legend, and `accessible = TRUE` makes text
larger and lines thicker for one plot.

``` r

cases |>
  count(setting) |>
  ggplot(aes(n, reorder(setting, n))) +
  geom_col(width = 0.7) +
  labs(title = "Cases by setting", x = "Cases", y = NULL) +
  theme_phw(grid = "x", legend = "none", accessible = TRUE)
```

![Horizontal bars of cases by setting, with vertical gridlines and no
legend.](charts_files/figure-html/unnamed-chunk-3-1.png)

## Colour scales

A discrete scale colours groups from the `main` palette, then carries on
into `extended`. Give it a `key` and each group keeps its colour in
every chart. [Colours and
accessibility](https://ch3w3y.github.io/phwstyle-r/articles/colours.html#colours-that-stay-with-their-groups)
covers keys and palettes, and [colour-blind safe
colours](https://ch3w3y.github.io/phwstyle-r/articles/colours.html#colour-blind-safe-colours)
covers the `accessible` palette and the shape and line type scales.

``` r

ggplot(cases, aes(age_group, fill = setting)) +
  geom_bar() +
  scale_fill_phw_d(key = "setting") +
  labs(title = "Cases by age group and setting", x = NULL, y = "Cases",
       caption = phw_caption("Example data"))
```

![Stacked bars of cases by age group, coloured by setting in navy, teal
and orange.](charts_files/figure-html/unnamed-chunk-4-1.png)

Numbers need a continuous scale.
[`scale_fill_phw_c()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
and
[`scale_colour_phw_c()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
blend a sequential palette such as `blues`, `teals` or `greens`.

``` r

grid <- tidyr::expand_grid(week = 1:52, age_group = levels(cases$age_group)) |>
  mutate(age_group = factor(age_group, levels = levels(cases$age_group)),
         cases = rpois(n(), 6 + (25 * exp(-((week - 8) / 6)^2) + 18 * exp(-((week - 40) / 5)^2)) * as.integer(age_group) / 3))
ggplot(grid, aes(week, age_group, fill = cases)) +
  geom_tile(colour = "white") +
  scale_fill_phw_c(palette = "blues") +
  labs(title = "Cases by week and age group", x = "Week", y = NULL, fill = "Cases") +
  theme_phw(grid = "none", legend = "right", legend_title = TRUE)
```

![A grid of tiles for 52 weeks and six age groups, shaded from light to
dark blue by case count, with darker patches around weeks 8 and
40.](charts_files/figure-html/unnamed-chunk-5-1.png)

[`scale_fill_phw_b()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
and
[`scale_colour_phw_b()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
cut the numbers into bins, so each colour stands for a range. This suits
maps and any chart where readers compare bands.

``` r

ggplot(grid, aes(week, age_group, fill = cases)) +
  geom_tile(colour = "white") +
  scale_fill_phw_b(palette = "teals", n.breaks = 5) +
  labs(title = "The same counts in bands", x = "Week", y = NULL, fill = "Cases") +
  theme_phw(grid = "none", legend = "right", legend_title = TRUE)
```

![Tiles for 52 weeks and six age groups shaded in bands by case count,
with a legend that lists each
band.](charts_files/figure-html/unnamed-chunk-6-1.png)

[`scale_fill_phw_div()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
and
[`scale_colour_phw_div()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
use two colours that meet at a pale midpoint, `0` unless you set
`midpoint`. They suit values above and below a reference, such as change
from last year.

``` r

change <- tibble(area = sprintf("Area %02d", 1:22), change = round(rnorm(22, 0, 8), 1))
ggplot(change, aes(change, reorder(area, change), fill = change)) +
  geom_col(width = 0.75) +
  scale_fill_phw_div(guide = "none") +
  labs(title = "Change in rate since last year", x = "Percentage points", y = NULL) +
  theme_phw(grid = "x")
```

![Horizontal bars of change in rate for 22 areas, sorted from lowest to
highest, orange below zero and navy above
zero.](charts_files/figure-html/unnamed-chunk-7-1.png)

Each scale has a `colour` version for points and lines, and a `color`
spelling that is the same function. The top row of this figure uses the
`colour` spellings and the bottom row uses `color`.

``` r

pts <- tibble(x = runif(400), y = runif(400), group = sample(c("A", "B", "C"), 400, TRUE)) |>
  mutate(value = 25 * (x - 0.5) + rnorm(400, 0, 6))
dots <- function(colour_aes, title) {
  ggplot(pts, aes(x, y, colour = {{ colour_aes }})) +
    geom_point(size = 1.8, alpha = 0.8) + labs(title = title, x = NULL, y = NULL) +
    theme_phw(legend = "right")
}
phw_arrange(
  dots(group, "colour, groups") + scale_colour_phw_d(),
  dots(value, "colour, numbers") + scale_colour_phw_c(),
  dots(value, "colour, bands") + scale_colour_phw_b(n.breaks = 4),
  dots(group, "color, groups") + scale_color_phw_d(),
  dots(value, "color, numbers") + scale_color_phw_c(),
  dots(value, "color, bands") + scale_color_phw_b(n.breaks = 4),
  ncol = 3, guides = "keep"
)
```

![Six scatter plots in two rows of three, with points coloured by group,
by number and by number
bands.](charts_files/figure-html/unnamed-chunk-8-1.png)

``` r

ggplot(pts, aes(x, y, colour = value)) +
  geom_point(size = 1.8, alpha = 0.8) +
  scale_colour_phw_div() +
  labs(title = "Diverging colour scale", x = NULL, y = NULL) +
  theme_phw(legend = "right")
```

![Points coloured orange below zero and navy above zero, using the
diverging colour scale.](charts_files/figure-html/unnamed-chunk-9-1.png)

``` r

ggplot(pts, aes(x, y, colour = value)) +
  geom_point(size = 1.8, alpha = 0.8) +
  scale_color_phw_div() +
  labs(title = "Same scale, other spelling", x = NULL, y = NULL) +
  theme_phw(legend = "right")
```

![Points coloured orange below zero and navy above zero, using the
American spelling of the diverging
scale.](charts_files/figure-html/unnamed-chunk-10-1.png)

## A second measure on its own axis

[`phw_sec_axis()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_sec_axis.md)
returns a secondary axis for a second measure. Its `$rescale()` function
maps that measure onto the scale of the first axis. Wrap the second
measure in `$rescale()` and give the same object to `sec.axis`.
Colouring the secondary axis to match its series helps readers see which
axis belongs to which.

``` r

wk <- tibble(week = 1:104) |>
  mutate(cases = rpois(n(), 30 + 400 * exp(-((week - 20) / 8)^2) + 250 * exp(-((week - 72) / 10)^2)),
         positivity = pmax(1, 3 + 24 * exp(-((week - 22) / 9)^2) + 16 * exp(-((week - 74) / 11)^2) +
                             rnorm(n(), 0, 1)))
orange <- phw_col("orange")

sec <- phw_sec_axis(wk$cases, wk$positivity, name = "Positivity (%)")
ggplot(wk, aes(week)) +
  geom_col(aes(y = cases), fill = phw_col("navy"), width = 0.85) +
  geom_line(aes(y = sec$rescale(positivity)), colour = orange, linewidth = 1) +
  scale_y_continuous("Cases", sec.axis = sec) +
  labs(title = "Cases and positivity by week", x = "Week") +
  theme_phw(axis.title.y.right = element_text(colour = orange),
            axis.text.y.right = element_text(colour = orange))
```

![Navy columns of weekly cases over two years with an orange line of
positivity, read against a second axis on the right. Both peak
twice.](charts_files/figure-html/unnamed-chunk-11-1.png)

On a log axis, say so with `scale = "log"` and use
[`scale_y_log10()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html):

``` r

sec <- phw_sec_axis(wk$cases, wk$positivity, name = "Positivity (%)", scale = "log")
ggplot(wk, aes(week)) +
  geom_line(aes(y = cases), colour = phw_col("navy")) +
  geom_line(aes(y = sec$rescale(positivity)), colour = orange) +
  scale_y_log10("Cases", sec.axis = sec) +
  labs(title = "The same measures on log axes", x = "Week") +
  theme_phw(axis.title.y.right = element_text(colour = orange),
            axis.text.y.right = element_text(colour = orange))
```

![Two lines on log axes, navy for cases on the left axis and orange for
positivity on the right
axis.](charts_files/figure-html/unnamed-chunk-12-1.png)

## Public health charts

These functions draw a whole chart from your data, in the PHW style.
Each returns a ggplot, so you can add
[`labs()`](https://ggplot2.tidyverse.org/reference/labs.html), scales
and themes as usual. The
[gallery](https://ch3w3y.github.io/phwstyle-r/articles/gallery.html#public-health)
shows more of them.

### Epidemic curve

[`phw_epicurve()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_epicurve.md)
counts events by day, week, month, quarter or year and draws them as
columns, with zero for periods that have no cases. Give it one row per
case, or a `count` column. `group` stacks the columns by a second
variable, and `interval` changes the period.

``` r

phw_epicurve(cases, onset, group = organism) +
  labs(title = "Cases by week of onset", x = "Week beginning", y = "Cases")
```

![Weekly columns of cases over three years with a winter peak each year,
stacked in five colours by organism
type.](charts_files/figure-html/unnamed-chunk-13-1.png)

`average` adds a trailing average of the total count over that many
periods, as a black line with its own legend entry. `average_label`
replaces the legend text, for example with your own wording in another
language.

``` r

phw_epicurve(cases, onset, average = 4) +
  labs(title = "Cases by week of onset", x = "Week beginning", y = "Cases")
```

![Weekly navy columns of cases with a black line for the 4-week average
and a legend entry for the
line.](charts_files/figure-html/unnamed-chunk-14-1.png)

``` r

phw_epicurve(cases, onset, average = 4, average_label = "Rolling four-week mean") +
  labs(title = "Cases by week of onset", x = "Week beginning", y = "Cases")
```

![The same average line with its legend text replaced by a label that
reads Rolling four-week
mean.](charts_files/figure-html/unnamed-chunk-15-1.png)

### Population pyramid

[`phw_pyramid()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pyramid.md)
draws counts by age group on the vertical axis, with one sex on each
side. `percent = TRUE` shows each bar as a share of the total, which
lets you compare groups of different sizes. `compare` draws a second
data frame with the same columns as outlines.

``` r

phw_pyramid(cases, age_band, sex, percent = TRUE) +
  labs(title = "Cases by age and sex")
```

![A pyramid of cases in 19 five-year age bands from 0-4 to 90+, with
females on one side and males on the other, shown as
percentages.](charts_files/figure-html/unnamed-chunk-16-1.png)

``` r

last_year <- cases |> slice_sample(prop = 0.8)
phw_pyramid(cases, age_band, sex, percent = TRUE, compare = last_year) +
  labs(title = "Cases by age and sex, with last year outlined")
```

![A pyramid of this year's cases in five-year age bands with black
outlines showing last year's cases for
comparison.](charts_files/figure-html/unnamed-chunk-17-1.png)

### Funnel plot

[`phw_funnel()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_funnel.md)
plots each unit’s proportion or rate against its denominator, between
control limits that narrow as the denominator grows. Points outside the
limits are coloured and shaped, and labelled when you give `label`. The
limits are the normal approximation around the target, which
[`?phw_funnel`](https://ch3w3y.github.io/phwstyle-r/reference/phw_funnel.md)
describes.

``` r

units <- tibble(area = sprintf("Area %03d", 1:150), eligible = round(rlnorm(150, 7.5, 0.8))) |>
  mutate(events = rbinom(n(), eligible, c(rep(0.72, 146), 0.66, 0.78, 0.65, 0.79)))
phw_funnel(units, events, eligible, label = area) +
  labs(title = "Proportion by area", x = "Population", y = "Proportion (%)")
```

![A funnel plot of proportion against population for 150 areas, with two
pairs of limits and a few labelled points outside
them.](charts_files/figure-html/unnamed-chunk-18-1.png)

To replace the words in the legend, give `labels` a named vector. The
names are the default zone text and the values are your replacements.
Each zone keeps its colour and shape. Pass the same names with your own
text, for example in Welsh.

``` r

phw_funnel(units, events, eligible, label = area,
           labels = c("Within limits" = "Inside the limits")) +
  labs(title = "Proportion by area", x = "Population", y = "Proportion (%)")
```

![The same funnel plot with the within-limits zone renamed to Inside the
limits in the legend.](charts_files/figure-html/unnamed-chunk-19-1.png)

### Forest plot

[`phw_forest()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_forest.md)
draws estimates and intervals you have already calculated, one row per
unit, sorted by value. The chunk below makes up the numbers so you can
run it. With `target`, units whose whole interval lies above or below it
are coloured and shaped Higher or Lower, and the rest Similar.

``` r

areas <- tibble(area = sprintf("Area %02d", 1:22), rate = round(runif(22, 40, 90), 1)) |>
  mutate(lower = rate - round(runif(22, 4, 12), 1), upper = rate + round(runif(22, 4, 12), 1))
phw_forest(areas, rate, lower, upper, label = area, target = 65) +
  labs(title = "Rate by area", x = "Rate per 100,000",
       colour = "Compared with Wales", shape = "Compared with Wales")
```

![A forest plot of 22 areas sorted by rate, with intervals, a dashed
target line, and areas coloured Higher, Similar or
Lower.](charts_files/figure-html/unnamed-chunk-20-1.png)

`labels` renames the three comparison levels. The names are `Higher`,
`Similar` and `Lower`, and the values are your own text.

``` r

phw_forest(areas, rate, lower, upper, label = area, target = 65,
           labels = c(Higher = "Above target", Similar = "Close to target",
                      Lower = "Below target")) +
  labs(title = "Rate by area", x = "Rate per 100,000",
       colour = "Compared with target", shape = "Compared with target")
```

![The same forest plot with the comparison levels renamed to Above
target, Close to target and Below
target.](charts_files/figure-html/unnamed-chunk-21-1.png)

### Control chart

[`phw_spc()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_spc.md)
draws an XmR chart or, with `type = "run"`, a run chart. It colours
points that show special cause variation. `improvement` says which
direction is better, so signals in the good direction are blue and those
in the bad direction are orange. `baseline` sets how many of the first
points fix the centre line and limits.

``` r

weekly <- tibble(week = seq(as.Date("2023-01-02"), by = "week", length.out = 130),
                 value = c(rnorm(52, 50, 4), rnorm(78, 50, 4) + c(rep(0, 20), rep(6, 58))))
phw_spc(weekly, week, value, improvement = "increase", baseline = 52) +
  labs(title = "Weekly measure")
```

![A control chart of a weekly measure over 130 weeks with a centre line,
process limits, and points coloured where the measure shifts
upward.](charts_files/figure-html/unnamed-chunk-22-1.png)

`labels` works as it does for the funnel plot. The names are the default
signal text and the values replace them.

``` r

phw_spc(weekly, week, value, improvement = "increase", baseline = 52,
        labels = c("Common cause" = "Within normal variation")) +
  labs(title = "Weekly measure")
```

![The same control chart with the common cause signal renamed to Within
normal variation in the
legend.](charts_files/figure-html/unnamed-chunk-23-1.png)

## Extension packages

Packages such as ggrepel and ggridges draw geoms with their own
defaults.
[`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md)
styles the ones that are loaded. If you load a package after calling it,
run
[`phw_style_extensions()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_style_extensions.md)
again.

``` r

library(ggrepel)
phw_style_extensions()
areas |>
  mutate(population = round(runif(n(), 20, 200))) |>
  ggplot(aes(population, rate, label = area)) +
  geom_point(colour = phw_col("navy"), size = 2) +
  geom_text_repel(max.overlaps = Inf) +
  labs(title = "Rate by population", x = "Population (thousands)", y = "Rate per 100,000")
```

![Labelled points of rate against population for 22 areas, with text in
the PHW font and no
overlaps.](charts_files/figure-html/unnamed-chunk-24-1.png)

``` r

library(ggridges)
phw_style_extensions()
cases |>
  mutate(score = rnorm(n(), 40 + 5 * as.integer(age_group), 8)) |>
  ggplot(aes(score, age_group, fill = age_group)) +
  geom_density_ridges(alpha = 0.85) +
  scale_fill_phw_d(guide = "none") +
  labs(title = "Distribution of a score by age group", x = "Score", y = NULL)
```

![Overlapping distributions of a score for six age groups, filled in
navy, teal, orange, pink, green and
gold.](charts_files/figure-html/unnamed-chunk-25-1.png)

## Several charts in one figure

[`phw_arrange()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_arrange.md)
joins plots with patchwork, adds a title, a source line and panel tags,
and merges identical legends into one.

``` r

a <- ggplot(cases, aes(y = setting)) + geom_bar() + labs(x = "Cases", y = NULL)
b <- phw_epicurve(cases, onset, interval = "month") + labs(y = "Cases")
phw_arrange(a, b, widths = c(1, 2), title = "Two charts, one title", source = "Example data",
            tag_levels = "A")
```

![A bar chart of cases by setting beside an epicurve by month over three
years, under one title, with panel tags A and B and a source
line.](charts_files/figure-html/unnamed-chunk-26-1.png)

If you build the figure with gridExtra instead,
[`phw_title_grob()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_title_grob.md)
makes a title in the same style to put above it.

``` r

panel <- gridExtra::arrangeGrob(a, b, ncol = 2, widths = c(1, 2))
fig <- gridExtra::arrangeGrob(
  phw_title_grob("Two charts, one title", "Joined with gridExtra"),
  panel, heights = c(1, 8)
)
grid::grid.newpage()
grid::grid.draw(fig)
```

![Two charts side by side under a navy title and a subtitle, joined with
gridExtra.](charts_files/figure-html/unnamed-chunk-27-1.png)

## Source lines, dates and numbers

[`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
builds the source line for `labs(caption = )`. Add a date and it writes
“Data correct as of” and the date. The words in front of the source and
the date are arguments, so you can replace them with your own text. Use
`sep = " | "` for a single line.

``` r

phw_caption("Example data", date = as.Date("2026-11-03"))
#> [1] "Source: Example data\nData correct as of 03/11/2026"
phw_caption("Example data", date = as.Date("2026-11-03"),
            source_prefix = "Data: ", date_prefix = "As of ", sep = " | ")
#> [1] "Data: Example data | As of 03/11/2026"
```

[`phw_date()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_date.md)
formats a date as dd/mm/yyyy, or in words with `style = "long"`, or with
any [`format()`](https://rdrr.io/r/base/format.html) string.
[`phw_number()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_number.md)
and
[`phw_percent()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_number.md)
return labelling functions for axes. They take the arguments of
[`scales::label_number()`](https://scales.r-lib.org/reference/label_number.html)
and
[`scales::label_percent()`](https://scales.r-lib.org/reference/label_percent.html).

``` r

phw_date(as.Date("2026-11-03"))
#> [1] "03/11/2026"
phw_date(as.Date("2026-11-03"), "long")
#> [1] "3 November 2026"
phw_number()(c(1200, 45000, 1250000))
#> [1] "1,200"     "45,000"    "1,250,000"
phw_percent()(c(0.052, 0.4, 0.875))
#> [1] "5.2%"  "40.0%" "87.5%"
```

``` r

age_totals <- cases |>
  count(age_group) |>
  mutate(cases = n * 100, share = n / sum(n))
a1 <- ggplot(age_totals, aes(age_group, cases)) +
  geom_col(width = 0.7) +
  scale_y_continuous(labels = phw_number()) +
  labs(title = "Cases", x = NULL, y = NULL)
a2 <- ggplot(age_totals, aes(age_group, share)) +
  geom_col(width = 0.7) +
  scale_y_continuous(labels = phw_percent(accuracy = 1)) +
  labs(title = "Share of cases", x = NULL, y = NULL)
phw_arrange(a1, a2, source = "Example data")
```

![Columns of cases by age group with thousands separators on the left
axis, and a line of the percentage of cases with percent
labels.](charts_files/figure-html/unnamed-chunk-30-1.png)

## Finishing and saving

[`phw_finalise()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_finalise.md)
adds a rule, the logo, the source and the date under a chart (or a
patchwork, or any grob). The logo appears once you have downloaded the
logos, which [Installation and
setup](https://ch3w3y.github.io/phwstyle-r/articles/setup.html#logos)
explains.
[`phw_save()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_save.md)
saves the result with the bundled font.
[`phw_finalise()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_finalise.md)
passes `source_prefix` and `date_prefix` on to
[`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md),
so you can replace those words here too.

``` r

p <- phw_epicurve(cases, onset) + labs(title = "Cases by week", x = "Week beginning", y = "Cases")
fin <- phw_finalise(p, source = "Example data", date = as.Date("2026-11-03"))
grid::grid.newpage()
grid::grid.draw(fin)
```

![An epicurve with a navy rule and a source line and date
underneath.](charts_files/figure-html/unnamed-chunk-31-1.png)

``` r

phw_save(fin, "epicurve.png")
```
