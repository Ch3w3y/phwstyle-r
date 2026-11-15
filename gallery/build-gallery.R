# Render a gallery of phwstyle outputs for visual review and documentation.
# All data are made up and labelled neutrally, so images can go in docs. The
# data are sized like real outputs (thousands of records, many areas, weekly
# series over several years) so each chart shows how it looks in practice.
# Maps use the real boundaries from phw_boundaries() with made-up values.
# Run from the package root after installing phwstyle:
#   Rscript gallery/build-gallery.R
# Outputs go to gallery/_output (git-ignored). Convert the images you want to
# show to .webp in man/figures, then run gallery/build-gallery-page.R to
# rebuild the gallery page on the documentation site.

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
map_src <- phw_caption("Example data. Boundaries: ONS and Welsh Government (OGL v3)")

save <- function(p, name, w = 16, h = 10) phw_save(p, file.path(out, paste0(name, ".png")), width = w, height = h, dpi = 200)

# As many areas as Wales has local authorities, and five groups.
areas <- sprintf("Area %02d", 1:22)
groups <- paste("Group", 1:5)
ages5 <- c(paste0(seq(0, 85, 5), "-", seq(4, 89, 5)), "90+")
months <- seq(as.Date("2021-01-01"), as.Date("2025-12-01"), by = "month")
weeks <- seq(as.Date("2023-01-02"), as.Date("2025-12-29"), by = "week")
season <- function(d) cos(2 * pi * (as.numeric(format(d, "%j")) - 15) / 365.25)

# 1. Lines by group over five years, with shapes as a second cue
ts <- expand.grid(month = months, group = groups)
ts$value <- round(40 + 6 * as.integer(ts$group) + 0.15 * match(ts$month, months) +
                    (4 + as.integer(ts$group)) * season(ts$month) + rnorm(nrow(ts), 0, 2), 1)
p1 <- ggplot(ts, aes(month, value, colour = group, shape = group)) +
  geom_line(linewidth = 0.8) + geom_point(size = 1.6) +
  scale_colour_phw_d(key = "gallery_groups") + scale_shape_phw() +
  scale_x_date(date_labels = "%Y", date_breaks = "1 year") +
  labs(title = "Line chart with colour and shape",
       subtitle = "Monthly values for five groups. scale_colour_phw_d() + scale_shape_phw()",
       x = NULL, y = "Value", caption = src)
save(p1, "01-line")

# 2. Facet wrap small multiples: three years of weekly values for every area
fw <- expand.grid(week = weeks, area = areas)
fw$value <- pmax(0, 20 + as.integer(factor(fw$area)) * 0.6 + 12 * season(fw$week) + rnorm(nrow(fw), 0, 3))
p2 <- ggplot(fw, aes(week, value)) +
  geom_area(fill = phw_col("light_teal"), alpha = 0.6) +
  geom_line(colour = phw_col("navy"), linewidth = 0.4) +
  facet_wrap(~area, ncol = 5) +
  scale_x_date(breaks = as.Date(c("2024-01-01", "2025-01-01")), date_labels = "%Y") +
  scale_y_continuous(breaks = c(0, 25, 50)) +
  labs(title = "Small multiples with facet_wrap()", subtitle = "Weekly values for 22 areas over three years",
       x = NULL, y = "Value", caption = src)
save(p2, "02-facet-wrap", w = 18, h = 13)

# 3. Horizontal bar with labels
hb <- data.frame(area = areas, value = round(rgamma(length(areas), 9, 2.5), 1))
p3 <- ggplot(hb, aes(value, reorder(area, value))) +
  geom_col(fill = phw_col("navy"), width = 0.7) +
  geom_text(aes(label = format(value, nsmall = 1)), hjust = -0.25, size = 3.2) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(title = "Horizontal bar chart", subtitle = 'theme_phw(grid = "x")', x = "Value", y = NULL, caption = src) +
  theme_phw(grid = "x")
save(p3, "03-bar-horizontal", h = 12)

# 4. Grouped columns faceted by two variables
regions <- paste("Region", 1:7)
gc <- expand.grid(region = regions, series = c("Series 1", "Series 2"),
                  measure = c("Measure X", "Measure Y", "Measure Z"), year = c("2024", "2025"))
gc$share <- round(pmin(0.99, runif(nrow(gc), 0.7, 0.92) + 0.03 * (gc$year == "2025")), 3)
p4 <- ggplot(gc, aes(region, share, fill = series)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.75) +
  geom_hline(yintercept = 0.9, linetype = "dashed", colour = phw_col("text_secondary")) +
  facet_grid(measure ~ year) +
  scale_x_discrete(labels = function(x) sub("Region ", "R", x)) +
  scale_y_continuous(labels = phw_percent(1), limits = c(0, 1), breaks = c(0, 0.5, 0.9)) +
  labs(title = "Dodged columns with facet_grid()",
       subtitle = 'Three measures by two years. Dashed line: a target. theme_phw(strip = "navy")',
       x = "Region", y = "Share", caption = src) +
  theme_phw(strip = "navy")
save(p4, "04-facet-grid-dodged", h = 12)

