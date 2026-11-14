# Write vignettes/articles/gallery.Rmd from the list of gallery items below.
# Run from the package root after gallery/build-gallery.R and after copying
# the images into man/figures (as .webp):
#   Rscript gallery/build-gallery-page.R
#
# Each item has:
#   file   image name in man/figures (without .webp)
#   title  short name
#   desc   one or two sentences: what it shows and when to use it
#   type   one of the keys of `types` below (drives the badge and the filter)
#   pkgs   packages used, besides phwstyle
#   fns    phwstyle functions used; each links to its reference page
#   args   optional: arguments worth noticing, shown as code

types <- list(
  chart = list(label = "Static chart",
               where = "RStudio Plots pane; saved as PNG, SVG or PDF; works in every report format"),
  map = list(label = "Static map",
             where = "RStudio Plots pane; saved as PNG, SVG or PDF; works in every report format"),
  table = list(label = "Report table",
               where = "RStudio Viewer; Word, PowerPoint, HTML and PDF reports"),
  widget = list(label = "Interactive (HTML)",
                where = "RStudio Viewer pane, a web browser, HTML reports, Quarto dashboards and Shiny. Not Word or PDF"),
  document = list(label = "Document template",
                  where = "Rendered from an .Rmd or .qmd file"),
  office = list(label = "Office file",
                where = "Written straight to .xlsx or .pptx; open in Excel or PowerPoint")
)

item <- function(file, title, desc, type, pkgs = "ggplot2", fns = character(), args = NULL) {
  list(file = file, title = title, desc = desc, type = type, pkgs = pkgs, fns = fns, args = args)
}

