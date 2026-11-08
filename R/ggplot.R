#' PHW theme for ggplot2
#'
#' A clean theme that follows how Public Health Wales and CDSC reports draw
#' charts:
#'
#' * a white background with light gridlines on the value axis only
#' * the legend at the bottom with no title
#' * a bold navy title on the left
#' * a bold, right-aligned source line in the caption
#' * facet strips with bold navy left-aligned labels on a light grey band
#'
#' With ggplot2 4.0 or later, the theme also sets the default colour and fill
#' palettes and the default geom colours. A plain `ggplot()` call then comes
#' out in PHW colours with no `scale_*()` needed.
#'
#' @param base_size Base font size in points. Reports use 11 for body text.
#' @param base_family Font family. Defaults to [phw_font()] (Ubuntu).
#' @param grid Which major gridlines to draw: `"y"` (default, horizontal
#'   lines for vertical bars and time series), `"x"` (for horizontal bars),
#'   `"xy"` or `"none"`.
#' @param legend Legend position: `"bottom"`, `"top"`, `"right"`, `"left"`,
#'   `"inside"` or `"none"`, or a numeric `c(x, y)` inside the panel.
#' @param legend_title Show the legend title? PHW reports usually don't.
#' @param strip Facet strip style: `"light"` (grey band, navy text),
#'   `"navy"` (navy band, white text) or `"plain"` (text only).
#' @param axis_line Draw a mid-grey line along the bottom axis?
#' @param axis_ticks Draw axis tick marks?
#' @param grid_minor Draw minor gridlines too (on the same axes as `grid`)?
#' @param title_colour,text_colour Colours for the title and other text.
#' @param background Plot background. Use `"transparent"` for slides or web
#'   pages with their own background.
#' @param base_line_size,base_rect_size Line and border widths, as in
#'   [ggplot2::theme_grey()].
#' @param accessible Larger text and thicker lines for public-facing or
#'   low-vision outputs. Raises `base_size` to at least 13 and makes lines
#'   and points bigger.
#' @param ... Any other theme settings, passed to [ggplot2::theme()]. They
#'   override the PHW defaults, so you don't need a separate `+ theme()`.
#' @return A ggplot2 theme.
#' @examples
#' library(ggplot2)
#' ggplot(mpg, aes(displ, hwy, colour = drv)) +
#'   geom_point() +
#'   labs(title = "Engine size and fuel economy",
#'        caption = phw_caption("ggplot2::mpg")) +
#'   theme_phw()
#' @export
theme_phw <- function(base_size = 11,
                      base_family = phw_font(),
                      ...,
                      grid = c("y", "x", "xy", "none"),
                      legend = "bottom",
                      legend_title = FALSE,
                      strip = c("light", "navy", "plain"),
                      axis_line = TRUE,
                      axis_ticks = FALSE,
                      grid_minor = FALSE,
                      title_colour = phw_colours[["navy"]],
                      text_colour = phw_colours[["text"]],
                      background = "#FFFFFF",
                      base_line_size = base_size / 22,
                      base_rect_size = base_size / 22,
                      accessible = FALSE) {
  grid <- rlang::arg_match(grid)
  strip <- rlang::arg_match(strip)
  inside <- is.numeric(legend)
  if (!inside) {
    legend <- rlang::arg_match(legend, c("bottom", "top", "right", "left", "inside", "none"))
  }
  if (accessible) {
    base_size <- max(base_size, 13)
    base_line_size <- base_line_size * 1.4
  }
  col <- phw_colours
  col[["text"]] <- text_colour
  el_grid <- ggplot2::element_line(colour = col[["grey_border"]], linewidth = 0.4)
  el_minor <- ggplot2::element_line(colour = col[["grey_bg"]], linewidth = 0.3)
  blank <- ggplot2::element_blank()
  half <- base_size / 2

  th <- ggplot2::theme_minimal(base_size = base_size, base_family = base_family,
                               base_line_size = base_line_size,
                               base_rect_size = base_rect_size) +
    ggplot2::theme(
      text = ggplot2::element_text(colour = col[["text"]]),
      plot.title = ggplot2::element_text(
        face = "bold", colour = title_colour, size = ggplot2::rel(1.25),
        hjust = 0, margin = ggplot2::margin(b = half * 0.6)),
      plot.subtitle = ggplot2::element_text(
        colour = col[["text_secondary"]], size = ggplot2::rel(1),
        hjust = 0, margin = ggplot2::margin(b = half)),
      plot.caption = ggplot2::element_text(
        face = "bold", colour = col[["text"]], size = ggplot2::rel(0.8),
        hjust = 1, lineheight = 1.1, margin = ggplot2::margin(t = half)),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.background = ggplot2::element_rect(fill = background, colour = NA),
      plot.margin = ggplot2::margin(half, half * 1.5, half, half),
      axis.title = ggplot2::element_text(colour = col[["text_secondary"]], size = ggplot2::rel(0.9)),
      axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = half * 0.8)),
      axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = half * 0.8)),
      axis.text = ggplot2::element_text(colour = col[["text_secondary"]], size = ggplot2::rel(0.85)),
      axis.ticks = if (axis_ticks) ggplot2::element_line(colour = col[["grey_mid"]]) else blank,
      axis.line = blank,
      panel.grid.major.x = if (grid %in% c("x", "xy")) el_grid else blank,
      panel.grid.major.y = if (grid %in% c("y", "xy")) el_grid else blank,
      panel.grid.minor = blank,
      panel.grid.minor.x = if (grid_minor && grid %in% c("x", "xy")) el_minor else blank,
      panel.grid.minor.y = if (grid_minor && grid %in% c("y", "xy")) el_minor else blank,
      panel.spacing = grid::unit(base_size, "pt"),
      legend.position = if (inside) "inside" else legend,
      legend.title = if (legend_title) ggplot2::element_text(size = ggplot2::rel(0.9), face = "bold") else blank,
      legend.text = ggplot2::element_text(size = ggplot2::rel(0.85), colour = col[["text"]]),
      legend.key.size = grid::unit(base_size * 1.1, "pt"),
      legend.margin = ggplot2::margin(0, 0, 0, 0),
      legend.box.spacing = grid::unit(half, "pt"),
      strip.text = ggplot2::element_text(
        face = "bold", hjust = 0, size = ggplot2::rel(0.9),
        colour = if (strip == "navy") "#FFFFFF" else col[["navy"]],
        margin = ggplot2::margin(4, 6, 4, 6)),
      strip.background = switch(strip,
        light = ggplot2::element_rect(fill = col[["grey_bg"]], colour = NA),
        navy = ggplot2::element_rect(fill = col[["navy"]], colour = NA),
        plain = blank)
    )

  if (axis_line && grid != "none") {
    line <- ggplot2::element_line(colour = col[["grey_mid"]], linewidth = 0.5)
    th <- th + if (grid == "x") ggplot2::theme(axis.line.y = line) else ggplot2::theme(axis.line.x = line)
  }
  if (inside) {
    th <- th + ggplot2::theme(legend.position.inside = legend,
                              legend.background = ggplot2::element_rect(fill = background, colour = NA))
  } else if (legend %in% c("bottom", "top")) {
    th <- th + ggplot2::theme(legend.justification = "left",
                              legend.location = "plot")
  }
  if (ggplot2_v4()) th <- th + phw_theme_v4_defaults(base_family, base_size, accessible)
  extra <- list(...)
  if (length(extra)) th <- th + do.call(ggplot2::theme, extra)
  th
}

