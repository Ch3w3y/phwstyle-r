make_ll <- function() {
  set.seed(3)
  data.frame(age = factor(sample(c("0-14", "15-64", "65+"), 120, TRUE), levels = c("0-14", "15-64", "65+")),
             sex = sample(c("F", "M", NA), 120, TRUE, prob = c(.45, .45, .1)),
             days = rpois(120, 5), grp = sample(c("A", "B"), 120, TRUE))
}

test_that("phw_summary_table counts and labels correctly", {
  ll <- make_ll()
  tab <- phw_summary_table(ll, by = "grp", labels = list(age = "Age group"))
  expect_s3_class(tab, "phw_summary")
  types <- attr(tab, "row_type")
  expect_equal(tab[[1]][types == "variable"], c("Age group", "sex"))
  n_tot <- sum(ll$age == "0-14")
  expect_match(tab[tab[[1]] == "0-14", ncol(tab)], paste0("^", n_tot, " "))
  expect_true("Unknown" %in% tab[[1]])
  expect_match(names(tab)[ncol(tab)], "Total \\(n = 120\\)")
  expect_equal(attr(tab, "spanner"), "grp")
  tab2 <- phw_summary_table(ll, vars = "days", numeric = "mean_sd", n_in_header = FALSE)
  expect_match(tab2[1, 2], "^[0-9.]+ \\([0-9.]+\\)$")
  expect_output(print(tab), "Age group")
})

test_that("phw_crosstab totals and percentages add up", {
  ll <- make_ll()
  xt <- phw_crosstab(ll, "age", "grp")
  expect_equal(xt$Total[nrow(xt)], 120)
  expect_equal(sum(xt$A[-nrow(xt)]), xt$A[nrow(xt)])
  xr <- phw_crosstab(ll, "age", "grp", percent = "row")
  expect_true(all(grepl("100.0%", xr$Total)))
  xc <- phw_crosstab(ll, "age", "grp", percent = "column")
  expect_match(xc$A[nrow(xc)], "100.0%")
})

test_that("phw_rate_table gives exact Poisson intervals", {
  d <- data.frame(g = c("x", "y"), cases = c(0, 10), pop = c(1000, 1000))
  rt <- phw_rate_table(d, "g", "cases", "pop", per = 1000, total = FALSE)
  expect_equal(rt[["Rate per 1,000"]][attr(rt, "row_type") == "level"], c(0, 10))
  ci <- phw_poisson_ci(10)
  expect_equal(round(ci$lower, 3), 4.795)
  expect_equal(round(ci$upper, 3), 18.390)
  expect_equal(phw_poisson_ci(0)$lower, 0)
})

test_that("phw_risk_table computes attack rates and relative risks", {
  d <- data.frame(e = rep(c("Yes", "No"), each = 10), ill = c(rep(1, 6), rep(0, 4), rep(1, 2), rep(0, 8)))
  rk <- phw_risk_table(d, "e", "ill")
  lv <- rk[attr(rk, "row_type") == "level", ]
  expect_equal(lv$Exposure, c("No", "Yes"))
  expect_equal(lv[["Attack rate (%)"]], c(20, 60))
  expect_equal(lv[["Relative risk"]][2], "3.00")
})

test_that("summary tables render in flextable and reactable", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("reactable")
  ll <- make_ll()
  tab <- phw_summary_table(ll, by = "grp")
  ft <- phw_flextable(tab, source = "S")
  expect_s3_class(ft, "flextable")
  expect_equal(flextable::nrow_part(ft, "header"), 2)
  expect_true(inherits(phw_reactable(tab), c("htmlwidget", "shiny.tag.list")))
  df <- data.frame(a = c("x", "y"), n = c(3, 5), r = c(0.9, 0.96))
  expect_s3_class(phw_reactable(df, columns = list(n = phw_col_bar(df, "n"), r = phw_col_rag(c(0.92, 0.95)))), "htmlwidget")
  expect_s3_class(phw_flextable_bars(phw_flextable(df), "n"), "flextable")
})

test_that("plotly pies and colour scales get PHW colours", {
  skip_if_not_installed("plotly")
  w <- phw_plotly(plotly::plot_ly(labels = c("a", "b"), values = 1:2, type = "pie"))
  expect_equal(w$x$attrs[[1]]$marker$colors[1], phw_palettes$main[1])
  cs <- phw_plotly_colorscale("blues", n = 3)
  expect_equal(cs[[1]][[1]], 0)
  expect_equal(cs[[3]][[1]], 1)
})

make_ops <- function() {
  set.seed(1)
  data.frame(group = sample(c("Group A", "Group B", "Group C"), 200, TRUE),
             type = sample(c("Type 1", "Type 2", "Type 3"), 200, TRUE),
             year = sample(2023:2024, 200, TRUE), q = sample(c("Q1", "Q2"), 200, TRUE),
             days = rpois(200, 3))
}

test_that("phw_group_table nests groups and totals add up", {
  dat <- make_ops()
  t1 <- phw_group_table(dat, c("group", "type"), "year")
  types <- attr(t1, "row_type")
  expect_equal(t1$Total[types == "total"], 200)
  expect_equal(sum(t1$Total[types == "variable"]), 200)
  expect_equal(sum(t1$Total[types == "level"]), 200)
  gb <- which(t1[[1]] == "Group B")
  expect_equal(t1$Total[gb], sum(t1$Total[gb + 1:3]))
  expect_equal(attr(t1, "depth")[gb + 1], 1)
  expect_equal(attr(t1, "spanner"), "year")
  expect_equal(attr(t1, "group_start"), which(types %in% c("variable", "total"))[-1])
})

test_that("phw_group_table total options and layouts work", {
  dat <- make_ops()
  t2 <- phw_group_table(dat, c("group", "type"), totals = c("group", "subgroup", "table"),
                        subtotal_position = "below", layout = "columns", percent = "parent",
                        total_position = "top")
  expect_equal(names(t2)[1:2], c("group", "type"))
  expect_equal(attr(t2, "row_type")[1], "total")
  expect_true("Group B total" %in% t2$group)
  expect_true("Total by type" %in% t2$group)
  expect_true(all(t2$n[t2$group %in% c("Group B", "Group A", "Group C")] == ""))
  expect_match(t2$n[1], "100.0%")
  t3 <- phw_group_table(dat, c("group", "type"), c("year", "q"), col_totals = c("group", "table"),
                        totals = "none")
  ch <- attr(t3, "col_header")
  expect_equal(dim(ch), c(2, 7))
  expect_equal(ch[, 7], c("Total", "Total"))
  expect_false("total" %in% attr(t3, "row_type"))
  t4 <- phw_group_table(dat, "group", value = "days", fun = mean, totals = "table")
  expect_equal(t4$days[t4$group == "Total"], mean(dat$days))
  expect_error(phw_group_table(dat, "nope"), "not found")
  expect_error(phw_group_table(dat, "group", "year", col_totals = "none", percent = "row"), "total column")
  expect_output(print(t3), "Group A")
})

test_that("grouped tables render with flextable and reactable", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("reactable")
  dat <- make_ops()
  t3 <- phw_group_table(dat, c("group", "type"), c("year", "q"), col_totals = c("group", "table"))
  ft <- phw_flextable(t3)
  expect_equal(flextable::nrow_part(ft, "header"), 2)
  t2 <- phw_group_table(dat, c("group", "type"), layout = "columns", separate = "both")
  expect_s3_class(phw_flextable(t2), "flextable")
  expect_s3_class(phw_reactable(t3), "htmlwidget")
})
