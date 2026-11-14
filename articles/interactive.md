# Interactive charts, tables and apps

This page shows how to make a sortable table, a hover chart and a small
Shiny app in the PHW style. All the data is made up.

Interactive widgets don’t follow
[`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md),
which only changes ggplot2 charts and flextables. Call
[`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md),
[`phw_datatable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_datatable.md)
and
[`phw_plotly()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_plotly.md)
each time you make one. For interactive maps, see [Maps and
boundaries](https://ch3w3y.github.io/phwstyle-r/articles/maps.html#interactive-maps).

``` r

library(phwstyle)
library(dplyr)
library(ggplot2)
set.seed(1)
areas <- paste("Area", LETTERS[1:6])
weekly <- expand.grid(week = 1:12, area = areas[1:3]) |>
  mutate(cases = rpois(n(), 8 + 5 * sin(week / 2) + 3 * as.integer(factor(area))))
areas_tab <- tibble(
  area = areas,
  cases = c(120, 85, 64, 19, 23, 48),
  rate = c(41.2, 22.5, 63.1, 10.4, 25.8, 33.3),
  share = cases / sum(cases),
  completeness = c(97, 91, 78, 99, 66, 88)
)
```

## reactable

[`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md)
styles a data frame with the navy header, striped rows, highlighting and
a compact layout. `caption` sits above the table, and `source` and
`date` sit below it.

``` r

phw_reactable(areas_tab[c("area", "cases", "rate")], caption = "Cases by area",
              source = "Example data", date = "2025-06-30")
```

Cases by area

Source: Example data  
Data correct as of 2025-06-30

Pass any other argument to
[`reactable::reactable()`](https://glin.github.io/reactable/reference/reactable.html).
Your values replace the PHW defaults.

### Column formats

Five helpers make `colDef()` objects for the `columns` argument.

- [`phw_col_bar()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_columns.md)
  draws a bar behind the number, scaled to the column maximum.
- [`phw_col_heat()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_columns.md)
  shades each cell along a sequential palette, and picks black or white
  text to stay readable.
- [`phw_col_rag()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_columns.md)
  colours a value red, amber or green from two `breaks` and adds a shape
  (▼, ■ or ▲), so the status does not rely on colour alone.
- [`phw_col_number()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_columns.md)
  shows a number with thousands separators and `digits` decimal places.
- [`phw_col_percent()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_columns.md)
  shows a proportion as a percentage.

``` r

phw_reactable(
  areas_tab, caption = "Cases by area", source = "Example data",
  columns = list(
    area = reactable::colDef(name = "Area"),
    cases = phw_col_bar(areas_tab, cases, name = "Cases"),
    rate = phw_col_heat(areas_tab, rate, name = "Rate per 100,000"),
    share = phw_col_percent(digits = 0, name = "Share of cases"),
    completeness = phw_col_rag(breaks = c(80, 95), digits = 0, name = "Completeness (%)")
  )
)
```

Cases by area

Source: Example data

`digits` on
[`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md)
sets the decimal places for every other non-integer column, and a column
you format yourself keeps its format.
[`phw_col_number()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_columns.md)
is the way to set the places for one column:

``` r

phw_reactable(areas_tab[c("area", "cases", "rate")], digits = 0,
              columns = list(rate = phw_col_number(digits = 1, name = "Rate")))
```

### Colours that match your charts

Give `group_col` the column that holds the groups, and each cell takes
the colour the same group has in your charts. `key` names the colour
key, as in [Colours and
accessibility](https://ch3w3y.github.io/phwstyle-r/articles/colours.html#colours-that-stay-with-their-groups).

``` r

phw_reactable(areas_tab[c("area", "cases")], group_col = area, key = "area")
```

### Summary tables

A summary table from
[`phw_summary_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_summary_table.md),
[`phw_crosstab()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_crosstab.md),
[`phw_rate_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_rate_table.md)
or
[`phw_risk_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_risk_table.md)
keeps its bold variable rows and indented levels. It shows without
sorting or paging. See
[Tables](https://ch3w3y.github.io/phwstyle-r/articles/tables.html#render-the-same-table-anywhere)
for building one.

``` r

cases <- tibble(
  age_group = sample(c("0-14", "15-44", "45-64", "65+"), 200, replace = TRUE),
  sex = sample(c("Female", "Male"), 200, replace = TRUE),
  outcome = sample(c("Outcome X", "Outcome Y"), 200, replace = TRUE, prob = c(0.8, 0.2))
)
phw_summary_table(cases, by = outcome,
                  labels = list(age_group = "Age group", sex = "Sex")) |>
  phw_reactable(caption = "Characteristics by outcome", source = "Example data")
```

Characteristics by outcome

Source: Example data  
n (%)

### Header style and theme

`header` picks the header style: `"booktabs"` (navy text and rules, the
default), `"navy"` (a navy band with white text) or `"light"` (a light
teal band). `accent` changes the header and rule colour.

[`phw_reactable_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_theme.md)
returns the same theme as a
[`reactable::reactableTheme()`](https://glin.github.io/reactable/reference/reactableTheme.html).
Use it when you call
[`reactable::reactable()`](https://glin.github.io/reactable/reference/reactable.html)
yourself.

``` r

reactable::reactable(areas_tab[c("area", "cases")],
                     theme = phw_reactable_theme(header = "navy", font_size = 16),
                     striped = TRUE)
```

![A reactable table with bars, heat shading and status
cells](../reference/figures/reactable-columns.webp)

A reactable table with bars, heat shading and status cells

## DT

[`phw_datatable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_datatable.md)
gives a searchable, sortable and paged table. It takes `caption`,
`source`, `date` and `digits` like the other renderers. `page_length`
sets the rows per page, and `...` goes to
[`DT::datatable()`](https://rdrr.io/pkg/DT/man/datatable.html).

``` r

phw_datatable(weekly, caption = "Cases by week and area", source = "Example data",
              page_length = 6, filter = "top")
```

Cases by week and area

Source: Example data

Use `options` for DataTables options, such as
`options = list(dom = "t")` to show only the table.

## plotly

[`phw_plotly()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_plotly.md)
styles a plotly chart: PHW colours, the Ubuntu font, a legend under the
chart, and the source line. It takes a ggplot or a plotly object.
`legend` is `"bottom"`, `"right"` or `"none"`. `modebar = FALSE` hides
the tool bar.

### From a ggplot

``` r

g <- ggplot(weekly, aes(week, cases, colour = area)) + geom_line() +
  labs(x = "Week", y = "Cases")
phw_plotly(g, source = "Example data", hovermode = "x")
```

Extra arguments go to `plotly::layout()`, so `hovermode = "x"` above
shows all areas for one week at once. Lists are merged with the PHW
defaults, so `title = list(text = "Cases by week")` keeps the PHW title
style.

### From plot_ly()

``` r

p <- plotly::plot_ly(weekly, x = ~week, y = ~cases, color = ~area,
                     type = "scatter", mode = "lines")
phw_plotly(p, source = "Example data", legend = "right")
```

### Colour keys and colour scales

A plotly chart takes its colours from the `palette` argument unless a
trace sets its own. For colours that stay with a group across charts,
pass the colour key to plotly:

``` r

keyed <- plotly::plot_ly(weekly, x = ~week, y = ~cases, color = ~area,
                         colors = phw_colour_key(weekly$area, "area"),
                         type = "scatter", mode = "lines")
phw_plotly(keyed, source = "Example data")
```

A ggplot keeps the colours of its `scale_colour_phw_d(key = )`.

[`phw_plotly_colorscale()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_plotly_colorscale.md)
turns a PHW palette into a plotly colour scale, for heatmaps and markers
coloured by a number. `reverse = TRUE` flips it and `n` sets the steps.

``` r

heat <- plotly::plot_ly(z = volcano, type = "heatmap",
                        colorscale = phw_plotly_colorscale("teals"))
phw_plotly(heat, source = "Example data")
```

![A plotly line chart in the PHW
style](../reference/figures/plotly.webp)

A plotly line chart in the PHW style

## Shiny and bslib

[`phw_page_navbar()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_page_navbar.md)
builds a complete app page with the PHW header band, a navy navigation
bar and a footer. It takes
[`nav_panel()`](https://rstudio.github.io/bslib/reference/nav-items.html)
tabs like
[`bslib::page_navbar()`](https://rstudio.github.io/bslib/reference/page_navbar.html).
`title` and `subtitle` fill the header, and `footer = FALSE` drops the
footer.

``` r

library(shiny)
library(bslib)
use_phw_ggplot()

ui <- phw_page_navbar(
  title = "Weekly surveillance",
  subtitle = "Team name",
  nav_panel("Overview", card(card_header("Cases by week"), plotOutput("trend"))),
  nav_panel("Data", reactable::reactableOutput("table"))
)

server <- function(input, output, session) {
  output$trend <- renderPlot(
    ggplot(weekly, aes(week, cases, colour = area)) + geom_line() +
      scale_colour_phw_d(key = "area")
  )
  output$table <- reactable::renderReactable(phw_reactable(areas_tab))
}

shinyApp(ui, server)
```

[`phw_bs_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_bs_theme.md)
is the theme behind the page. Use it on any bslib or Shiny page, and add
your own values. They override the PHW ones.

``` r

theme <- phw_bs_theme(primary = "#24A2B5")
phw_page_navbar(title = "Weekly surveillance", theme = theme)
```

`phw_page_navbar(theme = )` takes it, and so do
[`bslib::page()`](https://rstudio.github.io/bslib/reference/page.html)
and `fluidPage(theme = )` in an app of your own.

[`phw_header()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_header.md)
makes only the header band, for a page that doesn’t use
[`phw_page_navbar()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_page_navbar.md).
With `logo = FALSE`, or when the logo isn’t installed, it shows the
organisation name instead. See [Installation and
setup](https://ch3w3y.github.io/phwstyle-r/articles/setup.html#logos).

``` r

phw_header(title = "Weekly surveillance", subtitle = "Team name", logo = FALSE)
```

A working app comes with the package. Run it, and copy it as a starting
point:

``` r

shiny::runApp(system.file("examples", "shiny", package = "phwstyle"))
```

![The example Shiny app with a sidebar, value boxes, a chart and a
table](../reference/figures/shiny.webp)

The example Shiny app with a sidebar, value boxes, a chart and a table

The
[gallery](https://ch3w3y.github.io/phwstyle-r/articles/gallery.html#interactive)
shows more interactive outputs.
