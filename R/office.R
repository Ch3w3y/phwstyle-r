#' Interactive tables with DT
#'
#' Builds a [DT::datatable()] in the PHW style: PHW font, navy header, light
#' row lines, thousands separators, and a title and source line. Useful in
#' Shiny apps and HTML reports when readers need to search, sort or page
#' through a long table. A summary table (see [phw_summary_table()],
#' [phw_group_table()] and [phw_as_summary()]) looks as it does in
#' [phw_gt()] and [phw_reactable()]: shaded variable rows with navy labels,
#' indented levels, total rows, the header spanning the group columns and
#' right-aligned statistics. It is shown whole, without sorting or paging.
#'
#' @param data A data frame, or a `phw_summary` table.
#' @param caption Title shown above the table.
#' @param source,date Passed to [phw_caption()] and shown under the table.
#' @param caption_args List of other [phw_caption()] arguments.
#' @param digits Decimal places for non-integer numbers.
#' @param page_length Rows per page.
#' @param options List of DataTables options, merged with the defaults.
#' @param ... Passed to [DT::datatable()], e.g. `filter = "top"`.
#' @return A DT htmlwidget (wrapped with the title and source when given).
#' @examples
#' if (requireNamespace("DT", quietly = TRUE)) {
#'   tbl <- phw_datatable(mtcars, caption = "Example table", source = "mtcars")
#'   # Printing shows the table in the Viewer or a browser.
#'   if (interactive()) print(tbl)
#' }
#' @export
phw_datatable <- function(data, caption = NULL, source = NULL, date = NULL, digits = 1,
                          page_length = 10, options = list(), caption_args = list(), ...) {
  rlang::check_installed("DT")
  check_unique_names(data)
  sm <- NULL
  note <- NULL
  if (inherits(data, "phw_summary")) {
    sm <- summary_dt_parts(data)
    note <- attr(data, "note")
    data <- sm$data
  }
  data <- as.data.frame(data)
  defaults <- if (is.null(sm)) {
    list(pageLength = page_length, dom = "ftip")
  } else {
    list(paging = FALSE, ordering = FALSE, dom = "t", columnDefs = sm$column_defs)
  }
  opts <- utils::modifyList(c(defaults, list(autoWidth = FALSE, language = list(search = "Search:"))), options)
  args <- list(data = data, rownames = FALSE, class = "phw-dt compact hover", options = opts, style = "default")
  if (!is.null(sm$container)) args$container <- sm$container
  args <- utils::modifyList(args, list(...))
  w <- do.call(DT::datatable, args)
  num <- setdiff(names(data)[vapply(data, is.numeric, logical(1))], sm$helper)
  is_int <- vapply(data[num], function(v) all(v == round(v), na.rm = TRUE), logical(1))
  if (any(is_int)) w <- DT::formatRound(w, num[is_int], digits = 0)
  if (any(!is_int)) w <- DT::formatRound(w, num[!is_int], digits = digits)
  if (!is.null(sm)) w <- style_summary_dt(w, sm)
  w$dependencies <- c(w$dependencies, list(phw_font_dependency(), phw_dt_css()))
  wrap_widget(w, caption, caption_from(source, date, caption_args), note)
}

# Each row is styled through a hidden column holding its row number, which
# formatStyle() reads, so the styles stay with their rows when sorted.
summary_dt_parts <- function(x) {
  nl <- attr(x, "label_cols") %||% 1L
  df <- as.data.frame(unclass(x)[names(x)], check.names = FALSE)
  nc <- ncol(df)
  df$.phw_row <- seq_len(nrow(df))
  defs <- list(list(visible = FALSE, targets = nc))
  if (nc > nl) defs <- c(defs, list(list(className = "dt-right", targets = seq(nl, nc - 1))))
  list(data = df, rows = summary_rows(x), helper = ".phw_row", column_defs = defs,
       labels = names(df)[seq_len(nl)], container = summary_dt_header(x, nl))
}

# The header rows above the column names of a summary table: its spanner,
# or the upper levels of a multi-level header (years above quarters). Each
# level is a data frame of runs, giving a label, its first data column and
# how many columns it spans. `bottom` holds the column names to show.
summary_header <- function(x, nl) {
  ch <- attr(x, "col_header")
  sp <- attr(x, "spanner")
  data_names <- names(x)[-seq_len(nl)]
  if (is.null(ch)) {
    upper <- if (!is.null(sp) && length(data_names)) list(data.frame(label = sp, start = 1L, n = length(data_names)))
    return(list(upper = upper, bottom = data_names))
  }
  L <- nrow(ch)
  upper <- lapply(seq_len(L - 1), function(l) {
    key <- apply(ch[seq_len(l), , drop = FALSE], 2, paste, collapse = "\r")
    n <- rle(key)$lengths
    start <- cumsum(n) - n + 1
    # A grand total column has the same label at every level: show it once.
    total <- vapply(seq_along(n), function(g) all(ch[, start[g] + seq_len(n[g]) - 1] == ch[L, start[g]]), logical(1))
    data.frame(label = ifelse(total, "", ch[l, start]), start = start, n = n)
  })
  list(upper = upper, bottom = ch[L, ])
}

