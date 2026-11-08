#' Public Health Wales brand colours
#'
#' A named character vector of every colour in the PHW / CDSC identity.
#' Each colour and its role is listed in
#' `system.file("brand", "palette.csv", package = "phwstyle")`.
#'
#' * `navy`, `teal`, `orange`, `pink` are the four chart colours PHW reports
#'   use today, in that order.
#' * `blue_534` and `gold_465` are the official NHS Wales logo colours
#'   (Pantone 534 and 465).
#' * `blue`, `green`, `magenta` come from the phw.nhs.wales website.
#' * Greys and `text` are the NHS digital front-end neutrals used on the site.
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
#' * `extended` (qualitative, 8): `main` plus gold, purple, green and mid grey.
#'   Use facets or direct labels instead where you can. Some of these pairs
#'   are hard to tell apart for colour-blind readers.
#' * `accessible` (qualitative, 8): chosen so every pair stays distinct under
#'   simulated deuteranopia, protanopia and tritanopia (minimum CIELAB
#'   distance of about 20), and every colour has at least 3:1 contrast on
#'   white. It starts with navy, teal and orange, so short series still look
#'   like PHW. Use it for public-facing outputs with more than four groups.
#' * `highlight` (qualitative, 2): navy for the focus series, light grey for
#'   everything else.
#' * `rag` (qualitative, 3): red / amber / green that keeps 3:1 contrast on
#'   white. (A guess: PHW reports use Excel defaults that fail accessibility.)
#' * `rag_accessible` (qualitative, 3): like `rag`, but "good" is navy
#'   instead of green, because red and green look alike to many colour-blind
#'   readers.
#' * `blues`, `teals`, `gradient` (sequential).
#' * `orange_navy` (diverging).
#'
#' @format A named list of character vectors.
#' @export
phw_palettes <- list(
  main      = unname(phw_colours[c("navy", "teal", "orange", "pink")]),
  extended  = unname(phw_colours[c("navy", "teal", "orange", "pink",
                                   "gold_465", "purple", "green", "grey_mid")]),
  accessible = c("#285087", "#24A2B5", "#FF5D0C", "#000000", "#9D5659",
                 "#8478CF", "#882255", "#332288"),
  highlight = unname(phw_colours[c("navy", "grey_light")]),
  rag       = c(red = "#D50B5C", amber = "#D97F00", green = "#338276"),
  rag_accessible = c(red = "#D50B5C", amber = "#D97F00", green = "#285087"),
  blues     = c("#E8EDF4", "#C9D3E1", "#93A7C3", "#5D7BA5", "#285087", "#1B3660"),
  teals     = c("#E6F5F7", "#B2E0E7", "#7CC7D3", "#24A2B5", "#2D78A0", "#285087"),
  gradient  = c("#325082", "#326791", "#2A8DAC", "#2BADC5", "#27B8CD"),
  orange_navy = c("#C94100", "#FF5D0C", "#FFB088", "#F0F4F5", "#93A7C3",
                  "#285087", "#1B3660")
)

palette_type <- function(name) {
  if (name %in% c("main", "extended", "accessible", "highlight", "rag", "rag_accessible")) return("qualitative")
  if (name %in% c("orange_navy")) return("diverging")
  "sequential"
}

#' Get a vector of colours from a PHW palette
#'
#' Qualitative palettes return their colours in order (and refuse to make up
#' extra ones). Sequential and diverging palettes are interpolated to any
#' length.
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
    pal <- palette_colours(palette)
    if (is.character(palette) && length(palette) == 1 && palette %in% names(phw_palettes)) {
      type <- if (palette_type(palette) == "qualitative") "qualitative" else "sequential"
    }
    n <- n %||% length(pal)
    if (type == "qualitative") {
      if (n > length(pal)) {
        cli::cli_abort(c(
          "The palette has {length(pal)} colours but {n} were requested.",
          i = "Use {.code palette = \"accessible\"} (8 colours), facets, or direct labels."))
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
#' phwstyle uses `"main"` (navy, teal, orange, pink) for up to four groups
#' and `"accessible"` above that. Set `options(phwstyle.palette =
#' "accessible")` to use the colour-blind safe palette everywhere: ggplot2
#' defaults, plotly, colour keys and tables. You can also set it to your own
#' vector of colours.
#'
#' @return A palette name or vector.
#' @export
phw_default_palette <- function() getOption("phwstyle.palette", "main")

#' Palette functions for scales
#'
#' Returns a function of `n`, as the scales package expects.
#'
#' @inheritParams phw_pal
#' @return A function.
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

#' WCAG contrast ratio between two colours
#'
#' @param x,y Colours (any form [grDevices::col2rgb()] accepts).
#' @return Contrast ratios, from 1 to 21. WCAG AA needs 4.5 for body text and
#'   3 for large text and chart marks.
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
#' @export
phw_text_on <- function(bg) {
  ifelse(phw_contrast(bg, "#FFFFFF") >= phw_contrast(bg, phw_colours[["text"]]),
         "#FFFFFF", phw_colours[["text"]])
}
