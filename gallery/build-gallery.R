# Render a gallery of phwstyle outputs for visual review and documentation.
# All data are made up and labelled neutrally, so images can go in docs.
# Run from the package root after installing phwstyle:
#   Rscript gallery/build-gallery.R
# Outputs go to gallery/_output (git-ignored). Convert the images you want to
# show to .webp in man/figures, then run gallery/build-gallery-page.R to
# rebuild the gallery page on the documentation site.
#
# Boundary data: Local Authority Districts (December 2023) Boundaries UK BUC,
# Office for National Statistics, Open Government Licence v3.0.

library(ggplot2)
# Load extension packages before use_phw_ggplot() so their geoms are styled.
ext <- c("ggalluvial", "ggridges", "treemapify", "ggrepel", "patchwork", "gridExtra")
for (p in ext) if (requireNamespace(p, quietly = TRUE)) loadNamespace(p)
library(phwstyle)
out <- "gallery/_output"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
use_phw_ggplot()
set.seed(2026)
src <- phw_caption("Example data")

save <- function(p, name, w = 16, h = 10) phw_save(p, file.path(out, paste0(name, ".png")), width = w, height = h, dpi = 200)

areas <- paste("Area", LETTERS[1:7])
groups <- paste("Group", 1:4)

# 1. Lines by group, with shapes as a second cue
ts <- expand.grid(period = 1:13, group = groups)
ts$value <- round(30 + (ts$period - 1) * 6 + as.integer(ts$group) * 8 + rnorm(nrow(ts), 0, 8), 1)
p1 <- ggplot(ts, aes(period, value, colour = group, shape = group)) +
  geom_line(linewidth = 1) + geom_point(size = 2.2) +
  scale_colour_phw_d(key = "gallery_groups") + scale_shape_phw() +
  scale_x_continuous(breaks = seq(1, 13, 2)) +
  labs(title = "Line chart with colour and shape",
       subtitle = "scale_colour_phw_d() + scale_shape_phw()",
       x = "Period", y = "Value", caption = src)
save(p1, "01-line")

# 2. Facet wrap small multiples
fw <- expand.grid(period = 1:52, area = areas)
fw$value <- pmax(0, 20 + 15 * sin((fw$period - 5) / 8) + rnorm(nrow(fw), 0, 4) + as.integer(factor(fw$area)))
p2 <- ggplot(fw, aes(period, value)) +
  geom_area(fill = phw_col("light_teal"), alpha = 0.6) +
  geom_line(colour = phw_col("navy"), linewidth = 0.7) +
  facet_wrap(~area, ncol = 4) +
  labs(title = "Small multiples with facet_wrap()", x = "Period", y = "Value", caption = src)
save(p2, "02-facet-wrap", h = 11)

# 3. Horizontal bar with labels
hb <- data.frame(area = areas, value = c(2.0, 2.4, 5.5, 2.3, 2.6, 0.7, 3.9))
p3 <- ggplot(hb, aes(value, reorder(area, value))) +
  geom_col(fill = phw_col("navy"), width = 0.7) +
  geom_text(aes(label = format(value, nsmall = 1)), hjust = -0.25, size = 3.4) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(title = "Horizontal bar chart", subtitle = 'theme_phw(grid = "x")', x = "Value", y = NULL, caption = src) +
  theme_phw(grid = "x")
save(p3, "03-bar-horizontal")

# 4. Grouped columns with facet_grid
gc <- expand.grid(area = areas, panel = c("Panel X", "Panel Y", "Panel Z"), series = c("Series 1", "Series 2"))
gc$share <- round(runif(nrow(gc), 0.6, 0.97), 3)
p4 <- ggplot(gc, aes(area, share, fill = series)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.75) +
  geom_hline(yintercept = 0.9, linetype = "dashed", colour = phw_col("text_secondary")) +
  facet_grid(panel ~ .) +
  scale_y_continuous(labels = phw_percent(1), limits = c(0, 1), breaks = c(0, 0.5, 0.9)) +
  labs(title = "Dodged columns with facet_grid()", subtitle = 'Dashed line: a target. theme_phw(strip = "navy")',
       x = NULL, y = "Share", caption = src) +
  theme_phw(strip = "navy")
save(p4, "04-facet-grid-dodged", h = 12)

# 5. 100% stacked bars, with "Unknown" drawn grey automatically
mix <- expand.grid(year = 2021:2025, category = c("Category 1", "Category 2", "Unknown"))
mix$n <- c(25, 30, 28, 33, 29, 50, 52, 49, 56, 44, 3, 2, 4, 2, 1)
p5 <- ggplot(mix, aes(factor(year), n, fill = category)) +
  geom_col(position = "fill", width = 0.7) +
  scale_fill_phw_d() +
  scale_y_continuous(labels = phw_percent(1)) +
  labs(title = "100% stacked bars", subtitle = '"Unknown" is grey automatically', x = NULL, y = "Proportion",
       caption = src)
save(p5, "05-stacked-100")

