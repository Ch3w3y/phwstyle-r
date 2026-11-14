# Machado, Oliveira & Fernandes (2009) matrices at full severity, applied in
# linear RGB.
cvd_matrices <- list(
  protan = matrix(c(0.152286, 1.052583, -0.204868,
                    0.114503, 0.786281, 0.099216,
                    -0.003882, -0.048116, 1.051998), 3, byrow = TRUE),
  deutan = matrix(c(0.367322, 0.860646, -0.227968,
                    0.280085, 0.672501, 0.047413,
                    -0.011820, 0.042940, 0.968881), 3, byrow = TRUE),
  tritan = matrix(c(1.255528, -0.076749, -0.178779,
                    -0.078411, 0.930809, 0.147602,
                    0.004733, 0.691367, 0.303900), 3, byrow = TRUE)
)

srgb_to_linear <- function(v) ifelse(v <= 0.04045, v / 12.92, ((v + 0.055) / 1.055)^2.4)
linear_to_srgb <- function(v) ifelse(v <= 0.0031308, 12.92 * v, 1.055 * v^(1 / 2.4) - 0.055)

#' Simulate colour vision deficiency
#'
#' Shows how colours look to someone with one of the three common colour
#' vision deficiencies, using the Machado et al. (2009) model at full
#' severity. About 1 in 12 men and 1 in 200 women have red-green colour
#' blindness (deuteranopia or protanopia). Tritanopia is rare.
#'
#' @param colours Colours (any form [grDevices::col2rgb()] accepts), or a
#'   palette name. A missing colour (`NA`) stays `NA`.
#' @param type `"deutan"` (green-blind, the most common), `"protan"`
#'   (red-blind) or `"tritan"` (blue-blind).
#' @return Hex colours as they would be seen, with `NA` where a colour is
#'   missing.
#' @references Machado, G. M., Oliveira, M. M. and Fernandes, L. A. F. (2009).
#'   A physiologically-based model for simulation of color vision deficiency.
#'   IEEE Transactions on Visualization and Computer Graphics, 15(6),
#'   1291-1298. \doi{10.1109/TVCG.2009.113}
#' @examples
#' phw_cvd(phw_pal(4), "deutan")
#' @export
phw_cvd <- function(colours, type = c("deutan", "protan", "tritan")) {
  type <- rlang::arg_match(type)
  colours <- as_colours(colours, "colours", na_ok = TRUE)
  res <- rep(NA_character_, length(colours))
  ok <- !is.na(colours)
  rgb <- srgb_to_linear(grDevices::col2rgb(colours[ok]) / 255)
  out <- cvd_matrices[[type]] %*% rgb
  out <- pmin(pmax(linear_to_srgb(out), 0), 1)
  res[ok] <- grDevices::rgb(out[1, ], out[2, ], out[3, ])
  res
}

colour_distance <- function(colours) {
  lab <- grDevices::convertColor(t(grDevices::col2rgb(colours) / 255), "sRGB", "Lab")
  d <- as.matrix(stats::dist(lab))
  diag(d) <- NA
  d
}

#' Check colours for colour-blind readers and contrast
#'
#' Tests a set of colours, such as a palette or the fills in a chart. For
#' normal vision and each colour vision deficiency, it finds the two colours
#' that are hardest to tell apart. It also checks each colour's contrast
#' against the background.
#'
#' Distances are delta E in CIELAB, a colour space built so that equal
#' distances look about equally different; under about 10 is hard to tell
#' apart in a legend. The Web Content Accessibility Guidelines (WCAG 2.2)
#' ask for 3:1 contrast for chart marks and 4.5:1 for text.
#'
#' @param colours Colours to check. A palette name also works.
#' @param background Background colour.
#' @param min_distance Smallest acceptable delta E.
#' @param min_contrast Smallest acceptable contrast ratio for marks.
#' @return A data frame with one row per vision type, invisibly. It prints a
#'   summary.
#' @examples
#' phw_check_colours("main")
#' phw_check_colours(c("#D50B5C", "#338276"))
#' @export
phw_check_colours <- function(colours, background = "#FFFFFF", min_distance = 10,
                              min_contrast = 3) {
  cols <- as_colours(colours, "colours")
  background <- as_colours(background, "background")
  if (length(background) != 1) cli::cli_abort("{.arg background} must be one colour.")
  if (length(cols) < 2) cli::cli_abort("{.arg colours} must have at least two colours.")
  types <- c(normal = "none", deuteranopia = "deutan", protanopia = "protan", tritanopia = "tritan")
  rows <- lapply(names(types), function(nm) {
    seen <- if (types[[nm]] == "none") cols else phw_cvd(cols, types[[nm]])
    d <- colour_distance(seen)
    k <- which(d == min(d, na.rm = TRUE), arr.ind = TRUE)[1, ]
    data.frame(vision = nm, min_distance = round(min(d, na.rm = TRUE), 1),
               closest_pair = paste(cols[k[1]], cols[k[2]], sep = " / "),
               pass = min(d, na.rm = TRUE) >= min_distance)
  })
  out <- do.call(rbind, rows)
  contrast <- phw_contrast(cols, background)
  low <- cols[contrast < min_contrast]
  attr(out, "contrast") <- stats::setNames(round(contrast, 2), cols)
  msgs <- c()
  for (i in seq_len(nrow(out))) {
    msgs <- c(msgs, stats::setNames(
      sprintf("%s: closest pair %s (distance %s)", out$vision[i], out$closest_pair[i], out$min_distance[i]),
      if (out$pass[i]) "v" else "x"))
  }
  msgs <- c(msgs, if (length(low)) {
    c(x = sprintf("Below %s:1 contrast on %s: %s", min_contrast, background, paste(low, collapse = ", ")))
  } else {
    c(v = sprintf("All colours have at least %s:1 contrast on %s.", min_contrast, background))
  })
  cli::cli_inform(msgs)
  invisible(out)
}

#' Shape and linetype scales for colour-blind readers
#'
#' Colour should never be the only way to tell groups apart. These scales
#' add a second cue: point shapes that differ in outline as well as fill,
#' and line types that stay distinct in print. Use them on the same variable
#' as the colour, and ggplot2 merges the legends.
#'
#' @param ... Passed to [ggplot2::scale_shape_manual()] or
#'   [ggplot2::scale_linetype_manual()].
#' @param values Override the shapes or line types.
#' @param na.value Shape or line type for a missing group, so it stays on
#'   the chart.
#' @return A ggplot2 scale. A chart with more groups than `values` stops
#'   with an error when it is drawn.
#' @examples
#' library(ggplot2)
#' ggplot(mpg, aes(displ, hwy, colour = drv, shape = drv)) +
#'   geom_point() +
#'   scale_shape_phw() +
#'   theme_phw()
#' @export
scale_shape_phw <- function(..., values = c(16, 17, 15, 18, 1, 2, 0, 5), na.value = 4) {
  limit_groups(ggplot2::scale_shape_manual(..., values = values, na.value = na.value), values, "shapes")
}

#' @rdname scale_shape_phw
#' @export
scale_linetype_phw <- function(..., values = c("solid", "22", "42", "13", "1343", "73", "2262", "12223242"),
                               na.value = "16") {
  limit_groups(ggplot2::scale_linetype_manual(..., values = values, na.value = na.value), values, "line types")
}

limit_groups <- function(scale, values, what) {
  ggplot2::ggproto(NULL, scale, palette = function(n) {
    if (n > length(values)) {
      cli::cli_abort(c("There are {n} groups but only {length(values)} {what}.",
                       i = "Use facets or direct labels to tell this many groups apart."), call = NULL)
    }
    values
  })
}
