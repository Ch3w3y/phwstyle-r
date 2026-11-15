# How the "main" and "extended" palettes are put together, and how to try
# other colours in them.
#
# Run from the package root with the package loaded:
#   pkgload::load_all(); source("data-raw/palette-search.R")
#
# "main" is the first six colours of "extended", so every chart starts the
# same way. The order follows these rules:
#   * Colours with a PHW source come first.
#   * The two oranges are far apart, because they look alike side by side.
#   * Black comes last. Early on, a black series reads like a total or a
#     reference line.
#   * No lighter or darker shades of a colour already in the palette: they
#     are close to it for colour-blind readers. Ordered groups use the
#     sequential palettes instead.
#
# A set of colours is judged by its closest pair (CIELAB distance, delta E)
# for normal vision, deuteranopia and protanopia. About 10 or more is easy to
# tell apart.

main <- c(
  navy         = "#285087",  # chart colours PHW reports use
  teal         = "#24A2B5",
  orange       = "#FF5D0C",
  pink         = "#F43882",
  green        = "#338276",  # phw.nhs.wales stylesheet (action colour)
  gold_465     = "#CFAB7A"   # NHS Wales Logo Guidelines, July 2022 (Pantone 465)
)
rest <- c(
  wine         = "#A3245A",  # not a PHW colour: chosen to stay distinct
  mint         = "#5FBDAF",  # Long-Term Strategy 2023 to 2035, priority 4
  green_bright = "#50AF31",  # Long-Term Strategy 2023 to 2035, priority 6
  blue         = "#2D78A0",  # phw.nhs.wales stylesheet (primary)
  orange_dark  = "#C94100",  # dark end of the "orange_navy" palette
  black        = "#231F20"   # NHS Wales Logo Guidelines, July 2022
)
twelve <- c(main, rest)

lab <- function(x) grDevices::convertColor(t(grDevices::col2rgb(x)) / 255, "sRGB", "Lab")
views <- function(x) list(normal = lab(x), deutan = lab(phw_cvd(x, "deutan")), protan = lab(phw_cvd(x, "protan")))
closest_pair <- function(cols) {
  vapply(views(cols), function(m) min(stats::dist(m)), numeric(1))
}
# How far a candidate is from every colour in `chosen`, worst view first.
score <- function(candidate, chosen) {
  a <- views(candidate)
  b <- views(chosen)
  min(vapply(names(a), function(v) min(sqrt(rowSums(sweep(b[[v]], 2, a[[v]])^2))), numeric(1)))
}

print(data.frame(slot = seq_along(twelve), name = names(twelve), hex = unname(twelve),
                 contrast_on_white = round(phw_contrast(twelve, "#FFFFFF"), 2)), row.names = FALSE)
cat("\nClosest pair (CIELAB distance):\n")
print(round(rbind(main = closest_pair(main), twelve = closest_pair(twelve)), 1))
cat("\nPlaces from the orange to the dark orange:", diff(match(c("orange", "orange_dark"), names(twelve))), "\n")

# To try another colour in a slot, score it against the colours before it,
# e.g. score("#5A82E6", twelve[1:9]). Swap it in if it scores at least as
# well as the colour it replaces and the closest pair above stays over 10.

cat("\nSame as the palettes in the package:",
    identical(toupper(unname(main)), toupper(phw_palettes$main)) &&
      identical(toupper(unname(twelve)), toupper(phw_palettes$extended)), "\n")