summary_dt_header <- function(x, nl) {
  hd <- summary_header(x, nl)
  if (!length(hd$upper) && identical(hd$bottom, names(x)[-seq_len(nl)])) return(NULL)
  th <- htmltools::tags$th
  span <- length(hd$upper) + 1
  upper <- lapply(hd$upper, function(level) {
    lapply(seq_len(nrow(level)), function(g) {
      th(level$label[g], colspan = level$n[g], class = if (nzchar(level$label[g])) "phw-spanner" else "phw-blank")
    })
  })
  labels <- lapply(names(x)[seq_len(nl)], th, rowspan = span, class = "phw-label")
  rows <- c(list(c(labels, upper[[1]], list(th(".phw_row", rowspan = span)))), upper[-1],
            list(lapply(hd$bottom, th)))
  htmltools::tags$table(htmltools::tags$thead(lapply(rows, htmltools::tags$tr)))
}

style_summary_dt <- function(w, sm) {
  r <- sm$rows
  col <- phw_colours
  all_cols <- setdiff(names(sm$data), sm$helper)
  style <- function(w, cols, rows, ...) {
    if (!length(rows)) return(w)
    css <- lapply(list(...), function(v) DT::styleEqual(rows, v))
    do.call(DT::formatStyle, c(list(w, cols, valueColumns = sm$helper), css))
  }
  w <- style(w, all_cols, which(r$bold), fontWeight = "700")
  w <- style(w, all_cols, which(r$shade), backgroundColor = col[["grey_bg"]])
  w <- style(w, all_cols, which(r$space), paddingTop = "14px")
  rules <- c(which(r$rule), which(r$line))
  w <- style(w, all_cols, rules, borderTop = c(rep(paste("2px solid", col[["navy"]]), sum(r$rule)),
                                              rep(paste("1px solid", col[["grey_mid"]]), sum(r$line))))
  w <- style(w, sm$labels, which(r$navy), color = col[["navy"]])
  w <- style(w, sm$labels, which(r$italic), fontStyle = "italic")
  indented <- which(r$indent > 0)
  style(w, sm$labels[1], indented, paddingLeft = paste0(8 + 14 * r$indent[indented], "px"))
}

phw_dt_css <- function() {
  col <- phw_colours
  css <- sprintf(paste0(
    "table.phw-dt.dataTable {font-family: %1$s, Arial, sans-serif; font-size: 14px; color: %2$s;",
    "border-collapse: collapse;}",
    "table.phw-dt.dataTable thead th {color: %3$s; border-bottom: 2px solid %3$s; font-weight: 700;",
    "vertical-align: bottom;}",
    "table.phw-dt.dataTable thead tr:first-child th {border-top: 2px solid %3$s;}",
    "table.phw-dt.dataTable thead th.phw-spanner {text-align: center; border-bottom: 1px solid %7$s;}",
    "table.phw-dt.dataTable thead th.phw-blank {border-bottom: none;}",
    "table.phw-dt.dataTable tbody td {border-top: 1px solid %4$s;}",
    "table.phw-dt.dataTable tbody tr:last-child td {border-bottom: 2px solid %3$s;}",
    "table.phw-dt.dataTable tbody tr:hover {background: %5$s;}",
    ".dataTables_wrapper {font-family: %1$s, Arial, sans-serif; font-size: 14px; color: %2$s;}",
    ".dataTables_wrapper .dataTables_paginate .paginate_button.current {background: %3$s !important;",
    "color: #FFFFFF !important; border: 1px solid %3$s !important;}",
    ".dataTables_wrapper .dataTables_filter input:focus {outline: 3px solid %6$s;}"),
    phw_font(), col[["text"]], col[["navy"]], col[["grey_border"]], col[["grey_bg"]], col[["focus"]],
    col[["grey_mid"]])
  htmltools::htmlDependency("phw-dt", "0.1", src = c(href = ""), head = sprintf("<style>%s</style>", css))
}

