# Changelog

## phwstyle 0.3.0

### New charts and maps

- [`phw_forest()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_forest.md)
  draws your own estimates and intervals by unit, sorted by value. With
  `target`, a dashed line marks the target and units are coloured and
  shaped Higher, Similar or Lower. It calculates nothing.
- [`phw_map()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_map.md)
  joins your data to Welsh boundaries by area code and returns a styled
  choropleth for Word and PDF. Fills can be continuous, binned or by
  group, areas with no data are grey, and the boundary attribution is
  the default caption. It works with
  [`facet_wrap()`](https://ggplot2.tidyverse.org/reference/facet_wrap.html).
  Area labels are moved apart when ggrepel is installed.
- [`phw_epicurve()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_epicurve.md)
  gains `average` and `average_label`, which draw a trailing average of
  the total count as a black line with its own legend entry. `$data`
  gains an `average` column. Its default date labels now stay within the
  data, so the last label is no longer cut off.
- [`phw_funnel()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_funnel.md)
  and
  [`phw_spc()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_spc.md)
  gain `labels`, a named vector that renames zones or signals, and pass
  `...` to their points.

### Tables

- [`phw_as_summary()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_as_summary.md)
  gives a table you built yourself, for example with dplyr, the bold
  variable rows, indented levels and total rows of the built-in summary
  tables in every renderer.
- [`phw_datatable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_datatable.md)
  now styles summary tables like
  [`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md):
  bold variable, subtotal and total rows, indented levels, and no paging
  or sorting by default.
- [`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md)
  rounds numbers like the other renderers: whole-number columns show no
  decimals and other numbers show `digits` (default 1), with thousands
  separators.

### Slides

- [`phw_pptx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pptx.md)
  opens a bundled 16:9 PHW template with Ubuntu text and navy titles.
  [`phw_reference_pptx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reference_pptx.md)
  writes it to a file, like
  [`phw_reference_docx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reference_docx.md).
- [`phw_add_slide()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pptx.md)
  gains `alt`, the screen-reader text for the chart or table, and
  `caption_args`. It takes the slide master from the layout, so your own
  templates work.
- [`phw_add_slide()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pptx.md)
  makes charts and tables readable on a slide. Chart text is enlarged
  1.5 times (`plot_scale`), and tables built from a data frame or
  summary grow to fill the content area (`table_fit`). A tall table
  tightens its row spacing so the text can still grow.
- The Quarto extension gains a `phw-pptx` format.

## phwstyle 0.2.0

### Tidyverse-style column arguments

- Functions that take columns now take them the way dplyr does: unquoted
  names, `c(a, b)` for several, and helpers such as
  [`starts_with()`](https://tidyselect.r-lib.org/reference/starts_with.html).
  For example `phw_epicurve(cases, onset, group = organism)` and
  `phw_group_table(dat, rows = c(group, type), cols = year)`. They work
  in a pipe after dplyr verbs, and accept tibbles. This covers
  [`phw_epicurve()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_epicurve.md),
  [`phw_pyramid()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pyramid.md),
  [`phw_funnel()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_funnel.md),
  [`phw_spc()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_spc.md),
  [`phw_summary_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_summary_table.md),
  [`phw_crosstab()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_crosstab.md),
  [`phw_rate_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_rate_table.md),
  [`phw_risk_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_risk_table.md),
  [`phw_group_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_group_table.md),
  [`phw_flextable_heat()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_heat.md),
  [`phw_flextable_groups()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_groups.md),
  [`phw_flextable_bars()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_bars.md),
  `phw_reactable(group_col = )`,
  [`phw_col_bar()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_columns.md),
  [`phw_col_heat()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_columns.md)
  and
  [`phw_leaflet_polygons()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_leaflet.md).
- Code that passes column names as strings keeps working, including
  names held in a variable.
- [`phw_leaflet_polygons()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_leaflet.md)
  labels and popups can be built from columns, e.g.
  `label = paste(name, rate)`.
- phwstyle now imports tidyselect. The examples, vignettes and starter
  documents are written with dplyr and tidyr.

### Requirements

- phwstyle now needs R 4.3 or later (was 4.1). R 4.3 is the oldest
  version for which Windows users can install, without compiling,
  versions of ggplot2, flextable, rmarkdown and the other packages
  phwstyle works with.
- DESCRIPTION states the oldest version of each optional package that
  phwstyle works with.

### New palettes

- `"extended"` now has twelve colours instead of eight: the four
  `"main"` colours; then black, green and gold from the NHS Wales logo
  guidelines and the phw.nhs.wales website; then mint and bright green
  from the Long-Term Strategy; then a blue, a dark green and a violet
  chosen to stay distinct from the rest. Every pair stays apart for
  colour-blind readers. **Charts with five or more groups change
  colour**: the fifth to eighth colours were gold, purple, green and
  grey.
- `"strategy"`: the colours of the six strategic priorities in the
  Long-Term Strategy 2023 to 2035, for work reported by priority.
- `"greens"`: a sequential green palette, from a pale tint to the
  website green, for `scale_*_phw_c()`, `scale_*_phw_b()`, heat tables,
  maps and plotly colour scales.
- New colours in `phw_colours`: `mint` and `green_bright`.

### Changes to default colours

- **The default palette no longer switches to `"accessible"` above four
  groups.** Charts with more than four groups now carry on from `"main"`
  into `"extended"` (navy, teal, orange, pink, then black, green, gold
  and more), so every chart in a report starts with the same colours
  however many groups it has. Before, a five-group chart was drawn in
  the accessible palette next to four-group charts in the main one. This
  applies everywhere groups are coloured: ggplot2 defaults,
  `scale_*_phw_d()`,
  [`phw_epicurve()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_epicurve.md),
  [`phw_colour_key()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_colour_key.md),
  [`phw_pal()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pal.md),
  [`phw_plotly()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_plotly.md),
  [`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md),
  [`phw_flextable_groups()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_groups.md)
  and
  [`phw_leaflet_polygons()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_leaflet.md).
  Charts with five or more groups that relied on the old switch will
  change colour. To keep the colour-blind safe palette, switch it on
  (next item).
- **Accessible colours are now a switch.** Turn it on once and every
  chart, table and widget uses the `"accessible"` palette, for any
  number of groups, so one document can be rendered both ways:
  - R Markdown: new `palette` argument for
    [`phw_html_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md),
    [`phw_word_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md)
    and
    [`phw_pdf_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md),
    e.g.
    `rmarkdown::render("report.Rmd", output_options = list(palette = "accessible"))`.
    The palette is put back when the render finishes.
  - Quarto: `phw-palette: accessible` in the document’s YAML header.
  - Any route: the environment variable `PHWSTYLE_PALETTE=accessible`,
    for switching one render from the command line.
  - `use_phw_ggplot(palette = "accessible")` and
    `options(phwstyle.palette = "accessible")` work as before.

  `theme_phw(accessible = TRUE)` (larger text, thicker lines) is
  separate and unchanged: it doesn’t change colours, and the palette
  switch doesn’t change sizes. See
  [`?phw_default_palette`](https://ch3w3y.github.io/phwstyle-r/reference/phw_default_palette.md).
- Colour keys keep a separate copy for the accessible palette, stored as
  `name@accessible` with the groups in the same order, so a keyed chart
  follows the switch and both versions of a report keep their colours
  between runs. A key used with `palette = "accessible"` before this
  version is carried over.
  [`phw_key_reset()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_key.md)
  clears both copies.
- [`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md)
  now gives the same result on ggplot2 3.5 and 4.0. A layer with no
  colour of its own
  ([`geom_col()`](https://ggplot2.tidyverse.org/reference/geom_bar.html),
  [`geom_line()`](https://ggplot2.tidyverse.org/reference/geom_path.html),
  [`geom_point()`](https://ggplot2.tidyverse.org/reference/geom_point.html)…)
  is navy on both; before, it was navy on 3.5 but grey or near-black on
  4.0. Text, reference lines
  ([`geom_hline()`](https://ggplot2.tidyverse.org/reference/geom_abline.html)
  and friends) and box plot outlines use the PHW text colour, and box
  plots and violins keep a white fill. Line widths, point sizes and text
  sizes now match too, so `accessible = TRUE` thickens lines on ggplot2
  3.5 as well.
- A plot left on the default colours now gets exactly the colours
  `scale_*_phw_d()` would give the same number of groups. Past the end
  of a palette that means spare colours from the other PHW palettes and
  a warning, instead of blended in-between colours.

### Boundaries

- `phw_boundaries("msoa")` and `phw_boundaries("lsoa")` work again. The
  ONS Open Geography Portal stopped publishing the layers they used, so
  both now come from DataMapWales (Welsh Government), with the super
  generalised ONS boundaries as the alternative. MSOAs from DataMapWales
  have no Welsh names, so `name_cy` is missing for them.
- Where a geography is published by more than one source,
  [`phw_boundaries()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundaries.md)
  tries the others if the first cannot be reached, and warns which
  boundaries it returned.
- An area that a source holds as several rows, such as an LSOA with
  islands, is returned as one row.
- [`phw_boundaries()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundaries.md)
  keeps working when a publisher replaces or withdraws a layer after
  phwstyle was installed. If none of the layers it lists can be
  downloaded, it fetches the current list of layers from the phwstyle
  repository and tries those, and failing that returns boundaries saved
  from an earlier release, with a warning in both cases. Set
  `options(phwstyle.boundary_update = FALSE)` to stop it fetching the
  list.
- The list of layers is now checked every week instead of every month. A
  layer is listed only once a test download works, and a new ONS release
  is used once its generalised boundaries are published, so the default
  level of detail is never lost while a release is part way out.

### Fixes for older versions of other packages

- [`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md),
  and so every `phw_*_document()` R Markdown format, no longer fails
  with “Can’t find geom called”histogram”” on ggplot2 older than 4.0.
  The geom defaults are now set one by one, so a geom that an installed
  ggplot2 doesn’t have is skipped.
- On ggplot2 older than 4.0, a plot that mapped a variable to `colour`
  or `fill` and had no scale of its own failed with “argument”n” is
  missing” after
  [`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md),
  which meant most charts in a `phw_*_document()`. The default scales
  are now set up correctly there, and continuous and binned defaults use
  the same blues as on ggplot2 4.0.
- The R Markdown formats no longer stop a whole render if styling the
  charts or the flextables fails. The document is rendered and a warning
  says what was left unstyled and why.
- [`phw_gt()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_gt_theme.md)
  works with gt older than 0.11.1, which doesn’t export
  [`all_of()`](https://tidyselect.r-lib.org/reference/all_of.html).
- [`phw_page_navbar()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_page_navbar.md)
  works with bslib older than 0.9.0, which has no
  [`navbar_options()`](https://rstudio.github.io/bslib/reference/navbar_options.html).
- [`phw_write_xlsx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_write_xlsx.md)
  no longer fails with “Failed to save workbook” on computers where R
  names a zip program that isn’t installed.
- The Quarto `phw-typst` format works with Quarto 1.5 and 1.6. It failed
  there with “unexpected argument: spacing”, and top-level headings came
  out numbered “0.1” and too small.
- [`phw_pdf_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md)
  no longer fails on a document with a flextable when the Ubuntu font is
  not installed on the computer. Tables now use the bundled font, as the
  rest of the document does.

### Other changes

- The ready-made charts
  ([`phw_epicurve()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_epicurve.md),
  [`phw_pyramid()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pyramid.md),
  [`phw_funnel()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_funnel.md),
  [`phw_spc()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_spc.md))
  follow the settings given to
  [`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md),
  such as `base_size = 14` or `accessible = TRUE`. Before, they always
  used the
  [`theme_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw.md)
  defaults.
- [`vignette("phwstyle")`](https://ch3w3y.github.io/phwstyle-r/articles/phwstyle.md)
  has a new section, “How the pieces fit together”: what each function
  switches on, what you still need to add to a plot after setup, and how
  your own scales and theme settings take priority.
- New
  [`phw_sec_axis()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_sec_axis.md)
  draws a second measure against its own axis, on linear and log scales,
  without working out the rescaling by hand.
  [`theme_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw.md)
  spaces the titles of top and right axes like the bottom and left ones.

## phwstyle 0.1.2

- Resubmission to CRAN. The
  [`phw_datatable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_datatable.md)
  example no longer opens a browser when examples are run
  non-interactively.

## phwstyle 0.1.1

- First CRAN submission. Fixes the notes from the automated CRAN checks
  on 0.1.0 (wording in DESCRIPTION and links in the README).

## phwstyle 0.1.0

- First release.
- Brand colours and palettes (`phw_colours`,
  [`phw_pal()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pal.md)),
  with WCAG contrast helpers. Every `palette` argument also takes your
  own colours.
- A colour-blind safe `accessible` palette,
  [`phw_cvd()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_cvd.md),
  [`phw_check_colours()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_check_colours.md),
  [`scale_shape_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/scale_shape_phw.md)
  and
  [`scale_linetype_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/scale_shape_phw.md).
- Colour keys that keep each group’s colour across charts and reports
  ([`phw_colour_key()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_colour_key.md),
  `scale_*_phw_d(key = )`,
  [`phw_key_file()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_key.md)).
- Extension geoms styled automatically
  ([`phw_style_extensions()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_style_extensions.md)),
  and multi-plot figures with
  [`phw_arrange()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_arrange.md)
  and
  [`phw_title_grob()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_title_grob.md).
  [`phw_finalise()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_finalise.md)
  accepts patchworks and grobs.
- Summary tables for reports and epidemiology
  ([`phw_summary_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_summary_table.md),
  [`phw_crosstab()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_crosstab.md),
  [`phw_rate_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_rate_table.md),
  [`phw_risk_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_risk_table.md),
  [`phw_group_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_group_table.md)
  for nested row and column groups with group, subgroup and table
  totals), rendered by
  [`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md)
  and
  [`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md),
  plus column formats
  ([`phw_flextable_bars()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_bars.md),
  [`phw_col_bar()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_columns.md),
  [`phw_col_heat()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_columns.md),
  [`phw_col_rag()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_columns.md)).
- [`phw_plotly()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_plotly.md)
  styles every plotly chart type;
  [`phw_plotly_colorscale()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_plotly_colorscale.md).
- Public health charts:
  [`phw_epicurve()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_epicurve.md),
  [`phw_pyramid()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pyramid.md),
  [`phw_funnel()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_funnel.md)
  and
  [`phw_spc()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_spc.md).
- More outputs: gt
  ([`phw_gt()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_gt_theme.md),
  [`phw_gt_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_gt_theme.md)),
  gtsummary
  ([`use_phw_gtsummary()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_gtsummary.md)),
  DT
  ([`phw_datatable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_datatable.md)),
  leaflet
  ([`phw_leaflet()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_leaflet.md),
  [`phw_leaflet_polygons()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_leaflet.md),
  [`phw_leaflet_palette()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_leaflet.md)),
  Excel
  ([`phw_write_xlsx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_write_xlsx.md))
  and PowerPoint
  ([`phw_pptx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pptx.md),
  [`phw_add_slide()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pptx.md)).
- [`phw_boundaries()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundaries.md)
  downloads and caches boundaries for 13 Welsh geographies from the ONS
  Open Geography Portal and DataMapWales, including health boards and GP
  clusters;
  [`phw_boundary_levels()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundary_levels.md)
  lists them.
- [`phw_setup_check()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_setup_check.md)
  lists missing fonts, packages and tools and offers to install them.
- Bundled Ubuntu font with Arial fallback
  ([`phw_font()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_font.md),
  [`phw_install_fonts()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_install_fonts.md)).
- ggplot2 theme and scales
  ([`theme_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw.md),
  [`theme_phw_map()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw_map.md),
  `scale_*_phw_*()`,
  [`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md),
  [`phw_finalise()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_finalise.md),
  [`phw_save()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_save.md)).
- Tables and widgets:
  [`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md),
  [`phw_flextable_heat()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_heat.md),
  [`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md),
  [`phw_plotly()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_plotly.md).
- Shiny:
  [`phw_bs_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_bs_theme.md),
  [`phw_header()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_header.md),
  [`phw_page_navbar()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_page_navbar.md).
- R Markdown formats:
  [`phw_html_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md),
  [`phw_word_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md),
  [`phw_pdf_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md).
- Quarto extension with HTML, Word, Typst, LaTeX PDF, revealjs and
  dashboard formats
  ([`use_phw_quarto()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_quarto.md)).
- Captions and dates
  ([`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md),
  [`phw_date()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_date.md)),
  with every word changeable.
