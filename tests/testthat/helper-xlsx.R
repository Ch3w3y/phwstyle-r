# What Excel shows for each cell of one sheet of an .xlsx file: its value
# and its font, fill, borders, alignment and number format.
xlsx_cells <- function(file, sheet = 1) {
  dir <- withr::local_tempdir()
  utils::unzip(file, exdir = dir)
  read <- function(path) {
    x <- xml2::read_xml(file.path(dir, path))
    xml2::xml_ns_strip(x)
    x
  }
  st <- read("xl/styles.xml")
  fonts <- xml2::xml_find_all(st, "//fonts/font")
  fills <- xml2::xml_find_all(st, "//fills/fill")
  borders <- xml2::xml_find_all(st, "//borders/border")
  xfs <- xml2::xml_find_all(st, "//cellXfs/xf")
  fmts <- xml2::xml_find_all(st, "//numFmts/numFmt")
  fmt_code <- stats::setNames(xml2::xml_attr(fmts, "formatCode"), xml2::xml_attr(fmts, "numFmtId"))
  strings <- if (file.exists(file.path(dir, "xl/sharedStrings.xml"))) {
    vapply(xml2::xml_find_all(read("xl/sharedStrings.xml"), "//si"), xml2::xml_text, "")
  }
  attr_of <- function(node, path, a) xml2::xml_attr(xml2::xml_find_first(node, path), a)
  cells <- xml2::xml_find_all(read(sprintf("xl/worksheets/sheet%d.xml", sheet)), "//sheetData//c")
  out <- lapply(cells, function(cl) {
    xf <- xfs[[as.integer(xml2::xml_attr(cl, "s") %|% "0") + 1]]
    font <- fonts[[as.integer(xml2::xml_attr(xf, "fontId")) + 1]]
    fill <- fills[[as.integer(xml2::xml_attr(xf, "fillId")) + 1]]
    border <- borders[[as.integer(xml2::xml_attr(xf, "borderId")) + 1]]
    v <- xml2::xml_text(xml2::xml_find_first(cl, "v|is"))
    if (identical(xml2::xml_attr(cl, "t"), "s")) v <- strings[as.integer(v) + 1]
    fmt <- xml2::xml_attr(xf, "numFmtId")
    data.frame(
      ref = xml2::xml_attr(cl, "r"), value = v,
      bold = !is.na(xml2::xml_find_first(font, "b")),
      italic = !is.na(xml2::xml_find_first(font, "i")),
      colour = attr_of(font, "color", "rgb"),
      fill = attr_of(fill, ".//fgColor", "rgb"),
      top = attr_of(border, "top", "style"), top_colour = attr_of(border, "top/color", "rgb"),
      bottom = attr_of(border, "bottom", "style"), bottom_colour = attr_of(border, "bottom/color", "rgb"),
      align = attr_of(xf, "alignment", "horizontal"),
      format = if (fmt %in% names(fmt_code)) fmt_code[[fmt]] else fmt
    )
  })
  do.call(rbind, out)
}

`%|%` <- function(x, y) if (is.na(x)) y else x

xlsx_rgb <- function(colour) paste0("FF", toupper(sub("#", "", phw_colours[[colour]])))
