# One palette for a whole document, however many groups a chart has, with
# the accessible palette as an explicit switch.

main <- phw_palettes$main
extended <- phw_palettes$extended
accessible <- phw_palettes$accessible

# Every way a chart, table or widget picks colours for `n` groups when no
# palette is named.
default_routes <- function(n) {
  library(ggplot2)
  d <- groups(n)
  bars <- ggplot(d, aes(g, v, fill = g)) + geom_col()
  cases <- data.frame(onset = as.Date("2025-01-06") + seq_len(n), g = d$g)
  phw_key_reset("t_routes")
  out <- list(
    "ggplot2 default" = plot_colours(bars),
    "ggplot2 default colour" = plot_colours(ggplot(d, aes(g, v, colour = g)) + geom_point(), "colour"),
    "scale_fill_phw_d()" = plot_colours(bars + scale_fill_phw_d()),
    "scale with a key" = plot_colours(bars + scale_fill_phw_d(key = "t_routes")),
    "phw_epicurve()" = plot_colours(phw_epicurve(cases, "onset", group = "g")),
    "phw_colour_key()" = unname(phw_colour_key(d$g)),
    "phw_pal()" = phw_pal(n)
  )
  if (requireNamespace("flextable", quietly = TRUE)) {
    ft <- phw_flextable_groups(phw_flextable(d), "g")
    out[["phw_flextable_groups()"]] <- unname(ft$body$styles$cells$background.color$data[, "g"])
  }
  if (requireNamespace("plotly", quietly = TRUE)) {
    w <- phw_plotly(plotly::plot_ly())
    out[["phw_plotly()"]] <- w$x$layoutAttrs[[1]]$colorway[seq_len(n)]
    built <- plotly::plotly_build(phw_plotly(bars))
    # plotly writes colours as "rgba(40,80,135,1)".
    rgba <- vapply(built$x$data, function(t) t$marker$color, "")
    parts <- lapply(strsplit(gsub("[^0-9,.]", "", rgba), ","), as.numeric)
    out[["phw_plotly(ggplot)"]] <- vapply(parts, function(x) {
      grDevices::rgb(x[1], x[2], x[3], maxColorValue = 255)
    }, "")
  }
  phw_key_reset("t_routes")
  out
}

test_that("main carries on into extended", {
  expect_equal(extended[1:4], main)
  expect_equal(phw_pal(4), main)
  expect_equal(phw_pal(6), extended[1:6])
  expect_equal(phw_pal(6, "main"), extended[1:6])
  expect_equal(palette_for("main", 4), "main")
  expect_equal(palette_for("main", 5), "extended")
  expect_equal(palette_for("accessible", 12), "accessible")
  expect_equal(palette_for(c("#111111", "#222222"), 5), c("#111111", "#222222"))
})

test_that("by default charts with 4 and with 5 or more groups share their colours", {
  local_ggplot_state()
  use_phw_ggplot()
  four <- default_routes(4)
  six <- default_routes(6)
  for (route in names(four)) {
    expect_equal(four[[!!route]], main)
    expect_equal(six[[!!route]], extended[1:6])
    # The first colours of the bigger chart are the colours of the smaller.
    expect_equal(six[[!!route]][1:4], four[[!!route]])
  }
  # Nothing switches to the accessible palette unasked.
  expect_false(any(unlist(default_routes(7)) %in% setdiff(accessible, extended)))
})

test_that("the accessible switch changes every chart, table and widget", {
  local_ggplot_state()
  use_phw_ggplot(palette = "accessible")
  for (n in c(3, 4, 6, 8)) {
    routes <- default_routes(n)
    for (route in names(routes)) expect_equal(routes[[!!route]], accessible[seq_len(n)])
  }
  # Switching back gives the default colours again.
  options(phwstyle.palette = NULL)
  expect_equal(default_routes(6)[["ggplot2 default"]], extended[1:6])
})

test_that("the switch works without use_phw_ggplot() where the theme carries colours", {
  skip_if(utils::packageVersion("ggplot2") < "4.0.0", "themes can't carry palettes before ggplot2 4.0")
  library(ggplot2)
  bars <- ggplot(groups(6), aes(g, v, fill = g)) + geom_col() + theme_phw()
  expect_equal(plot_colours(bars), extended[1:6])
  withr::local_options(phwstyle.palette = "accessible")
  expect_equal(plot_colours(bars), accessible[1:6])
})