#' Write tables to a styled Excel workbook
#'
#' Writes one or more data frames to an `.xlsx` file in the PHW style, one
#' sheet each: a title row, a navy header, thousands separators, ISO dates,
#' sensible column widths, frozen header row and a bold source line under
#' the table. Summary tables from [phw_summary_table()], [phw_group_table()]
#' and friends look as they do in the other renderers: the header spanning
#' the group columns, shaded variable rows with navy labels, indented
#' levels, italic subtotals and a navy rule above the total.
#'
#' @param x A data frame, or a named list of data frames (one sheet each;
#'   the names become the sheet names).
#' @param file Path of the `.xlsx` file.
#' @param title Title for the first row of each sheet: one string, or one
#'   per sheet. `NULL` for none.
#' @param source,date Passed to [phw_caption()] and written under each
#'   table.
#' @param caption_args List of other [phw_caption()] arguments.
#' @param digits Decimal places for non-integer numbers.
#' @param header_fill Header fill colour: a colour, or a name from
#'   [phw_colours] such as `"navy"`.
#' @param font Font name. Excel uses it if it is installed on the reader's
#'   computer, so Arial is the safe default.
#' @param overwrite Replace `file` if it exists?
#' @return The path to the file, invisibly.
#' @examples
#' if (requireNamespace("openxlsx2", quietly = TRUE)) {
#'   f <- tempfile(fileext = ".xlsx")
#'   phw_write_xlsx(list(Cars = head(mtcars), Iris = head(iris)), f,
#'                  title = "Example tables", source = "Example data")
#' }
#' @export
phw_write_xlsx <- function(x, file, title = NULL, source = NULL, date = NULL, caption_args = list(),
                           digits = 1, header_fill = phw_colours[["navy"]], font = "Arial",
                           overwrite = TRUE) {
  rlang::check_installed("openxlsx2")
  x <- xlsx_sheets(x)
  if (is.character(header_fill) && length(header_fill) == 1 && header_fill %in% names(phw_colours)) {
    header_fill <- phw_colours[[header_fill]]
  }
  check_colours(header_fill, "header_fill")
  titles <- rep_len(as.list(title %||% list(NULL)), length(x))
  cap <- caption_from(source, date, caption_args)
  col <- phw_colours
  colour <- function(h) openxlsx2::wb_color(paste0("FF", toupper(sub("^#", "", grDevices::rgb(t(grDevices::col2rgb(h)), maxColorValue = 255)))))
  add_font <- function(wb, sheet, dims, ..., size = 10, color = col[["text"]]) {
    openxlsx2::wb_add_font(wb, sheet, dims, name = font, size = size, color = colour(color), ...)
  }
  wb <- openxlsx2::wb_workbook()
  wb <- openxlsx2::wb_set_base_font(wb, font_size = 10, font_name = font)
  for (k in seq_along(x)) {
    sheet <- substr(gsub("[][*?:/\\\\]", " ", names(x)[k]), 1, 31)
    s <- x[[k]]
    is_sum <- inherits(s, "phw_summary")
    df <- as.data.frame(unclass(s)[names(s)], check.names = FALSE)
    nl <- if (is_sum) attr(s, "label_cols") %||% 1L else 0L
    hd <- if (is_sum) summary_header(s, nl) else list(upper = list(), bottom = names(df))
    header <- c(names(df)[seq_len(nl)], hd$bottom)
    nc <- ncol(df)
    nr <- nrow(df)
    wb <- openxlsx2::wb_add_worksheet(wb, sheet, grid_lines = FALSE)
    row <- 1
    if (!is.null(titles[[k]])) {
      wb <- openxlsx2::wb_add_data(wb, sheet, titles[[k]], start_row = 1)
      wb <- add_font(wb, sheet, "A1", bold = TRUE, size = 13, color = col[["navy"]])
      row <- 3
    }
    # The spanner, or the upper column levels (years above quarters).
    for (level in hd$upper) {
      for (g in seq_len(nrow(level))) {
        cols <- nl + level$start[g] + seq_len(level$n[g]) - 1
        dims <- openxlsx2::wb_dims(rows = row, cols = cols)
        if (!nzchar(level$label[g])) next
        wb <- openxlsx2::wb_add_data(wb, sheet, level$label[g], start_row = row, start_col = cols[1])
        if (length(cols) > 1) wb <- openxlsx2::wb_merge_cells(wb, sheet, dims)
        wb <- add_font(wb, sheet, dims, bold = TRUE, color = col[["navy"]])
        wb <- openxlsx2::wb_add_cell_style(wb, sheet, dims, horizontal = "center")
        wb <- openxlsx2::wb_add_border(wb, sheet, dims, bottom_color = colour(col[["grey_mid"]]),
                                       left_border = NULL, right_border = NULL, top_border = NULL)
      }
      row <- row + 1
    }
    head_row <- row
    if (is_sum && isTRUE(attr(s, "indent") %||% TRUE)) {
      df[[1]] <- paste0(strrep("    ", summary_rows(s)$indent), df[[1]])
    }
    # Header written separately so repeated labels (Q1 under each year) stay as they are.
    wb <- openxlsx2::wb_add_data(wb, sheet, as.data.frame(t(header)), start_row = head_row, col_names = FALSE)
    wb <- openxlsx2::wb_add_data(wb, sheet, df, start_row = head_row + 1, col_names = FALSE, na.strings = "")
    hdims <- openxlsx2::wb_dims(rows = head_row, cols = seq_len(nc))
    wb <- openxlsx2::wb_add_fill(wb, sheet, hdims, color = colour(header_fill))
    wb <- add_font(wb, sheet, hdims, bold = TRUE, color = phw_text_on(header_fill))
    if (nr > 0) {
      body <- openxlsx2::wb_dims(rows = head_row + seq_len(nr), cols = seq_len(nc))
      wb <- openxlsx2::wb_add_border(wb, sheet, body,
                                     inner_hgrid = "thin", inner_hcolor = colour(col[["grey_border"]]),
                                     left_border = NULL, right_border = NULL, top_border = NULL,
                                     bottom_border = "medium", bottom_color = colour(col[["navy"]]))
      for (j in which(vapply(df, is.numeric, logical(1)) | seq_along(df) > nl & is_sum)) {
        wb <- openxlsx2::wb_add_cell_style(wb, sheet, openxlsx2::wb_dims(rows = head_row + 0:nr, cols = j),
                                           horizontal = "right")
      }
      for (j in seq_along(df)) {
        v <- df[[j]]
        fmt <- if (inherits(v, "POSIXt")) "yyyy-mm-dd hh:mm" else if (inherits(v, "Date")) "yyyy-mm-dd" else if (is.numeric(v)) {
          if (all(v == round(v), na.rm = TRUE)) "#,##0" else paste0("#,##0.", strrep("0", digits))
        }
        if (!is.null(fmt)) wb <- openxlsx2::wb_add_numfmt(wb, sheet, openxlsx2::wb_dims(rows = head_row + seq_len(nr), cols = j), fmt)
      }
      if (is_sum) wb <- style_summary_xlsx(wb, sheet, s, head_row, nl, nc, add_font, colour)
    }
    foot <- head_row + nr + 2
    notes <- if (is_sum) attr(s, "note")
    for (n in seq_along(notes)) {
      wb <- openxlsx2::wb_add_data(wb, sheet, notes[n], start_row = foot)
      wb <- add_font(wb, sheet, openxlsx2::wb_dims(rows = foot, cols = 1), size = 9, color = col[["text_secondary"]])
      foot <- foot + 1
    }
    for (line in if (!is.null(cap)) strsplit(cap, "\n")[[1]]) {
      dims <- openxlsx2::wb_dims(rows = foot, cols = seq_len(nc))
      wb <- openxlsx2::wb_add_data(wb, sheet, line, start_row = foot)
      if (nc > 1) wb <- openxlsx2::wb_merge_cells(wb, sheet, dims)
      wb <- add_font(wb, sheet, dims, bold = TRUE, size = 9)
      wb <- openxlsx2::wb_add_cell_style(wb, sheet, dims, horizontal = "right")
      foot <- foot + 1
    }
    wb <- openxlsx2::wb_set_col_widths(wb, sheet, cols = seq_len(nc), widths = "auto")
    wb <- openxlsx2::wb_freeze_pane(wb, sheet, first_active_row = head_row + 1)
  }
  # openxlsx2 1.22 and later zips the workbook with the system tool that R
  # was built to use, even on a computer that doesn't have it. Point it at
  # its other methods in that case.
  zip_tool <- Sys.getenv("R_ZIPCMD")
  if (nzchar(zip_tool) && !nzchar(Sys.which(zip_tool))) {
    old <- options(openxlsx2.no_utils_zip = TRUE)
    on.exit(options(old), add = TRUE)
  }
  openxlsx2::wb_save(wb, file, overwrite = overwrite)
  invisible(file)
}