sections <- list(
  list(id = "charts", title = "Everyday charts",
       intro = "Standard ggplot2 charts. Call `use_phw_ggplot()` once at the top of a script and every chart after it gets the PHW theme, font and colours; the scale functions pick colours from PHW palettes.",
       items = list(
         item("01-line", "Lines with shapes", "Several groups over time. Shapes give a second cue for readers who can't tell the colours apart, and the colour key keeps each group's colour the same in every chart.", "chart",
              fns = c("use_phw_ggplot", "scale_colour_phw_d", "scale_shape_phw"), args = 'key = "gallery_groups"'),
         item("03-bar-horizontal", "Horizontal bars with labels", "Ranked values for named areas. Horizontal bars leave room for long names; only vertical gridlines are drawn.", "chart",
              fns = c("theme_phw", "phw_col"), args = 'theme_phw(grid = "x")'),
         item("04-facet-grid-dodged", "Grouped columns in a grid", "Two series side by side, split into panels with `facet_grid()`, with a dashed target line and navy panel strips.", "chart",
              fns = c("theme_phw", "phw_percent"), args = 'theme_phw(strip = "navy")'),
         item("05-stacked-100", "100% stacked bars", "Shares of a whole by year. A level called \"Unknown\" (or \"Missing\", \"Not known\") is drawn grey automatically.", "chart",
              fns = c("scale_fill_phw_d", "phw_percent")),
         item("27-stacked-area", "Stacked area", "Counts by group over time. Uses the same colour key as the line chart, so Group 1 is the same colour in both.", "chart",
              fns = c("scale_fill_phw_d"), args = 'key = "gallery_groups"'),
         item("28-bar-line", "Bars with a rolling average", "Daily counts as bars with a 7-day average line on top, each with its own legend entry.", "chart",
              fns = "phw_epicurve", args = "average = 7"),
         item("26-scatter", "Scatter with a continuous colour", "Two measures against each other, with a fitted line and a third measure as colour.", "chart",
              fns = c("scale_colour_phw_c")),
         item("02-facet-wrap", "Small multiples", "One small panel per area with `facet_wrap()`. The theme styles the panel strips.", "chart",
              fns = c("theme_phw", "phw_col")),
         item("07-heatmap-diverging", "Diverging heat map", "Change above and below zero. Cell labels switch between dark and white text to stay readable on every fill.", "chart",
              fns = c("scale_fill_phw_div", "phw_text_on"), args = "midpoint = 0"),
         item("30-linetype", "Observed and projected", "Solid and dashed lines from the linetype scale, so the chart still reads when printed in black and white.", "chart",
              fns = c("scale_linetype_phw", "scale_colour_phw_d")),
         item("31-dumbbell", "Change between two periods", "A dumbbell chart: one row per area, a dot per period and a line between them.", "chart",
              fns = c("scale_colour_phw_d", "theme_phw"))
       )),
  list(id = "uncertainty", title = "Uncertainty and distributions",
       intro = "Intervals you have already calculated, and the spread of values.",
       items = list(
         item("24-ribbon", "Rate with a confidence band", "A monthly rate per 100,000 with limits you supply drawn as a shaded band, using `geom_ribbon()`.", "chart",
              fns = "phw_col"),
         item("25-forest", "Rates by area with intervals", "A forest plot of estimates and intervals you have already calculated: each area's rate and interval against a target line, coloured by whether it is higher, similar or lower.", "chart",
              fns = "phw_forest", args = "target = overall"),
         item("08-boxplot-highlight", "Highlight one group", "Box plots with one group picked out and the rest in grey.", "chart",
              fns = c("scale_fill_phw_d"), args = 'palette = "highlight"'),
         item("29-histogram", "Histograms by group", "The distribution of a measure in each group, one panel per group.", "chart",
              fns = c("scale_fill_phw_d")),
         item("15-ridges", "Ridgeline plot", "Distributions stacked as ridges. ggridges picks up the PHW styling automatically.", "chart",
              pkgs = c("ggplot2", "ggridges"), fns = c("scale_fill_phw_d", "phw_style_extensions"))
       )),
  list(id = "public-health", title = "Public health charts",
       intro = "Ready-made charts for common surveillance and quality outputs. Each returns a ggplot, so you can add titles, scales or layers as usual.",
       items = list(
         item("20-epicurve", "Epidemic curve", "Cases by week of onset from a line list, stacked by group. Days, weeks or months.", "chart",
              fns = "phw_epicurve", args = 'interval = "week"'),
         item("21-pyramid", "Population pyramid", "Age and sex structure as percentages, with outlines for a comparison population.", "chart",
              fns = "phw_pyramid", args = "compare = other_pop"),
         item("22-funnel", "Funnel plot", "Proportions by unit against size, with 95% and 99.8% control limits. Units outside the limits are labelled.", "chart",
              fns = "phw_funnel"),
         item("23-spc", "SPC chart", "A control chart (XmR: individual values, with limits from the moving range) with limits from a baseline period. Shifts, trends and points outside the limits are flagged.", "chart",
              fns = "phw_spc", args = 'improvement = "increase", baseline = 20')
       )),
  list(id = "extensions", title = "Extension packages",
       intro = "ggplot2 extension packages are styled too. Load them before `use_phw_ggplot()`, or call `phw_style_extensions()` after loading them.",
       items = list(
         item("14-alluvial", "Flow diagram with three stages", "A Sankey-style flow through three stages. Add more stages with axis4, axis5 and so on.", "chart",
              pkgs = c("ggplot2", "ggalluvial"), fns = c("phw_style_extensions", "scale_fill_phw_d")),
         item("16-treemap", "Treemap", "Parts of a whole as rectangles, with white labels and borders.", "chart",
              pkgs = c("ggplot2", "treemapify"), fns = c("phw_style_extensions", "scale_fill_phw_d")),
         item("17-repel", "Labels that avoid each other", "Point labels pushed apart so they don't overlap, in the PHW font.", "chart",
              pkgs = c("ggplot2", "ggrepel"), fns = "phw_style_extensions")
       )),
  list(id = "finishing", title = "Layout and finishing",
       intro = "Put several charts in one figure, add the source and date bar, and save at the right size.",
       items = list(
         item("09-finalised", "Source and date bar", "A footer with the source, team and date (and the logo, if you have downloaded it), then saved at report size.", "chart",
              fns = c("phw_finalise", "phw_save")),
         item("18-arrange", "Several charts in one figure", "Panels side by side with a shared title, panel letters and source line.", "chart",
              pkgs = c("ggplot2", "patchwork"), fns = "phw_arrange", args = 'tag_levels = "A"'),
         item("19-gridextra", "gridExtra layout", "The same with gridExtra, using a PHW title block.", "chart",
              pkgs = c("ggplot2", "gridExtra"), fns = c("phw_title_grob", "phw_finalise"))
       )),
  list(id = "colour", title = "Colour and accessibility",
       intro = "Palettes, colour keys that keep each group's colour across reports, and checks for colour blindness and contrast.",
       items = list(
         item("10-palettes", "All palettes", "Every PHW palette with its name, for use as `palette = \"...\"` in any function: groups (`main`, `extended`, `accessible`, `strategy`), status (`rag`) and numbers (`blues`, `greens` and more).", "chart",
              fns = "show_phw_palettes"),
         item("11-palettes-deutan", "Palettes with colour blindness", "The same palettes as seen with deuteranopia, the most common type.", "chart",
              fns = c("show_phw_palettes", "phw_cvd"), args = 'cvd = "deutan"'),
         item("13-accessible", "Colour-blind safe palette", "Seven groups in the palette that stays distinct for the common types of colour blindness.", "chart",
              fns = "scale_colour_phw_d", args = 'palette = "accessible"'),
         item("12-colour-key", "Colours that stay with their groups", "Report 2 adds a group and \"Unknown\", and the existing groups keep their colours from report 1.", "chart",
              fns = c("phw_colour_key", "scale_fill_phw_d"), args = 'key = "my_groups"')
       )),
  list(id = "maps", title = "Maps",
       intro = "Boundaries for every level of Welsh geography are downloaded on first use and cached. Static maps use ggplot2 and sf; interactive maps use leaflet.",
       items = list(
         item("06-map", "Choropleth", "Local authorities filled by a binned value, joined to the boundaries by area code.", "map",
              pkgs = c("ggplot2", "sf"), fns = "phw_map", args = "by = code, fill = value, level = la, bins = c(1, 2, 3, 5)"),
         item("34-map-labels", "Choropleth with values printed", "The same kind of map with each area's value printed on it. With ggrepel installed, labels that would overlap on small areas are moved apart.", "map",
              pkgs = c("ggplot2", "sf"), fns = "phw_map", args = "label = rate"),
         item("32-map-facets", "One map per year", "Small-multiple maps with `facet_wrap()`, sharing one legend. The data has one row per area and year.", "map",
              pkgs = c("ggplot2", "sf"), fns = "phw_map", args = "bins = c(2, 4, 6, 8)"),
         item("33-map-points", "Areas with points on top", "Seven health boards coloured by name from the twelve-colour `extended` palette, with sites drawn as points with a white halo so they show on any fill.", "map",
              pkgs = c("ggplot2", "sf"), fns = c("phw_boundaries", "theme_phw_map", "scale_fill_phw_d", "scale_shape_phw")),
         item("06-boundaries", "Every level of geography", "Health boards, GP clusters, Senedd constituencies and MSOAs, all from one function.", "map",
              pkgs = c("ggplot2", "sf", "patchwork"), fns = c("phw_boundaries", "phw_boundary_levels", "phw_arrange")),
         item("leaflet", "Interactive map with bins", "Hover for each area's name and value, zoom and pan. Values are grouped into bins with a legend.", "widget",
              pkgs = c("leaflet", "sf"), fns = c("phw_leaflet", "phw_leaflet_polygons", "phw_boundaries"), args = "bins = c(10, 20, 30, 40, 50)"),
         item("leaflet-groups", "Interactive map with categories", "The same map coloured by category, with colours from a PHW palette.", "widget",
              pkgs = c("leaflet", "sf"), fns = c("phw_leaflet", "phw_leaflet_polygons", "phw_leaflet_palette"), args = 'palette = "accessible"')
       )),
  list(id = "tables", title = "Tables for reports",
       intro = "flextable and gt tables for Word, PowerPoint, HTML and PDF. The summary functions turn a raw data frame into a finished table; `phw_flextable()` and `phw_gt()` style it.",
       items = list(
         item("table-nested", "Nested row and column groups", "Groups within groups in both rows and columns, built from a raw line list, with group and table totals.", "table",
              pkgs = "flextable", fns = c("phw_group_table", "phw_flextable"), args = "rows = c(category, subgroup), cols = c(year, half)"),
         item("table-nested-columns", "Groups in columns, totals below", "Group and subgroup in separate columns, a total below each group and percentages of the parent group.", "table",
              pkgs = "flextable", fns = c("phw_group_table", "phw_flextable"), args = 'layout = "columns", percent = "parent"'),
         item("table-summary", "Characteristics by group", "A \"Table 1\" of counts, percentages and medians by outcome, straight from a line list.", "table",
              pkgs = "flextable", fns = c("phw_summary_table", "phw_flextable")),
         item("table-as-summary", "Your own table, styled as a summary", "A table made with dplyr or by hand, marked with `phw_as_summary()` so it gets bold variable rows, indented levels and total rows like the tables above.", "table",
              pkgs = "flextable", fns = c("phw_as_summary", "phw_flextable"), args = "row_type = kind"),
         item("table-rates", "Rates with confidence intervals", "Crude rates per 100,000 with exact intervals by demographic and risk group.", "table",
              pkgs = "flextable", fns = c("phw_rate_table", "phw_flextable")),
         item("table-risk", "Attack rates and relative risks", "An outbreak table: attack rates for exposed and unexposed, relative risk and p-value.", "table",
              pkgs = "flextable", fns = c("phw_risk_table", "phw_flextable")),
         item("table-crosstab", "Cross-tabulation with heat colours", "Counts by two variables with totals, shaded by value.", "table",
              pkgs = "flextable", fns = c("phw_crosstab", "phw_flextable_heat")),
         item("table-rag", "RAG status with shapes", "Red, amber and green (RAG) status cells that also carry a shape, so they work for colour-blind readers.", "table",
              pkgs = "flextable", fns = "phw_flextable_heat", args = 'palette = "rag_accessible"'),
         item("table-bars", "In-cell bars", "A bar in each cell showing the value's size.", "table",
              pkgs = "flextable", fns = "phw_flextable_bars"),
         item("table-groups", "Cells coloured by group", "Group names coloured to match the charts, using the same colour key.", "table",
              pkgs = "flextable", fns = "phw_flextable_groups", args = 'key = "gallery_groups"'),
         item("table-booktabs", "Style: booktabs", "Rules above and below the header and at the foot only. The default.", "table",
              pkgs = "flextable", fns = "phw_flextable", args = 'style = "booktabs"'),
         item("table-header", "Style: navy header", "A filled navy header row.", "table",
              pkgs = "flextable", fns = "phw_flextable", args = 'style = "header"'),
         item("table-zebra", "Style: zebra", "Alternate rows shaded for long tables.", "table",
              pkgs = "flextable", fns = "phw_flextable", args = 'style = "zebra"'),
         item("table-light", "Style: light", "Thin grey lines between every row.", "table",
              pkgs = "flextable", fns = "phw_flextable", args = 'style = "light"'),
         item("gt-table", "gt", "The nested group table from above, rendered with gt instead of flextable.", "table",
              pkgs = "gt", fns = c("phw_gt", "phw_group_table")),
         item("gtsummary", "gtsummary", "A gtsummary table with the PHW theme switched on for the session.", "table",
              pkgs = c("gtsummary", "gt"), fns = "use_phw_gtsummary")
       )),
  list(id = "interactive", title = "Interactive tables and charts",
       intro = "HTML widgets: sortable and searchable tables, and charts you can hover over and zoom. They show in the RStudio Viewer pane and in HTML outputs such as Quarto HTML reports, dashboards and Shiny apps. They can't go in Word or PDF.",
       items = list(
         item("reactable", "Sortable table", "A reactable table with search and paging.", "widget",
              pkgs = "reactable", fns = "phw_reactable", args = "searchable = TRUE"),
         item("reactable-columns", "Bars, heat and RAG in cells", "Column helpers for in-cell bars, heat colours, RAG status and percentages.", "widget",
              pkgs = "reactable", fns = c("phw_reactable", "phw_col_bar", "phw_col_heat", "phw_col_rag", "phw_col_percent")),
         item("reactable-summary", "Summary table, interactive", "The same summary table as in the report tables, as a reactable.", "widget",
              pkgs = "reactable", fns = c("phw_summary_table", "phw_reactable")),
         item("dt", "Searchable table (DT)", "A DataTables table with PHW styling, for long tables people need to filter.", "widget",
              pkgs = "DT", fns = "phw_datatable"),
         item("plotly", "ggplot made interactive", "The line chart from the top of this page, converted to plotly with hover labels.", "widget",
              pkgs = c("plotly", "ggplot2"), fns = "phw_plotly"),
         item("plotly-bar", "plotly bar chart", "A chart built with plot_ly(), using colours from a colour key.", "widget",
              pkgs = "plotly", fns = c("phw_plotly", "phw_colour_key")),
         item("plotly-donut", "plotly donut", "Parts of a whole as a donut chart.", "widget",
              pkgs = "plotly", fns = "phw_plotly"),
         item("plotly-heatmap", "plotly heat map", "A diverging heat map with a PHW colour scale.", "widget",
              pkgs = "plotly", fns = c("phw_plotly", "phw_plotly_colorscale"), args = '"orange_navy"'),
         item("plotly-subplot", "plotly subplots", "Two plotly charts side by side with `plotly::subplot()`.", "widget",
              pkgs = "plotly", fns = c("phw_plotly", "phw_colour_key"))
       )),
  list(id = "documents", title = "Reports and documents",
       intro = "Templates for R Markdown and Quarto. Add the Quarto templates to a project with `use_phw_quarto()`; R Markdown formats are under File > New File > R Markdown > From Template.",
       items = list(
         item("quarto-typst-1", "PDF report cover (Quarto, Typst)", "A PDF report through Typst, which needs no LaTeX installation. Cover page with title, team and date.", "document",
              pkgs = "quarto", fns = "use_phw_quarto", args = "format: phw-typst"),
         item("quarto-typst-2", "PDF report page (Quarto, Typst)", "An inside page: running header band, numbered figures and tables, page numbers.", "document",
              pkgs = "quarto", fns = "use_phw_quarto", args = "format: phw-typst"),
         item("quarto-typst-3", "PDF report table page", "A table page in the same report.", "document",
              pkgs = "quarto", fns = "use_phw_quarto", args = "format: phw-typst"),
         item("quarto-latex-2", "PDF report (Quarto, LaTeX)", "The same report through LaTeX, for teams that already use it.", "document",
              pkgs = "quarto", fns = c("use_phw_quarto", "phw_latex_header"), args = "format: phw-pdf"),
         item("quarto-html", "HTML report (Quarto)", "A web page report with a table of contents and links to the other formats.", "document",
              pkgs = "quarto", fns = "use_phw_quarto", args = "format: phw-html"),
         item("quarto-word-1", "Word report (Quarto)", "A Word document using the PHW reference document for styles.", "document",
              pkgs = "quarto", fns = c("use_phw_quarto", "phw_reference_docx"), args = "format: phw-docx"),
         item("rmd-word-1", "Word report (R Markdown)", "The R Markdown version of the Word report.", "document",
              pkgs = "rmarkdown", fns = "phw_word_document", args = "output: phwstyle::phw_word_document"),
         item("rmd-html", "HTML report (R Markdown)", "The R Markdown version of the HTML report.", "document",
              pkgs = "rmarkdown", fns = "phw_html_document", args = "output: phwstyle::phw_html_document"),
         item("rmd-pdf-1", "PDF report (R Markdown)", "The R Markdown version of the PDF report.", "document",
              pkgs = "rmarkdown", fns = "phw_pdf_document", args = "output: phwstyle::phw_pdf_document")
       )),
  list(id = "presenting", title = "Slides, dashboards and apps",
       intro = "Outputs for presenting and sharing live. Slides and dashboards are Quarto formats; the Shiny theme works in any Shiny app.",
       items = list(
         item("slides-1", "Title slide (Quarto, reveal.js)", "HTML slides that open in a browser, with a title slide.", "document",
              pkgs = "quarto", fns = "use_phw_quarto", args = "format: phw-revealjs"),
         item("slides-2", "Text slide", "A key messages slide with the footer.", "document",
              pkgs = "quarto", fns = "use_phw_quarto", args = "format: phw-revealjs"),
         item("slides-3", "Chart slide", "A ggplot on a slide, styled automatically.", "document",
              pkgs = "quarto", fns = "use_phw_quarto", args = "format: phw-revealjs"),
         item("dashboard", "Dashboard (Quarto)", "A one-page HTML dashboard with value boxes, a plotly chart and a table.", "document",
              pkgs = c("quarto", "plotly", "reactable"), fns = c("use_phw_quarto", "phw_plotly", "phw_reactable"), args = "format: phw-dashboard"),
         item("shiny", "Shiny app", "A Shiny app with the PHW header, navigation bar and Bootstrap theme.", "widget",
              pkgs = c("shiny", "bslib"), fns = c("phw_page_navbar", "phw_bs_theme", "phw_header"))
       )),
  list(id = "office", title = "Office files",
       intro = "Tables and charts written to .xlsx and .pptx.",
       items = list(
         item("powerpoint", "PowerPoint slides", "A 16:9 deck with a text slide, a chart (editable in PowerPoint with rvg) and a table. Charts are enlarged and tables fill the content area by default.", "office",
              pkgs = c("officer", "rvg"), fns = c("phw_pptx", "phw_add_slide"), args = "plot_scale = 1.5, table_fit = TRUE"),
         item("excel", "Excel workbook", "One sheet per table, with a title, source, styled header and frozen panes.", "office",
              pkgs = "openxlsx2", fns = "phw_write_xlsx")
       ))
)