# 6. Choropleth map (random values)
if (requireNamespace("sf", quietly = TRUE)) {
  la <- sf::st_read("gallery/wales-la-2023.geojson", quiet = TRUE)
  la$value <- round(runif(nrow(la), 0, 9.2), 1)
  p6 <- ggplot(la) + geom_sf(aes(fill = value), colour = "white", linewidth = 0.3) +
    scale_fill_phw_b(name = "Value", breaks = c(1, 2, 3, 5)) +
    labs(title = "Choropleth map", subtitle = "Random values. theme_phw_map() + scale_fill_phw_b()",
         caption = phw_caption("Example data. Boundaries: ONS (OGL v3)")) +
    theme_phw_map()
  save(p6, "06-map", w = 14, h = 14)

  # 6b. Boundaries for several levels, downloaded and cached by phw_boundaries()
  if (requireNamespace("patchwork", quietly = TRUE)) {
    bmap <- function(level, title) {
      b <- phw_boundaries(level, quiet = TRUE)
      b$value <- runif(nrow(b))
      ggplot(b) + geom_sf(aes(fill = value), colour = "white", linewidth = 0.15) +
        scale_fill_phw_c(guide = "none") + labs(title = title, subtitle = paste(nrow(b), "areas")) +
        theme_phw_map()
    }
    p6b <- phw_arrange(bmap("health_board", "Health boards"), bmap("gp_cluster", "GP clusters"),
                       bmap("senedd_constituency", "Senedd constituencies"), bmap("msoa", "MSOAs"),
                       ncol = 4, title = "Boundaries for every level", subtitle = "phw_boundaries(), random values",
                       source = "Example data. Boundaries: ONS and Welsh Government (OGL v3)")
    save(p6b, "06-boundaries", w = 24, h = 9)
  }
}

# 7. Heatmap with diverging scale
hm <- expand.grid(month = factor(month.abb, levels = month.abb), area = areas)
hm$change <- round(rnorm(nrow(hm), 0, 12), 1)
p7 <- ggplot(hm, aes(month, area, fill = change)) +
  geom_tile(colour = "white", linewidth = 0.8) +
  geom_text(aes(label = change, colour = after_scale(phw_text_on(fill))), size = 2.8) +
  scale_fill_phw_div(midpoint = 0, name = "% change") +
  labs(title = "Diverging heatmap", subtitle = "scale_fill_phw_div(midpoint = 0)", x = NULL, y = NULL,
       caption = src) +
  theme_phw(grid = "none", legend = "right", legend_title = TRUE)
save(p7, "07-heatmap-diverging")

# 8. Distributions: boxplot with one group highlighted
p8 <- ggplot(mpg, aes(class, hwy, fill = class == "compact")) +
  geom_boxplot(width = 0.6, outlier.colour = phw_col("grey_mid")) +
  scale_fill_phw_d(palette = "highlight", reverse = TRUE, guide = "none") +
  labs(title = "Highlight one group", subtitle = "Using the 'highlight' palette", x = NULL, y = "Miles per gallon",
       caption = phw_caption("ggplot2::mpg"))
save(p8, "08-boxplot-highlight")

# 9. Finalised chart with logo footer
p9 <- ggplot(hb, aes(value, reorder(area, value))) +
  geom_col(fill = phw_col("teal"), width = 0.7) +
  labs(title = "Chart with the PHW footer", subtitle = "phw_finalise()", x = "Value", y = NULL) +
  theme_phw(grid = "x")
save(phw_finalise(p9, source = "Example data", team = "Team name"), "09-finalised", h = 11)

# 10. Palettes, as seen with normal vision and with deuteranopia
save(show_phw_palettes(), "10-palettes", h = 9)
save(show_phw_palettes(cvd = "deutan") + labs(title = "The same palettes with deuteranopia (phw_cvd)"),
     "11-palettes-deutan", h = 9.5)

# 12. Colour keys: the same group keeps its colour when groups are added
k1 <- data.frame(group = factor(groups[1:3], levels = groups[1:3]), value = c(4, 6, 5))
k2 <- data.frame(group = factor(c("Group 0", groups[1:3], "Unknown"), levels = c("Group 0", groups[1:3], "Unknown")),
                 value = c(3, 4, 6, 5, 1))
phw_key_reset("gallery_key")
both <- rbind(cbind(k1, report = "Report 1: three groups"), cbind(k2, report = "Report 2: a new group and Unknown"))
p12 <- ggplot(both, aes(group, value, fill = group)) +
  geom_col(width = 0.7) +
  facet_wrap(~report, scales = "free_x") +
  scale_fill_phw_d(key = "gallery_key", guide = "none") +
  labs(title = "Colours stay with their group", subtitle = 'scale_fill_phw_d(key = "my_groups")',
       x = NULL, y = "Value", caption = src)
# Draw report 1 first so its groups take the first colours.
invisible(phw_colour_key(k1$group, "gallery_key"))
save(p12, "12-colour-key")