# 5. 100% stacked bars over ten years, with "Unknown" drawn grey automatically
cats <- c(paste("Category", 1:5), "Unknown")
mix <- expand.grid(year = 2016:2025, category = factor(cats, cats))
mix$n <- round(c(40, 30, 25, 15, 10, 4)[as.integer(mix$category)] *
                 (1 + 0.04 * (mix$year - 2016) * c(1, -0.5, 0.5, 1.5, 2, -1.5)[as.integer(mix$category)]) *
                 runif(nrow(mix), 0.9, 1.1))
p5 <- ggplot(mix, aes(factor(year), n, fill = category)) +
  geom_col(position = "fill", width = 0.7) +
  scale_fill_phw_d() +
  scale_y_continuous(labels = phw_percent(1)) +
  labs(title = "100% stacked bars", subtitle = '"Unknown" is grey automatically', x = NULL, y = "Proportion",
       caption = src)
save(p5, "05-stacked-100")

# Maps: real boundaries, made-up values that vary smoothly across Wales
if (requireNamespace("sf", quietly = TRUE)) {
  smooth_values <- function(b, lo, hi, noise = 0.25) {
    xy <- sf::st_coordinates(suppressWarnings(sf::st_point_on_surface(sf::st_geometry(b))))
    x <- (xy[, 1] - min(xy[, 1])) / diff(range(xy[, 1]))
    y <- (xy[, 2] - min(xy[, 2])) / diff(range(xy[, 2]))
    s <- sin(3 * x + 1) + cos(4 * y) + rnorm(nrow(b), 0, noise)
    lo + (hi - lo) * (s - min(s)) / diff(range(s))
  }
  la <- phw_boundaries("local_authority", quiet = TRUE)
  msoa <- phw_boundaries("msoa", quiet = TRUE)

  # 6. Choropleth map of small areas
  ms <- data.frame(code = msoa$code, value = round(smooth_values(msoa, 0.5, 9.5), 1))
  p6 <- phw_map(ms, by = code, fill = value, level = msoa, bins = c(2, 4, 6, 8), linewidth = 0.1) +
    labs(title = "Choropleth map", subtitle = paste0("Made-up values for ", nrow(msoa), " MSOAs. phw_map()"),
         fill = "Value", caption = map_src)
  save(p6, "06-map", w = 14, h = 14)

  # 6b. Boundaries for several levels, downloaded and cached by phw_boundaries()
  if (requireNamespace("patchwork", quietly = TRUE)) {
    bmap <- function(level, title) {
      b <- phw_boundaries(level, quiet = TRUE)
      b$value <- smooth_values(b, 0, 1)
      ggplot(b) + geom_sf(aes(fill = value), colour = "white", linewidth = 0.15) +
        scale_fill_phw_c(guide = "none") + labs(title = title, subtitle = paste(nrow(b), "areas")) +
        theme_phw_map()
    }
    p6b <- phw_arrange(bmap("health_board", "Health boards"), bmap("gp_cluster", "GP clusters"),
                       bmap("senedd_constituency", "Senedd constituencies"), bmap("msoa", "MSOAs"),
                       ncol = 4, title = "Boundaries for every level", subtitle = "phw_boundaries(), made-up values",
                       source = "Example data. Boundaries: ONS and Welsh Government (OGL v3)")
    save(p6b, "06-boundaries", w = 24, h = 9)
  }
}

# 7. Heatmap with diverging scale
hm <- expand.grid(month = factor(month.abb, levels = month.abb), area = factor(areas, rev(areas)))
hm$change <- round(rnorm(nrow(hm), 0, 9) + 6 * cos(2 * pi * (as.integer(hm$month) - 1) / 12), 0)
p7 <- ggplot(hm, aes(month, area, fill = change)) +
  geom_tile(colour = "white", linewidth = 0.6) +
  geom_text(aes(label = change, colour = after_scale(phw_text_on(fill))), size = 2.6) +
  scale_fill_phw_div(midpoint = 0, name = "% change") +
  labs(title = "Diverging heatmap", subtitle = "scale_fill_phw_div(midpoint = 0)", x = NULL, y = NULL,
       caption = src) +
  theme_phw(grid = "none", legend = "right", legend_title = TRUE)
save(p7, "07-heatmap-diverging", h = 12)

# 8. Distributions: boxplots for every area, with one highlighted
stay <- data.frame(area = sample(areas, 6000, TRUE))
stay$days <- round(rgamma(nrow(stay), shape = 2 + match(stay$area, areas) %% 5 / 2, rate = 0.35))
p8 <- ggplot(stay, aes(days, reorder(area, days, median), fill = area == "Area 07")) +
  geom_boxplot(width = 0.6, outlier.colour = phw_col("grey_mid"), outlier.size = 0.6) +
  scale_fill_phw_d(palette = "highlight", reverse = TRUE, guide = "none") +
  labs(title = "Highlight one group", subtitle = "Using the 'highlight' palette. 6,000 made-up stays",
       x = "Length of stay (days)", y = NULL, caption = src) +
  theme_phw(grid = "x")
save(p8, "08-boxplot-highlight", h = 12)

# 9. Finalised chart with logo footer
p9 <- ggplot(hb, aes(value, reorder(area, value))) +
  geom_col(fill = phw_col("teal"), width = 0.7) +
  labs(title = "Chart with the PHW footer", subtitle = "phw_finalise()", x = "Value", y = NULL) +
  theme_phw(grid = "x")
save(phw_finalise(p9, source = "Example data", team = "Team name"), "09-finalised", h = 12)