# ---- Write the page --------------------------------------------------------

# Map each function to its help page through the \alias lines in man/.
rd <- list.files("man", pattern = "\\.Rd$", full.names = TRUE)
alias_page <- unlist(lapply(rd, function(f) {
  a <- sub("^\\\\alias\\{(.*)\\}$", "\\1", grep("^\\\\alias\\{", readLines(f, warn = FALSE), value = TRUE))
  stats::setNames(rep(sub("\\.Rd$", ".html", basename(f)), length(a)), a)
}))

esc <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}
md_code <- function(x) gsub("`([^`]+)`", "<code>\\1</code>", esc(x))
fn_link <- function(f) {
  page <- alias_page[f]
  if (is.na(page)) stop("No help page for ", f)
  sprintf('<a href="../reference/%s"><code>%s()</code></a>', page, f)
}
pkg_link <- function(p) {
  if (p == "quarto") return('<span class="pkg">Quarto</span>')
  sprintf('<a class="pkg" href="https://cran.r-project.org/package=%s">%s</a>', p, p)
}

all_items <- unlist(lapply(sections, `[[`, "items"), recursive = FALSE)
missing <- setdiff(vapply(all_items, `[[`, "", "file"), sub("\\.webp$", "", list.files("man/figures", "\\.webp$")))
if (length(missing)) stop("Missing images: ", paste(missing, collapse = ", "))

