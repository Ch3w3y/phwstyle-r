# phwstyle (development version)

## New charts and maps

* `phw_forest()` draws your own estimates and intervals by unit, sorted by
  value. With `target`, a dashed line marks the target and units are
  coloured and shaped Higher, Similar or Lower. It calculates nothing.
* `phw_map()` joins your data to Welsh boundaries by area code and returns a
  styled choropleth for Word and PDF. Fills can be continuous, binned or
  by group, areas with no data are grey, and the boundary attribution is the
  default caption. It works with `facet_wrap()`.
* `phw_epicurve()` gains `average` and `average_label`, which draw a
  trailing average of the total count as a black line with its own legend
  entry. `$data` gains an `average` column.
* `phw_funnel()` and `phw_spc()` gain `labels`, a named vector that renames
  zones or signals, and pass `...` to their points.

## Tables

* `phw_as_summary()` gives a table you built yourself, for example with
  dplyr, the bold variable rows, indented levels and total rows of the
  built-in summary tables in every renderer.
* `phw_datatable()` now styles summary tables like `phw_reactable()`: bold
  variable, subtotal and total rows, indented levels, and no paging or
  sorting by default.

## Slides

* `phw_pptx()` opens a bundled 16:9 PHW template with Ubuntu text and navy
  titles. `phw_reference_pptx()` writes it to a file, like
  `phw_reference_docx()`.
* `phw_add_slide()` gains `alt`, the screen-reader text for the chart or
  table, and `caption_args`. It takes the slide master from the layout, so
  your own templates work.
* The Quarto extension gains a `phw-pptx` format.

# phwstyle 0.2.0

## Tidyverse-style column arguments

* Functions that take columns now take them the way dplyr does: unquoted
  names, `c(a, b)` for several, and helpers such as `starts_with()`. For
  example `phw_epicurve(cases, onset, group = organism)` and
  `phw_group_table(dat, rows = c(group, type), cols = year)`. They work in a
  pipe after dplyr verbs, and accept tibbles. This covers `phw_epicurve()`,
  `phw_pyramid()`, `phw_funnel()`, `phw_spc()`, `phw_summary_table()`,
  `phw_crosstab()`, `phw_rate_table()`, `phw_risk_table()`,
  `phw_group_table()`, `phw_flextable_heat()`, `phw_flextable_groups()`,
  `phw_flextable_bars()`, `phw_reactable(group_col = )`, `phw_col_bar()`,
  `phw_col_heat()` and `phw_leaflet_polygons()`.
* Code that passes column names as strings keeps working, including names
  held in a variable.
* `phw_leaflet_polygons()` labels and popups can be built from columns, e.g.
  `label = paste(name, rate)`.
* phwstyle now imports tidyselect. The examples, vignettes and starter
  documents are written with dplyr and tidyr.

## Requirements

* phwstyle now needs R 4.3 or later (was 4.1). R 4.3 is the oldest version
  for which Windows users can install, without compiling, versions of
  ggplot2, flextable, rmarkdown and the other packages phwstyle works with.
* DESCRIPTION states the oldest version of each optional package that
  phwstyle works with.

## New palettes

* `"extended"` now has twelve colours instead of eight: the four `"main"`
  colours; then black, green and gold from the NHS Wales logo guidelines and
  the phw.nhs.wales website; then mint and bright green from the Long-Term
  Strategy; then a blue, a dark green and a violet chosen to stay distinct
  from the rest. Every pair stays apart for colour-blind readers. **Charts
  with five or more groups change colour**: the fifth to eighth colours were
  gold, purple, green and grey.
* `"strategy"`: the colours of the six strategic priorities in the
  Long-Term Strategy 2023 to 2035, for work reported by priority.
* `"greens"`: a sequential green palette, from a pale tint to the website
  green, for `scale_*_phw_c()`, `scale_*_phw_b()`, heat tables, maps and
  plotly colour scales.
* New colours in `phw_colours`: `mint` and `green_bright`.

## Changes to default colours

* **The default palette no longer switches to `"accessible"` above four
  groups.** Charts with more than four groups now carry on from `"main"`
  into `"extended"` (navy, teal, orange, pink, then black, green, gold and more), so
  every chart in a report starts with the same colours however many groups
  it has. Before, a five-group chart was drawn in the accessible palette
  next to four-group charts in the main one. This applies everywhere groups
  are coloured: ggplot2 defaults, `scale_*_phw_d()`, `phw_epicurve()`,
  `phw_colour_key()`, `phw_pal()`, `phw_plotly()`, `phw_reactable()`,
  `phw_flextable_groups()` and `phw_leaflet_polygons()`. Charts with five or
  more groups that relied on the old switch will change colour. To keep the
  colour-blind safe palette, switch it on (next item).
