#' Interactive tables with DT
#'
#' Builds a [DT::datatable()] in the PHW style: PHW font, navy header, light
#' row lines, thousands separators, and a title and source line. Useful in
#' Shiny apps and HTML reports when readers need to search, sort or page
#' through a long table. A summary table (see [phw_summary_table()] and
#' [phw_as_summary()]) keeps its bold variable and total rows and indented
#' levels, and is shown whole, without sorting or paging.
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
  sm <- NULL
  if (inherits(data, "phw_summary")) {
    sm <- summary_dt_parts(data)
    if (!is.null(attr(data, "note"))) caption_args$note <- caption_args$note %||% attr(data, "note")
    data <- sm$data
  }
  data <- as.data.frame(data)
  defaults <- if (is.null(sm)) {
    list(pageLength = page_length, dom = "ftip")
  } else {
    list(paging = FALSE, ordering = FALSE, dom = "t", columnDefs = list(list(visible = FALSE, targets = sm$hidden)))
  }
  opts <- utils::modifyList(c(defaults, list(autoWidth = FALSE, language = list(search = "Search:"))), options)
  args <- utils::modifyList(list(data = data, rownames = FALSE, class = "phw-dt compact hover",
                                 options = opts, style = "default"), list(...))
  w <- do.call(DT::datatable, args)
  num <- setdiff(names(data)[vapply(data, is.numeric, logical(1))], sm$helpers)
  is_int <- vapply(data[num], function(v) all(v == round(v), na.rm = TRUE), logical(1))
  if (any(is_int)) w <- DT::formatRound(w, num[is_int], digits = 0)
  if (any(!is_int)) w <- DT::formatRound(w, num[!is_int], digits = digits)
  if (!is.null(sm)) w <- style_summary_dt(w, sm)
  w$dependencies <- c(w$dependencies, list(phw_font_dependency(), phw_dt_css()))
  wrap_widget(w, caption, caption_from(source, date, caption_args))
}

# The row types and indent depths travel as two hidden columns, which
# formatStyle() reads to style each row.
summary_dt_parts <- function(x) {
  types <- attr(x, "row_type")
  depth <- attr(x, "depth") %||% as.integer(types == "level")
  indent <- isTRUE(attr(x, "indent") %||% TRUE)
  df <- as.data.frame(unclass(x)[names(x)], check.names = FALSE)
  helpers <- c(".phw_row_type", ".phw_depth")
  df[[helpers[1]]] <- types
  df[[helpers[2]]] <- if (indent) depth else rep(0L, nrow(df))
  list(data = df, helpers = helpers, hidden = ncol(df) - 2:1,
       label = names(x)[1])
}

style_summary_dt <- function(w, sm) {
  col <- phw_colours
  bold <- c("variable", "subtotal", "total")
  all_cols <- setdiff(names(sm$data), sm$helpers)
  w <- DT::formatStyle(w, all_cols, valueColumns = sm$helpers[1],
    fontWeight = DT::styleEqual(bold, rep("700", 3)),
    borderTop = DT::styleEqual("total", paste("2px solid", col[["navy"]])))
  w <- DT::formatStyle(w, sm$label, valueColumns = sm$helpers[1],
    fontStyle = DT::styleEqual("subtotal", "italic"))
  depths <- sort(setdiff(unique(sm$data[[sm$helpers[2]]]), 0))
  if (length(depths)) {
    w <- DT::formatStyle(w, sm$label, valueColumns = sm$helpers[2],
      paddingLeft = DT::styleEqual(depths, paste0(8 + 14 * depths, "px")))
  }
  w
}

