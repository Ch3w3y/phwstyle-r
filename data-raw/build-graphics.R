# Build the brand graphics that ship with phwstyle. Run from the package root:
#   Rscript data-raw/build-graphics.R
#
# Everything here is drawn from scratch with grid, so the package owns these
# images outright. Nothing is cropped from PHW publications. The logo is
# never baked in: it is added at run time (see R/assets.R), so the package
# works with or without bundled logos.

library(grid)

stops <- c("#325082", "#326791", "#2A8DAC", "#2BADC5", "#27B8CD")

# Horizontal gradient band (headers): 2480 x 260 px = 21 cm x 2.2 cm at 300 dpi
band <- grDevices::colorRampPalette(stops, space = "Lab")(2480)
ragg::agg_png("inst/graphics/band.png", width = 2480, height = 260)
grid.raster(matrix(band, nrow = 1), width = unit(1, "npc"), height = unit(1, "npc"), interpolate = TRUE)
dev.off()

# Diagonal gradient with soft wave lines, for covers
diag_gradient <- function(w, h) {
  pal <- grDevices::colorRampPalette(stops, space = "Lab")(256)
  x <- matrix(rep(seq(0, 1, length.out = w), each = h), nrow = h)
  y <- matrix(rep(seq(0, 1, length.out = h), times = w), nrow = h)
  t <- (0.75 * x + 0.45 * y) / 1.2
  matrix(pal[pmax(1, pmin(256, round(t * 255) + 1))], nrow = h)
}

waves <- function(n = 5, base = 0.12, amp = 0.035) {
  cols <- c("#FFFFFF", "#7CC7D3", "#FFFFFF", "#F43882", "#FF5D0C")
  for (i in seq_len(n)) {
    x <- seq(0, 1, length.out = 400)
    y <- base + amp * sin(2 * pi * (x * (1.1 + i * 0.15) + i / 3)) + i * 0.012
    grid.lines(x, y, gp = gpar(col = grDevices::adjustcolor(cols[i], alpha.f = 0.45), lwd = 6))
  }
}

ragg::agg_jpeg("inst/graphics/cover-a4.jpg", width = 1240, height = 1754, quality = 88)
grid.raster(diag_gradient(310, 438), width = unit(1, "npc"), height = unit(1, "npc"), interpolate = TRUE)
waves(base = 0.1)
dev.off()

ragg::agg_jpeg("inst/graphics/cover-wide.jpg", width = 1920, height = 1080, quality = 88)
grid.raster(diag_gradient(480, 270), width = unit(1, "npc"), height = unit(1, "npc"), interpolate = TRUE)
waves(base = 0.08, amp = 0.03)
dev.off()

message("Graphics written to inst/graphics/")
