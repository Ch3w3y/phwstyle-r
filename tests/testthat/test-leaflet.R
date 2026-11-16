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

test_that("groups take the colours a PHW ggplot2 scale gives the same data", {
  skip_if_not_installed("ggplot2")
  gg_fill <- function(d) {
    ggplot2::layer_data(ggplot2::ggplot(d) + ggplot2::geom_sf(ggplot2::aes(fill = grp)) + scale_fill_phw_d())$fill
  }
  sq <- squares()
  sq$grp <- c("Zeta", "Alpha", "Mid")
  m <- phw_leaflet() |> phw_leaflet_polygons(sq, fill = grp)
  expect_equal(polygon_fill(m), gg_fill(sq), ignore_attr = TRUE)
  expect_equal(polygon_fill(m), phw_colours[c("orange", "navy", "teal")], ignore_attr = TRUE)
  sq$grp <- factor(c("Low", "High", "Low"), levels = c("Low", "Mid", "High"))
  m <- phw_leaflet() |> phw_leaflet_polygons(sq, fill = grp)
  expect_equal(polygon_fill(m), gg_fill(sq), ignore_attr = TRUE)
  expect_equal(legend_args(m)$labels, c("Low", "High"), ignore_attr = TRUE)
})

test_that("a factor palette gives each group an exact palette colour, ignoring NA and unused levels", {
  main <- unname(phw_palettes$main[1:3])
  pal <- phw_leaflet_palette("main", domain = c("b", "a", NA, "c"), type = "factor")
  expect_equal(pal(c("a", "b", "c")), main)
  pal <- phw_leaflet_palette("main", domain = factor(c("c", "a"), levels = c("a", "b", "c")), type = "factor")
  expect_equal(pal(c("a", "c")), main[1:2])
  expect_equal(pal(NA), phw_colours[["grey_light"]], ignore_attr = TRUE)
})

test_that("a factor palette gives each group the colour a map of the same groups gives it", {
  areas <- c("Wrexham", "Cardiff", "Unknown", "Bangor", "Newport")
  pal <- phw_leaflet_palette("main", domain = areas, type = "factor")
  sq <- squares(5)
  sq$grp <- areas
  m <- phw_leaflet() |> phw_leaflet_polygons(sq, fill = grp)
  expect_equal(pal(areas), polygon_fill(m))
  expect_equal(pal("Unknown"), phw_colours[["grey_mid"]], ignore_attr = TRUE)
  expect_equal(pal(c("Bangor", "Cardiff", "Newport", "Wrexham")), phw_pal(4))
})

test_that("a factor palette carries \"main\" on into \"extended\" and reverses as phw_pal() does", {
  lv <- sprintf("g%02d", 1:13)
  pal <- suppressWarnings(phw_leaflet_palette("main", domain = lv, type = "factor"))
  expect_equal(pal(lv[1:12]), phw_pal(12))
  expect_length(unique(pal(lv)), 13)
  pal <- phw_leaflet_palette("main", domain = c(lv[1:3], "Unknown"), type = "factor", reverse = TRUE)
  expect_equal(pal(c(lv[1:3], "Unknown")), c(phw_pal(3, reverse = TRUE), phw_colours[["grey_mid"]]))
})

test_that("a factor palette spreads a sequential palette as phw_pal() does", {
  pal <- phw_leaflet_palette("blues", domain = c("a", "b", "c"), type = "factor")
  expect_equal(pal(c("a", "b", "c")), phw_pal(3, "blues"))
  pal <- phw_leaflet_palette("blues", domain = c("a", "b", "c"), type = "factor", reverse = TRUE)
  expect_equal(pal(c("a", "b", "c")), phw_pal(3, "blues", reverse = TRUE))
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

test_that("bins split the areas into the classes phw_map() gives, with no value drawn as missing", {
  skip_if_not_installed("ggplot2")
  sq <- squares(4)
  sq$code <- paste0("A", 1:4)
  sq$rate <- c(10, 25, 35, 40)
  classes <- function(cols) match(cols, unique(cols))
  for (bins in list(c(20, 30, 40), c(0, 20, 30, 100), 5)) {
    m <- expect_no_warning(phw_leaflet() |> phw_leaflet_polygons(sq, fill = rate, bins = bins))
    p <- phw_map(sf::st_drop_geometry(sq), by = code, fill = rate, level = sq, bins = bins)
    expect_false(any(polygon_fill(m) == phw_colours[["grey_light"]]))
    expect_equal(classes(polygon_fill(m)), classes(ggplot2::layer_data(p, 2)$fill))
    expect_equal(gsub("&ndash;", "-", legend_args(m)$labels), c("10 - 20", "20 - 30", "30 - 40"),
                 ignore_attr = TRUE)
  }
  expect_message(phw_leaflet() |> phw_leaflet_polygons(sq, fill = rate, bins = c(50, 60)), "inside the data")
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