# 13. Many groups with the accessible palette
many <- expand.grid(period = 1:10, group = paste("Group", 1:7))
many$value <- round(as.integer(many$group) * 5 + many$period * 2 + rnorm(nrow(many), 0, 2), 1)
p13 <- ggplot(many, aes(period, value, colour = group)) +
  geom_line(linewidth = 1) +
  scale_colour_phw_d(palette = "accessible") +
  labs(title = "Seven groups, colour-blind safe", subtitle = 'scale_colour_phw_d(palette = "accessible")',
       x = "Period", y = "Value", caption = src) +
  theme_phw(legend = "right")
save(p13, "13-accessible")

# 14-19. Extension packages and multi-plot layouts
if (requireNamespace("ggalluvial", quietly = TRUE)) {
  # Any number of stages: add axis3, axis4... (or use the long "lodes" format).
  fl <- expand.grid(s1 = c("A", "B"), s2 = c("X", "Y", "Z"), s3 = c("Done", "Ongoing"))
  fl$n <- round(runif(nrow(fl), 3, 30))
  p14 <- ggplot(fl, aes(axis1 = s1, axis2 = s2, axis3 = s3, y = n)) +
    ggalluvial::geom_alluvium(aes(fill = s1), width = 0.25) +   # coloured by scale_fill_phw_d()
    ggalluvial::geom_stratum(width = 0.25) +                    # styled by phw_style_extensions()
    geom_text(stat = ggalluvial::StatStratum, aes(label = after_stat(stratum)), size = 3) +
    scale_x_discrete(limits = c("Stage 1", "Stage 2", "Stage 3"), expand = c(0.08, 0.08)) +
    scale_fill_phw_d() +
    labs(title = "Flow (Sankey-style) diagram", subtitle = "ggalluvial with three stages", x = NULL, y = "Count",
         caption = src) +
    theme_phw(legend = "none")
  save(p14, "14-alluvial")
}
if (requireNamespace("ggridges", quietly = TRUE)) {
  rd <- data.frame(group = rep(groups, each = 200), value = rnorm(800, rep(c(0, 1, 1.5, 3), each = 200)))
  p15 <- ggplot(rd, aes(value, group, fill = group)) +
    ggridges::geom_density_ridges(scale = 1.4) +
    scale_fill_phw_d(key = "gallery_groups", guide = "none") +
    labs(title = "Ridgeline plot", subtitle = "ggridges with the same colour key as the line chart", x = "Value", y = NULL,
         caption = src)
  save(p15, "15-ridges")
}
if (requireNamespace("treemapify", quietly = TRUE)) {
  tm <- data.frame(category = paste("Category", LETTERS[1:6]), n = c(30, 20, 15, 10, 8, 5))
  p16 <- ggplot(tm, aes(area = n, fill = category, label = category)) +
    treemapify::geom_treemap() + treemapify::geom_treemap_text(place = "topleft", padding.x = grid::unit(2, "mm")) +
    scale_fill_phw_d(palette = "accessible", guide = "none") +
    labs(title = "Treemap", subtitle = "treemapify: white labels and borders by default", caption = src)
  save(p16, "16-treemap")
}
if (requireNamespace("ggrepel", quietly = TRUE)) {
  rp <- data.frame(x = runif(14), y = runif(14), label = paste("Point", 1:14))
  p17 <- ggplot(rp, aes(x, y, label = label)) + geom_point(colour = phw_col("navy")) +
    ggrepel::geom_text_repel(size = 3.2) +
    labs(title = "Labels that avoid each other", subtitle = "ggrepel in the PHW font", x = "x", y = "y", caption = src)
  save(p17, "17-repel")
}
if (requireNamespace("patchwork", quietly = TRUE)) {
  pa <- ggplot(hb, aes(value, reorder(area, value))) + geom_col(fill = phw_col("navy"), width = 0.7) +
    labs(title = "Panel one", x = "Value", y = NULL) + theme_phw(grid = "x")
  pb <- ggplot(ts, aes(period, value, colour = group)) + geom_line(linewidth = 0.9) +
    scale_colour_phw_d(key = "gallery_groups") + labs(title = "Panel two", x = "Period", y = "Value")
  save(phw_arrange(pa, pb, title = "Several charts in one figure", subtitle = "phw_arrange(), using patchwork",
                   source = "Example data", tag_levels = "A", widths = c(1, 1.4)), "18-arrange", w = 20, h = 10)
}
if (requireNamespace("gridExtra", quietly = TRUE)) {
  g <- gridExtra::arrangeGrob(p3 + labs(title = NULL, subtitle = NULL, caption = NULL),
                              p5 + labs(title = NULL, subtitle = NULL, caption = NULL), ncol = 2,
                              top = phw_title_grob("gridExtra layout", "phw_title_grob() and phw_finalise()"))
  save(phw_finalise(g, source = "Example data"), "19-gridextra", w = 20, h = 11)
}

