# Neighbour paths

A fix that works for the issue's repro often leaves the same defect one step away, or breaks an input next to it. The next sweep then files that as a new issue. Examples:

- #328 fixed a bottom legend that ran off the chart, and #334 found the same problem with a second legend.
- #330 fixed a gt table that ran off the PDF page, and its fix made a table longer than a page leave page 1 blank (#337).
- #335 fixed the licence line on a half-width map, and #353 found it running off on maps side by side.
- #339 fixed row-name labels being dropped, which caused #352 (`tapply()` labels shown twice) and #365 (row numbers of `rbind()` subsets shown as a column).
- #341 and #342 fixed `phw_plotly()` legends and missing-group colours on single charts, and #355 and #356 found the same defects in `plotly::subplot()`.

A neighbour counts when it fails for the same root cause and a user would hit it in normal use (the bar in the sweep skill's "Normal use only"). For any fix, run the repro, or the call the change touches, through each neighbour below that applies. Then find every caller of each helper you change (`grep -rn "<helper>(" R/`) and run one ordinary call through each caller.

- **Summary builders:** `phw_summary_table()`, `phw_crosstab()`, `phw_group_table()` and `phw_as_summary()`, whose output every renderer takes.
- **Table renderers:** `phw_flextable()`, `phw_gt()`, `phw_reactable()`, `phw_datatable()`, `phw_write_xlsx()`, and the flextable variants `phw_flextable_groups()`, `phw_flextable_heat()` and `phw_flextable_bars()`.
- **Output formats:** the Viewer or HTML (`phw_html_document()`), Word (`phw_word_document()`), PDF (`phw_pdf_document()`), PowerPoint (`phw_pptx()`, `phw_add_slide()`, and a deck knitted with `phw_reference_pptx()`) and saved files (`phw_save()`, `phw_write_xlsx()`).
- **Chart layouts:** a single chart, `phw_finalise()`, `phw_arrange()` and patchwork side by side and stacked, and `phw_save()` at the default size, half a slide and a narrow width.
- **Chart extras:** a second legend (an average line, the epicurve average), a continuous or binned colour legend, a legend one panel turns off, `phw_sec_axis()`, facets and a long caption or source.
- **Interactive charts:** `phw_plotly()` on a ggplot, on the package's own charts (`phw_epicurve()`, `phw_pyramid()`, `phw_funnel()`, `phw_map()`), on `plot_ly()`, on `ggplotly()`, on `plotly::subplot()` and on a `phw_arrange()` figure. Colours from `phw_pal()`, from `phw_colour_key()`, or none. `color` set in `plot_ly()` or in a later `add_*()`.
- **Maps:** `phw_map()` and `phw_leaflet_polygons()` at full and half width, alone and arranged.
- **Input shapes:** a data frame, a tibble, `table()`, a matrix and an sf object. Data frames from `aggregate()` or `tapply()`, from `rbind()` of subsets, and with row names. Factors with unused levels. NA in groups, values and labels. A crosstab with a total row or column, or an NA column.

This list is a start. Add the neighbours the code in hand has.
