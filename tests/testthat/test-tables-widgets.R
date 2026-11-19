test_that("phw_flextable styles a table in every style", {
  skip_if_not_installed("flextable")
  df <- data.frame(Area = c("A", "B", "Total"), Cases = c(1200L, 30L, 1230L), Rate = c(1.25, 3.5, 2.1))
  for (s in c("booktabs", "header", "light", "zebra")) {
    ft <- phw_flextable(df, caption = "Example", source = "Test", style = s, total_row = TRUE)
    expect_s3_class(ft, "flextable")
  }
  ft <- phw_flextable(df, caption = "Example", number = 2, number_prefix = "Tabl",
                      caption_args = list(note = "Provisional"), accent = "#24A2B5",
                      padding = 2, header_bg = "#F0F4F5")
  expect_s3_class(ft, "flextable")
  expect_s3_class(phw_flextable_heat(ft, j = "Rate"), "flextable")
  expect_s3_class(phw_flextable_heat(ft, j = "Rate", palette = c("#FFFFFF", "#285087")), "flextable")
  rag <- phw_flextable_heat(ft, j = "Rate", palette = "rag", breaks = c(2, 3))
  # Checked in the rendered table, which every flextable version can make.
  expect_match(as.character(flextable::htmltools_value(rag)), "\u25BC")
  grp <- phw_flextable_groups(ft, j = "Area", values = c(A = "#000000"))
  expect_s3_class(grp, "flextable")
})

test_that("reactable and plotly helpers return widgets", {
  skip_if_not_installed("reactable")
  skip_if_not_installed("plotly")
  expect_s3_class(phw_reactable(head(mtcars)), "htmlwidget")
  expect_s3_class(phw_reactable(head(mtcars), caption = "x", source = "y"), "shiny.tag.list")
  df <- data.frame(g = c("A", "B"), n = 1:2)
  expect_s3_class(phw_reactable(df, group_col = "g", theme = phw_reactable_theme(accent = "#000000")), "htmlwidget")
  library(ggplot2)
  p <- ggplot(mpg, aes(displ, hwy, colour = drv)) + geom_point()
  w <- phw_plotly(p, source = "mpg")
  expect_s3_class(w, "plotly")
  built <- plotly::plotly_build(w)
  cols <- unlist(lapply(built$x$data, function(t) t$marker$color))
  expect_true(any(grepl("40,80,135", gsub(" ", "", cols))))
  w2 <- phw_plotly(plotly::plot_ly(), palette = "accessible", modebar = FALSE, font = list(size = 20))
  expect_equal(w2$x$layoutAttrs[[1]]$font$size, 20)
  expect_match(w2$x$layoutAttrs[[1]]$font$family, "Ubuntu")
})

test_that("every PHW widget brings the Ubuntu web font into the saved page", {
  skip_if_not_installed("reactable")
  skip_if_not_installed("plotly")
  skip_if_not_installed("DT")
  df <- data.frame(group = c("B", "A"), n = 1:2)
  p <- plotly::plot_ly(df, x = ~group, y = ~n, type = "bar")
  font_refs <- function(x) {
    f <- withr::local_tempfile(fileext = ".html")
    htmltools::save_html(x, f)
    sum(grepl("phw-ubuntu", readLines(f)))
  }
  widgets <- list(reactable = phw_reactable(df), plotly = phw_plotly(p),
                  plotly_source = phw_plotly(p, source = "S"), datatable = phw_datatable(df))
  for (nm in names(widgets)) expect_gt(font_refs(widgets[[nm]]), 0, label = nm)
})

test_that("Shiny theme and header build", {
  skip_if_not_installed("bslib")
  expect_s3_class(phw_bs_theme(), "bs_theme")
  expect_s3_class(phw_bs_theme(primary = "#24A2B5"), "bs_theme")
  expect_s3_class(phw_header("App"), "shiny.tag.list")
})

test_that("phw_page_navbar builds a navy navbar on every bslib", {
  skip_if_not_installed("bslib")
  # bslib 0.9.0 moved the navbar colours into navbar_options(); older
  # versions take them as arguments of page_navbar().
  page <- phw_page_navbar(bslib::nav_panel("One", "Content"), title = "App", subtitle = "Team")
  html <- htmltools::renderTags(page)$html
  expect_match(html, "phw-header")
  expect_match(html, "navbar")
  expect_match(html, phw_colours[["navy"]], ignore.case = TRUE)
  expect_match(html, phw_org, fixed = TRUE)
})

reactable_formats <- function(w) {
  cols <- w$x$tag$attribs$columns
  stats::setNames(lapply(cols, function(cd) cd$format$cell$digits), vapply(cols, function(cd) cd$id, ""))
}

test_that("phw_reactable rounds numbers like phw_flextable and phw_gt", {
  skip_if_not_installed("reactable")
  df <- data.frame(area = c("A", "B", "C"), cases = c(10, 20, 30), rate = c(1.5, 2.25, 3))
  fmt <- reactable_formats(phw_reactable(df))
  expect_equal(fmt$cases, 0)
  expect_equal(fmt$rate, 1)
  expect_equal(reactable_formats(phw_reactable(df, digits = 2))$rate, 2)
  own <- reactable::colDef(format = reactable::colFormat(digits = 3))
  expect_equal(reactable_formats(phw_reactable(df, columns = list(rate = own)))$rate, 3)
  sm <- new_phw_summary(data.frame(label = c("X", "Y", "Z"), n = c(10, 20, 30), rate = c(1.5, 2.25, 3)),
                         row_type = rep("level", 3))
  fmt <- reactable_formats(phw_reactable(sm))
  expect_equal(fmt$rate, 1)
  expect_equal(fmt$n, 0)
  own_default <- reactable::colDef(format = reactable::colFormat(digits = 2))
  fmt <- reactable_formats(phw_reactable(df, defaultColDef = own_default))
  expect_equal(fmt$rate, 2)
  expect_equal(fmt$cases, 2)
  fmt <- reactable_formats(phw_reactable(df, defaultColDef = own_default, columns = list(rate = own)))
  expect_equal(fmt$rate, 3)
  expect_equal(fmt$cases, 2)
})

test_that("phw_reactable merges your columns into a summary table's own", {
  skip_if_not_installed("reactable")
  x <- phw_group_table(data.frame(g = c("A", "A", "B"), t = c("1", "2", "1")), c(g, t))
  cols <- function(w) stats::setNames(w$x$tag$attribs$columns, names(x))
  plain <- cols(phw_reactable(x))
  mine <- cols(phw_reactable(x, columns = list(n = phw_col_bar(x, n))))
  expect_equal(mine[[1]]$style, plain[[1]]$style)
  expect_equal(mine[[1]]$minWidth, plain[[1]]$minWidth)
  expect_equal(mine$n[["na"]], "")
  expect_equal(mine$n[["name"]], plain$n[["name"]])
  expect_equal(mine$n$align, "left")
  expect_false(is.null(mine$n$cell))
})

# One grouped table drawn by every renderer, for the shading tests.
make_groups <- function(...) {
  d <- data.frame(group = rep(c("Group A", "Group B"), each = 4),
                  type = rep(c("Type 1", "Type 2"), 4), year = rep(2023:2024, each = 2, times = 2))
  phw_group_table(d, c(group, type), cols = year, ...)
}

