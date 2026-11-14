#' Choropleth maps for reports
#'
#' `phw_map()` joins your data to Welsh boundaries and draws a styled
#' choropleth, a ggplot for Word and PDF. It is the static counterpart of
#' [phw_leaflet_polygons()]. Areas with no data are drawn in the scale's
#' missing-value colour, and the boundary source becomes the caption.
#'
#' @param data A data frame with one row per area (or per area and period,
#'   for use with [ggplot2::facet_wrap()]).
#' @param by Column of `data` holding the area codes, unquoted as in dplyr
#'   (a string works too). Codes are matched to the boundary `code`. Rows
#'   whose code is missing or matches no boundary are left out, and a
#'   message lists those codes. A code that appears twice in one panel gives
#'   a message when the map is drawn, since its area is drawn twice.
#' @param fill Column of `data` to colour by. Numbers get a continuous or
#'   binned scale; text and factors get distinct colours.
#' @param level A boundary level for [phw_boundaries()] such as
#'   `"local_authority"`, or an sf data frame with `code` and `name` columns
#'   that you have already loaded.
#' @param bins Breaks for numeric `fill`, or a single number of bins. Not
#'   used for text or factor `fill`.
#'   `NULL` gives a continuous scale. The legend also shows the lowest and
#'   highest values, rounded out to tidy numbers.
#' @param palette Palette name or colours, as in [phw_pal()]. Defaults to
#'   `"blues"` for numbers and the default palette for groups.
#' @param key Name of a colour key, so groups keep their colours (see
#'   [phw_colour_key()]). Not used for numeric `fill`.
#' @param label Text to print on each area: a column of `data`, unquoted, or
#'   an expression built from its columns such as `paste(name, rate)`. The
#'   columns of `data` and the boundary `name` are available. With ggrepel
#'   installed, labels that would overlap on small areas are moved apart.
#' @param detail Level of detail for [phw_boundaries()].
#' @param ... Passed to [ggplot2::geom_sf()], for example `colour` or
#'   `linewidth` for the outlines.
#' @return A ggplot, styled with [theme_phw_map()]. `$data` is the joined sf
#'   data frame, with the boundary `name` added when `data` has no `name`
#'   column. The caption is the boundary attribution, which [ggplot2::labs()]
#'   replaces.
#' @seealso [phw_boundaries()], [phw_leaflet_polygons()]
#' @examples
#' if (requireNamespace("sf", quietly = TRUE)) {
#'   square <- function(x, y) sf::st_polygon(list(rbind(c(x, y), c(x + 1, y), c(x + 1, y + 1),
#'                                                      c(x, y + 1), c(x, y))))
#'   areas <- sf::st_sf(code = paste0("A", 1:4), name = paste("Area", 1:4),
#'                      geometry = sf::st_sfc(square(0, 0), square(1, 0), square(0, 1), square(1, 1)))
#'   rates <- data.frame(area = paste0("A", 1:3), rate = c(12, 25, 40))
#'   phw_map(rates, by = area, fill = rate, level = areas, label = rate)
#' }
#' \donttest{
#' if (requireNamespace("sf", quietly = TRUE) && interactive()) {
#'   la <- phw_boundaries("local_authority")
#'   d <- data.frame(code = la$code, rate = runif(nrow(la), 10, 50))
#'   phw_map(d, by = code, fill = rate, level = la, bins = c(20, 30, 40)) +
#'     ggplot2::labs(fill = "Rate per 1,000")
#' }
#' }
#' @export
phw_map <- function(data, by, fill, level, bins = NULL, palette = NULL, key = NULL, label = NULL,
                    detail = "generalised", ...) {
  rlang::check_installed("sf")
  by <- pick_col(rlang::enquo(by), data, "by")
  fill <- pick_col(rlang::enquo(fill), data, "fill")
  quo_label <- rlang::enquo(label)
  check_has_rows(data)
  bounds <- map_boundaries(level, detail)
  if (all(is.na(data[[fill]]))) cli::cli_abort("Every value in {.field {fill}} is missing, so there is nothing to map.")

  codes <- as.character(data[[by]])
  hit <- match(codes, bounds$code)
  if (all(is.na(hit))) {
    cli::cli_abort(c("No codes in {.field {by}} match the boundary codes.",
                     "i" = "Expected codes such as {.val {utils::head(bounds$code, 3)}}.",
                     "i" = "Found {.val {utils::head(unique(codes), 3)}}."))
  }
  keep <- !is.na(hit)
  if (!all(keep)) {
    cli::cli_inform("phw_map(): Left out {sum(!keep)} row{?s} whose {.field {by}} is missing or not a boundary code: {.val {unique(codes[!keep])}}.")
  }
  joined <- data[keep, , drop = FALSE]
  if (!"name" %in% names(joined)) joined$name <- bounds$name[hit[keep]]
  joined <- sf::st_sf(joined, geometry = sf::st_geometry(bounds)[hit[keep]])
  n_inf <- sum(is.infinite(joined[[fill]]))
  if (n_inf) cli::cli_inform("phw_map(): {n_inf} area{?s} with an infinite {.field {fill}} {?is/are} drawn as missing.")

  scale <- map_fill_scale(joined[[fill]], bins, palette, key)
  geom_args <- utils::modifyList(list(colour = "#FFFFFF", linewidth = 0.3), list(...))

  p <- ggplot2::ggplot(joined)
  if (!all(bounds$code %in% data[[by]])) {
    p <- p + do.call(ggplot2::geom_sf, c(list(data = bounds[!bounds$code %in% data[[by]], ],
                                              fill = scale$na.value), geom_args))
  }
  areas <- ggplot2::aes(fill = .data[[fill]], phw_code = .data[[by]])
  p <- p + do.call(ggplot2::geom_sf, c(list(mapping = areas, stat = StatPhwMapAreas), geom_args)) +
    scale +
    ggplot2::labs(x = NULL, y = NULL, caption = wrap_caption(attr(bounds, "attribution"))) +
    theme_phw_map()

  text <- pick_text(quo_label, joined)
  if (!is.null(text)) {
    pts <- sf::st_point_on_surface(sf::st_geometry(joined))
    pts <- sf::st_sf(joined[setdiff(names(joined), attr(joined, "sf_column"))], geometry = pts)
    pts$.label <- text
    if (requireNamespace("ggrepel", quietly = TRUE)) {
      # Boxes in the area's own fill keep a label readable after ggrepel moves it off a small area.
      p <- p + ggrepel::geom_label_repel(
        ggplot2::aes(geometry = .data$geometry, label = .data$.label, fill = .data[[fill]],
                     colour = ggplot2::after_scale(phw_text_on(.data$fill))),
        data = pts, stat = "sf_coordinates", size = 2.8, family = phw_font(),
        label.padding = grid::unit(0.12, "lines"), label.r = grid::unit(0.08, "lines"), box.padding = 0.1,
        point.size = NA, min.segment.length = 0, segment.colour = phw_colours[["text_secondary"]],
        seed = 1, inherit.aes = FALSE, show.legend = FALSE, na.rm = TRUE)
    } else {
      # The text layer maps fill only so after_scale() can read it; ggplot2 warns that it is unknown.
      p <- p + withCallingHandlers(ggplot2::geom_sf_text(
        ggplot2::aes(label = .data$.label, fill = .data[[fill]],
                     colour = ggplot2::after_scale(phw_text_on(.data$fill))),
        data = pts, size = 2.8, family = phw_font(), inherit.aes = FALSE, show.legend = FALSE, na.rm = TRUE),
        warning = function(w) if (grepl("unknown aesthetic", conditionMessage(w), ignore.case = TRUE)) invokeRestart("muffleWarning"))
    }
  }
  p
}

