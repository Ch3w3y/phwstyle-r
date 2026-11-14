tiny_areas <- function() {
  skip_if_not_installed("sf")
  square <- function(x, y) sf::st_polygon(list(rbind(c(x, y), c(x + 1, y), c(x + 1, y + 1),
                                                     c(x, y + 1), c(x, y))))
  out <- sf::st_sf(code = paste0("A", 1:4), name = paste("Area", 1:4),
                   geometry = sf::st_sfc(square(0, 0), square(1, 0), square(0, 1), square(1, 1)))
  attr(out, "attribution") <- "Boundaries: test source"
  out
}

fills <- function(p) ggplot2::ggplot_build(p)$data[[length(p$layers)]]$fill

test_that("a numeric fill gives a continuous scale and keeps the joined data", {
  areas <- tiny_areas()
  p <- phw_map(data.frame(area = c("A1", "A2", "A3", "A4"), rate = 1:4), by = area, fill = rate, level = areas)
  expect_s3_class(p, "ggplot")
  expect_s3_class(p$data, "sf")
  expect_equal(p$data$rate, 1:4)
  expect_equal(p$data$name, areas$name)
  expect_s3_class(p$scales$get_scales("fill"), "ScaleContinuous")
  expect_equal(ggplot2::get_labs(p)$fill, "rate")
})

test_that("bins give a binned scale with those breaks", {
  areas <- tiny_areas()
  d <- data.frame(area = areas$code, rate = c(5, 15, 25, 35))
  p <- phw_map(d, by = area, fill = rate, level = areas, bins = c(10, 20, 30))
  sc <- p$scales$get_scales("fill")
  expect_s3_class(sc, "ScaleBinned")
  expect_equal(sc$breaks, c(10, 20, 30))
  expect_length(unique(fills(p)), 4)
})

test_that("text fills use the group palette and keep factor levels", {
  areas <- tiny_areas()
  d <- data.frame(area = areas$code, band = factor(c("High", "Low", "High", "Low"), levels = c("Low", "High")))
  p <- phw_map(d, by = area, fill = band, level = areas)
  sc <- p$scales$get_scales("fill")
  expect_s3_class(sc, "ScaleDiscrete")
  cols <- fills(p)
  expect_equal(cols[1], cols[3])
  expect_false(cols[1] == cols[2])
})

test_that("areas without data are drawn in the NA colour", {
  areas <- tiny_areas()
  p <- phw_map(data.frame(area = c("A1", "A2"), rate = c(1, 2)), by = area, fill = rate, level = areas)
  expect_equal(nrow(p$data), 2)
  expect_equal(unique(ggplot2::ggplot_build(p)$data[[1]]$fill), unname(phw_colours[["grey_light"]]))
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("codes that match nothing are an error showing the expected codes", {
  areas <- tiny_areas()
  expect_error(phw_map(data.frame(area = c("X1", "X2"), rate = 1:2), by = area, fill = rate, level = areas),
               "A1")
})

test_that("the boundary attribution is the caption and labs() replaces it", {
  areas <- tiny_areas()
  d <- data.frame(area = areas$code, rate = 1:4)
  p <- phw_map(d, by = area, fill = rate, level = areas)
  expect_equal(ggplot2::get_labs(p)$caption, "Boundaries: test source")
  p2 <- p + ggplot2::labs(caption = "Mine")
  expect_equal(ggplot2::get_labs(p2)$caption, "Mine")
})

test_that("labels are added at each area and level needs code and name", {
  areas <- tiny_areas()
  d <- data.frame(area = areas$code, rate = 1:4)
  p <- phw_map(d, by = area, fill = rate, level = areas, label = paste(name, rate))
  lab <- ggplot2::layer_data(p, length(p$layers))
  expect_equal(lab$label, paste(areas$name, 1:4))
  expect_error(phw_map(d, by = area, fill = rate, level = areas[, "code"]), "code")
})