ggplot2_v4 <- function() utils::packageVersion("ggplot2") >= "4.0.0"

phw_theme_v4_defaults <- function(base_family, base_size, accessible = FALSE) {
  col <- phw_colours
  args <- list(
    geom = ggplot2::element_geom(
      ink = col[["text"]], paper = "#FFFFFF", accent = col[["navy"]],
      family = base_family, fontsize = base_size * 0.8,
      linewidth = if (accessible) 1.1 else 0.7, pointsize = if (accessible) 2.6 else 1.8),
    palette.colour.discrete = phw_discrete_auto,
    palette.fill.discrete = phw_discrete_auto,
    palette.colour.continuous = phw_palettes$blues[2:6],
    palette.fill.continuous = phw_palettes$blues[2:6]
  )
  do.call(ggplot2::theme, args)
}

phw_discrete_auto <- function(n) {
  pal <- phw_default_palette()
  if (identical(pal, "main") && n > 4) pal <- "accessible"
  cols <- if (is.function(pal)) pal(n) else palette_colours(pal)
  if (n <= length(cols)) return(cols[seq_len(n)])
  cli::cli_warn(c("{n} groups is too many to tell apart by colour.",
                  i = "Consider facets, direct labels, or highlighting one group with {.code palette = \"highlight\"}."))
  grDevices::colorRampPalette(cols, space = "Lab")(n)
}