phw_dt_css <- function() {
  col <- phw_colours
  css <- sprintf(paste0(
    "table.phw-dt.dataTable {font-family: %1$s, Arial, sans-serif; color: %2$s; border-collapse: collapse;}",
    "table.phw-dt.dataTable thead th {color: %3$s; border-top: 2px solid %3$s; border-bottom: 2px solid %3$s;",
    "font-weight: 700;}",
    "table.phw-dt.dataTable tbody td {border-top: 1px solid %4$s;}",
    "table.phw-dt.dataTable tbody tr:last-child td {border-bottom: 2px solid %3$s;}",
    "table.phw-dt.dataTable tbody tr:hover {background: %5$s;}",
    ".dataTables_wrapper {font-family: %1$s, Arial, sans-serif; color: %2$s;}",
    ".dataTables_wrapper .dataTables_paginate .paginate_button.current {background: %3$s !important;",
    "color: #FFFFFF !important; border: 1px solid %3$s !important;}",
    ".dataTables_wrapper .dataTables_filter input:focus {outline: 3px solid %6$s;}"),
    phw_font(), col[["text"]], col[["navy"]], col[["grey_border"]], col[["grey_bg"]], col[["focus"]])
  htmltools::htmlDependency("phw-dt", "0.1", src = c(href = ""), head = sprintf("<style>%s</style>", css))
}

