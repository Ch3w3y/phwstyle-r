deck_xml <- function(deck, i = length(deck)) {
  f <- withr::local_tempfile(fileext = ".pptx")
  print(deck, target = f)
  dir <- withr::local_tempdir()
  utils::unzip(f, exdir = dir)
  xml2::read_xml(file.path(dir, "ppt", "slides", paste0("slide", i, ".xml")))
}

# Position and size in inches of each shape that holds a chart, picture,
# table or text body, in the order they were added.
slide_shapes <- function(deck, i = length(deck)) {
  xml <- deck_xml(deck, i)
  shapes <- xml2::xml_find_all(xml, "//p:spTree/*[p:nvSpPr or p:nvGraphicFramePr or p:nvPicPr]")
  inches <- function(node, path, attr) {
    as.numeric(xml2::xml_attr(xml2::xml_find_first(node, path), attr)) / 914400
  }
  data.frame(
    name = xml2::xml_attr(xml2::xml_find_first(shapes, "*[1]/p:cNvPr"), "name"),
    kind = xml2::xml_name(shapes),
    text = xml2::xml_text(shapes),
    x = inches(shapes, ".//a:off|.//p:xfrm/a:off", "x"),
    y = inches(shapes, ".//a:off|.//p:xfrm/a:off", "y"),
    width = inches(shapes, ".//a:ext[@cx]", "cx")
  )
}

test_slide_plot <- function() {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
}

test_that("a call that stops leaves the deck as it was", {
  skip_if_not_installed("officer")
  deck <- phw_pptx()
  expect_error(phw_add_slide(deck, "x", plot = test_slide_plot(), text = "a"), "one content area")
  expect_error(phw_add_slide(deck, "x", plot = test_slide_plot(), layout = "Section Header"))
  expect_error(phw_add_slide(deck, "x", text = "a", layout = "Blank"), "has no title")
  expect_length(deck, 0)
})

test_that("a failure after the slide is added removes that slide", {
  skip_if_not_installed("officer")
  deck <- phw_pptx()
  local_mocked_bindings(set_slide_alt = function(...) stop("boom"))
  expect_error(phw_add_slide(deck, "x", text = "a", alt = "Alt"), "boom")
  expect_length(deck, 0)
})

test_that("Title Only and Blank place the content below the title or on the whole slide", {
  skip_if_not_installed("officer")
  skip_if_not_installed("xml2")
  deck <- phw_add_slide(phw_pptx(), "Chart", plot = test_slide_plot(), layout = "Title Only",
                        editable = FALSE)
  shapes <- slide_shapes(deck)
  expect_equal(shapes$kind, c("sp", "pic"))
  expect_equal(shapes$y[2], 1.65, tolerance = 0.01)
  expect_equal(shapes$width[2], 12.133, tolerance = 0.01)

  deck <- phw_add_slide(phw_pptx(), table = head(mtcars[, 1:3]), layout = "Title Only")
  expect_equal(slide_shapes(deck)$kind, "graphicFrame")

  deck <- phw_add_slide(phw_pptx(), text = c("One", "Two"), layout = "Blank")
  shapes <- slide_shapes(deck)
  expect_equal(shapes$y, 0.4, tolerance = 0.01)
  expect_equal(shapes$text, "OneTwo")
  expect_length(xml2::xml_find_all(deck_xml(deck), "//a:buChar"), 2)
})

test_that("Two Content fills the left area first, and the second content goes right", {
  skip_if_not_installed("officer")
  skip_if_not_installed("xml2")
  one <- slide_shapes(phw_add_slide(phw_pptx(), "One", text = "Left", layout = "Two Content"))
  expect_equal(one$x[one$text == "Left"], 0.6, tolerance = 0.01)

  deck <- phw_add_slide(phw_pptx(), "Two", plot = test_slide_plot(), text = "Right",
                        layout = "Two Content", editable = FALSE, alt = "The chart")
  shapes <- slide_shapes(deck)
  expect_equal(shapes$x[shapes$kind == "pic"], 0.6, tolerance = 0.01)
  expect_equal(shapes$x[shapes$text == "Right"], 6.866, tolerance = 0.01)
  expect_equal(xml2::xml_attr(xml2::xml_find_all(deck_xml(deck), "//p:cNvPr[@descr]"), "descr"), "The chart")
})

