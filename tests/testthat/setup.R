# Measure text with ragg (which sees the registered Ubuntu font) rather than
# the default pdf() device, which only knows PostScript fonts.
if (requireNamespace("ragg", quietly = TRUE)) {
  ragg::agg_png(tempfile(fileext = ".png"))
  withr::defer(grDevices::dev.off(), teardown_env())
}

# Test the package defaults, whatever the palette settings of the person or
# machine running the tests.
withr::local_options(phwstyle.palette = NULL, .local_envir = teardown_env())
withr::local_envvar(PHWSTYLE_PALETTE = NA, .local_envir = teardown_env())

# A failed boundary download makes phw_boundaries() look for a newer list of
# layers on GitHub. Tests of failures must not go online; the tests of that
# step switch it back on with a made-up list.
withr::local_options(phwstyle.boundary_update = FALSE, .local_envir = teardown_env())
