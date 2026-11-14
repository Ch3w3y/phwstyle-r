#' Public Health Wales brand colours
#'
#' A named character vector of every colour in the PHW identity, as used by
#' its Communicable Disease Surveillance Centre (CDSC).
#' Each colour and its role is listed in
#' `system.file("brand", "palette.csv", package = "phwstyle")`.
#'
#' * `navy`, `teal`, `orange`, `pink` are the four chart colours PHW reports
#'   use today, in that order.
#' * `blue_534` and `gold_465` are the official NHS Wales logo colours
#'   (Pantone 534 and 465).
#' * `blue`, `green`, `magenta` come from the phw.nhs.wales website.
#' * Greys and `text` are the NHS digital front-end neutrals used on the site.
#' * `mint` and `green_bright` are two of the six strategic priority colours
#'   in PHW's Long-Term Strategy 2023 to 2035.
#'
#' @format A named character vector of hex colours.
#' @examples
#' phw_colours["navy"]
#' @export
phw_colours <- c(
  navy           = "#285087",
  navy_dark      = "#1B3660",
  blue_534       = "#325A8A",
  gold_465       = "#CFAB7A",
  black          = "#231F20",
  teal           = "#24A2B5",
  orange         = "#FF5D0C",
  pink           = "#F43882",
  blue           = "#2D78A0",
  green          = "#338276",
  green_dark     = "#173934",
  magenta        = "#D50B5C",
  cyan           = "#27B8CD",
  light_teal     = "#7CC7D3",
  purple         = "#846AA4",
  amber          = "#D97F00",
  mint           = "#5FBDAF",
  green_bright   = "#50AF31",
  text           = "#212B32",
  text_secondary = "#4C6272",
  grey_mid       = "#768692",
  grey_light     = "#AEB7BD",
  grey_border    = "#D8DDE0",
  grey_bg        = "#F0F4F5",
  focus          = "#FFEB3B",
  white          = "#FFFFFF"
)

#' Get PHW colours by name
#'
#' Works like `phw_colours[c(...)]` but gives a clear error for unknown names
#' and returns unnamed values when `names = FALSE`, which is what most
#' plotting functions want.
#'
#' @param ... Colour names (see [phw_colours]). Leave empty to get all.
#' @param names Keep the names on the result?
#' @return A character vector of hex codes.
#' @examples
#' phw_col("navy", "teal")
#' @export
phw_col <- function(..., names = TRUE) {
  cols <- c(...)
  if (length(cols) == 0) return(phw_colours)
  bad <- setdiff(cols, names(phw_colours))
  if (length(bad)) {
    cli::cli_abort(c("Unknown PHW colour{?s}: {.val {bad}}.",
                     i = "Available: {.val {names(phw_colours)}}."))
  }
  out <- phw_colours[cols]
  if (!names) out <- unname(out)
  out
}