test_that("every renderer shades variable rows unless highlight = FALSE", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("gt")
  skip_if_not_installed("reactable")
  skip_if_not_installed("DT")
  skip_if_not_installed("openxlsx2")
  grey <- phw_colours[["grey_bg"]]
  shaded <- function(tab) {
    ft <- phw_flextable(tab)
    xl <- withr::local_tempfile(fileext = ".xlsx")
    phw_write_xlsx(tab, xl)
    cells <- xlsx_cells(xl)
    rt <- phw_reactable(tab)
    c(flextable = ft$body$styles$cells$background.color$data[1, 1] == grey,
      gt = grepl(grey, gt::as_raw_html(phw_gt(tab)), ignore.case = TRUE),
      reactable = identical(rt$x$tag$attribs$rowStyle[[1]]$background, grey),
      DT = grepl(grey, as.character(phw_datatable(tab)$x$options$rowCallback), fixed = TRUE),
      xlsx = identical(cells$fill[cells$ref == "A3"], xlsx_rgb("grey_bg")))
  }
  expect_true(all(shaded(make_groups())))
  expect_false(any(shaded(make_groups(highlight = FALSE))))
  ll <- data.frame(sex = c("F", "M"), g = c("a", "b"))
  expect_equal(unname(phw_flextable(phw_summary_table(ll, by = g))$body$styles$cells$background.color$data[1, 1]), grey)
})

test_that("phw_datatable draws the spanner, column levels, group lines and right-aligned statistics", {
  skip_if_not_installed("DT")
  w <- phw_datatable(make_groups(separate = "line", labels = list(year = "Year")))
  head <- as.character(w$x$container)
  expect_match(head, '<th colspan="3" class="phw-spanner">Year</th>', fixed = TRUE)
  styles <- as.character(w$x$options$rowCallback)
  expect_match(styles, "'color':value == 1 ? \"#285087\" : value == 4 ? \"#285087\"", fixed = TRUE)
  expect_match(styles, "value == 4 ? \"1px solid #768692\"", fixed = TRUE)
  right <- Filter(function(d) identical(d$className, "dt-right"), w$x$options$columnDefs)[[1]]
  expect_equal(right$targets, 1:3)

  q <- data.frame(g = c("A", "A", "B"), t = c("1", "2", "1"), y = c(2023, 2023, 2024), q = c("Q1", "Q2", "Q1"))
  head2 <- as.character(phw_datatable(phw_group_table(q, c(g, t), cols = c(y, q)))$x$container)
  expect_match(head2, '<th colspan="2" class="phw-spanner">2023</th>', fixed = TRUE)
  expect_match(head2, "<th>Q1</th>", fixed = TRUE)
  expect_no_match(head2, "2023 / Q1", fixed = TRUE)
  expect_match(as.character(phw_dt_css()$head), "font-size: 14px", fixed = TRUE)
})

test_that("phw_datatable keeps your columnDefs for a summary table", {
  skip_if_not_installed("DT")
  mine <- list(width = "200px", targets = 1)
  w <- phw_datatable(make_groups(), options = list(columnDefs = list(mine)))
  defs <- w$x$options$columnDefs
  at <- function(keep) which(vapply(defs, keep, logical(1)))
  hide <- at(function(d) isFALSE(d$visible))
  expect_lt(at(function(d) identical(d, mine)), hide)
  hidden <- defs[[hide]]
  expect_equal(names(w$x$data)[hidden$targets + 1], ".phw_row")
})

test_that("phw_flextable's source line is bold and not italic under a summary note", {
  skip_if_not_installed("flextable")
  ft <- phw_flextable(phw_summary_table(data.frame(a = c("x", "y"))), source = "Probe")
  expect_equal(ft$footer$styles$text$italic$data[, 1], c(TRUE, FALSE))
  expect_equal(ft$footer$styles$text$bold$data[, 1], c(FALSE, TRUE))
})

test_that("phw_reactable is unstriped, closed with a navy rule and has a navy spanner", {
  skip_if_not_installed("reactable")
  rt <- phw_reactable(data.frame(a = 1:3))
  expect_false(isTRUE(rt$x$tag$attribs$striped))
  theme <- phw_reactable_theme()
  expect_equal(theme$tableStyle$borderBottom, paste("2px solid", phw_colours[["navy"]]))
  expect_equal(theme$groupHeaderStyle$color, phw_colours[["navy"]])
})

test_that("phw_reactable's booktabs top rule sits above the column groups", {
  skip_if_not_installed("reactable")
  rule <- paste("2px solid", phw_colours[["navy"]])
  theme <- phw_reactable_theme()
  expect_equal(theme$tableStyle$borderTop, rule)
  expect_null(theme$headerStyle$borderTop)
  expect_null(theme$groupHeaderStyle$borderTop)
  expect_null(phw_reactable_theme(header = "navy")$tableStyle$borderTop)
})

test_that("phw_reactable and phw_datatable show a summary note above the source, not in it", {
  skip_if_not_installed("reactable")
  skip_if_not_installed("DT")
  tab <- phw_summary_table(data.frame(a = c("x", "y")))
  for (w in list(phw_reactable(tab, source = "Probe"), phw_datatable(tab, source = "Probe"))) {
    html <- as.character(w)
    expect_match(html, "n (%)</div>", fixed = TRUE)
    expect_match(html, ">Source: Probe</div>", fixed = TRUE)
    expect_lt(regexpr("n (%)", html, fixed = TRUE), regexpr("Source: Probe", html, fixed = TRUE))
  }
})

test_that("phw_write_xlsx draws the house look on summary tables", {
  skip_if_not_installed("openxlsx2")
  f <- withr::local_tempfile(fileext = ".xlsx")
  phw_write_xlsx(make_groups(subtotal_position = "below", labels = list(year = "Year")), f, source = "Probe")
  cells <- xlsx_cells(f)
  cell <- function(v) cells[which(cells$value == v)[1], ]
  expect_true(cell("Year")$bold)
  expect_equal(cell("Year")$colour, xlsx_rgb("navy"))
  expect_equal(cell("Group A")$colour, xlsx_rgb("navy"))
  expect_true(cell("Group A total")$italic)
  total_row <- as.integer(sub("A", "", cells$ref[cells$value %in% "Total" & grepl("^A", cells$ref)]))
  above_total <- cells[cells$ref == paste0("A", total_row - 1), ]
  expect_equal(above_total$bottom, "medium")
  expect_equal(above_total$bottom_colour, xlsx_rgb("navy"))
  expect_true(cell("Source: Probe")$bold)
  expect_equal(cell("Source: Probe")$align, "right")
})

test_that("every renderer shows years without a thousands separator", {
  df <- data.frame(Year = 2021:2022, year_of_onset = c(2019, NA), Cases = c(1520, 2021))
  skip_if_not_installed("flextable")
  html <- as.character(flextable::htmltools_value(phw_flextable(df)))
  expect_match(html, ">2021<")
  expect_match(html, ">2019<")
  expect_match(html, ">1,520<")
  expect_match(html, ">2,021<")
  skip_if_not_installed("gt")
  html <- as.character(gt::as_raw_html(phw_gt(df)))
  expect_match(html, ">2021<")
  expect_match(html, ">2019<")
  expect_match(html, ">1,520<")
  skip_if_not_installed("reactable")
  cols <- phw_reactable(df)$x$tag$attribs$columns
  expect_equal(vapply(cols, function(c) isTRUE(c$format$cell$separators), TRUE), c(FALSE, FALSE, TRUE))
  skip_if_not_installed("DT")
  defs <- Filter(function(d) !is.null(d$render), phw_datatable(df)$x$options$columnDefs)
  marks <- vapply(defs, function(d) sub('.*formatRound\\(data, 0, 3, "(.?)".*', "\\1", d$render), "")
  expect_equal(marks[order(vapply(defs, function(d) d$targets, numeric(1)))], c("", "", ","))
  skip_if_not_installed("openxlsx2")
  f <- withr::local_tempfile(fileext = ".xlsx")
  phw_write_xlsx(df, f)
  cells <- xlsx_cells(f)
  expect_equal(cells$format[cells$ref %in% c("A2", "B2", "C2")], c("0", "0", "#,##0"))
})