# 10. Palettes, as seen with normal vision and with deuteranopia
# Wide enough for the twelve hex codes of "extended" to fit their tiles.
save(show_phw_palettes(), "10-palettes", w = 26, h = 12)
save(show_phw_palettes(cvd = "deutan") + labs(title = "The same palettes with deuteranopia (phw_cvd)"),
     "11-palettes-deutan", w = 26, h = 12.5)

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
many <- expand.grid(month = months, group = paste("Group", 1:7))
many$value <- round(as.integer(many$group) * 6 + match(many$month, months) * 0.3 +
                      3 * season(many$month) + rnorm(nrow(many), 0, 1.2), 1)
p13 <- ggplot(many, aes(month, value, colour = group)) +
  geom_line(linewidth = 0.8) +
  scale_colour_phw_d(palette = "accessible") +
  scale_x_date(date_labels = "%Y", date_breaks = "1 year") +
  labs(title = "Seven groups, colour-blind safe", subtitle = 'scale_colour_phw_d(palette = "accessible")',
       x = NULL, y = "Value", caption = src) +
  theme_phw(legend = "right")
save(p13, "13-accessible")

# 14-19. Extension packages and multi-plot layouts
if (requireNamespace("ggalluvial", quietly = TRUE)) {
  # Any number of stages: add axis4, axis5... (or use the long "lodes" format).
  n_fl <- 3000
  fl <- data.frame(s1 = sample(c("Setting A", "Setting B", "Setting C", "Setting D"), n_fl, TRUE, prob = c(.4, .3, .2, .1)))
  fl$s2 <- ifelse(runif(n_fl) < 0.5, "Route X",
                  sample(c("Route X", "Route Y", "Route Z"), n_fl, TRUE, prob = c(.2, .5, .3)))
  fl$s3 <- sample(c("Done", "Ongoing", "Stopped"), n_fl, TRUE, prob = c(.6, .28, .12))
  fl <- aggregate(list(n = rep(1, n_fl)), fl[c("s1", "s2", "s3")], sum)
  p14 <- ggplot(fl, aes(axis1 = s1, axis2 = s2, axis3 = s3, y = n)) +
    ggalluvial::geom_alluvium(aes(fill = s1), width = 0.25) +   # coloured by scale_fill_phw_d()
    ggalluvial::geom_stratum(width = 0.25) +                    # styled by phw_style_extensions()
    geom_text(stat = ggalluvial::StatStratum, aes(label = after_stat(stratum)), size = 3) +
    scale_x_discrete(limits = c("Stage 1", "Stage 2", "Stage 3"), expand = c(0.08, 0.08)) +
    scale_fill_phw_d() +
    labs(title = "Flow (Sankey-style) diagram", subtitle = "ggalluvial with three stages, 3,000 records",
         x = NULL, y = "Count", caption = src) +
    theme_phw(legend = "none")
  save(p14, "14-alluvial")
}
if (requireNamespace("ggridges", quietly = TRUE)) {
  rd <- data.frame(month = factor(sample(month.abb, 12000, TRUE), rev(month.abb)))
  rd$value <- rnorm(nrow(rd), 20 + 8 * cos(2 * pi * (match(rd$month, month.abb) - 1) / 12), 4)
  p15 <- ggplot(rd, aes(value, month)) +
    ggridges::geom_density_ridges(scale = 1.8) +
    labs(title = "Ridgeline plot", subtitle = "ggridges, one distribution per month", x = "Value", y = NULL,
         caption = src)
  save(p15, "15-ridges", h = 12)
}
if (requireNamespace("treemapify", quietly = TRUE)) {
  tm <- expand.grid(sub = 1:5, group = paste("Group", 1:4))
  tm <- tm[!(tm$group == "Group 4" & tm$sub > 3), ]
  tm$label <- paste0(sub("Group ", "", tm$group), ".", tm$sub)
  tm$n <- round(runif(nrow(tm), 15, 90) * c(1.6, 1.2, 1, 0.7)[as.integer(tm$group)])
  p16 <- ggplot(tm, aes(area = n, fill = group, subgroup = group, label = paste0("Type ", label, "\n", n))) +
    treemapify::geom_treemap() +
    treemapify::geom_treemap_subgroup_border(colour = "white", size = 4) +
    treemapify::geom_treemap_text(place = "topleft", padding.x = grid::unit(2, "mm"),
                                  padding.y = grid::unit(2, "mm"), size = 11) +
    scale_fill_phw_d() +
    labs(title = "Treemap", subtitle = "treemapify: types nested in groups, white labels and borders by default",
         fill = NULL, caption = src)
  save(p16, "16-treemap")
}
if (requireNamespace("ggrepel", quietly = TRUE)) {
  rp <- data.frame(x = rnorm(length(areas), 50, 15), label = areas)
  rp$y <- round(10 + 0.4 * rp$x + rnorm(nrow(rp), 0, 5), 1)
  p17 <- ggplot(rp, aes(x, y, label = label)) + geom_point(colour = phw_col("navy"), size = 2) +
    ggrepel::geom_text_repel(size = 3.2, seed = 1) +
    labs(title = "Labels that avoid each other", subtitle = "ggrepel in the PHW font", x = "Measure X",
         y = "Measure Y", caption = src)
  save(p17, "17-repel")
}
if (requireNamespace("patchwork", quietly = TRUE)) {
  pa <- ggplot(hb, aes(value, reorder(area, value))) + geom_col(fill = phw_col("navy"), width = 0.7) +
    labs(title = "Panel one", x = "Value", y = NULL) + theme_phw(grid = "x")
  pb <- ggplot(ts, aes(month, value, colour = group)) + geom_line(linewidth = 0.7) +
    scale_colour_phw_d(key = "gallery_groups") + labs(title = "Panel two", x = NULL, y = "Value")
  save(phw_arrange(pa, pb, title = "Several charts in one figure", subtitle = "phw_arrange(), using patchwork",
                   source = "Example data", tag_levels = "A", widths = c(1, 1.6)), "18-arrange", w = 20, h = 11)
}
if (requireNamespace("gridExtra", quietly = TRUE)) {
  g <- gridExtra::arrangeGrob(p3 + labs(title = NULL, subtitle = NULL, caption = NULL),
                              p5 + labs(title = NULL, subtitle = NULL, caption = NULL), ncol = 2,
                              top = phw_title_grob("gridExtra layout", "phw_title_grob() and phw_finalise()"))
  save(phw_finalise(g, source = "Example data"), "19-gridextra", w = 20, h = 12)
}

