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
  expect_equal(plot_labs(p)$fill, "rate")
})

test_that("maps follow the settings given to use_phw_ggplot() and keep their own legend and gridlines", {
  library(ggplot2)
  local_ggplot_state()
  areas <- tiny_areas()
  d <- data.frame(area = areas$code, rate = 1:4)
  expect_equal(phw_map(d, area, rate, areas)$theme$text$size, 11)
  use_phw_ggplot(base_size = 16, accessible = TRUE, strip = "navy", grid = "xy", legend = "bottom")
  th <- phw_map(d, area, rate, areas)$theme
  expect_equal(th$text$size, 16)
  expect_equal(th$strip.background$fill, phw_colours[["navy"]])
  expect_equal(th$legend.position, "right")
  expect_s3_class(th$legend.title, "element_text")
  expect_s3_class(th$panel.grid, "element_blank")
  expect_s3_class(th$panel.grid.major.x, "element_blank")
  expect_s3_class(th$axis.text, "element_blank")
  theme_update(plot.title = element_text(colour = "red"))
  expect_equal(phw_map(d, area, rate, areas)$theme$text$size, 16)
  theme_set(theme_grey())
  expect_equal(phw_map(d, area, rate, areas)$theme$text$size, 11)
})

test_that("bins give a binned scale with those breaks", {
  areas <- tiny_areas()
  d <- data.frame(area = areas$code, rate = c(5, 15, 25, 35))
  p <- phw_map(d, by = area, fill = rate, level = areas, bins = c(10, 20, 30))
  sc <- p$scales$get_scales("fill")
  expect_s3_class(sc, "ScaleBinned")
  expect_length(unique(fills(p)), 4)
  expect_equal(ggplot2::get_guide_data(p, "fill")$.label, c("5", "10", "20", "30", "35"))
})