# One data frame per sheet, named, before anything is written.
xlsx_sheets <- function(x, call = rlang::caller_env()) {
  if (is.data.frame(x)) x <- list(Sheet1 = x)
  ok <- is.list(x) && length(x) && all(vapply(x, is.data.frame, logical(1)))
  if (!ok) {
    bad <- if (is.list(x) && length(x)) x[!vapply(x, is.data.frame, logical(1))][[1]] else x
    cli::cli_abort(c("{.arg x} must be a data frame or a list of data frames.",
                     x = "It has {.obj_type_friendly {bad}}."), call = call)
  }
  nms <- names(x) %||% rep("", length(x))
  blank <- is.na(nms) | !nzchar(nms)
  nms[blank] <- paste0("Sheet", which(blank))
  names(x) <- nms
  for (nm in nms) check_unique_names(x[[nm]], arg = "x", call = call)
  x
}

style_summary_xlsx <- function(wb, sheet, s, head_row, nl, nc, add_font, colour) {
  r <- summary_rows(s)
  col <- phw_colours
  row_dims <- function(i, cols = seq_len(nc)) openxlsx2::wb_dims(rows = head_row + i, cols = cols)
  for (i in which(r$shade)) {
    wb <- openxlsx2::wb_add_fill(wb, sheet, row_dims(i), color = colour(col[["grey_bg"]]))
  }
  for (i in which(r$bold | r$italic | r$navy)) {
    wb <- add_font(wb, sheet, row_dims(i, seq_len(nl)), bold = if (r$bold[i]) TRUE else "",
                   italic = if (r$italic[i]) TRUE else "", color = if (r$navy[i]) col[["navy"]] else col[["text"]])
    if (nc > nl && r$bold[i]) wb <- add_font(wb, sheet, row_dims(i, seq(nl + 1, nc)), bold = TRUE)
  }
  # A navy rule above each total row, and a grey one between groups, drawn
  # as the bottom border of the row above.
  for (i in which((r$rule | r$line) & seq_len(nrow(r)) > 1)) {
    rule <- if (r$rule[i]) c("medium", col[["navy"]]) else c("thin", col[["grey_mid"]])
    wb <- openxlsx2::wb_add_border(wb, sheet, row_dims(i - 1), bottom_border = rule[1], bottom_color = colour(rule[2]),
                                   left_border = NULL, right_border = NULL, top_border = NULL)
  }
  wb
}

