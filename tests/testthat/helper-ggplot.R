# ggplot2::get_labs() arrived after 3.5.1. Before it, the labels sit on the plot.
plot_labs <- function(p) {
  if (exists("get_labs", envir = asNamespace("ggplot2"), inherits = FALSE)) ggplot2::get_labs(p) else p$labels
}

# The lines of `caption` as phw_save() draws them, with their edges in inches
# from the left and top of the image. Other text, such as legend labels, is
# left out.
saved_caption_lines <- function(plot, caption, width = 16, height = 10) {
  testthat::skip_if_not_installed("rvg")
  testthat::skip_if_not_installed("xml2")
  file <- tempfile(fileext = ".xml")
  phw_save(plot, file, width = width, height = height, units = "cm",
           device = function(filename, width, height, ...) {
             rvg::dml_pptx(file = filename, width = width, height = height, offx = 0, offy = 0,
                           raster_prefix = file.path(tempdir(), "raster_"))
           })
  shapes <- xml2::xml_find_all(xml2::read_xml(file), "//p:sp[.//a:t]")
  inches <- function(path, attr) as.numeric(xml2::xml_attr(xml2::xml_find_first(shapes, path), attr)) / 914400
  out <- data.frame(text = xml2::xml_text(shapes), left = inches(".//a:off", "x"), top = inches(".//a:off", "y"))
  out$right <- out$left + inches(".//a:ext", "cx")
  part <- vapply(out$text, function(t) grepl("[A-Za-z]", t) && grepl(t, caption, fixed = TRUE), logical(1))
  out[part, ]
}

# Every line is inside `from` to `to` inches, and read top to bottom they give
# the whole caption.
expect_caption_within <- function(lines, caption, from, to) {
  expect_gte(min(lines$left), from)
  expect_lte(max(lines$right), to)
  expect_equal(paste(lines$text[order(lines$top)], collapse = " "), gsub("\n", " ", caption, fixed = TRUE))
}

# Two captions side by side: each whole, on the image and clear of the other.
expect_captions_side_by_side <- function(lines, caption, width) {
  left <- lines$right < mean(range(lines$right))
  expect_caption_within(lines[left, ], caption, 0, min(lines$left[!left]))
  expect_caption_within(lines[!left, ], caption, max(lines$right[left]), width)
}

# The width in inches of each panel of `plot` laid out as phw_save() draws it.
drawn_panel_widths <- function(plot, width = 16, height = 10) {
  width <- width / 2.54
  height <- height / 2.54
  if (!inherits(plot, "phw_finalised")) plot <- fit_captions(plot, width, height)
  grDevices::pdf(NULL, width = width, height = height)
  on.exit(grDevices::dev.off())
  g <- if (inherits(plot, "phw_finalised")) grid::makeContext(plot) else plot_gtable(plot)
  grid::pushViewport(grid::viewport(layout = grid::grid.layout(
    nrow(g), ncol(g), widths = g$widths, heights = g$heights, respect = g$respect)))
  panels <- g$layout[grepl("^panel", g$layout$name) & g$layout$name != "panel-area", ]
  vapply(seq_len(nrow(panels)), function(i) {
    grid::pushViewport(grid::viewport(layout.pos.row = panels$t[i]:panels$b[i], layout.pos.col = panels$l[i]:panels$r[i]))
    on.exit(grid::popViewport())
    grid::convertWidth(grid::unit(1, "npc"), "in", valueOnly = TRUE)
  }, numeric(1))
}