#' PHW map theme
#'
#' [theme_phw()] without axes or gridlines, with the legend on the right.
#' Use it for choropleth maps of health boards or local authorities, with
#' [scale_fill_phw_c()] or [scale_fill_phw_b()].
#'
#' @inheritParams theme_phw
#' @param ... Passed to [theme_phw()].
#' @return A ggplot2 theme.
#' @export
theme_phw_map <- function(base_size = 11, base_family = phw_font(), legend = "right", ...) {
  theme_phw(base_size = base_size, base_family = base_family, grid = "none",
            legend = legend, legend_title = TRUE, ...) +
    ggplot2::theme(axis.text = ggplot2::element_blank(),
                   axis.title = ggplot2::element_blank(),
                   panel.grid = ggplot2::element_blank())
}

#' PHW colour and fill scales
#'
#' * `_d` scales are discrete and use the qualitative palettes (`main`,
#'   `extended`, `accessible`, `highlight`, `rag`).
#' * `_c` scales are continuous, `_b` scales are binned. Both use sequential
#'   or diverging palettes (`blues`, `teals`, `gradient`, `orange_navy`).
#' * `scale_*_phw_div()` centres the diverging palette on `midpoint`.
#'
#' Every scale takes a palette name, your own vector of colours, or (for
#' `_d` scales) a function of `n`. Everything else goes to the ggplot2 scale,
#' so `name`, `labels`, `breaks`, `limits`, `guide`, `na.value` and so on work
#' as usual.
#'
#' **Colours that stick to groups.** By default a `_d` scale colours groups
#' in the order they appear. To keep the same colour for a group in every
#' chart and every report, give a `key`, e.g. `key = "age_group"`. New groups
#' get the next free colour and old ones never move (see
#' [phw_colour_key()]). You can also pin colours with `values`, a named
#' vector such as `c(Wales = "#285087")`. Groups named "Other" or "Unknown"
#' are drawn in grey.
#'
#' **Colour-blind readers.** Use `palette = "accessible"`, or set
#' `options(phwstyle.palette = "accessible")` for every chart. Add
#' [scale_shape_phw()] or [scale_linetype_phw()] so groups differ by more
#' than colour.
#'
#' @param palette Palette name (see [phw_palettes]), a vector of colours, or
#'   a function of `n`.
#' @param reverse Reverse the palette?
#' @param key Name of a colour key, so each group keeps its colour across
#'   charts and reports.
#' @param values Named vector of colours to pin to particular groups.
#' @param neutral Group names to draw in grey, see [phw_colour_key()].
#' @param aesthetics Aesthetics this scale works with, e.g.
#'   `c("colour", "fill")` to colour both with one scale.
#' @param na.value Colour for missing values.
#' @param ... Passed to the underlying ggplot2 scale constructor.
#' @return A ggplot2 scale.
#' @name phw_scales
#' @examples
#' library(ggplot2)
#' ggplot(mpg, aes(class, fill = drv)) + geom_bar() + scale_fill_phw_d() + theme_phw()
#'
#' # The same colour for each group in every chart:
#' ggplot(mpg, aes(displ, hwy, colour = drv)) +
#'   geom_point() +
#'   scale_colour_phw_d(key = "drive_example") +
#'   theme_phw()
#' phw_key_reset("drive_example")
NULL

phw_discrete_scale <- function(aesthetics, palette, reverse, key, values, neutral, na.value, ...) {
  if (reverse && !is.function(palette)) palette <- rev(palette_colours(palette))
  sc <- ggplot2::discrete_scale(aesthetics, palette = phw_discrete_auto, na.value = na.value, ...)
  ggplot2::ggproto(NULL, sc,
    phw_args = list(palette = palette, key = key, values = values, neutral = neutral),
    map = function(self, x, limits = self$get_limits()) {
      a <- self$phw_args
      lv <- as.character(limits)
      lv <- lv[!is.na(lv)]
      cols <- phw_colour_key(lv, name = a$key, palette = a$palette, fixed = a$values,
                             neutral = a$neutral)
      out <- unname(cols[as.character(x)])
      out[is.na(out)] <- self$na.value
      out
    })
}

