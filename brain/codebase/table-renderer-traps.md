# Table renderer traps

- **gt drops attached HTML dependencies.** `gt:::as.tags.gt_tbl()` rebuilds the HTML and loses anything attached with `htmltools::attachDependencies()`. `phw_gt_theme()` adds the class `phw_gt`, whose `as.tags` method attaches `phw_font_dependency()`.
- **openxlsx2 `wb_add_font()` defaults `size` to 11.** Pass the size every time, or bold rows come out larger than the 10pt body.
- **One row model for all renderers.** `summary_rows()` in R/summaries.R decides shading, bold, italic, navy, rules and indents for every summary and group row. Change the look there, not in one renderer, so the five stay the same.
- **Shading rule:** shade variable and group rows when `attr(x, "highlight") %||% TRUE`.
- To compare all five renderers by eye, render the same inputs through each one and montage the screenshots: HTML via headless Firefox, docx and xlsx via the `phw-lo-writer` image ([[codebase/render-pptx-with-libreoffice]]).
