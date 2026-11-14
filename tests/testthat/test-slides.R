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

test_that("a table too tall for the slide warns with how many rows fit", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")
  tall <- data.frame(n = 1:40, label = rep(letters, length.out = 40))
  expect_warning(phw_add_slide(phw_pptx(), "Tall", table = tall), "Only 23 of the table's 40 rows fit in the slide's content area")
  expect_no_warning(phw_add_slide(phw_pptx(), "Short", table = head(tall)))
})

test_that("an empty table stops", {
  skip_if_not_installed("officer")
  skip_if_not_installed("flextable")
  expect_error(phw_add_slide(phw_pptx(), "x", table = mtcars[0, ]), "`table` has no rows")
  expect_error(phw_add_slide(phw_pptx(), "x", table = data.frame()), "`table` has no columns")
  expect_error(phw_add_slide(phw_pptx(), "x", table = flextable::flextable(mtcars[0, 1:2])), "no rows")
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
