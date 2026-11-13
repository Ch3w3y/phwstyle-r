#' PHW theme for reactable
#'
#' A [reactable::reactableTheme()] that uses the PHW font and colours: a navy
#' header rule, light grey striping and hover, and the yellow keyboard focus
#' outline used on phw.nhs.wales.
#'
#' @param font_size Base font size in px.
#' @param header Header style: `"booktabs"` (navy text and rules), `"navy"`
#'   (navy band, white text) or `"light"` (light teal band).
#' @param accent Colour used for the header, rules and current page button.
#' @param ... Other [reactable::reactableTheme()] arguments. They override
#'   the PHW defaults.
#' @return A reactable theme.
#' @export
phw_reactable_theme <- function(font_size = 14, header = c("booktabs", "navy", "light"),
                                accent = phw_colours[["navy"]], ...) {
  rlang::check_installed("reactable")
  header <- rlang::arg_match(header)
  col <- phw_colours
  col[["navy"]] <- accent
  header_style <- switch(header,
    booktabs = list(color = col[["navy"]], borderTop = paste("2px solid", col[["navy"]]),
                    borderBottom = paste("2px solid", col[["navy"]]), fontWeight = 700),
    navy = list(color = "#FFFFFF", background = col[["navy"]], fontWeight = 700,
                borderBottom = paste("2px solid", col[["navy"]])),
    light = list(color = col[["text"]], background = col[["light_teal"]], fontWeight = 700,
                 borderBottom = paste("1px solid", col[["grey_border"]])))
  args <- list(
    color = col[["text"]],
    backgroundColor = "#FFFFFF",
    borderColor = col[["grey_border"]],
    stripedColor = col[["grey_bg"]],
    highlightColor = "#E8EDF4",
    cellPadding = "6px 10px",
    style = list(fontFamily = paste0(phw_font(), ", Arial, sans-serif"),
                 fontSize = paste0(font_size, "px")),
    headerStyle = c(header_style, list(fontSize = paste0(font_size, "px"),
                                       "&:hover[aria-sort]" = list(background = col[["grey_bg"]], color = col[["navy"]]),
                                       "&[aria-sort='ascending'], &[aria-sort='descending']" = list(background = col[["grey_bg"]], color = col[["navy"]]))),
    footerStyle = list(fontWeight = 700, borderTop = paste("2px solid", col[["navy"]])),
    searchInputStyle = list(borderColor = col[["grey_mid"]], width = "100%",
                            "&:focus" = list(outline = paste("3px solid", col[["focus"]]),
                                             borderColor = col[["text"]])),
    inputStyle = list("&:focus" = list(outline = paste("3px solid", col[["focus"]]))),
    pageButtonHoverStyle = list(background = col[["grey_bg"]]),
    pageButtonActiveStyle = list(background = "#E8EDF4"),
    pageButtonCurrentStyle = list(background = col[["navy"]], color = "#FFFFFF")
  )
  extra <- list(...)
  args[names(extra)] <- extra
  do.call(reactable::reactableTheme, args)
}