# Tables
if (requireNamespace("flextable", quietly = TRUE)) {
  tbl <- data.frame(Area = areas, `Year 1` = c(3.2, 1.5, 3.8, 2.3, 0.5, 0.0, 2.3),
                    `Year 2` = c(4.4, 0.7, 4.2, 0.2, 1.6, 3.0, 3.7), `Year 3` = c(2.0, 2.4, 5.5, 2.3, 2.6, 0.7, 3.9),
                    Count = c(12L, 14L, 28L, 10L, 10L, 1L, 15L), check.names = FALSE)
  for (s in c("booktabs", "header", "light", "zebra")) {
    ft <- phw_flextable(tbl, caption = sprintf('Table style "%s"', s), number = 1, source = "Example data",
                        style = s, bold_first_col = TRUE)
    flextable::save_as_image(ft, file.path(out, paste0("table-", s, ".png")), res = 200)
  }
  heat <- phw_flextable_heat(phw_flextable(tbl[, 1:4], caption = "Heat table", source = "Example data"), j = 2:4)
  flextable::save_as_image(heat, file.path(out, "table-heat.png"), res = 200)
  rag <- data.frame(Area = areas, `Measure 1` = c(0.952, 0.948, 0.931, 0.944, 0.958, 0.962, 0.939),
                    `Measure 2` = c(0.941, 0.952, 0.921, 0.938, 0.947, 0.955, 0.93), check.names = FALSE)
  ragft <- phw_flextable(rag, caption = "RAG status with shapes for colour-blind readers", source = "Example data", digits = 3)
  ragft <- phw_flextable_heat(ragft, j = 2:3, palette = "rag_accessible", breaks = c(0.93, 0.95))
  flextable::save_as_image(ragft, file.path(out, "table-rag.png"), res = 200)
  grp <- data.frame(Group = c(groups[1:3], "Unknown"), Count = c(120L, 85L, 64L, 9L), Share = c(0.43, 0.31, 0.23, 0.03))
  gft <- phw_flextable_groups(phw_flextable(grp, caption = "Cells coloured by group key", source = "Example data"),
                              j = "Group", key = "gallery_groups")
  flextable::save_as_image(gft, file.path(out, "table-groups.png"), res = 200)
}

# Summary tables: made-up line list and aggregated data
set.seed(7)
ll <- data.frame(
  age_group = factor(sample(c("0-14", "15-44", "45-64", "65+"), 400, TRUE, prob = c(.15, .35, .3, .2)),
                     levels = c("0-14", "15-44", "45-64", "65+")),
  sex = sample(c("Female", "Male", NA), 400, TRUE, prob = c(.49, .49, .02)),
  setting = sample(c("Setting 1", "Setting 2", "Setting 3"), 400, TRUE),
  days = rpois(400, 5),
  outcome = sample(c("Outcome X", "Outcome Y"), 400, TRUE, prob = c(.7, .3)),
  period = sample(paste("Period", 1:6), 400, TRUE))
labs_ll <- list(age_group = "Age group", sex = "Sex", setting = "Setting", days = "Days to recovery",
                outcome = "Outcome")
sum_tab <- phw_summary_table(ll, vars = c("age_group", "sex", "setting", "days"), by = "outcome", labels = labs_ll)
agg <- expand.grid(age_group = c("0-14", "15-44", "45-64", "65+"), sex = c("Female", "Male"),
                   group = c("Group A", "Group B"))
agg$cases <- rpois(nrow(agg), c(8, 20, 30, 45))
agg$pop <- round(runif(nrow(agg), 40, 120)) * 1000
rate_tab <- phw_rate_table(agg, c("age_group", "sex", "group"), "cases", "pop",
                           labels = list(age_group = "Age group", sex = "Sex", group = "Risk group"))
ob <- data.frame(item_a = sample(c("Yes", "No"), 150, TRUE), item_b = sample(c("Yes", "No"), 150, TRUE),
                 item_c = sample(c("Yes", "No"), 150, TRUE))
ob$ill <- rbinom(150, 1, ifelse(ob$item_a == "Yes", 0.55, 0.15))
risk_tab <- phw_risk_table(ob, c("item_a", "item_b", "item_c"), "ill",
                           labels = list(item_a = "Exposure A", item_b = "Exposure B", item_c = "Exposure C"))
