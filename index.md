# phwstyle

phwstyle gives the charts, tables, widgets, dashboards, reports and
slides you already make one consistent, accessible house style, based on
the Public Health Wales visual identity. You bring your own numbers and
add one function to style the result. It does not analyse anything.

![Line chart with colour and shape by
group](https://ch3w3y.github.io/phwstyle-r/reference/figures/01-line.webp)![Summary
table of characteristics by
group](https://ch3w3y.github.io/phwstyle-r/reference/figures/table-summary.webp)

## Installation

phwstyle needs R 4.3 or later and ggplot2 3.5 or later. The Quarto
formats need Quarto 1.5 or later. Install it from GitHub:

``` r

install.packages("remotes")
remotes::install_github("Ch3w3y/phwstyle-r", dependencies = TRUE)
```

`dependencies = TRUE` also installs the optional packages for every
output type. For faster installs, managed computers and installs that
fail, see [Installation and
setup](https://ch3w3y.github.io/phwstyle-r/articles/setup.html). Run
[`phwstyle::phw_setup_check()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_setup_check.md)
once afterwards to see what is ready.

## A first chart and a first document

Call
[`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md)
once, then write plain ggplot2:

``` r

library(phwstyle)
library(ggplot2)

use_phw_ggplot()   # style every chart in the session

ggplot(mpg, aes(displ, hwy, colour = drv)) +
  geom_point() +
  facet_wrap(~year) +
  labs(title = "Engine size and fuel economy",
       caption = phw_caption("ggplot2::mpg"))
```

For a document, name a phwstyle format and everything inside it is
styled:

``` yaml
output: phwstyle::phw_word_document   # R Markdown
format: phw-typst                     # Quarto, after use_phw_quarto()
```

## What it covers

| Output | Functions | Guide |
|----|----|----|
| ggplot2 | [`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md), [`theme_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw.md), [`scale_colour_phw_d()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md) and the other scales, [`phw_sec_axis()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_sec_axis.md), [`phw_finalise()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_finalise.md), [`phw_save()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_save.md) | [Charts](https://ch3w3y.github.io/phwstyle-r/articles/charts.html) |
| Public health charts | [`phw_epicurve()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_epicurve.md), [`phw_pyramid()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pyramid.md), [`phw_funnel()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_funnel.md), [`phw_forest()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_forest.md), [`phw_spc()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_spc.md) | [Charts](https://ch3w3y.github.io/phwstyle-r/articles/charts.html#public-health-charts) |
| Extensions and several charts | [`phw_style_extensions()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_style_extensions.md), [`phw_arrange()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_arrange.md), [`phw_title_grob()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_title_grob.md) | [Charts](https://ch3w3y.github.io/phwstyle-r/articles/charts.html) |
| Colours and accessibility | [`phw_pal()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pal.md), [`phw_colour_key()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_colour_key.md), [`phw_default_palette()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_default_palette.md), [`phw_check_colours()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_check_colours.md), [`phw_cvd()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_cvd.md), [`scale_shape_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/scale_shape_phw.md) | [Colours](https://ch3w3y.github.io/phwstyle-r/articles/colours.html) |
| Summary tables | [`phw_summary_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_summary_table.md), [`phw_as_summary()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_as_summary.md), [`phw_crosstab()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_crosstab.md), [`phw_rate_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_rate_table.md), [`phw_risk_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_risk_table.md), [`phw_group_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_group_table.md) | [Tables](https://ch3w3y.github.io/phwstyle-r/articles/tables.html#summary-tables) |
| Word, PDF, HTML tables | [`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md), [`phw_gt()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_gt_theme.md), [`use_phw_gtsummary()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_gtsummary.md), [`use_phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_flextable.md) | [Tables](https://ch3w3y.github.io/phwstyle-r/articles/tables.html#render-the-same-table-anywhere) |
| Maps | [`phw_map()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_map.md), [`phw_boundaries()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundaries.md), [`theme_phw_map()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw_map.md), [`phw_leaflet()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_leaflet.md), [`phw_leaflet_polygons()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_leaflet.md) | [Maps](https://ch3w3y.github.io/phwstyle-r/articles/maps.html) |
| Interactive | [`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md), [`phw_datatable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_datatable.md), [`phw_plotly()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_plotly.md), [`phw_bs_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_bs_theme.md), [`phw_page_navbar()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_page_navbar.md) | [Interactive](https://ch3w3y.github.io/phwstyle-r/articles/interactive.html) |
| R Markdown and Quarto | `phw_html_document`, `phw_word_document`, `phw_pdf_document`, [`use_phw_quarto()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_quarto.md) with `phw-html`, `phw-docx`, `phw-typst`, `phw-pdf`, `phw-revealjs`, `phw-pptx`, `phw-dashboard` | [Reports, slides and dashboards](https://ch3w3y.github.io/phwstyle-r/articles/documents.html) |
| Excel and PowerPoint | [`phw_write_xlsx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_write_xlsx.md), [`phw_pptx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pptx.md) and [`phw_add_slide()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pptx.md) (a 16:9 template), [`phw_reference_pptx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reference_pptx.md) | [Excel, PowerPoint and Word](https://ch3w3y.github.io/phwstyle-r/articles/exporting.html) |
| Captions, dates and numbers | [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md), [`phw_date()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_date.md), [`phw_number()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_number.md), [`phw_percent()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_number.md) | [Charts](https://ch3w3y.github.io/phwstyle-r/articles/charts.html#source-lines-dates-and-numbers) |
| Setup | [`phw_setup_check()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_setup_check.md), [`phw_install_fonts()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_install_fonts.md), [`phw_download_logos()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_download_logos.md) | [Installation and setup](https://ch3w3y.github.io/phwstyle-r/articles/setup.html) |

[Getting
started](https://ch3w3y.github.io/phwstyle-r/articles/phwstyle.html)
walks through one worked example and has a table of [which function you
need](https://ch3w3y.github.io/phwstyle-r/articles/phwstyle.html#which-function-do-i-need)
for each task. Anything you add to a plot wins over the defaults, and
every word phwstyle writes can be replaced, for example with your own
Welsh text.

## Gallery

[![Epidemic curve by week with stacked
groups](https://ch3w3y.github.io/phwstyle-r/reference/figures/20-epicurve.webp)](https://ch3w3y.github.io/phwstyle-r/articles/gallery.html)
[![Forest plot of estimates and intervals against a
target](https://ch3w3y.github.io/phwstyle-r/reference/figures/25-forest.webp)](https://ch3w3y.github.io/phwstyle-r/articles/gallery.html)
[![Choropleth maps of Welsh areas in small
multiples](https://ch3w3y.github.io/phwstyle-r/reference/figures/32-map-facets.webp)](https://ch3w3y.github.io/phwstyle-r/articles/gallery.html)

[![Table with nested row and column groups and
totals](https://ch3w3y.github.io/phwstyle-r/reference/figures/table-nested.webp)](https://ch3w3y.github.io/phwstyle-r/articles/gallery.html)
[![Interactive table with bar, heat and status
columns](https://ch3w3y.github.io/phwstyle-r/reference/figures/reactable-columns.webp)](https://ch3w3y.github.io/phwstyle-r/articles/gallery.html)
[![PowerPoint slides in the PHW
template](https://ch3w3y.github.io/phwstyle-r/reference/figures/powerpoint.webp)](https://ch3w3y.github.io/phwstyle-r/articles/gallery.html)

The [gallery](https://ch3w3y.github.io/phwstyle-r/articles/gallery.html)
shows every kind of output with the functions behind it. All examples
use made-up data.
[`examples/phwstyle-demo.R`](https://github.com/Ch3w3y/phwstyle-r/blob/main/examples/phwstyle-demo.R)
builds each output type from one raw data frame.

## Accessibility

- Text colours meet the AA contrast level of the Web Content
  Accessibility Guidelines (WCAG) on white.
- The `accessible` palette stays distinct for colour-blind readers. Turn
  it on once with `use_phw_ggplot(palette = "accessible")` and every
  chart, table and widget uses it. Shape and line type scales add a
  second cue besides colour.
- HTML outputs keep a visible keyboard focus outline.

See [Colours and
accessibility](https://ch3w3y.github.io/phwstyle-r/articles/colours.html).

## Fonts and logos

The Ubuntu typeface is bundled and registered for you. Run
[`phw_install_fonts()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_install_fonts.md)
once if you use Word, base R graphics or LaTeX on your own computer. The
Public Health Wales logo is a trade mark and is not included. Point
phwstyle at an approved copy, or run
[`phw_download_logos()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_download_logos.md).
Without a logo, every output is still styled and shows the organisation
name. Both are covered in [Installation and
setup](https://ch3w3y.github.io/phwstyle-r/articles/setup.html#fonts).

## Licence

Code: MIT. The Ubuntu font is under the Ubuntu Font Licence. This is not
an official Public Health Wales product.