#' Make a PHW-styled reactable
#'
#' Calls [reactable::reactable()] with the PHW theme, striping, compact rows
#' and number formatting with thousands separators. It also attaches the
#' Ubuntu web font. You can add a title above and a source line below.
#'
#' @param data A data frame, or a summary table from [phw_summary_table()],
#'   [phw_crosstab()], [phw_rate_table()] or [phw_risk_table()] (shown with
#'   bold headings, indented levels and no sorting or paging).
#' @param ... Passed to [reactable::reactable()]. Any of them, including
#'   `theme`, `defaultColDef` and `language`, replace the PHW defaults.
#' @param caption Optional title shown above the table.
#' @param source,date Passed to [phw_caption()] and shown below the table.
#' @param header,accent Passed to [phw_reactable_theme()].
#' @param caption_args List of other [phw_caption()] arguments.
#' @param group_col,key,palette Colour the cells of the column `group_col`
#'   (unquoted as in dplyr, or a string) by group, with the same colours as
#'   your charts. `key` and `palette` are
#'   passed to [phw_colour_key()].
#' @return An htmlwidget (or a tag list when a caption or source is given).
#' @export
phw_reactable <- function(data, ..., caption = NULL, source = NULL, date = NULL,
                          header = "booktabs", accent = phw_colours[["navy"]],
                          caption_args = list(), group_col = NULL, key = NULL,
                          palette = phw_default_palette()) {
  rlang::check_installed("reactable")
  group_col <- pick_col(rlang::enquo(group_col), data, "group_col", null_ok = TRUE)
  args <- list(...)
  defaults <- list(striped = TRUE, highlight = TRUE, compact = TRUE,
                   theme = phw_reactable_theme(header = header, accent = accent),
                   defaultColDef = reactable::colDef(
                     format = reactable::colFormat(separators = TRUE),
                     headerVAlign = "bottom"))
  if (inherits(data, "phw_summary")) {
    sm <- summary_reactable_args(data)
    for (nm in names(sm)) if (is.null(args[[nm]])) args[[nm]] <- sm[[nm]]
    if (!is.null(attr(data, "note"))) caption_args$note <- caption_args$note %||% attr(data, "note")
    data <- as.data.frame(unclass(data)[names(data)], check.names = FALSE)
  }
  for (nm in names(defaults)) if (is.null(args[[nm]])) args[[nm]] <- defaults[[nm]]
  if (!is.null(group_col)) {
    cols <- phw_colour_key(data[[group_col]], name = key, palette = palette)
    style_fun <- function(value) {
      bg <- unname(cols[as.character(value)])
      if (is.na(bg)) return(NULL)
      list(background = bg, color = phw_text_on(bg), fontWeight = 500)
    }
    col_defs <- args$columns %||% list()
    col_defs[[group_col]] <- col_defs[[group_col]] %||% reactable::colDef(style = style_fun)
    args$columns <- col_defs
  }
  tbl <- do.call(reactable::reactable, c(list(data), args))
  tbl <- htmltools::attachDependencies(tbl, phw_font_dependency(), append = TRUE)
  wrap_widget(tbl, caption, caption_from(source, date, caption_args))
}

wrap_widget <- function(widget, caption, cap) {
  if (is.null(caption) && is.null(cap)) return(widget)
  htmltools::browsable(htmltools::tagList(
    phw_font_dependency(),
    htmltools::div(
      class = "phw-widget",
      style = sprintf("font-family:%s, Arial, sans-serif;", phw_font()),
      if (!is.null(caption)) htmltools::div(
        caption, style = sprintf("font-weight:700;color:%s;font-size:1.05em;margin:0 0 6px 0;",
                                 phw_colours[["navy"]])),
      widget,
      if (!is.null(cap)) htmltools::div(
        htmltools::HTML(gsub("\n", "<br>", htmltools::htmlEscape(cap))),
        style = sprintf("font-weight:700;text-align:right;font-size:0.8em;color:%s;margin-top:6px;",
                        phw_colours[["text"]]))
    )
  ))
}