#' PowerPoint slides with officer
#'
#' `phw_pptx()` starts a PowerPoint deck, from the PHW template (16:9, Ubuntu
#' text, navy titles) or from your own. `phw_add_slide()` adds a slide with a PHW-styled title
#' and a chart, table or text, so a set of results becomes a deck in a few
#' lines. Charts are added as editable vector graphics when the rvg package
#' is installed, so colleagues can tweak them in PowerPoint.
#'
#' Every argument is checked before the slide is added, so a call that
#' stops leaves the deck as it was.
#'
#' @param template Path to a `.pptx` template, e.g. the PHW corporate
#'   template. `NULL` uses the PHW template from [phw_reference_pptx()].
#' @return An officer `rpptx` object. Save it with `print(deck, target =
#'   "file.pptx")`.
#' @examples
#' if (requireNamespace("officer", quietly = TRUE)) {
#'   deck <- phw_pptx()
#'   deck <- phw_add_slide(deck, "Key messages",
#'                         text = c("Point one", "Point two"))
#'   if (requireNamespace("ggplot2", quietly = TRUE)) {
#'     p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
#'     deck <- phw_add_slide(deck, "A chart", plot = p, source = "mtcars", editable = FALSE)
#'     deck <- phw_add_slide(deck, "A chart and its data", plot = p,
#'                           table = head(mtcars[, c("wt", "mpg")]),
#'                           layout = "Two Content", editable = FALSE)
#'   }
#'   print(deck, target = tempfile(fileext = ".pptx"))
#' }
#' @export
phw_pptx <- function(template = NULL) {
  rlang::check_installed("officer")
  check_one_string(template, allow_null = TRUE)
  if (!is.null(template) && !file.exists(template)) {
    cli::cli_abort("{.arg template}: file not found: {.file {template}}.")
  }
  officer::read_pptx(template %||% phw_file("rmarkdown", "resources", "phw-reference.pptx"))
}

