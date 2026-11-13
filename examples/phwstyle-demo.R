# =============================================================================
# phwstyle demo: every output type, from a raw data frame to a styled result
# =============================================================================
#
# This script is a worked tour of phwstyle, for copying into your own
# reports. It is not part of the installed package. Run it top to bottom:
# later sections reuse charts and tables made in earlier ones.
#
# Everything uses made-up data. Outputs (images, HTML, Word, Excel and
# PowerPoint files) go to `out_dir`, which is printed at the end.
#
# A note on approach: phwstyle is built so you can go from a raw line list
# straight to a formatted table or chart, with the output functions doing
# the grouping and totals. You rarely need to reshape data first. Where a
# little preparation helps, it is written with dplyr and tidyr.
#
# Packages: phwstyle needs only ggplot2. This script also uses dplyr, tidyr
# and lubridate to prepare the example data. The other packages used here
# are optional. Run phwstyle::phw_setup_check() to see which are missing.

# -----------------------------------------------------------------------------
# 0. Setup
# -----------------------------------------------------------------------------

library(phwstyle)
library(ggplot2)
library(dplyr)

out_dir <- file.path(tempdir(), "phwstyle-demo")
dir.create(out_dir, showWarnings = FALSE)
out <- function(name) file.path(out_dir, name)

# Style every ggplot in this session: theme, colour scales, fonts and the
# defaults of extension geoms (ggalluvial, ggridges, ggrepel...).
# Load extension packages BEFORE this call so their geoms get styled too.
if (requireNamespace("ggalluvial", quietly = TRUE)) loadNamespace("ggalluvial")
use_phw_ggplot()

# Optional: colour-blind safe colours everywhere, and bigger text.
# use_phw_ggplot(palette = "accessible", accessible = TRUE)

set.seed(2026)

# -----------------------------------------------------------------------------
# 1. Example data: a raw line list (one row per case) and a list of grouped records
# -----------------------------------------------------------------------------

n <- 600
cases <- tibble(
  id        = seq_len(n),
  onset     = as.Date("2025-01-06") + round(rgamma(n, 5, 0.12)),
  age       = round(pmin(95, rgamma(n, 3, 0.07))),
  sex       = sample(c("Female", "Male", NA), n, replace = TRUE, prob = c(0.49, 0.49, 0.02)),
  area      = sample(paste("Area", LETTERS[1:6]), n, replace = TRUE),
  setting   = sample(c("Setting 1", "Setting 2", "Setting 3"), n, replace = TRUE, prob = c(0.6, 0.15, 0.25)),
  organism  = sample(c("Type 1", "Type 2", "Type 3"), n, replace = TRUE, prob = c(0.5, 0.35, 0.15)),
  outcome   = sample(c("Outcome X", "Outcome Y"), n, replace = TRUE, prob = c(0.8, 0.2)),
  days      = rpois(n, 4)
) |>
  # Age groups: cut() bands a number.
  mutate(age_group = cut(age, c(-Inf, 14, 44, 64, Inf),
                         labels = c("0-14", "15-44", "45-64", "65+")))

# Grouped records for nested tables: group, then type, by year and quarter.
dat <- tibble(
  group = sample(c("Group A", "Group B", "Group C"), 800, replace = TRUE, prob = c(0.45, 0.4, 0.15)),
  type  = sample(c("Type 1", "Type 2", "Type 3"), 800, replace = TRUE, prob = c(0.45, 0.45, 0.1)),
  year  = sample(2024:2025, 800, replace = TRUE),
  quarter = sample(paste0("Q", 1:4), 800, replace = TRUE),
  days   = rpois(800, 3)
) |>
  # Factor levels control the order of rows and columns everywhere.
  mutate(type = factor(type, levels = c("Type 1", "Type 2", "Type 3")))

# -----------------------------------------------------------------------------
# 2. Colours that stay with their groups
# -----------------------------------------------------------------------------