#' Apply PHW styling to a plotly chart
#'
#' Restyles a plotly figure with the PHW font, colour order, light
#' gridlines, a horizontal legend under the chart, and hover labels in navy.
#' It also trims the mode bar. You can pass it a plotly object, or a ggplot,
#' which is converted with [plotly::ggplotly()] first.
#'
#' @param p A plotly object or a ggplot.
#' @param source,date Passed to [phw_caption()] and shown under the chart.
#' @param legend `"bottom"`, `"right"` or `"none"`.
#' @param palette Colour order for traces that don't set their own colour: a
#'   palette name or a vector of colours.
#' @param font_size Base font size in px.
#' @param caption_args List of other [phw_caption()] arguments.
#' @param modebar Show the plotly tool bar?
#' @param ... Extra arguments for [plotly::layout()]. They override the PHW
#'   defaults; lists are merged, so `title = list(text = "My title")` keeps
#'   the PHW title style.
#' @return A plotly object.
#' @details Any plotly chart type works: scatter and lines, bars, pies and
#'   donuts (given the PHW colours and white slice borders), box and violin plots, histograms,
#'   heatmaps and choropleth maps (which pick up the PHW sequential
#'   colour scale unless you set `colorscale`), and figures combined with
#'   [plotly::subplot()]. Use [phw_plotly_colorscale()] to set a PHW scale on
#'   a trace yourself.
#'
#'   For colours that stay with a group across charts, pass a colour
#'   key to plotly yourself, e.g.
#'   `plot_ly(df, x = ~week, y = ~rate, color = ~age, colors = phw_colour_key(df$age, "age"))`.
#'   ggplots keep the colours of their `scale_colour_phw_d(key = ...)`.
#' @export
phw_plotly <- function(p, source = NULL, date = NULL, ...,
                       legend = c("bottom", "right", "none"),
                       palette = phw_default_palette(), font_size = 13, caption_args = list(),
                       modebar = TRUE) {
  rlang::check_installed("plotly")
  legend <- rlang::arg_match(legend)
  if (inherits(p, "ggplot")) p <- ggplotly_phw(p)
  col <- phw_colours
  # plotly works through the colours in order, so "main" needs the rest of
  # "extended" behind it for charts with more than four traces.
  colorway <- palette_colours(palette_for(palette, Inf))
  font <- list(family = paste0(phw_font(), ", Arial, sans-serif"), size = font_size, color = col[["text"]])
  axis <- list(gridcolor = col[["grey_border"]], zerolinecolor = col[["grey_mid"]],
               linecolor = col[["grey_mid"]], tickfont = list(color = col[["text_secondary"]]),
               title = list(font = list(color = col[["text_secondary"]])))
  cap <- caption_from(source, date, caption_args)
  ann <- if (!is.null(cap)) list(list(
    text = paste0("<b>", gsub("\n", "<br>", cap), "</b>"), showarrow = FALSE,
    xref = "paper", yref = "paper", x = 1, y = 0, xanchor = "right", yanchor = "top",
    yshift = if (legend == "bottom") -70 else -40, font = list(size = 11, color = col[["text"]]))) else list()
  base <- list(
    font = font,
    colorway = unname(colorway),
    colorscale = list(sequential = phw_plotly_colorscale("blues"),
                      sequentialminus = phw_plotly_colorscale("blues"),
                      diverging = phw_plotly_colorscale("orange_navy")),
    paper_bgcolor = "#FFFFFF", plot_bgcolor = "#FFFFFF",
    title = list(font = list(color = col[["navy"]], size = 17), x = 0, xanchor = "left"),
    xaxis = axis, yaxis = axis,
    showlegend = legend != "none",
    legend = if (legend == "bottom") list(orientation = "h", x = 0, y = -0.15, xanchor = "left",
                                          yanchor = "top", title = list(text = ""))
             else list(orientation = "v", title = list(text = "")),
    hoverlabel = list(bgcolor = col[["navy"]], bordercolor = col[["navy"]],
                      font = list(color = "#FFFFFF", family = font$family)),
    margin = list(b = if (!is.null(cap)) 110 else 60, t = 50),
    annotations = ann
  )
  extra <- list(...)
  for (nm in names(extra)) {
    base[[nm]] <- if (is.list(base[[nm]]) && is.list(extra[[nm]])) {
      utils::modifyList(base[[nm]], extra[[nm]])
    } else {
      extra[[nm]]
    }
  }
  p <- colour_pies(p, unname(colorway))
  p <- do.call(plotly::layout, c(list(p), base))
  p <- plotly::config(p, displaylogo = FALSE, displayModeBar = modebar,
                      modeBarButtonsToRemove = c("lasso2d", "select2d", "autoScale2d",
                                                 "hoverCompareCartesian", "toggleSpikelines"),
                      toImageButtonOptions = list(format = "png", scale = 2))
  htmltools::attachDependencies(p, phw_font_dependency(), append = TRUE)
}

# plotly::ggplotly() builds the plot itself and ignores palettes stored in
# the theme (ggplot2 >= 4.0), so add PHW scales explicitly where the plot
# has none.
ggplotly_phw <- function(p) {
  b <- ggplot2::ggplot_build(p)
  has <- vapply(c("colour", "fill"), function(a) !is.null(b$plot$scales$get_scales(a)), logical(1))
  user <- vapply(c("colour", "fill"), function(a) {
    any(vapply(p$scales$scales, function(s) a %in% s$aesthetics, logical(1)))
  }, logical(1))
  for (a in c("colour", "fill")) {
    if (has[[a]] && !user[[a]]) {
      sc <- b$plot$scales$get_scales(a)
      p <- p + if (sc$is_discrete()) {
        if (a == "colour") scale_colour_phw_d() else scale_fill_phw_d()
      } else {
        if (a == "colour") scale_colour_phw_c() else scale_fill_phw_c()
      }
    }
  }
  plotly::ggplotly(p)
}

