# phwstyle

<!-- badges: start -->
[![R-CMD-check](https://github.com/Ch3w3y/phwstyle-r/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Ch3w3y/phwstyle-r/actions/workflows/R-CMD-check.yaml)
[![Docs](https://img.shields.io/badge/docs-pkgdown-285087)](https://ch3w3y.github.io/phwstyle-r/)
<!-- badges: end -->

phwstyle is a theming toolkit for R. It gives the outputs you already make
(charts, tables, interactive widgets, dashboards, reports and slides) one
consistent, accessible house style, based on the Public Health Wales visual
identity.

You write your analysis as usual, then add one function to style the
result. The same colours, fonts and layout carry across ggplot2, flextable,
reactable, plotly, Shiny, R Markdown and Quarto, so a chart looks the same
in a Word report, an HTML page, a slide deck and a dashboard.

<p align="center">
  <img src="man/figures/01-line.webp" width="49%" alt="Line chart with colour and shape by group">
  <img src="man/figures/table-summary.webp" width="49%" alt="Summary table of characteristics by group">
</p>

## Installation

phwstyle needs R 4.3 or later and ggplot2 3.5 or later. The Quarto formats
need Quarto 1.5 or later.

phwstyle has been submitted to CRAN but is not on CRAN yet. Until it is,
install it from GitHub.

**From CRAN** (once it is accepted):

```r
install.packages("phwstyle", dependencies = TRUE)
```

**Faster binaries from Posit Package Manager (P3M).** Pre-built packages
for Windows and macOS, so nothing compiles. On Linux use the URL for your
distribution from the [P3M setup page](https://packagemanager.posit.co/client/#/repos/cran/setup).

```r
install.packages("phwstyle", dependencies = TRUE,
                 repos = "https://packagemanager.posit.co/cran/latest")
```

**With [uvr](https://nbafrank.github.io/uvr/)**, in a uvr project:

```sh
uvr add phwstyle                 # from CRAN, once accepted
uvr add Ch3w3y/phwstyle-r@main   # development version from GitHub
```

**Development version from GitHub:**

```r
# install.packages("remotes")
remotes::install_github("Ch3w3y/phwstyle-r", dependencies = TRUE)
```

**If the install fails on a managed computer.** The last line of the error
names a file in your Temp folder (`installation of package
'C:/Users/.../Temp/.../phwstyle_0.2.0.tar.gz' had non-zero exit status`).
That is only where R unpacked the download. The cause is a few lines
further up:

* **`LoadLibrary failure: This program is blocked by group policy`**
  (Windows). Your organisation only lets code run from approved folders,
  and the folder R installs packages into is not one of them. Nothing is
  wrong with phwstyle: any package with compiled code fails the same way
  (try `library(rlang)`). Moving the temporary folder or installing from the
  release file does not help. Ask IT which folder is approved for R
  packages, or to approve your R library (shown by `.libPaths()[1]`). If
  they give you a folder, add it to your `.Renviron` file
  (`usethis::edit_r_environ()` opens it) and restart R:

  ```
  R_LIBS_USER=C:/the/approved/folder
  ```

* **"Do you want to install from sources the package which needs
  compilation?"** Answer no. R then uses the ready-built version, which is
  what you want unless Rtools is installed.

* **`'configure' exists but is not executable`** (Linux servers). The
  packages phwstyle depends on compile from source by default, and the
  temporary folder does not allow programs to run. Install the dependencies
  from the P3M repository above, which avoids compiling, or give R a
  temporary folder you control by adding `TMPDIR=/home/your.name/tmp` to
  `.Renviron` (create the folder first).

* **GitHub cannot be reached.** Install the built package from the
  [releases page](https://github.com/Ch3w3y/phwstyle-r/releases) instead
  (change the version to the latest release):

  ```r
  install.packages(c("cli", "ggplot2", "gtable", "htmltools", "rlang",
                     "scales", "systemfonts", "tidyselect", "zip"))
  install.packages(
    "https://github.com/Ch3w3y/phwstyle-r/releases/download/v0.2.0/phwstyle_0.2.0.tar.gz",
    repos = NULL, type = "source")
  ```

A program-blocking policy on its own is not a problem: phwstyle installs
from GitHub when programs and scripts in the Temp folder are blocked, on
R 4.3 and on the current R, and from an account whose name has an accented
letter.

`dependencies = TRUE` also installs the optional packages for every output
type (flextable, reactable, plotly, bslib, ragg...). Then run the setup
check once:

```r
phwstyle::phw_setup_check()
```

It lists what is ready and what is missing (the Ubuntu font on your
computer, the logo, optional packages, Pandoc, Quarto and LaTeX), and offers
to install the missing packages and the font. If you skip it, functions that
need an optional package offer to install it the first time you use them,
and phwstyle reminds you when it loads.

## Getting started

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

For documents, use a phwstyle format and everything inside it is styled:

```yaml
# R Markdown
output: phwstyle::phw_word_document

# Quarto, after running phwstyle::use_phw_quarto() once in the project
format: phw-typst
```

The R Markdown formats style charts and flextables for you. In Quarto, call
`use_phw_ggplot()` (and `use_phw_flextable()`) in the setup chunk.

### Which function do I need?

Set the style once, then write plain ggplot2:

* **Once per document or script:** a `phw_*_document` format or
  `use_phw_ggplot()`. This sets the theme, the PHW colours for groups and
  numbers, navy for bars, lines and points with no colour of their own, and
  the font. It works the same on ggplot2 3.5 and 4.0.
* **On one plot, only to change something:** `theme_phw(grid = "x")`,
  `scale_fill_phw_d(key = "age_group")`, `scale_shape_phw()` and so on.
* **Anything you add to a plot wins** over the defaults: a `scale_*()`, a
  `+ theme()`, or `fill =` in a geom. The house style is a starting point
  you can adjust.

The [getting started guide](https://ch3w3y.github.io/phwstyle-r/articles/phwstyle.html#how-the-pieces-fit-together)
has a table of what each function switches on, and what you still need to
add after setup.

## What it covers

| Output | Functions |
|---|---|
| ggplot2 | `theme_phw()`, `scale_colour_phw_d()` and friends, `scale_shape_phw()`, `use_phw_ggplot()`, `phw_finalise()`, `phw_save()` |
| Public health charts | `phw_epicurve()`, `phw_pyramid()`, `phw_funnel()`, `phw_spc()` |
| ggplot2 extensions | `phw_style_extensions()` restyles geoms from ggalluvial, ggsankey, ggridges, ggrepel, treemapify, ggtext and others |
| Multi-plot figures | `phw_arrange()` (patchwork), `phw_title_grob()` (gridExtra, cowplot) |
| Maps | `phw_boundaries()` downloads and caches boundaries for every Welsh level (health boards, GP clusters, local authorities, Senedd and UK Parliament constituencies, wards, communities, MSOAs, LSOAs, output areas, fire and police areas), `theme_phw_map()` |
| Colours | `phw_pal()`, `phw_colour_key()`, `phw_check_colours()`, `phw_cvd()` |
| Summary tables | `phw_summary_table()`, `phw_crosstab()`, `phw_rate_table()`, `phw_risk_table()`, `phw_group_table()` (nested row and column groups) |
| flextable | `phw_flextable()`, `phw_flextable_theme()`, `phw_flextable_heat()`, `phw_flextable_bars()`, `phw_flextable_groups()` |
| gt and gtsummary | `phw_gt()`, `phw_gt_theme()`, `use_phw_gtsummary()` |
| reactable | `phw_reactable()`, `phw_reactable_theme()`, `phw_col_bar()`, `phw_col_heat()`, `phw_col_rag()` |
| DT | `phw_datatable()` |
| leaflet | `phw_leaflet()`, `phw_leaflet_polygons()`, `phw_leaflet_palette()` |
| Excel and PowerPoint | `phw_write_xlsx()`, `phw_pptx()`, `phw_add_slide()` |
| plotly | `phw_plotly()` for any plotly chart or ggplot, `phw_plotly_colorscale()` |
| Shiny and bslib | `phw_bs_theme()`, `phw_page_navbar()`, `phw_header()` |
| R Markdown | `phw_html_document`, `phw_word_document`, `phw_pdf_document` |
| Quarto | `use_phw_quarto()`, then `phw-html`, `phw-docx`, `phw-typst`, `phw-pdf`, `phw-revealjs`, `phw-dashboard` |

Functions that take columns take them as dplyr does: unquoted, as in
`phw_epicurve(cases, onset, group = organism)`, and they work in a pipe.
Strings work too. Most functions pass extra arguments through to the function they wrap (the
`...` on each help page), so defaults can be overridden, and every `palette` argument also accepts your
own colours.

## Gallery

All examples use made-up data. The images are produced by
[`gallery/build-gallery.R`](https://github.com/Ch3w3y/phwstyle-r/blob/main/gallery/build-gallery.R), and
[`examples/phwstyle-demo.R`](https://github.com/Ch3w3y/phwstyle-r/blob/main/examples/phwstyle-demo.R) is a commented
script that builds every output type from one raw data frame, ready to
copy into your own reports. Full documentation for every function is in the
package help (`?phwstyle`) and the vignettes.

### Charts

<p align="center">
  <img src="man/figures/02-facet-wrap.webp" width="49%" alt="Small multiples with facet_wrap">
  <img src="man/figures/04-facet-grid-dodged.webp" width="49%" alt="Dodged columns with facet_grid">
</p>
<p align="center">
  <img src="man/figures/07-heatmap-diverging.webp" width="49%" alt="Diverging heatmap">
  <img src="man/figures/06-map.webp" width="40%" alt="Choropleth map of Welsh local authorities">
</p>
<p align="center">
  <img src="man/figures/06-boundaries.webp" width="98%" alt="Health boards, GP clusters, Senedd constituencies and MSOAs">
</p>
<p align="center">
  <img src="man/figures/09-finalised.webp" width="49%" alt="Chart with a logo and source footer">
  <img src="man/figures/18-arrange.webp" width="49%" alt="Two charts combined with phw_arrange">
</p>

### Public health charts

<p align="center">
  <img src="man/figures/20-epicurve.webp" width="49%" alt="Epidemic curve by week with stacked groups">
  <img src="man/figures/21-pyramid.webp" width="49%" alt="Population pyramid with a comparison outline">
</p>
<p align="center">
  <img src="man/figures/22-funnel.webp" width="49%" alt="Funnel plot with 95% and 99.8% limits">
  <img src="man/figures/23-spc.webp" width="49%" alt="SPC chart with special cause points">
</p>

### Extension packages

<p align="center">
  <img src="man/figures/14-alluvial.webp" width="49%" alt="Sankey-style flow diagram with ggalluvial">
  <img src="man/figures/15-ridges.webp" width="49%" alt="Ridgeline plot with ggridges">
</p>

### Colour keys and colour-blind readers

Every chart, table and widget draws its groups from one palette: navy,
teal, orange and pink, carrying on into black, green, gold and five more
when there are more than four groups. So a chart with six groups starts with the same
colours as a chart with four. A colour key keeps each group's colour fixed
across charts and reports, so adding a group never reshuffles the others.
`phw_cvd()` shows how any palette looks to colour-blind readers.

<p align="center">
  <img src="man/figures/12-colour-key.webp" width="49%" alt="The same groups keep their colours when a group is added">
  <img src="man/figures/13-accessible.webp" width="49%" alt="Seven groups in the accessible palette">
</p>
<p align="center">
  <img src="man/figures/11-palettes-deutan.webp" width="70%" alt="Palettes as seen with deuteranopia">
</p>

```r
scale_colour_phw_d(key = "age_group")      # fixed colours per group
phw_key_file("phw-colours.csv")            # keep them across reports
phw_check_colours(c("#D50B5C", "#338276")) # test any colours
```

### Accessible colours, when you want them

The `accessible` palette stays distinct for all common types of colour
blindness. It is a switch, not the default: turn it on once and every
chart, table and widget uses it, whatever the number of groups. The same
document can then be rendered both ways.

```r
# A script or a setup chunk
use_phw_ggplot(palette = "accessible")     # or options(phwstyle.palette = "accessible")

# R Markdown: the same document, twice
word <- "phwstyle::phw_word_document"
rmarkdown::render("report.Rmd", word, output_file = "report.docx")
rmarkdown::render("report.Rmd", word, output_file = "report-accessible.docx",
                  output_options = list(palette = "accessible"))
```

```r
# Quarto: the same document, twice (this works on Windows too)
system2("quarto", c("render", "report.qmd", "--to", "phw-docx"))
Sys.setenv(PHWSTYLE_PALETTE = "accessible")
system2("quarto", c("render", "report.qmd", "--to", "phw-docx", "-o", "report-accessible.docx"))
Sys.unsetenv("PHWSTYLE_PALETTE")
```

To switch a document for good, put `palette: accessible` under an R Markdown
format, or `phw-palette: accessible` in the YAML header of a Quarto
document. See `?phw_default_palette`.

### Tables

Summary and epidemiology tables are built once, then rendered with
flextable (Word, PDF, HTML) or reactable (interactive HTML).

<p align="center">
  <img src="man/figures/table-rates.webp" width="49%" alt="Rates with exact confidence intervals by demographic group">
  <img src="man/figures/table-risk.webp" width="49%" alt="Attack rates and relative risks by exposure">
</p>
<p align="center">
  <img src="man/figures/table-crosstab.webp" width="49%" alt="Cross-tabulation with heat colours">
  <img src="man/figures/table-rag.webp" width="40%" alt="RAG status table with shapes">
</p>
<p align="center">
  <img src="man/figures/table-nested.webp" width="58%" alt="Nested row and column groups with group totals">
  <img src="man/figures/table-nested-columns.webp" width="38%" alt="Groups in separate columns with totals below each group">
</p>

<p align="center">
  <img src="man/figures/gt-table.webp" width="49%" alt="Grouped table rendered with gt">
  <img src="man/figures/gtsummary.webp" width="40%" alt="gtsummary table with the PHW theme">
</p>

### Interactive

<p align="center">
  <img src="man/figures/reactable-columns.webp" width="49%" alt="reactable with bar, heat and RAG columns">
  <img src="man/figures/plotly-donut.webp" width="49%" alt="plotly donut chart">
</p>
<p align="center">
  <img src="man/figures/plotly-subplot.webp" width="49%" alt="plotly box plot and lines in one figure">
  <img src="man/figures/shiny.webp" width="49%" alt="Shiny app with header band, value boxes and cards">
</p>
<p align="center">
  <img src="man/figures/leaflet.webp" width="40%" alt="leaflet map of health boards">
  <img src="man/figures/dt.webp" width="49%" alt="Searchable DT table">
</p>

### Excel and PowerPoint

<p align="center">
  <img src="man/figures/powerpoint.webp" width="98%" alt="Three PowerPoint slides: bullet points, chart and table">
</p>
<p align="center">
  <img src="man/figures/excel.webp" width="49%" alt="Excel sheet with a grouped table">
</p>

### Documents, slides and dashboards

<p align="center">
  <img src="man/figures/quarto-typst-1.webp" width="24%" alt="PDF report cover">
  <img src="man/figures/quarto-typst-2.webp" width="24%" alt="PDF report page">
  <img src="man/figures/rmd-word-1.webp" width="24%" alt="Word report page">
  <img src="man/figures/quarto-latex-2.webp" width="24%" alt="LaTeX PDF report page">
</p>
<p align="center">
  <img src="man/figures/slides-1.webp" width="49%" alt="Title slide">
  <img src="man/figures/slides-3.webp" width="49%" alt="Chart slide">
</p>
<p align="center">
  <img src="man/figures/dashboard.webp" width="80%" alt="Quarto dashboard">
</p>

## Accessibility

Outputs are designed to be read by the public:

* Text colours meet the WCAG AA contrast standard on white. The four `main`
  chart colours and every `accessible` colour meet the 3:1 contrast rule
  for graphics. Three of the later `extended` colours (gold, mint and
  bright green) do not, so they suit filled bars better than thin lines.
* The `accessible` and `rag_accessible` palettes stay distinct for colour-blind
  readers, and shape, line type and symbol scales give a second cue besides
  colour. The accessible palette is switched on with `palette = "accessible"`
  (see above); it is not used by default.
* `use_phw_ggplot(accessible = TRUE)` or `theme_phw(accessible = TRUE)` uses
  larger text and thicker lines. This is separate from the palette: use
  either or both.
* HTML outputs keep a visible keyboard focus outline.

## Fonts

The Ubuntu typeface is bundled and registered automatically for ragg,
svglite and Office outputs, with Arial as a fallback. For LaTeX PDFs, base
graphics devices and Word on your own computer, run `phw_install_fonts()`
once.

## Logos

The Public Health Wales logo is a trade mark and is not included in the
package. Point phwstyle at an approved copy with
`options(phwstyle.logo_dir = ...)`, or run `phw_download_logos()` once to
save the logo from phw.nhs.wales to your cache folder. Without a logo, every
output is still styled and shows the organisation name instead. The
examples on this page are shown without the logo. See `inst/COPYRIGHTS`.

## Licence

Code: MIT. The Ubuntu font is under the Ubuntu Font Licence. This is not an
official Public Health Wales product.