#' PHW palettes
#'
#' The palettes the package uses for discrete (qualitative), sequential and
#' diverging scales.
#'
#' * `main` (qualitative, 4): navy, teal, orange, pink. The default. It stays
#'   distinguishable under all three colour-vision deficiencies.
#' * `extended` (qualitative, 12): `main` and eight more. Charts with more
#'   than four groups carry on into it automatically, so every chart in a
#'   report starts with the same four colours. It is built in order of how
#'   well each colour is sourced:
#'   * 1 to 4 are `main`.
#'   * 5 to 7 have a published source: black and gold (Pantone 465) from the
#'     NHS Wales logo guidelines, and the green of the phw.nhs.wales
#'     website.
#'   * 8 and 9 are mint and bright green from the Long-Term Strategy.
#'   * 10 to 12 (blue, dark green, violet) are not PHW colours. They were
#'     chosen in the same hues to stay distinct from the other nine.
#'
#'   Every pair of the twelve stays apart for colour-blind readers: the
#'   colour difference (delta E in CIELAB, a scale where about 10 or more
#'   is easy to tell apart) is at least 15 under simulated deuteranopia and
#'   protanopia, the two red-green types. Gold, mint
#'   and bright green are below 3:1 contrast on white, so they suit filled
#'   shapes better than thin lines. Twelve lines on one chart are still hard
#'   to read: use facets or direct labels where you can.
#' * `accessible` (qualitative, 8): chosen so every pair stays distinct under
#'   simulated deuteranopia, protanopia and tritanopia (minimum colour
#'   difference, delta E, of about 20), and every colour has at least 3:1 contrast on
#'   white. It starts with navy, teal and orange, so short series still look
#'   like PHW. It is never used unless you ask for it: see
#'   [phw_default_palette()] for how to switch a whole script or document
#'   to it.
#' * `highlight` (qualitative, 2): navy for the focus series, light grey for
#'   everything else.
#' * `rag` (qualitative, 3): red / amber / green (RAG) status colours that
#'   keep 3:1 contrast on white. These were chosen for phwstyle, not taken from a PHW source.
#' * `rag_accessible` (qualitative, 3): like `rag`, but "good" is navy
#'   instead of green, because red and green look alike to many colour-blind
#'   readers.
#' * `strategy` (qualitative, 6): the colours of the six strategic
#'   priorities in PHW's Long-Term Strategy 2023 to 2035, named `services`,
#'   `system`, `behaviours`, `wellbeing`, `determinants` and `climate`. Use
#'   it for work reported by priority. The order is not the strategy's own
#'   numbering: it follows `main` (blue, teal, orange, pink, then the rest),
#'   so the first groups in a chart look the same whichever palette is used.
#'   To colour by priority, match on the names.
#' * `blues`, `teals`, `greens`, `gradient` (sequential). `greens` runs from
#'   a pale tint to the website green and its dark shade.
#' * `orange_navy` (diverging).
#'
#' **Colour order.** `main`, `extended` and `accessible` all start navy,
#' teal, orange, so a chart with up to three groups looks the same
#' whichever of them a report uses. `highlight` starts with the same navy,
#' then grey. `strategy` has its own shades in the same order: blue, mint,
#' orange, pink. The exceptions are the palettes where colour carries a
#' fixed meaning (`rag`, `rag_accessible`), and the sequential and diverging
#' palettes, which run from light to dark.
#'
#' @format A named list of character vectors.
#' @examples
#' names(phw_palettes)
#' phw_palettes$main
#' phw_palettes$strategy
#' show_phw_palettes(c("main", "extended", "accessible"))
#' @export
phw_palettes <- list(
  main      = unname(phw_colours[c("navy", "teal", "orange", "pink")]),
  extended  = c(
    # 1-4: the chart colours PHW reports use.
    unname(phw_colours[c("navy", "teal", "orange", "pink")]),
    # 5-7: published sources (NHS Wales logo guidelines; phw.nhs.wales).
    unname(phw_colours[c("black", "green", "gold_465")]),
    # 8-9: Long-Term Strategy 2023 to 2035 priority colours.
    unname(phw_colours[c("mint", "green_bright")]),
    # 10-12: not PHW colours; chosen in the same hues to stay distinct from
    # the rest. See data-raw/palette-search.R.
    "#5A82E6", "#274309", "#730BB1"),
  accessible = c("#285087", "#24A2B5", "#FF5D0C", "#000000", "#9D5659",
                 "#8478CF", "#882255", "#332288"),
  highlight = unname(phw_colours[c("navy", "grey_light")]),
  rag       = c(red = "#D50B5C", amber = "#D97F00", green = "#338276"),
  rag_accessible = c(red = "#D50B5C", amber = "#D97F00", green = "#285087"),
  strategy  = c(services = "#215B8B", system = "#5FBDAF", behaviours = "#ED6F18",
                wellbeing = "#E05A8C", determinants = "#5A356B", climate = "#50AF31"),
  blues     = c("#E8EDF4", "#C9D3E1", "#93A7C3", "#5D7BA5", "#285087", "#1B3660"),
  teals     = c("#E6F5F7", "#B2E0E7", "#7CC7D3", "#24A2B5", "#2D78A0", "#285087"),
  greens    = c("#E8F1F0", "#CCE0DD", "#99C1BB", "#66A198", "#338276", "#173934"),
  gradient  = c("#325082", "#326791", "#2A8DAC", "#2BADC5", "#27B8CD"),
  orange_navy = c("#C94100", "#FF5D0C", "#FFB088", "#F0F4F5", "#93A7C3",
                  "#285087", "#1B3660")
)

# "main" is the first four colours of "extended". Past four groups the
# default carries on into "extended", so a chart with six groups starts with
# the same colours as a chart with four.
palette_for <- function(palette, n) {
  if (identical(palette, "main") && n > length(phw_palettes$main)) "extended" else palette
}

palette_type <- function(name) {
  if (name %in% c("main", "extended", "accessible", "highlight", "rag", "rag_accessible", "strategy")) return("qualitative")
  if (name %in% c("orange_navy")) return("diverging")
  "sequential"
}