test_that("phw_write_xlsx writes a missing summary row label as an empty cell", {
  skip_if_not_installed("openxlsx2")
  f <- withr::local_tempfile(fileext = ".xlsx")
  phw_write_xlsx(phw_as_summary(data.frame(lab = c("A", NA), n = 1:2)), f)
  got <- openxlsx2::read_xlsx(f, col_names = FALSE)
  expect_equal(got[[1]], c("lab", "    A", NA))
})

test_that("phw_write_xlsx writes dates in ISO format", {
  skip_if_not_installed("openxlsx2")
  f <- withr::local_tempfile(fileext = ".xlsx")
  phw_write_xlsx(data.frame(d = as.Date("2026-01-01")), f)
  expect_equal(xlsx_cells(f)$format[2], "yyyy-mm-dd")
})

test_that("phw_write_xlsx checks what it is given before writing", {
  skip_if_not_installed("openxlsx2")
  f <- withr::local_tempfile(fileext = ".xlsx")
  expect_error(phw_write_xlsx(1:3, f), "must be a data frame or a list of data frames")
  expect_error(phw_write_xlsx(list(a = mtcars, b = 1:3), f), "integer vector")
  expect_false(file.exists(f))
  phw_write_xlsx(list(a = head(mtcars), head(iris)), f, header_fill = "teal")
  expect_equal(openxlsx2::wb_load(f)$get_sheet_names(), c(a = "a", Sheet2 = "Sheet2"))
  expect_equal(xlsx_cells(f)$fill[1], xlsx_rgb("teal"))
  expect_error(phw_write_xlsx(mtcars, f, header_fill = "nope"), "header_fill")
})

test_that("phw_write_xlsx checks the file and the titles before writing", {
  skip_if_not_installed("openxlsx2")
  dir <- withr::local_tempdir()
  expect_error(phw_write_xlsx(mtcars, file.path(dir, "nofolder", "x.xlsx")), "folder not found")
  expect_error(phw_write_xlsx(mtcars, file.path(dir, "x.xls")), "must end in .*\\.xlsx")
  f <- file.path(dir, "x.xlsx")
  three <- list(a = head(iris), b = head(mtcars), c = head(cars))
  expect_error(phw_write_xlsx(three, f, title = c("Iris", "Cars")), "2 titles for 3 sheets")
  expect_error(phw_write_xlsx(head(iris), f, title = c("Iris", "Cars")), "2 titles for 1 sheet")
  expect_false(file.exists(f))
  phw_write_xlsx(three, f, title = c("Iris", "Mtcars", "Cars"))
  expect_equal(vapply(1:3, function(i) xlsx_cells(f, i)$value[1], ""), c("Iris", "Mtcars", "Cars"))
  phw_write_xlsx(three, f, title = "Same")
  expect_equal(xlsx_cells(f, 3)$value[1], "Same")
})

test_that("phw_write_xlsx stops on sheet names Excel would treat as the same", {
  skip_if_not_installed("openxlsx2")
  f <- withr::local_tempfile(fileext = ".xlsx")
  one <- data.frame(a = 1)
  expect_error(phw_write_xlsx(list("North/South" = one, "North?South" = one), f),
               "North/South.*North\\?South.*North South")
  expect_error(phw_write_xlsx(list(Cases = one, cases = one), f), "Cases.*cases")
  expect_error(phw_write_xlsx(list(one, sheet1 = one), f), "Sheet1.*sheet1")
  long <- strrep("x", 31)
  expect_error(phw_write_xlsx(setNames(list(one, one), paste0(long, 1:2)), f), "31 characters")
  expect_false(file.exists(f))
  phw_write_xlsx(list("North/South" = data.frame(area = c("N1", "N2")), "North-South" = data.frame(area = "S1")), f)
  expect_equal(unname(openxlsx2::wb_load(f)$get_sheet_names()), c("North South", "North-South"))
  expect_equal(openxlsx2::read_xlsx(f, sheet = 1)$area, c("N1", "N2"))
  expect_equal(openxlsx2::read_xlsx(f, sheet = 2)$area, "S1")
})

test_that("phw_gt carries the Ubuntu web font and italic subtotals, and left-aligns dates", {
  skip_if_not_installed("gt")
  g <- phw_gt(data.frame(d = as.Date("2026-01-01"), n = 1)) |> gt::tab_header("Title")
  deps <- htmltools::findDependencies(htmltools::as.tags(g))
  expect_true("phw-ubuntu-font" %in% vapply(deps, `[[`, "", "name"))
  expect_match(gt::as_raw_html(g, inline_css = FALSE), 'gt_row gt_left">2026-01-01', fixed = TRUE)
  html <- gt::as_raw_html(phw_gt(make_groups(subtotal_position = "below")))
  expect_match(html, "font-style: italic;[^>]*>Group A total", perl = TRUE)
})

test_that("phw_gt_theme(...) replaces a PHW setting", {
  skip_if_not_installed("gt")
  css <- function(g) gt::as_raw_html(g, inline_css = FALSE)
  g <- gt::tab_header(gt::gt(head(iris)), "Iris")
  expect_match(css(phw_gt_theme(g)), "\\.gt_heading \\{[^}]*text-align: left;")
  expect_match(css(phw_gt_theme(g, heading.align = "center")), "\\.gt_heading \\{[^}]*text-align: center;")
  g <- phw_gt(head(iris), theme_args = list(data_row.padding = gt::px(2)))
  expect_match(css(g), "\\.gt_row \\{[^}]*padding-top: 2px;")
})

test_that("phw_gt takes a summary table's column names in gt_args", {
  skip_if_not_installed("gt")
  s <- phw_summary_table(data.frame(age = c("0-14", "15-44", "0-14")))
  html <- gt::as_raw_html(phw_gt(s, gt_args = list(rowname_col = "Characteristic")))
  expect_match(html, "gt_stub[^>]*text-indent: 14px;[^>]*>0-14<", perl = TRUE)
  expect_match(html, "color: #285087;[^>]*>Characteristic<", perl = TRUE)
  expect_error(phw_gt(make_groups(layout = "columns"), gt_args = list(groupname_col = "group")),
               "groupname_col.*does not work on a summary table")
  expect_error(phw_gt(s, gt_args = list(rowname_col = "characteristic")),
               "No column called \"characteristic\".*\"Characteristic\" and \"All \\(n = 3\\)\"")
})

test_that("later gt steps find a summary table's columns by name", {
  skip_if_not_installed("gt")
  html <- function(g) gt::as_raw_html(g, inline_css = FALSE)
  ll <- data.frame(hb = c("Cardiff", "Swansea", "Cardiff", "Powys"),
                   sex = c("Male", "Female", "Female", "Male"))
  s <- phw_summary_table(ll, by = sex)
  g <- phw_gt(s) |>
    gt::cols_width(Characteristic ~ gt::px(200)) |>
    gt::cols_label(`Total (n = 4)` = "All Wales")
  expect_match(html(g), "width:200px")
  expect_match(html(g), ">All Wales<")
  ct <- phw_gt(phw_crosstab(ll, hb, sex)) |> gt::cols_hide(Total)
  expect_match(html(ct), "headers=\"Female\"")
  expect_no_match(html(ct), "headers=\"Total\"")
})