#' @rdname phw_scales
#' @export
scale_colour_phw_d <- function(palette = phw_default_palette(), reverse = FALSE, key = NULL,
                               values = NULL, neutral = default_neutral,
                               aesthetics = "colour",
                               na.value = phw_colours[["grey_light"]], ...) {
  phw_discrete_scale(aesthetics, palette, reverse, key, values, neutral, na.value, ...)
}

#' @rdname phw_scales
#' @export
scale_fill_phw_d <- function(palette = phw_default_palette(), reverse = FALSE, key = NULL,
                             values = NULL, neutral = default_neutral,
                             aesthetics = "fill",
                             na.value = phw_colours[["grey_light"]], ...) {
  phw_discrete_scale(aesthetics, palette, reverse, key, values, neutral, na.value, ...)
}

#' @rdname phw_scales
#' @export
scale_color_phw_d <- scale_colour_phw_d

seq_cols <- function(palette, reverse) {
  if (is.character(palette) && length(palette) == 1 && palette %in% names(phw_palettes) &&
      palette_type(palette) == "qualitative") {
    cli::cli_abort("{.val {palette}} is a qualitative palette. Use a {.code _d} scale.")
  }
  cols <- palette_colours(palette)
  if (reverse) cols <- rev(cols)
  cols
}

#' @rdname phw_scales
#' @export
scale_colour_phw_c <- function(palette = "blues", reverse = FALSE, aesthetics = "colour",
                               na.value = phw_colours[["grey_light"]], ...) {
  ggplot2::scale_colour_gradientn(colours = seq_cols(palette, reverse), aesthetics = aesthetics,
                                  na.value = na.value, ...)
}

#' @rdname phw_scales
#' @export
scale_fill_phw_c <- function(palette = "blues", reverse = FALSE, aesthetics = "fill",
                             na.value = phw_colours[["grey_light"]], ...) {
  ggplot2::scale_fill_gradientn(colours = seq_cols(palette, reverse), aesthetics = aesthetics,
                                na.value = na.value, ...)
}

#' @rdname phw_scales
#' @export
scale_color_phw_c <- scale_colour_phw_c

#' @rdname phw_scales
#' @export
scale_colour_phw_b <- function(palette = "blues", reverse = FALSE, aesthetics = "colour",
                               na.value = phw_colours[["grey_light"]], ...) {
  ggplot2::scale_colour_stepsn(colours = seq_cols(palette, reverse), aesthetics = aesthetics,
                               na.value = na.value, ...)
}

#' @rdname phw_scales
#' @export
scale_fill_phw_b <- function(palette = "blues", reverse = FALSE, aesthetics = "fill",
                             na.value = phw_colours[["grey_light"]], ...) {
  ggplot2::scale_fill_stepsn(colours = seq_cols(palette, reverse), aesthetics = aesthetics,
                             na.value = na.value, ...)
}

#' @rdname phw_scales
#' @export
scale_color_phw_b <- scale_colour_phw_b

mid_rescaler <- function(midpoint) {
  force(midpoint)
  function(x, to = c(0, 1), from = range(x, na.rm = TRUE)) {
    scales::rescale_mid(x, to = to, from = from, mid = midpoint)
  }
}

#' @rdname phw_scales
#' @param midpoint Value at the centre of a diverging scale.
#' @export
scale_fill_phw_div <- function(midpoint = 0, palette = "orange_navy", reverse = FALSE,
                               aesthetics = "fill", na.value = phw_colours[["grey_light"]], ...) {
  ggplot2::scale_fill_gradientn(colours = seq_cols(palette, reverse), rescaler = mid_rescaler(midpoint),
                                aesthetics = aesthetics, na.value = na.value, ...)
}

#' @rdname phw_scales
#' @export
scale_colour_phw_div <- function(midpoint = 0, palette = "orange_navy", reverse = FALSE,
                                 aesthetics = "colour", na.value = phw_colours[["grey_light"]], ...) {
  ggplot2::scale_colour_gradientn(colours = seq_cols(palette, reverse), rescaler = mid_rescaler(midpoint),
                                  aesthetics = aesthetics, na.value = na.value, ...)
}

#' @rdname phw_scales
#' @export
scale_color_phw_div <- scale_colour_phw_div

