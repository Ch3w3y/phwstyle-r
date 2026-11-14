#' Apply PHW styling to a flextable
#'
#' Styles an existing flextable the way PHW and its Communicable Disease
#' Surveillance Centre (CDSC) present tables in reports. Four styles are available:
#'
#' * `"booktabs"` (default): horizontal rules only, as in printed journal
#'   tables: a navy rule above and below the header and along the bottom, a
#'   bold header, no vertical lines and no fill.
#' * `"header"`: a navy header band with white bold text.
#' * `"light"`: a light-teal header band with dark text (as in the weekly acute
#'   respiratory infection report).
#' * `"zebra"`: `"booktabs"` plus light grey banding on alternate rows.
#'
#' Numbers are right-aligned and text is left-aligned. In every style the
#' font is Ubuntu (or the [phw_font()] fallback).
#'
#' @param x A flextable.
#' @param style `"booktabs"`, `"header"`, `"light"` or `"zebra"`.
#' @param font_size Body font size in points. Header uses the same size.
#' @param font_family Font family.
#' @param bold_first_col Bold the first column? (Area names in many PHW tables.)
#' @param total_row Treat the last row as a total row (bold with a rule
#'   above)?
#' @param accent Colour of the rules and header (navy by default).
#' @param header_bg,header_colour Override the header fill and text colour.
#' @param text_colour Body text colour.
#' @param stripe_colour Fill for alternate rows in `"zebra"`.
#' @param padding Cell padding in points: one number, or
#'   `c(top_bottom, left_right)`, or `NULL` to keep the existing padding
#'   (for tables that use padding for indents, such as gtsummary output).
#' @param align Align numbers right and text left automatically? Set to
#'   `FALSE` to keep your own alignment.
#' @return A flextable.
#' @examples
#' if (requireNamespace("flextable", quietly = TRUE)) {
#'   ft <- flextable::flextable(head(airquality))
#'   phw_flextable_theme(ft)
#' }
#' @export
phw_flextable_theme <- function(x, style = c("booktabs", "header", "light", "zebra"),
                                font_size = 10, font_family = phw_font(),
                                bold_first_col = FALSE, total_row = FALSE,
                                accent = phw_colours[["navy"]], header_bg = NULL,
                                header_colour = NULL, text_colour = phw_colours[["text"]],
                                stripe_colour = phw_colours[["grey_bg"]],
                                padding = c(3, 5), align = TRUE) {
  rlang::check_installed(c("flextable", "officer"))
  style <- rlang::arg_match(style)
  col <- phw_colours
  col[["navy"]] <- accent
  col[["text"]] <- text_colour
  col[["grey_bg"]] <- stripe_colour
  ft <- flextable::font(x, fontname = font_family, part = "all")
  ft <- flextable::fontsize(ft, size = font_size, part = "all")
  ft <- flextable::color(ft, color = col[["text"]], part = "all")
  ft <- flextable::border_remove(ft)
  ft <- flextable::bg(ft, bg = "transparent", part = "all")
  ft <- flextable::bold(ft, part = "header")
  ft <- flextable::valign(ft, valign = "center", part = "all")
  if (!is.null(padding)) {
    pad <- rep_len(padding, 2)
    ft <- flextable::padding(ft, padding.top = pad[1], padding.bottom = pad[1],
                             padding.left = pad[2], padding.right = pad[2], part = "all")
  }
  ft <- flextable::line_spacing(ft, space = 1, part = "all")

  navy <- officer::fp_border(color = col[["navy"]], width = 1.5)
  thin <- officer::fp_border(color = col[["grey_border"]], width = 0.75)
  nb <- nrow_part(ft, "body")

  if (style %in% c("booktabs", "zebra")) {
    ft <- flextable::hline_top(ft, border = navy, part = "header")
    ft <- flextable::hline_bottom(ft, border = navy, part = "header")
    ft <- flextable::hline_bottom(ft, border = navy, part = "body")
    ft <- flextable::color(ft, color = col[["navy"]], part = "header")
  }
  if (style == "header") {
    ft <- flextable::bg(ft, bg = col[["navy"]], part = "header")
    ft <- flextable::color(ft, color = "#FFFFFF", part = "header")
    ft <- flextable::hline(ft, border = thin, part = "body")
    ft <- flextable::hline_bottom(ft, border = navy, part = "body")
  }
  if (style == "light") {
    ft <- flextable::bg(ft, bg = col[["light_teal"]], part = "header")
    ft <- flextable::color(ft, color = col[["text"]], part = "header")
    ft <- flextable::border_outer(ft, border = thin, part = "all")
    ft <- flextable::border_inner(ft, border = thin, part = "all")
  }
  if (style == "zebra" && nb > 1) {
    even <- seq(2, nb, by = 2)
    ft <- flextable::bg(ft, i = even, bg = col[["grey_bg"]], part = "body")
  }
  if (bold_first_col) ft <- flextable::bold(ft, j = 1, part = "body")
  if (total_row && nb > 0) {
    ft <- flextable::bold(ft, i = nb, part = "body")
    if (nb > 1) ft <- flextable::hline(ft, i = nb - 1, border = navy, part = "body")
  }

  if (!is.null(header_bg)) ft <- flextable::bg(ft, bg = header_bg, part = "header")
  if (!is.null(header_colour)) ft <- flextable::color(ft, color = header_colour, part = "header")
  if (align) ft <- align_by_type(ft)
  ft
}