#' Write tables to a styled Excel workbook
#'
#' Writes one or more data frames to an `.xlsx` file in the PHW style, one
#' sheet each: a title row, a navy header, thousands separators, sensible
#' column widths, frozen header row and a source note under the table.
#' Summary tables from [phw_summary_table()], [phw_group_table()] and
#' friends keep their bold group rows and indented levels.
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
#' @param header_fill Header fill colour.
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
  if (is.data.frame(x)) x <- list(Sheet1 = x)
  if (is.null(names(x))) names(x) <- paste0("Sheet", seq_along(x))
  titles <- rep_len(as.list(title %||% list(NULL)), length(x))
  cap <- caption_from(source, date, caption_args)
  hex <- function(h) sub("^#", "FF", toupper(h))
  wb <- openxlsx2::wb_workbook()
  wb <- openxlsx2::wb_set_base_font(wb, font_size = 10, font_name = font)
  for (k in seq_along(x)) {
    sheet <- substr(gsub("[][*?:/\\\\]", " ", names(x)[k]), 1, 31)
    s <- x[[k]]
    is_sum <- inherits(s, "phw_summary")
    df <- as.data.frame(unclass(s)[names(s)], check.names = FALSE)
    ch <- attr(s, "col_header")
    nl <- if (is_sum) attr(s, "label_cols") %||% 1L else 0L
    header <- names(df)
    if (!is.null(ch)) header[-seq_len(nl)] <- ch[nrow(ch), ]
    wb <- openxlsx2::wb_add_worksheet(wb, sheet, grid_lines = FALSE)
    row <- 1
    if (!is.null(titles[[k]])) {
      wb <- openxlsx2::wb_add_data(wb, sheet, titles[[k]], start_row = 1)
      wb <- openxlsx2::wb_add_font(wb, sheet, "A1", bold = TRUE, size = 13, name = font,
                                   color = openxlsx2::wb_color(hex(phw_colours[["navy"]])))
      row <- 3
    }
    # Upper column header levels, e.g. years above quarters.
    if (!is.null(ch) && nrow(ch) > 1) {
      for (l in seq_len(nrow(ch) - 1)) {
        key <- apply(ch[seq_len(l), , drop = FALSE], 2, paste, collapse = "\r")
        lab <- ifelse(duplicated(key) | ch[l, ] == ch[nrow(ch), ], "", ch[l, ])
        vals <- c(rep("", nl), lab)
        wb <- openxlsx2::wb_add_data(wb, sheet, as.data.frame(t(vals)), start_row = row, col_names = FALSE)
        dims <- openxlsx2::wb_dims(rows = row, cols = seq_along(vals))
        wb <- openxlsx2::wb_add_font(wb, sheet, dims, bold = TRUE, name = font,
                                     color = openxlsx2::wb_color(hex(phw_colours[["navy"]])))
        row <- row + 1
      }
    }
    head_row <- row
    if (is_sum && isTRUE(attr(s, "indent") %||% TRUE)) {
      depth <- attr(s, "depth") %||% as.integer(attr(s, "row_type") == "level")
      df[[1]] <- paste0(strrep("    ", depth), df[[1]])
    }
    # Header written separately so repeated labels (Q1 under each year) stay as they are.
    wb <- openxlsx2::wb_add_data(wb, sheet, as.data.frame(t(header)), start_row = head_row, col_names = FALSE)
    wb <- openxlsx2::wb_add_data(wb, sheet, df, start_row = head_row + 1, col_names = FALSE, na.strings = "")
    nc <- ncol(df)
    nr <- nrow(df)
    hdims <- openxlsx2::wb_dims(rows = head_row, cols = seq_len(nc))
    wb <- openxlsx2::wb_add_fill(wb, sheet, hdims, color = openxlsx2::wb_color(hex(header_fill)))
    wb <- openxlsx2::wb_add_font(wb, sheet, hdims, bold = TRUE, name = font,
                                 color = openxlsx2::wb_color(hex(phw_text_on(header_fill))))
    if (nr > 0) {
      body <- openxlsx2::wb_dims(rows = head_row + seq_len(nr), cols = seq_len(nc))
      wb <- openxlsx2::wb_add_border(wb, sheet, body,
                                     inner_hgrid = "thin", inner_hcolor = openxlsx2::wb_color(hex(phw_colours[["grey_border"]])),
                                     left_border = NULL, right_border = NULL, top_border = NULL,
                                     bottom_border = "medium", bottom_color = openxlsx2::wb_color(hex(phw_colours[["navy"]])))
      for (j in which(vapply(df, is.numeric, logical(1)) | seq_along(df) > nl & is_sum)) {
        wb <- openxlsx2::wb_add_cell_style(wb, sheet, openxlsx2::wb_dims(rows = head_row + 0:nr, cols = j),
                                           horizontal = "right")
      }
      for (j in which(vapply(df, is.numeric, logical(1)))) {
        whole <- all(df[[j]] == round(df[[j]]), na.rm = TRUE)
        fmt <- if (whole) "#,##0" else paste0("#,##0.", strrep("0", digits))
        wb <- openxlsx2::wb_add_numfmt(wb, sheet, openxlsx2::wb_dims(rows = head_row + seq_len(nr), cols = j), fmt)
      }
      if (is_sum) {
        types <- attr(s, "row_type")
        bold <- which(types %in% c("variable", "total", "subtotal"))
        for (i in bold) {
          wb <- openxlsx2::wb_add_font(wb, sheet, openxlsx2::wb_dims(rows = head_row + i, cols = seq_len(nc)),
                                       bold = TRUE, name = font)
        }
        top <- which(types == "variable" & (attr(s, "depth") %||% rep(0, nr)) == 0)
        for (i in top) {
          wb <- openxlsx2::wb_add_fill(wb, sheet, openxlsx2::wb_dims(rows = head_row + i, cols = seq_len(nc)),
                                       color = openxlsx2::wb_color(hex(phw_colours[["grey_bg"]])))
        }
      }
    }
    foot <- head_row + nr + 2
    notes <- c(if (is_sum) attr(s, "note"), if (!is.null(cap)) strsplit(cap, "\n")[[1]])
    for (n in seq_along(notes)) {
      wb <- openxlsx2::wb_add_data(wb, sheet, notes[n], start_row = foot + n - 1)
      wb <- openxlsx2::wb_add_font(wb, sheet, openxlsx2::wb_dims(rows = foot + n - 1, cols = 1), size = 9,
                                   name = font, color = openxlsx2::wb_color(hex(phw_colours[["text_secondary"]])))
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

#' PowerPoint slides with officer
#'
#' `phw_pptx()` starts a PowerPoint deck, from the PHW template (16:9, Ubuntu
#' text, navy titles) or from your own. `phw_add_slide()` adds a slide with a PHW-styled title
#' and a chart, table or text, so a set of results becomes a deck in a few
#' lines. Charts are added as editable vector graphics when the rvg package
#' is installed, so colleagues can tweak them in PowerPoint.
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
#'   }
#'   print(deck, target = tempfile(fileext = ".pptx"))
#' }
#' @export
phw_pptx <- function(template = NULL) {
  rlang::check_installed("officer")
  officer::read_pptx(template %||% phw_file("rmarkdown", "resources", "phw-reference.pptx"))
}

#' @rdname phw_pptx
#' @param x An `rpptx` object from `phw_pptx()`.
#' @param title Slide title.
#' @param plot A ggplot (or anything [officer::ph_with()] accepts as a
#'   graphic).
#' @param table A data frame, flextable or summary table (rendered with
#'   [phw_flextable()]).
#' @param text Character vector of bullet points.
#' @param source,date Passed to [phw_caption()] and shown at the bottom.
#' @param layout,master Slide layout and slide master names in the
#'   template. A slide master is the set of layouts a template provides;
#'   see them in PowerPoint under View > Slide Master, or with
#'   `officer::layout_summary(x)`. The default layout suits the PHW template,
#'   which also has `"Title Slide"` (the title and `text` as a subtitle),
#'   `"Section Header"`, `"Two Content"`, `"Title Only"` and `"Blank"`. With
#'   your own template, give the layout names it uses. The default
#'   `master = NULL` uses the master in the deck that has the layout (the
#'   first one, if several do), so you only need `master` when two masters
#'   share a layout name.
#' @param editable Add charts as editable vector graphics (needs rvg)?
#' @param plot_scale How much to enlarge a chart's text on the slide, as a
#'   multiple of the size the chart already uses. The default `1.5` brings
#'   axis and legend text to about 14 points, which reads from the back of a
#'   room. `1` leaves the chart as it is. It scales the text and legend keys
#'   that follow the plot's base size, as [theme_phw()] and the ggplot2
#'   themes do, and the size of text drawn by `geom_text()` with ggplot2 4.0.0
#'   or later. Text you gave an exact size in your own `theme()` keeps it.
#' @param table_fit Enlarge a table built here from a data frame or summary
#'   table so it fills the width of the slide's content area? The text grows
#'   with it, by up to 1.6 times, and a narrow table is widened by at most
#'   another 80% (more for a table with more columns). A tall table tightens
#'   its row spacing so the text can grow. `FALSE` keeps the table at the size [phw_flextable()] gives
#'   it. A flextable you pass in is never resized.
#' @param title_size Title font size. On a layout with a dark background (the
#'   title slide and section header) the template sets the size and colour, and
#'   this applies only when you give it.
#' @param caption_args List of other [phw_caption()] arguments.
#' @param alt Alternative text for the chart or table on the slide, read out
#'   by screen readers. `NULL` adds none, except that a ggplot's own
#'   `labs(alt = )` text is used when there is one.
#' @export
phw_add_slide <- function(x, title = NULL, plot = NULL, table = NULL, text = NULL,
                          source = NULL, date = NULL, layout = "Title and Content",
                          master = NULL, editable = TRUE, title_size = 28,
                          caption_args = list(), alt = NULL,
                          plot_scale = 1.5, table_fit = TRUE) {
  rlang::check_installed("officer")
  if (is.null(master)) {
    available <- officer::layout_summary(x)
    master <- available$master[available$layout == layout][1]
    if (is.na(master)) {
      cli::cli_abort(c(
        "This deck has no slide layout called {.val {layout}}.",
        "i" = "Layouts available: {.val {unique(available$layout)}}."
      ))
    }
  }
  # Scale before adding the slide, so a bad plot_scale leaves the deck as it was.
  if (inherits(plot, "ggplot")) plot <- scale_plot_text(plot, plot_scale)
  x <- officer::add_slide(x, layout = layout, master = master)
  types <- officer::layout_properties(x, layout = layout, master = master)$type
  on_navy <- "subTitle" %in% types || layout == "Section Header"
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
    tp <- officer::fpar(officer::ftext(title, title_props))
    x <- officer::ph_with(x, tp, location = officer::ph_location_type(if ("ctrTitle" %in% types) "ctrTitle" else "title"))
  }
  body <- officer::ph_location_type(body_type(types))
  area <- officer::layout_properties(x, layout = layout, master = master)
  area <- area[area$type == body_type(types), ][1, ]
  if (!is.null(plot)) {
    if (is.null(alt) && inherits(plot, "ggplot") && nzchar(ggplot2::get_alt_text(plot))) {
      alt <- ggplot2::get_alt_text(plot)
    }
    value <- if (editable && inherits(plot, "ggplot") && requireNamespace("rvg", quietly = TRUE)) {
      rvg::dml(ggobj = plot, fonts = list(sans = phw_font()))
    } else {
      plot
    }
    if (!is.null(alt) && inherits(value, "ggplot")) {
      x <- officer::ph_with(x, value, location = body, alt_text = alt)
    } else {
      x <- officer::ph_with(x, value, location = body)
      x <- set_slide_alt(x, alt)
    }
  } else if (!is.null(table)) {
    ft <- if (inherits(table, "flextable")) {
      table
    } else {
      built <- phw_flextable(table)
      if (isTRUE(table_fit)) fit_table_to_area(built, area$cx, area$cy) else built
    }
    x <- officer::ph_with(x, ft, location = body)
    x <- set_slide_alt(x, alt)
  } else if (!is.null(text)) {
    if (on_navy) {
      props <- officer::fp_text(font.family = phw_font(), font.size = 22, color = phw_colours[["grey_bg"]])
      x <- officer::ph_with(x, do.call(officer::block_list, lapply(text, function(t) officer::fpar(officer::ftext(t, props)))), location = body)
    } else {
      props <- officer::fp_text(font.family = phw_font(), font.size = 20, color = phw_colours[["text"]])
      x <- officer::ph_with(x, officer::unordered_list(str_list = text, level_list = rep(1L, length(text)), style = props), location = body)
    }
  }
  cap <- caption_from(source, date, caption_args)
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
}

body_type <- function(types) if ("subTitle" %in% types) "subTitle" else "body"

scale_plot_text <- function(plot, scale) {
  if (!is.numeric(scale) || length(scale) != 1 || is.na(scale) || scale <= 0) {
    cli::cli_abort("{.arg plot_scale} must be a single positive number, not {.val {scale}}.")
  }
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
    if (tall) {
      for (k in seq_along(parts)) {
        ft <- flextable::height(ft, i = seq_along(sizes[[k]]), part = parts[k], unit = "in",
                                height = (sizes[[k]] * grow * line_height + pads[[k]]) / 72)
      }
    }
  }
  widths <- ft$body$colwidths
  max_pad <- max_pad + 0.3 * max(length(widths) - 2, 0)
  pad <- min(width / sum(widths), max_pad)
  flextable::width(ft, j = seq_along(widths), width = widths * pad)
}

# officer's ph_with() takes alt text only for ggplot images, so editable
# charts and tables get it written onto the shape just added.
set_slide_alt <- function(x, alt) {
  if (is.null(alt)) return(x)
  rlang::check_installed("xml2")
  doc <- x$slide$get_slide(x$cursor)$get()
  shapes <- xml2::xml_find_all(doc, "//p:spTree/*[p:nvSpPr or p:nvGrpSpPr or p:nvGraphicFramePr or p:nvPicPr]")
  last <- shapes[[length(shapes)]]
  xml2::xml_set_attr(xml2::xml_find_first(last, "*[1]/p:cNvPr"), "descr", alt)
  x
}
