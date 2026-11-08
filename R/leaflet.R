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
#'     phw_leaflet_polygons(hb, fill = "rate", label = "name", legend_title = "Rate")
#' }
#' }
#' @export
phw_leaflet <- function(data = NULL, tiles = "Esri.WorldGrayCanvas", view = "wales", ...) {
  rlang::check_installed("leaflet")
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
#' @param fill Column of `data` to colour by. Numbers get a continuous or
#'   binned scale; text and factors get distinct colours.
#' @param palette Palette name or colours, as in [phw_pal()]. Defaults to
#'   `"blues"` for numbers and the default palette for groups.
#' @param bins Number of bins, or a vector of breaks, for numeric `fill`.
#'   `NULL` gives a continuous scale.
#' @param label Column used for the hover label.
#' @param popup Column, or vector, used for the click popup.
#' @param legend_title Legend title, or `NULL` for no legend.
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
  if (!is.na(sf::st_crs(data)) && !isTRUE(sf::st_is_longlat(data))) data <- sf::st_transform(data, 4326)
  pal_fun <- NULL
  fill_col <- phw_colours[["navy"]]
  if (!is.null(fill)) {
    v <- data[[fill]]
    if (is.numeric(v)) {
      pal_fun <- phw_leaflet_palette(palette %||% "blues", domain = v,
                                     type = if (is.null(bins)) "numeric" else "bin", bins = bins)
    } else {
      levels <- if (is.factor(v)) levels(v) else unique(as.character(v))
      cols <- phw_colour_key(levels, name = key, palette = palette %||% phw_default_palette(),
                             save = !is.null(key))
      pal_fun <- leaflet::colorFactor(unname(cols[levels]), levels = levels, ordered = TRUE)
    }
    fill_col <- pal_fun(v)
  }
  lab <- if (!is.null(label)) {
    if (length(label) == 1 && label %in% names(data)) as.character(data[[label]]) else label
  }
  pop <- if (!is.null(popup)) {
    if (length(popup) == 1 && popup %in% names(data)) as.character(data[[popup]]) else popup
  }
  args <- utils::modifyList(list(
    map = map, data = data, fillColor = fill_col, fillOpacity = opacity, color = colour, weight = weight,
    label = lab, popup = pop,
    highlightOptions = leaflet::highlightOptions(weight = 3, color = phw_colours[["navy_dark"]],
                                                 bringToFront = TRUE)
  ), polygon_args)
  map <- do.call(leaflet::addPolygons, args)
  if (!is.null(pal_fun) && !is.null(legend_title)) {
    map <- leaflet::addLegend(map, pal = pal_fun, values = data[[fill]], title = legend_title,
                              opacity = opacity, position = "bottomright")
  }
  map
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
