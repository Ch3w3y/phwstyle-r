#' Interactive maps with leaflet
#'
#' `phw_leaflet()` starts a [leaflet::leaflet()] map with a light, quiet
#' base map and the PHW font, centred on Wales. `phw_leaflet_polygons()`
#' adds filled areas (e.g. from [phw_boundaries()]) with PHW colours, hover
#' labels and a legend in one call. `phw_leaflet_palette()` gives a leaflet
#' colour function from any PHW palette, for your own layers.
#'
#' @param data Optional data for the map, as in [leaflet::leaflet()].
#' @param tiles Base map from [leaflet::providers], or `NULL` for none.
#'   The default is a light grey map (Esri World Gray Canvas, which needs no
#'   API key) that keeps your colours readable.
#' @param view `"wales"` to start on Wales, or `NULL` to fit the data.
#' @param ... Passed to [leaflet::leaflet()].
#' @return A leaflet map.
#' @examples
#' if (requireNamespace("leaflet", quietly = TRUE)) {
#'   phw_leaflet()
#' }
#' \donttest{
#' if (requireNamespace("leaflet", quietly = TRUE) && requireNamespace("sf", quietly = TRUE) &&
#'     interactive()) {
#'   hb <- phw_boundaries("health_board", crs = 4326)
#'   hb$rate <- runif(nrow(hb), 10, 50)
#'   phw_leaflet() |>
#'     phw_leaflet_polygons(hb, fill = rate, label = name, legend_title = "Rate")
#' }
#' }
#' @export
phw_leaflet <- function(data = NULL, tiles = "Esri.WorldGrayCanvas", view = "wales", ...) {
  rlang::check_installed("leaflet")
  if (!is.null(view)) view <- rlang::arg_match(view, "wales")
  m <- leaflet::leaflet(data, ...)
  if (!is.null(tiles)) m <- leaflet::addProviderTiles(m, tiles)
  if (identical(view, "wales")) m <- leaflet::fitBounds(m, -5.4, 51.35, -2.65, 53.45)
  m$dependencies <- c(m$dependencies, list(phw_font_dependency(), phw_leaflet_css()))
  m
}

phw_leaflet_css <- function() {
  css <- sprintf(paste0(
    ".leaflet-container, .leaflet-container .info, .leaflet-tooltip, .leaflet-popup-content {",
    "font-family: %s, Arial, sans-serif; color: %s;}",
    ".leaflet-container .legend {border-radius: 2px; box-shadow: 0 1px 4px rgba(0,0,0,.25);}",
    ".leaflet-container .legend strong, .leaflet-container .legend .legend-title {color: %s;}"),
    phw_font(), phw_colours[["text"]], phw_colours[["navy"]])
  htmltools::htmlDependency("phw-leaflet", "0.1", src = c(href = ""), head = sprintf("<style>%s</style>", css))
}