test_that("a plain chart and scale_*_phw_d() agree for any number of groups", {
  library(ggplot2)
  local_ggplot_state()
  use_phw_ggplot()
  for (pal in list(NULL, "accessible")) {
    options(phwstyle.palette = pal)
    for (n in c(1, 2, 5, 7, 8, 10)) {
      bars <- ggplot(groups(n), aes(g, v, fill = g)) + geom_col()
      plain <- suppressWarnings(plot_colours(bars))
      scaled <- suppressWarnings(plot_colours(bars + scale_fill_phw_d()))
      expect_equal(plain, scaled)
      expect_equal(anyDuplicated(plain), 0)
    }
  }
})

test_that("the palette can be switched by option, environment variable or document", {
  expect_equal(phw_default_palette(), "main")
  # A document's YAML header counts only while it is being knitted.
  local_mocked_bindings(document_palette = function() "accessible")
  expect_equal(phw_default_palette(), "accessible")
  # The environment variable overrides the document...
  withr::local_envvar(PHWSTYLE_PALETTE = "extended")
  expect_equal(phw_default_palette(), "extended")
  # ...and the option (what the functions and formats set) overrides both.
  withr::local_options(phwstyle.palette = "highlight")
  expect_equal(phw_default_palette(), "highlight")
  withr::local_options(phwstyle.palette = c("#111111", "#222222"))
  expect_equal(phw_pal(2), c("#111111", "#222222"))
})

test_that("the document palette is only read while knitting", {
  withr::local_options(knitr.in.progress = NULL)
  expect_null(document_palette())
  expect_equal(phw_default_palette(), "main")
  withr::local_envvar(PHWSTYLE_PALETTE = "accessible")
  expect_equal(phw_default_palette(), "accessible")
  expect_equal(phw_pal(5), accessible[1:5])
})

test_that("a colour key keeps a separate accessible copy in the same order", {
  for (k in c("t_acc", "t_pin", "t_only")) phw_key_reset(k)
  withr::defer(for (k in c("t_acc", "t_pin", "t_only")) phw_key_reset(k))
  lv <- paste("Group", 1:6)
  def <- phw_colour_key(lv, "t_acc")
  expect_equal(unname(def), extended[1:6])
  acc <- phw_colour_key(rev(lv), "t_acc", palette = "accessible")
  # Asked for in another order, the copy still follows the default key.
  expect_equal(unname(acc[lv]), accessible[1:6])
  expect_equal(names(phw_key("t_acc@accessible")), lv)
  # The default key is untouched, and both grow independently.
  expect_equal(phw_key("t_acc"), def)
  withr::local_options(phwstyle.palette = "accessible")
  more <- phw_colour_key(c(lv, "Group 7", "Unknown"), "t_acc")
  expect_equal(unname(more), c(accessible[1:7], phw_colours[["grey_mid"]]))
  expect_length(phw_key("t_acc"), 6)
  expect_true(all(c("t_acc", "t_acc@accessible") %in% phw_keys()$key))
  phw_key_reset("t_acc")
  expect_length(phw_key("t_acc@accessible"), 0)

  # Hand-picked colours, and colours that are in both palettes, stay put.
  phw_key_set("t_pin", c(Female = "#FF5D0C", Male = "#285087", Wales = "#123456", Other = phw_colours[["grey_mid"]]))
  phw_colour_key(c("A", "B"), "t_pin", palette = "main")
  pin <- phw_colour_key(c("Female", "Male", "Wales", "Other", "A", "B"), "t_pin")
  expect_equal(unname(pin[c("Female", "Male", "Wales", "Other")]),
               c("#FF5D0C", "#285087", "#123456", phw_colours[["grey_mid"]]))
  expect_equal(anyDuplicated(pin), 0)
  expect_true(all(pin[c("A", "B")] %in% accessible))

  # With no default key to follow, the copy starts from scratch.
  expect_equal(unname(phw_colour_key(lv[1:5], "t_only")), accessible[1:5])
  expect_length(phw_key("t_only"), 0)
})

test_that("phw_plotly gives plotly the whole default palette", {
  skip_if_not_installed("plotly")
  colorway <- function(...) phw_plotly(plotly::plot_ly(), ...)$x$layoutAttrs[[1]]$colorway
  expect_equal(colorway(), extended)
  expect_equal(colorway(palette = "accessible"), accessible)
  expect_equal(colorway(palette = c("#111111", "#222222")), c("#111111", "#222222"))
  withr::local_options(phwstyle.palette = "accessible")
  expect_equal(colorway(), accessible)
})