test_that("breaks outside the data never draw a value as missing", {
  areas <- tiny_areas()
  d <- data.frame(area = areas$code, rate = c(5, 15, 25, 35))
  p <- phw_map(d, by = area, fill = rate, level = areas, bins = c(0, 20, 100))
  expect_false(any(fills(p) == phw_colours[["grey_light"]]))
  expect_length(unique(fills(p)), 2)
  expect_equal(ggplot2::get_guide_data(p, "fill")$.label, c("5", "20", "35"))
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

test_that("ten deciles take the whole sequential palette, as phw_pal() does", {
  skip_if_not_installed("sf")
  square <- function(x) sf::st_polygon(list(rbind(c(x, 0), c(x + 1, 0), c(x + 1, 1), c(x, 1), c(x, 0))))
  areas <- sf::st_sf(code = paste0("A", 1:10), name = paste("Area", 1:10),
                     geometry = sf::st_sfc(lapply(1:10, square)))
  d <- data.frame(area = areas$code, decile = factor(1:10))
  expect_no_warning(p <- phw_map(d, by = area, fill = decile, level = areas, palette = "blues"))
  expect_equal(fills(p), phw_pal(10, "blues"))
})

test_that("areas without data are drawn in the NA colour", {
  areas <- tiny_areas()
  p <- phw_map(data.frame(area = c("A1", "A2"), rate = c(1, 2)), by = area, fill = rate, level = areas)
  expect_equal(nrow(p$data), 2)
  expect_equal(unique(ggplot2::ggplot_build(p)$data[[1]]$fill), unname(phw_colours[["grey_light"]]))
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("an area held as several rows in level is filled in every part", {
  areas <- tiny_areas()
  areas$code[4] <- "A2"
  p <- phw_map(data.frame(area = c("A1", "A2"), rate = c(10, 20)), by = area, fill = rate, level = areas)
  expect_equal(nrow(ggplot2::layer_data(p, 1)), 3)
  expect_equal(nrow(p$data), 2)
  expect_equal(sf::st_area(p$data), c(1, 2))
  expect_equal(plot_labs(p)$caption, wrap_caption("Boundaries: test source"))
})

test_that("each facet panel draws every area, in the NA colour where it has no data", {
  areas <- tiny_areas()
  d <- data.frame(area = c("A1", "A2", "A3", "A4", "A1", "A2"), yr = c(1, 1, 1, 1, 2, 2), v = 1:6)
  p <- phw_map(d, by = area, fill = v, level = areas) + ggplot2::facet_wrap(~yr)
  under <- ggplot2::layer_data(p, 1)
  expect_equal(as.vector(table(under$PANEL)), c(4, 4))
  expect_equal(unique(under$fill), unname(phw_colours[["grey_light"]]))
  expect_equal(as.vector(table(ggplot2::layer_data(p, 2)$PANEL)), c(4, 2))
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
  expect_equal(plot_labs(p)$caption, "Boundaries: test source", ignore_attr = TRUE)
  p2 <- p + ggplot2::labs(caption = "Mine")
  expect_equal(plot_labs(p2)$caption, "Mine")
})

test_that("labels are added at each area and level needs code and name", {
  areas <- tiny_areas()
  d <- data.frame(area = areas$code, rate = 1:4)
  p <- phw_map(d, by = area, fill = rate, level = areas, label = paste(name, rate))
  lab <- ggplot2::layer_data(p, length(p$layers))
  expect_equal(lab$label, paste(areas$name, 1:4))
  expect_error(phw_map(d, by = area, fill = rate, level = areas[, "code"]), "code")
})

test_that("each label takes white or dark text from its own area's fill", {
  areas <- tiny_areas()
  dark <- phw_colours[["text"]]
  label_cols <- function(p) ggplot2::layer_data(p, length(p$layers))$colour
  d <- data.frame(area = areas$code, rate = c(1, 100, 1, 100),
                  band = c("Deep", "Pale", "Deep", "Pale"))

  cont <- phw_map(d, by = area, fill = rate, level = areas, label = rate)
  expect_equal(label_cols(cont), phw_text_on(fills(cont)))
  expect_equal(unique(label_cols(cont)), c(dark, "#FFFFFF"))
  expect_equal(label_cols(cont)[2], "#FFFFFF")

  disc <- phw_map(d, by = area, fill = band, level = areas, label = band) +
    ggplot2::scale_fill_manual(values = c(Deep = unname(phw_col("navy")), Pale = unname(phw_col("light_teal"))))
  ld <- ggplot2::layer_data(disc, length(disc$layers))
  expect_equal(ld$colour[ld$label == "Deep"], rep("#FFFFFF", 2))
  expect_equal(ld$colour[ld$label == "Pale"], rep(dark, 2))

  d$rate[2] <- NA
  gap <- phw_map(d, by = area, fill = rate, level = areas, label = rate)
  expect_equal(label_cols(gap), phw_text_on(fills(gap)))
})

test_that("rows whose code is missing or unknown are left out with one message", {
  areas <- tiny_areas()
  d <- data.frame(area = c("A1", "A2", "X9", NA), rate = 1:4)
  expect_message(p <- phw_map(d, by = area, fill = rate, level = areas), "Left out 2 rows.*X9")
  expect_equal(p$data$area, c("A1", "A2"))
})

test_that("a code drawn twice in one panel gives a message, but not when faceted", {
  areas <- tiny_areas()
  d <- data.frame(area = c("A1", "A1", "A2", "A2"), period = c(1, 2, 1, 2), rate = 1:4)
  p <- phw_map(d, by = area, fill = rate, level = areas)
  expect_message(ggplot2::ggplot_build(p), "A1.*more than one row")
  expect_no_message(ggplot2::ggplot_build(p + ggplot2::facet_wrap(~period)))
})

test_that("phw_map handles missing, infinite and out-of-range fills", {
  areas <- tiny_areas()
  d <- data.frame(area = areas$code, rate = c(1, NA, 3, 4))
  expect_no_warning(ggplot2::ggplot_build(phw_map(d, by = area, fill = rate, level = areas, label = rate)))
  expect_error(phw_map(transform(d, rate = NA_real_), by = area, fill = rate, level = areas, bins = 2),
               "Every value in rate is missing")
  expect_message(phw_map(d, by = area, fill = rate, level = areas, bins = c(50, 60)), "inside the data")
  expect_message(phw_map(transform(d, rate = c(1, Inf, 3, 4)), by = area, fill = rate, level = areas),
                 "infinite")
})

test_that("a qualitative palette or a plain data frame level gives an error naming the fix", {
  areas <- tiny_areas()
  d <- data.frame(area = areas$code, rate = 1:4)
  expect_error(phw_map(d, by = area, fill = rate, level = areas, palette = "main"), "sequential palette")
  expect_error(phw_map(d, by = area, fill = rate, level = as.data.frame(areas)[c("code", "name")]),
               "sf data frame")
})

test_that("bins must be a number of bins (2 or more) or a vector of breaks", {
  areas <- tiny_areas()
  d <- data.frame(area = areas$code, rate = c(-3, -1, 0, 5))
  for (bins in list(1, 0, -2, Inf, NA_real_, numeric(0), "5")) {
    expect_error(phw_map(d, by = area, fill = rate, level = areas, bins = bins), "`bins` must be")
  }
})

test_that("phw_map says when bins or key do not apply to the fill", {
  areas <- tiny_areas()
  d <- data.frame(area = areas$code, rate = 1:4, band = c("a", "b", "a", "b"))
  expect_message(phw_map(d, by = area, fill = band, level = areas, bins = 3), "bins")
  expect_message(phw_map(d, by = area, fill = rate, level = areas, key = "k"), "key")
})

test_that("map labels show in plotly, in the text colour of their area", {
  skip_if_not_installed("plotly")
  skip_if_not_installed("ggrepel")
  areas <- tiny_areas()
  d <- data.frame(area = areas$code, rate = c(1, 2, 3, 40))
  expect_no_warning(w <- phw_plotly(phw_map(d, by = area, fill = rate, level = areas, label = paste(name, rate))))
  lab <- Filter(function(t) identical(t$mode, "text"), plotly::plotly_build(w)$x$data)
  text <- unlist(lapply(lab, function(t) as.vector(t$text)))
  colour <- unlist(lapply(lab, function(t) rep_len(t$textfont$color, length(t$text))))
  expect_setequal(text, paste(areas$name, d$rate))
  expect_equal(text[colour == "rgba(255,255,255,1)"], "Area 4 40")
})

licence <- paste("Source: Office for National Statistics licensed under the Open Government",
                 "Licence v3.0. Contains OS data (c) Crown copyright and database right.")

# Taller than wide, as Wales is, so a longer caption makes it narrower.
licensed_map <- function(...) {
  areas <- tiny_areas()
  sf::st_geometry(areas) <- sf::st_geometry(areas) * matrix(c(1, 0, 0, 1.5), 2)
  attr(areas, "attribution") <- licence
  phw_map(data.frame(area = areas$code, rate = c(52, 61, 47, 70)), by = area, fill = rate, level = areas, ...)
}

test_that("a map saved at half-page width keeps its whole licence line on the image", {
  m <- licensed_map()
  for (fig in list(m, phw_finalise(m, logo = FALSE))) {
    lines <- saved_caption_lines(fig, licence, width = 8, height = 9)
    expect_caption_within(lines, licence, 0, 8 / 2.54)
  }
})

test_that("two maps side by side each keep their whole licence line, clear of the other", {
  skip_if_not_installed("patchwork")
  m <- licensed_map()
  expect_captions_side_by_side(saved_caption_lines(phw_arrange(m, m), licence), licence, 16 / 2.54)
})

test_that("a map beside a chart, or two maps finalised, keep their size and whole licence line", {
  skip_if_not_installed("patchwork")
  chart <- ggplot2::ggplot(data.frame(year = c("2024", "2025"), cases = c(300, 340)),
                           ggplot2::aes(year, cases, fill = year)) +
    ggplot2::geom_col() + ggplot2::labs(title = "Total") + theme_phw()
  figures <- function(m) {
    list(phw_arrange(m, chart, title = "Map and chart", source = "PHW"),
         phw_finalise(phw_arrange(m, chart, title = "Map and chart"), source = "PHW"),
         phw_finalise(phw_arrange(m, m, title = "Two maps"), source = "PHW"))
  }
  m <- licensed_map() + ggplot2::labs(title = "Rate")
  uncaptioned <- figures(m + ggplot2::labs(caption = NULL))
  for (i in seq_along(uncaptioned)) {
    fig <- figures(m)[[i]]
    expect_caption_within(saved_caption_lines(fig, licence), licence, 0, 16 / 2.54)
    expect_gt(min(drawn_panel_widths(fig)), min(drawn_panel_widths(uncaptioned[[i]])) / 2)
  }
})

test_that("the titles of two maps with different legends stay apart", {
  skip_if_not_installed("patchwork")
  titles <- c("Rate by area", "Binned")
  fig <- phw_arrange(licensed_map() + ggplot2::labs(title = titles[1]),
                     licensed_map(bins = c(45, 55, 65, 75)) + ggplot2::labs(title = titles[2]))
  drawn <- saved_caption_lines(fig, paste(titles, collapse = "\n"))
  expect_setequal(drawn$text, titles)
  expect_lt(drawn$right[drawn$text == titles[1]], drawn$left[drawn$text == titles[2]])
})