#' @rdname phw_pptx
#' @param x An `rpptx` object from `phw_pptx()`.
#' @param title Slide title, a single string.
#' @param plot A ggplot, or a grob or gtable such as a [phw_finalise()]
#'   result. A grob goes on the slide as a picture.
#' @param table A data frame, flextable or summary table (rendered with
#'   [phw_flextable()]). It must have at least one row.
#' @param text Character vector of bullet points.
#' @param source,date Passed to [phw_caption()] and shown at the bottom.
#' @param layout,master Slide layout and slide master names in the
#'   template. A slide master is the set of layouts a template provides;
#'   see them in PowerPoint under View > Slide Master, or with
#'   `officer::layout_summary(x)`. The default `master = NULL` uses the
#'   master in the deck that has the layout (the first one, if several do),
#'   so you only need `master` when two masters share a layout name.
#'
#'   Give one of `plot`, `table` or `text` for each content area. The PHW
#'   template has these layouts:
#'
#'   * `"Title and Content"` (the default): one chart, table or text.
#'   * `"Two Content"`: two side by side. With one, it goes on the left.
#'     With two, the first of `plot`, `table` and `text` goes on the left.
#'   * `"Title Only"`: one chart, table or text in the space below the
#'     title.
#'   * `"Blank"`: one chart, table or text filling the slide. It has no
#'     title.
#'   * `"Title Slide"` and `"Section Header"`: a title and `text` on navy.
#'     They have no room for a chart or table.
#'
#'   With your own template, give the layout names it uses.
#' @param editable Add charts as editable vector graphics (needs rvg)?
#' @param plot_scale How much to enlarge a chart's text on the slide, as a
#'   multiple of the size the chart already uses. The default `1.5` brings
#'   axis and legend text to about 14 points, which reads from the back of a
#'   room. `1` leaves the chart as it is. It scales the text and legend keys
#'   that follow the plot's base size, as [theme_phw()] and the ggplot2
#'   themes do, and the size of text drawn by `geom_text()` with ggplot2 4.0.0
#'   or later. Text you gave an exact size in your own `theme()` keeps it.
#'   A grob keeps the sizes it was drawn with.
#' @param table_fit Enlarge a table built here from a data frame or summary
#'   table so it fills the width of the slide's content area? The text grows
#'   with it, by up to 1.6 times, and a narrow table is widened by at most
#'   another 80% (more for a table with more columns). A tall table tightens
#'   its row spacing so the text can grow. `FALSE` keeps the table at the size [phw_flextable()] gives
#'   it. A flextable you pass in is never resized. The text never shrinks,
#'   so a table with too many rows for the slide gives a warning that says
#'   how many fit.
#' @param title_size Title font size. On a layout with a dark background (the
#'   title slide and section header) the template sets the size and colour, and
#'   this applies only when you give it.
#' @param caption_args List of other [phw_caption()] arguments.
#' @param alt Alternative text for the chart or table on the slide, read out
#'   by screen readers. `NULL` adds none, except that a ggplot's own
#'   `labs(alt = )` text is used when there is one. On a slide with two
#'   contents, it goes on the first.
#' @export
phw_add_slide <- function(x, title = NULL, plot = NULL, table = NULL, text = NULL,
                          source = NULL, date = NULL, layout = "Title and Content",
                          master = NULL, editable = TRUE, title_size = 28,
                          caption_args = list(), alt = NULL,
                          plot_scale = 1.5, table_fit = TRUE) {
  rlang::check_installed("officer")
  if (!inherits(x, "rpptx")) {
    cli::cli_abort("{.arg x} must be a deck from {.fn phw_pptx}, not {.obj_type_friendly {x}}.")
  }
  check_one_string(title, allow_null = TRUE)
  check_one_string(alt, allow_null = TRUE)
  check_one_string(layout)
  check_one_string(master, allow_null = TRUE)
  check_true_false(editable)
  check_true_false(table_fit)
  if (!is.numeric(plot_scale) || length(plot_scale) != 1 || is.na(plot_scale) || plot_scale <= 0) {
    cli::cli_abort("{.arg plot_scale} must be a single positive number, not {.val {plot_scale}}.")
  }
  if (!is.numeric(title_size) || length(title_size) != 1 || is.na(title_size) || title_size <= 0) {
    cli::cli_abort("{.arg title_size} must be a single positive number, not {.val {title_size}}.")
  }
  contents <- slide_contents(plot, table, text)
  available <- officer::layout_summary(x)
  if (is.null(master)) {
    master <- available$master[available$layout == layout][1]
    if (is.na(master)) {
      cli::cli_abort(c(
        "This deck has no slide layout called {.val {layout}}.",
        "i" = "Layouts available: {.val {unique(available$layout)}}."
      ))
    }
  } else if (!any(available$layout == layout & available$master == master)) {
    cli::cli_abort(c(
      "This deck has no slide layout called {.val {layout}} in a master called {.val {master}}.",
      "i" = "Masters with that layout: {.val {unique(available$master[available$layout == layout])}}."
    ))
  }
  props <- officer::layout_properties(x, layout = layout, master = master)
  on_navy <- "subTitle" %in% props$type || layout == "Section Header"
  title_type <- intersect(c("ctrTitle", "title"), props$type)[1]
  if (!is.null(title) && is.na(title_type)) {
    cli::cli_abort(c("The {.val {layout}} layout has no title.",
                     i = 'Use {.code layout = "Title Only"} for a title above the content, or leave out {.arg title}.'))
  }
  areas <- slide_areas(props, officer::slide_size(x), layout, on_navy, names(contents))
  cap <- caption_from(source, date, caption_args)
  if (is.null(alt) && inherits(plot, "ggplot") && nzchar(ggplot2::get_alt_text(plot))) {
    alt <- ggplot2::get_alt_text(plot)
  }
  values <- Map(slide_value, contents, names(contents), areas,
                MoreArgs = list(editable = editable, plot_scale = plot_scale,
                                table_fit = table_fit, on_navy = on_navy))

  x <- officer::add_slide(x, layout = layout, master = master)
  index <- x$cursor
  tryCatch({
    if (!is.null(title)) {
      # Cover layouts have a dark background and set their own title colour and size,
      # so the run leaves both to the placeholder. A fixed navy would vanish there.
      title_props <- if (on_navy) {
        officer::fp_text_lite(font.family = phw_font(), bold = TRUE,
                              font.size = if (missing(title_size)) NA else title_size)
      } else {
        officer::fp_text(font.family = phw_font(), font.size = title_size, bold = TRUE,
                         color = phw_colours[["navy"]])
      }
      x <- officer::ph_with(x, officer::fpar(officer::ftext(title, title_props)),
                            location = officer::ph_location_type(title_type))
    }
    for (i in seq_along(values)) {
      shape_alt <- if (i == 1) alt
      if (!is.null(shape_alt) && inherits(values[[i]], "ggplot")) {
        x <- officer::ph_with(x, values[[i]], location = areas[[i]]$location, alt_text = shape_alt)
      } else {
        x <- officer::ph_with(x, values[[i]], location = areas[[i]]$location)
        if (names(values)[i] == "text" && isTRUE(areas[[i]]$free)) x <- set_slide_bullets(x)
        x <- set_slide_alt(x, shape_alt)
      }
    }
    if (!is.null(cap)) {
      size <- officer::slide_size(x)
      fp <- officer::fp_text(font.family = phw_font(), font.size = 10, bold = TRUE,
                             color = phw_colours[[if (on_navy) "white" else "text"]])
      x <- officer::ph_with(x, officer::fpar(officer::ftext(gsub("\n", " | ", cap), fp),
                                             fp_p = officer::fp_par(text.align = "right")),
                            location = officer::ph_location(left = 0.6, top = size$height - 0.6,
                                                            width = size$width - 1.2, height = 0.4))
    }
    x
  }, error = function(e) {
    # The deck changes in place, so a failure part way would leave a half-built slide.
    officer::remove_slide(x, index = index)
    stop(e)
  })
}

body_type <- function(types) if ("subTitle" %in% types) "subTitle" else "body"

