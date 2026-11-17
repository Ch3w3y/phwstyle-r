# Extracted from test-tables-widgets.R:652

# prequel ----------------------------------------------------------------------
reactable_formats <- function(w) {
  cols <- w$x$tag$attribs$columns
  stats::setNames(lapply(cols, function(cd) cd$format$cell$digits), vapply(cols, function(cd) cd$id, ""))
}
make_groups <- function(...) {
  d <- data.frame(group = rep(c("Group A", "Group B"), each = 4),
                  type = rep(c("Type 1", "Type 2"), 4), year = rep(2023:2024, each = 2, times = 2))
  phw_group_table(d, c(group, type), cols = year, ...)
}

# test -------------------------------------------------------------------------
skip_if_not_installed("reactable")
dat <- data.frame(group = rep(c("A", "B", "C"), times = c(10, 20, 30)),
                    type = rep(c("x", "y"), 30))
ct <- phw_crosstab(dat, group, type)
expect_equal(phw_col_heat(ct, x)$format$digits, 0)