summary_reactable_args <- function(x) {
  types <- attr(x, "row_type")
  depth <- attr(x, "depth") %||% as.integer(types == "level")
  nl <- attr(x, "label_cols") %||% 1L
  indent <- attr(x, "indent") %||% TRUE
  highlight <- attr(x, "highlight") %||% TRUE
  starts <- attr(x, "group_start") %||% integer()
  sep <- attr(x, "separate") %||% "none"
  col <- phw_colours
  nms <- names(x)
  cols <- list()
  for (j in seq_len(nl)) {
    cols[[nms[j]]] <- reactable::colDef(
      minWidth = if (nl == 1) 160 else 110,
      style = function(value, index) {
        st <- list()
        if (indent && depth[index] > 0) st$paddingLeft <- paste0(8 + 14 * depth[index], "px")
        if (types[index] == "variable" && depth[index] == 0) st$color <- col[["navy"]]
        if (types[index] == "subtotal") st$fontStyle <- "italic"
        st
      })
  }
  ch <- attr(x, "col_header")
  data_cols <- nms[-seq_len(nl)]
  for (i in seq_along(data_cols)) {
    cols[[data_cols[i]]] <- reactable::colDef(
      align = "right", na = "",
      name = if (!is.null(ch)) ch[nrow(ch), i] else data_cols[i])
  }
  sp <- attr(x, "spanner")
  groups <- NULL
  if (!is.null(ch) && nrow(ch) > 1) {
    key <- apply(ch[-nrow(ch), , drop = FALSE], 2, paste, collapse = " \u00b7 ")
    r <- rle(key)
    ends <- cumsum(r$lengths)
    groups <- lapply(seq_along(ends), function(g) {
      idx <- (ends[g] - r$lengths[g] + 1):ends[g]
      # A grand total column has the same label at every level: show it once.
      same <- all(ch[, idx] == ch[nrow(ch), idx[1]])
      reactable::colGroup(name = if (same) "" else r$values[g], columns = data_cols[idx])
    })
  } else if (!is.null(sp)) {
    groups <- list(reactable::colGroup(name = sp, columns = data_cols))
  }
  list(
    columns = cols,
    columnGroups = groups,
    sortable = FALSE, pagination = FALSE, striped = FALSE,
    rowStyle = function(index) {
      st <- list()
      if (types[index] %in% c("variable", "subtotal", "total")) st$fontWeight <- 700
      if (types[index] == "total") st$borderTop <- paste("2px solid", col[["navy"]])
      if (types[index] == "variable" && depth[index] == 0 && highlight) st$background <- col[["grey_bg"]]
      if (index %in% starts && types[index] != "total") {
        if (sep %in% c("line", "both")) st$borderTop <- paste("1px solid", col[["grey_mid"]])
        if (sep %in% c("space", "both")) st$marginTop <- "10px"
      }
      st
    }
  )
}

#' Column formats for reactable
#'
#' Ready-made [reactable::colDef()]s for common PHW table columns. Pass them
#' in `columns = list(...)` of [phw_reactable()] or [reactable::reactable()].
#'
#' * `phw_col_bar()`: the value with a horizontal bar behind it, scaled to
#'   the column's largest value. Good for counts and rates.
#' * `phw_col_heat()`: cell background from a sequential or diverging
#'   palette, with readable text.
#' * `phw_col_rag()`: red, amber or green cells with a shape, so status
#'   doesn't rely on colour alone.
#' * `phw_col_number()` and `phw_col_percent()`: thousands separators and
#'   fixed decimals.
#'
#' @param data The data frame (bar and heat columns need it to find the
#'   range).
#' @param column The column, unquoted as in dplyr. A string works too.
#' @param colour Bar colour.
#' @param palette Palette name or vector of colours.
#' @param domain Range for the heat colours. Defaults to the column range.
#' @param breaks,higher_is_better See [phw_flextable_heat()].
#' @param rag_palette `"rag"` or `"rag_accessible"`.
#' @param digits Decimal places.
#' @param ... Other [reactable::colDef()] arguments, e.g. `name`.
#' @return A [reactable::colDef()].
#' @examples
#' if (requireNamespace("reactable", quietly = TRUE)) {
#'   df <- data.frame(area = paste("Area", LETTERS[1:5]), cases = c(120, 85, 64, 19, 23),
#'                    rate = c(4.1, 2.2, 6.3, 1.0, 2.5), share = c(.38, .27, .2, .06, .07))
#'   phw_reactable(df, columns = list(
#'     cases = phw_col_bar(df, cases, name = "Cases"),
#'     rate = phw_col_heat(df, rate, name = "Rate"),
#'     share = phw_col_percent(name = "Share")
#'   ))
#' }
#' @name phw_reactable_columns
NULL