test_that("phw_gt keeps a spanner whose label is also a column name", {
  skip_if_not_installed("gt")
  d <- data.frame(hb = c("Cardiff", "Swansea", "Cardiff"), smoker = c("smoker", "non-smoker", "smoker"))
  html <- gt::as_raw_html(phw_gt(phw_crosstab(d, hb, smoker)), inline_css = FALSE)
  expect_match(html, "gt_column_spanner[^>]*>smoker<", perl = TRUE)
  expect_match(html, "headers=\"smoker\"")
})

test_that("use_phw_flextable() styles are not carried into another style", {
  skip_if_not_installed("flextable")
  old <- use_phw_flextable(style = "zebra")
  on.exit(do.call(flextable::set_flextable_defaults, old))
  ft <- phw_flextable(head(airquality), style = "header")
  expect_true(all(ft$body$styles$cells$background.color$data == "transparent"))
})

test_that("phw_flextable spanners take the header's colours", {
  skip_if_not_installed("flextable")
  set.seed(1)
  ll <- data.frame(group = sample(c("A", "B"), 40, TRUE), area = sample(c("X", "Y"), 40, TRUE),
                   year = sample(2023:2024, 40, TRUE), quarter = sample(c("Q1", "Q2"), 40, TRUE))
  spanner <- function(ft) {
    h <- ft$header$styles
    list(text = unique(h$text$color$data[1, -1]), rule = unique(h$cells$border.color.bottom$data[1, -1]))
  }
  tabs <- list(phw_summary_table(ll, by = group), phw_crosstab(ll, area, group),
               phw_group_table(ll, area, cols = c(year, quarter)))
  for (tab in tabs) {
    expect_equal(spanner(phw_flextable(tab, style = "header")), list(text = "#FFFFFF", rule = "#FFFFFF"))
    expect_equal(spanner(phw_flextable(tab))$text, phw_colours[["navy"]])
  }
  expect_equal(spanner(phw_flextable(tabs[[1]], accent = "#AA0000"))$text, "#AA0000")
})

test_that("phw_flextable draws no rule over the label column inside a spanner header", {
  skip_if_not_installed("flextable")
  set.seed(1)
  ll <- data.frame(group = sample(c("A", "B"), 40, TRUE), area = sample(c("X", "Y"), 40, TRUE),
                   year = sample(2023:2024, 40, TRUE), quarter = sample(c("Q1", "Q2"), 40, TRUE))
  tabs <- list(phw_crosstab(ll, area, group), phw_group_table(ll, area, cols = c(year, quarter)))
  for (tab in tabs) {
    for (style in c("booktabs", "light")) {
      cells <- phw_flextable(tab, style = style)$header$styles$cells
      n <- nrow(cells$border.width.top$data)
      expect_equal(unname(cells$border.width.bottom$data[-n, 1]), rep(0, n - 1))
      expect_equal(unname(cells$border.width.top$data[-1, 1]), rep(0, n - 1))
    }
    top <- phw_flextable(tab)$header$styles$cells
    expect_equal(unique(top$border.color.top$data[1, ]), phw_colours[["navy"]])
  }
})

test_that("a column added to a summary table has no upper header in any renderer", {
  skip_if_not_installed("dplyr")
  set.seed(1)
  ll <- data.frame(area = sample(c("X", "Y"), 40, TRUE), year = sample(2023:2024, 40, TRUE),
                   quarter = sample(c("Q1", "Q2"), 40, TRUE))
  tabs <- list(phw_crosstab(ll, area, year), phw_group_table(ll, area, cols = c(year, quarter)))
  for (tab in tabs) {
    assigned <- tab
    assigned$change <- 1
    for (x in list(assigned, dplyr::mutate(tab, change = 1))) {
      n <- ncol(x)
      if (requireNamespace("gt", quietly = TRUE)) {
        g <- phw_gt(x)
        expect_false(paste0("c", n) %in% unlist(g[["_spanners"]]$vars))
        expect_equal(g[["_boxhead"]]$column_label[[n]], "change")
      }
      if (requireNamespace("flextable", quietly = TRUE)) {
        h <- phw_flextable(x)$header
        expect_equal(h$dataset[-nrow(h$dataset), n], rep("", nrow(h$dataset) - 1))
        expect_equal(h$dataset[nrow(h$dataset), n], "change")
        expect_equal(unname(h$styles$cells$border.width.bottom$data[-nrow(h$dataset), n]), rep(0, nrow(h$dataset) - 1))
      }
      if (requireNamespace("reactable", quietly = TRUE)) {
        groups <- phw_reactable(x)$x$tag$attribs$columnGroups
        last <- Filter(function(gr) "change" %in% gr$columns, groups)[[1]]
        expect_equal(last$name, "")
      }
      if (requireNamespace("DT", quietly = TRUE)) {
        head <- as.character(phw_datatable(x)$x$container)
        expect_match(head, '<th colspan="1" class="phw-blank"></th>', fixed = TRUE)
        expect_match(head, "<th>change</th>", fixed = TRUE)
      }
      if (requireNamespace("openxlsx2", quietly = TRUE)) {
        f <- withr::local_tempfile(fileext = ".xlsx")
        phw_write_xlsx(x, f)
        cells <- openxlsx2::read_xlsx(f, col_names = FALSE, skip_empty_rows = FALSE)
        expect_equal(cells[[n]][length(cells[[n]]) - nrow(x)], "change")
        expect_true(all(is.na(cells[[n]][seq_len(length(cells[[n]]) - nrow(x) - 1)])))
      }
    }
  }
})

test_that("theme styles are checked when they are set", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("gtsummary")
  expect_error(use_phw_flextable(style = "nope"), "must be one of")
  expect_error(use_phw_gtsummary(style = "nope"), "must be one of")
})

test_that("phw_flextable works on one row with a total and with a subset of columns", {
  skip_if_not_installed("flextable")
  expect_s3_class(phw_flextable(data.frame(a = "x", n = 1), total_row = TRUE), "flextable")
  area <- data.frame(area = c("A", "B"), cases = c(10, 20), rate = c(1.5, 2.5))
  ft <- phw_flextable(area, flextable_args = list(col_keys = c("area", "rate")))
  expect_equal(ft$col_keys, c("area", "rate"))
})

test_that("RAG symbols keep the table's number format", {
  skip_if_not_installed("flextable")
  df <- data.frame(Area = c("A", "B", "C"), Uptake = c(92.345678, 95.1, NA), Cases = c(1234, 95, 10))
  ft <- phw_flextable(df, digits = 1) |>
    phw_flextable_heat(Uptake, palette = "rag", breaks = c(93, 95)) |>
    phw_flextable_heat(Cases, palette = "rag", breaks = c(100, 1000))
  html <- as.character(flextable::htmltools_value(ft))
  expect_match(html, "\u25BC\\s*</span>.*?92\\.3<")
  expect_match(html, "\u25B2\\s*</span>.*?1,234<")
  expect_no_match(html, "92\\.34|95\\.10")
})

