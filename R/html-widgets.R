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
    booktabs = list(color = col[["navy"]], borderBottom = paste("2px solid", col[["navy"]]),
                    fontWeight = 700),
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
    # The booktabs top rule sits on the table, so it stays above column groups.
    tableStyle = c(if (header == "booktabs") list(borderTop = paste("2px solid", col[["navy"]])),
                   list(borderBottom = paste("2px solid", col[["navy"]]))),
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
#'   Whole numbers show with a thousands separator, except in a year
#'   column: whole numbers from 1800 to 2200 in a column whose name has the
#'   word "year", "yr" or "blwyddyn" in it, such as `Year`, `year_of_onset`
#'   or `Blwyddyn`. These show as 2021, not 2,021.
#'   A column you format yourself in `columns` keeps your format, and a
#'   `format` in `defaultColDef` applies to every column.
#' @param group_col,key,palette Colour the cells of the column `group_col`
#'   (unquoted as in dplyr, or a string) by group, with the same colours as
#'   your charts. `key` and `palette` are
#'   passed to [phw_colour_key()]. On a summary table, only the level rows
#'   are coloured: headings, subtotals and totals are left as they are and
#'   are not added to the key.
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
  data <- check_table_data(data)
  data <- blank_non_finite(data)
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
  base_cols <- list()
  if (inherits(data, "phw_summary")) {
    sm <- summary_reactable_args(data)
    base_cols <- sm$columns
    sm$columns <- NULL
    for (nm in names(sm)) if (is.null(args[[nm]])) args[[nm]] <- sm[[nm]]
    note <- attr(data, "note")
  }
  if (!is.null(group_col)) {
    rows <- heat_rows(data)
    cols <- phw_colour_key(table_group_levels(data[[group_col]][rows], data), name = key, palette = palette)
    under <- base_cols[[group_col]]$style
    style_fun <- function(value, index) {
      st <- if (!is.null(under)) under(value, index)
      bg <- if (index %in% rows) unname(cols[as.character(value)]) else NA
      if (is.na(bg)) return(st)
      c(st, list(background = bg, color = phw_text_on(bg), fontWeight = 500))
    }
    group_def <- stats::setNames(list(reactable::colDef(style = style_fun)), group_col)
    base_cols <- merge_col_defs(base_cols, group_def)
  }
  args$columns <- merge_col_defs(base_cols, args$columns)
  if (inherits(data, "phw_summary")) data <- as.data.frame(unclass(data)[names(data)], check.names = FALSE)
  data <- local_times(data)
  for (nm in names(defaults)) if (is.null(args[[nm]])) args[[nm]] <- defaults[[nm]]
  if (!own_format) args$columns <- with_number_formats(args$columns, data, digits)
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
  years <- names(data)[year_cols(data)]
  for (nm in names(data)[vapply(data, is.numeric, logical(1))]) {
    places <- col_digits(data[[nm]], digits)
    def <- columns[[nm]] %||% reactable::colDef()
    if (is.null(def$format)) {
      fmt <- reactable::colFormat(separators = !nm %in% years, digits = places)
      def$format <- list(cell = fmt, aggregated = fmt)
    }
    columns[[nm]] <- def
  }
  columns
}