#' @rdname phw_leaflet
#' @param map A leaflet map.
#' @param fill Column of `data` to colour by, unquoted as in dplyr (a string
#'   works too). Numbers get a continuous or binned scale; text and factors
#'   get distinct colours.
#' @param palette Palette name or colours, as in [phw_pal()]. Defaults to
#'   `"blues"` for numbers and the default palette for groups.
#' @param bins Number of bins, or a vector of breaks, for numeric `fill`.
#'   `NULL` gives a continuous scale.
#' @param label,popup What to show on hover and on click: a column of
#'   `data`, unquoted, or an expression built from its columns such as
#'   `paste(name, rate)`. A string naming a column, or a vector with one
#'   value per row, works too.
#' @param legend_title Legend title, or `NULL` for no legend. Defaults to
#'   the name of the `fill` column.
#' @param opacity Fill opacity.
#' @param weight,colour Outline width and colour.
#' @param key Name of a colour key, so groups keep their colours (see
#'   [phw_colour_key()]).
#' @param polygon_args List of other [leaflet::addPolygons()] arguments.
#' @export
phw_leaflet_polygons <- function(map, data, fill = NULL, palette = NULL, bins = NULL,
                                 label = NULL, popup = NULL, legend_title = fill,
                                 opacity = 0.8, weight = 1, colour = "#FFFFFF", key = NULL,
                                 polygon_args = list()) {
  rlang::check_installed(c("leaflet", "sf"))
  rlang::check_required(data)
  data <- check_leaflet_polygons(map, data, bins, polygon_args)
  fill <- pick_col(rlang::enquo(fill), data, "fill", null_ok = TRUE)
  label <- leaflet_text(rlang::enquo(label), data, "label")
  popup <- leaflet_text(rlang::enquo(popup), data, "popup")
  if (!is.na(sf::st_crs(data)) && !isTRUE(sf::st_is_longlat(data))) data <- sf::st_transform(data, 4326)
  na_col <- phw_colours[["grey_light"]]
  pal_fun <- NULL
  legend_values <- NULL
  fill_col <- phw_colours[["navy"]]
  if (!is.null(fill)) {
    v <- data[[fill]]
    if (is.numeric(v)) {
      if (!is.null(key)) cli::cli_warn("{.arg key} is for a fill of groups, so it is not used with a numeric fill.")
      ok <- is.finite(v)
      if (!any(ok)) {
        cli::cli_inform("{.field {fill}} has no values to colour by, so every area is drawn as missing.")
        fill_col <- na_col
      } else {
        legend_values <- ifelse(ok, v, NA)
        pal_fun <- phw_leaflet_palette(palette %||% "blues", domain = v[ok],
                                       type = if (is.null(bins)) "numeric" else "bin", bins = bins,
                                       na.color = na_col)
        fill_col <- pal_fun(legend_values)
      }
    } else {
      if (!is.null(bins)) cli::cli_warn("{.arg bins} is for a numeric fill, so it is not used with groups.")
      levels <- if (is.factor(v)) levels(v) else unique(as.character(v[!is.na(v)]))
      cols <- phw_colour_key(levels, name = key, palette = palette %||% phw_default_palette(),
                             save = !is.null(key))
      pal_fun <- leaflet::colorFactor(unname(cols[levels]), levels = levels, ordered = TRUE,
                                      na.color = na_col)
      legend_values <- v
      fill_col <- pal_fun(v)
    }
  }
  args <- utils::modifyList(list(
    map = map, data = data, fillColor = fill_col, fillOpacity = opacity, color = colour, weight = weight,
    label = label, popup = popup,
    highlightOptions = leaflet::highlightOptions(weight = 3, color = phw_colours[["navy_dark"]],
                                                 bringToFront = TRUE)
  ), polygon_args)
  map <- do.call(leaflet::addPolygons, args)
  if (!is.null(pal_fun) && !is.null(legend_title)) {
    values <- unique(legend_values[!is.na(legend_values)])
    map <- if (is.numeric(values) && length(values) == 1) {
      # A gradient over a single value has no length, so show it as a swatch.
      leaflet::addLegend(map, colors = pal_fun(values), labels = format(values),
                         title = legend_title, opacity = opacity, position = "bottomright")
    } else {
      leaflet::addLegend(map, pal = pal_fun, values = legend_values, title = legend_title,
                         opacity = opacity, position = "bottomright")
    }
  }
  map
}