# A colour key fixes the colour of each level, so "Setting 2" is the same
# colour in every chart and table, and adding a level never reshuffles the
# others. Keys last for the session; phw_key_file() saves them to a CSV so
# they carry across reports and years.
phw_colour_key(c("Setting 1", "Setting 2", "Setting 3"), name = "setting")
# phw_key_file("phw-colours.csv")   # keep keys between reports

# Check any colours for contrast and colour-blind distinguishability:
phw_check_colours(phw_pal(4))
# How a palette looks with deuteranopia (red-green colour blindness):
# show_phw_palettes(cvd = "deutan")

# -----------------------------------------------------------------------------
# 3. ggplot2 charts
# -----------------------------------------------------------------------------

# Bars. The data are aggregated by ggplot (geom_bar counts rows), so no
# summarising is needed first.
p_bar <- ggplot(cases, aes(area, fill = setting)) +
  geom_bar() +
  scale_fill_phw_d(key = "setting") +       # colours from the key above
  labs(title = "Cases by area and setting",
       subtitle = "Stacked bars",
       x = NULL, y = "Cases",
       caption = phw_caption("Example data"))
p_bar

# Horizontal bars sorted by size: reorder() inside aes(), no data prep.
p_hbar <- ggplot(cases, aes(y = reorder(area, area, length))) +
  geom_bar() +                               # navy, the default after use_phw_ggplot()
  labs(title = "Cases by area", x = "Cases", y = NULL) +
  theme_phw(grid = "x")                      # gridlines only where useful

# Lines by group, with shapes as a second cue for colour-blind readers.
weekly <- cases |>
  count(week = lubridate::floor_date(onset, "week", week_start = 1), organism)
p_line <- ggplot(weekly, aes(week, n, colour = organism, shape = organism)) +
  geom_line() + geom_point() +
  scale_colour_phw_d() + scale_shape_phw() +
  labs(title = "Weekly cases by type", x = NULL, y = "Cases")

# Small multiples: facet_wrap works as normal and strips are styled.
p_facet <- ggplot(cases, aes(age_group, fill = sex)) +
  geom_bar(position = "dodge") +
  facet_wrap(~setting) +
  scale_fill_phw_d() +                       # NA (missing sex) shows in grey
  labs(title = "Cases by age group, sex and setting", x = NULL, y = "Cases")

# Continuous and diverging colour scales.
p_heat <- cases |>
  count(area, age_group) |>
  tidyr::complete(area, age_group, fill = list(n = 0)) |>
  ggplot(aes(age_group, area, fill = n)) +
  geom_tile(colour = "white") +
  scale_fill_phw_c(name = "Cases") +
  labs(title = "Heat map", x = "Age group", y = NULL) +
  theme_phw(grid = "none", legend = "right")

# Add the logo, source and date bar under a chart, then save at the right
# size. phw_save() uses the ragg device so the bundled font always works.
fin <- phw_finalise(p_bar, source = "Example data", date = Sys.Date())
phw_save(fin, out("bar-finalised.png"), width = 16, height = 10)
if (requireNamespace("svglite", quietly = TRUE)) {
  phw_save(p_line, out("line.svg"), width = 16, height = 10)   # SVG for web
}

# -----------------------------------------------------------------------------
# 4. Extension packages (ggalluvial, ggridges, treemapify, ggrepel...)
# -----------------------------------------------------------------------------

if (requireNamespace("ggalluvial", quietly = TRUE)) {
  # Any number of stages: add axis4, axis5... Each row is a flow, and y is
  # its size. Count first so each combination is one row.
  flows <- count(cases, setting, organism, outcome)
  p_flow <- ggplot(flows, aes(axis1 = setting, axis2 = organism, axis3 = outcome, y = n)) +
    ggalluvial::geom_alluvium(aes(fill = setting), width = 0.25) +   # coloured by the key
    ggalluvial::geom_stratum(width = 0.25) +                         # styled by use_phw_ggplot()
    geom_text(stat = ggalluvial::StatStratum, aes(label = after_stat(stratum)), size = 3) +
    scale_x_discrete(limits = c("Setting", "Type", "Outcome"), expand = c(0.08, 0.08)) +
    scale_fill_phw_d(key = "setting") +
    labs(title = "Flow from setting to outcome", x = NULL, y = "Cases") +
    theme_phw(legend = "none")
  phw_save(p_flow, out("alluvial.png"))
}
# If you style plots one at a time with theme_phw() instead of
# use_phw_ggplot(), call phw_style_extensions() once to style extension geoms.

