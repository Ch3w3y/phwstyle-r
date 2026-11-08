#' Arrange several plots in one PHW-styled figure
#'
#' Puts plots side by side or in a grid, with one PHW title, subtitle and
#' source line for the whole figure. Use it when facets can't do the job,
#' for example to combine a map, a bar chart and a table-like chart. It is a
#' thin wrapper around the patchwork package, so the result can be changed
#' further with patchwork operators (`+`, `|`, `/`, `&`).
#'
#' To keep the same colour for a group in every panel, give each plot the
#' same colour key, e.g. `scale_fill_phw_d(key = "area")`. With
#' `guides = "collect"`, matching legends are then merged into one.
#'
#' @param ... ggplots (or other patchwork-compatible objects).
#' @param plots A list of plots, instead of or as well as `...`.
#' @param ncol,nrow,widths,heights,design Layout, passed to
#'   [patchwork::plot_layout()].
#' @param title,subtitle Figure title and subtitle.
#' @param source,date,caption_args Passed to [phw_caption()] for the
#'   figure's source line.
#' @param guides `"collect"` merges identical legends from all panels into
#'   one, at `legend`; `"keep"` leaves each legend with its plot.
#' @param legend Position of collected legends.
#' @param tag_levels Panel tags, e.g. `"A"` for A, B, C or `"1"`. `NULL` for
#'   none.
#' @param theme The theme used for the figure title and source line.
#' @return A patchwork object. Add [phw_finalise()] for the logo footer, or
#'   save with [phw_save()].
#' @examples
#' if (requireNamespace("patchwork", quietly = TRUE)) {
#'   library(ggplot2)
#'   p1 <- ggplot(mpg, aes(displ, hwy, colour = drv)) + geom_point() + theme_phw()
#'   p2 <- ggplot(mpg, aes(drv, fill = drv)) + geom_bar() + theme_phw()
#'   phw_arrange(p1, p2, title = "Two charts", source = "ggplot2::mpg", tag_levels = "A")
#' }
#' @export
phw_arrange <- function(..., plots = NULL, ncol = NULL, nrow = NULL, widths = NULL,
                        heights = NULL, design = NULL, title = NULL, subtitle = NULL,
                        source = NULL, date = NULL, caption_args = list(),
                        guides = c("collect", "keep"), legend = "bottom",
                        tag_levels = NULL, theme = theme_phw()) {
  rlang::check_installed("patchwork", "to arrange plots")
  guides <- rlang::arg_match(guides)
  all <- c(list(...), plots)
  if (!length(all)) cli::cli_abort("Give at least one plot.")
  out <- patchwork::wrap_plots(all, ncol = ncol, nrow = nrow, widths = widths,
                               heights = heights, design = design, guides = guides)
  ann_theme <- theme + ggplot2::theme(
    plot.tag = ggplot2::element_text(face = "bold", colour = phw_colours[["navy"]]))
  out <- out + patchwork::plot_annotation(
    title = title, subtitle = subtitle,
    caption = caption_from(source, date, caption_args),
    tag_levels = tag_levels, theme = ann_theme)
  if (guides == "collect") out <- out & ggplot2::theme(legend.position = legend)
  if (!is.null(tag_levels)) {
    out <- out & ggplot2::theme(plot.tag = ggplot2::element_text(
      face = "bold", colour = phw_colours[["navy"]], size = ggplot2::rel(1.1)))
  }
  out
}

#' PHW title for gridExtra and cowplot layouts
#'
#' gridExtra and cowplot draw figure titles in the default font. This
#' builds a PHW-styled title (bold navy, left-aligned, with an optional
#' subtitle) to pass as `top =` in [gridExtra::grid.arrange()] or
#' [gridExtra::arrangeGrob()], or to stack above a cowplot figure.
#'
#' @param title Title text.
#' @param subtitle Optional subtitle.
#' @param size Title size in points. The subtitle is a little smaller.
#' @param margin Left margin in mm.
#' @return A grob.
#' @examples
#' if (requireNamespace("gridExtra", quietly = TRUE)) {
#'   library(ggplot2)
#'   p <- ggplot(mpg, aes(displ, hwy)) + geom_point() + theme_phw()
#'   gridExtra::grid.arrange(p, p, ncol = 2, top = phw_title_grob("Two charts", "Same data twice"))
#' }
#' @export
phw_title_grob <- function(title, subtitle = NULL, size = 14, margin = 3) {
  fam <- phw_font()
  x <- grid::unit(margin, "mm")
  t <- grid::textGrob(title, x = x, hjust = 0, vjust = 1, y = grid::unit(1, "npc") - grid::unit(1, "mm"),
                      gp = grid::gpar(fontfamily = fam, fontface = "bold", fontsize = size,
                                      col = phw_colours[["navy"]]))
  kids <- list(t)
  h <- size * 1.6
  if (!is.null(subtitle)) {
    s <- grid::textGrob(subtitle, x = x, hjust = 0, vjust = 1,
                        y = grid::unit(1, "npc") - grid::unit(1, "mm") - grid::unit(size * 1.4, "pt"),
                        gp = grid::gpar(fontfamily = fam, fontsize = size * 0.8,
                                        col = phw_colours[["text_secondary"]]))
    kids <- c(kids, list(s))
    h <- h + size * 1.2
  }
  wrap_title_height(grid::gTree(children = do.call(grid::gList, kids), name = "phw-title"), h)
}

wrap_title_height <- function(g, h) {
  gt <- gtable::gtable(widths = grid::unit(1, "null"), heights = grid::unit(h, "pt"))
  gtable::gtable_add_grob(gt, g, t = 1, l = 1, clip = "off", name = "phw-title")
}
