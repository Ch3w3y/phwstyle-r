# Table renderer traps

- **gt drops attached HTML dependencies.** `gt:::as.tags.gt_tbl()` rebuilds the HTML and loses anything attached with `htmltools::attachDependencies()`. `phw_gt_theme()` adds the class `phw_gt`, whose `as.tags` method attaches `phw_font_dependency()`.
- **htmlwidgets ignore `attachDependencies()`.** An htmlwidget renders from its own `$dependencies` list, so add the font with `w$dependencies <- c(w$dependencies, list(phw_font_dependency()))` (DT, leaflet, reactable, plotly). Test it by saving the page with `htmltools::save_html()` and looking for `phw-ubuntu`.
- **openxlsx2 `wb_add_font()` defaults `size` to 11.** Pass the size every time, or bold rows come out larger than the 10pt body.
- **One row model for all renderers.** `summary_rows()` in R/summaries.R decides shading, bold, italic, navy, rules and indents for every summary and group row. Change the look there, not in one renderer, so the five stay the same.
- **One header model too.** `summary_header()` in R/office.R gives the spanner or the upper header levels as runs, with a `total` flag for grand total columns. DT, xlsx, gt and reactable hide a total's upper labels. flextable keeps them so `merge_v()` joins the total into one tall cell.
- **Red, amber, green:** `rag_status()` in R/flextable.R classifies values for `phw_flextable_heat()` and `phw_col_rag()`.
- **Shading rule:** shade variable and group rows when `attr(x, "highlight") %||% TRUE`.
- To compare all five renderers by eye, render the same inputs through each one and montage the screenshots: HTML via headless Firefox, docx and xlsx via the `phw-lo-writer` image ([[codebase/render-pptx-with-libreoffice]]).
- **DataTables `columnDefs`: earlier definitions win.** DataTables 1.13 reads the array from last to first, so the first definition that sets a property wins. `className` is the exception: classes add up, and `dt-right` beats `dt-left` in the stylesheet. `utils::modifyList()` replaces unnamed lists whole, so join `columnDefs` with `c()`, never through `modifyList()`.