* **Accessible colours are now a switch.** Turn it on once and every chart,
  table and widget uses the `"accessible"` palette, for any number of
  groups, so one document can be rendered both ways:
  * R Markdown: new `palette` argument for `phw_html_document()`,
    `phw_word_document()` and `phw_pdf_document()`, e.g.
    `rmarkdown::render("report.Rmd", output_options = list(palette = "accessible"))`.
    The palette is put back when the render finishes.
  * Quarto: `phw-palette: accessible` in the document's YAML header.
  * Any route: the environment variable `PHWSTYLE_PALETTE=accessible`, for
    switching one render from the command line.
  * `use_phw_ggplot(palette = "accessible")` and
    `options(phwstyle.palette = "accessible")` work as before.

  `theme_phw(accessible = TRUE)` (larger text, thicker lines) is separate
  and unchanged: it doesn't change colours, and the palette switch doesn't
  change sizes. See `?phw_default_palette`.
* Colour keys keep a separate copy for the accessible palette, stored as
  `name@accessible` with the groups in the same order, so a keyed chart
  follows the switch and both versions of a report keep their colours
  between runs. A key used with `palette = "accessible"` before this
  version is carried over. `phw_key_reset()` clears both copies.
* `use_phw_ggplot()` now gives the same result on ggplot2 3.5 and 4.0. A
  layer with no colour of its own (`geom_col()`, `geom_line()`,
  `geom_point()`...) is navy on both; before, it was navy on 3.5 but grey
  or near-black on 4.0. Text, reference lines (`geom_hline()` and friends)
  and box plot outlines use the PHW text colour, and box plots and violins
  keep a white fill. Line widths, point sizes and text sizes now match too,
  so `accessible = TRUE` thickens lines on ggplot2 3.5 as well.
* A plot left on the default colours now gets exactly the colours
  `scale_*_phw_d()` would give the same number of groups. Past the end of a
  palette that means spare colours from the other PHW palettes and a
  warning, instead of blended in-between colours.

## Boundaries

* `phw_boundaries("msoa")` and `phw_boundaries("lsoa")` work again. The ONS
  Open Geography Portal stopped publishing the layers they used, so both now
  come from DataMapWales (Welsh Government), with the super generalised ONS
  boundaries as the alternative. MSOAs from DataMapWales have no Welsh
  names, so `name_cy` is missing for them.
* Where a geography is published by more than one source,
  `phw_boundaries()` tries the others if the first cannot be reached, and
  warns which boundaries it returned.
* An area that a source holds as several rows, such as an LSOA with
  islands, is returned as one row.
* `phw_boundaries()` keeps working when a publisher replaces or withdraws a
  layer after phwstyle was installed. If none of the layers it lists can be
  downloaded, it fetches the current list of layers from the phwstyle
  repository and tries those, and failing that returns boundaries saved from
  an earlier release, with a warning in both cases. Set
  `options(phwstyle.boundary_update = FALSE)` to stop it fetching the list.
* The list of layers is now checked every week instead of every month. A
  layer is listed only once a test download works, and a new ONS release is
  used once its generalised boundaries are published, so the default level
  of detail is never lost while a release is part way out.

## Fixes for older versions of other packages

* `use_phw_ggplot()`, and so every `phw_*_document()` R Markdown format, no
  longer fails with "Can't find geom called "histogram"" on ggplot2 older
  than 4.0. The geom defaults are now set one by one, so a geom that an
  installed ggplot2 doesn't have is skipped.
* On ggplot2 older than 4.0, a plot that mapped a variable to `colour` or
  `fill` and had no scale of its own failed with "argument "n" is missing"
  after `use_phw_ggplot()`, which meant most charts in a `phw_*_document()`.
  The default scales are now set up correctly there, and continuous and
  binned defaults use the same blues as on ggplot2 4.0.
* The R Markdown formats no longer stop a whole render if styling the
  charts or the flextables fails. The document is rendered and a warning
  says what was left unstyled and why.
* `phw_gt()` works with gt older than 0.11.1, which doesn't export
  `all_of()`.
* `phw_page_navbar()` works with bslib older than 0.9.0, which has no
  `navbar_options()`.