test_that("col_keys drops columns from a summary table", {
  skip_if_not_installed("flextable")
  rt <- phw_rate_table(data.frame(a = c("x", "y"), cases = c(1, 2), pop = c(100, 100)), a, cases, pop)
  ft <- phw_flextable(rt, flextable_args = list(col_keys = c("Group", "Cases")))
  expect_equal(ft$col_keys, c("Group", "Cases"))
  ct <- phw_crosstab(mtcars, cyl, gear)
  ft <- phw_flextable(ct, flextable_args = list(col_keys = c("cyl", "4", "3")))
  expect_equal(ft$header$spans$rows[1, ], c(1, 2, 0))
  dat <- expand.grid(group = c("A", "B"), year = c(2024, 2025), q = c("Q1", "Q2"))
  grouped <- phw_group_table(dat, group, c(year, q))
  ft <- phw_flextable(grouped, flextable_args = list(col_keys = names(grouped)[c(1, 2, 3, 6)]))
  expect_equal(ft$header$spans$rows[1, ], c(1, 2, 0, 1))
  ft <- phw_flextable(grouped, flextable_args = list(col_keys = "group"))
  expect_equal(flextable::nrow_part(ft, "header"), 1)
  expect_error(phw_flextable(rt, flextable_args = list(col_keys = c("Cases", "Group"))),
               "must start with the label column")
  expect_error(phw_flextable(rt, flextable_args = list(col_keys = c("Group", "Nope"))),
               "must name columns of the summary table")
})

test_that("flextable colouring helpers check their table and columns", {
  skip_if_not_installed("flextable")
  v <- data.frame(a = c("x", "y"), n = c(NA, NA), m = c(1, 3), neg = c(-5, 2))
  ft <- phw_flextable(v)
  expect_error(phw_flextable_heat(v, m), "must be a flextable")
  expect_error(phw_flextable_bars(v, m), "must be a flextable")
  expect_error(phw_flextable_groups(v, a), "must be a flextable")
  expect_error(phw_flextable_heat(ft, a), "must be a numeric column")
  expect_error(phw_flextable_heat(ft, m, palette = "rag", breaks = 1), "must be two numbers")
  expect_message(phw_flextable_heat(ft, n), "has no values")
  expect_message(phw_flextable_bars(ft, n), "has no values")
  expect_message(phw_flextable_heat(phw_flextable(v[0, ]), m), "has no values")
  expect_error(phw_flextable_bars(ft, neg), "negative values")
})

test_that("reactable column helpers check their values", {
  skip_if_not_installed("reactable")
  v <- data.frame(n = c(NA, NA), neg = c(-5, 2))
  expect_message(phw_col_bar(v, n), "has no values")
  expect_message(phw_col_heat(v, n), "has no values")
  expect_error(phw_col_bar(v, neg), "negative values")
  expect_error(phw_col_rag(), "must be two numbers")
  expect_error(phw_col_rag(1), "must be two numbers")
  expect_error(phw_col_rag(c(1, 2), rag_palette = "nope"), "must be one of")
})

test_that("every renderer stops on duplicated column names", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("gt")
  skip_if_not_installed("reactable")
  skip_if_not_installed("DT")
  skip_if_not_installed("openxlsx2")
  d <- data.frame(A = 1, A = 2, check.names = FALSE)
  expect_error(phw_flextable(d), "more than one column named")
  expect_error(phw_gt(d), "more than one column named")
  expect_error(phw_reactable(d), "more than one column named")
  expect_error(phw_datatable(d), "more than one column named")
  expect_error(phw_write_xlsx(d, withr::local_tempfile(fileext = ".xlsx")), "more than one column named")
})

test_that("every renderer asks for a data frame when given a table or a matrix", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("gt")
  skip_if_not_installed("reactable")
  skip_if_not_installed("DT")
  skip_if_not_installed("openxlsx2")
  m <- table(c("a", "b", "a"), c("x", "y", "y"))
  f <- withr::local_tempfile(fileext = ".xlsx")
  for (x in list(m, unclass(m))) {
    expect_error(phw_flextable(x), "must be a data frame.*as.data.frame")
    expect_error(phw_gt(x), "must be a data frame.*as.data.frame")
    expect_error(phw_reactable(x), "must be a data frame.*as.data.frame")
    expect_error(phw_datatable(x), "must be a data frame.*as.data.frame")
    expect_error(phw_write_xlsx(x, f), "must be a data frame.*as.data.frame")
  }
  expect_false(file.exists(f))
  expect_s3_class(phw_flextable(as.data.frame(m)), "flextable")
})

test_that("every renderer shows labels kept in row names as a first column", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("gt")
  skip_if_not_installed("reactable")
  skip_if_not_installed("DT")
  skip_if_not_installed("openxlsx2")
  hb <- c("Betsi Cadwaladr", "Powys Teaching", "Hywel Dda")
  d <- as.data.frame(matrix(c(171, 108.3, 164.2, 180.1, 112.4, 170), 3,
                            dimnames = list(hb, c("2023", "2024"))))
  expect_equal(phw_flextable(d)$body$dataset[[1]], hb)
  expect_equal(phw_gt(d)[["_data"]][[1]], hb)
  expect_equal(phw_datatable(d)$x$data[[1]], hb)
  expect_equal(jsonlite::fromJSON(as.character(phw_reactable(d)$x$tag$attribs$data))[[1]], hb)
  f <- withr::local_tempfile(fileext = ".xlsx")
  phw_write_xlsx(d, f)
  expect_equal(openxlsx2::read_xlsx(f)[[1]], hb)
  for (cols in list(phw_flextable(d)$col_keys, names(phw_gt(d)[["_data"]]),
                    attr(phw_datatable(d)$x, "colnames"))) {
    expect_equal(cols, c(" ", "2023", "2024"))
  }

  plain <- data.frame(area = c("A", "B", "C"), n = 1:3)
  expect_equal(phw_flextable(plain[plain$n > 1, ])$col_keys, c("area", "n"))
})

test_that("phw_datatable rounds and styles columns renamed with a named colnames", {
  skip_if_not_installed("DT")
  renders <- function(w) {
    defs <- Filter(function(d) !is.null(d$render), w$x$options$columnDefs)
    stats::setNames(vapply(defs, function(d) sub(".*formatRound\\(data, (\\d+).*", "\\1", d$render), ""),
                    vapply(defs, function(d) d$targets, numeric(1)))
  }
  df <- data.frame(area = c("A", "B"), cases = c(1.5, 2), n = 1:2)
  w <- phw_datatable(df, colnames = c(Cases = "cases"))
  expect_equal(attr(w$x, "colnames"), c("area", "Cases", "n"))
  expect_equal(renders(w), c(`1` = "1", `2` = "0"))
  expect_equal(renders(phw_datatable(df, rownames = TRUE)), c(`2` = "1", `3` = "0"))

  d <- data.frame(label = c("Age", "0-14", "All"), n = c(NA, 12, 42), kind = c("variable", "level", "total"))
  tab <- phw_as_summary(d, kind)
  plain <- phw_datatable(tab)$x$options$rowCallback
  renamed <- phw_datatable(tab, colnames = c(Age = "label"))$x$options$rowCallback
  expect_equal(as.character(renamed), as.character(plain))
})

