# Measure text with ragg (which sees the registered Ubuntu font) rather than
# the default pdf() device, which only knows PostScript fonts.
if (requireNamespace("ragg", quietly = TRUE)) {
  ragg::agg_png(tempfile(fileext = ".png"))
  withr::defer(grDevices::dev.off(), teardown_env())
}