* `phw_write_xlsx()` no longer fails with "Failed to save workbook" on
  computers where R names a zip program that isn't installed.
* The Quarto `phw-typst` format works with Quarto 1.5 and 1.6. It failed
  there with "unexpected argument: spacing", and top-level headings came out
  numbered "0.1" and too small.
* `phw_pdf_document()` no longer fails on a document with a flextable when
  the Ubuntu font is not installed on the computer. Tables now use the
  bundled font, as the rest of the document does.

## Other changes

* The ready-made charts (`phw_epicurve()`, `phw_pyramid()`, `phw_funnel()`,
  `phw_spc()`) follow the settings given to `use_phw_ggplot()`, such as
  `base_size = 14` or `accessible = TRUE`. Before, they always used the
  `theme_phw()` defaults.
* `vignette("phwstyle")` has a new section, "How the pieces fit together":
  what each function switches on, what you still need to add to a plot
  after setup, and how your own scales and theme settings take priority.
* New `phw_sec_axis()` draws a second measure against its own axis, on linear
  and log scales, without working out the rescaling by hand. `theme_phw()`
  spaces the titles of top and right axes like the bottom and left ones.

# phwstyle 0.1.2

* Resubmission to CRAN. The `phw_datatable()` example no longer opens a
  browser when examples are run non-interactively.

# phwstyle 0.1.1

* First CRAN submission. Fixes the notes from the automated CRAN checks on
  0.1.0 (wording in DESCRIPTION and links in the README).

# phwstyle 0.1.0

* First release.
* Brand colours and palettes (`phw_colours`, `phw_pal()`), with WCAG contrast
  helpers. Every `palette` argument also takes your own colours.
* A colour-blind safe `accessible` palette, `phw_cvd()`, `phw_check_colours()`,
  `scale_shape_phw()` and `scale_linetype_phw()`.
* Colour keys that keep each group's colour across charts and reports
  (`phw_colour_key()`, `scale_*_phw_d(key = )`, `phw_key_file()`).
* Extension geoms styled automatically (`phw_style_extensions()`), and
  multi-plot figures with `phw_arrange()` and `phw_title_grob()`.
  `phw_finalise()` accepts patchworks and grobs.
* Summary tables for reports and epidemiology (`phw_summary_table()`,
  `phw_crosstab()`, `phw_rate_table()`, `phw_risk_table()`,
  `phw_group_table()` for nested row and column groups with group, subgroup
  and table totals), rendered by
  `phw_flextable()` and `phw_reactable()`, plus column formats
  (`phw_flextable_bars()`, `phw_col_bar()`, `phw_col_heat()`, `phw_col_rag()`).
* `phw_plotly()` styles every plotly chart type; `phw_plotly_colorscale()`.
* Public health charts: `phw_epicurve()`, `phw_pyramid()`, `phw_funnel()` and
  `phw_spc()`.
* More outputs: gt (`phw_gt()`, `phw_gt_theme()`), gtsummary
  (`use_phw_gtsummary()`), DT (`phw_datatable()`), leaflet (`phw_leaflet()`,
  `phw_leaflet_polygons()`, `phw_leaflet_palette()`), Excel
  (`phw_write_xlsx()`) and PowerPoint (`phw_pptx()`, `phw_add_slide()`).
* `phw_boundaries()` downloads and caches boundaries for 13 Welsh geographies
  from the ONS Open Geography Portal and DataMapWales, including health boards
  and GP clusters; `phw_boundary_levels()` lists them.
* `phw_setup_check()` lists missing fonts, packages and tools and offers to
  install them.
* Bundled Ubuntu font with Arial fallback (`phw_font()`, `phw_install_fonts()`).
* ggplot2 theme and scales (`theme_phw()`, `theme_phw_map()`,
  `scale_*_phw_*()`, `use_phw_ggplot()`, `phw_finalise()`, `phw_save()`).
* Tables and widgets: `phw_flextable()`, `phw_flextable_heat()`,
  `phw_reactable()`, `phw_plotly()`.
* Shiny: `phw_bs_theme()`, `phw_header()`, `phw_page_navbar()`.
* R Markdown formats: `phw_html_document()`, `phw_word_document()`,
  `phw_pdf_document()`.
* Quarto extension with HTML, Word, Typst, LaTeX PDF, revealjs and dashboard
  formats (`use_phw_quarto()`).
* Captions and dates (`phw_caption()`, `phw_date()`), with every word
  changeable.