# Area tables: one row per area, a column per year
yrs <- as.character(2021:2025)
tbl <- data.frame(Area = areas, check.names = FALSE)
base <- rgamma(length(areas), 8, 2.5)
for (y in yrs) tbl[[y]] <- round(pmax(0, base * runif(length(areas), 0.75, 1.25)), 1)
tbl$Count <- as.integer(round(tbl[["2025"]] * runif(length(areas), 8, 14)))
rag <- data.frame(Area = areas, check.names = FALSE)
for (m in paste("Measure", 1:4)) rag[[m]] <- round(pmin(0.99, rnorm(length(areas), 0.947, 0.016)), 3)
if (requireNamespace("flextable", quietly = TRUE)) {
  for (s in c("booktabs", "header", "light", "zebra")) {
    ft <- phw_flextable(tbl, caption = sprintf('Table style "%s"', s), number = 1, source = "Example data",
                        style = s, bold_first_col = TRUE)
    flextable::save_as_image(ft, file.path(out, paste0("table-", s, ".png")), res = 200)
  }
  heat <- phw_flextable_heat(phw_flextable(tbl[, c("Area", yrs)], caption = "Heat table", source = "Example data"),
                             j = 2:6)
  flextable::save_as_image(heat, file.path(out, "table-heat.png"), res = 200)
  ragft <- phw_flextable(rag, caption = "RAG status with shapes for colour-blind readers", source = "Example data", digits = 3)
  ragft <- phw_flextable_heat(ragft, j = 2:5, palette = "rag_accessible", breaks = c(0.93, 0.95))
  flextable::save_as_image(ragft, file.path(out, "table-rag.png"), res = 200)
  grp <- data.frame(Group = c(groups, "Unknown"), Count = c(1210L, 860L, 655L, 420L, 230L, 95L))
  grp$Share <- round(grp$Count / sum(grp$Count), 2)
  gft <- phw_flextable_groups(phw_flextable(grp, caption = "Cells coloured by group key", source = "Example data",
                                            digits = 2),
                              j = Group, key = "gallery_groups")
  flextable::save_as_image(gft, file.path(out, "table-groups.png"), res = 200)
}

# Summary tables: a made-up line list of 5,000 cases and aggregated data
set.seed(7)
n_ll <- 5000
age_bands <- c("0-4", "5-14", "15-24", "25-44", "45-64", "65-74", "75+")
ll <- data.frame(
  age_group = factor(sample(age_bands, n_ll, TRUE, prob = c(.08, .1, .12, .25, .22, .12, .11)), levels = age_bands),
  sex = sample(c("Female", "Male", NA), n_ll, TRUE, prob = c(.49, .49, .02)),
  setting = sample(paste("Setting", 1:4), n_ll, TRUE, prob = c(.45, .25, .2, .1)),
  days = rpois(n_ll, 5),
  outcome = sample(c("Outcome X", "Outcome Y", "Outcome Z"), n_ll, TRUE, prob = c(.6, .3, .1)),
  month = factor(sample(month.abb, n_ll, TRUE), month.abb))
labs_ll <- list(age_group = "Age group", sex = "Sex", setting = "Setting", days = "Days to recovery",
                outcome = "Outcome")
sum_tab <- phw_summary_table(ll, vars = c(age_group, sex, setting, days), by = outcome, labels = labs_ll)
agg <- expand.grid(age_group = age_bands, sex = c("Female", "Male"), group = c("Group A", "Group B", "Group C"))
agg$pop <- round(runif(nrow(agg), 40, 120)) * 1000
agg$cases <- rpois(nrow(agg), agg$pop / 1e5 * rep(c(30, 15, 20, 35, 55, 80, 120), 6))
rate_tab <- phw_rate_table(agg, c(age_group, sex, group), cases, pop,
                           labels = list(age_group = "Age group", sex = "Sex", group = "Risk group"))
