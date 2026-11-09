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
