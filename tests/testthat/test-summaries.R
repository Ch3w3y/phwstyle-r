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
  expect_equal(summary_header(tab, 1)$upper[[1]]$label, "grp")
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
  expect_equal(summary_header(t1, 1)$upper[[1]]$label, "year")
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
  d <- data.frame(board = c("Board 1", "Board 2", "Board 1"), org = c("MRSA", "MSSA", "MRSA"))
  lab <- list(org = "MRSA or MSSA (NHS lab)")
  t_sub <- phw_group_table(d, c(board, org), totals = "subgroup", labels = lab)
  expect_true("Total by MRSA or MSSA (NHS lab)" %in% t_sub$board)
  t_cy <- phw_group_table(d, c(board, org), totals = "subgroup", labels = lab,
                          subgroup_label = "Cyfanswm fesul {variable}")
  expect_true("Cyfanswm fesul MRSA or MSSA (NHS lab)" %in% t_cy$board)
  expect_error(phw_group_table(d, c(board, org), subgroup_label = c("a", "b")), "single string")
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
  expect_error(phw_group_table(dat, "nope"), "doesn't exist")
  expect_error(phw_group_table(dat, "group", "year", col_totals = "none", percent = "row"), "total column")
  expect_output(print(t3), "Group A")
})

test_that("columns layout puts the subgroup levels in the innermost column", {
  d <- data.frame(board = c("Board A", "Board B", "Board A", "Board B"),
                  sex = c("Female", "Male", "Male", "Female"),
                  age = c("0-14", "65+", "15-64", "0-14"))
  for (pos in c("bottom", "top")) {
    g <- phw_group_table(d, c(board, sex, age), totals = c("subgroup", "table"),
                         layout = "columns", total_position = pos)
    head <- which(g$board == "Total by age")
    lv <- head + 1:3
    expect_equal(g$age[lv], c("0-14", "15-64", "65+"))
    expect_equal(g$sex[lv], rep("", 3))
    expect_equal(g$board[lv], rep("", 3))
    expect_equal(g$n[lv], c(2, 1, 1))
  }
  ind <- phw_group_table(d, c(board, sex, age), totals = "subgroup")
  expect_equal(attr(ind, "depth")[which(ind[[1]] == "Total by age") + 1:3], rep(1, 3))
})