#' Use PHW styling for every ggplot in the session
#'
#' Sets [theme_phw()] as the default theme and makes PHW palettes the default
#' discrete and continuous scales. Text geoms use Ubuntu too. Put it at the
#' top of a script or in an R Markdown/Quarto setup chunk.
#'
#' This is like calling `theme_set()` in base ggplot2. The difference is
#' that it also sets colours, which `theme_set()` can't do before ggplot2 4.0.
#' It also restyles geoms from extension packages that are already loaded
#' (see [phw_style_extensions()]), so load ggrepel, ggridges and the like
#' first.
#'
#' @param ... Passed to [theme_phw()], e.g. `base_size = 14` or
#'   `accessible = TRUE`.
#' @param palette Default qualitative palette for every chart, table and
#'   widget, e.g. `"accessible"`. Sets `options(phwstyle.palette)`.
#' @return The previous theme, invisibly.
#' @export
use_phw_ggplot <- function(..., palette = NULL) {
  if (!is.null(palette)) options(phwstyle.palette = palette)
  old <- ggplot2::theme_set(theme_phw(...))
  phw_style_extensions()
  if (!ggplot2_v4()) {
    # Before ggplot2 4.0 themes can't carry palettes, so use global options.
    options(
      ggplot2.discrete.colour = phw_discrete_auto,
      ggplot2.discrete.fill = phw_discrete_auto,
      ggplot2.continuous.colour = function(...) scale_colour_phw_c(...),
      ggplot2.continuous.fill = function(...) scale_fill_phw_c(...)
    )
    fam <- phw_font()
    ggplot2::update_geom_defaults("text", list(family = fam, colour = phw_colours[["text"]]))
    ggplot2::update_geom_defaults("label", list(family = fam, colour = phw_colours[["text"]]))
    for (g in c("point", "line", "path", "step", "smooth", "segment", "errorbar",
                "pointrange", "linerange", "crossbar", "hline", "vline", "abline")) {
      ggplot2::update_geom_defaults(g, list(colour = phw_colours[["navy"]]))
    }
    for (g in c("bar", "col", "area", "histogram", "boxplot", "violin", "density",
                "ribbon", "tile", "rect", "polygon", "dotplot")) {
      ggplot2::update_geom_defaults(g, list(fill = phw_colours[["navy"]]))
    }
  }
  invisible(old)
}