test_that("phw_datatable shows renamed columns in the header of a summary table", {
  skip_if_not_installed("DT")
  header <- function(w) {
    cells <- regmatches(w, gregexpr("<th[^>]*>[^<]*</th>", w))[[1]]
    sub("<th[^>]*>([^<]*)</th>", "\\1", cells)
  }
  shown <- function(...) header(as.character(phw_datatable(...)$x$container))
  ct <- phw_crosstab(data.frame(a = c("x", "y", "x"), b = c("p", "q", "q")), a, b)
  expect_equal(shown(ct, colnames = c(Row = "a", P = "p")), c("Row", "b", ".phw_row", "P", "q", "Total"))
  expect_equal(shown(ct, colnames = c(Row = 1)), c("Row", "b", ".phw_row", "p", "q", "Total"))
  expect_equal(shown(ct, colnames = c("R", "P", "Q", "All")), c("R", "b", ".phw_row", "P", "Q", "All"))
  expect_error(phw_datatable(ct, colnames = c(Row = "zz")), '"zz", which is not a column')

  q <- data.frame(g = c("A", "A", "B"), t = c("1", "2", "1"), y = c(2023, 2023, 2024), q = c("Q1", "Q2", "Q1"))
  multi <- phw_group_table(q, c(g, t), cols = c(y, q))
  expect_equal(tail(shown(multi, colnames = c(First = "2023 / Q1")), 4), c("First", "Q2", "Q1", "Total"))

  d <- data.frame(label = c("Age", "0-14", "All"), n = c(NA, 12, 42), kind = c("variable", "level", "total"))
  w <- phw_datatable(phw_as_summary(d, kind), colnames = c("Label", "N"))
  expect_equal(header(as.character(w$x$container)), c("Label", "N", ".phw_row"))
})

test_that("the HTML tables show date-times at their local time, as phw_flextable does", {
  skip_if_not_installed("reactable")
  skip_if_not_installed("DT")
  df <- data.frame(event = c("a", "b"), ts = as.POSIXct(c("2026-07-01 10:00", NA), tz = "Europe/London"))
  shown <- jsonlite::fromJSON(as.character(phw_reactable(df)$x$tag$attribs$data))
  expect_equal(shown$ts, c("2026-07-01 10:00:00", NA))
  expect_equal(phw_datatable(df)$x$data$ts, c("2026-07-01 10:00:00", NA))
})

test_that("phw_flextable_groups() leaves a missing group uncoloured and saves to Word", {
  skip_if_not_installed("flextable")
  df <- data.frame(Group = c("Group B", NA, "Group A"), Cases = c(120, 85, 64))
  key <- phw_colour_key(c("Group A", "Group B"))
  plain <- phw_flextable(df)
  bg <- function(ft) ft$body$styles$cells$background.color$data
  fg <- function(ft) ft$body$styles$text$color$data
  for (what in c("background", "text")) {
    for (rows in c(FALSE, TRUE)) {
      ft <- phw_flextable_groups(plain, Group, what = what, rows = rows)
      coloured <- if (what == "background") bg(ft) else fg(ft)
      expect_equal(coloured[c(1, 3), "Group"], unname(key[c("Group B", "Group A")]))
      expect_equal(bg(ft)[2, ], bg(plain)[2, ])
      expect_equal(fg(ft)[2, ], fg(plain)[2, ])
      path <- tempfile(fileext = ".docx")
      flextable::save_as_docx(ft, path = path)
      expect_true(file.exists(path))
    }
  }
  none <- phw_flextable(data.frame(Group = NA_character_, Cases = 1))
  expect_identical(phw_flextable_groups(none, Group), none)
})

test_that("table group colours match the chart's colours", {
  df <- data.frame(group = c("Group B", "Group A", "Group C", "Group A"), n = 1:4)
  chart <- phw_colour_key(c("Group A", "Group B", "Group C"))
  if (requireNamespace("flextable", quietly = TRUE)) {
    ft <- phw_flextable_groups(phw_flextable(df), group)
    expect_equal(ft$body$styles$cells$background.color$data[, "group"],
                 unname(chart[df$group]))
    f <- data.frame(g = factor(c("A", "B", "C"), levels = c("Z", "A", "B", "C")))
    ft <- phw_flextable_groups(phw_flextable(f), g)
    expect_equal(ft$body$styles$cells$background.color$data[, "g"], phw_pal(3))
  }
  skip_if_not_installed("reactable")
  group_def <- function(tbl) tbl$x$tag$attribs$columns[[1]]
  bg <- function(tbl) vapply(group_def(tbl)$style, function(s) s$background, "")
  expect_equal(bg(phw_reactable(df, group_col = group)), unname(chart[df$group]))
  r <- phw_reactable(df, group_col = group,
                     columns = list(group = reactable::colDef(name = "Group")))
  expect_equal(bg(r), unname(chart[df$group]))
  expect_equal(group_def(r)$name, "Group")
})

test_that("renderers show phw_group_table(digits = ) unless given their own", {
  x <- phw_group_table(data.frame(g = c("A", "B"), v = c(1.23456, 2.5)), g, value = v, digits = 3)
  skip_if_not_installed("flextable")
  html <- as.character(flextable::htmltools_value(phw_flextable(x)))
  expect_match(html, ">1\\.235<")
  expect_match(html, ">2\\.500<")
  expect_match(as.character(flextable::htmltools_value(phw_flextable(x, digits = 1))), ">1\\.2<")
  skip_if_not_installed("gt")
  expect_match(as.character(gt::as_raw_html(phw_gt(x))), ">1\\.235<")
  skip_if_not_installed("reactable")
  expect_equal(reactable_formats(phw_reactable(x))$v, 3)
  expect_equal(reactable_formats(phw_reactable(x, digits = 2))$v, 2)
  skip_if_not_installed("DT")
  rounding <- function(w) {
    js <- vapply(w$x$options$columnDefs, function(d) as.character(d$render %||% ""), "")
    regmatches(js, regexpr("formatRound\\(data, \\d+", js))
  }
  expect_equal(rounding(phw_datatable(x)), "formatRound(data, 3")
  skip_if_not_installed("openxlsx2")
  f <- withr::local_tempfile(fileext = ".xlsx")
  phw_write_xlsx(list(Grouped = x), f)
  ex <- withr::local_tempdir()
  utils::unzip(f, exdir = ex)
  styles <- paste(readLines(file.path(ex, "xl", "styles.xml"), warn = FALSE), collapse = "")
  expect_match(styles, 'formatCode="#,##0.000"', fixed = TRUE)
})

test_that("heat colours only the level rows of a summary table", {
  skip_if_not_installed("flextable")
  dat <- data.frame(group = rep(c("A", "B", "C"), times = c(10, 20, 30)),
                    type = rep(c("x", "y"), 30))
  ft <- phw_crosstab(dat, group, type) |> phw_flextable() |> phw_flextable_heat(j = 2:3)
  bg <- ft$body$styles$cells$background.color$data
  # The largest level cell takes the darkest colour, not the total.
  expect_equal(unname(bg[3, "x"]), toupper(utils::tail(seq_cols("teals", FALSE), 1)))
  expect_equal(bg[4, c("x", "y")], c(x = "transparent", y = "transparent"))

  grouped <- phw_group_table(data.frame(a = rep(c("x", "y"), 50), b = rep(c("p", "q", "r", "s"), 25)),
                             c(a, b), subtotal_position = "below")
  types <- attr(grouped, "row_type")
  plain <- phw_flextable(grouped)$body$styles$cells$background.color$data
  heated <- phw_flextable(grouped) |> phw_flextable_heat(n)
  bg <- heated$body$styles$cells$background.color$data
  expect_identical(bg[types != "level", ], plain[types != "level", ])
  expect_true(all(bg[types == "level", "n"] != "transparent"))
})

