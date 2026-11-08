make_grouped <- function() {
  set.seed(1)
  dat <- data.frame(group = sample(c("Group A", "Group B"), 60, TRUE), type = sample(c("Type 1", "Type 2"), 60, TRUE),
                    year = sample(2023:2024, 60, TRUE), q = sample(c("Q1", "Q2"), 60, TRUE))
  phw_group_table(dat, c("group", "type"), c("year", "q"), col_totals = c("group", "table"))
}

test_that("phw_gt styles data frames and summary tables", {
  skip_if_not_installed("gt")
  g <- phw_gt(head(mtcars[, 1:3]), caption = "Cars", number = 2, source = "mtcars")
  expect_s3_class(g, "gt_tbl")
  html <- as.character(gt::as_raw_html(g))
  expect_match(html, "Table 2 Cars")
  expect_match(html, "Source: mtcars")
  g2 <- phw_gt(make_grouped())
  html2 <- as.character(gt::as_raw_html(g2))
  expect_match(html2, "2023")
  expect_match(html2, "Group A")
})

test_that("use_phw_gtsummary sets a theme", {
  skip_if_not_installed("gtsummary")
  skip_if_not_installed("flextable")
  withr::defer(gtsummary::reset_gtsummary_theme())
  use_phw_gtsummary()
  tb <- gtsummary::tbl_summary(data.frame(a = c(1, 2, 3), g = c("x", "y", "x")), by = g)
  expect_s3_class(gtsummary::as_gt(tb), "gt_tbl")
  ft <- gtsummary::as_flex_table(tb)
  expect_equal(unname(ft$header$styles$text$color$data[1, 1]), phw_colours[["navy"]])
})

test_that("phw_datatable and phw_leaflet build widgets", {
  skip_if_not_installed("DT")
  w <- phw_datatable(mtcars, caption = "Cars", source = "mtcars")
  expect_s3_class(w, "shiny.tag.list")
  expect_s3_class(phw_datatable(mtcars), "datatables")
  skip_if_not_installed("leaflet")
  skip_if_not_installed("sf")
  sq <- sf::st_sf(name = c("a", "b"), v = c(1, 2),
                  geometry = sf::st_sfc(sf::st_polygon(list(rbind(c(-4, 52), c(-3, 52), c(-3, 53), c(-4, 52)))),
                                        sf::st_polygon(list(rbind(c(-4, 51), c(-3, 51), c(-3, 52), c(-4, 51)))),
                                        crs = 4326))
  m <- phw_leaflet() |> phw_leaflet_polygons(sq, fill = "v", label = "name")
  expect_s3_class(m, "leaflet")
  m2 <- phw_leaflet(tiles = NULL, view = NULL) |> phw_leaflet_polygons(sq, fill = "name", bins = NULL)
  expect_s3_class(m2, "leaflet")
  expect_type(phw_leaflet_palette("blues", domain = 1:10, type = "bin")(5), "character")
})

test_that("phw_write_xlsx writes styled sheets", {
  skip_if_not_installed("openxlsx2")
  f <- withr::local_tempfile(fileext = ".xlsx")
  phw_write_xlsx(list(Grouped = make_grouped(), Cars = head(mtcars)), f, title = "T", source = "S")
  expect_true(file.exists(f))
  expect_equal(openxlsx2::wb_load(f)$get_sheet_names()[[1]], "Grouped")
  d <- openxlsx2::read_xlsx(f, sheet = "Cars", rows = 3:9)
  expect_equal(names(d)[1], "mpg")
  expect_equal(d$mpg[1], 21)
})

test_that("phw_pptx builds a deck", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")
  deck <- phw_pptx()
  deck <- phw_add_slide(deck, "Text", text = c("a", "b"))
  deck <- phw_add_slide(deck, "Table", table = head(mtcars[, 1:3]), source = "mtcars")
  deck <- phw_add_slide(deck, "Plot", plot = ggplot2::ggplot(), editable = FALSE)
  f <- withr::local_tempfile(fileext = ".pptx")
  print(deck, target = f)
  expect_equal(length(deck), 3)
  expect_true(file.exists(f))
})