#' @rdname phw_reactable_columns
#' @export
phw_col_bar <- function(data, column, colour = phw_colours[["light_teal"]], digits = 0, ...) {
  rlang::check_installed("reactable")
  column <- pick_col(rlang::enquo(column), data, "column")
  mx <- max(data[[column]], na.rm = TRUE)
  reactable::colDef(
    align = "left",
    cell = function(value) {
      if (is.na(value)) return("")
      w <- if (mx > 0) paste0(round(100 * value / mx, 1), "%") else "0%"
      htmltools::div(
        style = "display:flex;align-items:center;gap:6px;",
        htmltools::div(style = "flex:1 1 auto;background:transparent;",
          htmltools::div(style = sprintf("width:%s;height:14px;background:%s;border-radius:2px;", w, colour))),
        htmltools::span(style = "min-width:3.5em;text-align:right;font-variant-numeric:tabular-nums;",
                        fmt_num(value, digits)))
    }, ...)
}

#' @rdname phw_reactable_columns
#' @export
phw_col_heat <- function(data, column, palette = "teals", domain = NULL, digits = 1, ...) {
  rlang::check_installed("reactable")
  column <- pick_col(rlang::enquo(column), data, "column")
  domain <- domain %||% range(data[[column]], na.rm = TRUE)
  fill <- scales::col_numeric(seq_cols(palette, FALSE), domain = domain, na.color = "transparent")
  reactable::colDef(
    format = reactable::colFormat(separators = TRUE, digits = digits),
    style = function(value) {
      if (is.na(value)) return(NULL)
      bg <- fill(value)
      list(background = bg, color = phw_text_on(bg))
    }, ...)
}

#' @rdname phw_reactable_columns
#' @export
phw_col_rag <- function(breaks, higher_is_better = TRUE, rag_palette = "rag_accessible",
                        digits = 1, ...) {
  rlang::check_installed("reactable")
  pal <- phw_palettes[[rag_palette]]
  shapes <- c(red = "\u25BC", amber = "\u25A0", green = "\u25B2")
  status <- function(v) {
    st <- if (v < breaks[1]) "low" else if (v < breaks[2]) "mid" else "high"
    if (higher_is_better) c(low = "red", mid = "amber", high = "green")[[st]]
    else c(low = "green", mid = "amber", high = "red")[[st]]
  }
  reactable::colDef(
    align = "right",
    cell = function(value) if (is.na(value)) "" else paste(shapes[[status(value)]], fmt_num(value, digits)),
    style = function(value) {
      if (is.na(value)) return(NULL)
      bg <- pal[[status(value)]]
      list(background = bg, color = phw_text_on(bg), fontWeight = 500)
    }, ...)
}

#' @rdname phw_reactable_columns
#' @export
phw_col_number <- function(digits = 0, ...) {
  rlang::check_installed("reactable")
  reactable::colDef(format = reactable::colFormat(separators = TRUE, digits = digits), align = "right", ...)
}

#' @rdname phw_reactable_columns
#' @export
phw_col_percent <- function(digits = 1, ...) {
  rlang::check_installed("reactable")
  reactable::colDef(format = reactable::colFormat(percent = TRUE, digits = digits), align = "right", ...)
}

#' PHW colour scale for plotly
#'
#' Turns a PHW palette into the colour scale format plotly expects, for
#' heatmaps, choropleths and markers coloured by a number, e.g.
#' `plot_ly(z = volcano, type = "heatmap", colorscale = phw_plotly_colorscale("teals"))`.
#'
#' @param palette A sequential or diverging palette name, or a vector of
#'   colours.
#' @param reverse Reverse the scale?
#' @param n Number of steps.
#' @return A list of `list(position, colour)` pairs.
#' @examples
#' phw_plotly_colorscale("blues", n = 3)
#' @export
phw_plotly_colorscale <- function(palette = "blues", reverse = FALSE, n = 9) {
  cols <- grDevices::colorRampPalette(seq_cols(palette, reverse), space = "Lab")(n)
  lapply(seq_len(n), function(i) list((i - 1) / (n - 1), cols[i]))
}

# Pie traces ignore colorway, so give them PHW colours unless they set their own.
colour_pies <- function(p, cols) {
  if (is.null(p$x$attrs)) return(p)
  p$x$attrs <- lapply(p$x$attrs, function(a) {
    if (identical(a$type, "pie") && is.null(a$marker$colors)) {
      a$marker <- utils::modifyList(a$marker %||% list(),
                                    list(colors = cols, line = list(color = "#FFFFFF", width = 1.5)))
    }
    a
  })
  p
}
