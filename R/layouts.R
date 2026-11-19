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
#' @param legend Position of collected legends: `"bottom"`, `"top"`,
#'   `"right"`, `"left"` or `"none"`.
#' @param tag_levels Panel tags, e.g. `"A"` for A, B, C or `"1"`. `NULL` for
#'   none.
#' @param theme The theme used for the figure title and source line. The
#'   default, `NULL`, is [theme_phw()] with the settings given to
#'   [use_phw_ggplot()], so the figure text matches the charts.
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
                        tag_levels = NULL, theme = NULL) {
  rlang::check_installed("patchwork", "to arrange plots")
  guides <- rlang::arg_match(guides)
  legend <- rlang::arg_match(legend, c("bottom", "top", "right", "left", "none"))
  all <- c(list(...), plots)
  if (!length(all)) cli::cli_abort("Give at least one plot.")
  bad <- which(!vapply(all, inherits, logical(1), what = c("ggplot", "grob")))
  if (length(bad)) {
    cli::cli_abort(c("Each plot must be a ggplot or a grob.",
                     x = "Plot {bad[1]} is {.cls {class(all[[bad[1]]])[1]}}."))
  }
  ann_theme <- (theme %||% chart_theme()) + ggplot2::theme(
    plot.tag = ggplot2::element_text(face = "bold", colour = phw_colours[["navy"]]))
  if (guides == "collect") ann_theme <- ann_theme + ggplot2::theme(legend.position = legend)
  arrange <- function(plots) {
    out <- patchwork::wrap_plots(plots, ncol = ncol, nrow = nrow, widths = widths,
                                 heights = heights, design = design, guides = guides)
    out <- out + patchwork::plot_annotation(
      title = title, subtitle = subtitle,
      caption = caption_from(source, date, caption_args),
      tag_levels = tag_levels, theme = ann_theme)
    if (is.null(tag_levels)) return(out)
    out & ggplot2::theme(plot.tag = ggplot2::element_text(
      face = "bold", colour = phw_colours[["navy"]], size = ggplot2::rel(1.1)))
  }
  if (guides == "keep") {
    share <- if (is.null(design)) column_shares(length(all), nrow, ncol, widths) else 1
    return(arrange(Map(wrap_legends, all, share = share)))
  }
  all <- lapply(all, place_legend, legend)
  room <- collected_room(arrange(all))
  arrange(lapply(all, wrap_legends, position = legend, room = room))
}

# The width, in cm, that patchwork gives a legend collected from `figure`
# when drawn on the open device: from the left of the first panel to the
# right of the last, less the y axes and the figure margins. As a function,
# because the width is known only when the figure is drawn. NULL when the
# figure has no collected legend across it. Each legend in the figure asks,
# so the width is kept for each kind and size of device.
collected_room <- function(figure) {
  known <- list()
  function() {
    key <- paste(names(grDevices::dev.cur()), paste(grDevices::dev.size("cm"), collapse = "x"))
    if (key %in% names(known)) return(known[[key]])
    g <- suppressMessages(suppressWarnings(patchwork::patchworkGrob(figure)))
    i <- which(g$layout$name == "guide-box")
    cm <- function(u) grid::convertWidth(u, "cm", valueOnly = TRUE)
    room <- if (length(i) == 1) {
      outside <- setdiff(seq_along(g$widths), g$layout$l[i]:g$layout$r[i])
      cm(grid::unit(1, "npc")) - sum(vapply(outside, function(j) cm(g$widths[j]), numeric(1)))
    }
    known[key] <<- list(room)
    room
  }
}

# Each plot's share of the figure width, in a grid filled row by row as
# patchwork fills it. Widths given as units count as equal.
column_shares <- function(n, nrow, ncol, widths) {
  ncol <- ggplot2::wrap_dims(n, nrow, ncol)[2]
  w <- if (is.numeric(widths) && !grid::is.unit(widths)) rep_len(widths, ncol) else rep(1, ncol)
  (w / sum(w))[(seq_len(n) - 1) %% ncol + 1]
}

# Moves the legend of a plot that shows one to `legend`, where the figure
# collects it. A plot that turned its own legend off keeps it off.
place_legend <- function(plot, legend) {
  moved <- ggplot2::theme(legend.position = legend)
  if (inherits(plot, "patchwork")) return(plot & moved)
  if (!inherits(plot, "ggplot")) return(plot)
  own <- ggplot2::calc_element("legend.position", ggplot2::theme_get() + plot$theme)
  if (identical(own, "none")) plot else plot + moved
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
#' @param size Title size in points. The subtitle is a little smaller. The
#'   default, `NULL`, is 14 pt, scaled up with the `base_size` or
#'   `accessible` setting given to [use_phw_ggplot()] so the figure title is
#'   no smaller than the chart titles under it.
#' @param margin Left margin in mm.
#' @return A grob.
#' @examples
#' if (requireNamespace("gridExtra", quietly = TRUE)) {
#'   library(ggplot2)
#'   p <- ggplot(mpg, aes(displ, hwy)) + geom_point() + theme_phw()
#'   gridExtra::grid.arrange(p, p, ncol = 2, top = phw_title_grob("Two charts", "Same data twice"))
#' }
#' @export
phw_title_grob <- function(title, subtitle = NULL, size = NULL, margin = 3) {
  size <- size %||% (14 * session_text_scale())
  fam <- phw_font()
  x <- grid::unit(margin, "mm")
  gap <- grid::unit(size * 0.7, "pt")
  top <- grid::unit(1, "mm")
  t <- grid::textGrob(title, x = x, hjust = 0, vjust = 1, y = grid::unit(1, "npc") - top,
                      gp = grid::gpar(fontfamily = fam, fontface = "bold", fontsize = size,
                                      col = phw_colours[["navy"]]))
  kids <- list(t)
  h <- top + grid::grobHeight(t) + gap
  if (!is.null(subtitle)) {
    s <- grid::textGrob(subtitle, x = x, hjust = 0, vjust = 1, y = grid::unit(1, "npc") - h,
                        gp = grid::gpar(fontfamily = fam, fontsize = size * 0.8,
                                        col = phw_colours[["text_secondary"]]))
    kids <- c(kids, list(s))
    h <- h + grid::grobHeight(s) + gap
  }
  wrap_title_height(grid::gTree(children = do.call(grid::gList, kids), name = "phw-title"), h)
}

wrap_title_height <- function(g, h) {
  gt <- gtable::gtable(widths = grid::unit(1, "null"), heights = h)
  gt <- gtable::gtable_add_grob(gt, g, t = 1, l = 1, clip = "off", name = "phw-title")
  class(gt) <- c("phw_title", class(gt))
  gt
}

# gtable's own method passes the heights through absolute.size(), which turns
# the measured text heights into null units, so gridExtra's `top =` row would
# lose them.
#' @exportS3Method grid::heightDetails
heightDetails.phw_title <- function(x) sum(x$heights)
