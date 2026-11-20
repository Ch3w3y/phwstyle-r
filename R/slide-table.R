# Slides are projected, so no text in a table on a slide is smaller than this,
# in points.
slide_min_size <- 12

# A table with room on its slide grows its text up to this size, in points,
# the usual size of projected body text.
slide_max_size <- 18

# A table as it goes on slides, as a list of flextables, one per slide. Its
# caption becomes the top row, its text is at least `slide_min_size` points,
# and a table wider than `width` wraps its headings, then its cells. A table
# taller than `height` tightens its row spacing and then shares its body rows
# out over as many slides as it takes. Each slide repeats the header rows,
# with the caption marked `continued` after the first, and the footer (the
# source line) goes on the last. With `grow`, a table with room to spare
# grows to fill the space (see grow_to_area()).
slide_table_pages <- function(ft, width, height, continued = NULL, where = "the slide", grow = FALSE) {
  continued <- continued %||% attr(ft, "phw_continued") %||% "(continued)"
  caption <- caption_text(ft)
  ft <- caption_as_header(ft)
  ft <- slide_text_size(ft)
  ft <- fit_table_to_width(ft, width, min_size = slide_min_size, where = where, floor = "all")
  if (grow) ft <- grow_to_area(ft, width, height)
  ft <- fit_rows_to_height(ft, height)
  rows <- slide_rows(ft, height, keep_rows(ft))
  if (length(rows) == 1) return(list(ft))
  body <- seq_len(flextable::nrow_part(ft, "body"))
  last <- length(body)
  lapply(seq_along(rows), function(k) {
    page <- flextable::delete_rows(ft, setdiff(body, rows[[k]]), part = "body")
    # delete_rows() turns a one-column dataset into a vector.
    page$body$dataset <- ft$body$dataset[rows[[k]], , drop = FALSE]
    # The rule under the table goes under each slide's part of it.
    for (prop in c("border.width.bottom", "border.color.bottom", "border.style.bottom")) {
      cells <- page$body$styles$cells[[prop]]$data
      cells[nrow(cells), ] <- ft$body$styles$cells[[prop]]$data[last, ]
      page$body$styles$cells[[prop]]$data <- cells
    }
    if (k < length(rows) && flextable::nrow_part(page, "footer")) page <- flextable::delete_part(page, "footer")
    if (k > 1 && length(caption)) {
      page <- flextable::compose(page, i = 1, part = "header",
                                 value = flextable::as_paragraph(paste(caption, continued)))
    }
    page
  })
}

caption_text <- function(ft) {
  caption <- ft$caption$value
  text <- if (is.character(caption)) caption else paste(caption$txt, collapse = "")
  if (length(text) && nzchar(text)) text
}

# Text below `slide_min_size` grows to it, and each column widens as much as
# its text grew, so the table wraps as it did before.
slide_text_size <- function(ft) {
  grow <- rep(1, length(ft$col_keys))
  for (part in c("header", "body", "footer")) {
    if (!flextable::nrow_part(ft, part)) next
    sizes <- ft[[part]]$styles$text$font.size$data
    raised <- pmax(sizes, slide_min_size)
    # A merged cell, such as the caption row, spans columns it doesn't size.
    ratio <- ifelse(ft[[part]]$spans$rows == 1, raised / sizes, 1)
    grow <- pmax(grow, apply(ratio, 2, max, na.rm = TRUE))
    ft[[part]]$styles$text$font.size$data[] <- raised
    ft[[part]]$content$data[] <- lapply(ft[[part]]$content$data, function(chunks) {
      chunks$font.size <- pmax(chunks$font.size, slide_min_size)
      chunks
    })
  }
  flextable::width(ft, j = seq_along(grow), width = ft$body$colwidths * grow)
}

# Grows the text of a table with room to spare, and its column widths with
# it, to the largest size up to `slide_max_size` points, in steps of `step`,
# at which the table still takes no more slides than before and no taller a
# part of one. A table over several slides grows as one, so each slide shows
# the same size. Then the columns widen to fill more of `width`, by at most
# `max_pad` times, and a little more for each column past two.
grow_to_area <- function(ft, width, height, step = 0.5, max_pad = 1.8) {
  parts <- Filter(function(part) flextable::nrow_part(ft, part) > 0, c("header", "body", "footer"))
  top <- max(unlist(lapply(parts, function(part) ft[[part]]$styles$text$font.size$data)), na.rm = TRUE)
  most <- min(slide_max_size, top * width / sum(ft$body$colwidths))
  if (most >= top + step && flextable::nrow_part(ft, "body")) {
    keep <- keep_rows(ft)
    layout <- function(ft) {
      ft <- fit_rows_to_height(ft, height)
      rows <- slide_rows(ft, height, keep)
      body <- ft$body$rowheights
      tall <- vapply(rows, function(r) sum(body[r]), numeric(1))
      tall[length(tall)] <- tall[length(tall)] + sum(ft$footer$rowheights)
      c(slides = length(rows), tallest = sum(ft$header$rowheights) + max(tall))
    }
    before <- layout(ft)
    fits <- function(size) {
      after <- layout(scale_text(ft, parts, size / top))
      after[["slides"]] <= before[["slides"]] && after[["tallest"]] <= max(height, before[["tallest"]]) + 0.001
    }
    sizes <- seq(top, most, by = step)
    lo <- 1
    hi <- length(sizes)
    while (lo < hi) {
      mid <- ceiling((lo + hi) / 2)
      if (fits(sizes[mid])) lo <- mid else hi <- mid - 1
    }
    ft <- scale_text(ft, parts, sizes[lo] / top)
  }
  widths <- ft$body$colwidths
  pad <- max(min(width / sum(widths), max_pad + 0.3 * max(length(widths) - 2, 0)), 1)
  flextable::width(ft, j = seq_along(widths), width = widths * pad)
}

