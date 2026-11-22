# Package index

## Setup

Check what each output needs, and install fonts and logos.

- [`phw_setup_check()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_setup_check.md)
  : Check what phwstyle needs on this computer
- [`phw_install_fonts()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_install_fonts.md)
  : Install the Ubuntu font for your user account
- [`phw_register_fonts()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_register_fonts.md)
  : Register the bundled Ubuntu fonts
- [`phw_font()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_font.md)
  : PHW font family
- [`phw_font_dependency()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_font_dependency.md)
  : HTML dependency that serves the Ubuntu web font
- [`phw_download_logos()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_download_logos.md)
  : Download the PHW logo
- [`phw_has_logo()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_has_logo.md)
  : Does phwstyle have a PHW logo to use?
- [`phw_logo()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_logo.md)
  : Path to a PHW logo file
- [`phw_graphic()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_graphic.md)
  : Path to a PHW brand graphic

## Colours and palettes

Brand colours, palettes, the default palette, and colour keys that keep
each group the same colour across charts and reports.

- [`phw_colours`](https://ch3w3y.github.io/phwstyle-r/reference/phw_colours.md)
  : Public Health Wales brand colours
- [`phw_col()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_col.md)
  : Get PHW colours by name
- [`phw_pal()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pal.md)
  : Get a vector of colours from a PHW palette
- [`phw_pal_fun()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pal_fun.md)
  : Palette functions for scales