ob <- data.frame(item_a = sample(c("Yes", "No"), 400, TRUE))
for (it in c("item_b", "item_c", "item_d", "item_e", "item_f")) ob[[it]] <- sample(c("Yes", "No"), 400, TRUE)
ob$ill <- rbinom(400, 1, ifelse(ob$item_a == "Yes", 0.55, 0.15) + ifelse(ob$item_d == "Yes", 0.1, 0))
risk_tab <- phw_risk_table(ob, c(item_a, item_b, item_c, item_d, item_e, item_f), ill,
                           labels = list(item_a = "Exposure A", item_b = "Exposure B", item_c = "Exposure C",
                                         item_d = "Exposure D", item_e = "Exposure E", item_f = "Exposure F"))
xt <- phw_crosstab(ll, month, age_group, labels = list(month = "Month", age_group = "Age group"))
dat <- data.frame(category = sample(paste("Category", LETTERS[1:4]), n_ll, TRUE, prob = c(.4, .3, .2, .1)),
                  subgroup = sample(c("Type 1", "Type 2", "Type 3"), n_ll, TRUE, prob = c(.45, .4, .15)),
                  year = sample(2023:2025, n_ll, TRUE), half = sample(c("H1", "H2"), n_ll, TRUE))
ops_lab <- list(category = "Category", subgroup = "Type", year = "Year", half = "Half")
if (requireNamespace("flextable", quietly = TRUE)) {
  st <- function(ft, name) flextable::save_as_image(ft, file.path(out, paste0(name, ".png")), res = 200)
  st(phw_flextable(sum_tab, caption = "Characteristics by outcome", number = 2, source = "Example data"), "table-summary")
  st(phw_flextable(rate_tab, caption = "Rates by demographic and risk group", number = 3, source = "Example data"), "table-rates")
  st(phw_flextable(risk_tab, caption = "Attack rates by exposure", number = 4, source = "Example data"), "table-risk")
  xft <- phw_flextable_heat(phw_flextable(xt, caption = "Counts by month and age group", number = 5,
                                          source = "Example data"), j = 2:8)
  st(xft, "table-crosstab")
  own <- data.frame(
    Characteristic = c("Age group", "0-14", "15-44", "45-64", "65-79", "80+", "All ages",
                       "Setting", "Home", "Care home", "Hospital", "Other", "All settings"),
    Cases = c(NA, 412, 1036, 958, 640, 354, 3400, NA, 2210, 545, 476, 169, 3400),
    kind = c("variable", rep("level", 5), "total", "variable", rep("level", 4), "total"))
  own$Share <- round(own$Cases / 3400, 2)
  own <- own[c("Characteristic", "Cases", "Share", "kind")]
  own <- phw_as_summary(own, row_type = kind, note = "Made-up counts, built with a plain data frame.")
  st(phw_flextable(own, caption = "A table of your own, styled as a summary", number = 8, source = "Example data",
                   digits = 2), "table-as-summary")
  st(phw_flextable(phw_group_table(dat, c(category, subgroup), c(year, half), labels = ops_lab,
                                   col_totals = c("group", "table")),
                   caption = "Nested row and column groups", number = 6, source = "Example data"), "table-nested")
  st(phw_flextable(phw_group_table(dat, c(category, subgroup), labels = ops_lab, layout = "columns",
                                   totals = c("group", "subgroup", "table"), subtotal_position = "below",
                                   percent = "parent", separate = "both"),
                   caption = "Group totals below each group", number = 7, source = "Example data"), "table-nested-columns")
  bars <- tbl[c("Area", "Count")]
  st(phw_flextable_bars(phw_flextable(bars, caption = "In-cell bars", source = "Example data"), Count), "table-bars")
}

# Interactive widgets
if (requireNamespace("plotly", quietly = TRUE)) {
  w <- phw_plotly(p1 + labs(title = NULL, subtitle = NULL, caption = NULL), source = "Example data")
  htmlwidgets::saveWidget(w, normalizePath(file.path(out, "plotly.html"), mustWork = FALSE), selfcontained = TRUE, title = "PHW plotly")
}
rx <- data.frame(Area = areas, Count = tbl$Count, Rate = tbl[["2025"]],
                 Status = rag[["Measure 1"]], Share = round(tbl$Count / sum(tbl$Count), 3))
