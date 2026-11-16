#' PHW theme for reactable
#'
#' A [reactable::reactableTheme()] that uses the PHW font and colours: navy
#' header rules and a navy rule closing the table, navy column group
#' headings, light grey hover (and striping, if you turn it on), and the
#' yellow keyboard focus outline used on phw.nhs.wales.
#'
#' @param font_size Base font size in px.
#' @param header Header style: `"booktabs"` (navy text and rules), `"navy"`
#'   (navy band, white text) or `"light"` (light teal band).
#' @param accent Colour used for the header, rules and current page button.
#' @param ... Other [reactable::reactableTheme()] arguments. They override
#'   the PHW defaults.
#' @return A reactable theme.
#' @examples
#' if (requireNamespace("reactable", quietly = TRUE)) {
#'   tbl <- reactable::reactable(head(mtcars),
#'                               theme = phw_reactable_theme(header = "navy"))
#'   if (interactive()) print(tbl)
#' }
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
  group_style <- switch(header,
    booktabs = list(color = col[["navy"]], fontWeight = 700),
    navy = list(color = "#FFFFFF", background = col[["navy"]], fontWeight = 700),
    light = list(color = col[["text"]], background = col[["light_teal"]], fontWeight = 700))
  args <- list(
    color = col[["text"]],
    backgroundColor = "#FFFFFF",
    borderColor = col[["grey_border"]],
    stripedColor = col[["grey_bg"]],
    highlightColor = "#E8EDF4",
    cellPadding = "6px 10px",
    style = list(fontFamily = paste0(phw_font(), ", Arial, sans-serif"),
                 fontSize = paste0(font_size, "px")),
    tableStyle = list(borderBottom = paste("2px solid", col[["navy"]])),
    groupHeaderStyle = c(group_style, list(fontSize = paste0(font_size, "px"))),
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
#' Calls [reactable::reactable()] with the PHW theme, compact rows and
#' number formatting with thousands separators. Rows are not striped, as in
#' the other PHW tables; pass `striped = TRUE` to stripe them. It also attaches the
#' Ubuntu web font. You can add a title above and a source line below.
#'
#' @param data A data frame, or a summary table from [phw_summary_table()],
#'   [phw_crosstab()], [phw_rate_table()] or [phw_risk_table()] (shown with
#'   bold headings, indented levels and no sorting or paging).
#' @param ... Passed to [reactable::reactable()]. Any of them, including
#'   `theme`, `defaultColDef` and `language`, replace the PHW defaults. For a
#'   summary table, `columns` change only the settings you give, so the
#'   table keeps its indents, alignment and headings.
#' @param caption Optional title shown above the table.
#' @param source,date Passed to [phw_caption()] and shown below the table.
#' @param header,accent Passed to [phw_reactable_theme()].
#' @param caption_args List of other [phw_caption()] arguments.
#' @param digits Decimal places for non-integer numbers, as in
#'   [phw_flextable()] and [phw_gt()]. A column of whole numbers shows none.
#'   A column you format yourself in `columns` keeps your format, and a
#'   `format` in `defaultColDef` applies to every column.
#' @param group_col,key,palette Colour the cells of the column `group_col`
#'   (unquoted as in dplyr, or a string) by group, with the same colours as
#'   your charts. `key` and `palette` are
#'   passed to [phw_colour_key()].
#' @return An htmlwidget (or a tag list when a caption or source is given).
#' @examples
#' if (requireNamespace("reactable", quietly = TRUE)) {
#'   df <- data.frame(area = paste("Area", LETTERS[1:5]),
#'                    group = c("Group A", "Group B", "Group A", "Group C", "Group B"),
#'                    cases = c(1203, 845, 642, 190, 231))
#'   tbl <- phw_reactable(df, caption = "Cases by area", source = "Example data",
#'                        searchable = TRUE)
#'
#'   # Colour the group column with the same colours as your charts
#'   tbl2 <- phw_reactable(df, group_col = group)
#'
#'   # A summary table keeps its bold headings and indents
#'   ll <- data.frame(sex = rep(c("Female", "Male"), 10),
#'                    outcome = rep(c("Outcome X", "Outcome Y"), each = 10))
#'   tbl3 <- phw_reactable(phw_summary_table(ll, by = outcome))
#'
#'   # Printing shows the table in the Viewer or a browser.
#'   if (interactive()) print(tbl)
#' }
#' @export
phw_reactable <- function(data, ..., caption = NULL, source = NULL, date = NULL,
                          header = "booktabs", accent = phw_colours[["navy"]],
                          caption_args = list(), digits = 1, group_col = NULL, key = NULL,
                          palette = phw_default_palette()) {
  rlang::check_installed("reactable")
  check_unique_names(data)
  if (missing(digits)) digits <- attr(data, "digits") %||% digits
  group_col <- pick_col(rlang::enquo(group_col), data, "group_col", null_ok = TRUE)
  args <- list(...)
  note <- NULL
  defaults <- list(striped = FALSE, highlight = TRUE, compact = TRUE,
                   theme = phw_reactable_theme(header = header, accent = accent),
                   defaultColDef = reactable::colDef(
                     format = reactable::colFormat(separators = TRUE),
                     headerVAlign = "bottom"))
  own_format <- !is.null(args[["defaultColDef"]][["format"]])
  if (inherits(data, "phw_summary")) {
    sm <- summary_reactable_args(data)
    args$columns <- merge_col_defs(sm$columns, args$columns)
    sm$columns <- NULL
    for (nm in names(sm)) if (is.null(args[[nm]])) args[[nm]] <- sm[[nm]]
    note <- attr(data, "note")
    data <- as.data.frame(unclass(data)[names(data)], check.names = FALSE)
  }
  data <- local_times(data)
  for (nm in names(defaults)) if (is.null(args[[nm]])) args[[nm]] <- defaults[[nm]]
  if (!own_format) args$columns <- with_number_formats(args$columns, data, digits)
  if (!is.null(group_col)) {
    cols <- phw_colour_key(group_levels(data[[group_col]]), name = key, palette = palette)
    style_fun <- function(value) {
      bg <- unname(cols[as.character(value)])
      if (is.na(bg)) return(NULL)
      list(background = bg, color = phw_text_on(bg), fontWeight = 500)
    }
    group_def <- stats::setNames(list(reactable::colDef(style = style_fun)), group_col)
    args$columns <- merge_col_defs(group_def, args$columns)
  }
  tbl <- do.call(reactable::reactable, c(list(data), args))
  tbl$dependencies <- c(tbl$dependencies, list(phw_font_dependency()))
  wrap_widget(tbl, caption, caption_from(source, date, caption_args), note)
}

# The user's settings for a column replace only the same settings in `base`.
merge_col_defs <- function(base, user) {
  for (nm in names(user)) {
    def <- base[[nm]] %||% reactable::colDef()
    def[names(user[[nm]])] <- user[[nm]]
    base[[nm]] <- def
  }
  base
}

# Date-times as text at the clock time of their own time zone, as
# phw_flextable() and phw_gt() show them. The widgets would show UTC.
local_times <- function(data) {
  is_time <- vapply(data, inherits, logical(1), "POSIXt")
  data[is_time] <- lapply(data[is_time], format, format = "%Y-%m-%d %H:%M:%S")
  data
}

with_number_formats <- function(columns, data, digits) {
  columns <- columns %||% list()
  for (nm in names(data)[vapply(data, is.numeric, logical(1))]) {
    v <- data[[nm]]
    places <- if (all(v == round(v), na.rm = TRUE)) 0 else digits
    def <- columns[[nm]] %||% reactable::colDef()
    if (is.null(def$format)) {
      fmt <- reactable::colFormat(separators = TRUE, digits = places)
      def$format <- list(cell = fmt, aggregated = fmt)
    }
    columns[[nm]] <- def
  }
  columns
}

# The title above, then the table, a summary table's note on the statistics
# and the bold source line, as phw_flextable() and phw_gt() lay them out.
wrap_widget <- function(widget, caption, cap, note = NULL) {
  if (is.null(caption) && is.null(cap) && is.null(note)) return(widget)
  htmltools::browsable(htmltools::tagList(
    phw_font_dependency(),
    htmltools::div(
      class = "phw-widget",
      style = sprintf("font-family:%s, Arial, sans-serif;", phw_font()),
      if (!is.null(caption)) htmltools::div(
        caption, style = sprintf("font-weight:700;color:%s;font-size:1.05em;margin:0 0 6px 0;",
                                 phw_colours[["navy"]])),
      widget,
      if (!is.null(note)) htmltools::div(
        note, style = sprintf("font-size:0.8em;color:%s;margin-top:6px;", phw_colours[["text_secondary"]])),
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
#' @param legend Where the legend goes: `"bottom"`, `"right"` or `"none"`.
#'   As in plotly, a chart with one trace has no legend; pass
#'   `showlegend = TRUE` to show one.
#' @param palette Colours for traces that don't set their own: a palette
#'   name, a vector of colours or a function of `n`, as in [phw_pal()]. A
#'   trace that maps `color` to groups without giving `colors` takes them
#'   from this palette too.
#' @param font_size Base font size in px.
#' @param caption_args List of other [phw_caption()] arguments.
#' @param modebar Show the plotly tool bar?
#' @param ... Extra arguments for [plotly::layout()]. They override the PHW
#'   defaults; lists are merged, so `title = list(text = "My title")` keeps
#'   the PHW title style. `annotations` are added after the caption.
#' @return A plotly object.
#' @details Any plotly chart type works: scatter and lines, bars, pies and
#'   donuts (given the PHW colours and white slice borders), box and violin plots, histograms,
#'   heatmaps, contours and choropleth maps, and markers coloured by a number
#'   (which pick up the PHW sequential colour scale unless you set
#'   `colorscale` or `colors`), and figures combined with
#'   [plotly::subplot()]. Use [phw_plotly_colorscale()] to set a PHW scale on
#'   a trace yourself.
#'
#'   In a [plotly::subplot()] figure, a group has the same colour in every
#'   panel. If a panel sets its own colours with `colors` or `I()`, the group
#'   colours and colour scales stay as each panel was built. To give the
#'   other panels PHW colours, style each panel with `phw_plotly()` before
#'   combining them.
#'
#'   For colours that stay with a group across charts, pass a colour
#'   key to plotly yourself, e.g.
#'   `plot_ly(df, x = ~week, y = ~rate, color = ~age, colors = phw_colour_key(df$age, "age"))`.
#'   ggplots keep the colours of their `scale_colour_phw_d(key = ...)`.
#' @examples
#' if (requireNamespace("plotly", quietly = TRUE)) {
#'   df <- data.frame(week = rep(1:10, 2),
#'                    cases = c(3, 5, 9, 14, 20, 18, 13, 9, 6, 4,
#'                              2, 4, 6, 9, 11, 13, 12, 10, 7, 5),
#'                    group = rep(c("Group A", "Group B"), each = 10))
#'
#'   # A chart built with plot_ly()
#'   p <- plotly::plot_ly(df, x = ~week, y = ~cases, color = ~group,
#'                        type = "scatter", mode = "lines")
#'   w1 <- phw_plotly(p, source = "Example data")
#'
#'   # A ggplot, converted for you
#'   g <- ggplot2::ggplot(df, ggplot2::aes(week, cases, colour = group)) +
#'     ggplot2::geom_line()
#'   w2 <- phw_plotly(g, source = "Example data", hovermode = "x")
#'
#'   # Printing shows the chart in the Viewer or a browser.
#'   if (interactive()) print(w1)
#' }
#' @export
phw_plotly <- function(p, source = NULL, date = NULL, ...,
                       legend = c("bottom", "right", "none"),
                       palette = phw_default_palette(), font_size = 13, caption_args = list(),
                       modebar = TRUE) {
  rlang::check_installed("plotly")
  legend <- rlang::arg_match(legend)
  if (!inherits(p, c("plotly", "ggplot"))) {
    cli::cli_abort("{.arg p} must be a plotly chart or a ggplot, not {.obj_type_friendly {p}}.")
  }
  cap <- caption_from(source, date, caption_args)
  if (inherits(p, "ggplot")) p <- ggplotly_phw(p)
  col <- phw_colours
  colorway <- plotly_colorway(p, palette)
  font <- list(family = paste0(phw_font(), ", Arial, sans-serif"), size = font_size, color = col[["text"]])
  # An axis `color` colours its title and tick labels without replacing the
  # title text, which a list title would do when plotly merges layouts.
  axis <- list(color = col[["text_secondary"]], gridcolor = col[["grey_border"]],
               zerolinecolor = col[["grey_mid"]], linecolor = col[["grey_mid"]],
               tickfont = list(color = col[["text_secondary"]]))
  axes <- lapply(c(xaxis = "xaxis", yaxis = "yaxis"), function(a) {
    # ggplotly() gives its axis titles a font colour of their own.
    if (is.list(current_title(p, a))) axis$title <- list(font = list(color = col[["text_secondary"]]))
    axis
  })
  title <- current_title(p)
  ann <- if (!is.null(cap)) list(list(
    name = "phw_source", text = paste0("<b>", gsub("\n", "<br>", cap), "</b>"), showarrow = FALSE,
    xref = "paper", yref = "paper", x = 1, y = 0, xanchor = "right", yanchor = "top",
    yshift = if (legend == "bottom") -70 else -40, font = list(size = 11, color = col[["text"]]))) else list()
  base <- list(
    font = font,
    colorway = unname(colorway),
    colorscale = list(sequential = phw_plotly_colorscale("blues"),
                      sequentialminus = phw_plotly_colorscale("blues"),
                      diverging = phw_plotly_colorscale("orange_navy")),
    paper_bgcolor = "#FFFFFF", plot_bgcolor = "#FFFFFF",
    title = c(if (!is.null(title) && !is.list(title)) list(text = title),
              list(font = list(color = col[["navy"]], size = 17), x = 0, xanchor = "left")),
    xaxis = axes$xaxis, yaxis = axes$yaxis,
    legend = if (legend == "bottom") list(orientation = "h", x = 0, y = -0.15, xanchor = "left",
                                          yanchor = "top", title = list(text = ""))
             else list(orientation = "v", title = list(text = "")),
    hoverlabel = list(bgcolor = col[["navy"]], bordercolor = col[["navy"]],
                      font = list(color = "#FFFFFF", family = font$family)),
    margin = list(b = if (!is.null(cap)) 110 else 60, t = 50),
    annotations = ann
  )
  if (legend == "none") base$showlegend <- FALSE
  extra <- list(...)
  for (nm in names(extra)) {
    base[[nm]] <- if (nm == "annotations") {
      # One annotation, or a list of them, goes after the caption.
      add <- extra[[nm]]
      c(base[[nm]], if (rlang::is_named(add)) list(add) else add)
    } else if (is.list(base[[nm]]) && is.list(extra[[nm]])) {
      utils::modifyList(base[[nm]], extra[[nm]])
    } else {
      extra[[nm]]
    }
  }
  p <- colour_built(p, palette, colorway)
  p <- colour_pies(p, palette, unname(colorway))
  p <- colour_mapped(p, palette)
  p <- do.call(plotly::layout, c(list(p), base))
  p <- plotly::config(p, displaylogo = FALSE, displayModeBar = modebar,
                      modeBarButtonsToRemove = c("lasso2d", "select2d", "autoScale2d",
                                                 "hoverCompareCartesian", "toggleSpikelines"),
                      toImageButtonOptions = list(format = "png", scale = 2))
  p$dependencies <- c(p$dependencies, list(phw_font_dependency()))
  if (legend == "bottom") {
    js <- paste(readLines(system.file("js", "plotly-bottom-legend.js", package = "phwstyle")), collapse = "\n")
    p <- htmlwidgets::onRender(p, js, data = list(margin = extra$margin$b %||% 0))
  }
  p
}

# The last title set on the chart, or on one axis, before phw_plotly():
# plotly merges p$x$layout and then each layout() call in turn. Only whether
# it is text or a list matters here, and the last one decides that.
current_title <- function(p, axis = NULL) {
  out <- NULL
  for (l in c(list(p$x$layout), p$x$layoutAttrs)) {
    t <- if (is.null(axis)) l[["title"]] else l[[axis]][["title"]]
    if (!is.null(t)) out <- t
  }
  out
}

# plotly::ggplotly() builds the plot itself and ignores palettes stored in
# the theme (ggplot2 >= 4.0), so add the default scales use_phw_ggplot()
# gives a static chart where the plot has none.
ggplotly_phw <- function(p) {
  b <- ggplot2::ggplot_build(p)
  has <- vapply(c("colour", "fill"), function(a) !is.null(b$plot$scales$get_scales(a)), logical(1))
  user <- vapply(c("colour", "fill"), function(a) {
    any(vapply(p$scales$scales, function(s) a %in% s$aesthetics, logical(1)))
  }, logical(1))
  for (a in c("colour", "fill")) {
    if (has[[a]] && !user[[a]]) {
      discrete <- b$plot$scales$get_scales(a)$is_discrete()
      p <- p + phw_default_scale(a, if (discrete) "discrete" else "continuous")
    }
  }
  plotly::ggplotly(p)
}

summary_reactable_args <- function(x) {
  rows <- summary_rows(x)
  nl <- attr(x, "label_cols") %||% 1L
  col <- phw_colours
  nms <- names(x)
  cols <- list()
  for (j in seq_len(nl)) {
    cols[[nms[j]]] <- reactable::colDef(
      minWidth = if (nl == 1) 160 else 110,
      style = function(value, index) {
        st <- list()
        if (rows$indent[index] > 0) st$paddingLeft <- paste0(8 + 14 * rows$indent[index], "px")
        if (rows$navy[index]) st$color <- col[["navy"]]
        if (rows$italic[index]) st$fontStyle <- "italic"
        st
      })
  }
  hd <- summary_header(x, nl)
  data_cols <- nms[-seq_len(nl)]
  for (i in seq_along(data_cols)) {
    cols[[data_cols[i]]] <- reactable::colDef(align = "right", na = "", name = hd$bottom[i])
  }
  ch <- attr(x, "col_header")
  groups <- NULL
  if (length(hd$upper)) {
    # reactable has one level of column groups: group by the lowest upper
    # level and name each group by every upper level.
    level <- hd$upper[[length(hd$upper)]]
    groups <- lapply(seq_len(nrow(level)), function(g) {
      idx <- level$start[g] + seq_len(level$n[g]) - 1
      name <- if (level$total[g]) "" else if (is.null(ch)) level$label[g] else paste(ch[-nrow(ch), idx[1]], collapse = " \u00b7 ")
      reactable::colGroup(name = name, columns = data_cols[idx])
    })
  }
  list(
    columns = cols,
    columnGroups = groups,
    sortable = FALSE, pagination = FALSE, striped = FALSE,
    rowStyle = function(index) {
      st <- list()
      if (rows$bold[index]) st$fontWeight <- 700
      if (rows$rule[index]) st$borderTop <- paste("2px solid", col[["navy"]])
      if (rows$shade[index]) st$background <- col[["grey_bg"]]
      if (rows$line[index]) st$borderTop <- paste("1px solid", col[["grey_mid"]])
      if (rows$space[index]) st$marginTop <- "10px"
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
  if (!length(value_cols(data, column, "column"))) return(reactable::colDef(align = "right", ...))
  check_bar_values(data[[column]], column, "column")
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
  fmt <- reactable::colFormat(separators = TRUE, digits = digits)
  if (!length(value_cols(data, column, "column"))) return(reactable::colDef(format = fmt, ...))
  domain <- domain %||% range(data[[column]], na.rm = TRUE)
  fill <- scales::col_numeric(seq_cols(palette, FALSE), domain = domain, na.color = "transparent")
  reactable::colDef(
    format = fmt,
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
  if (missing(breaks)) breaks <- NULL
  check_breaks(breaks)
  rag_palette <- rlang::arg_match(rag_palette, c("rag_accessible", "rag"))
  pal <- phw_palettes[[rag_palette]]
  shapes <- c(red = "\u25BC", amber = "\u25A0", green = "\u25B2")
  status <- function(v) rag_status(v, breaks, higher_is_better)
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
#' @param palette A sequential or diverging palette name, a vector of
#'   colours, or a function of `n`.
#' @param reverse Reverse the scale?
#' @param n Number of steps, 2 or more.
#' @return A list of `list(position, colour)` pairs.
#' @examples
#' phw_plotly_colorscale("blues", n = 3)
#' @export
phw_plotly_colorscale <- function(palette = "blues", reverse = FALSE, n = 9) {
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 2) {
    cli::cli_abort("{.arg n} must be one number, 2 or more.")
  }
  cols <- if (is.function(palette)) {
    phw_pal(n, palette, reverse = reverse)
  } else {
    grDevices::colorRampPalette(seq_cols(palette, reverse), space = "Lab")(n)
  }
  lapply(seq_len(n), function(i) list((i - 1) / (n - 1), cols[i]))
}

# The colours plotly gives traces in turn. "main" needs the rest of
# "extended" behind it for charts with more than six traces. A function
# palette is asked for as many colours as there are traces. Sequential and
# diverging palettes drop their near-white steps, which vanish on white.
plotly_colorway <- function(p, palette) {
  if (is.function(palette)) {
    return(phw_pal(max(length(plotly::plotly_build(p)$x$data), 1), palette))
  }
  cols <- palette_colours(palette_for(palette, Inf))
  if (is_ramp(palette)) {
    cols <- cols[phw_contrast(cols) >= 1.3]
  }
  cols
}

# Trace types coloured by a colour scale.
plotly_scale_types <- c("heatmap", "contour", "histogram2d", "histogram2dcontour", "choropleth")

# A trace that maps `color` without `colors` gets plotly's own palette, so
# give it PHW colours: a colour key for groups, and the PHW sequential scale
# for numbers and for heatmaps, contours and choropleths. Every trace takes
# the same key, as plotly colours all traces from the first one's `colors`.
# A trace with its own key, such as one from phw_colour_key(), keeps it, with
# "NA" added in grey when a value is missing.
colour_mapped <- function(p, palette) {
  if (is.null(p$x$attrs)) return(p)
  seq <- palette_colours("blues")
  values <- Map(function(a, id) {
    if (is.null(a$colorscale) && !is.null(a$color)) mapped_values(a$color, p, id)
  }, p$x$attrs, rlang::names2(p$x$attrs))
  own <- vapply(p$x$attrs, function(a) !is.null(a$colors), logical(1))
  keyed <- vapply(p$x$attrs, function(a) is.character(a$colors) && rlang::is_named(a$colors), logical(1))
  missing <- vapply(values, function(v) !is.numeric(v) && anyNA(v), logical(1))
  groups <- Filter(function(v) !is.null(v) && !is.numeric(v), values[!own])
  key <- if (length(groups)) group_colours(groups, palette)
  keyed_na <- any(keyed & missing)
  p$x$attrs <- Map(function(a, v, keyed) {
    if (keyed && keyed_na) {
      if (!"NA" %in% names(a$colors)) a$colors[["NA"]] <- phw_colours[["grey_light"]]
      if (!is.numeric(v) && anyNA(v)) a$color <- na_as_group(a$color)
    }
    if (!is.null(a$colors) || !is.null(a$colorscale)) return(a)
    if (is.null(a$color)) {
      if (isTRUE(a$type %in% plotly_scale_types)) a$colors <- seq
      return(a)
    }
    if (is.null(v)) return(a)
    if (is.numeric(v)) {
      a$colors <- seq
    } else {
      a$colors <- key
      if (anyNA(v)) a$color <- na_as_group(a$color)
    }
    a
  }, p$x$attrs, values, keyed)
  p
}

# A plotly::subplot() figure arrives with its traces built, in plotly's own
# colours, which plotly marks with the classes "colorway" (a trace with no
# colour mapping) and "plotly_default" (group colours and colour scales).
# Give them PHW colours as colour_mapped() does before a build: the colorway
# in trace order, a colour key by trace name and the PHW sequential scale.
# Colours a panel set itself are marked "plotly_default" too, so when any
# panel sets its own, groups and scales keep the colours they were built with.
colour_built <- function(p, palette, colorway) {
  if (!length(p$x$data)) return(p)
  own <- any(vapply(p$x$attrs, sets_colours, logical(1)))
  if (own && any(vapply(p$x$attrs, maps_colours, logical(1)))) {
    cli::cli_inform(c(
      "phw_plotly(): The groups and colour scales of this {.fn plotly::subplot} keep the colours each panel was built with, because a panel sets its own colours.",
      i = "Style each panel with {.fn phw_plotly} before combining them, or give each panel its own {.arg colors}."
    ))
  }
  colorway <- unname(colorway)
  grouped <- !own & vapply(p$x$data, function(t) any(rapply(t, is_group_colour, how = "unlist")), logical(1))
  trace_names <- vapply(p$x$data, function(t) t$name %||% NA_character_, "")
  lv <- unique(trace_names[grouped & !is.na(trace_names)])
  key <- if (length(lv)) group_colours(list(factor(lv, lv)), palette)
  at <- seq(0, 1, length.out = 25)
  scale <- matrix(c(at, plotly::toRGB(scales::col_numeric(palette_colours("blues"), c(0, 1))(at))), ncol = 2)
  p$x$data <- lapply(seq_along(p$x$data), function(i) {
    way <- colorway[[(i - 1) %% length(colorway) + 1]]
    group <- if (grouped[[i]]) if (is.na(trace_names[[i]])) way else key[[trace_names[[i]]]]
    rapply(p$x$data[[i]], function(x) {
      new <- if (inherits(x, "colorway")) {
        plotly::toRGB(way, rgba_alpha(x))
      } else if (!is.null(group) && is_group_colour(x)) {
        plotly::toRGB(group, rgba_alpha(x))
      } else if (!own && is_default(x) && is.matrix(x)) {
        scale
      }
      # plotly reads the class to tell its defaults from colours a user set.
      if (is.null(new)) x else structure(new, class = oldClass(x))
    }, how = "replace")
  })
  p
}

# Whether a trace's attributes set its colours, or map colours from plotly's
# defaults.
sets_colours <- function(a) {
  !is.null(a$colors) || !is.null(a$strokes) || inherits(a$color, "AsIs") || inherits(a$stroke, "AsIs")
}

maps_colours <- function(a) {
  (!is.null(a$color) && !inherits(a$color, "AsIs") && is.null(a$colors)) ||
    (!is.null(a$stroke) && !inherits(a$stroke, "AsIs") && is.null(a$strokes)) ||
    (isTRUE(a$type %in% plotly_scale_types) && is.null(a$colors) && is.null(a$colorscale))
}

is_default <- function(x) inherits(x, "plotly_default") && !inherits(x, "colorway")

# A colour plotly gave a group: one rgba() value marked as its default. A
# missing group is "transparent", and other defaults are titles and numbers.
is_group_colour <- function(x) {
  is_default(x) && is.character(x) && length(x) == 1 && startsWith(x, "rgba(")
}

rgba_alpha <- function(x) as.numeric(sub(".*,\\s*([0-9.]+)\\)$", "\\1", x))

# Colours for groups, named by group, as the PHW ggplot2 scales give them:
# the groups in use, in order, each with its own colour from
# phw_colour_key(), and "NA" in grey when a value is missing.
group_colours <- function(values, palette) {
  lv <- unique(unlist(lapply(values, group_levels)))
  key <- phw_colour_key(lv, palette = palette)
  if (any(vapply(values, anyNA, logical(1)))) key[["NA"]] <- phw_colours[["grey_light"]]
  key
}

# plotly makes missing values transparent, so map them to an "NA" group
# instead, which group_colours() gives a colour.
na_as_group <- function(x) {
  if (!rlang::is_formula(x)) return(na_group(x))
  rlang::new_formula(NULL, rlang::call2(na_group, rlang::f_rhs(x)), env = rlang::f_env(x))
}

na_group <- function(x) {
  lv <- group_levels(x)
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  factor(x, levels = c(lv, "NA"))
}

# The values a plotly attribute maps: a formula of the trace's data, or the
# values themselves. NULL for a constant such as I("red"). Each trace's data
# is stored under the name of its attributes.
mapped_values <- function(x, p, id) {
  if (inherits(x, "AsIs")) return(NULL)
  if (!rlang::is_formula(x)) return(x)
  data <- tryCatch(plotly::plotly_data(p, id), error = function(e) NULL)
  tryCatch(rlang::eval_tidy(rlang::f_rhs(x), data = data, env = rlang::f_env(x)), error = function(e) NULL)
}

# Pie traces ignore colorway, so give them PHW colours unless they set their
# own, by group as in the other charts. A missing label would show as
# "null", so it shows as "NA" in grey, as missing groups do in the charts.
colour_pies <- function(p, palette, colorway) {
  if (is.null(p$x$attrs)) return(p)
  p$x$attrs <- Map(function(a, id) {
    if (identical(a$type, "pie") && is.null(a$marker$colors)) {
      lab <- mapped_values(a$labels, p, id)
      slices <- colorway
      if (!is.null(lab)) {
        key <- group_colours(list(lab), palette)
        if (anyNA(lab)) a$labels <- lab <- as.character(na_group(lab))
        slices <- unname(key[as.character(lab)])
      }
      a$marker <- utils::modifyList(a$marker %||% list(),
                                    list(colors = slices, line = list(color = "#FFFFFF", width = 1.5)))
    }
    a
  }, p$x$attrs, rlang::names2(p$x$attrs))
  p
}
