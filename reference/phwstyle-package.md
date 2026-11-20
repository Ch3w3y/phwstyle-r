# phwstyle: Public Health Wales styling for R outputs

phwstyle gives the outputs you already make one consistent, accessible
house style. Write your analysis as usual, then add one function to
style the result.

## Getting started

- [`phw_setup_check()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_setup_check.md)
  lists the fonts, packages and tools each output needs, and offers to
  install what is missing.

- [`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md)
  styles every ggplot in the session.

- [`vignette("phwstyle")`](https://ch3w3y.github.io/phwstyle-r/articles/phwstyle.md)
  explains how the pieces fit together (what is set once for a document,
  what is added to one chart, and how your own changes take priority),
  then walks through each output type. The script
  `examples/phwstyle-demo.R` in the source repository runs them all from
  one raw data frame.

- The website, <https://ch3w3y.github.io/phwstyle-r/>, has a guide for
  charts, colours, tables, maps, documents and exports, and a gallery of
  every kind of output.

## Charts

[`theme_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw.md),
[`theme_phw_map()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw_map.md),
the `scale_*_phw_*()` colour and fill scales,
[`scale_shape_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/scale_shape_phw.md),
[`scale_linetype_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/scale_shape_phw.md),
[`phw_sec_axis()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_sec_axis.md),
[`phw_finalise()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_finalise.md),
[`phw_save()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_save.md),
[`phw_arrange()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_arrange.md),
[`phw_style_extensions()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_style_extensions.md),
and public health charts:
[`phw_epicurve()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_epicurve.md),
[`phw_pyramid()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pyramid.md),
[`phw_funnel()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_funnel.md)
and
[`phw_spc()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_spc.md).

## Colours and accessibility

[phw_colours](https://ch3w3y.github.io/phwstyle-r/reference/phw_colours.md),
[`phw_pal()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pal.md)
and the palettes in
[phw_palettes](https://ch3w3y.github.io/phwstyle-r/reference/phw_palettes.md)
(including `strategy` for the Long-Term Strategy priorities and
`greens`),
[`phw_colour_key()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_colour_key.md)
(colours that stay with their groups across reports),
[`phw_default_palette()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_default_palette.md)
(switching everything to the colour-blind safe `accessible` palette),
[`phw_check_colours()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_check_colours.md)
and
[`phw_cvd()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_cvd.md).

## Tables

Build with
[`phw_summary_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_summary_table.md),
[`phw_crosstab()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_crosstab.md),
[`phw_rate_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_rate_table.md),
[`phw_risk_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_risk_table.md)
or
[`phw_group_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_group_table.md),
then render with
[`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md)
(Word, PDF),
[`phw_gt()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_gt_theme.md),
[`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md),
[`phw_datatable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_datatable.md)
or
[`phw_write_xlsx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_write_xlsx.md)
(Excel).
[`use_phw_gtsummary()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_gtsummary.md)
styles gtsummary tables.

## Maps

[`phw_boundaries()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundaries.md)
downloads boundaries for every level of Welsh geography;
[`phw_leaflet()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_leaflet.md)
makes interactive maps.

## Documents, slides and apps

R Markdown formats
([`phw_html_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md),
[`phw_word_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md),
[`phw_pdf_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md)),
the Quarto extension
([`use_phw_quarto()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_quarto.md)),
PowerPoint
([`phw_pptx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pptx.md),
[`phw_add_slide()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pptx.md)),
and Shiny
([`phw_bs_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_bs_theme.md),
[`phw_page_navbar()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_page_navbar.md),
[`phw_header()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_header.md)).

## Options

- `phwstyle.palette`: default palette name, e.g. `"accessible"` for the
  colour-blind safe palette in every chart, table and widget. The
  environment variable `PHWSTYLE_PALETTE` and `phw-palette` in a
  document's YAML header do the same; see
  [`phw_default_palette()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_default_palette.md).

- `phwstyle.font`: font family to use instead of Ubuntu.

- `phwstyle.logo_dir`: folder with your own logo files.

- `phwstyle.boundary_dir`: where downloaded boundaries are cached.

- `phwstyle.boundary_update`: `FALSE` stops
  [`phw_boundaries()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundaries.md)
  checking for a newer list of boundary layers.

- `phwstyle.boundary_list_url`: the address of that list. Point it at
  your own copy of `boundaries.csv` if your network blocks GitHub.

- `phwstyle.quiet`: `TRUE` hides the startup reminder.

## See also

Useful links:

- <https://ch3w3y.github.io/phwstyle-r/>

- <https://github.com/Ch3w3y/phwstyle-r>

- Report bugs at <https://github.com/Ch3w3y/phwstyle-r/issues>

## Author

**Maintainer**: Daryn Sutton <cheweych3w3y@gmail.com>

Authors:

- Daryn Sutton <cheweych3w3y@gmail.com>

Other contributors:

- Canonical Ltd (Ubuntu font family, Ubuntu Font Licence 1.0)
  \[copyright holder\]