test_that("a Comparison layout fills its content areas, not its headings", {
  skip_if_not_installed("officer")
  skip_if_not_installed("xml2")
  deck <- phw_pptx(system.file("template", "template.pptx", package = "officer"))
  deck <- phw_add_slide(deck, "Cmp", plot = test_slide_plot(), table = head(mtcars[, 1:3]),
                        layout = "Comparison", editable = FALSE)
  shapes <- slide_shapes(deck)
  expect_equal(shapes$x[shapes$kind == "pic"], 0.5, tolerance = 0.01)
  expect_equal(shapes$y[shapes$kind == "pic"], 2.378, tolerance = 0.01)
  expect_equal(shapes$x[shapes$kind == "graphicFrame"], 5.08, tolerance = 0.01)
  expect_equal(shapes$y[shapes$kind == "graphicFrame"], 2.378, tolerance = 0.01)
})

test_that("more contents than the layout has areas stops, naming them", {
  skip_if_not_installed("officer")
  p <- test_slide_plot()
  expect_error(phw_add_slide(phw_pptx(), "x", plot = p, table = mtcars, text = "a"),
               "one content area.*plot.*table.*text")
  expect_error(phw_add_slide(phw_pptx(), "x", plot = p, table = mtcars, text = "a", layout = "Two Content"),
               "2 content areas")
  expect_error(phw_add_slide(phw_pptx(), "x", plot = p, text = "a", layout = "Title Only"),
               "one content area")
})

test_that("Title Slide and Section Header refuse a chart or table", {
  skip_if_not_installed("officer")
  expect_error(phw_add_slide(phw_pptx(), "x", table = head(mtcars), layout = "Title Slide"),
               "Title and Content")
  expect_error(phw_add_slide(phw_pptx(), "x", plot = test_slide_plot(), layout = "Section Header"),
               "Title and Content")
})

test_that("text and source are readable on the title and section slides of any template", {
  skip_if_not_installed("officer")
  run_colour <- function(xml, text) {
    run <- xml2::xml_find_first(xml, sprintf("//a:r[a:t = '%s']", text))
    xml2::xml_attr(xml2::xml_find_first(run, "a:rPr/a:solidFill/a:srgbClr"), "val")
  }
  hex <- function(name) sub("#", "", phw_colours[[name]])
  light <- file.path(system.file(package = "officer"), "template", "template.pptx")
  for (layout in c("Title Slide", "Section Header")) {
    for (template in list(NULL, light)) {
      deck <- phw_add_slide(phw_pptx(template), "Title", text = "Subtitle line",
                            layout = layout, source = "S")
      xml <- deck_xml(deck)
      expect_identical(run_colour(xml, "Subtitle line"), NA_character_)
      expect_identical(run_colour(xml, "Source: S"), if (is.null(template)) "FFFFFF" else hex("text"))
    }
  }
})

test_that("title and section slide runs keep the PHW font and bold, and title_size when given", {
  skip_if_not_installed("officer")
  run_props <- function(xml, text) {
    rpr <- xml2::xml_find_first(xml, sprintf("//a:r[a:t = '%s']/a:rPr", text))
    font <- function(tag) xml2::xml_attr(xml2::xml_find_first(rpr, tag), "typeface")
    list(b = xml2::xml_attr(rpr, "b"), sz = xml2::xml_attr(rpr, "sz"),
         fonts = c(font("a:latin"), font("a:ea"), font("a:cs")))
  }
  light <- file.path(system.file(package = "officer"), "template", "template.pptx")
  for (layout in c("Title Slide", "Section Header")) {
    for (template in list(NULL, light)) {
      xml <- deck_xml(phw_add_slide(phw_pptx(template), "Title", text = "Subtitle line",
                                    layout = layout))
      expect_identical(run_props(xml, "Title"), list(b = "1", sz = NA_character_, fonts = rep(phw_font(), 3)))
      expect_identical(run_props(xml, "Subtitle line"), list(b = NA_character_, sz = NA_character_, fonts = rep(phw_font(), 3)))
      xml <- deck_xml(phw_add_slide(phw_pptx(template), "Title", text = "Subtitle line",
                                    layout = layout, title_size = 44))
      expect_identical(run_props(xml, "Title")$sz, "4400")
      expect_identical(run_props(xml, "Subtitle line")$sz, NA_character_)
    }
  }
})