if (requireNamespace("reactable", quietly = TRUE)) {
  r <- phw_reactable(tbl, searchable = TRUE, defaultPageSize = 10)
  htmlwidgets::saveWidget(r, normalizePath(file.path(out, "reactable.html"), mustWork = FALSE), selfcontained = TRUE, title = "PHW reactable")
  save_tags <- function(tags, name) htmltools::save_html(tags, file.path(out, paste0(name, ".html")))
  save_tags(phw_reactable(sum_tab, caption = "Characteristics by outcome", source = "Example data"), "reactable-summary")
  save_tags(phw_reactable(rx, caption = "Column formats", source = "Example data", defaultPageSize = 12, columns = list(
    Count = phw_col_bar(rx, Count), Rate = phw_col_heat(rx, Rate),
    Status = phw_col_rag(breaks = c(0.93, 0.95), digits = 3), Share = phw_col_percent())), "reactable-columns")
}
if (requireNamespace("plotly", quietly = TRUE)) {
  sp <- function(w, name) htmlwidgets::saveWidget(w, normalizePath(file.path(out, paste0(name, ".html")), mustWork = FALSE),
                                                  selfcontained = TRUE, title = "PHW plotly")
  bar <- data.frame(area = rep(areas, 2), series = rep(c("Series 1", "Series 2"), each = length(areas)),
                    value = round(c(tbl[["2024"]], tbl[["2025"]]) * 10))
  sp(phw_plotly(plotly::plot_ly(bar, x = ~area, y = ~value, color = ~series, type = "bar",
                                colors = phw_colour_key(bar$series, "gallery_series")),
                source = "Example data", title = list(text = "Bar chart")), "plotly-bar")
  sp(phw_plotly(plotly::plot_ly(data.frame(g = paste("Category", 1:4), n = c(45, 30, 15, 10)), labels = ~g, values = ~n,
                                type = "pie", hole = 0.5, sort = FALSE),
                source = "Example data", title = list(text = "Donut chart")), "plotly-donut")
  hmz <- matrix(hm$change, length(areas), byrow = TRUE, dimnames = list(areas, month.abb))
  sp(phw_plotly(plotly::plot_ly(x = colnames(hmz), y = rownames(hmz), z = hmz, type = "heatmap",
                                colorscale = phw_plotly_colorscale("orange_navy"), zmid = 0),
                source = "Example data", title = list(text = "Heatmap")), "plotly-heatmap")
  bx <- plotly::plot_ly(ll, x = ~age_group, y = ~days, color = ~age_group, type = "box",
                        colors = phw_colour_key(ll$age_group, "gallery_age"))
  ln <- plotly::plot_ly(ts, x = ~month, y = ~value, color = ~group, type = "scatter", mode = "lines",
                        colors = phw_colour_key(ts$group, "gallery_groups"))
  sp(phw_plotly(plotly::subplot(bx, ln, nrows = 1, margin = 0.06, titleX = TRUE, titleY = TRUE),
                source = "Example data", title = list(text = "Box plot and lines with subplot()")), "plotly-subplot")
}

# 20-23. Public health charts
# A line list of 4,000 cases over two winters.
wave <- function(n, peak, sd) as.Date(peak) + round(rnorm(n, 0, sd))
cases <- data.frame(onset = c(wave(1500, "2024-01-10", 30), wave(2500, "2025-01-05", 25),
                              as.Date("2023-10-01") + sample(0:600, 600, TRUE)))
cases$group <- sample(c("Group A", "Group B", "Group C", "Group D"), nrow(cases), TRUE, prob = c(.4, .3, .2, .1))
save(phw_epicurve(cases, onset, group = group) +
       labs(title = "Epidemic curve", subtitle = paste0("phw_epicurve(), ", format(nrow(cases), big.mark = ","),
                                                        " cases by week of onset"),
            x = "Week beginning", y = "Cases", caption = src), "20-epicurve")
pop <- expand.grid(age = factor(ages5, ages5), sex = c("Female", "Male"))
shape <- c(5.2, 5.6, 5.8, 5.9, 6.6, 6.4, 6.3, 6.1, 5.9, 6.0, 6.6, 7.0, 6.8, 6.1, 5.6, 4.6, 3.2, 1.9, 1.3)
pop$n <- round(c(shape, shape * c(rep(1.03, 12), 0.98, 0.96, 0.93, 0.88, 0.8, 0.68, 0.48)) * 30000)
cmp <- pop
cmp$n <- round(cmp$n * rep(seq(1.12, 0.85, length.out = length(ages5)), 2) * runif(nrow(cmp), 0.97, 1.03))
save(phw_pyramid(pop, age, sex, value = n, percent = TRUE, compare = cmp) +
       labs(title = "Population pyramid", subtitle = "phw_pyramid(), 5-year age bands, outlines show a comparison population",
            caption = src), "21-pyramid", h = 12)
units <- data.frame(unit = sprintf("Unit %03d", 1:150), n = round(rlnorm(150, log(1500), 0.8)))
units$n <- pmin(pmax(units$n, 150), 15000)
p_unit <- rep(0.12, 150); p_unit[c(12, 57, 101)] <- c(0.19, 0.06, 0.17)
units$events <- rbinom(150, units$n, p_unit)
save(phw_funnel(units, events, n, label = unit) +
       labs(title = "Funnel plot", subtitle = "phw_funnel(), 150 units, 95% and 99.8% limits around the overall value",
            x = "Population", y = "Proportion (%)", caption = src), "22-funnel")
spc <- data.frame(month = seq(as.Date("2021-01-01"), by = "month", length.out = 60))
spc$value <- round(c(rnorm(42, 50, 3), rnorm(18, 56, 3)), 1)
save(phw_spc(spc, month, value, improvement = "increase", baseline = 24) +
       labs(title = "SPC chart", subtitle = "phw_spc(), five years of monthly values, limits from the first 24 months",
            y = "Measure", caption = src), "23-spc")

# 24-35. More chart combinations, all built from plain ggplot2 plus phwstyle
# 24. Weekly rate over three years with a confidence ribbon drawn from limits you supply
rt <- data.frame(week = weeks, pop = 250000)
rt$cases <- rpois(nrow(rt), 45 + 30 * season(rt$week))
ci <- phw_poisson_ci(rt$cases)
rt$rate <- rt$cases / rt$pop * 1e5
rt$lower <- ci$lower / rt$pop * 1e5
rt$upper <- ci$upper / rt$pop * 1e5
p24 <- ggplot(rt, aes(week, rate)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), fill = phw_col("light_teal"), alpha = 0.6) +
  geom_line(colour = phw_col("navy"), linewidth = 0.7) +
  scale_x_date(date_labels = "%b %Y", date_breaks = "6 months") +
  labs(title = "Rate with a 95% confidence interval", subtitle = "Weekly rate. geom_ribbon() with your own limits",
       x = NULL, y = "Rate per 100,000", caption = src)
