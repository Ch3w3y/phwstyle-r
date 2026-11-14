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

test_that("phw_datatable styles a phw_summary like the other renderers", {
  skip_if_not_installed("DT")
  d <- data.frame(label = c("Age", "0-14", "65+", "All"), n = c(NA, 12, 30, 42),
                  kind = c("variable", "level", "level", "total"))
  w <- phw_datatable(phw_as_summary(d, kind))
  expect_s3_class(w, "datatables")
  expect_equal(names(w$x$data), c("label", "n", ".phw_row_type", ".phw_depth"))
  expect_false(w$x$options$paging)
  expect_false(w$x$options$ordering)
  defs <- w$x$options$columnDefs
  hidden <- defs[[which(vapply(defs, function(d) isFALSE(d$visible), logical(1)))]]
  expect_equal(hidden$targets, c(2, 3))
  expect_equal(w$x$data$.phw_row_type, d$kind)
  expect_equal(w$x$data$.phw_depth, c(0, 1, 1, 0))
  styles <- as.character(w$x$options$rowCallback)
  expect_match(styles, '"variable" ? "700"', fixed = TRUE)
  expect_match(styles, '"total" ? "2px solid', fixed = TRUE)
  expect_match(styles, "padding-left':value == 1 ? \"22px\"", fixed = TRUE)
  plain <- phw_datatable(d)
  expect_null(plain$x$options$rowCallback)
  expect_equal(plain$x$options$pageLength, 10)
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

test_that("phw_add_slide finds the master that has the layout", {
  skip_if_not_installed("officer")
  masters <- function(deck) officer::layout_summary(deck)$master
  deck <- phw_add_slide(phw_pptx(), "Bundled", text = "a")
  expect_equal(length(deck), 1)
  expect_equal(unique(masters(deck)), "PHW")
  own <- officer::read_pptx()
  expect_equal(unique(masters(own)), "Office Theme")
  own <- phw_add_slide(own, "Own template", text = "a")
  expect_equal(length(own), 1)
})

test_that("phw_add_slide lists the layouts when the layout is unknown", {
  skip_if_not_installed("officer")
  expect_error(phw_add_slide(phw_pptx(), "x", layout = "Nope"), "Title and Content")
  expect_error(phw_add_slide(officer::read_pptx(), "x", layout = "Nope"), "no slide layout called")
})

test_that("slide titles are readable on dark and light layouts", {
  skip_if_not_installed("officer")
  deck <- phw_pptx()
  for (layout in c("Title Slide", "Section Header", "Title and Content")) {
    deck <- phw_add_slide(deck, "Headline", text = "Sub", layout = layout)
  }
  dir <- withr::local_tempdir()
  f <- file.path(dir, "deck.pptx")
  print(deck, target = f)
  utils::unzip(f, exdir = dir)
  title_fill <- function(path) {
    doc <- xml2::read_xml(file.path(dir, path))
    xml2::xml_attr(xml2::xml_find_all(
      doc, "//p:sp[.//p:ph[@type='title' or @type='ctrTitle']]//a:rPr/a:solidFill/a:srgbClr"), "val")
  }
  layout_default <- function(path) {
    doc <- xml2::read_xml(file.path(dir, path))
    xml2::xml_attr(xml2::xml_find_first(
      doc, "//p:sp[.//p:ph[@type='title' or @type='ctrTitle']]//a:defRPr/a:solidFill/a:srgbClr"), "val")
  }
  expect_length(title_fill("ppt/slides/slide1.xml"), 0)
  expect_length(title_fill("ppt/slides/slide2.xml"), 0)
  expect_equal(title_fill("ppt/slides/slide3.xml"), "285087")

  layouts <- officer::layout_summary(officer::read_pptx(f))
  for (name in c("Title Slide", "Section Header")) {
    n <- which(layouts$layout == name)
    expect_equal(layout_default(sprintf("ppt/slideLayouts/slideLayout%d.xml", n)), "FFFFFF")
  }
})

test_that("phw_add_slide uses a ggplot's own alt text on the editable path too", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")
  skip_if_not_installed("xml2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point() +
    ggplot2::labs(alt = "Heavier cars use more fuel")
  deck <- phw_add_slide(phw_pptx(), "Fuel", plot = p, editable = TRUE)
  f <- withr::local_tempfile(fileext = ".pptx")
  print(deck, target = f)
  dir <- withr::local_tempdir()
  utils::unzip(f, exdir = dir)
  xml <- paste(readLines(file.path(dir, "ppt", "slides", "slide1.xml"), warn = FALSE), collapse = "")
  expect_match(xml, 'descr="Heavier cars use more fuel"', fixed = TRUE)
})

slide_xml <- function(deck, i = 1) {
  f <- withr::local_tempfile(fileext = ".pptx")
  print(deck, target = f)
  dir <- withr::local_tempdir()
  utils::unzip(f, exdir = dir)
  paste(readLines(file.path(dir, "ppt", "slides", paste0("slide", i, ".xml")), warn = FALSE), collapse = "")
}

xml_numbers <- function(xml, pattern) {
  as.numeric(gsub("\\D", "", regmatches(xml, gregexpr(pattern, xml))[[1]]))
}

test_that("phw_add_slide enlarges chart text on the editable path", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point() + theme_phw()
  # Geom text follows plot_scale only from ggplot2 4.0, as the help page says.
  if (ggplot2_v4()) p <- p + ggplot2::geom_text(ggplot2::aes(label = cyl))
  sizes <- function(...) xml_numbers(slide_xml(phw_add_slide(phw_pptx(), "Chart", plot = p, ...)), 'sz="[0-9]+"')
  small <- setdiff(sizes(plot_scale = 1), 2800) / 100
  large <- setdiff(sizes(), 2800) / 100
  expect_equal(max(small), 9.9)
  expect_gte(sort(large)[2], 14)
  # Slide XML stores sizes in hundredths of a point.
  expect_lt(abs(max(large) - max(small) * 1.5), 0.011)
  expect_lt(abs(min(large) - min(small) * 1.5), 0.011)
})

test_that("phw_add_slide scales a plain ggplot and rejects a bad plot_scale", {
  skip_if_not_installed("officer")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  scaled <- scale_plot_text(p, 1.5)
  th <- ggplot2::theme_get() + scaled$theme
  expect_equal(ggplot2::calc_element("axis.text.x", th)$size, 0.8 * 11 * 1.5)
  expect_identical(scale_plot_text(p, 1), p)
  expect_error(phw_add_slide(phw_pptx(), "x", plot = p, plot_scale = 0), "plot_scale")
})

test_that("phw_add_slide scales the picture path the same way", {
  skip_if_not_installed("officer")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point() + theme_phw()
  deck <- phw_add_slide(phw_pptx(), "Chart", plot = p, editable = FALSE)
  expect_length(deck, 1)
  th <- ggplot2::theme_get() + scale_plot_text(p, 1.5)$theme
  expect_gte(ggplot2::calc_element("axis.text.x", th)$size, 14)
})

test_that("phw_add_slide fills the content area with a table", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")
  area <- 12.133
  widths <- function(table, ...) {
    xml <- slide_xml(phw_add_slide(phw_pptx(), "Table", table = table, ...))
    list(width = sum(xml_numbers(xml, '<a:gridCol w="[0-9]+"')) / 914400,
         size = max(setdiff(xml_numbers(xml, 'sz="[0-9]+"'), 2800)) / 100)
  }
  tab <- phw_summary_table(data.frame(age = rep(c("0-15", "16-64", "65+"), 2),
                                      sex = rep(c("Female", "Male"), each = 3)), by = sex)
  fitted <- widths(tab)
  plain <- widths(tab, table_fit = FALSE)
  expect_gt(fitted$width, 0.8 * area)
  expect_lte(fitted$width, area)
  expect_gt(fitted$size, plain$size)
  expect_lte(fitted$size, 16)
  expect_equal(plain$size, 10)
  narrow <- widths(data.frame(a = 1:3, b = 4:6))
  expect_lt(narrow$width, 0.3 * area)
  expect_lte(widths(head(mtcars, 25))$width, area + 0.001)
  own <- flextable::flextable(head(mtcars[, 1:3]))
  expect_equal(widths(own)$width, widths(own, table_fit = FALSE)$width)
})

test_that("phw_add_slide makes a tall table readable and keeps it inside the placeholder", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")
  area_width <- 12.133
  area_height <- 4.9
  set.seed(1)
  ops <- data.frame(category = sample(paste("Category", LETTERS[1:4]), 600, TRUE),
                    subgroup = sample(paste("Type", 1:3), 600, TRUE),
                    year = sample(2023:2024, 600, TRUE))
  grouped <- phw_group_table(ops, c(category, subgroup), year)
  expect_gte(nrow(grouped), 13)
  xml <- slide_xml(phw_add_slide(phw_pptx(), "Tall", table = grouped))
  sizes <- setdiff(xml_numbers(xml, 'sz="[0-9]+"'), 2800) / 100
  expect_gte(min(sizes), 12)
  expect_gte(sum(xml_numbers(xml, '<a:gridCol w="[0-9]+"')) / 914400, 0.7 * area_width)
  expect_lte(sum(xml_numbers(xml, '<a:tr h="[0-9]+"')) / 914400, area_height + 0.001)
  plain <- slide_xml(phw_add_slide(phw_pptx(), "Tall", table = grouped, table_fit = FALSE))
  expect_gt(sum(xml_numbers(plain, '<a:tr h="[0-9]+"')) / 914400, area_height)
})