# The given contents in the order they fill a slide's areas: plot, table, text.
slide_contents <- function(plot, table, text, call = rlang::caller_env()) {
  if (!is.null(plot) && !inherits(plot, c("ggplot", "grob"))) {
    cli::cli_abort("{.arg plot} must be a ggplot, or a grob such as a {.fn phw_finalise} result, not {.obj_type_friendly {plot}}.",
                   call = call)
  }
  if (inherits(table, "flextable")) {
    if (!flextable::nrow_part(table, "body")) cli::cli_abort("{.arg table} has no rows.", call = call)
  } else if (is.data.frame(table)) {
    if (!ncol(table)) cli::cli_abort("{.arg table} has no columns.", call = call)
    check_has_rows(table, "table", call = call)
  } else if (!is.null(table)) {
    cli::cli_abort("{.arg table} must be a data frame, a summary table or a flextable, not {.obj_type_friendly {table}}.",
                   call = call)
  }
  if (!is.null(text) && (!is.character(text) || !length(text) || anyNA(text))) {
    cli::cli_abort("{.arg text} must be a character vector with no missing values, not {.obj_type_friendly {text}}.",
                   call = call)
  }
  Filter(Negate(is.null), list(plot = plot, table = table, text = text))
}

# Where content goes on a layout with no content placeholder: below the
# title (Title Only), or the whole slide inside the margins (Blank). The
# bottom margin leaves room for the source line. In inches.
slide_margins <- c(side = 0.6, top = 0.4, bottom = 0.95, gap = 0.25)

# One area per content: its officer location and its size in inches.
slide_areas <- function(props, size, layout, on_navy, kinds, call = rlang::caller_env()) {
  if (!length(kinds)) return(list())
  if (on_navy && any(kinds %in% c("plot", "table"))) {
    cli::cli_abort(c("The {.val {layout}} layout has room only for {.arg text}.",
                     i = 'Use {.code layout = "Title and Content"} for a chart or table.'), call = call)
  }
  bodies <- props[props$type == body_type(props$type), , drop = FALSE]
  bodies <- bodies[order(bodies$offx, bodies$offy), , drop = FALSE]
  n <- max(nrow(bodies), 1)
  if (length(kinds) > n) {
    room <- if (n == 1) "one content area" else paste(n, "content areas")
    cli::cli_abort(c("The {.val {layout}} layout has {room}, but you gave {.arg {kinds}}.",
                     i = if (n == 1) 'Give one of them, or use {.code layout = "Two Content"} for two side by side.'),
                   call = call)
  }
  if (nrow(bodies)) {
    return(lapply(seq_along(kinds), function(i) {
      list(location = officer::ph_location_id(bodies$id[i]), width = bodies$cx[i], height = bodies$cy[i])
    }))
  }
  m <- slide_margins
  title <- props[props$type %in% c("ctrTitle", "title"), , drop = FALSE]
  if (nrow(title)) {
    left <- title$offx[1]
    width <- title$cx[1]
    top <- title$offy[1] + title$cy[1] + m[["gap"]]
  } else {
    left <- m[["side"]]
    width <- size$width - 2 * m[["side"]]
    top <- m[["top"]]
  }
  height <- size$height - m[["bottom"]] - top
  list(list(location = officer::ph_location(left = left, top = top, width = width, height = height),
            width = width, height = height, free = TRUE))
}

# The officer value for one content, sized for its area.
slide_value <- function(value, kind, area, editable, plot_scale, table_fit, on_navy) {
  if (kind == "plot") {
    if (!inherits(value, "ggplot")) {
      file <- tempfile(fileext = ".png")
      phw_save(value, file, width = area$width, height = area$height, units = "in", dpi = 200)
      return(officer::external_img(file, width = area$width, height = area$height))
    }
    value <- scale_plot_text(value, plot_scale)
    if (editable && requireNamespace("rvg", quietly = TRUE)) {
      return(rvg::dml(ggobj = value, fonts = list(sans = phw_font())))
    }
    return(value)
  }
  if (kind == "table") {
    ft <- if (inherits(value, "flextable")) {
      value
    } else {
      built <- phw_flextable(value)
      if (table_fit) fit_table_to_area(built, area$width, area$height) else built
    }
    n <- flextable::nrow_part(ft, "body")
    fits <- table_rows_that_fit(ft, area$height)
    if (fits < n) {
      cli::cli_warn(c("Only {fits} of the table's {n} rows fit in the slide's content area, so the table runs past it.",
                      i = "Split the table over more slides, or show fewer rows."))
    }
    return(ft)
  }
  if (on_navy) {
    props <- officer::fp_text(font.family = phw_font(), font.size = 22, color = phw_colours[["grey_bg"]])
    return(do.call(officer::block_list, lapply(value, function(t) officer::fpar(officer::ftext(t, props)))))
  }
  props <- officer::fp_text(font.family = phw_font(), font.size = 20, color = phw_colours[["text"]])
  officer::unordered_list(str_list = value, level_list = rep(1L, length(value)), style = props)
}

# Slides treat row heights as minimums, so the set heights tell how far down
# the table reaches.
table_rows_that_fit <- function(ft, height) {
  fixed <- sum(ft$header$rowheights, ft$footer$rowheights)
  sum(fixed + cumsum(ft$body$rowheights) <= height + 0.001)
}