save(p24, "24-ribbon")

# 25. Forest-style plot: rates by area with intervals and the overall rate
fa <- data.frame(area = areas, pop = round(rlnorm(length(areas), log(130), 0.45)) * 1000)
fa$cases <- rpois(length(areas), fa$pop / 1e5 * rnorm(length(areas), 50, 10))
fci <- phw_poisson_ci(fa$cases)
fa$rate <- fa$cases / fa$pop * 1e5; fa$lower <- fci$lower / fa$pop * 1e5; fa$upper <- fci$upper / fa$pop * 1e5
overall <- sum(fa$cases) / sum(fa$pop) * 1e5
p25 <- phw_forest(fa, rate, lower, upper, area, target = overall) +
  labs(title = "Rates by area with confidence intervals", subtitle = "phw_forest()",
       x = "Rate per 100,000", colour = "Compared with overall", shape = "Compared with overall",
       caption = src)
save(p25, "25-forest", h = 12)

# 26. Scatter with a continuous colour scale and a fitted line, one point per small area
sc <- data.frame(x = rbeta(1900, 2, 3) * 100)
sc$y <- 20 + 0.6 * sc$x + rnorm(nrow(sc), 0, 9)
sc$z <- sc$x / 100 + rnorm(nrow(sc), 0, 0.15)
p26 <- ggplot(sc, aes(x, y)) +
  geom_point(aes(colour = z), size = 1.2, alpha = 0.8) +
  geom_smooth(method = "lm", formula = y ~ x, colour = phw_col("navy"), fill = phw_col("grey_border")) +
  scale_colour_phw_c(name = "Third measure") +
  labs(title = "Scatter plot with a continuous colour scale",
       subtitle = "1,900 small areas. scale_colour_phw_c() with geom_smooth()",
       x = "Measure X", y = "Measure Y", caption = src) +
  theme_phw(legend = "right", legend_title = TRUE)
save(p26, "26-scatter")

# 27. Stacked area over three years of weeks
sa <- expand.grid(week = weeks, group = groups)
sa$n <- round(pmax(0, 10 + as.integer(sa$group) * 3 + (14 - 2 * as.integer(sa$group)) * season(sa$week) +
                     rnorm(nrow(sa), 0, 2)))
p27 <- ggplot(sa, aes(week, n, fill = group)) +
  geom_area(colour = "white", linewidth = 0.2) +
  scale_fill_phw_d(key = "gallery_groups") +
  scale_x_date(date_labels = "%b %Y", date_breaks = "6 months") +
  labs(title = "Stacked area chart", subtitle = "Same colour key as the line chart, so groups match across charts",
       x = NULL, y = "Count", caption = src)
save(p27, "27-stacked-area")

# 28. A year of daily counts with a rolling average line
rb <- data.frame(day = seq(as.Date("2025-01-01"), as.Date("2025-12-31"), by = "day"))
rb$n <- rpois(nrow(rb), (30 + 18 * season(rb$day)) * ifelse(format(rb$day, "%u") %in% c("6", "7"), 0.6, 1))
p28 <- phw_epicurve(rb, day, count = n, interval = "day", average = 7, date_breaks = "1 month", date_labels = "%b") +
  labs(title = "Daily counts with a rolling average", subtitle = "phw_epicurve(average = 7)",
       x = NULL, y = "Count", caption = src)
save(p28, "28-bar-line")

# 29. Distributions: histograms in small multiples
hd <- data.frame(group = rep(groups, each = 2000))
hd$value <- rgamma(nrow(hd), shape = rep(c(2, 3, 4, 6, 8), each = 2000), rate = 0.5)
p29 <- ggplot(hd, aes(value, fill = group)) +
  geom_histogram(binwidth = 1, colour = "white", linewidth = 0.2) +
  facet_wrap(~group, nrow = 1) +
  scale_fill_phw_d(key = "gallery_groups", guide = "none") +
  labs(title = "Histograms by group", subtitle = "facet_wrap() with the gallery colour key, 2,000 values per group",
       x = "Value", y = "Count", caption = src)
save(p29, "29-histogram", h = 8)

# 30. Observed and projected lines with linetypes
pj <- rbind(data.frame(year = 1996:2025, value = 50 + (0:29) * 1.1 + rnorm(30, 0, 1.5), type = "Observed"),
            data.frame(year = 2025:2040, value = NA, type = "Projected"))
pj$value[pj$type == "Projected"] <- pj$value[pj$year == 2025 & pj$type == "Observed"] + (0:15) * 0.9
p30 <- ggplot(pj, aes(year, value, linetype = type, colour = type)) +
  geom_line(linewidth = 1.1) +
  scale_linetype_phw() + scale_colour_phw_d() +
  labs(title = "Observed and projected values", subtitle = "scale_linetype_phw() keeps lines apart in black and white",
       x = NULL, y = "Value", caption = src)
save(p30, "30-linetype")

# 31. Dumbbell: change between two periods
db <- data.frame(area = areas, before = round(rnorm(length(areas), 50, 8)))
db$after <- db$before + sample(c(-8:-1, 1:12), length(areas), TRUE)
dbl <- rbind(data.frame(area = db$area, period = "Period 1", value = db$before),
             data.frame(area = db$area, period = "Period 2", value = db$after))
