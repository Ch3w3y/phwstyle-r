# How the "extended" palette was put together, and how to redo it with
# other colours.
#
# Run from the package root with the package loaded:
#   devtools::load_all(); source("data-raw/palette-search.R")
#
# The palette has three parts:
#   1-4   "main": the chart colours PHW reports use. Fixed.
#   5-7   colours with a published source. Chosen below from `sourced`.
#   8-12  other colours found in PHW documents, then colours generated in
#         the same hues.
#
# A colour is scored by how far it is (CIELAB distance) from the colours
# already chosen, for normal vision, deuteranopia and protanopia, taking the
# worst of the three. Each step adds the colour with the best score.

main <- unname(phw_colours[c("navy", "teal", "orange", "pink")])

# Where each candidate comes from. To use colours from another source, add
# them here (or to `found` below) and re-run.
sourced <- c(
  black       = "#231F20",  # NHS Wales Logo Guidelines, July 2022
  gold_465    = "#CFAB7A",  # NHS Wales Logo Guidelines, July 2022 (Pantone 465)
  green       = "#338276",  # phw.nhs.wales stylesheet (action colour)
  green_dark  = "#173934",  # phw.nhs.wales stylesheet (button hover)
  magenta     = "#D50B5C",  # phw.nhs.wales stylesheet (link hover)
  blue        = "#2D78A0"   # phw.nhs.wales stylesheet (primary)
)
found <- c(
  mint         = "#5FBDAF",  # Long-Term Strategy 2023 to 2035, priority 4
  green_bright = "#50AF31",  # Long-Term Strategy 2023 to 2035, priority 6
  purple_dark  = "#5A356B",  # Long-Term Strategy 2023 to 2035, priority 1
  jade         = "#40A294",  # website icons, Bowel Screening report
  cyan         = "#27B8CD",  # end of the header gradient band
  light_teal   = "#7CC7D3"   # table shading in surveillance reports
)

lab <- function(x) grDevices::convertColor(t(grDevices::col2rgb(x)) / 255, "sRGB", "Lab")
views <- function(x) list(normal = lab(x), deutan = lab(phw_cvd(x, "deutan")), protan = lab(phw_cvd(x, "protan")))
score <- function(candidate, chosen) {
  a <- views(candidate)
  b <- views(chosen)
  min(vapply(names(a), function(v) min(sqrt(rowSums(sweep(b[[v]], 2, a[[v]])^2))), numeric(1)))
}
closest_pair <- function(cols) {
  vapply(views(cols), function(m) min(stats::dist(m)), numeric(1))
}
add_best <- function(chosen, candidates, prefer = character(), within = 0.7) {
  candidates <- candidates[!toupper(candidates) %in% toupper(chosen)]
  sc <- vapply(candidates, score, numeric(1), chosen = chosen)
  best <- which.max(sc)
  # A sourced or found colour wins if it is nearly as good as the best one.
  p <- which(names(candidates) %in% prefer)
  if (length(p) && max(sc[p]) >= within * max(sc)) best <- p[which.max(sc[p])]
  c(chosen, candidates[best])
}

# 5-7: the three sourced colours that keep the seven furthest apart.
sets <- utils::combn(names(sourced), 3, simplify = FALSE)
worst <- vapply(sets, function(s) min(closest_pair(c(main, sourced[s]))), numeric(1))
tier1 <- sourced[sets[[which.max(worst)]]]
# Colours with 3:1 contrast on white go first, so the low-contrast one is
# the last of the seven to be used.
strong <- phw_contrast(tier1, "#FFFFFF") >= 3
seven <- main
for (i in seq_len(sum(strong))) seven <- add_best(seven, tier1[strong])
for (i in seq_len(sum(!strong))) seven <- add_best(seven, tier1[!strong])

# Generated candidates: colours in the hues the theme already uses, with at
# least 3:1 contrast on white, and no dark warm colours (they read as brown).
luv_hue <- function(x) {
  luv <- grDevices::convertColor(t(grDevices::col2rgb(x)) / 255, "sRGB", "Luv")
  (atan2(luv[, 3], luv[, 2]) * 180 / pi) %% 360
}
theme_hues <- luv_hue(c(main, sourced[c("green", "gold_465", "magenta")], found[c("mint", "green_bright", "purple_dark")]))
grid <- expand.grid(h = seq(0, 357.5, 2.5), c = c(30, 45, 60, 75, 90), l = c(25, 32, 40, 48, 56, 64, 72))
gen <- grDevices::hcl(grid$h, grid$c, grid$l, fixup = FALSE)
ok <- !is.na(gen)
gen <- gen[ok]
gh <- luv_hue(gen)
near <- vapply(gh, function(h) min(abs(((h - theme_hues + 180) %% 360) - 180)), numeric(1)) <= 10
warm <- gh < 85 | gh > 345
gen <- gen[near & !(warm & grid$l[ok] < 50) & phw_contrast(gen, "#FFFFFF") >= 3]
names(gen) <- sprintf("generated_%03d", seq_along(gen))

# 8-12: gap-fill from found and generated colours, found ones preferred.
twelve <- seven
pool <- c(sourced, found, gen)
for (i in 1:5) twelve <- add_best(twelve, pool, prefer = c(names(sourced), names(found)))

# In the package the found colours come before the generated ones.
is_gen <- grepl("^generated", names(twelve))
twelve <- c(twelve[!is_gen], twelve[is_gen])

print(data.frame(slot = seq_along(twelve), name = names(twelve), hex = unname(twelve),
                 contrast_on_white = round(phw_contrast(twelve, "#FFFFFF"), 2)), row.names = FALSE)
cat("\nClosest pair (CIELAB distance):\n")
print(round(rbind(seven = closest_pair(seven), twelve = closest_pair(twelve)), 1))
cat("\nSame as the palette in the package:", identical(toupper(unname(twelve)), toupper(phw_palettes$extended)), "\n")