test_that("a table too tall for the slide warns with how many rows fit", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")
  tall <- data.frame(n = 1:40, label = rep(letters, length.out = 40))
  expect_warning(phw_add_slide(phw_pptx(), "Tall", table = tall), "Only 23 of the table's 40 rows fit in the slide's content area")
  expect_no_warning(phw_add_slide(phw_pptx(), "Short", table = head(tall)))
})

test_that("a flextable's caption shows above the table on the slide", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")
  skip_if_not_installed("xml2")
  first_cells <- function(table) {
    xml <- deck_xml(phw_add_slide(phw_pptx(), "Cases", table = table))
    xml2::xml_text(xml2::xml_find_all(xml, "//a:tr/a:tc[1]"))
  }
  d <- data.frame(area = c("Cardiff", "Swansea"), cases = c(95, 75))
  ft <- phw_flextable(d, caption = "Cases by area, 2026", number = 1, source = "Example")
  expect_equal(first_cells(ft)[1:2], c("Table 1 Cases by area, 2026", "area"))
  expect_equal(first_cells(flextable::set_caption(flextable::flextable(d), "My caption"))[1], "My caption")
  expect_equal(first_cells(phw_flextable(d))[1], "area")
})

test_that("an empty table stops", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")
  expect_error(phw_add_slide(phw_pptx(), "x", table = mtcars[0, ]), "`table` has no rows")
  expect_error(phw_add_slide(phw_pptx(), "x", table = data.frame()), "`table` has no columns")
  expect_error(phw_add_slide(phw_pptx(), "x", table = flextable::flextable(mtcars[0, 1:2])), "no rows")
})

test_that("a table with bars stops, as PowerPoint tables cannot show them", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")
  deck <- phw_pptx()
  ft <- phw_flextable_bars(phw_flextable(data.frame(area = c("A", "B"), n = c(3, 5))), n)
  expect_error(phw_add_slide(deck, "x", table = ft), "cannot show images")
  expect_length(deck, 0)
})

test_that("a phw_finalise() chart goes on the slide as a picture", {
  skip_if_not_installed("officer")
  skip_if_not_installed("xml2")
  fp <- phw_finalise(test_slide_plot(), source = "mtcars", logo = FALSE)
  deck <- phw_add_slide(phw_pptx(), "Finalised", plot = fp, alt = "A chart")
  shapes <- slide_shapes(deck)
  expect_equal(shapes$kind[2], "pic")
  expect_equal(shapes$width[2], 12.133, tolerance = 0.01)
  expect_match(as.character(deck_xml(deck)), 'descr="A chart"', fixed = TRUE)
})

test_that("the deck, plot, table, text and flags are checked at entry", {
  skip_if_not_installed("officer")
  deck <- phw_pptx()
  expect_error(phw_add_slide(NULL, "x"), "must be a deck from `phw_pptx()`", fixed = TRUE)
  expect_error(phw_add_slide("deck.pptx", "x"), "must be a deck")
  expect_error(phw_add_slide(deck, "x", plot = "chart.png"), "`plot` must be a ggplot")
  expect_error(phw_add_slide(deck, "x", plot = structure(list(), class = "recordedplot")), "`plot` must be a ggplot")
  expect_error(phw_add_slide(deck, "x", table = as.matrix(mtcars)), "`table` must be a data frame")
  expect_error(phw_add_slide(deck, "x", text = NA), "`text` must be a character vector")
  expect_error(phw_add_slide(deck, "x", text = 1:3), "`text` must be a character vector")
  expect_error(phw_add_slide(deck, NA), "`title` must be a single string")
  expect_error(phw_add_slide(deck, c("a", "b")), "`title` must be a single string")
  expect_error(phw_add_slide(deck, "x", plot = test_slide_plot(), editable = NA), "`editable` must be `TRUE` or `FALSE`")
  expect_error(phw_add_slide(deck, "x", table = mtcars, table_fit = "yes"), "`table_fit`")
  expect_length(deck, 0)
})

test_that("an unknown master is named in the error", {
  skip_if_not_installed("officer")
  expect_error(phw_add_slide(phw_pptx(), "x", text = "a", master = "Nope"),
               "no slide layout called \"Title and Content\" in a master called \"Nope\"")
})

test_that("phw_pptx checks the template path", {
  skip_if_not_installed("officer")
  expect_error(phw_pptx(TRUE), "`template` must be a single string")
  expect_error(phw_pptx("no-such-deck.pptx"), "file not found")
})