figure <- function(it) {
  t <- types[[it$type]]
  args <- if (!is.null(it$args)) sprintf('<div class="g-row"><span class="k">Key arguments</span><code>%s</code></div>', esc(it$args)) else ""
  paste0(
    sprintf('<figure class="g-item" data-type="%s" id="%s">', it$type, it$file),
    sprintf('<a class="g-img" href="../reference/figures/%s.webp"><img src="../reference/figures/%s.webp" alt="%s" loading="lazy"></a>',
            it$file, it$file, esc(it$title)),
    '<figcaption>',
    sprintf('<span class="badge t-%s">%s</span>', it$type, t$label),
    sprintf('<h4>%s</h4>', esc(it$title)),
    sprintf('<p>%s</p>', md_code(it$desc)),
    sprintf('<div class="g-row"><span class="k">phwstyle</span>%s</div>', paste(vapply(it$fns, fn_link, ""), collapse = " ")),
    args,
    sprintf('<div class="g-row"><span class="k">Packages</span>%s</div>', paste(vapply(it$pkgs, pkg_link, ""), collapse = " ")),
    sprintf('<div class="g-row where"><span class="k">Shows in</span>%s</div>', esc(t$where)),
    '</figcaption></figure>')
}

css <- '
<style>
.g-intro{color:var(--phw-ink-soft, #4C6272);margin:4px 0 14px}
.g-intro dl{display:grid;grid-template-columns:max-content 1fr;gap:6px 14px;margin:8px 0 0}
.g-intro dt{font-weight:500}.g-intro dd{margin:0}
.g-nav{padding:10px 0;margin-bottom:8px;display:flex;flex-wrap:wrap;gap:6px}
.g-nav a{font-size:.85rem;text-decoration:none;padding:3px 10px;border:1px solid var(--phw-rule, #D8DDE0);border-radius:999px;color:var(--phw-navy, #285087);white-space:nowrap}
.g-nav a:hover{background:var(--phw-navy, #285087);color:#fff;border-color:var(--phw-navy, #285087)}
.g-nav a .n{font-weight:700;margin-right:4px}
.g-filter{display:flex;flex-wrap:wrap;gap:6px;align-items:center;margin:4px 0 6px;font-size:.85rem}
.g-filter button{border:1px solid var(--phw-navy, #285087);background:#fff;color:var(--phw-navy, #285087);border-radius:2px;padding:3px 10px;font-size:.85rem}
.g-filter button[aria-pressed="true"]{background:var(--phw-navy, #285087);color:#fff}
.g-section{margin-top:36px;scroll-margin-top:110px}
.g-section > .g-head{display:flex;align-items:baseline;gap:12px;border-bottom:3px solid var(--phw-navy, #285087);padding-bottom:6px;margin-bottom:6px}
.g-head .num{background:var(--phw-navy, #285087);color:#fff;font-weight:700;min-width:2.1em;text-align:center;padding:2px 8px;border-radius:2px}
.g-head h2{margin:0;border:0;font-size:1.5rem}
.g-head .count{margin-left:auto;color:var(--phw-ink-soft, #4C6272);font-size:.85rem}
.g-section > p.lead-in{color:var(--phw-ink-soft, #4C6272);margin:6px 0 14px;font-size:.95rem}
.g-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:18px}
.g-item{margin:0;border:1px solid var(--phw-rule, #D8DDE0);border-radius:4px;background:#fff;display:flex;flex-direction:column;overflow:hidden}
.g-img{display:block;background:#fff;border-bottom:1px solid var(--phw-rule, #D8DDE0);aspect-ratio:16/10;overflow:hidden}
.g-img img{width:100%;height:100%;object-fit:contain;object-position:top center;display:block}
.g-item figcaption{padding:10px 12px 12px;font-size:.85rem;color:var(--phw-ink, #212B32)}
.g-item h4{font-size:1rem;margin:6px 0 4px;color:var(--phw-navy, #285087)}
.g-item p{margin:0 0 8px}
.g-item .g-row{display:block;margin:3px 0;line-height:1.5}
.g-item .k{display:inline-block;min-width:6.5em;color:var(--phw-ink-soft, #4C6272);font-size:.78rem;text-transform:uppercase;letter-spacing:.03em}
.g-item code{font-size:.8rem}
.g-item .pkg{display:inline-block;background:var(--phw-mist, #F0F4F5);border-radius:2px;padding:0 6px;margin-right:3px;text-decoration:none;color:var(--phw-ink, #212B32)}
.g-item .where{color:var(--phw-ink-soft, #4C6272)}
.badge{display:inline-block;font-size:.72rem;font-weight:500;padding:2px 8px;border-radius:2px;color:#fff}
.t-chart{background:var(--phw-navy, #285087)}.t-map{background:#338276}.t-table{background:var(--phw-ink-soft, #4C6272)}
.t-widget{background:#D50B5C}.t-document{background:#24A2B5}.t-office{background:#D97F00}
.g-top{font-size:.8rem;display:inline-block;margin-top:10px}
@media (max-width:600px){.g-grid{grid-template-columns:1fr}.g-intro dl{grid-template-columns:1fr}.g-intro dd{margin-bottom:6px}}
</style>'

js <- '
<script>
document.addEventListener("DOMContentLoaded", function () {
  var buttons = document.querySelectorAll(".g-filter button");
  buttons.forEach(function (b) {
    b.addEventListener("click", function () {
      var t = b.dataset.type;
      buttons.forEach(function (o) { o.setAttribute("aria-pressed", o === b ? "true" : "false"); });
      document.querySelectorAll(".g-item").forEach(function (f) {
        f.style.display = (t === "all" || f.dataset.type === t) ? "" : "none";
      });
      document.querySelectorAll(".g-section").forEach(function (s) {
        var shown = s.querySelectorAll(".g-item:not([style*=\\"none\\"])").length;
        s.style.display = shown ? "" : "none";
        var c = s.querySelector(".count .shown"); if (c) c.textContent = shown;
      });
    });
  });
});
</script>'

intro <- paste0(
  '<p class="g-intro">All examples use made-up data. Code: ',
  '<a href="https://github.com/Ch3w3y/phwstyle-r/blob/main/gallery/build-gallery.R"><code>gallery/build-gallery.R</code></a>. ',
  'Commented walk-through: <a href="https://github.com/Ch3w3y/phwstyle-r/blob/main/examples/phwstyle-demo.R"><code>examples/phwstyle-demo.R</code></a>.</p>')

nav <- paste0('<nav class="g-nav" aria-label="Gallery sections">',
              paste(vapply(seq_along(sections), function(i)
                sprintf('<a href="#%s"><span class="n">%d</span>%s</a>', sections[[i]]$id, i, esc(sections[[i]]$title)), ""), collapse = ""),
              '</nav>')

filter <- paste0('<div class="g-filter" role="group" aria-label="Filter by output type"><span>Show:</span>',
                 '<button type="button" data-type="all" aria-pressed="true">All</button>',
                 paste(vapply(names(types), function(k) sprintf('<button type="button" data-type="%s" aria-pressed="false">%s</button>', k, types[[k]]$label), ""), collapse = ""),
                 '</div>')

section_html <- vapply(seq_along(sections), function(i) {
  s <- sections[[i]]
  n <- length(s$items)
  paste0(sprintf('<section class="g-section" id="%s">', s$id),
         sprintf('<div class="g-head"><span class="num">%d</span><h2>%s</h2><span class="count"><span class="shown">%d</span> of %d examples</span></div>',
                 i, esc(s$title), n, n),
         sprintf('<p class="lead-in">%s</p>', md_code(s$intro)),
         '<div class="g-grid">', paste(vapply(s$items, figure, ""), collapse = "\n"), '</div>',
         '<a class="g-top" href="#top">Back to top</a></section>')
}, "")

rmd <- c("---", 'title: "Gallery"', "description: >", "  Examples of every phwstyle output.", "---", "",
         "```{=html}", css, '<div id="top"></div>', intro, nav, filter, section_html, js, "```")
writeLines(rmd, "vignettes/articles/gallery.Rmd", useBytes = TRUE)
message("Wrote vignettes/articles/gallery.Rmd with ", length(all_items), " items")