check_leaflet_polygons <- function(map, data, bins, polygon_args, call = rlang::caller_env()) {
  if (!inherits(map, "leaflet")) {
    cli::cli_abort("{.arg map} must be a leaflet map, such as {.code phw_leaflet()}, not {.obj_type_friendly {map}}.",
                   call = call)
  }
  if (!inherits(data, "sf")) {
    cli::cli_abort(c("{.arg data} must be an sf object of areas, not {.obj_type_friendly {data}}.",
                     i = "Use {.fn phw_boundaries}, or convert with {.fn sf::st_as_sf}."), call = call)
  }
  check_has_rows(data, call = call)
  if (!is.null(bins) && (!is.numeric(bins) || anyNA(bins) ||
                         (length(bins) == 1 && bins < 2) || length(bins) == 0)) {
    cli::cli_abort("{.arg bins} must be a number of bins (2 or more) or a vector of breaks.", call = call)
  }
  if (!is.list(polygon_args) || (length(polygon_args) && !rlang::is_named(polygon_args))) {
    cli::cli_abort("{.arg polygon_args} must be a named list, e.g. {.code list(smoothFactor = 0.5)}.", call = call)
  }
  empty <- sf::st_is_empty(data)
  if (all(empty)) cli::cli_abort("{.arg data} has no areas to draw: every geometry is empty.", call = call)
  if (any(empty)) {
    cli::cli_inform("Left out {sum(empty)} row{?s} of {.arg data} with an empty geometry.")
    data <- data[!empty, ]
  }
  types <- unique(as.character(sf::st_geometry_type(data)))
  bad <- setdiff(types, c("POLYGON", "MULTIPOLYGON"))
  if (length(bad)) {
    cli::cli_abort(c("{.arg data} must hold polygons, but has {.val {bad}} geometry.",
                     i = "Use {.fn leaflet::addCircleMarkers} or {.fn leaflet::addPolylines} for other shapes."),
                   call = call)
  }
  if (is.na(sf::st_crs(data))) {
    bb <- sf::st_bbox(data)
    if (any(abs(bb[c("xmin", "xmax")]) > 180) || any(abs(bb[c("ymin", "ymax")]) > 90)) {
      cli::cli_abort(c("{.arg data} has no coordinate reference system, and its coordinates are not longitude and latitude.",
                       i = "For British National Grid, set it with {.code sf::st_set_crs(data, 27700)}."),
                     call = call)
    }
  }
  data
}

# Hover and click text: a column or an expression of the columns, with one
# value per row or one for every row.
leaflet_text <- function(quo, data, arg, call = rlang::caller_env()) {
  val <- tryCatch(pick_text(quo, data), error = function(e) {
    cli::cli_abort("{.arg {arg}} must be a column of {.arg data} or an expression of its columns.",
                   parent = e, call = call)
  })
  if (!is.null(val) && !length(val) %in% c(1, nrow(data))) {
    cli::cli_abort("{.arg {arg}} must have one value, or one for each of the {nrow(data)} rows, not {length(val)}.",
                   call = call)
  }
  val
}

#' @rdname phw_leaflet
#' @param domain Values the palette should cover.
#' @param type `"numeric"` (continuous), `"bin"`, `"quantile"` or
#'   `"factor"`.
#' @param reverse Reverse the palette?
#' @param na.color Colour for missing values.
#' @export
phw_leaflet_palette <- function(palette = "blues", domain, type = c("numeric", "bin", "quantile", "factor"),
                                bins = 5, reverse = FALSE, na.color = phw_colours[["grey_light"]]) {
  rlang::check_installed("leaflet")
  type <- rlang::arg_match(type)
  if (type != "factor") {
    if (is.character(palette) && length(palette) == 1 && palette %in% names(phw_palettes) &&
        palette_type(palette) == "qualitative") {
      cli::cli_abort(c("{.val {palette}} is a palette for groups, not for numbers.",
                       i = "Use a sequential palette such as {.val blues}, or {.code type = \"factor\"}."))
    }
    if (!is.numeric(domain)) cli::cli_abort("{.arg domain} must be numbers for {.code type = \"{type}\"}.")
    domain <- domain[is.finite(domain)]
    if (!length(domain)) cli::cli_abort("{.arg domain} has no values that are not missing.")
  }
  if (type == "quantile") {
    n_q <- if (length(bins) == 1) bins else 5
    breaks <- unique(stats::quantile(domain, probs = seq(0, 1, length.out = n_q + 1), names = FALSE))
    if (length(breaks) < n_q + 1) {
      cli::cli_abort(c("{.arg domain} has too few different values for {n_q} quantile groups.",
                       i = "Use fewer {.arg bins}, or {.code type = \"bin\"}."))
    }
  }
  n <- if (type == "factor") length(unique(domain)) else 9
  cols <- phw_pal(n, palette = palette, reverse = reverse,
                  type = if (type == "factor") "qualitative" else "sequential")
  switch(type,
    numeric = leaflet::colorNumeric(cols, domain = domain, na.color = na.color),
    bin = leaflet::colorBin(cols, domain = domain, bins = bins %||% 5, na.color = na.color),
    quantile = leaflet::colorQuantile(cols, domain = domain, n = if (length(bins) == 1) bins else 5,
                                      na.color = na.color),
    factor = leaflet::colorFactor(cols, domain = domain, na.color = na.color))
}