scale_plot_text <- function(plot, scale) {
  if (scale == 1) return(plot)
  current <- ggplot2::theme_get() + plot$theme
  plot <- plot + ggplot2::theme(
    text = ggplot2::element_text(size = ggplot2::calc_element("text", current)$size * scale),
    legend.key.size = ggplot2::calc_element("legend.key.size", current) * scale
  )
  if (ggplot2_v4()) {
    # element_geom() reads points but calc_element() returns millimetres
    fontsize <- ggplot2::calc_element("geom", current)$fontsize
    if (!is.null(fontsize)) {
      # Looked up by name: ggplot2 before 4.0 has no element_geom(), as in theme_phw().
      element_geom <- getExportedValue("ggplot2", "element_geom")
      plot <- plot + ggplot2::theme(geom = element_geom(fontsize = fontsize * scale * ggplot2::.pt))
    }
  }
  plot
}

# Grows a table's text so it fills the area, then widens its columns. A tall
# table is bound by height, so it squeezes its vertical padding and sets row
# heights from the text size and padding: the heights flextable measures are
# larger than the text needs, and slides treat them as minimums. It never
# shrinks the text.
fit_table_to_area <- function(ft, width, height, max_grow = 1.6, max_pad = 1.8,
                              line_height = 1.25, tight_pad = 1) {
  parts <- Filter(function(part) flextable::nrow_part(ft, part) > 0, c("header", "body", "footer"))
  sizes <- lapply(parts, function(part) apply(ft[[part]]$styles$text$font.size$data, 1, max))
  pads <- lapply(parts, function(part) {
    pars <- ft[[part]]$styles$pars
    apply(pars$padding.top$data, 1, max) + apply(pars$padding.bottom$data, 1, max)
  })
  text_pt <- sum(unlist(sizes)) * line_height
  grow_for <- function(pad_pt) (height * 72 - pad_pt) / text_pt
  grow_w <- flextable::flextable_dim(ft)$widths
  grow_w <- width / grow_w
  wanted <- min(grow_w, max_grow)
  pad_pt <- sum(unlist(pads))
  tall <- grow_for(pad_pt) < wanted
  if (tall) {
    pads <- lapply(pads, function(p) rep(2 * tight_pad, length(p)))
    pad_pt <- sum(unlist(pads))
    ft <- flextable::padding(ft, padding.top = tight_pad, padding.bottom = tight_pad, part = "all")
  }
  grow <- min(wanted, grow_for(pad_pt))
  if (grow > 1) {
    for (k in seq_along(parts)) {
      for (i in seq_along(sizes[[k]])) {
        ft <- flextable::fontsize(ft, i = i, size = sizes[[k]][i] * grow, part = parts[k])
      }
    }
    ft <- flextable::autofit(ft)
  }
  if (tall) {
    grow <- max(grow, 1)
    for (k in seq_along(parts)) {
      ft <- flextable::height(ft, i = seq_along(sizes[[k]]), part = parts[k], unit = "in",
                              height = (sizes[[k]] * grow * line_height + pads[[k]]) / 72)
    }
  }
  widths <- ft$body$colwidths
  max_pad <- max_pad + 0.3 * max(length(widths) - 2, 0)
  pad <- min(width / sum(widths), max_pad)
  flextable::width(ft, j = seq_along(widths), width = widths * pad)
}

# officer's ph_with() takes alt text only for ggplot images, so editable
# charts, pictures and tables get it written onto the shape just added.
set_slide_alt <- function(x, alt) {
  if (is.null(alt)) return(x)
  rlang::check_installed("xml2")
  doc <- x$slide$get_slide(x$cursor)$get()
  shapes <- xml2::xml_find_all(doc, "//p:spTree/*[p:nvSpPr or p:nvGrpSpPr or p:nvGraphicFramePr or p:nvPicPr]")
  last <- shapes[[length(shapes)]]
  xml2::xml_set_attr(xml2::xml_find_first(last, "*[1]/p:cNvPr"), "descr", alt)
  x
}

# A text box outside a placeholder doesn't inherit the master's bullets, so
# the paragraphs of the shape just added get the template's first-level ones.
set_slide_bullets <- function(x) {
  rlang::check_installed("xml2")
  doc <- x$slide$get_slide(x$cursor)$get()
  shapes <- xml2::xml_find_all(doc, "//p:spTree/p:sp")
  for (p in xml2::xml_find_all(shapes[[length(shapes)]], ".//a:p")) {
    ppr <- xml2::xml_find_first(p, "a:pPr")
    if (inherits(ppr, "xml_missing")) ppr <- xml2::xml_add_child(p, "a:pPr", .where = 0)
    xml2::xml_set_attrs(ppr, c(xml2::xml_attrs(ppr), marL = "342900", indent = "-342900"))
    xml2::xml_add_child(ppr, "a:buFont", typeface = "Arial", .where = 0)
    xml2::xml_add_child(ppr, "a:buChar", char = "\u2022", .where = 1)
  }
  x
}