p31 <- ggplot(db, aes(y = reorder(area, after))) +
  geom_segment(aes(x = before, xend = after, yend = reorder(area, after)), colour = phw_col("grey_mid"), linewidth = 1.2) +
  geom_point(data = dbl, aes(x = value, y = area, colour = period), size = 3.2) +
  scale_colour_phw_d() +
  labs(title = "Change between two periods", subtitle = "A dumbbell chart from geom_segment() and geom_point()",
       x = "Value", y = NULL, caption = src) +
  theme_phw(grid = "x")
save(p31, "31-dumbbell", h = 12)

if (requireNamespace("sf", quietly = TRUE)) {
  # 32. Small-multiple maps, one per year
  ms_trend <- smooth_values(msoa, 0, 4)
  ms4 <- do.call(rbind, lapply(2022:2025, function(y) {
    data.frame(code = msoa$code, year = y, value = round(ms_trend + (y - 2022) * 1.3 + runif(nrow(msoa), 0, 1.5), 1))
  }))
  p32 <- phw_map(ms4, by = code, fill = value, level = msoa, bins = c(2, 4, 6, 8), linewidth = 0.05) +
    facet_wrap(~year, nrow = 1) +
    labs(title = "One map per year", subtitle = "phw_map() with facet_wrap(), made-up values for every MSOA",
         fill = "Value", caption = map_src)
  save(p32, "32-map-facets", w = 24, h = 9)

  # 34. Values printed on each area with label =
  lad <- data.frame(code = la$code, rate = round(smooth_values(la, 12, 48, noise = 0.4)))
  p32b <- phw_map(lad, by = code, fill = rate, level = la, bins = c(20, 30, 40), label = rate) +
    labs(title = "Values printed on each area", subtitle = "phw_map(label = rate), local authorities",
         fill = "Rate per 1,000", caption = map_src)
  save(p32b, "34-map-labels", w = 14, h = 14)

  # 33. Health boards by name with sites as points and labels
  hbm <- phw_boundaries("health_board", quiet = TRUE)
  hbm$short <- sub(" (University )?(Teaching )?Health Board$", "", hbm$name)
  sites <- sf::st_sample(sf::st_union(hbm), 120)
  sites <- sf::st_sf(type = sample(c("Site type 1", "Site type 2", "Site type 3"), 120, TRUE, prob = c(.6, .3, .1)),
                     geometry = sites)
  p33 <- ggplot() +
    geom_sf(data = hbm, aes(fill = short), colour = "white", linewidth = 0.4, alpha = 0.85) +
    geom_sf(data = sites, colour = "white", size = 3.6) +            # white halo so points show on any fill
    geom_sf(data = sites, aes(shape = type), size = 2, colour = phw_col("text")) +
    scale_fill_phw_d(palette = "extended", name = NULL) +
    scale_shape_phw(name = NULL) +
    labs(title = "Areas by name with points on top", subtitle = "phw_boundaries(\"health_board\"), 120 made-up sites",
         caption = map_src) +
    theme_phw_map(legend = "right")
  save(p33, "33-map-points", w = 18, h = 13)
}

# gt, gtsummary, DT, leaflet, Excel and PowerPoint
grouped <- phw_group_table(dat, c(category, subgroup), year,
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
  htmltools::save_html(phw_datatable(rx[c("Area", "Count", "Rate")],
                                     caption = "Searchable table with DT", source = "Example data"),
                       file.path(out, "dt.html"))
}
if (requireNamespace("leaflet", quietly = TRUE) && requireNamespace("sf", quietly = TRUE)) {
  ml <- sf::st_transform(msoa, 4326)
  ml$rate <- round(smooth_values(msoa, 10, 50), 1)
  m <- phw_leaflet() |>
    phw_leaflet_polygons(ml, fill = rate, bins = c(10, 20, 30, 40, 50), label = name, legend_title = "Rate")
  htmlwidgets::saveWidget(m, normalizePath(file.path(out, "leaflet.html"), mustWork = FALSE), selfcontained = TRUE)
  ll_la <- sf::st_transform(la, 4326)
  ll_la$band <- cut(lad$rate, c(10, 25, 40, 50), labels = c("Low", "Middle", "High"), include.lowest = TRUE)
  m2 <- phw_leaflet() |>
    phw_leaflet_polygons(ll_la, fill = band, palette = "accessible", label = name, legend_title = "Band")
  htmlwidgets::saveWidget(m2, normalizePath(file.path(out, "leaflet-groups.html"), mustWork = FALSE), selfcontained = TRUE)
}
if (requireNamespace("openxlsx2", quietly = TRUE)) {
  phw_write_xlsx(list(Grouped = grouped, Areas = tbl[c("Area", "Count")]),
                 file.path(out, "tables.xlsx"), title = c("A grouped table", "Counts by area"), source = "Example data")
}
if (requireNamespace("officer", quietly = TRUE)) {
  deck <- phw_pptx() |>
    phw_add_slide("Key messages", text = c("First message", "Second message")) |>
    phw_add_slide("Cases by week", plot = phw_epicurve(cases, onset, group = group), source = "Example data") |>
    phw_add_slide("A grouped table", table = grouped, source = "Example data")
  print(deck, target = file.path(out, "slides.pptx"))
}
message("Gallery written to ", out)
