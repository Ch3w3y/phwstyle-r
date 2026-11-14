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

test_that("phw_gt carries the Ubuntu web font and italic subtotals, and left-aligns dates", {
  skip_if_not_installed("gt")
  g <- phw_gt(data.frame(d = as.Date("2026-01-01"), n = 1)) |> gt::tab_header("Title")
  deps <- htmltools::findDependencies(htmltools::as.tags(g))
  expect_true("phw-ubuntu-font" %in% vapply(deps, `[[`, "", "name"))
  expect_match(gt::as_raw_html(g, inline_css = FALSE), 'gt_row gt_left">2026-01-01', fixed = TRUE)
  html <- gt::as_raw_html(phw_gt(make_groups(subtotal_position = "below")))
  expect_match(html, "font-style: italic;[^>]*>Group A total", perl = TRUE)
})

test_that("use_phw_flextable() styles are not carried into another style", {
  skip_if_not_installed("flextable")
  old <- use_phw_flextable(style = "zebra")
  on.exit(do.call(flextable::set_flextable_defaults, old))
  ft <- phw_flextable(head(airquality), style = "header")
  expect_true(all(ft$body$styles$cells$background.color$data == "transparent"))
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