# Multiplies every text size, and each column's width, by `scale`.
scale_text <- function(ft, parts, scale) {
  for (part in parts) {
    ft[[part]]$styles$text$font.size$data[] <- ft[[part]]$styles$text$font.size$data * scale
    ft[[part]]$content$data[] <- lapply(ft[[part]]$content$data, function(chunks) {
      chunks$font.size <- chunks$font.size * scale
      chunks
    })
  }
  flextable::width(ft, j = seq_along(ft$col_keys), width = ft$body$colwidths * scale)
}

# The body rows a slide must not end on, such as a group's heading.
keep_rows <- function(ft) {
  keep <- attr(ft, "phw_keep")
  if (length(keep) == flextable::nrow_part(ft, "body")) keep
}

# Sets each row to the height its text needs, wrapped at the column widths.
# Slides treat row heights as minimums. A table taller than `height` first
# tightens the padding above and below its text to `tight_pad` points.
fit_rows_to_height <- function(ft, height, tight_pad = 2) {
  parts <- Filter(function(part) flextable::nrow_part(ft, part) > 0, c("header", "body", "footer"))
  needed <- function(ft) lapply(parts, function(part) row_heights(ft, part))
  heights <- needed(ft)
  if (sum(unlist(heights)) > height) {
    ft <- flextable::padding(ft, padding.top = tight_pad, padding.bottom = tight_pad, part = "all")
    heights <- needed(ft)
  }
  for (k in seq_along(parts)) ft <- flextable::height(ft, height = heights[[k]], part = parts[k])
  ft
}

# The body rows on each slide: as few slides as the rows need, the rows
# shared out evenly between them where their heights allow. The footer goes
# with the last row, and a slide doesn't end on a row marked in `keep`, such
# as a group's heading. A row too tall for a slide alone still gets one, and
# a table with no rows gets one slide for its header and footer.
slide_rows <- function(ft, height, keep = NULL) {
  keep <- keep %||% logical(length(ft$body$rowheights))
  head <- sum(ft$header$rowheights)
  need <- ft$body$rowheights
  n <- length(need)
  if (!n) return(list(integer()))
  need[n] <- need[n] + sum(ft$footer$rowheights)
  pages <- function(most) {
    out <- list()
    i <- 1
    while (i <= n) {
      used <- head
      rows <- integer()
      while (i <= n && length(rows) < most && (!length(rows) || used + need[i] <= height + 0.001)) {
        used <- used + need[i]
        rows <- c(rows, i)
        i <- i + 1
      }
      while (i <= n && length(rows) > 1 && keep[rows[length(rows)]]) {
        rows <- rows[-length(rows)]
        i <- i - 1
      }
      out <- c(out, list(rows))
    }
    out
  }
  fewest <- pages(n)
  even <- pages(ceiling(n / length(fewest)))
  if (length(even) == length(fewest)) even else fewest
}

# Row heights in inches from the text size, the number of lines each cell's
# text wraps to, and the padding. 1.25 times the text size per line leaves
# room for PowerPoint's line spacing.
row_heights <- function(ft, part, line_height = 1.25) {
  p <- ft[[part]]
  sizes <- p$styles$text$font.size$data
  lines <- matrix(0, nrow(sizes), ncol(sizes))
  for (i in seq_len(nrow(sizes))) {
    for (j in seq_len(ncol(sizes))) {
      span <- p$spans$rows[i, j]
      if (span < 1) next
      chunks <- p$content$data[[i, j]]
      size <- max(sizes[i, j], chunks$font.size, na.rm = TRUE)
      room <- sum(p$colwidths[j:(j + span - 1)]) * 72 -
        p$styles$pars$padding.left$data[i, j] - p$styles$pars$padding.right$data[i, j]
      bold <- isTRUE(p$styles$text$bold$data[i, j]) || any(chunks$bold %in% TRUE)
      lines[i, j] <- wrapped_lines(paste(chunks$txt, collapse = ""), room,
                                   p$styles$text$font.family$data[i, j], bold, size) * size
    }
  }
  pads <- p$styles$pars$padding.top$data + p$styles$pars$padding.bottom$data
  apply(lines * line_height + pads, 1, max) / 72
}

# How many lines `text` takes in `room` points, wrapped at spaces as
# PowerPoint does. A word wider than the room breaks over lines.
wrapped_lines <- function(text, room, family, bold, size) {
  room <- max(room, 1)
  pars <- strsplit(text, "\n", fixed = TRUE)[[1]]
  counts <- vapply(pars, function(par) {
    words <- strsplit(par, " ", fixed = TRUE)[[1]]
    if (!length(words)) return(1)
    widths <- text_widths(c(" ", words), family, bold, size)
    space <- widths[1]
    widths <- widths[-1]
    lines <- 0
    used <- Inf
    for (w in widths) {
      if (used + space + w <= room) {
        used <- used + space + w
      } else {
        k <- max(ceiling(w / room), 1)
        lines <- lines + k
        used <- w - (k - 1) * room
      }
    }
    lines
  }, numeric(1))
  max(sum(counts), 1)
}

# Widths in points. systemfonts 1.2.4 replaced `bold` with `weight`.
text_widths <- function(x, family, bold, size) {
  style <- if ("weight" %in% names(formals(systemfonts::string_width))) {
    list(weight = if (bold) "bold" else "normal")
  } else {
    list(bold = bold)
  }
  do.call(systemfonts::string_width, c(list(x, family = family, size = size, res = 72), style))
}