# -----------------------------------------------------------------------------
# 5. Several charts in one figure
# -----------------------------------------------------------------------------

if (requireNamespace("patchwork", quietly = TRUE)) {
  fig <- phw_arrange(p_hbar, p_line, ncol = 2, widths = c(1, 2),
                     title = "Two charts, one title",
                     subtitle = "phw_arrange() collects legends and adds the source",
                     source = "Example data", tag_levels = "A")
  phw_save(fig, out("arranged.png"), width = 24, height = 10)
}
# For gridExtra or cowplot layouts, phw_title_grob() gives a styled title
# grob, and phw_finalise() accepts any grob.

# -----------------------------------------------------------------------------
# 6. Public health charts
# -----------------------------------------------------------------------------

# Epidemic curve straight from the line list: dates are binned by week
# (Monday start), empty weeks are filled with zero, groups are stacked.
p_epi <- phw_epicurve(cases, onset, group = organism, interval = "week") +
  labs(title = "Cases by week of onset", x = "Week beginning", y = "Cases")
phw_save(p_epi, out("epicurve.png"))

# Population pyramid, as percentages.
p_pyr <- phw_pyramid(filter(cases, !is.na(sex)), age = age_group, sex = sex, percent = TRUE) +
  labs(title = "Cases by age and sex")

# Funnel plot: one row per unit with a numerator and denominator.
units <- tibble(area = paste("Area", 1:30), eligible = round(runif(30, 300, 6000))) |>
  mutate(events = rbinom(n(), eligible, 0.72))
p_funnel <- phw_funnel(units, events, eligible, label = area) +
  labs(title = "Proportion by area", x = "Population", y = "Proportion (%)")

# SPC chart (XmR), with limits from a baseline period and the direction
# that counts as improvement.
monthly <- tibble(month = seq(as.Date("2023-01-01"), by = "month", length.out = 30),
                  value = c(rnorm(20, 50, 4), rnorm(10, 57, 4)))
p_spc <- phw_spc(monthly, month, value, improvement = "increase", baseline = 20) +
  labs(title = "Monthly measure", y = "Value")

# -----------------------------------------------------------------------------
# 7. Maps
# -----------------------------------------------------------------------------

if (requireNamespace("sf", quietly = TRUE) && requireNamespace("jsonlite", quietly = TRUE)) {
  # See every available level: health boards, GP clusters, local
  # authorities, Senedd constituencies, wards, MSOAs, LSOAs...
  print(phw_boundary_levels())

  # Downloads once, then reads from your cache. Columns: code, name,
  # name_cy (Welsh) and geometry.
  hb <- phw_boundaries("health_board")

  # Join your data on the ONS code (or the name). Put the boundaries first
  # so the result keeps its map geometry.
  rates <- tibble(code = hb$code, rate = round(runif(nrow(hb), 20, 80), 1))
  hb <- left_join(hb, rates, by = "code")

  p_map <- ggplot(hb) +
    geom_sf(aes(fill = rate), colour = "white", linewidth = 0.3) +
    scale_fill_phw_b(name = "Rate per\n100,000") +    # binned scale reads well on maps
    theme_phw_map() +
    labs(title = "Rate by health board", caption = attr(hb, "attribution"))
  phw_save(p_map, out("map.png"), width = 14, height = 14)

  # Interactive map with leaflet (needs longitude/latitude: crs = 4326).
  if (requireNamespace("leaflet", quietly = TRUE)) {
    m <- phw_leaflet() |>
      phw_leaflet_polygons(sf::st_transform(hb, 4326), fill = rate, bins = 4,
                           label = name, legend_title = "Rate")
    htmlwidgets::saveWidget(m, out("map.html"))
  }
}