# Decimal places for a column, as the renderers show it: none for whole
# numbers, `digits` otherwise.
col_digits <- function(v, digits) {
  if (is.numeric(v) && all(v == round(v), na.rm = TRUE)) 0 else digits
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
#' which is converted with [plotly::ggplotly()] first. A ggplot's subtitle
#' goes under its title. A ggplot that maps the `text` aesthetic shows only
#' that text on hover, as `ggplotly(tooltip = "text")` does.
#'
#' A ggplot's secondary axis, such as one from [phw_sec_axis()], is drawn
#' on the right (or the top), as in the static chart. Hover shows the
#' second measure in the units of the main axis, so map the `text`
#' aesthetic to show it in its own. A faceted chart can't show a secondary
#' axis: `phw_plotly()` warns, and the series is read against the main
#' axis. To combine charts that have one with [plotly::subplot()], pass the
#' combined figure to `phw_plotly()` too, so each axis stays on its own
#' chart.
#'
#' @param p A plotly object or a ggplot.
#' @param source,date Passed to [phw_caption()] and shown under the chart.
#'   When they and `caption_args` give no source line, a ggplot shows its
#'   own caption there, such as one from `labs(caption = phw_caption(...))`.
#' @param legend Where the legend goes: `"bottom"`, `"right"` or `"none"`.
#'   As in plotly, a chart with one trace has no legend; pass
#'   `showlegend = TRUE` to show one.
#' @param palette Colours for traces that don't set their own: a palette
#'   name, a vector of colours or a function of `n`, as in [phw_pal()]. A
#'   trace that maps `color` to groups without giving `colors` takes them
#'   from this palette too, as do the groups of a ggplot with no colour or
#'   fill scale of its own.
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
#'   (which start at the same blue as the ggplot2 charts, not the palest
#'   one, unless you set `colorscale` or `colors`, and draw a missing number
#'   in light grey), and figures combined with
#'   [plotly::subplot()]. Use [phw_plotly_colorscale()] to set a PHW scale on
#'   a trace yourself.
#'
#'   In a [plotly::subplot()] figure, a group has the same colour in every
#'   panel. If a panel sets its own colours with `colors` or `I()`, the group
#'   colours and colour scales stay as each panel was built. To give the
#'   other panels PHW colours, style each panel with `phw_plotly()` before
#'   combining them. Groups of a ggplot in ggplot2's default colours take
#'   the PHW colours too; a ggplot that sets its own colours with a scale,
#'   such as [ggplot2::scale_colour_manual()], keeps them.
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
  subtitle <- NULL
  strip <- 0
  if (inherits(p, "ggplot")) {
    # ggplotly() leaves out the subtitle and the caption.
    cap <- cap %||% label_text(p$labels$caption)
    subtitle <- label_text(p$labels$subtitle)
    p <- ggplotly_phw(p, palette)
    # ggplotly() draws the facet strips above the top panels in pixels.
    strip <- max(0, unlist(lapply(p$x$layout$shapes, function(s) if (identical(s$ysizemode, "pixel")) s$y1)))
  } else {
    p <- tidy_ggplotly(p)
  }
  p <- overlay_own_panel(p)
  col <- phw_colours
  colorway <- plotly_colorway(p, palette)
  font <- list(family = paste0(phw_font(), ", Arial, sans-serif"), size = font_size, color = col[["text"]])
  # An axis `color` colours its title and tick labels without replacing the
  # title text, which a list title would do when plotly merges layouts.
  axis <- list(color = col[["text_secondary"]], gridcolor = col[["grey_border"]],
               zerolinecolor = col[["grey_mid"]], linecolor = col[["grey_mid"]],
               tickfont = list(color = col[["text_secondary"]]))
  # A subplot() figure or a faceted ggplot has an x and a y axis per panel.
  axis_names <- unlist(lapply(c(list(p$x$layout), p$x$layoutAttrs), names))
  axis_names <- unique(c("xaxis", "yaxis", grep("^[xy]axis[0-9]+$", axis_names, value = TRUE)))
  axes <- lapply(rlang::set_names(axis_names), function(a) {
    # ggplotly() gives its axis titles a font colour of their own.
    if (is.list(current_title(p, a))) axis$title <- list(font = list(color = col[["text_secondary"]]))
    axis
  })
  title <- current_title(p)
  if (!is.null(subtitle)) {
    title <- paste(c(title$text, sprintf('<span style="font-size:%gpx;color:%s">%s</span>', font_size,
                                         col[["text_secondary"]], gsub("\n", "<br>", subtitle))),
                   collapse = "<br>")
  }
  # The title is pinned to the top and the plot starts below its last line
  # and the facet strips. A line of the 17px title font takes 22px.
  title_text <- if (is.list(title)) title$text else title
  title_lines <- if (has_text(title_text)) sum(gregexpr("<br|\n", title_text)[[1]] > 0) + 1 else 1
  ann <- if (!is.null(cap)) list(list(
    name = "phw_source", text = paste0("<b>", gsub("\n", "<br>", cap), "</b>"), showarrow = FALSE,
    xref = "paper", yref = "paper", x = 1, y = 0, xanchor = "right", yanchor = "top",
    yshift = if (legend == "bottom") -70 else -40, font = list(size = 11, color = col[["text"]]))) else list()
  base <- list(
    font = font,
    colorway = unname(colorway),
    colorscale = list(sequential = phw_plotly_colorscale(phw_continuous_auto),
                      sequentialminus = phw_plotly_colorscale(phw_continuous_auto),
                      diverging = phw_plotly_colorscale("orange_navy")),
    paper_bgcolor = "#FFFFFF", plot_bgcolor = "#FFFFFF",
    title = c(if (!is.null(title) && !is.list(title)) list(text = title),
              list(font = list(color = col[["navy"]], size = 17), x = 0, xanchor = "left",
                   # plotly.js drops the cap height shift of a title on more
                   # than one line, so its first line needs the 12px back.
                   y = 1, yref = "container", yanchor = "top",
                   pad = list(t = if (title_lines > 1) 26 else 14))),
    legend = if (legend == "bottom") list(orientation = "h", x = 0, y = -0.15, xanchor = "left",
                                          yanchor = "top")
             # ggplotly() places the legend from the theme, so every
             # position field is set, not only the orientation.
             else list(orientation = "v", x = 1.02, y = 1, xanchor = "left", yanchor = "top"),
    hoverlabel = list(bgcolor = col[["navy"]], bordercolor = col[["navy"]],
                      font = list(color = "#FFFFFF", family = font$family)),
    margin = list(b = if (!is.null(cap)) 110 else 60, t = 28 + 22 * title_lines + strip),
    annotations = ann
  )
  base <- c(base, axes)
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
  if (!"colorway" %in% names(extra)) base$colorway <- spare_colorway(base$colorway, p)
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
  grey_missing_numbers(p)
}

# plotly keeps a missing number in a trace's colour array, and plotly.js
# draws it in its near-black fallback colour, which reads as a high value.
# Only built traces hold that array, so a chart coloured by a number with a
# missing value is built here, and built traces, such as a subplot()'s, are
# greyed. The chart stays a plain plotly widget, which htmlwidgets names by
# its first class. A missing heat map cell is a gap that shows the white
# background, which reads as the lowest value, so a grey heat map of the
# missing cells goes under it. The grey layers are made afresh each time, so
# a subplot() of styled charts gets one per heat map, on its new axes.
grey_missing_numbers <- function(p) {
  ids <- rlang::names2(p$x$attrs)
  unbuilt <- vapply(seq_along(p$x$attrs), function(i) {
    a <- p$x$attrs[[i]]
    if (inherits(a, "plotly_eval")) return(FALSE)
    any(vapply(list(a$color, a[["z"]]), function(x) {
      v <- mapped_values(x, p, ids[[i]])
      is.numeric(v) && anyNA(v)
    }, logical(1)))
  }, logical(1))
  if (any(unbuilt)) p <- plotly::plotly_build(p)
  if (length(p$x$data)) {
    data <- Filter(function(t) !identical(t$name, "phw_missing"), p$x$data)
    p$x$data <- unlist(lapply(data, function(t) c(missing_cells(t), list(grey_missing_number(t)))),
                       recursive = FALSE)
  }
  p
}