#' Get a vector of colours from a PHW palette
#'
#' Qualitative palettes return their colours in order (and refuse to make up
#' extra ones). Sequential and diverging palettes are interpolated to any
#' length. Asking `"main"` for more than four colours carries on into
#' `"extended"`, as the charts do.
#'
#' `palette` can be a PHW palette name, your own vector of colours, or a
#' function of `n`. So any scale or table function in phwstyle accepts a
#' custom palette as easily as a built-in one.
#'
#' @param n Number of colours. Defaults to the palette length.
#' @param palette A palette name (see [phw_palettes]), a character vector of
#'   colours, or a function that takes `n` and returns colours.
#' @param reverse Reverse the order?
#' @param type For a vector of colours: `"qualitative"` (use in order) or
#'   `"sequential"` (interpolate). Names are always qualitative.
#' @return A character vector of hex colours.
#' @examples
#' phw_pal(3)
#' phw_pal(9, "blues")
#' phw_pal(2, c("#285087", "#FF5D0C"))
#' @export
phw_pal <- function(n = NULL, palette = phw_default_palette(), reverse = FALSE,
                    type = c("qualitative", "sequential")) {
  type <- rlang::arg_match(type)
  if (is.function(palette)) {
    out <- palette(n %||% 1L)
  } else {
    palette <- palette_for(palette, n %||% 0L)
    pal <- palette_colours(palette)
    if (is.character(palette) && length(palette) == 1 && palette %in% names(phw_palettes)) {
      type <- if (palette_type(palette) == "qualitative") "qualitative" else "sequential"
    }
    n <- n %||% length(pal)
    if (type == "qualitative") {
      if (n > length(pal)) {
        cli::cli_abort(c(
          "The palette has {length(pal)} colours but {n} were requested.",
          i = "Use facets, direct labels, or highlight one group with {.code palette = \"highlight\"}."))
      }
      out <- pal[seq_len(n)]
    } else {
      out <- grDevices::colorRampPalette(pal, space = "Lab")(n)
    }
  }
  out <- unname(out)
  if (reverse) out <- rev(out)
  out
}

palette_colours <- function(palette) {
  if (is.character(palette) && length(palette) == 1 && palette %in% names(phw_palettes)) {
    return(unname(phw_palettes[[palette]]))
  }
  if (is.character(palette) && length(palette) == 1 && !is_colour(palette)) {
    cli::cli_abort(c("Unknown palette {.val {palette}}.",
                     i = "Use one of {.val {names(phw_palettes)}}, or a vector of colours."))
  }
  if (!is.character(palette) || !all(is_colour(palette))) {
    cli::cli_abort("{.arg palette} must be a palette name, a vector of colours or a function.")
  }
  unname(palette)
}

is_colour <- function(x) {
  vapply(x, function(v) !inherits(try(grDevices::col2rgb(v), silent = TRUE), "try-error"), logical(1))
}

#' The default qualitative palette
#'
#' The palette that charts, tables and widgets use for groups when you
#' don't name one. Out of the box it is `"main"` (navy, teal, orange, pink),
#' carrying on into `"extended"` past four groups, so every chart in a
#' report draws from one set of colours however many groups it has.
#'
#' The colour-blind safe `"accessible"` palette is a switch you turn on
#' once, and it then applies to every chart, table and widget, for any
#' number of groups. The first of these that is set wins:
#'
#' 1. `options(phwstyle.palette = "accessible")`, which is also what
#'    `use_phw_ggplot(palette = "accessible")` and the `palette` argument of
#'    [phw_html_document()], [phw_word_document()] and [phw_pdf_document()]
#'    set.
#' 2. The environment variable `PHWSTYLE_PALETTE`, for switching one render
#'    from the command line without editing the document, e.g.
#'    `PHWSTYLE_PALETTE=accessible quarto render report.qmd`.
#' 3. `phw-palette: accessible` in the YAML header of a Quarto or R Markdown
#'    document.
#'
#' The option can also be any other palette name from [phw_palettes], or
#' your own vector of colours.
#'
#' This switch changes colours only. Larger text and thicker lines are a
#' separate setting, `accessible = TRUE` in [theme_phw()] or
#' [use_phw_ggplot()]; neither turns the other on.
#'
#' @return A palette name or vector.
#' @examples
#' phw_default_palette()
#' phw_pal(6)
#'
#' old <- options(phwstyle.palette = "accessible")
#' phw_pal(6)
#' options(old)
#' @export
phw_default_palette <- function() {
  opt <- getOption("phwstyle.palette")
  if (!is.null(opt)) return(opt)
  env <- Sys.getenv("PHWSTYLE_PALETTE")
  if (nzchar(env)) return(env)
  document_palette() %||% "main"
}