# Checks for a code drawn twice in one panel at build time, once the facets
# are known: rows per area and period are fine when faceted by period.
StatPhwMapAreas <- ggplot2::ggproto("StatPhwMapAreas", ggplot2::StatSf,
  default_aes = ggplot2::aes(phw_code = NA),
  compute_layer = function(self, data, params, layout) {
    twice <- unique(unlist(lapply(split(data$phw_code, data$PANEL), function(x) x[duplicated(x)])))
    if (length(twice)) {
      cli::cli_inform(c("phw_map(): {.val {as.character(twice)}} {?has/have} more than one row, so {?its area is/their areas are} drawn twice.",
                        i = "Give one row per area, or facet by period with {.fn ggplot2::facet_wrap}."))
    }
    data$phw_code <- NULL
    ggplot2::ggproto_parent(ggplot2::StatSf, self)$compute_layer(data, params, layout)
  })

wrap_caption <- function(x) {
  if (is.null(x)) NULL else paste(strwrap(x, 70), collapse = "\n")
}

map_boundaries <- function(level, detail, call = rlang::caller_env()) {
  if (is.data.frame(level) && !inherits(level, "sf")) {
    cli::cli_abort(c("{.arg level} must be a level name, such as {.val local_authority}, or an sf data frame.",
                     i = "Make an sf data frame with {.fn sf::st_as_sf}."), call = call)
  }
  if (inherits(level, "sf")) {
    if (!all(c("code", "name") %in% names(level))) {
      cli::cli_abort("{.arg level} must have {.field code} and {.field name} columns.", call = call)
    }
    return(level)
  }
  phw_boundaries(level, detail = detail, quiet = TRUE)
}

map_fill_scale <- function(v, bins, palette, key) {
  if (is.numeric(v)) {
    if (!is.null(key)) cli::cli_inform("phw_map(): {.arg key} is for groups, so it is not used for a numeric {.arg fill}.")
    palette <- palette %||% "blues"
    if (is.null(bins)) return(scale_fill_phw_c(palette))
    lims <- range(pretty(range(v[is.finite(v)])))
    if (length(bins) > 1 && !any(bins > lims[1] & bins < lims[2])) {
      cli::cli_inform("phw_map(): No value of {.arg bins} falls inside the data ({lims[1]} to {lims[2]}), so every area has one colour.")
    }
    if (length(bins) == 1) return(scale_fill_phw_b(palette, n.breaks = bins, limits = lims, show.limits = TRUE))
    return(scale_fill_phw_b(palette, breaks = bins, limits = lims, show.limits = TRUE))
  }
  if (!is.null(bins)) cli::cli_inform("phw_map(): {.arg bins} is for numbers, so it is not used for a text or factor {.arg fill}.")
  scale_fill_phw_d(palette %||% phw_default_palette(), key = key)
}
