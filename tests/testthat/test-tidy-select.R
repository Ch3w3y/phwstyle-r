# Column arguments take bare names, strings, positions and tidyselect
# helpers. Each function should give the same result however a column is named.

cases <- data.frame(
  onset = as.Date("2025-01-06") + c(0, 1, 8, 9, 15, 16, 22, 30),
  group = rep(c("A", "B"), 4),
  sex = rep(c("Female", "Male"), each = 4),
  age = factor(rep(c("0-44", "45+"), 4)),
  n = c(2, 3, 1, 4, 2, 2, 5, 1),
  pop = c(100, 120, 90, 110, 100, 130, 95, 105),
  ill = rep(c(1, 0), 4),
  exposed = rep(c("Yes", "Yes", "No", "No"), 2)
)

test_that("pick_cols and pick_col accept every way of naming columns", {
  f <- function(data, cols) pick_cols(rlang::enquo(cols), data, "cols", null_ok = TRUE)
  expect_equal(f(cases, group), "group")
  expect_equal(f(cases, "group"), "group")
  expect_equal(f(cases, c(group, sex)), c("group", "sex"))
  expect_equal(f(cases, c("group", "sex")), c("group", "sex"))
  expect_equal(f(cases, 2:3), c("group", "sex"))
  expect_equal(f(cases, tidyselect::starts_with("on")), "onset")
  expect_null(f(cases, NULL))
  # Names held in a variable, as code that builds a selection does.
  chosen <- c("sex", "age")
  expect_equal(f(cases, chosen), c("sex", "age"))
  expect_equal(f(cases, tidyselect::all_of(chosen)), c("sex", "age"))
  nothing <- NULL
  expect_null(f(cases, nothing))
  # Passed on from a function that takes bare names itself.
  wrapper <- function(data, col) f(data, {{ col }})
  expect_equal(wrapper(cases, pop), "pop")
  # Errors name the argument or the column.
  g <- function(data, col) pick_col(rlang::enquo(col), data, "col")
  expect_error(g(cases), "is needed")
  expect_error(g(cases, NULL), "is needed")
  expect_error(g(cases, c(group, sex)), "one column")
  expect_error(g(cases, nope), "doesn't exist")
})

test_that("the chart functions give the same chart for bare names and strings", {
  same <- function(a, b) expect_equal(ggplot2::layer_data(a), ggplot2::layer_data(b))
  same(phw_epicurve(cases, onset, group = group, count = n),
       phw_epicurve(cases, "onset", group = "group", count = "n"))
  same(phw_epicurve(cases, onset), phw_epicurve(cases, "onset"))
  same(phw_pyramid(cases, age, sex, value = n), phw_pyramid(cases, "age", "sex", value = "n"))
  same(phw_funnel(cases, n, pop, label = group), phw_funnel(cases, "n", "pop", label = "group"))
  same(phw_spc(cases, onset, n), phw_spc(cases, "onset", "n"))
  # A tibble works like a data frame.
  skip_if_not_installed("dplyr")
  same(phw_epicurve(dplyr::as_tibble(cases), onset, group = group), phw_epicurve(cases, onset, group = group))
})

test_that("the table functions give the same table for bare names and strings", {
  expect_identical(phw_crosstab(cases, group, sex, count = n), phw_crosstab(cases, "group", "sex", count = "n"))
  expect_identical(phw_summary_table(cases, vars = c(group, age), by = sex),
                   phw_summary_table(cases, vars = c("group", "age"), by = "sex"))
  expect_identical(phw_summary_table(cases, vars = tidyselect::starts_with("ag"), by = sex),
                   phw_summary_table(cases, vars = "age", by = "sex"))
  expect_identical(phw_rate_table(cases, c(group, sex), n, pop), phw_rate_table(cases, c("group", "sex"), "n", "pop"))
  expect_identical(phw_risk_table(cases, exposed, ill), phw_risk_table(cases, "exposed", "ill"))
  expect_identical(phw_group_table(cases, c(group, sex), cols = age, value = n),
                   phw_group_table(cases, c("group", "sex"), cols = "age", value = "n"))
  expect_identical(phw_group_table(cases, group), phw_group_table(cases, "group"))
  # With the pipe and dplyr verbs, as an analyst would write it.
  skip_if_not_installed("dplyr")
  piped <- cases |> dplyr::filter(sex == "Female") |> phw_crosstab(group, age)
  expect_identical(piped, phw_crosstab(cases[cases$sex == "Female", ], "group", "age"))
})

test_that("the flextable helpers take bare names, strings and positions", {
  skip_if_not_installed("flextable")
  tab <- data.frame(Area = c("A", "B", "C"), Cases = c(5, 20, 12), Rate = c(1.5, 6.2, 3.3))
  ft <- phw_flextable(tab)
  bg <- function(x) x$body$styles$cells$background.color$data
  expect_identical(bg(phw_flextable_heat(ft, c(Cases, Rate))), bg(phw_flextable_heat(ft, c("Cases", "Rate"))))
  expect_identical(bg(phw_flextable_heat(ft, 2:3)), bg(phw_flextable_heat(ft, c(Cases, Rate))))
  expect_identical(bg(phw_flextable_groups(ft, Area, key = NULL)), bg(phw_flextable_groups(ft, "Area", key = NULL)))
  expect_s3_class(phw_flextable_bars(ft, Cases), "flextable")
  expect_error(phw_flextable_groups(ft, c(Area, Cases)), "one column")
})

test_that("the reactable helpers take bare names and strings", {
  skip_if_not_installed("reactable")
  tab <- data.frame(Area = c("A", "B", "C"), Cases = c(5, 20, 12))
  expect_s3_class(phw_col_bar(tab, Cases), "colDef")
  expect_s3_class(phw_col_heat(tab, "Cases"), "colDef")
  a <- phw_reactable(tab, group_col = Area)
  b <- phw_reactable(tab, group_col = "Area")
  expect_s3_class(a, "htmlwidget")
  expect_equal(names(a$x$tag$attribs$columns), names(b$x$tag$attribs$columns))
})

test_that("phw_leaflet_polygons takes bare names, strings and expressions", {
  skip_if_not_installed("leaflet")
  skip_if_not_installed("sf")
  sq <- function(x) sf::st_polygon(list(rbind(c(x, 51), c(x + 1, 51), c(x + 1, 52), c(x, 52), c(x, 51))))
  shp <- sf::st_sf(name = c("One", "Two"), rate = c(10, 20), geometry = sf::st_sfc(sq(-4), sq(-3), crs = 4326))
  calls <- function(m) m$x$calls[[which(vapply(m$x$calls, function(k) k$method, "") == "addPolygons")]]$args
  bare <- calls(phw_leaflet_polygons(phw_leaflet(), shp, fill = rate, label = name))
  string <- calls(phw_leaflet_polygons(phw_leaflet(), shp, fill = "rate", label = "name"))
  expect_equal(bare, string)
  built <- phw_leaflet_polygons(phw_leaflet(), shp, fill = rate, label = paste(name, rate))
  expect_true(any(grepl("One 10", unlist(calls(built)))))
  # The legend takes its title from the fill column.
  legend <- function(m) m$x$calls[[which(vapply(m$x$calls, function(k) k$method, "") == "addLegend")]]$args
  expect_true("rate" %in% unlist(legend(phw_leaflet_polygons(phw_leaflet(), shp, fill = rate))))
})
