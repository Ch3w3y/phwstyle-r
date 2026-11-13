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