# A heat map trace, in grey, of the cells `trace` leaves missing, or none.
missing_cells <- function(trace) {
  z <- trace[["z"]]
  if (!identical(trace$type, "heatmap") || !is.numeric(z) || !anyNA(z)) return(list())
  place <- c("x", "y", "x0", "dx", "y0", "dy", "transpose", "xgap", "ygap", "xaxis", "yaxis")
  grey <- phw_colours[["grey_light"]]
  list(c(trace[intersect(place, names(trace))],
         list(type = "heatmap", name = "phw_missing", z = ifelse(is.na(z), 1, NA),
              colorscale = list(list(0, grey), list(1, grey)), showscale = FALSE,
              showlegend = FALSE, hoverinfo = "skip")))
}

grey_missing_number <- function(trace) {
  grey <- function(x) {
    if (!is.numeric(x) || !anyNA(x)) return(x)
    out <- as.list(unclass(x))
    out[is.na(x)] <- phw_colours[["grey_light"]]
    structure(out, class = setdiff(oldClass(x), c("numeric", "integer")))
  }
  if (is.list(trace$marker)) {
    trace$marker$color <- grey(trace$marker$color)
    if (is.list(trace$marker$line)) trace$marker$line$color <- grey(trace$marker$line$color)
  }
  if (is.list(trace$line)) trace$line$color <- grey(trace$line$color)
  trace
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

# A ggplot subtitle or caption as text: NULL when unset or not a
# string, such as a plotmath expression.
label_text <- function(x) if (is.character(x) && has_text(x)) paste(x, collapse = "\n")

# plotly::ggplotly() builds the plot itself and ignores palettes stored in
# the theme (ggplot2 >= 4.0), so add the default scales use_phw_ggplot()
# gives a static chart where the plot has none, with groups taken from
# `palette`.
ggplotly_phw <- function(p, palette) {
  b <- ggplot2::ggplot_build(p)
  has <- vapply(c("colour", "fill"), function(a) !is.null(b$plot$scales$get_scales(a)), logical(1))
  user <- vapply(c("colour", "fill"), function(a) {
    any(vapply(p$scales$scales, function(s) a %in% s$aesthetics, logical(1)))
  }, logical(1))
  for (a in c("colour", "fill")) {
    if (has[[a]] && !user[[a]]) {
      discrete <- b$plot$scales$get_scales(a)$is_discrete()
      p <- p + if (discrete) {
        phw_discrete_scale(a, palette, reverse = FALSE, key = NULL, values = NULL,
                           neutral = character(), na.value = "grey50")
      } else {
        phw_default_scale(a, "continuous")
      }
    }
  }
  keys <- unlist(lapply(b$plot$scales$scales, function(s) {
    if (s$is_discrete() && !any(c("x", "y") %in% s$aesthetics)) as.character(s$get_limits())
  }))
  # A mapped `text` aesthetic is there for the hover, as with
  # ggplotly(tooltip = "text").
  mappings <- c(list(p$mapping), lapply(p$layers, function(l) l$mapping))
  tooltip <- if (any(vapply(mappings, function(m) "text" %in% names(m), logical(1)))) "text" else "all"
  w <- plain_legend(plotly::ggplotly(unrepel(p), tooltip = tooltip), keys)
  w <- secondary_axes(w, b)
  # ggplotly() gives the legend a title even when the theme blanks it.
  if (inherits(ggplot2::calc_element("legend.title", ggplot2::theme_get() + p$theme), "element_blank")) {
    w$x$layout$legend$title <- NULL
  }
  w
}

# ggplotly() drops a secondary axis, which leaves the second series read
# against the main axis. Draw it as a second plotly axis over the main one,
# matched to its range, with the secondary breaks placed in the main axis's
# units as ggplot2 places them. plotly.js draws only an axis a trace is on,
# so an empty trace goes on it. A faceted chart has one plotly axis per
# panel, which this does not cover.
secondary_axes <- function(w, b) {
  panels <- b$layout$panel_params
  for (a in c("x", "y")) {
    view <- panels[[1]][[paste0(a, ".sec")]]
    if (!inherits(view$scale$secondary.axis, "AxisSecondary")) next
    if (length(panels) > 1) {
      cli::cli_warn(c(
        "{.fn phw_plotly} can't show the secondary axis of a faceted chart.",
        i = "Its series are read against the main axis. Combine one chart per panel with {.code phw_plotly(plotly::subplot(...))} instead."
      ))
      next
    }
    breaks <- view$get_breaks()
    keep <- !is.na(breaks)
    title <- b$layout$resolve_label(view$scale, b$plot$labels)$secondary
    axis <- w$x$layout[[paste0(a, "axis")]]
    axis[c("range", "domain", "categoryorder", "categoryarray")] <- NULL
    axis$title$text <- if (is.character(title)) paste(title, collapse = "\n") else ""
    w$x$layout[[paste0(a, "axis2")]] <- utils::modifyList(axis, list(
      overlaying = a, matches = a, anchor = if (a == "y") "x" else "y",
      side = if (a == "y") "right" else "top", tickmode = "array",
      tickvals = breaks[keep], ticktext = as.character(view$get_labels()[keep]),
      showgrid = FALSE, zeroline = FALSE, automargin = TRUE
    ))
    trace <- list(type = "scatter", mode = "lines", x = list(), y = list(),
                  showlegend = FALSE, hoverinfo = "skip")
    trace[[paste0(a, "axis")]] <- paste0(a, "2")
    w$x$data <- c(w$x$data, list(trace))
  }
  w
}

# plotly::subplot() renames each chart's axes but leaves an axis drawn over
# another, such as a ggplot's secondary axis, over the first chart's axis.
# Put it back over the main axis of its own chart: the one it is anchored
# with.
overlay_own_panel <- function(p) {
  l <- p$x$layout
  axes <- grep("^[xy]axis[0-9]*$", names(l), value = TRUE)
  for (nm in axes) {
    ax <- l[[nm]]
    if (!is.character(ax$overlaying) || !is.character(ax$anchor)) next
    main <- Filter(function(m) {
      substr(m, 1, 1) == substr(nm, 1, 1) && is.null(l[[m]]$overlaying) && identical(l[[m]]$anchor, ax$anchor)
    }, axes)
    if (!length(main)) next
    ref <- sub("axis", "", main[[1]])
    if (identical(ax$matches, ax$overlaying)) l[[nm]]$matches <- ref
    l[[nm]]$overlaying <- ref
  }
  p$x$layout <- l
  p
}

# plotly drops ggrepel labels with a warning of its own, and it has no
# geom_label() either, so draw them as plain text. Copies of the layers keep
# the user's plot as it was.
unrepel <- function(p) {
  p$layers <- lapply(p$layers, function(l) {
    if (!inherits(l$geom, c("GeomTextRepel", "GeomLabelRepel"))) return(l)
    ggplot2::ggproto(NULL, l, geom = GeomPhwPlotlyText)
  })
  p
}

GeomPhwPlotlyText <- ggplot2::ggproto("GeomPhwPlotlyText", ggplot2::GeomText)

# plotly centres text on its point whatever its hjust and vjust, which would
# put a label such as phw_funnel()'s over its marker.
#' @exportS3Method plotly::geom2trace
geom2trace.GeomPhwPlotlyText <- function(data, params, p) {
  class(data)[1] <- "GeomText"
  trace <- plotly::geom2trace(data, params, p)
  trace$textposition <- paste(ifelse(data$vjust < 0.5, "top", ifelse(data$vjust > 0.5, "bottom", "middle")),
                              ifelse(data$hjust < 0.5, "right", ifelse(data$hjust > 0.5, "left", "center")))
  trace
}

# ggplotly() names a trace by every discrete legend scale of the plot. A
# layer without one of them, such as the line next to filled bars, gets its
# panel number in that place: "(A,1)". Name such a trace by its group, as
# the static legend does, and show each group in the legend once, by a
# trace that was named plainly when there is one: a forest plot's points
# and their shapes rather than the error bars.
plain_legend <- function(p, keys) {
  traces <- p$x$data
  renamed <- logical(length(traces))
  for (i in seq_along(traces)) {
    nm <- traces[[i]]$name
    if (is.null(nm) || !grepl("^\\(.*\\)$", nm)) next
    inner <- substr(nm, 2, nchar(nm) - 1)
    core <- sub("(,[0-9]+)+$", "", inner)
    rest <- strsplit(substring(inner, nchar(core) + 2), ",", fixed = TRUE)[[1]]
    if (core %in% keys && !any(rest %in% keys)) {
      traces[[i]]$name <- traces[[i]]$legendgroup <- core
      renamed[i] <- TRUE
    }
  }
  if (!any(renamed)) return(p)
  shown <- vapply(traces, function(t) isTRUE(t$showlegend), logical(1))
  group <- vapply(traces, function(t) t$legendgroup %||% NA_character_, "")
  for (g in unique(group[renamed])) {
    idx <- which(group == g & shown)
    keep <- c(idx[!renamed[idx]], idx)[1]
    for (i in setdiff(idx, keep)) traces[[i]]$showlegend <- FALSE
  }
  p$x$data <- traces
  p
}

# A chart made with ggplotly() comes without its ggplot, but its `attrs` keep
# each layer's mapping and `visdat` the layer's data. Give it the legend
# names and the hover that phw_plotly() gives the ggplot.
tidy_ggplotly <- function(p) {
  legend_aes <- c("colour", "fill", "shape", "linetype", "linewidth", "size", "alpha")
  keys <- unlist(lapply(ggplotly_values(p, legend_aes), function(v) {
    if (is.factor(v)) levels(v) else if (is.character(v) || is.logical(v)) unique(as.character(v))
  }))
  texts <- unlist(lapply(ggplotly_values(p, "text"), format, justify = "none"))
  text_hover(plain_legend(p, keys), unique(texts))
}

ggplotly_values <- function(p, aes) {
  unlist(lapply(names(p$x$attrs), function(id) {
    a <- p$x$attrs[[id]]
    data <- p$x$visdat[[id]]
    if (!inherits(a, "plotly_eval") || !is.function(data)) return(NULL)
    data <- data()
    lapply(a[intersect(names(a), aes)], function(f) {
      if (rlang::is_formula(f)) tryCatch(rlang::eval_tidy(rlang::f_rhs(f), data), error = function(e) NULL)
    })
  }), recursive = FALSE)
}

# ggplotly() puts every aesthetic in the hover unless it is given
# `tooltip = "text"`: "x: -5<br />sex: Female<br />Female, 0-4: 5". The
# mapped text is the one line without a name in front. When the hover holds
# it and more, show only the text, and no hover on layers without one, as
# for a ggplot that maps `text`. A text layer's own `text` is its label.
text_hover <- function(p, texts) {
  if (!length(texts)) return(p)
  field <- vapply(p$x$data, function(t) {
    if ("hovertext" %in% names(t) || grepl("text", t$mode %||% "")) "hovertext" else "text"
  }, "")
  hover <- Map(function(t, f) if (is.character(t[[f]]) && !identical(t$hoverinfo, "skip")) t[[f]], p$x$data, field)
  shown <- lapply(hover, function(h) {
    if (is.null(h)) return(NULL)
    seg <- strsplit(h, "<br />", fixed = TRUE)
    line <- rep(seq_along(seg), lengths(seg))
    seg <- unlist(seg)
    hit <- which(seg %in% texts)
    hit <- hit[!duplicated(line[hit])]
    out <- rep("", length(h))
    out[line[hit]] <- seg[hit]
    ifelse(h %in% texts, h, out)
  })
  cut <- any(unlist(Map(function(h, s) !is.null(h) && any(s != "" & s != h), hover, shown)))
  if (!cut) return(p)
  for (i in which(!vapply(shown, is.null, logical(1)))) p$x$data[[i]][[field[[i]]]] <- shown[[i]]
  p
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
  levels <- summary_header_levels(x, nl)
  groups <- NULL
  if (length(hd$upper)) {
    # reactable has one level of column groups: group by the lowest upper
    # level and name each group by every upper level.
    level <- hd$upper[[length(hd$upper)]]
    groups <- lapply(seq_len(nrow(level)), function(g) {
      idx <- level$start[g] + seq_len(level$n[g]) - 1
      name <- if (level$total[g]) "" else paste(Filter(nzchar, levels[-nrow(levels), idx[1]]), collapse = " \u00b7 ")
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
#'   the column's largest value. Good for counts and rates. On a summary
#'   table, only the level rows get bars: headings, subtotals and totals
#'   show the number only and stay out of the scale.
#' * `phw_col_heat()`: cell background from a sequential or diverging
#'   palette, with readable text. On a summary table, only the level rows
#'   are coloured: headings, subtotals and totals keep their own styling and
#'   stay out of the colour scale.
#' * `phw_col_rag()`: red, amber or green cells with a shape, so status
#'   doesn't rely on colour alone. Give it the table as `data` and, on a
#'   summary table, only the level rows are coloured, as with the heat
#'   column.
#' * `phw_col_number()` and `phw_col_percent()`: thousands separators and
#'   fixed decimals.
#'
#' @param data The data frame. Bar and heat columns need it to find the
#'   range. `phw_col_rag()` uses it, when given, to leave the headings,
#'   subtotals and totals of a summary table uncoloured and to pick the
#'   decimal places.
#' @param column The column, unquoted as in dplyr. A string works too.
#' @param colour Bar colour.
#' @param palette Palette name or vector of colours.
#' @param domain Range for the heat colours. Defaults to the range of the
#'   coloured cells. Values beyond it take the colour at the nearer end.
#' @param breaks,higher_is_better See [phw_flextable_heat()].
#' @param rag_palette `"rag"` or `"rag_accessible"`.
#' @param digits Decimal places. Heat and RAG columns follow the table by
#'   default: none for whole numbers, otherwise the summary table's own
#'   `digits`, or 1.
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
  rows <- heat_rows(data)
  if (!length(value_cols(data[rows, , drop = FALSE], column, "column"))) return(reactable::colDef(align = "right", ...))
  check_bar_values(data[[column]][rows], column, "column")
  mx <- max(data[[column]][rows], na.rm = TRUE)
  reactable::colDef(
    align = "left",
    cell = function(value, index) {
      if (is.na(value)) return("")
      w <- if (mx > 0 && index %in% rows) paste0(round(100 * value / mx, 1), "%") else "0%"
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
  if (missing(digits)) digits <- col_digits(data[[column]], attr(data, "digits") %||% digits)
  fmt <- reactable::colFormat(separators = TRUE, digits = digits)
  rows <- heat_rows(data)
  if (!length(value_cols(data[rows, , drop = FALSE], column, "column"))) return(reactable::colDef(format = fmt, ...))
  fill <- heat_fill(palette, domain %||% range(data[[column]][rows], na.rm = TRUE))
  reactable::colDef(
    format = fmt,
    style = function(value, index) {
      if (is.na(value) || !index %in% rows) return(NULL)
      bg <- fill(value)
      list(background = bg, color = phw_text_on(bg))
    }, ...)
}

#' @rdname phw_reactable_columns
#' @export
phw_col_rag <- function(breaks, higher_is_better = TRUE, rag_palette = "rag_accessible",
                        digits = 1, data = NULL, ...) {
  rlang::check_installed("reactable")
  if (missing(breaks)) breaks <- NULL
  check_breaks(breaks)
  rag_palette <- rlang::arg_match(rag_palette, c("rag_accessible", "rag"))
  if (!is.null(data) && !is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame, not {.obj_type_friendly {data}}.")
  }
  pal <- phw_palettes[[rag_palette]]
  shapes <- c(red = "\u25BC", amber = "\u25A0", green = "\u25B2")
  status <- function(v) rag_status(v, breaks, higher_is_better)
  rows <- if (is.null(data)) NULL else heat_rows(data)
  coloured <- function(value, index) !is.na(value) && (is.null(rows) || index %in% rows)
  # reactable passes each cell its column name, so the places can follow
  # that column of `data`.
  places <- function(name) digits
  if (missing(digits) && !is.null(data)) {
    digits <- attr(data, "digits") %||% digits
    places <- function(name) col_digits(data[[name]], digits)
  }
  reactable::colDef(
    align = "right",
    cell = function(value, index, name) {
      if (is.na(value)) return("")
      txt <- fmt_num(value, places(name))
      if (coloured(value, index)) paste(shapes[[status(value)]], txt) else txt
    },
    style = function(value, index) {
      if (!coloured(value, index)) return(NULL)
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
  check_whole_number(n, 2)
  cols <- if (is.function(palette)) {
    phw_pal(n, palette, reverse = reverse)
  } else {
    grDevices::colorRampPalette(seq_cols(palette, reverse), space = "Lab")(n)
  }
  lapply(seq_len(n), function(i) list((i - 1) / (n - 1), cols[i]))
}

# The colours plotly gives traces in turn: trace i takes colour i, counting
# every trace. "main" needs the rest of "extended" behind it for charts with
# more than six traces. A function palette, or "highlight", is asked for as
# many colours as there are traces. Sequential and diverging palettes drop
# their near-white steps, which vanish on white, and spread what is left over
# the traces.
plotly_colorway <- function(p, palette) {
  per_trace <- is.function(palette) || identical(palette, "highlight")
  if (!per_trace && !is_ramp(palette)) {
    return(palette_colours(palette_for(palette, Inf)))
  }
  # plotly repeats its notes about the chart when it is printed.
  built <- suppressMessages(suppressWarnings(plotly::plotly_build(p)))
  n <- max(length(built$x$data), 1)
  if (per_trace) return(phw_pal(n, palette))
  cols <- palette_colours(palette)
  phw_pal(n, cols[phw_contrast(cols) >= 1.3], type = "sequential")
}

# Trace types coloured by a colour scale.
plotly_scale_types <- c("heatmap", "contour", "histogram2d", "histogram2dcontour", "choropleth")

# A trace that maps `color` without `colors` gets plotly's own palette, so
# give it PHW colours: a colour key for groups, and the continuous colours of
# the ggplot2 charts for numbers and for heatmaps, contours and choropleths.
# Every trace takes the same key, and a trace with no `colors` takes those of
# the first trace that has them, as plotly colours all traces from the first
# one's.
# A trace with its own `colors`, such as phw_colour_key() or phw_pal(), keeps
# them, with "NA" added in grey when a value is missing.
# A subplot()'s traces are already built and colour_built() colours them.
colour_mapped <- function(p, palette) {
  todo <- unbuilt_attrs(p)
  if (!any(todo)) return(p)
  attrs <- p$x$attrs[todo]
  values <- Map(function(a, id) {
    if (is.null(a[["colorscale"]]) && !is.null(a[["color"]])) mapped_values(a[["color"]], p, id)
  }, attrs, rlang::names2(attrs))
  missing <- vapply(values, function(v) !is.numeric(v) && anyNA(v), logical(1))
  if (any(missing)) {
    groups <- Filter(function(v) !is.null(v) && !is.numeric(v), values)
    attrs <- lapply(attrs, function(a) {
      if (!is.null(a[["colors"]]) && !rlang::is_named(a[["colors"]])) a[["colors"]] <- colours_by_group(a[["colors"]], groups)
      a
    })
  }
  own <- vapply(attrs, function(a) !is.null(a[["colors"]]), logical(1))
  keyed <- vapply(attrs, function(a) is.character(a[["colors"]]) && rlang::is_named(a[["colors"]]), logical(1))
  groups <- Filter(function(v) !is.null(v) && !is.numeric(v), values[!own])
  key <- if (length(groups)) group_colours(groups, palette)
  keyed_na <- any(keyed & missing)
  attrs <- Map(function(a, v, keyed) {
    if (keyed && keyed_na) {
      if (!"NA" %in% names(a[["colors"]])) a[["colors"]][["NA"]] <- phw_colours[["grey_light"]]
      if (!is.numeric(v) && anyNA(v)) a[["color"]] <- na_as_group(a[["color"]])
    }
    if (!is.null(a[["colors"]]) || !is.null(a[["colorscale"]])) return(a)
    if (is.null(a[["color"]])) {
      if (isTRUE(a[["type"]] %in% plotly_scale_types)) a[["colors"]] <- phw_continuous_auto
      return(a)
    }
    if (is.null(v)) return(a)
    if (is.numeric(v)) {
      a[["colors"]] <- phw_continuous_auto
    } else {
      a[["colors"]] <- key
      if (anyNA(v)) a[["color"]] <- na_as_group(a[["color"]])
    }
    a
  }, attrs, values, keyed)
  shared <- Find(Negate(is.null), lapply(attrs, `[[`, "colors"))
  if (!is.null(shared)) {
    attrs <- lapply(attrs, function(a) {
      if (is.null(a[["colors"]])) a[["colors"]] <- shared
      a
    })
  }
  p$x$attrs[todo] <- attrs
  p
}

# plotly spreads unnamed `colors`, such as phw_pal() or a palette name, over
# the groups as below. Naming each colour by its group lets a missing group
# be added in grey.
colours_by_group <- function(colors, values) {
  all <- unlist(values)
  lv <- if (is.factor(all)) levels(all) else sort(unique(all))
  stats::setNames(scales::col_factor(colors, levels = lv)(lv), lv)
}

# The attributes plotly has yet to evaluate. A built figure, such as a
# subplot()'s, marks its attributes "plotly_eval" and keeps no data to
# evaluate them with, so a formula would be evaluated in its environment.
unbuilt_attrs <- function(p) {
  !vapply(p$x$attrs, inherits, logical(1), "plotly_eval")
}

# A trace that maps no colour takes the colorway colour of its place among
# all traces, so a line drawn before the groups would take the first group's
# colour. Leave the colours of the groups' key out of the colorway while any
# are left.
spare_colorway <- function(colorway, p) {
  key <- Find(Negate(is.null), lapply(p$x$attrs, `[[`, "colors"))
  if (!is.character(key) || !rlang::is_named(key)) return(colorway)
  spare <- colorway[!toupper(colorway) %in% toupper(key)]
  if (length(spare)) spare else colorway
}

# A plotly::subplot() figure arrives with its traces built, in plotly's own
# colours, which plotly marks with the classes "colorway" (a trace with no
# colour mapping) and "plotly_default" (group colours and colour scales).
# Give them PHW colours as colour_mapped() does before a build: the colorway
# in trace order, a colour key by trace name, grey for a missing group and
# the PHW sequential scale. Colours a panel set itself are marked
# "plotly_default" too, so when any panel sets its own, groups and scales
# keep the colours they were built with, and only a missing group turns grey. A ggplot's groups come unmarked, in
# ggplot2's default colours, and take the colour key too.
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
  coloured <- vapply(p$x$data, function(t) any(rapply(t, is_group_colour, how = "unlist")), logical(1))
  grouped <- !own & coloured
  panel <- vapply(p$x$data, function(t) paste(t$xaxis %||% "x", t$yaxis %||% "y"), "")
  trace_names <- vapply(p$x$data, function(t) t$name %||% NA_character_, "")
  # A panel's own colours leave its missing group transparent as well, in a
  # trace named NA.
  na_named <- vapply(p$x$data, function(t) identical(t$name, NA_character_) || identical(t$name, "NA"), logical(1))
  missing <- (!own | na_named) &
    vapply(p$x$data, function(t) any(rapply(t, is_missing_colour, how = "unlist")), logical(1))
  gg <- ggplot_groups(p$x$data, panel)
  lv <- unique(c(trace_names[grouped & !is.na(trace_names)], gg))
  key <- if (length(lv)) group_colours(list(factor(lv, lv)), palette)
  at <- seq(0, 1, length.out = 25)
  scale <- matrix(c(at, plotly::toRGB(scales::col_numeric(phw_continuous_auto, c(0, 1))(at))), ncol = 2)
  gradient <- if (uses_ggplot_gradient(p$x$data)) ggplot_gradient()
  p$x$data <- lapply(seq_along(p$x$data), function(i) {
    if (missing[[i]]) {
      like <- p$x$data[coloured & panel == panel[[i]]]
      return(grey_missing(p$x$data[[i]], if (length(like)) like[[1]]))
    }
    way <- colorway[[(i - 1) %% length(colorway) + 1]]
    group <- if (grouped[[i]]) if (is.na(trace_names[[i]])) way else key[[trace_names[[i]]]]
    rapply(p$x$data[[i]], function(x) {
      new <- if (inherits(x, "colorway")) {
        plotly::toRGB(way, rgba_alpha(x))
      } else if (!is.null(group) && !own && is_group_colour(x)) {
        plotly::toRGB(group, rgba_alpha(x))
      } else if (is_plain_rgba(x) && !is.na(gg[paste(panel[[i]], rgb_of(x))])) {
        plotly::toRGB(key[[gg[[paste(panel[[i]], rgb_of(x))]]]], rgba_alpha(x))
      } else if (!own && is_default(x) && is.matrix(x)) {
        scale
      } else if (!is.null(gradient)) {
        regradient(x, gradient)
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

is_missing_colour <- function(x) is_default(x) && identical(unclass(x), "transparent")

# ggplotly() builds a ggplot without the palette its theme sets, so its
# groups come out in ggplot2's default hue colours, with no class: plotly
# marks only the colours it picks itself. The trace name is not the colour
# group: a trace split by colour and shape is named "(A,1)". A panel holds
# one ggplot, in which each hue colour is one colour level, so group by
# panel and hue colour, and name the group by the part every one of its
# trace names shares, for the same group in other panels to match. Returns
# the group names, keyed by panel and hue colour.
ggplot_groups <- function(traces, panel) {
  plain <- lapply(traces, function(t) unique(rgb_of(unlist(rapply(t, function(x) if (is_plain_rgba(x)) unclass(x), how = "list")))))
  hue <- ggplot_hue(length(unique(unlist(plain))))
  rows <- do.call(rbind, Map(function(cols, pn, nm) {
    cols <- intersect(cols, hue)
    data.frame(id = paste(rep(pn, length(cols)), cols), panel = rep(pn, length(cols)), name = rep(nm, length(cols)))
  }, plain, panel, vapply(traces, function(t) t$name %||% NA_character_, "")))
  if (is.null(rows) || !nrow(rows)) return(character())
  ids <- unique(rows$id)
  labels <- vapply(ids, function(id) shared_name(rows$name[rows$id == id]), "")
  pn <- rows$panel[match(ids, rows$id)]
  clash <- !is.na(labels) & (duplicated(paste(pn, labels)) | duplicated(paste(pn, labels), fromLast = TRUE))
  labels[is.na(labels) | clash] <- paste0("\u001f", ids[is.na(labels) | clash])
  labels
}

# The one value all of a group's trace names share, where ggplotly() names a
# trace split by more than one legend "(A,1)", or NA.
shared_name <- function(names) {
  names <- unique(names[!is.na(names)])
  if (!length(names)) return(NA_character_)
  tuple <- grepl("^\\(.*\\)$", names)
  parts <- lapply(seq_along(names), function(j) {
    if (tuple[[j]]) strsplit(substr(names[[j]], 2, nchar(names[[j]]) - 1), ",", fixed = TRUE)[[1]] else names[[j]]
  })
  common <- Reduce(intersect, parts)
  if (length(common) == 1) common else NA_character_
}

# The colours ggplot2's default scale gives up to n groups.
ggplot_hue <- function(n) {
  unique(unlist(lapply(seq_len(n), function(k) rgb_of(plotly::toRGB(scales::hue_pal()(k))))))
}

# ggplotly() skips the continuous palette a theme sets too, so a number
# comes out in ggplot2's default gradient, from #132B43 for low values to
# #56B1F7 for high ones: hex colours in a colour scale and rgba() colours on
# the marks, with no class. Nothing else says where on the scale a colour
# sits, so look each one up on the gradient and give it the PHW colour at
# the same place. Other scales cross the gradient too (PHW's own "gradient"
# palette does near #326791), so only a figure that holds both ends of the
# gradient, as the default scale gives its lowest and highest values, is
# recoloured. A colour more than one step off the gradient is kept.
ggplot_gradient <- function() {
  at <- seq(0, 1, length.out = 1001)
  list(from = grDevices::col2rgb(scales::seq_gradient_pal("#132B43", "#56B1F7")(at)),
       to = scales::gradient_n_pal(phw_continuous_auto)(at))
}

uses_ggplot_gradient <- function(data) {
  cols <- unique(unlist(rapply(data, plain_colours, how = "list")))
  rgb <- colour_rgb(cols)
  ends <- grDevices::col2rgb(c("#132B43", "#56B1F7"))
  all(apply(ends, 2, function(end) any(colSums(rgb == end) == 3)))
}

regradient <- function(x, gradient) {
  cols <- plain_colours(x)
  if (!length(cols)) return(NULL)
  rgb <- colour_rgb(cols)
  new <- vapply(seq_along(cols), function(i) {
    off <- abs(gradient$from - rgb[, i])
    near <- which(colSums(off > 1) == 0)
    if (!length(near)) return(NA_character_)
    to <- gradient$to[[near[which.min(colSums(off[, near, drop = FALSE]))]]]
    if (startsWith(cols[[i]], "#")) to else plotly::toRGB(to, rgba_alpha(cols[[i]]))
  }, "")
  swap <- stats::setNames(new, cols)[!is.na(new)]
  hit <- x %in% names(swap)
  if (!any(hit)) return(NULL)
  x[hit] <- unname(swap[x[hit]])
  x
}

# The unclassed hex and rgba() colours in a value, and their red, green and
# blue, one column each.
plain_colours <- function(x) {
  if (!is.character(x) || !is.null(oldClass(x))) return(character())
  unique(x[grepl("^(rgba\\(|#[0-9A-Fa-f]{6}$)", x)])
}

colour_rgb <- function(cols) {
  vapply(cols, function(col) {
    if (startsWith(col, "#")) as.numeric(grDevices::col2rgb(col))
    else as.numeric(strsplit(gsub("^rgba\\(|\\)$", "", col), ",")[[1]][1:3])
  }, numeric(3), USE.NAMES = FALSE)
}

is_plain_rgba <- function(x) {
  is.character(x) && length(x) == 1 && is.null(oldClass(x)) && isTRUE(startsWith(x, "rgba("))
}

rgb_of <- function(x) sub(",[^,]*\\)$", "", x)

# Grey for a missing group's "transparent" colours, each with the alpha a
# group in the same panel has in the same slot, as plotly fills at a lower
# alpha than it draws lines.
grey_missing <- function(trace, like) {
  alphas <- if (!is.null(like)) unlist(rapply(like, function(x) if (is_group_colour(x)) rgba_alpha(x), how = "list"))
  walk <- function(x, path) {
    if (is.list(x)) {
      x[] <- Map(function(el, nm) walk(el, c(path, nm)), x, rlang::names2(x))
      return(x)
    }
    if (!is_missing_colour(x)) return(x)
    slot <- paste(path, collapse = ".")
    alpha <- if (slot %in% names(alphas)) alphas[[slot]] else 1
    structure(plotly::toRGB(phw_colours[["grey_light"]], alpha), class = oldClass(x))
  }
  walk(trace, NULL)
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
# own, by group as in the other charts. All pies in a figure share one key,
# so a label has one colour in every pie. A missing label would show as
# "null", so it shows as "NA" in grey, as missing groups do in the charts.
colour_pies <- function(p, palette, colorway) {
  pie <- unbuilt_attrs(p) &
    vapply(p$x$attrs, function(a) identical(a$type, "pie") && is.null(a$marker$colors), logical(1))
  if (!any(pie)) return(p)
  labels <- Map(function(a, id, pie) if (pie) mapped_values(a$labels, p, id),
                p$x$attrs, rlang::names2(p$x$attrs), pie)
  used <- Filter(Negate(is.null), labels)
  key <- if (length(used)) group_colours(used, palette)
  p$x$attrs <- Map(function(a, lab, pie) {
    if (!pie) return(a)
    slices <- colorway
    if (!is.null(lab)) {
      if (anyNA(lab)) a$labels <- lab <- as.character(na_group(lab))
      slices <- unname(key[as.character(lab)])
    }
    a$marker <- utils::modifyList(a$marker %||% list(),
                                  list(colors = slices, line = list(color = "#FFFFFF", width = 1.5)))
    a
  }, p$x$attrs, labels, pie)
  p
}