nrow_part <- function(ft, part) {
  ft[[part]]$content$nrow %||% nrow(ft[[part]]$dataset)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

align_by_type <- function(ft) {
  data <- ft$body$dataset
  keys <- ft$col_keys
  num <- keys[keys %in% names(data) & vapply(keys, function(k) {
    k %in% names(data) && is.numeric(data[[k]])
  }, logical(1))]
  txt <- setdiff(keys, num)
  if (length(num)) ft <- flextable::align(ft, j = num, align = "right", part = "all")
  if (length(txt)) ft <- flextable::align(ft, j = txt, align = "left", part = "all")
  ft
}

#' Make a PHW-styled flextable from a data frame
#'
#' One call that builds a flextable, formats numbers with thousands
#' separators, applies [phw_flextable_theme()] and adds the PHW caption and
#' source line. The caption ("Table 1 ...") goes above and the bold source
#' goes below, right-aligned.
#'
#' @param data A data frame, or a summary table from [phw_summary_table()],
#'   [phw_crosstab()], [phw_rate_table()] or [phw_risk_table()]. Summary
#'   tables get bold variable headings, indented levels, a header spanning
#'   the group columns and a note on the statistics shown.
#' @param caption Table title, e.g. `"Counts by health board, 2020-2024"`.
#' @param number Optional table number. Gives "Table 1 ...".
#' @param number_prefix Word before the number.
#' @param source,date Passed to [phw_caption()] and shown under the table.
#' @param caption_args List of other [phw_caption()] arguments, e.g.
#'   `list(note = "Provisional")`.
#' @param flextable_args List of arguments for [flextable::flextable()],
#'   e.g. `list(col_keys = c("area", "rate"))`.
#' @param style Passed to [phw_flextable_theme()].
#' @param digits Decimal places for non-integer numbers.
#' @param col_labels Optional named list of display names, as in
#'   [flextable::set_header_labels()].
#' @param autofit Fit column widths to their content?
#' @param ... Passed to [phw_flextable_theme()].
#' @return A flextable.
#' @examples
#' if (requireNamespace("flextable", quietly = TRUE)) {
#'   phw_flextable(head(mtcars[, 1:4]), caption = "Example", source = "mtcars")
#' }
#' @export
phw_flextable <- function(data, caption = NULL, number = NULL, source = NULL,
                          date = NULL, style = "booktabs", digits = 1,
                          col_labels = NULL, autofit = TRUE, number_prefix = "Table",
                          caption_args = list(), flextable_args = list(), ...) {
  rlang::check_installed(c("flextable", "officer"))
  check_unique_names(data)
  ft <- do.call(flextable::flextable, c(list(as.data.frame(data)), flextable_args))
  shown <- names(data) %in% ft$col_keys
  is_int <- vapply(data, function(v) is.numeric(v) && all(v == round(v), na.rm = TRUE), logical(1)) & shown
  is_dbl <- vapply(data, is.numeric, logical(1)) & shown & !is_int
  if (any(is_int)) ft <- flextable::colformat_double(ft, j = names(data)[is_int], digits = 0, big.mark = ",", na_str = "")
  if (any(is_dbl)) ft <- flextable::colformat_double(ft, j = names(data)[is_dbl], digits = digits, big.mark = ",", na_str = "")
  if (!is.null(col_labels)) ft <- do.call(flextable::set_header_labels, c(list(ft), col_labels))
  ft <- phw_flextable_theme(ft, style = style, ...)
  if (inherits(data, "phw_summary")) ft <- style_summary_ft(ft, data)

  if (!is.null(caption)) {
    title <- if (is.null(number)) caption else paste(number_prefix, number, caption)
    ft <- flextable::set_caption(
      ft,
      caption = flextable::as_paragraph(flextable::as_chunk(
        title,
        props = officer::fp_text(font.family = phw_font(), bold = TRUE,
                                 color = phw_colours[["navy"]], font.size = 11))),
      fp_p = officer::fp_par(text.align = "left", padding.bottom = 4),
      align_with_table = FALSE)
  }
  cap <- caption_from(source, date, caption_args)
  if (!is.null(cap)) {
    ft <- flextable::add_footer_lines(ft, values = cap)
    k <- flextable::nrow_part(ft, "footer")
    ft <- flextable::style(ft, i = k, part = "footer",
                           pr_t = officer::fp_text(bold = TRUE, italic = FALSE, font.size = 8.5,
                                                   font.family = phw_font(), color = phw_colours[["text"]]))
    ft <- flextable::align(ft, i = k, align = "right", part = "footer")
  }
  if (autofit) ft <- flextable::autofit(ft)
  ft
}

#' Set PHW defaults for every new flextable
#'
#' Sets [flextable::set_flextable_defaults()] so all new flextables use the
#' PHW font, colours and padding, and applies [phw_flextable_theme()]
#' automatically. Put it in your setup chunk.
#'
#' @param style Passed to [phw_flextable_theme()].
#' @param font_size Body font size.
#' @param ... Other [phw_flextable_theme()] arguments, e.g. `accent`.
#' @return The previous defaults, invisibly.
#' @examples
#' if (requireNamespace("flextable", quietly = TRUE)) {
#'   old <- use_phw_flextable()
#'   flextable::flextable(head(airquality))
#'
#'   # Put back the defaults you had before
#'   do.call(flextable::set_flextable_defaults, old)
#' }
#' @export
use_phw_flextable <- function(style = "booktabs", font_size = 10, ...) {
  rlang::check_installed(c("flextable", "officer"))
  style <- rlang::arg_match(style, c("booktabs", "header", "light", "zebra"))
  theme_args <- list(...)
  old <- flextable::set_flextable_defaults(
    font.family = phw_font(), font.size = font_size,
    font.color = phw_colours[["text"]],
    border.color = phw_colours[["grey_border"]],
    padding.top = 3, padding.bottom = 3, padding.left = 5, padding.right = 5,
    big.mark = ",", decimal.mark = ".", digits = 1, na_str = "",
    theme_fun = function(x) do.call(phw_flextable_theme, c(list(x, style = style, font_size = font_size), theme_args))
  )
  invisible(old)
}

#' Colour flextable cells by value
#'
#' Fills cells in the given columns with a PHW sequential palette, the way
#' PHW heat tables do, and picks white or dark text automatically so values
#' stay readable.
#'
#' For `palette = "rag"`, colour alone doesn't work for colour-blind
#' readers or in black-and-white print, so `symbols = TRUE` (the default)
#' adds a shape before each value as well.
#'
#' @param x A flextable.
#' @param j Columns to colour, chosen as in [dplyr::select()]: unquoted
#'   names such as `c(rate, cases)`, positions such as `2:5`, or strings.
#' @param palette A sequential or diverging palette name, a vector of
#'   colours, `"rag"` or `"rag_accessible"` (navy instead of green).
#' @param domain Range of values the palette spans. Defaults to the range of
#'   the selected columns.
#' @param breaks For `palette = "rag"`: two cut points (red below the first,
#'   green at or above the second).
#' @param higher_is_better For `"rag"`: is a high value good (green)?
#' @param symbols For `"rag"`: add a shape before each value (a down
#'   triangle for red, a square for amber, an up triangle for green)?
#' @return A flextable.
#' @examples
#' if (requireNamespace("flextable", quietly = TRUE)) {
#'   rates <- data.frame(Area = paste("Area", LETTERS[1:4]),
#'                       `2024` = c(3.2, 1.5, 3.8, 2.3), `2025` = c(4.4, 0.7, 4.2, 0.2),
#'                       check.names = FALSE)
#'   phw_flextable(rates) |>
#'     phw_flextable_heat(j = 2:3)
#'
#'   # Red, amber and green, with a shape in each cell as a second cue
#'   uptake <- data.frame(Area = paste("Area", LETTERS[1:4]),
#'                        Uptake = c(0.96, 0.93, 0.91, 0.95))
#'   phw_flextable(uptake, digits = 2) |>
#'     phw_flextable_heat(Uptake, palette = "rag_accessible", breaks = c(0.92, 0.95))
#' }
#' @export
phw_flextable_heat <- function(x, j, palette = "teals", domain = NULL, breaks = NULL,
                               higher_is_better = TRUE, symbols = TRUE) {
  rlang::check_installed("flextable")
  check_flextable(x)
  data <- x$body$dataset
  j <- pick_cols(rlang::enquo(j), data, "j")
  j <- value_cols(data, j, "j")
  if (!length(j)) return(x)
  vals <- unlist(data[j])
  rag <- identical(palette, "rag") || identical(palette, "rag_accessible")
  if (rag) {
    check_breaks(breaks)
    rag_status <- function(v) {
      st <- ifelse(v < breaks[1], "low", ifelse(v < breaks[2], "mid", "high"))
      if (higher_is_better) c(low = "red", mid = "amber", high = "green")[st]
      else c(low = "green", mid = "amber", high = "red")[st]
    }
    fill_fun <- function(v) {
      out <- unname(phw_palettes[[palette]][rag_status(v)])
      out[is.na(v)] <- "transparent"
      out
    }
  } else {
    domain <- domain %||% range(vals, na.rm = TRUE)
    fill_fun <- scales::col_numeric(seq_cols(palette, FALSE), domain = domain, na.color = "transparent")
  }
  shapes <- c(red = "\u25BC", amber = "\u25A0", green = "\u25B2")
  for (col in j) {
    v <- data[[col]]
    fills <- fill_fun(v)
    x <- flextable::bg(x, j = col, bg = fills, part = "body")
    txt <- ifelse(fills == "transparent", phw_colours[["text"]], phw_text_on(sub("transparent", "#FFFFFF", fills)))
    x <- flextable::color(x, j = col, color = txt, part = "body")
    if (rag && symbols) {
      st <- unname(rag_status(v))
      shown <- ifelse(is.na(v), "", paste(shapes[st], format(v, big.mark = ",", trim = TRUE)))
      x <- flextable::compose(x, j = col, part = "body",
                              value = flextable::as_paragraph(flextable::as_chunk(shown)))
    }
  }
  x
}

#' Colour flextable cells by group
#'
#' Colours cells by the group they contain, using the same colours as your
#' charts. With a `key`, each group keeps its colour across tables, charts
#' and reports (see [phw_colour_key()]).
#'
#' @param x A flextable.
#' @param j Column that holds the groups, unquoted as in dplyr. A string or
#'   a position works too.
#' @param key,palette,values Passed to [phw_colour_key()] as `name`,
#'   `palette` and `fixed`.
#' @param what Colour the cell `"background"` or the `"text"`?
#' @param rows Colour the whole row (`TRUE`) or only column `j`?
#' @return A flextable.
#' @examples
#' if (requireNamespace("flextable", quietly = TRUE)) {
#'   df <- data.frame(Group = c("Group A", "Group B", "Group C", "Unknown"),
#'                    Cases = c(120, 85, 64, 9))
#'   phw_flextable(df) |>
#'     phw_flextable_groups(Group)
#'
#'   # Colour the text instead, across the whole row
#'   phw_flextable(df) |>
#'     phw_flextable_groups(Group, what = "text", rows = TRUE)
#' }
#' @export
phw_flextable_groups <- function(x, j, key = NULL, palette = phw_default_palette(),
                                 values = NULL, what = c("background", "text"), rows = FALSE) {
  rlang::check_installed("flextable")
  what <- rlang::arg_match(what)
  check_flextable(x)
  data <- x$body$dataset
  j <- pick_col(rlang::enquo(j), data, "j")
  groups <- data[[j]]
  cols <- phw_colour_key(groups, name = key, palette = palette, fixed = values)
  fill <- unname(cols[as.character(groups)])
  target <- if (rows) x$col_keys else j
  for (k in target) {
    if (what == "background") {
      x <- flextable::bg(x, j = k, bg = fill, part = "body")
      x <- flextable::color(x, j = k, color = phw_text_on(fill), part = "body")
    } else {
      x <- flextable::color(x, j = k, color = fill, part = "body")
    }
  }
  x
}

style_summary_ft <- function(ft, x) {
  r <- summary_rows(x)
  nl <- attr(x, "label_cols") %||% 1L
  nc <- ncol(x)
  navy <- officer::fp_border(color = phw_colours[["navy"]], width = 1)
  grey <- officer::fp_border(color = phw_colours[["grey_mid"]], width = 0.75)
  lab_j <- seq_len(nl)
  ft <- flextable::align(ft, j = lab_j, align = "left", part = "all")
  if (any(r$bold)) ft <- flextable::bold(ft, i = which(r$bold), part = "body")
  if (any(r$navy)) ft <- flextable::color(ft, i = which(r$navy), j = lab_j, color = phw_colours[["navy"]], part = "body")
  if (any(r$shade)) ft <- flextable::bg(ft, i = which(r$shade), bg = phw_colours[["grey_bg"]], part = "body")
  if (any(r$italic)) ft <- flextable::italic(ft, i = which(r$italic), j = lab_j, part = "body")
  for (d in setdiff(unique(r$indent), 0)) {
    ft <- flextable::padding(ft, i = which(r$indent == d), j = 1, padding.left = 4 + 12 * d, part = "body")
  }
  tot <- which(r$rule)
  above <- tot[tot > 1] - 1
  if (length(above)) ft <- flextable::hline(ft, i = above, border = navy, part = "body")
  if (1 %in% tot && nrow(x) > 1) ft <- flextable::hline(ft, i = 1, border = navy, part = "body")
  if (any(r$space)) ft <- flextable::padding(ft, i = which(r$space), padding.top = 10, part = "body")
  line <- setdiff(which(r$line) - 1, 0)
  if (length(line)) ft <- flextable::hline(ft, i = line, border = grey, part = "body")
  # Numbers and statistics right-aligned, whatever their type.
  if (nc > nl) ft <- flextable::align(ft, j = seq(nl + 1, nc), align = "right", part = "all")
  ch <- attr(x, "col_header")
  sp <- attr(x, "spanner")
  if (!is.null(ch)) {
    data_j <- seq(nl + 1, nc)
    L <- nrow(ch)
    labs <- stats::setNames(as.list(ch[L, ]), names(x)[data_j])
    ft <- do.call(flextable::set_header_labels, c(list(ft), labs))
    for (l in rev(seq_len(L - 1))) {
      key <- apply(ch[seq_len(l), , drop = FALSE], 2, paste, collapse = "\r")
      r <- rle(key)
      vals <- ch[l, cumsum(r$lengths)]
      ft <- flextable::add_header_row(ft, values = c(rep("", nl), vals), colwidths = c(rep(1, nl), r$lengths))
      ft <- flextable::hline(ft, i = 1, j = data_j, border = grey, part = "header")
    }
    ft <- flextable::merge_v(ft, j = data_j, part = "header")
    ft <- flextable::align(ft, i = seq_len(L - 1), j = data_j, align = "center", part = "header")
    ft <- flextable::bold(ft, part = "header")
    ft <- flextable::color(ft, i = seq_len(L - 1), color = phw_colours[["navy"]], part = "header")
  } else if (!is.null(sp) && nc > nl) {
    ft <- flextable::add_header_row(ft, values = c(rep("", nl), sp), colwidths = c(rep(1, nl), nc - nl))
    ft <- flextable::align(ft, i = 1, j = seq(nl + 1, nc), align = "center", part = "header")
    ft <- flextable::bold(ft, part = "header")
    ft <- flextable::color(ft, i = 1, color = phw_colours[["navy"]], part = "header")
    ft <- flextable::hline(ft, i = 1, j = seq(nl + 1, nc), border = grey, part = "header")
  }
  note <- attr(x, "note")
  if (!is.null(note)) {
    ft <- flextable::add_footer_lines(ft, values = note)
    ft <- flextable::italic(ft, i = flextable::nrow_part(ft, "footer"), part = "footer")
    ft <- flextable::fontsize(ft, i = flextable::nrow_part(ft, "footer"), size = 8.5, part = "footer")
    ft <- flextable::color(ft, i = flextable::nrow_part(ft, "footer"), color = phw_colours[["text_secondary"]], part = "footer")
  }
  ft
}

#' Add in-cell bars to a flextable
#'
#' Draws a small horizontal bar before each value, scaled to the largest
#' value in the column, so readers can compare sizes at a glance (as in
#' many PHW summary tables).
#'
#' @param x A flextable.
#' @param j Columns, chosen as in [dplyr::select()]: unquoted names,
#'   positions or strings.
#' @param colour Bar colour.
#' @param width,height Bar size in inches.
#' @param digits Decimal places for the value.
#' @return A flextable.
#' @examples
#' if (requireNamespace("flextable", quietly = TRUE)) {
#'   df <- data.frame(Area = paste("Area", LETTERS[1:4]), Cases = c(120, 85, 64, 19))
#'   phw_flextable_bars(phw_flextable(df), Cases)
#' }
#' @export
phw_flextable_bars <- function(x, j, colour = phw_colours[["light_teal"]], width = 0.9,
                               height = 0.1, digits = 0) {
  rlang::check_installed("flextable")
  check_flextable(x)
  data <- x$body$dataset
  j <- pick_cols(rlang::enquo(j), data, "j")
  j <- value_cols(data, j, "j")
  for (col in j) check_bar_values(data[[col]], col, "j")
  for (col in j) {
    v <- data[[col]]
    mx <- max(v, na.rm = TRUE)
    x <- flextable::compose(x, j = col, part = "body", value = flextable::as_paragraph(
      flextable::minibar(value = ifelse(is.na(v), 0, v), max = mx, barcol = colour,
                         bg = "transparent", width = width, height = height),
      " ", flextable::as_chunk(ifelse(is.na(v), "", fmt_num(v, digits)))))
    x <- flextable::align(x, j = col, align = "left", part = "all")
    # Room for the bar, a space, the widest number and the cell padding, so
    # the number never wraps under the bar.
    size <- x$body$styles$text$font.size$data[1, col] %||% 11
    x <- flextable::width(x, j = col, width = width + 0.3 + size * 0.62 / 72 * max(nchar(fmt_num(v, digits)), 1))
  }
  x
}