xt <- phw_crosstab(ll, "period", "age_group", labels = list(period = "Period", age_group = "Age group"))
if (requireNamespace("flextable", quietly = TRUE)) {
  st <- function(ft, name) flextable::save_as_image(ft, file.path(out, paste0(name, ".png")), res = 200)
  st(phw_flextable(sum_tab, caption = "Characteristics by outcome", number = 2, source = "Example data"), "table-summary")
  st(phw_flextable(rate_tab, caption = "Rates by demographic and risk group", number = 3, source = "Example data"), "table-rates")
  st(phw_flextable(risk_tab, caption = "Attack rates by exposure", number = 4, source = "Example data"), "table-risk")
  xft <- phw_flextable_heat(phw_flextable(xt, caption = "Counts by period and age group", number = 5,
                                          source = "Example data"), j = 2:5)
  st(xft, "table-crosstab")
  dat <- data.frame(category = sample(c("Category A", "Category B", "Category C"), 400, TRUE),
                    subgroup = sample(c("Type 1", "Type 2", "Type 3"), 400, TRUE, prob = c(.45, .45, .1)),
                    year = sample(2023:2024, 400, TRUE), half = sample(c("H1", "H2"), 400, TRUE))
  ops_lab <- list(category = "Category", subgroup = "Type", year = "Year", half = "Half")
  st(phw_flextable(phw_group_table(dat, c("category", "subgroup"), c("year", "half"), labels = ops_lab,
                                   col_totals = c("group", "table")),
                   caption = "Nested row and column groups", number = 6, source = "Example data"), "table-nested")
  st(phw_flextable(phw_group_table(dat, c("category", "subgroup"), labels = ops_lab, layout = "columns",
                                   totals = c("group", "subgroup", "table"), subtotal_position = "below",
                                   percent = "parent", separate = "both"),
                   caption = "Group totals below each group", number = 7, source = "Example data"), "table-nested-columns")
  bars <- data.frame(Area = areas, Count = c(120L, 85L, 64L, 19L, 23L, 51L, 40L))
  st(phw_flextable_bars(phw_flextable(bars, caption = "In-cell bars", source = "Example data"), "Count"), "table-bars")
}

# Interactive widgets
if (requireNamespace("plotly", quietly = TRUE)) {
  w <- phw_plotly(p1 + labs(title = NULL, subtitle = NULL, caption = NULL), source = "Example data")
  htmlwidgets::saveWidget(w, normalizePath(file.path(out, "plotly.html"), mustWork = FALSE), selfcontained = TRUE, title = "PHW plotly")
}
if (requireNamespace("reactable", quietly = TRUE)) {
  r <- phw_reactable(tbl, searchable = TRUE, defaultPageSize = 7)
  htmlwidgets::saveWidget(r, normalizePath(file.path(out, "reactable.html"), mustWork = FALSE), selfcontained = TRUE, title = "PHW reactable")
  save_tags <- function(tags, name) htmltools::save_html(tags, file.path(out, paste0(name, ".html")))
  save_tags(phw_reactable(sum_tab, caption = "Characteristics by outcome", source = "Example data"), "reactable-summary")
  rx <- data.frame(Area = areas, Count = c(120L, 85L, 64L, 19L, 23L, 51L, 40L),
                   Rate = c(4.1, 2.2, 6.3, 1.0, 2.5, 3.3, 2.9), Status = c(0.96, 0.93, 0.91, 0.95, 0.97, 0.92, 0.94),
                   Share = c(.3, .21, .16, .05, .06, .12, .1))
  save_tags(phw_reactable(rx, caption = "Column formats", source = "Example data", columns = list(
    Count = phw_col_bar(rx, "Count"), Rate = phw_col_heat(rx, "Rate"),
    Status = phw_col_rag(breaks = c(0.93, 0.95), digits = 2), Share = phw_col_percent())), "reactable-columns")
}
if (requireNamespace("plotly", quietly = TRUE)) {
  sp <- function(w, name) htmlwidgets::saveWidget(w, normalizePath(file.path(out, paste0(name, ".html")), mustWork = FALSE),
                                                  selfcontained = TRUE, title = "PHW plotly")
  bar <- data.frame(area = rep(areas[1:5], 2), series = rep(c("Series 1", "Series 2"), each = 5), value = round(runif(10, 10, 60)))
  sp(phw_plotly(plotly::plot_ly(bar, x = ~area, y = ~value, color = ~series, type = "bar",
                                colors = phw_colour_key(bar$series, "gallery_series")),
                source = "Example data", title = list(text = "Bar chart")), "plotly-bar")
  sp(phw_plotly(plotly::plot_ly(data.frame(g = paste("Category", 1:4), n = c(45, 30, 15, 10)), labels = ~g, values = ~n,
                                type = "pie", hole = 0.5, sort = FALSE),
                source = "Example data", title = list(text = "Donut chart")), "plotly-donut")
  hmz <- matrix(round(rnorm(7 * 12, 0, 10), 1), 7, dimnames = list(areas, month.abb))
  sp(phw_plotly(plotly::plot_ly(x = colnames(hmz), y = rownames(hmz), z = hmz, type = "heatmap",
                                colorscale = phw_plotly_colorscale("orange_navy"), zmid = 0),
                source = "Example data", title = list(text = "Heatmap")), "plotly-heatmap")
  bx <- plotly::plot_ly(ll, x = ~age_group, y = ~days, color = ~age_group, type = "box",
                        colors = phw_colour_key(ll$age_group, "gallery_age"))
  ln <- plotly::plot_ly(ts, x = ~period, y = ~value, color = ~group, type = "scatter", mode = "lines",
                        colors = phw_colour_key(ts$group, "gallery_groups"))
  sp(phw_plotly(plotly::subplot(bx, ln, nrows = 1, margin = 0.06, titleX = TRUE, titleY = TRUE),
                source = "Example data", title = list(text = "Box plot and lines with subplot()")), "plotly-subplot")
}

# 20-23. Public health charts
cases <- data.frame(onset = as.Date("2025-01-01") + round(rgamma(300, 6, 0.15)),
                    group = sample(c("Group A", "Group B", "Group C"), 300, TRUE))