- [`phw_palettes`](https://ch3w3y.github.io/phwstyle-r/reference/phw_palettes.md)
  : PHW palettes
- [`phw_default_palette()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_default_palette.md)
  : The default qualitative palette
- [`show_phw_palettes()`](https://ch3w3y.github.io/phwstyle-r/reference/show_phw_palettes.md)
  : Show PHW palettes
- [`phw_colour_key()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_colour_key.md)
  : Fixed colours for groups that stay the same across reports
- [`phw_key()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_key.md)
  [`phw_keys()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_key.md)
  [`phw_key_set()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_key.md)
  [`phw_key_recolour()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_key.md)
  [`phw_key_reset()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_key.md)
  [`phw_key_file()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_key.md)
  : Manage colour keys

## Accessibility

Switch every chart, table and widget to the colour-blind safe palette,
check colours for contrast and colour blindness, and give groups a
second cue besides colour.

- [`phw_check_colours()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_check_colours.md)
  : Check colours for colour-blind readers and contrast
- [`phw_contrast()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_contrast.md)
  : Contrast ratio between two colours
- [`phw_text_on()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_text_on.md)
  : Choose readable text colour for a background
- [`phw_cvd()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_cvd.md)
  : Simulate colour vision deficiency
- [`scale_shape_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/scale_shape_phw.md)
  [`scale_linetype_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/scale_shape_phw.md)
  : Shape and linetype scales for colour-blind readers

## ggplot2 charts

Style every plot with
[`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md),
or one plot with
[`theme_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw.md)
and the PHW scales. Then add a second axis, a logo footer, or save at
report size.

- [`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md)
  : Use PHW styling for every ggplot in the session
- [`theme_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw.md)
  : PHW theme for ggplot2
- [`theme_phw_map()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw_map.md)
  : PHW map theme
- [`scale_colour_phw_d()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
  [`scale_fill_phw_d()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
  [`scale_color_phw_d()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
  [`scale_colour_phw_c()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
  [`scale_fill_phw_c()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
  [`scale_color_phw_c()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
  [`scale_colour_phw_b()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
  [`scale_fill_phw_b()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
  [`scale_color_phw_b()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
  [`scale_fill_phw_div()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
  [`scale_colour_phw_div()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
  [`scale_color_phw_div()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
  : PHW colour and fill scales
- [`phw_sec_axis()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_sec_axis.md)
  : Secondary axis for a second measure
- [`phw_finalise()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_finalise.md)
  : Add the PHW footer (logo and source) to a ggplot
- [`phw_save()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_save.md)
  : Save a PHW chart
- [`phw_style_extensions()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_style_extensions.md)
  : Style geoms from ggplot2 extension packages

## Multi-plot figures

Several charts in one figure with one title and source line.

- [`phw_arrange()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_arrange.md)
  : Arrange several plots in one PHW-styled figure
- [`phw_title_grob()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_title_grob.md)
  : PHW title for gridExtra and cowplot layouts

## Public health charts

Ready-made ggplots for surveillance and quality improvement.

- [`phw_epicurve()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_epicurve.md)
  : Epidemic curve
- [`phw_pyramid()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pyramid.md)
  : Population pyramid
- [`phw_funnel()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_funnel.md)
  : Funnel plot
- [`phw_forest()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_forest.md)
  : Forest plot
- [`phw_spc()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_spc.md)
  : Statistical process control (SPC) chart

## Maps

Boundaries for every level of Welsh geography, and interactive maps.

- [`phw_boundaries()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundaries.md)
  : Boundaries of Welsh areas for maps
- [`phw_boundary_levels()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundary_levels.md)
  : Boundary levels available for Wales
- [`phw_boundaries_cache()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundaries_cache.md)
  : Boundary cache folder
- [`phw_map()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_map.md)
  : Choropleth maps for reports
- [`phw_leaflet()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_leaflet.md)
  [`phw_leaflet_polygons()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_leaflet.md)
  [`phw_leaflet_palette()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_leaflet.md)
  : Interactive maps with leaflet

## Building tables

Build a table once from a data frame, then render it with any table
package.

- [`phw_summary_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_summary_table.md)
  : Summary table of characteristics by group
- [`phw_as_summary()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_as_summary.md)
  : Turn a table you built into a summary table
- [`phw_crosstab()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_crosstab.md)
  : Cross-tabulation of counts
- [`phw_rate_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_rate_table.md)
  : Rates with confidence intervals by group
- [`phw_poisson_ci()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_poisson_ci.md)
  : Exact Poisson confidence interval for a count
- [`phw_risk_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_risk_table.md)
  : Attack rates and relative risks by exposure
- [`phw_group_table()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_group_table.md)
  : Grouped table with nested row and column groups

## flextable (Word, PDF, PowerPoint)

Render a data frame or a summary table as a styled flextable, colour
cells by value or group, and add in-cell bars.

- [`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md)
  : Make a PHW-styled flextable from a data frame
- [`phw_flextable_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_theme.md)
  : Apply PHW styling to a flextable
- [`use_phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_flextable.md)
  : Set PHW defaults for every new flextable
- [`phw_flextable_heat()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_heat.md)
  : Colour flextable cells by value
- [`phw_flextable_bars()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_bars.md)
  : Add in-cell bars to a flextable
- [`phw_flextable_groups()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_groups.md)
  : Colour flextable cells by group

## gt and gtsummary

The same tables rendered with gt, and a theme for every gtsummary table.

- [`phw_gt_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_gt_theme.md)
  [`phw_gt()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_gt_theme.md)
  : PHW style for gt tables
- [`use_phw_gtsummary()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_gtsummary.md)
  : PHW theme for gtsummary

## Interactive HTML

Sortable tables and charts you can hover over, for HTML reports,
dashboards and Shiny. They can’t go in Word or PDF.

- [`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md)
  : Make a PHW-styled reactable
- [`phw_reactable_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_theme.md)
  : PHW theme for reactable
- [`phw_col_bar()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_columns.md)
  [`phw_col_heat()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_columns.md)
  [`phw_col_rag()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_columns.md)
  [`phw_col_number()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_columns.md)
  [`phw_col_percent()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable_columns.md)
  : Column formats for reactable
- [`phw_datatable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_datatable.md)
  : Interactive tables with DT
- [`phw_plotly()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_plotly.md)
  : Apply PHW styling to a plotly chart
- [`phw_plotly_colorscale()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_plotly_colorscale.md)
  : PHW colour scale for plotly

## Excel and PowerPoint

Tables written to Excel sheets, and slides with charts and tables.

- [`phw_write_xlsx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_write_xlsx.md)
  : Write tables to a styled Excel workbook
- [`phw_pptx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pptx.md)
  [`phw_add_slide()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pptx.md)
  : PowerPoint slides with officer

## Captions, dates and numbers

Source lines, dates and number formats written the PHW way. Every word
can be changed.

- [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  : Build a PHW source caption
- [`phw_date()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_date.md)
  : Format a date the PHW way
- [`phw_number()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_number.md)
  [`phw_percent()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_number.md)
  : Number formatting in PHW style

## Documents

R Markdown formats (HTML, Word, PDF), the Quarto extension and the files
behind them.

- [`phw_html_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md)
  [`phw_word_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md)
  [`phw_pdf_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md)
  : PHW R Markdown output formats
- [`use_phw_quarto()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_quarto.md)
  : Add the PHW Quarto extension to a project
- [`phw_reference_docx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reference_docx.md)
  : Path to the PHW Word reference document
- [`phw_reference_pptx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reference_pptx.md)
  : Path to the PHW PowerPoint template
- [`phw_latex_header()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_latex_header.md)
  : Write the PHW LaTeX header to a file

## Shiny and bslib

A Bootstrap theme, header band and complete page for Shiny apps.

- [`phw_bs_theme()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_bs_theme.md)
  : PHW Bootstrap theme for Shiny, R Markdown and Quarto HTML
- [`phw_page_navbar()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_page_navbar.md)
  : A complete PHW Shiny page
- [`phw_header()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_header.md)
  : PHW branded header band for HTML pages

## Package

An overview of the package and its options.

- [`phwstyle`](https://ch3w3y.github.io/phwstyle-r/reference/phwstyle-package.md)
  [`phwstyle-package`](https://ch3w3y.github.io/phwstyle-r/reference/phwstyle-package.md)
  : phwstyle: Public Health Wales styling for R outputs
