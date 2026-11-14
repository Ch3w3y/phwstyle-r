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

slide_alt_texts <- function(deck, i) {
  f <- withr::local_tempfile(fileext = ".pptx")
  print(deck, target = f)
  dir <- withr::local_tempdir()
  utils::unzip(f, exdir = dir)
  xml <- paste(readLines(file.path(dir, "ppt", "slides", paste0("slide", i, ".xml")), warn = FALSE), collapse = "")
  regmatches(xml, gregexpr('descr="[^"]*"', xml))[[1]]
}

test_that("phw_add_slide writes alt text for charts and tables", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")
  skip_if_not_installed("rvg")
  skip_if_not_installed("xml2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  deck <- phw_pptx()
  deck <- phw_add_slide(deck, "Image", plot = p, editable = FALSE, alt = "Scatter of weight and mpg")
  deck <- phw_add_slide(deck, "Editable", plot = p, alt = "Editable scatter")
  deck <- phw_add_slide(deck, "Table", table = head(mtcars[, 1:3]), alt = "First rows of mtcars")
  deck <- phw_add_slide(deck, "None", plot = p, editable = FALSE)
  expect_true('descr="Scatter of weight and mpg"' %in% slide_alt_texts(deck, 1))
  expect_true('descr="Editable scatter"' %in% slide_alt_texts(deck, 2))
  expect_true('descr="First rows of mtcars"' %in% slide_alt_texts(deck, 3))
  expect_false(any(grepl("Scatter|Editable|First rows", slide_alt_texts(deck, 4))))
})

test_that("phw_add_slide passes caption_args to the source line", {
  skip_if_not_installed("officer")
  deck <- phw_add_slide(phw_pptx(), "Text", text = "a", source = "Survey", caption_args = list(note = "Provisional"))
  expect_match(officer::pptx_summary(deck)$text, "Provisional", all = FALSE)
})

test_that("a deck built with all defaults uses the PHW master and layouts", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  deck <- phw_pptx()
  deck <- phw_add_slide(deck, "Title", text = "Subtitle", layout = "Title Slide")
  deck <- phw_add_slide(deck, "Chart", plot = p, editable = FALSE, source = "mtcars")
  deck <- phw_add_slide(deck, "Table", table = head(mtcars[, 1:3]))
  deck <- phw_add_slide(deck, "Points", text = c("a", "b"))
  f <- withr::local_tempfile(fileext = ".pptx")
  print(deck, target = f)
  saved <- officer::read_pptx(f)
  expect_equal(length(saved), 4)
  expect_equal(unique(officer::layout_summary(saved)$master), "PHW")
  expect_setequal(officer::layout_summary(saved)$layout,
                  c("Title Slide", "Title and Content", "Section Header", "Two Content", "Title Only", "Blank"))
  expect_equal(unname(unlist(officer::slide_size(saved))), c(13.333, 7.5), tolerance = 1e-3)
  expect_equal(officer::pptx_summary(saved)$text[1], "Title")
})

test_that("phw_reference_pptx writes the template and stays small", {
  f <- phw_reference_pptx()
  expect_true(file.exists(f))
  expect_lt(file.size(f), 100 * 1024)
})