# -----------------------------------------------------------------------------
# 8. Tables: build once, render anywhere
# -----------------------------------------------------------------------------
# Each builder returns a data frame that knows its layout (group rows,
# indents, header spanners). Render it with phw_flextable() for Word/PDF,
# phw_gt() for HTML/Quarto, phw_reactable() for interactive HTML, or
# phw_write_xlsx() for Excel. Print it to see the plain data.

# "Table 1": characteristics by group, n (%) and median (IQR).
tab1 <- phw_summary_table(cases, vars = c(age_group, sex, setting, days), by = outcome,
                          labels = list(age_group = "Age group", sex = "Sex", setting = "Setting",
                                        days = "Days to recovery", outcome = "Outcome"))

# Cross-tab with totals and row percentages.
xt <- phw_crosstab(cases, area, age_group, percent = "row",
                   labels = list(area = "Area", age_group = "Age group"))

# Rates with exact confidence intervals for several breakdowns at once.
# Needs aggregated data: cases and population per group.
agg <- cases |>
  filter(!is.na(sex)) |>
  count(age_group, sex, name = "cases") |>
  mutate(population = round(runif(n(), 50, 150)) * 1000)
rates_tab <- phw_rate_table(agg, c(age_group, sex), cases, population,
                            labels = list(age_group = "Age group", sex = "Sex"))

# Attack rates and relative risks by exposure (outbreak style).
outbreak <- tibble(exposure_a = sample(c("Yes", "No"), 120, replace = TRUE),
                   exposure_b = sample(c("Yes", "No"), 120, replace = TRUE)) |>
  mutate(ill = rbinom(n(), 1, if_else(exposure_a == "Yes", 0.6, 0.15)))
risk_tab <- phw_risk_table(outbreak, c(exposure_a, exposure_b), ill,
                           labels = list(exposure_a = "Exposure A", exposure_b = "Exposure B"))

# Nested groups from a raw data frame: group, then type, split by year and
# quarter. Group rows carry their totals; there is a table total and a
# total by type across all groups.
nested <- phw_group_table(
  dat,
  rows = c(group, type),            # outermost first
  cols = c(year, quarter),          # spanning headers
  totals = c("group", "subgroup", "table"),
  col_totals = c("group", "table"),     # a total per year and overall
  labels = list(group = "Group", type = "Type", year = "Year", quarter = "Quarter")
)
nested

# Other layouts of the same data:
# - type in its own column, totals after each group, % of the group above
phw_group_table(dat, c(group, type), layout = "columns", subtotal_position = "below",
                percent = "parent", separate = "both")
# - any statistic instead of counts (computed from the records, not added up)
phw_group_table(dat, c(group, type), year, value = days,
                fun = function(x) round(mean(x), 1), totals = c("group", "table"))

if (requireNamespace("flextable", quietly = TRUE)) {
  ft1 <- phw_flextable(tab1, caption = "Characteristics by outcome", number = 1, source = "Example data")
  ft2 <- phw_flextable(nested, caption = "Counts by group and type", number = 2, source = "Example data")
  # Extra formats: heat colours and in-cell bars.
  ft3 <- phw_flextable_heat(phw_flextable(phw_crosstab(cases, area, age_group)), j = 2:5)
  ft4 <- phw_flextable_bars(phw_flextable(count(cases, Area = area, name = "Cases")), Cases)
  # Several tables in one Word file:
  flextable::save_as_docx(`Table 1` = ft1, `Table 2` = ft2, `Heat` = ft3, `Bars` = ft4, path = out("tables.docx"))
  # Set PHW defaults for every flextable you make yourself:
  # use_phw_flextable()
}

if (requireNamespace("gt", quietly = TRUE)) {
  g <- phw_gt(nested, caption = "Counts by group and type", source = "Example data")
  gt::gtsave(g, out("nested-gt.html"))
  # Style any gt table you already have:
  # phw_gt_theme(gt::gt(my_data))
}

# -----------------------------------------------------------------------------
# 9. gtsummary
# -----------------------------------------------------------------------------

