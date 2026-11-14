skip_if_not_installed("leaflet")
skip_if_not_installed("sf")

squares <- function(n = 3, crs = 4326) {
  polys <- lapply(seq_len(n), function(i) {
    x <- -4 + (i - 1) * 0.5
    sf::st_polygon(list(rbind(c(x, 52), c(x + 0.4, 52), c(x + 0.4, 52.4), c(x, 52.4), c(x, 52))))
  })
  sf::st_sf(name = letters[seq_len(n)], geometry = sf::st_sfc(polys, crs = crs))
}

polygon_fill <- function(m) {
  call <- Filter(function(cl) cl$method == "addPolygons", m$x$calls)[[1]]
  call$args[[4]]$fillColor
}

legend_args <- function(m) Filter(function(cl) cl$method == "addLegend", m$x$calls)[[1]]$args[[1]]

test_that("missing groups are drawn in the house grey, as the legend shows", {
  sq <- squares()
  sq$grp <- c("A", NA, "B")
  m <- expect_no_warning(phw_leaflet() |> phw_leaflet_polygons(sq, fill = grp))
  expect_equal(polygon_fill(m), c(phw_colours[["navy"]], phw_colours[["grey_light"]], phw_colours[["teal"]]),
               ignore_attr = TRUE)
  expect_equal(legend_args(m)$na_color, phw_colours[["grey_light"]])
})

test_that("a numeric fill with no usable values draws every area as missing, with one message", {
  sq <- squares()
  sq$rate <- c(NA, Inf, NA)
  expect_message(m <- phw_leaflet() |> phw_leaflet_polygons(sq, fill = rate), "no values to colour by")
  expect_equal(unique(polygon_fill(m)), phw_colours[["grey_light"]])
  sq$rate <- c(1, Inf, 5)
  m <- expect_no_warning(phw_leaflet() |> phw_leaflet_polygons(sq, fill = rate))
  expect_equal(polygon_fill(m)[2], phw_colours[["grey_light"]])
  expect_equal(legend_args(m)$na_color, phw_colours[["grey_light"]])
})

test_that("one value gives a single legend swatch", {
  sq <- squares()
  sq$rate <- 5
  m <- phw_leaflet() |> phw_leaflet_polygons(sq, fill = rate)
  expect_equal(legend_args(m)$labels, "5", ignore_attr = TRUE)
})

test_that("quantile bins over tied values stop with a clear error", {
  expect_error(phw_leaflet_palette("blues", c(1, 1, 1, 2), type = "quantile"), "too few different values")
})

test_that("a group palette is refused for numbers", {
  sq <- squares()
  sq$rate <- 1:3
  expect_error(phw_leaflet() |> phw_leaflet_polygons(sq, fill = rate, palette = "main"), "palette for groups")
})

test_that("areas with no CRS in British National Grid stop and say how to set it", {
  sq <- sf::st_set_crs(sf::st_transform(squares(), 27700), NA)
  expect_error(phw_leaflet() |> phw_leaflet_polygons(sq), "st_set_crs\\(data, 27700\\)")
})

test_that("labels must be a column or one value per row", {
  sq <- squares()
  expect_error(phw_leaflet() |> phw_leaflet_polygons(sq, label = nope), "`label` must be a column")
  expect_error(phw_leaflet() |> phw_leaflet_polygons(sq, label = c("x", "y")), "one for each of the 3 rows")
})

test_that("map, data, bins and polygon_args are checked at entry", {
  sq <- squares()
  sq$rate <- 1:3
  expect_error(phw_leaflet_polygons(NULL, sq), "must be a leaflet map")
  expect_error(phw_leaflet() |> phw_leaflet_polygons(as.data.frame(sq)), "must be an sf object")
  expect_error(phw_leaflet() |> phw_leaflet_polygons(suppressWarnings(sf::st_centroid(sq))), "must hold polygons")
  expect_error(phw_leaflet() |> phw_leaflet_polygons(sq, fill = rate, bins = 1), "`bins` must be")
  expect_error(phw_leaflet() |> phw_leaflet_polygons(sq, polygon_args = "x"), "named list")
  expect_error(phw_leaflet() |> phw_leaflet_polygons(sq[0, ]), "has no rows")
})

test_that("empty geometries are left out with a message", {
  sq <- squares()
  sf::st_geometry(sq)[2] <- sf::st_polygon()
  expect_message(m <- phw_leaflet() |> phw_leaflet_polygons(sq), "Left out 1 row")
  expect_s3_class(m, "leaflet")
})

test_that("view must be wales or NULL, and unused arguments warn", {
  expect_error(phw_leaflet(view = "scotland"), "must be one of")
  sq <- squares()
  sq$rate <- 1:3
  expect_warning(phw_leaflet() |> phw_leaflet_polygons(sq, fill = name, bins = 3), "`bins` is for a numeric fill")
  expect_warning(phw_leaflet() |> phw_leaflet_polygons(sq, fill = rate, key = "k"), "`key` is for a fill of groups")
})