# `phw-palette` from the YAML header of the document being knitted (Quarto
# or R Markdown). Only looked up while knitting, so a document rendered
# earlier in the session doesn't leave its palette behind.
document_palette <- function() {
  if (!isTRUE(getOption("knitr.in.progress")) || !isNamespaceLoaded("rmarkdown")) return(NULL)
  pal <- tryCatch(rmarkdown::metadata[["phw-palette"]], error = function(e) NULL)
  if (is.character(pal) && length(pal) >= 1 && all(nzchar(pal))) pal else NULL
}

#' Palette functions for scales
#'
#' Returns a function of `n`, as the scales package expects.
#'
#' @inheritParams phw_pal
#' @return A function.
#' @examples
#' pal <- phw_pal_fun("blues")
#' pal(3)
#' @keywords internal
#' @export
phw_pal_fun <- function(palette = phw_default_palette(), reverse = FALSE) {
  force(palette); force(reverse)
  function(n) phw_pal(n, palette = palette, reverse = reverse)
}

#' Show PHW palettes
#'
#' Draws every palette as a strip of swatches. Handy for checking colours.
#'
#' @param palettes Palette names to draw.
#' @param cvd Show the palettes as someone with a colour vision deficiency
#'   would see them: `"none"`, `"deutan"`, `"protan"` or `"tritan"`. See
#'   [phw_cvd()].
#' @return A ggplot object.
#' @examples
#' show_phw_palettes()
#' show_phw_palettes(c("main", "accessible"), cvd = "deutan")
#' @export
show_phw_palettes <- function(palettes = names(phw_palettes),
                              cvd = c("none", "deutan", "protan", "tritan")) {
  cvd <- rlang::arg_match(cvd)
  df <- do.call(rbind, lapply(palettes, function(p) {
    cols <- unname(phw_palettes[[p]])
    if (cvd != "none") cols <- phw_cvd(cols, cvd)
    data.frame(palette = p, i = seq_along(cols), hex = cols)
  }))
  df$palette <- factor(df$palette, levels = rev(palettes))
  df$label_col <- ifelse(luminance(df$hex) > 0.4, phw_colours[["text"]], "#FFFFFF")
  ggplot2::ggplot(df, ggplot2::aes(.data$i, .data$palette)) +
    ggplot2::geom_tile(ggplot2::aes(fill = .data$hex), colour = "white",
                       linewidth = 1, width = 1, height = 0.9) +
    ggplot2::geom_text(ggplot2::aes(label = .data$hex, colour = .data$label_col),
                       size = 2.8, family = phw_font()) +
    ggplot2::scale_fill_identity() +
    ggplot2::scale_colour_identity() +
    ggplot2::scale_x_continuous(expand = c(0, 0)) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_phw(grid = "none") +
    ggplot2::theme(axis.text.x = ggplot2::element_blank())
}

luminance <- function(hex) {
  rgb <- grDevices::col2rgb(hex) / 255
  lin <- ifelse(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055)^2.4)
  as.numeric(0.2126 * lin[1, ] + 0.7152 * lin[2, ] + 0.0722 * lin[3, ])
}

#' Contrast ratio between two colours
#'
#' The contrast ratio from the Web Content Accessibility Guidelines (WCAG),
#' the standard most public sector websites and documents are checked
#' against.
#'
#' @param x,y Colours (any form [grDevices::col2rgb()] accepts).
#' @return Contrast ratios, from 1 to 21. The WCAG AA level needs 4.5 for body
#'   text and 3 for large text and chart marks.
#' @examples
#' phw_contrast(phw_colours["teal"], "white")
#' @export
phw_contrast <- function(x, y = "#FFFFFF") {
  lx <- luminance(x); ly <- luminance(y)
  (pmax(lx, ly) + 0.05) / (pmin(lx, ly) + 0.05)
}

#' Choose readable text colour for a background
#'
#' @param bg Background colours.
#' @return `"#FFFFFF"` or the PHW text colour, whichever contrasts more.
#' @examples
#' phw_text_on(phw_col("navy", "light_teal", "gold_465"))
#' @export
phw_text_on <- function(bg) {
  ifelse(phw_contrast(bg, "#FFFFFF") >= phw_contrast(bg, phw_colours[["text"]]),
         "#FFFFFF", phw_colours[["text"]])
}