test_that("heat leaves total columns out of a scale shared with other columns", {
  skip_if_not_installed("flextable")
  top <- toupper(utils::tail(seq_cols("teals", FALSE), 1))
  bg <- function(ft) ft$body$styles$cells$background.color$data
  dat <- data.frame(group = rep(c("A", "B", "C"), times = c(10, 20, 30)),
                    type = rep(c("x", "y"), 30))
  ct <- phw_crosstab(dat, group, type)
  heated <- bg(phw_flextable(ct) |> phw_flextable_heat(-1))
  expect_equal(unname(heated[, "Total"]), rep("transparent", 4))
  expect_equal(unname(heated[3, c("x", "y")]), c(top, top))
  expect_identical(heated, bg(phw_flextable(ct) |> phw_flextable_heat(where(is.numeric))))

  renamed <- ct
  names(renamed)[4] <- "All"
  expect_equal(unname(bg(phw_flextable(renamed) |> phw_flextable_heat(-1))[, "All"]), rep("transparent", 4))

  # Chosen on its own, the total column gets a scale of its own.
  alone <- bg(phw_flextable(ct) |> phw_flextable_heat(Total))
  expect_equal(unname(alone[3, "Total"]), top)

  g <- phw_group_table(data.frame(a = rep(c("p", "q"), c(10, 50)), b = rep(c("r", "s", "t"), 20),
                                  c = rep(c("u", "v"), each = 30)),
                       a, cols = c(b, c), col_totals = c("group", "table"))
  totals <- grep("Total", names(g), value = TRUE)
  expect_length(totals, 4)
  heated <- bg(phw_flextable(g) |> phw_flextable_heat(-1))
  expect_true(all(heated[, totals] == "transparent"))
  expect_true(top %in% heated[, setdiff(names(g)[-1], totals)])
})

test_that("phw_col_heat colours only the level rows of a summary table", {
  skip_if_not_installed("reactable")
  dat <- data.frame(group = rep(c("A", "B", "C"), times = c(10, 20, 30)),
                    type = rep(c("x", "y"), 30))
  ct <- phw_crosstab(dat, group, type)
  style <- phw_col_heat(ct, x)$style
  expect_null(style(ct$x[4], 4))
  top <- utils::tail(seq_cols("teals", FALSE), 1)
  expect_equal(toupper(style(ct$x[3], 3)$background), toupper(top))
})

test_that("heat values beyond a fixed domain take the end colours", {
  r <- data.frame(area = c("A", "B", "C", "D"), rate = c(45, 120, -5, NA))
  ends <- toupper(seq_cols("teals", FALSE)[c(1, length(seq_cols("teals", FALSE)))])
  skip_if_not_installed("flextable")
  ft <- expect_no_warning(phw_flextable(r) |> phw_flextable_heat(rate, domain = c(0, 100)))
  bg <- unname(ft$body$styles$cells$background.color$data[, "rate"])
  expect_equal(bg[2:4], c(ends[2], ends[1], "transparent"))
  skip_if_not_installed("reactable")
  style <- phw_col_heat(r, rate, domain = c(0, 100))$style
  expect_equal(toupper(expect_no_warning(style(120, 2))$background), ends[2])
  expect_equal(toupper(style(-5, 3)$background), ends[1])
})

test_that("a heat domain is used as a range, in any order or pooled", {
  a <- data.frame(x = 1:3, rate = c(45, 120, 88))
  b <- data.frame(x = 1:2, rate = c(20, 150))
  pal <- scales::col_numeric(seq_cols("teals", FALSE), domain = c(20, 150))
  skip_if_not_installed("flextable")
  bg <- function(ft) unname(ft$body$styles$cells$background.color$data[, "rate"])
  pooled <- phw_flextable(b) |> phw_flextable_heat(rate, domain = c(a$rate, b$rate))
  expect_equal(toupper(bg(pooled)), toupper(pal(b$rate)))
  reversed <- phw_flextable(a) |> phw_flextable_heat(rate, domain = c(150, 20))
  expect_equal(toupper(bg(reversed)), toupper(pal(a$rate)))
  skip_if_not_installed("reactable")
  style <- phw_col_heat(a, rate, domain = c(150, 20))$style
  expect_equal(toupper(style(45, 1)$background), toupper(pal(45)))
})

test_that("phw_col_heat follows the table's decimal places", {
  skip_if_not_installed("reactable")
  dat <- data.frame(group = rep(c("A", "B", "C"), times = c(10, 20, 30)),
                    type = rep(c("x", "y"), 30))
  ct <- phw_crosstab(dat, group, type)
  expect_equal(phw_col_heat(ct, x)$format$cell$digits, 0)
  expect_equal(phw_col_heat(ct, x, digits = 2)$format$cell$digits, 2)
  rates <- data.frame(area = c("A", "B"), rate = c(1.25, 2.5))
  expect_equal(phw_col_heat(rates, rate)$format$cell$digits, 1)
  attr(rates, "digits") <- 2
  expect_equal(phw_col_heat(rates, rate)$format$cell$digits, 2)
})

test_that("phw_col_rag with data colours only the level rows of a summary table", {
  skip_if_not_installed("reactable")
  dat <- data.frame(group = rep(c("A", "B", "C"), times = c(10, 20, 30)),
                    type = rep(c("x", "y"), 30))
  ct <- phw_crosstab(dat, group, type)
  rag <- phw_col_rag(breaks = c(12, 25), data = ct)
  shown <- vapply(seq_len(nrow(ct)), function(i) rag$cell(ct$Total[i], i, "Total"), "")
  expect_equal(shown, c("\u25BC 10", "\u25A0 20", "\u25B2 30", "60"))
  expect_null(rag$style(ct$Total[4], 4))
  expect_equal(rag$style(ct$Total[3], 3)$background, phw_palettes$rag_accessible[["green"]])
  expect_equal(phw_col_rag(breaks = c(12, 25))$cell(60, 4, "Total"), "\u25B2 60.0")
  expect_equal(phw_col_rag(breaks = c(12, 25), digits = 2, data = ct)$cell(60, 4, "Total"), "60.00")
  expect_error(phw_col_rag(breaks = c(12, 25), data = 1:3), "must be a data frame")
})

test_that("phw_col_rag shows a missing value as a blank cell", {
  skip_if_not_installed("reactable")
  rag <- phw_col_rag(breaks = c(3, 6))
  expect_equal(rag$cell(NA, 1, "v"), "")
  expect_equal(rag$cell(NA_real_, 1, "v"), "")
  expect_null(rag$style(NA, 1))
  df <- data.frame(a = c("x", "y"), v = c(NA, NA))
  expect_s3_class(phw_reactable(df, columns = list(v = phw_col_rag(breaks = c(3, 6)))), "htmlwidget")
})

test_that("bars cover only the level rows of a summary table", {
  skip_if_not_installed("flextable")
  dat <- data.frame(group = rep(c("A", "B", "C"), times = c(10, 20, 30)),
                    type = rep(c("x", "y"), 30))
  ct <- phw_crosstab(dat, group, type)
  ft <- phw_flextable(ct) |> phw_flextable_bars(Total)
  chunks <- flextable::information_data_chunk(ft)
  chunks <- chunks[chunks$.part == "body" & chunks$.col_id == "Total", ]
  bars <- chunks[!is.na(chunks$width), ]
  filled <- vapply(bars$img_data, function(img) mean(toupper(img) == toupper(phw_colours[["light_teal"]])), 0)
  # The largest level (C, 30) takes the full bar, not the grand total (60),
  # and the total row has an empty bar.
  expect_equal(filled, c(10, 20, 30, 0) / 30, tolerance = 0.02)
  expect_true(all(c("10", "30", "60") %in% chunks$txt))
})

