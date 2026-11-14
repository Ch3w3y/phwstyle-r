#' Interactive tables with DT
#'
#' Builds a [DT::datatable()] in the PHW style: PHW font, navy header, light
#' row lines, thousands separators, and a title and source line. Useful in
#' Shiny apps and HTML reports when readers need to search, sort or page
#' through a long table. For styled summary tables use [phw_reactable()].
#'
#' @param data A data frame.
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
  data <- as.data.frame(data)
  opts <- utils::modifyList(list(pageLength = page_length, dom = "ftip", autoWidth = FALSE,
                                 language = list(search = "Search:")), options)
  args <- utils::modifyList(list(data = data, rownames = FALSE, class = "phw-dt compact hover",
                                 options = opts, style = "default"), list(...))
  w <- do.call(DT::datatable, args)
  num <- names(data)[vapply(data, is.numeric, logical(1))]
  is_int <- vapply(data[num], function(v) all(v == round(v), na.rm = TRUE), logical(1))
  if (any(is_int)) w <- DT::formatRound(w, num[is_int], digits = 0)
  if (any(!is_int)) w <- DT::formatRound(w, num[!is_int], digits = digits)
  w$dependencies <- c(w$dependencies, list(phw_font_dependency(), phw_dt_css()))
  wrap_widget(w, caption, caption_from(source, date, caption_args))
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
#' @param title_size Title font size.
#' @param caption_args List of other [phw_caption()] arguments.
#' @param alt Alternative text for the chart or table on the slide, read out
#'   by screen readers. `NULL` adds none, except that a ggplot's own
#'   `labs(alt = )` text is used when there is one.
#' @export
phw_add_slide <- function(x, title = NULL, plot = NULL, table = NULL, text = NULL,
                          source = NULL, date = NULL, layout = "Title and Content",
                          master = NULL, editable = TRUE, title_size = 28,
                          caption_args = list(), alt = NULL) {
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
  x <- officer::add_slide(x, layout = layout, master = master)
  types <- officer::layout_properties(x, layout = layout, master = master)$type
  navy <- phw_colours[["navy"]]
  if (!is.null(title)) {
    tp <- officer::fpar(officer::ftext(title, officer::fp_text(font.family = phw_font(), font.size = title_size,
                                                                  bold = TRUE, color = navy)))
    x <- officer::ph_with(x, tp, location = officer::ph_location_type(if ("ctrTitle" %in% types) "ctrTitle" else "title"))
  }
  body <- officer::ph_location_type(if ("subTitle" %in% types) "subTitle" else "body")
  if (!is.null(plot)) {
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
    ft <- if (inherits(table, "flextable")) table else phw_flextable(table)
    x <- officer::ph_with(x, ft, location = body)
    x <- set_slide_alt(x, alt)
  } else if (!is.null(text)) {
    if ("subTitle" %in% types) {
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
    on_navy <- "subTitle" %in% types || layout == "Section Header"
    fp <- officer::fp_text(font.family = phw_font(), font.size = 10, bold = TRUE,
                           color = phw_colours[[if (on_navy) "white" else "text"]])
    x <- officer::ph_with(x, officer::fpar(officer::ftext(gsub("\n", " | ", cap), fp),
                                           fp_p = officer::fp_par(text.align = "right")),
                          location = officer::ph_location(left = 0.6, top = size$height - 0.6,
                                                          width = size$width - 1.2, height = 0.4))
  }
  x
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
