# Interactive maps with leaflet

`phw_leaflet()` starts a
[`leaflet::leaflet()`](https://rstudio.github.io/leaflet/reference/leaflet.html)
map with a light, quiet base map and the PHW font, centred on Wales.
`phw_leaflet_polygons()` adds filled areas (e.g. from
[`phw_boundaries()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundaries.md))
with PHW colours, hover labels and a legend in one call.
`phw_leaflet_palette()` gives a leaflet colour function from any PHW
palette, for your own layers.

## Usage

``` r
phw_leaflet(data = NULL, tiles = "Esri.WorldGrayCanvas", view = "wales", ...)

phw_leaflet_polygons(
  map,
  data,
  fill = NULL,
  palette = NULL,
  bins = NULL,
  label = NULL,
  popup = NULL,
  legend_title = fill,
  opacity = 0.8,
  weight = 1,
  colour = "#FFFFFF",
  key = NULL,
  polygon_args = list()
)

phw_leaflet_palette(
  palette = "blues",
  domain,
  type = c("numeric", "bin", "quantile", "factor"),
  bins = 5,
  reverse = FALSE,
  na.color = phw_colours[["grey_light"]]
)
```

## Arguments

- data:

  Optional data for the map, as in
  [`leaflet::leaflet()`](https://rstudio.github.io/leaflet/reference/leaflet.html).

- tiles:

  Base map from
  [leaflet::providers](https://rstudio.github.io/leaflet/reference/providers.html),
  or `NULL` for none. The default is a light grey map (Esri World Gray
  Canvas, which needs no API key) that keeps your colours readable.

- view:

  `"wales"` to start on Wales, or `NULL` to fit the data.

- ...:

  Passed to
  [`leaflet::leaflet()`](https://rstudio.github.io/leaflet/reference/leaflet.html).

- map:

  A leaflet map.

- fill:

  Column of `data` to colour by, unquoted as in dplyr (a string works
  too). Numbers get a continuous or binned scale; text and factors get
  distinct colours.

- palette:

  Palette name or colours, as in
  [`phw_pal()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pal.md).
  Defaults to `"blues"` for numbers and the default palette for groups.

- bins:

  Number of bins, or a vector of breaks, for numeric `fill`. `NULL`
  gives a continuous scale.

- label, popup:

  What to show on hover and on click: a column of `data`, unquoted, or
  an expression built from its columns such as `paste(name, rate)`. A
  string naming a column, or a vector with one value per row, works too.

- legend_title:

  Legend title, or `NULL` for no legend. Defaults to the name of the
  `fill` column.

- opacity:

  Fill opacity.

- weight, colour:

  Outline width and colour.

- key:

  Name of a colour key, so groups keep their colours (see
  [`phw_colour_key()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_colour_key.md)).

- polygon_args:

  List of other
  [`leaflet::addPolygons()`](https://rstudio.github.io/leaflet/reference/map-layers.html)
  arguments.

- domain:

  Values the palette should cover.

- type:

  `"numeric"` (continuous), `"bin"`, `"quantile"` or `"factor"`.

- reverse:

  Reverse the palette?

- na.color:

  Colour for missing values.

## Value

A leaflet map.

## Examples

``` r
if (requireNamespace("leaflet", quietly = TRUE)) {
  phw_leaflet()
}

{"x":{"options":{"crs":{"crsClass":"L.CRS.EPSG3857","code":null,"proj4def":null,"projectedBounds":null,"options":{}}},"calls":[{"method":"addProviderTiles","args":["Esri.WorldGrayCanvas",null,null,{"errorTileUrl":"","noWrap":false,"detectRetina":false}]}],"fitBounds":[51.35,-5.4,53.45,-2.65,[]]},"evals":[],"jsHooks":[]}# \donttest{
if (requireNamespace("leaflet", quietly = TRUE) && requireNamespace("sf", quietly = TRUE) &&
    interactive()) {
  hb <- phw_boundaries("health_board", crs = 4326)
  hb$rate <- runif(nrow(hb), 10, 50)
  phw_leaflet() |>
    phw_leaflet_polygons(hb, fill = rate, label = name, legend_title = "Rate")
}
# }
```