save(phw_epicurve(cases, "onset", group = "group") +
       labs(title = "Epidemic curve", subtitle = "phw_epicurve(), cases by week of onset",
            x = "Week beginning", y = "Cases", caption = src), "20-epicurve")
ages <- c("0-14", "15-29", "30-44", "45-64", "65-79", "80+")
pop <- expand.grid(age = factor(ages, ages), sex = c("Female", "Male"))
pop$n <- c(240, 280, 300, 410, 260, 90, 250, 290, 295, 400, 240, 60) * 1000
cmp <- pop; cmp$n <- round(cmp$n * runif(12, 0.8, 1.2))
save(phw_pyramid(pop, "age", "sex", value = "n", percent = TRUE, compare = cmp) +
       labs(title = "Population pyramid", subtitle = "phw_pyramid(), outlines show a comparison population",
            caption = src), "21-pyramid")
units <- data.frame(unit = paste("Unit", 1:40), n = round(runif(40, 200, 5000)))
units$events <- rbinom(40, units$n, c(rep(0.12, 37), 0.2, 0.05, 0.17))
save(phw_funnel(units, "events", "n", label = "unit") +
       labs(title = "Funnel plot", subtitle = "phw_funnel(), 95% and 99.8% limits around the overall value",
            x = "Population", y = "Proportion (%)", caption = src), "22-funnel")
spc <- data.frame(month = seq(as.Date("2023-01-01"), by = "month", length.out = 30),
                  value = c(rnorm(20, 50, 4), rnorm(10, 58, 4)))
save(phw_spc(spc, "month", "value", improvement = "increase", baseline = 20) +
       labs(title = "SPC chart", subtitle = "phw_spc(), limits from the first 20 months",
            y = "Measure", caption = src), "23-spc")

# 24-35. More chart combinations, all built from plain ggplot2 plus phwstyle
# 24. Rate over time with a confidence ribbon (exact Poisson limits)
rt <- data.frame(month = seq(as.Date("2024-01-01"), by = "month", length.out = 24))
rt$pop <- 250000
rt$cases <- rpois(24, 60 + 25 * sin((1:24) / 3))
ci <- phw_poisson_ci(rt$cases)
rt$rate <- rt$cases / rt$pop * 1e5
rt$lower <- ci$lower / rt$pop * 1e5
rt$upper <- ci$upper / rt$pop * 1e5
p24 <- ggplot(rt, aes(month, rate)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), fill = phw_col("light_teal"), alpha = 0.6) +
  geom_line(colour = phw_col("navy"), linewidth = 1) +
  scale_x_date(date_labels = "%b %Y", date_breaks = "4 months") +
  labs(title = "Rate with a 95% confidence interval", subtitle = "phw_poisson_ci() for the limits, geom_ribbon() for the band",
       x = NULL, y = "Rate per 100,000", caption = src)
save(p24, "24-ribbon")

# 25. Forest-style plot: rates by area with intervals and the overall rate
fa <- data.frame(area = areas, pop = round(runif(7, 60, 200)) * 1000)
fa$cases <- rpois(7, fa$pop / 1e5 * c(40, 55, 30, 70, 45, 38, 52))
fci <- phw_poisson_ci(fa$cases)
fa$rate <- fa$cases / fa$pop * 1e5; fa$lower <- fci$lower / fa$pop * 1e5; fa$upper <- fci$upper / fa$pop * 1e5
overall <- sum(fa$cases) / sum(fa$pop) * 1e5
fa$vs <- ifelse(fa$lower > overall, "Higher", ifelse(fa$upper < overall, "Lower", "Similar"))
p25 <- ggplot(fa, aes(rate, reorder(area, rate), colour = vs)) +
  geom_vline(xintercept = overall, linetype = "dashed", colour = phw_col("text_secondary")) +
  geom_errorbar(aes(xmin = lower, xmax = upper), width = 0.25, linewidth = 0.8, orientation = "y") +
  geom_point(size = 3) +
  scale_colour_manual(values = c(Higher = unname(phw_col("magenta")), Similar = unname(phw_col("grey_mid")), Lower = unname(phw_col("navy"))),
                      breaks = c("Higher", "Similar", "Lower"), name = "Compared with overall") +
  labs(title = "Rates by area with confidence intervals", subtitle = "Dashed line: overall rate. phw_poisson_ci() and phw_col()",
       x = "Rate per 100,000", y = NULL, caption = src) +
  theme_phw(grid = "x", legend_title = TRUE)
save(p25, "25-forest")

# 26. Scatter with a continuous colour scale and a fitted line
sc <- data.frame(x = runif(120, 0, 100))
sc$y <- 20 + 0.6 * sc$x + rnorm(120, 0, 10)
sc$z <- sc$x / 100 + rnorm(120, 0, 0.15)
p26 <- ggplot(sc, aes(x, y)) +
  geom_smooth(method = "lm", formula = y ~ x, colour = phw_col("navy"), fill = phw_col("grey_border")) +
  geom_point(aes(colour = z), size = 2.2) +
  scale_colour_phw_c(name = "Third measure") +
  labs(title = "Scatter plot with a continuous colour scale", subtitle = "scale_colour_phw_c() with geom_smooth()",
       x = "Measure X", y = "Measure Y", caption = src) +
  theme_phw(legend = "right", legend_title = TRUE)
