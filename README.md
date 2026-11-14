# phwstyle

<!-- badges: start -->
[![R-CMD-check](https://github.com/Ch3w3y/phwstyle-r/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Ch3w3y/phwstyle-r/actions/workflows/R-CMD-check.yaml)
[![Docs](https://img.shields.io/badge/docs-pkgdown-285087)](https://ch3w3y.github.io/phwstyle-r/)
<!-- badges: end -->

phwstyle gives the charts, tables, widgets, dashboards, reports and slides you
already make one consistent, accessible house style, based on the Public
Health Wales visual identity. You bring your own numbers and add one function
to style the result. It does not analyse anything.

<p align="center">
  <img src="https://ch3w3y.github.io/phwstyle-r/reference/figures/01-line.webp" width="49%" alt="Line chart with colour and shape by group">
  <img src="https://ch3w3y.github.io/phwstyle-r/reference/figures/table-summary.webp" width="49%" alt="Summary table of characteristics by group">
</p>

## Installation

phwstyle needs R 4.3 or later and ggplot2 3.5 or later. The Quarto formats
need Quarto 1.5 or later. Install it from GitHub:

```r
install.packages("remotes")
remotes::install_github("Ch3w3y/phwstyle-r", dependencies = TRUE)
```

`dependencies = TRUE` also installs the optional packages for every output
type. For faster installs, managed computers and installs that fail, see
[Installation and setup](https://ch3w3y.github.io/phwstyle-r/articles/setup.html).
Run `phwstyle::phw_setup_check()` once afterwards to see what is ready.

## A first chart and a first document

Call `use_phw_ggplot()` once, then write plain ggplot2:

```r
library(phwstyle)
library(ggplot2)

use_phw_ggplot()   # style every chart in the session

ggplot(mpg, aes(displ, hwy, colour = drv)) +
  geom_point() +
  facet_wrap(~year) +
  labs(title = "Engine size and fuel economy",
       caption = phw_caption("ggplot2::mpg"))
```

For a document, name a phwstyle format and everything inside it is styled:

```yaml
output: phwstyle::phw_word_document   # R Markdown
format: phw-typst                     # Quarto, after use_phw_quarto()
```

## What it covers

| Output | Functions | Guide |
|---|---|---|
| ggplot2 | `use_phw_ggplot()`, `theme_phw()`, `scale_colour_phw_d()` and the other scales, `phw_sec_axis()`, `phw_finalise()`, `phw_save()` | [Charts](https://ch3w3y.github.io/phwstyle-r/articles/charts.html) |
| Public health charts | `phw_epicurve()`, `phw_pyramid()`, `phw_funnel()`, `phw_forest()`, `phw_spc()` | [Charts](https://ch3w3y.github.io/phwstyle-r/articles/charts.html#public-health-charts) |
| Extensions and several charts | `phw_style_extensions()`, `phw_arrange()`, `phw_title_grob()` | [Charts](https://ch3w3y.github.io/phwstyle-r/articles/charts.html) |
| Colours and accessibility | `phw_pal()`, `phw_colour_key()`, `phw_default_palette()`, `phw_check_colours()`, `phw_cvd()`, `scale_shape_phw()` | [Colours](https://ch3w3y.github.io/phwstyle-r/articles/colours.html) |
| Summary tables | `phw_summary_table()`, `phw_as_summary()`, `phw_crosstab()`, `phw_rate_table()`, `phw_risk_table()`, `phw_group_table()` | [Tables](https://ch3w3y.github.io/phwstyle-r/articles/tables.html#summary-tables) |
| Word, PDF, HTML tables | `phw_flextable()`, `phw_gt()`, `use_phw_gtsummary()`, `use_phw_flextable()` | [Tables](https://ch3w3y.github.io/phwstyle-r/articles/tables.html#render-the-same-table-anywhere) |
| Maps | `phw_map()`, `phw_boundaries()`, `theme_phw_map()`, `phw_leaflet()`, `phw_leaflet_polygons()` | [Maps](https://ch3w3y.github.io/phwstyle-r/articles/maps.html) |
| Interactive | `phw_reactable()`, `phw_datatable()`, `phw_plotly()`, `phw_bs_theme()`, `phw_page_navbar()` | [Interactive](https://ch3w3y.github.io/phwstyle-r/articles/interactive.html) |
| R Markdown and Quarto | `phw_html_document`, `phw_word_document`, `phw_pdf_document`, `use_phw_quarto()` with `phw-html`, `phw-docx`, `phw-typst`, `phw-pdf`, `phw-revealjs`, `phw-pptx`, `phw-dashboard` | [Reports, slides and dashboards](https://ch3w3y.github.io/phwstyle-r/articles/documents.html) |
| Excel and PowerPoint | `phw_write_xlsx()`, `phw_pptx()` and `phw_add_slide()` (a 16:9 template), `phw_reference_pptx()` | [Excel, PowerPoint and Word](https://ch3w3y.github.io/phwstyle-r/articles/exporting.html) |
| Captions, dates and numbers | `phw_caption()`, `phw_date()`, `phw_number()`, `phw_percent()` | [Charts](https://ch3w3y.github.io/phwstyle-r/articles/charts.html#source-lines-dates-and-numbers) |
| Setup | `phw_setup_check()`, `phw_install_fonts()`, `phw_download_logos()` | [Installation and setup](https://ch3w3y.github.io/phwstyle-r/articles/setup.html) |

[Getting started](https://ch3w3y.github.io/phwstyle-r/articles/phwstyle.html)
walks through one worked example and has a table of
[which function you need](https://ch3w3y.github.io/phwstyle-r/articles/phwstyle.html#which-function-do-i-need)
for each task. Anything you add to a plot wins over the defaults, and every
word phwstyle writes can be replaced, for example with your own Welsh text.

## Gallery

<p align="center">
  <a href="https://ch3w3y.github.io/phwstyle-r/articles/gallery.html"><img src="https://ch3w3y.github.io/phwstyle-r/reference/figures/20-epicurve.webp" width="32%" alt="Epidemic curve by week with stacked groups"></a>
  <a href="https://ch3w3y.github.io/phwstyle-r/articles/gallery.html"><img src="https://ch3w3y.github.io/phwstyle-r/reference/figures/25-forest.webp" width="32%" alt="Forest plot of estimates and intervals against a target"></a>
  <a href="https://ch3w3y.github.io/phwstyle-r/articles/gallery.html"><img src="https://ch3w3y.github.io/phwstyle-r/reference/figures/32-map-facets.webp" width="32%" alt="Choropleth maps of Welsh areas in small multiples"></a>
</p>
<p align="center">
  <a href="https://ch3w3y.github.io/phwstyle-r/articles/gallery.html"><img src="https://ch3w3y.github.io/phwstyle-r/reference/figures/table-nested.webp" width="32%" alt="Table with nested row and column groups and totals"></a>
  <a href="https://ch3w3y.github.io/phwstyle-r/articles/gallery.html"><img src="https://ch3w3y.github.io/phwstyle-r/reference/figures/reactable-columns.webp" width="32%" alt="Interactive table with bar, heat and status columns"></a>
  <a href="https://ch3w3y.github.io/phwstyle-r/articles/gallery.html"><img src="https://ch3w3y.github.io/phwstyle-r/reference/figures/powerpoint.webp" width="32%" alt="PowerPoint slides in the PHW template"></a>
</p>

The [gallery](https://ch3w3y.github.io/phwstyle-r/articles/gallery.html) shows
every kind of output with the functions behind it. All examples use made-up data.
[`examples/phwstyle-demo.R`](https://github.com/Ch3w3y/phwstyle-r/blob/main/examples/phwstyle-demo.R)
builds each output type from one raw data frame.

## Accessibility

* Text colours meet the AA contrast level of the Web Content Accessibility
  Guidelines (WCAG) on white.
* The `accessible` palette stays distinct for colour-blind readers. Turn it on
  once with `use_phw_ggplot(palette = "accessible")` and every chart, table
  and widget uses it. Shape and line type scales add a second cue besides colour.
* HTML outputs keep a visible keyboard focus outline.

See [Colours and accessibility](https://ch3w3y.github.io/phwstyle-r/articles/colours.html).

## Fonts and logos

The Ubuntu typeface is bundled and registered for you. Run
`phw_install_fonts()` once if you use Word, base R graphics or LaTeX on your
own computer. The Public Health Wales logo is a trade mark and is not included.
Point phwstyle at an approved copy, or run `phw_download_logos()`. Without a
logo, every output is still styled and shows the organisation name. Both are
covered in [Installation and setup](https://ch3w3y.github.io/phwstyle-r/articles/setup.html#fonts).

## Licence

Code: MIT. The Ubuntu font is under the Ubuntu Font Licence. This is not an
official Public Health Wales product.