test_that("phw_col_bar draws bars on the level rows of a summary table only", {
  skip_if_not_installed("reactable")
  dat <- data.frame(group = rep(c("A", "B", "C"), times = c(10, 20, 30)),
                    type = rep(c("x", "y"), 30))
  ct <- phw_crosstab(dat, group, type)
  cell <- phw_col_bar(ct, Total)$cell
  width <- function(i) sub(".*width:([0-9.]+%);height.*", "\\1", as.character(cell(ct$Total[i], i)))
  expect_equal(width(3), "100%")
  expect_equal(width(1), "33.3%")
  expect_equal(width(4), "0%")
  expect_match(as.character(cell(ct$Total[4], 4)), ">60<", fixed = TRUE)
})

test_that("the subgroup total block stays out of heat and bar scales", {
  dat <- data.frame(group = rep(c("A", "B", "C"), times = c(10, 20, 30)),
                    type = rep(c("T1", "T2"), 30))
  g <- phw_group_table(dat, c(group, type), totals = c("group", "subgroup", "table"))
  sub <- which(g[[1]] %in% c("T1", "T2") & g$n == 30)
  top <- which(g[[1]] %in% c("T1", "T2") & g$n == 15)
  expect_length(sub, 2)
  expect_length(top, 2)
  skip_if_not_installed("flextable")
  bg <- (phw_flextable(g) |> phw_flextable_heat(n))$body$styles$cells$background.color$data
  expect_equal(unname(bg[top, "n"]), rep(toupper(utils::tail(seq_cols("teals", FALSE), 1)), 2))
  expect_equal(unname(bg[sub, "n"]), rep("transparent", 2))
  chunks <- flextable::information_data_chunk(phw_flextable(g) |> phw_flextable_bars(n))
  chunks <- chunks[chunks$.part == "body" & chunks$.col_id == "n" & !is.na(chunks$width), ]
  filled <- vapply(chunks$img_data, function(img) mean(toupper(img) == toupper(phw_colours[["light_teal"]])), 0)
  expect_equal(filled[c(top, sub)], c(1, 1, 0, 0), tolerance = 0.02)
  skip_if_not_installed("reactable")
  cell <- phw_col_bar(g, n)$cell
  width <- function(i) sub(".*width:([0-9.]+%);height.*", "\\1", as.character(cell(g$n[i], i)))
  expect_equal(vapply(c(top, sub), width, ""), c("100%", "100%", "0%", "0%"))
  expect_null(phw_col_heat(g, n)$style(g$n[sub[1]], sub[1]))
})

test_that("every renderer shows NaN and Inf as blank cells, as NA", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("gt")
  skip_if_not_installed("reactable")
  skip_if_not_installed("DT")
  d <- data.frame(area = c("A", "B", "C", "D"), rate = c(0 / 0, 1 / 0, -1 / 0, 2.5))
  ft <- as.character(flextable::htmltools_value(phw_flextable(d)))
  expect_false(grepl("NaN|Inf", ft))
  expect_true(grepl("2.5", ft, fixed = TRUE))
  expect_false(grepl("NaN|Inf", gt::as_raw_html(phw_gt(d))))
  expect_equal(phw_datatable(d)$x$data$rate, c(NA, NA, NA, 2.5))
  rt <- as.character(phw_reactable(d)$x$tag$attribs$data)
  expect_false(grepl("NaN|Inf", rt))
  expect_identical(d$rate[2], Inf)
})

test_that("every renderer leaves out the geometry of a map's data", {
  skip_if_not_installed("sf")
  sq <- function(x) sf::st_polygon(list(rbind(c(x, 0), c(x + 1, 0), c(x + 1, 1), c(x, 1), c(x, 0))))
  s <- sf::st_sf(area = c("A", "B"), cases = c(10, 20), geometry = sf::st_sfc(lapply(0:1, sq)))
  shown <- c("area", "cases")
  skip_if_not_installed("flextable")
  expect_equal(phw_flextable(s)$col_keys, shown)
  skip_if_not_installed("gt")
  expect_equal(names(gt::extract_body(phw_gt(s))), shown)
  skip_if_not_installed("reactable")
  cols <- phw_reactable(s)$x$tag$attribs$columns
  expect_equal(vapply(cols, function(c) c$id, ""), shown)
  skip_if_not_installed("DT")
  expect_equal(names(phw_datatable(s)$x$data), shown)
  skip_if_not_installed("openxlsx2")
  f <- withr::local_tempfile(fileext = ".xlsx")
  expect_no_warning(phw_write_xlsx(list(map = s, plain = sf::st_drop_geometry(s)), f))
  expect_equal(names(openxlsx2::read_xlsx(f, sheet = "map")), shown)
})

test_that("every renderer shows a difftime as a plain number, with missing values blank", {
  d <- data.frame(patient = paste0("P", 1:3),
                  los = as.Date(c("2026-01-05", NA, "2026-02-20")) - as.Date("2026-01-01"))
  shown <- c(4, NA, 50)
  skip_if_not_installed("flextable")
  ft <- phw_flextable(d)
  body <- function(info) info[info$.part == "body" & info$.col_id == "los", ]
  expect_equal(body(flextable::information_data_chunk(ft))$txt, c("4", "", "50"))
  expect_equal(unique(body(flextable::information_data_paragraph(ft))$text.align), "right")
  skip_if_not_installed("gt")
  g <- phw_gt(d)
  expect_equal(gt::extract_body(g)$los, c("4", "<br />", "50"))
  expect_equal(g[["_boxhead"]]$column_align[g[["_boxhead"]]$var == "los"], "right")
  skip_if_not_installed("reactable")
  cols <- phw_reactable(d)$x$tag$attribs$columns
  expect_equal(cols[[2]]$type, "numeric")
  skip_if_not_installed("DT")
  dt <- phw_datatable(d)
  expect_identical(dt$x$data$los, shown)
  right <- Filter(function(def) identical(def$className, "dt-right"), dt$x$options$columnDefs)
  expect_true(1 %in% unlist(lapply(right, `[[`, "targets")))
  d$admitted <- structure(c(30600, 3600, NA), units = "secs", class = c("hms", "difftime"))
  expect_s3_class(phw_datatable(d)$x$data$admitted, "hms")
  skip_if_not_installed("openxlsx2")
  f <- withr::local_tempfile(fileext = ".xlsx")
  phw_write_xlsx(d, f)
  expect_equal(openxlsx2::read_xlsx(f)$los, shown)
})

test_that("phw_gt left-aligns every column that is not a number", {
  skip_if_not_installed("gt")
  d <- data.frame(health_board = factor(c("Powys THB", "Hywel Dda UHB")),
                  confirmed = c(TRUE, FALSE), area = c("North", "South"),
                  week = as.Date(c("2026-01-05", "2026-01-12")), cases = c(3L, 5L))
  box <- phw_gt(d)[["_boxhead"]]
  align <- stats::setNames(box$column_align, box$var)
  expect_equal(unname(align[c("health_board", "confirmed", "area", "week")]), rep("left", 4))
  expect_equal(unname(align["cases"]), "right")
  t2 <- as.data.frame(table(health_board = c("Powys THB", "Hywel Dda UHB", "Powys THB"),
                            sex = c("Female", "Male", "Male")))
  box <- phw_gt(t2)[["_boxhead"]]
  expect_equal(box$column_align, c("left", "left", "right"))
})