save(p26, "26-scatter")

# 27. Stacked area over time
sa <- expand.grid(week = 1:30, group = groups)
sa$n <- round(pmax(0, 20 + as.integer(sa$group) * 5 + 15 * sin((sa$week + as.integer(sa$group) * 3) / 5) + rnorm(nrow(sa), 0, 3)))
p27 <- ggplot(sa, aes(week, n, fill = group)) +
  geom_area(colour = "white", linewidth = 0.3) +
  scale_fill_phw_d(key = "gallery_groups") +
  labs(title = "Stacked area chart", subtitle = "Same colour key as the line chart, so groups match across charts",
       x = "Week", y = "Count", caption = src)
save(p27, "27-stacked-area")

# 28. Bars with a rolling average line
rb <- data.frame(day = seq(as.Date("2025-03-01"), by = "day", length.out = 60))
rb$n <- rpois(60, 20 + 10 * sin((1:60) / 9))
rb$avg <- as.numeric(stats::filter(rb$n, rep(1 / 7, 7), sides = 1))
p28 <- ggplot(rb, aes(day)) +
  geom_col(aes(y = n, fill = "Daily count"), width = 0.8) +
  geom_line(aes(y = avg, colour = "7-day average"), linewidth = 1.1, na.rm = TRUE) +
  scale_fill_manual(values = unname(phw_col("light_teal")), name = NULL) +
  scale_colour_manual(values = unname(phw_col("navy")), name = NULL) +
  scale_x_date(date_labels = "%d %b") +
  labs(title = "Daily counts with a rolling average", subtitle = "geom_col() and geom_line() with PHW colours",
       x = NULL, y = "Count", caption = src)
save(p28, "28-bar-line")

# 29. Distributions: histograms in small multiples
hd <- data.frame(group = rep(groups, each = 250), value = rgamma(1000, shape = rep(c(2, 3, 4, 6), each = 250), rate = 0.5))
p29 <- ggplot(hd, aes(value, fill = group)) +
  geom_histogram(binwidth = 1, colour = "white", linewidth = 0.2) +
  facet_wrap(~group, nrow = 1) +
  scale_fill_phw_d(key = "gallery_groups", guide = "none") +
  labs(title = "Histograms by group", subtitle = "facet_wrap() with the gallery colour key", x = "Value", y = "Count",
       caption = src)
save(p29, "29-histogram", h = 8)

# 30. Observed and projected lines with linetypes
pj <- rbind(data.frame(year = 2015:2025, value = 50 + (0:10) * 2.2 + rnorm(11, 0, 1.5), type = "Observed"),
            data.frame(year = 2025:2032, value = NA, type = "Projected"))
pj$value[pj$type == "Projected"] <- pj$value[pj$year == 2025 & pj$type == "Observed"] + (0:7) * 1.6
p30 <- ggplot(pj, aes(year, value, linetype = type, colour = type)) +
  geom_line(linewidth = 1.1) +
  scale_linetype_phw() + scale_colour_phw_d() +
  labs(title = "Observed and projected values", subtitle = "scale_linetype_phw() keeps lines apart in black and white",
       x = NULL, y = "Value", caption = src)
save(p30, "30-linetype")

# 31. Dumbbell: change between two periods
db <- data.frame(area = areas, before = c(42, 55, 38, 61, 47, 52, 44))
db$after <- db$before + c(6, -4, 9, 3, -2, 7, 1)
dbl <- rbind(data.frame(area = db$area, period = "Period 1", value = db$before),
             data.frame(area = db$area, period = "Period 2", value = db$after))
p31 <- ggplot(db, aes(y = reorder(area, after))) +
  geom_segment(aes(x = before, xend = after, yend = reorder(area, after)), colour = phw_col("grey_mid"), linewidth = 1.2) +
  geom_point(data = dbl, aes(x = value, y = area, colour = period), size = 3.5) +
  scale_colour_phw_d() +
  labs(title = "Change between two periods", subtitle = "A dumbbell chart from geom_segment() and geom_point()",
       x = "Value", y = NULL, caption = src) +
  theme_phw(grid = "x")
save(p31, "31-dumbbell")