#' Add the PHW footer (logo and source) to a ggplot
#'
#' Adds a branded footer under a chart: a thin navy rule, the PHW logo on
#' one side and the source text on the other. Use it for charts that stand
#' alone, such as slides, social media, briefings or images sent by email.
#' Charts inside a branded report don't need it, because the report already
#' carries the logo.
#'
#' @param plot A ggplot, a patchwork (e.g. from [phw_arrange()]), a cowplot
#'   figure, or any grob or gtable (e.g. from [gridExtra::arrangeGrob()]).
#' @param source,date Passed to [phw_caption()]. Leave both `NULL` to keep
#'   any caption already on the plot.
#' @param logo Logo variant (see [phw_logo()]), a path to your own PNG, or
#'   `FALSE` for none.
#' @param team Optional line under the source, e.g.
#'   `"Communicable Disease Surveillance Centre"`.
#' @param logo_height Logo height in cm.
#' @param logo_position `"left"` or `"right"`. The text goes on the other
#'   side.
#' @param text_size Footer text size in points.
#' @param text_colour,rule_colour Colours of the footer text and rule.
#' @param rule Draw the rule above the footer?
#' @param margin Space at each side, in mm.
#' @param ... Passed to [phw_caption()], e.g. `source_prefix = "Data: "` or
#'   `note = "Provisional"`.
#' @return A gtable that prints like a plot. Save it with [phw_save()].
#' @export
phw_finalise <- function(plot, source = NULL, date = NULL, logo = "blue",
                         team = NULL, logo_height = 1.1,
                         logo_position = c("left", "right"), text_size = 8.5,
                         text_colour = phw_colours[["text"]],
                         rule_colour = phw_colours[["navy"]], rule = TRUE,
                         margin = 4, ...) {
  logo_position <- rlang::arg_match(logo_position)
  caption <- phw_caption(source, date, ...)
  if (inherits(plot, "patchwork")) {
    if (is.null(caption)) caption <- plot$patches$annotation$caption
    plot <- plot + patchwork::plot_annotation(caption = NULL)
  } else if (inherits(plot, "ggplot")) {
    if (is.null(caption)) caption <- plot$labels$caption
    plot <- plot + ggplot2::labs(caption = NULL)
  } else if (!inherits(plot, "grob")) {
    cli::cli_abort("{.arg plot} must be a ggplot, a patchwork or a grob, not {.cls {class(plot)}}.")
  }
  txt <- paste(c(caption, team), collapse = "\n")
  fam <- phw_font()
  g <- if (inherits(plot, "gtable")) {
    plot
  } else if (inherits(plot, "grob")) {
    gtable::gtable_add_grob(gtable::gtable(widths = grid::unit(1, "null"), heights = grid::unit(1, "null")),
                            plot, t = 1, l = 1, name = "phw-content")
  } else {
    withCallingHandlers(ggplot2::ggplotGrob(plot), warning = function(w) {
      if (grepl("font (family|database)", conditionMessage(w))) invokeRestart("muffleWarning")
    })
  }

  m <- grid::unit(margin, "mm")
  left <- logo_position == "left"
  text <- grid::textGrob(txt, x = if (left) grid::unit(1, "npc") - m else m,
                         hjust = if (left) 1 else 0,
                         gp = grid::gpar(fontfamily = fam, fontface = "bold",
                                         fontsize = text_size, col = text_colour,
                                         lineheight = 1.1))
  kids <- list(text)
  if (rule) {
    kids <- c(kids, list(grid::segmentsGrob(
      x0 = m, x1 = grid::unit(1, "npc") - m, y0 = grid::unit(1, "npc"), y1 = grid::unit(1, "npc"),
      gp = grid::gpar(col = rule_colour, lwd = 1.5))))
  }
  if (!isFALSE(logo)) {
    lg <- if (is.character(logo) && file.exists(logo)) {
      rlang::check_installed("png", "to draw a logo")
      grid::rasterGrob(png::readPNG(logo), height = grid::unit(logo_height, "cm"),
                       x = if (left) m else grid::unit(1, "npc") - m,
                       hjust = if (left) 0 else 1, interpolate = TRUE)
    } else {
      logo_grob(logo, height = grid::unit(logo_height, "cm"),
                x = if (left) m else grid::unit(1, "npc") - m, hjust = if (left) 0 else 1)
    }
    kids <- c(kids, list(lg))
  }
  footer <- grid::gTree(children = do.call(grid::gList, kids))
  g <- gtable::gtable_add_rows(g, grid::unit(logo_height + 0.5, "cm"))
  g <- gtable::gtable_add_grob(g, footer, t = nrow(g), l = 1, r = ncol(g),
                               clip = "off", name = "phw-footer")
  class(g) <- c("phw_finalised", class(g))
  g
}

#' @export
print.phw_finalised <- function(x, ...) {
  grid::grid.newpage()
  grid::grid.draw(x)
  invisible(x)
}

#' Save a PHW chart
#'
#' A wrapper around [ggplot2::ggsave()] with sensible defaults for PHW
#' outputs. It saves at 16 x 10 cm and 300 dpi, uses 'ragg' for PNG so the
#' bundled Ubuntu font works, and accepts plots made with [phw_finalise()].
#'
#' @param plot A ggplot or the result of [phw_finalise()].
#' @param filename File name. The extension (`.png`, `.svg`, `.pdf`,
#'   `.jpeg`) picks the format.
#' @param width,height,units Size. Defaults to 16 x 10 cm, which fits an A4
#'   Word page with standard margins.
#' @param dpi Resolution for raster formats.
#' @param bg Background colour. Use `"transparent"` for overlays.
#' @param device Override the graphics device that the extension picks.
#' @param ... Passed to [ggplot2::ggsave()].
#' @return The file name, invisibly.
#' @export
phw_save <- function(plot = ggplot2::last_plot(), filename, width = 16, height = 10,
                     units = "cm", dpi = 300, bg = "white", device = NULL, ...) {
  ext <- tolower(tools::file_ext(filename))
  device <- device %||% switch(ext,
    png = if (requireNamespace("ragg", quietly = TRUE)) ragg::agg_png else "png",
    jpg = , jpeg = if (requireNamespace("ragg", quietly = TRUE)) ragg::agg_jpeg else "jpeg",
    tif = , tiff = if (requireNamespace("ragg", quietly = TRUE)) ragg::agg_tiff else "tiff",
    pdf = grDevices::cairo_pdf,
    NULL)
  ggplot2::ggsave(filename, plot = plot, width = width, height = height,
                  units = units, dpi = dpi, device = device, bg = bg, ...)
  invisible(filename)
}