if (requireNamespace("gtsummary", quietly = TRUE)) {
  use_phw_gtsummary()                    # once per session
  tb <- cases |>
    select(age_group, sex, setting, days, outcome) |>
    gtsummary::tbl_summary(by = outcome)
  gt::gtsave(gtsummary::as_gt(tb), out("gtsummary.html"))
  if (requireNamespace("flextable", quietly = TRUE)) {
    flextable::save_as_docx(gtsummary::as_flex_table(tb), path = out("gtsummary.docx"))
  }
  gtsummary::reset_gtsummary_theme()
}

# -----------------------------------------------------------------------------
# 10. Interactive HTML: plotly, reactable and DT
# -----------------------------------------------------------------------------

if (requireNamespace("plotly", quietly = TRUE)) {
  # Any ggplot becomes interactive, keeping the PHW style.
  htmlwidgets::saveWidget(phw_plotly(p_line, source = "Example data"), out("plotly-ggplot.html"))
  # Or build with plot_ly; colours can come from a key.
  pl <- plotly::plot_ly(count(cases, setting), x = ~setting, y = ~n,
                        color = ~setting, colors = phw_key("setting"), type = "bar")
  htmlwidgets::saveWidget(phw_plotly(pl, source = "Example data", title = list(text = "Cases by setting")),
                          out("plotly-bar.html"))
}

if (requireNamespace("reactable", quietly = TRUE)) {
  # Summary tables keep their layout:
  htmltools::save_html(phw_reactable(nested, caption = "Grouped table"), out("reactable-nested.html"))
  # Column formats on an ordinary data frame:
  by_area <- cases |>
    count(Area = area, name = "Cases") |>
    mutate(Rate = round(Cases / runif(n(), 0.8, 1.2), 1))
  htmltools::save_html(
    phw_reactable(by_area, caption = "Cases by area", source = "Example data",
                  columns = list(Cases = phw_col_bar(by_area, Cases),
                                 Rate = phw_col_heat(by_area, Rate))),
    out("reactable-columns.html"))
}

if (requireNamespace("DT", quietly = TRUE)) {
  # Searchable, sortable, paged: good for long lists in Shiny.
  htmltools::save_html(phw_datatable(select(cases, id, onset, area, setting, organism),
                                     caption = "Line list", source = "Example data", filter = "top"),
                       out("datatable.html"))
}

# -----------------------------------------------------------------------------
# 11. Excel and PowerPoint
# -----------------------------------------------------------------------------

if (requireNamespace("openxlsx2", quietly = TRUE)) {
  # One sheet per table; summary tables keep their bold group rows.
  phw_write_xlsx(list(`Table 1` = tab1, Grouped = nested, Rates = rates_tab),
                 out("tables.xlsx"), title = c("Characteristics", "Grouped table", "Rates"),
                 source = "Example data")
}

if (requireNamespace("officer", quietly = TRUE)) {
  # Pass your organisation's template with phw_pptx("template.pptx").
  deck <- phw_pptx() |>
    phw_add_slide("Key messages", text = c("Cases peaked in early February", "Most cases were in the community")) |>
    phw_add_slide("Cases by week", plot = p_epi, source = "Example data") |>   # editable with rvg
    phw_add_slide("Grouped table", table = phw_group_table(dat, c(group, type), year), source = "Example data")
  print(deck, target = out("slides.pptx"))
}

# -----------------------------------------------------------------------------
# 12. Documents, dashboards and Shiny
# -----------------------------------------------------------------------------
# R Markdown:   output: phwstyle::phw_word_document   (or phw_html_document,
#               phw_pdf_document). Start from File > New File > R Markdown >
#               From Template > PHW report.
# Quarto:       run phwstyle::use_phw_quarto() once in the project, then
#               format: phw-typst (PDF), phw-docx, phw-html, phw-revealjs
#               (slides) or phw-dashboard.
# Shiny:        see system.file("examples", "shiny", "app.R", package = "phwstyle")
#               for phw_page_navbar(), phw_bs_theme() and phw_header().

message("Demo outputs written to ", out_dir)