if (requireNamespace("sf", quietly = TRUE)) {
  # 32. Small-multiple maps, one per year
  la3 <- do.call(rbind, lapply(2023:2025, function(y) { d <- la; d$year <- y; d$value <- round(runif(nrow(la), 0, 9), 1); d }))
  p32 <- ggplot(la3) + geom_sf(aes(fill = value), colour = "white", linewidth = 0.2) +
    facet_wrap(~year) +
    scale_fill_phw_b(name = "Value", breaks = c(2, 4, 6, 8)) +
    labs(title = "One map per year", subtitle = "facet_wrap() on an sf data frame with theme_phw_map()",
         caption = phw_caption("Example data. Boundaries: ONS (OGL v3)")) +
    theme_phw_map()
  save(p32, "32-map-facets", w = 20, h = 10)

  # 33. Health boards by name with sites as points and labels
  hbm <- phw_boundaries("health_board", quiet = TRUE)
  hbm$short <- sub(" (University )?(Teaching )?Health Board$", "", hbm$name)
  sites <- sf::st_sample(sf::st_union(hbm), 25)
  sites <- sf::st_sf(type = sample(c("Site type 1", "Site type 2"), 25, TRUE), geometry = sites)
  p33 <- ggplot() +
    geom_sf(data = hbm, aes(fill = short), colour = "white", linewidth = 0.4, alpha = 0.85) +
    geom_sf(data = sites, colour = "white", size = 4.2) +            # white halo so points show on any fill
    geom_sf(data = sites, aes(shape = type), size = 2.4, colour = phw_col("text")) +
    scale_fill_phw_d(palette = "extended", name = NULL) +
    scale_shape_phw(name = NULL) +
    labs(title = "Areas by name with points on top", subtitle = "phw_boundaries(\"health_board\"), random sites",
         caption = phw_caption("Example data. Boundaries: ONS (OGL v3)")) +
    theme_phw_map(legend = "right")
  save(p33, "33-map-points", w = 18, h = 13)
}

# gt, gtsummary, DT, leaflet, Excel and PowerPoint
ops2 <- data.frame(category = sample(c("Category A", "Category B", "Category C"), 300, TRUE),
                   subgroup = sample(c("Type 1", "Type 2", "Type 3"), 300, TRUE),
                   year = sample(2023:2024, 300, TRUE))
grouped <- phw_group_table(ops2, c("category", "subgroup"), "year",
                           labels = list(category = "Category", subgroup = "Type", year = "Year"))
if (requireNamespace("gt", quietly = TRUE)) {
  gt::gtsave(phw_gt(grouped, caption = "A grouped table with gt", source = "Example data"),
             normalizePath(file.path(out, "gt-table.html"), mustWork = FALSE))
}
if (requireNamespace("gtsummary", quietly = TRUE)) {
  use_phw_gtsummary()
  tb <- gtsummary::tbl_summary(ll[, c("age_group", "sex", "days", "outcome")], by = outcome,
                               label = list(age_group ~ "Age group", sex ~ "Sex", days ~ "Days to recovery"))
  gt::gtsave(gtsummary::as_gt(tb), normalizePath(file.path(out, "gtsummary.html"), mustWork = FALSE))
  gtsummary::reset_gtsummary_theme()
}
if (requireNamespace("DT", quietly = TRUE)) {
  htmltools::save_html(phw_datatable(data.frame(Area = areas, Count = c(120L, 85L, 64L, 19L, 23L, 51L, 40L),
                                                Rate = c(4.1, 2.2, 6.3, 1.0, 2.5, 3.3, 2.9)),
                                     caption = "Searchable table with DT", source = "Example data"),
                       file.path(out, "dt.html"))
}
if (requireNamespace("leaflet", quietly = TRUE) && requireNamespace("sf", quietly = TRUE)) {
  hb <- phw_boundaries("health_board", crs = 4326, quiet = TRUE)
  hb$rate <- round(runif(nrow(hb), 10, 50), 1)
  m <- phw_leaflet() |>
    phw_leaflet_polygons(hb, fill = "rate", bins = c(10, 20, 30, 40, 50), label = "name", legend_title = "Rate")
  htmlwidgets::saveWidget(m, normalizePath(file.path(out, "leaflet.html"), mustWork = FALSE), selfcontained = TRUE)
  hb$band <- cut(hb$rate, c(10, 25, 40, 50), labels = c("Low", "Middle", "High"), include.lowest = TRUE)
  m2 <- phw_leaflet() |>
    phw_leaflet_polygons(hb, fill = "band", palette = "accessible", label = "name", legend_title = "Band")
  htmlwidgets::saveWidget(m2, normalizePath(file.path(out, "leaflet-groups.html"), mustWork = FALSE), selfcontained = TRUE)
}
if (requireNamespace("openxlsx2", quietly = TRUE)) {
  phw_write_xlsx(list(Grouped = grouped, Areas = data.frame(Area = areas, Count = c(120L, 85L, 64L, 19L, 23L, 51L, 40L))),
                 file.path(out, "tables.xlsx"), title = c("A grouped table", "Counts by area"), source = "Example data")
}
if (requireNamespace("officer", quietly = TRUE)) {
  deck <- phw_pptx() |>
    phw_add_slide("Key messages", text = c("First message", "Second message")) |>
    phw_add_slide("Cases by week", plot = phw_epicurve(cases, "onset", group = "group"), source = "Example data") |>
    phw_add_slide("A grouped table", table = grouped, source = "Example data")
  print(deck, target = file.path(out, "slides.pptx"))
}
message("Gallery written to ", out)