test_that("phw_group_table(drop = FALSE) keeps unused factor levels as zeros", {
  d <- data.frame(
    age = factor(c("0-4", "0-4", "15+"), levels = c("0-4", "5-14", "15+")),
    year = factor(c(2023, 2024, 2024), levels = c(2023, 2024, 2025))
  )
  kept <- phw_group_table(d, rows = age, cols = year, drop = FALSE)
  expect_equal(kept$age, c("0-4", "5-14", "15+", "Total"))
  expect_equal(names(kept), c("age", "2023", "2024", "2025", "Total"))
  expect_equal(kept[["2025"]], c(0, 0, 0, 0))
  expect_equal(kept$Total, c(2, 0, 1, 3))
  dropped <- phw_group_table(d, rows = age, cols = year)
  expect_equal(dropped$age, c("0-4", "15+", "Total"))
  expect_equal(names(dropped), c("age", "2023", "2024", "Total"))
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

test_that("col_labels relabel the bottom header of a nested group table", {
  skip_if_not_installed("flextable")
  x <- phw_group_table(data.frame(group = c("A", "B"), year = c(2023, 2024), q = c("Q1", "Q2")),
                       rows = group, cols = c(year, q))
  bottom <- function(ft) {
    i <- flextable::information_data_chunk(ft)
    i$txt[i$.part == "header" & i$.row_id == 2]
  }
  ft <- phw_flextable(x, col_labels = list(group = "Board", `2023 / Q1` = "First quarter",
                                           `Total / Total` = "All"))
  expect_equal(bottom(ft), c("Board", "First quarter", "Q2", "All"))
  ft <- phw_flextable(x, col_labels = list(`2023 / Q1` = "a", `2024 / Q2` = "b", `Total / Total` = "c"))
  expect_equal(bottom(ft), c("group", "a", "b", "c"))
})

test_that("phw_as_summary makes a hand-built table render like a built one", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("reactable")
  d <- data.frame(label = c("Age", "0-14", "65+", "All"), n = c(NA, 12, 30, 42),
                  kind = c("variable", "level", "level", "total"))
  tab <- phw_as_summary(d, row_type = kind, note = "Note.")
  expect_s3_class(tab, "phw_summary")
  expect_equal(names(tab), c("label", "n"))
  expect_equal(attr(tab, "note"), "Note.")
  ft <- phw_flextable(tab)
  expect_true(all(unlist(ft$body$styles$text$bold$data[c(1, 4), ])))
  expect_false(any(unlist(ft$body$styles$text$bold$data[c(2, 3), ])))
  rt <- phw_reactable(phw_as_summary(d, kind))
  rs <- rt$x$tag$attribs$rowStyle
  expect_equal(rs[[1]]$fontWeight, 700)
  expect_equal(rs[[4]]$fontWeight, 700)
  expect_null(rs[[2]]$fontWeight)
  expect_output(print(tab), "  0-14")
  all_levels <- phw_as_summary(d[1:2])
  expect_equal(attr(all_levels, "row_type"), rep("level", 4))
  expect_equal(attr(phw_as_summary(d, "kind"), "row_type"), d$kind)
})

test_that("phw_as_summary names unknown row types", {
  d <- data.frame(label = c("a", "b"), kind = c("level", "heading"))
  expect_error(phw_as_summary(d, kind), "heading")
})

test_that("phw_summary_table leaves out rows with a missing group when missing = NULL", {
  ll <- data.frame(age = c("0-14", "15-44", NA), sex = c("F", "M", "F"))
  expect_message(tab <- phw_summary_table(ll, by = age, missing = NULL), "Left out 1 row")
  expect_equal(names(tab)[-1], c("0-14 (n = 1)", "15-44 (n = 1)", "Total (n = 2)"))
  expect_equal(tab[[2]][2], "1 (100.0%)")
})

test_that("phw_summary_table leaves a statistic blank when it can't be worked out", {
  d <- data.frame(x = c(1, NA, NA), g = c("a", "b", "b"))
  tab <- phw_summary_table(d, by = g, missing = NULL)
  expect_equal(tab[[3]][1], "")
  tab <- phw_summary_table(d, by = g, numeric = "mean_sd", missing = NULL)
  expect_equal(tab[[2]][1], "1.0 (-)")
})

test_that("phw_group_table and phw_crosstab leave out rows with a missing value", {
  gd <- data.frame(g = c("A", "A", "B"), t = c("1", "2", "1"), v = c(5, NA, 2))
  expect_message(tab <- phw_group_table(gd, c(g, t), value = v), "Left out 1 row")
  expect_equal(tab$v[tab[[1]] == "Total"], 7)
  ct <- data.frame(r = c("x", "y"), k = c("p", "q"), n = c(1, NA))
  expect_message(tab <- phw_crosstab(ct, r, k, count = n), "Left out 1 row")
  expect_equal(tab$Total[tab$r == "Total"], 1)
  expect_error(phw_crosstab(transform(ct, n = "1"), r, k, count = n), "must be a numeric column")
})

test_that("phw_group_table says how many rows it leaves out when missing = NULL", {
  d <- data.frame(g = c("A", "A", NA, "B"), y = c(1, 2, 1, NA), v = c(3, NA, 5, 6))
  expect_message(tab <- phw_group_table(d, g, y, missing = NULL),
                 "Left out 2 rows with a missing value in g or y")
  expect_equal(tab$Total[tab$g == "Total"], 2)
  expect_message(tab <- phw_group_table(d, g, y, value = v, missing = NULL),
                 "Left out 3 rows")
  expect_equal(tab$Total[tab$g == "Total"], 3)
  expect_no_message(tab <- phw_group_table(d, g, y))
  expect_equal(tab$Total[tab$g == "Total"], 4)
})

test_that("phw_crosstab says how many rows it leaves out when missing = NULL", {
  d <- data.frame(area = c("A", "A", NA, "B"), sex = c("F", "M", "F", NA), n = c(3, 4, 5, 6))
  expect_message(tab <- phw_crosstab(d, area, sex, count = n, missing = NULL),
                 "Left out 2 rows")
  expect_equal(tab$Total[tab$area == "Total"], 7)
  expect_message(phw_crosstab(transform(d, n = c(NA, 4, 5, 6)), area, sex, count = n, missing = NULL),
                 "Left out 3 rows")
  expect_no_message(tab <- phw_crosstab(d, area, sex, count = n))
  expect_equal(tab$Total[tab$area == "Total"], 18)
})

test_that("labels can be a named character vector", {
  ll <- data.frame(age = c("0-14", "15-44"), sex = c("F", "M"))
  expect_equal(phw_summary_table(ll, labels = c(sex = "Sex"))[[1]][4], "Sex")
  expect_equal(summary_header(phw_crosstab(ll, age, sex, labels = c(sex = "Sex")), 1)$upper[[1]]$label, "Sex")
  expect_match(names(phw_group_table(ll, c(age, sex), labels = c(age = "Age")))[1], "^Age")
  expect_error(phw_summary_table(ll, labels = "Sex"), "must give a name")
})

test_that("the legacy rate and risk tables stop clearly with no rows to use", {
  rd <- data.frame(a = "x", cases = 1, pop = 10)
  expect_error(phw_rate_table(rd[0, ], a, cases, pop), "has no rows")
  rk <- data.frame(e = c("Yes", "No"), y = c(1, 0))
  expect_error(phw_risk_table(rk[0, ], e, y), "has no rows")
  expect_error(phw_risk_table(transform(rk, e = NA), e, y), "no rows with both")
})

test_that("the legacy rate table stops on a text count or population", {
  rd <- data.frame(age = c("0-14", "15+"), cases = c("3", "5"), pop = c(100, 200))
  expect_error(phw_rate_table(rd, age, cases, pop), "`cases` must be a numeric column")
  rd <- transform(rd, cases = c(3, 5), pop = c("100", "200"))
  expect_error(phw_rate_table(rd, age, cases, pop), "`population` must be a numeric column")
})

test_that("subsetting a summary table keeps its row styling on the rows kept", {
  d <- data.frame(age = c("0-14", "15-44", "65+", "0-14"), sex = c("F", "M", "F", "M"),
                  grp = c("A", "B", "A", "B"))
  s <- phw_summary_table(d, by = grp, labels = list(age = "Age group", sex = "Sex"))
  kept <- s[s$Characteristic != "15-44", ]
  expect_equal(kept$Characteristic, c("Age group", "0-14", "65+", "Sex", "F", "M"))
  expect_equal(attr(kept, "row_type"), c("variable", "level", "level", "variable", "level", "level"))
  expect_output(print(kept), "Sex")
  expect_equal(attr(s[3:1, ], "row_type"), attr(s, "row_type")[3:1])
  expect_equal(attr(head(s, 2), "row_type"), c("variable", "level"))

  skip_if_not_installed("flextable")
  ft <- phw_flextable(kept)
  expect_equal(unname(ft$body$styles$text$bold$data[, 1]), attr(kept, "row_type") == "variable")
})

test_that("dplyr verbs keep a summary table's styling in step", {
  skip_if_not_installed("dplyr")
  d <- data.frame(age = c("0-14", "15-44", "65+", "0-14"), sex = c("F", "M", "F", "M"),
                  grp = c("A", "B", "A", "B"))
  s <- phw_summary_table(d, by = grp, labels = list(age = "Age group", sex = "Sex"))
  kept <- dplyr::filter(s, Characteristic != "15-44")
  expect_equal(attr(kept, "row_type"), c("variable", "level", "level", "variable", "level", "level"))
  expect_equal(attr(dplyr::slice(s, 5:7), "row_type"), c("variable", "level", "level"))
  picked <- dplyr::select(s, Characteristic, `Total (n = 4)`)
  expect_s3_class(picked, "phw_summary")
  expect_equal(attr(picked, "row_type"), attr(s, "row_type"))
  expect_equal(summary_header(picked, 1)$upper[[1]]$label, "grp")

  skip_if_not_installed("reactable")
  expect_true(inherits(phw_reactable(kept), c("htmlwidget", "shiny.tag.list")))
  expect_true(inherits(phw_reactable(s[, 1:3]), c("htmlwidget", "shiny.tag.list")))
})

test_that("subsetting a group table keeps its column header and group starts in step", {
  t3 <- phw_group_table(make_ops(), c("group", "type"), c("year", "q"), col_totals = c("group", "table"),
                        totals = "none", separate = "line")
  ch <- attr(t3, "col_header")
  sub <- t3[-(1:4), c(1, 7, 8)]
  expect_equal(summary_header_levels(sub, 1), unname(ch[, 6:7]))
  expect_equal(attr(sub, "row_type"), attr(t3, "row_type")[-(1:4)])
  expect_equal(attr(sub, "group_start"), setdiff(attr(t3, "group_start") - 4L, 1L))
  expect_equal(attr(t3[-1, ], "group_start"), attr(t3, "group_start") - 1L)
})

test_that("a summary table's header follows its columns when they are moved or renamed", {
  skip_if_not_installed("dplyr")
  ct <- phw_crosstab(make_ops(), group, year)
  moved <- dplyr::mutate(ct, change = `2024` - `2023`, .before = `2024`)
  expect_equal(summary_header_levels(moved, 1),
               rbind(c("year", "", "year", "year"), c("2023", "change", "2024", "Total")))
  renamed <- dplyr::rename(ct, `Year 2023` = `2023`)
  expect_equal(summary_header(renamed, 1)$upper[[1]]$label, "year")
  t3 <- phw_group_table(make_ops(), group, c(year, q))
  names(t3)[2] <- "first"
  expect_equal(summary_header_levels(t3, 1)[, 1], c("2023", "Q1"))
})

test_that("a summary table loses its styling when its labels or rows can't be kept", {
  s <- phw_summary_table(data.frame(sex = c("F", "M"), g = c("a", "b")), by = g)
  expect_identical(class(s[, -1]), "data.frame")
  expect_identical(class(s[c(1, 99), ]), "data.frame")
  expect_null(attr(s[, -1], "row_type"))
})

test_that("a summary table whose row styling no longer fits its rows says how to fix it", {
  s <- phw_summary_table(data.frame(sex = c("F", "M"), g = c("a", "b")), by = g)
  expect_error(print(rbind(s, s)), "row styling is for 3")
  expect_output(print(as.data.frame(rbind(s, s))), "sex")
})
