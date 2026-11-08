logo_url <- "https://phw.nhs.wales/app/uploads/sites/2/2025/02/phw-logo.svg"

logo_colours <- c(blue = "#325A8A", white = "#FFFFFF", black = "#231F20")

#' Path to a PHW logo file
#'
#' The bilingual Public Health Wales logo, with Welsh first. Choose the
#' version that suits the background:
#'
#' * `"blue"`: Pantone 534, PHW's preferred logo colour, for white
#'   backgrounds.
#' * `"white"`: for the gradient band or any dark background.
#' * `"black"`: for mono print.
#'
#' The logo is a trade mark of Public Health Wales. phwstyle looks for it in
#' this order:
#'
#' 1. the folder in `options(phwstyle.logo_dir = ...)`, for example a copy
#'    from your organisation's approved logo pack
#' 2. logos in the package's `logos` folder (none are bundled with the
#'    released package)
#' 3. a copy downloaded earlier with [phw_download_logos()]
#'
#' If none is found, `phw_logo()` returns `NULL`. Outputs are then still
#' branded, just without the logo.
#'
#' Print guidance (NHS Wales Logo Guidelines, 2022): the minimum height is
#' 24 mm, and the clear space around the logo is half its height.
#'
#' @param variant One of `"blue"`, `"white"` or `"black"`.
#' @param format `"svg"` or `"png"`.
#' @return A file path, or `NULL` if no logo is available.
#' @examples
#' phw_logo("white", "svg")
#' @export
phw_logo <- function(variant = c("blue", "white", "black"), format = c("png", "svg")) {
  variant <- rlang::arg_match(variant)
  format <- rlang::arg_match(format)
  file <- sprintf("phw-logo-%s.%s", variant, format)
  dirs <- c(getOption("phwstyle.logo_dir"),
            system.file("logos", package = "phwstyle"),
            logo_cache_dir())
  for (d in dirs) {
    if (nzchar(d) && file.exists(file.path(d, file))) return(file.path(d, file))
  }
  NULL
}

logo_cache_dir <- function() tools::R_user_dir("phwstyle", which = "cache")

#' Does phwstyle have a PHW logo to use?
#' @return `TRUE` or `FALSE`.
#' @export
phw_has_logo <- function() !is.null(phw_logo("white", "svg")) && !is.null(phw_logo("white", "png"))

#' Download the PHW logo
#'
#' Downloads the official bilingual logo (SVG) from phw.nhs.wales. It then
#' makes blue, white and black versions in SVG and PNG, and stores them in
#' your user cache folder (see [tools::R_user_dir()]). You only need to do
#' this once per computer. It isn't needed if you set
#' `options(phwstyle.logo_dir = ...)` to a folder with your own copies.
#'
#' The logo is a trade mark of Public Health Wales. Use it only in line with
#' PHW's brand guidance.
#'
#' @param ask Ask before downloading? Always `TRUE` in interactive
#'   sessions unless you set it to `FALSE`.
#' @param url Where to download the white SVG logo from.
#' @return The cache folder, invisibly, or `NULL` if nothing was downloaded.
#' @export
phw_download_logos <- function(ask = interactive(), url = logo_url) {
  dest <- logo_cache_dir()
  if (ask) {
    ok <- utils::askYesNo(sprintf(
      "Download the Public Health Wales logo from phw.nhs.wales and store it in %s?", dest))
    if (!isTRUE(ok)) return(invisible(NULL))
  }
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(fileext = ".svg")
  status <- tryCatch(utils::download.file(url, tmp, mode = "wb", quiet = TRUE),
                     error = function(e) 1L)
  if (!identical(status, 0L) || !file.exists(tmp)) {
    cli::cli_warn("Couldn't download the logo from {.url {url}}.")
    return(invisible(NULL))
  }
  svg <- readLines(tmp, warn = FALSE)
  for (v in names(logo_colours)) {
    out <- gsub("rgb(255%,255%,255%)", logo_colours[[v]], svg, fixed = TRUE)
    out <- gsub('fill="white"', sprintf('fill="%s"', logo_colours[[v]]), out, fixed = TRUE)
    writeLines(out, file.path(dest, sprintf("phw-logo-%s.svg", v)))
    if (requireNamespace("rsvg", quietly = TRUE)) {
      rsvg::rsvg_png(file.path(dest, sprintf("phw-logo-%s.svg", v)),
                     file.path(dest, sprintf("phw-logo-%s.png", v)), width = 1200)
    }
  }
  if (!requireNamespace("rsvg", quietly = TRUE)) {
    cli::cli_inform(c("!" = "Install {.pkg rsvg} and run this again to make PNG logos for Word, PDF and plots."))
  }
  cli::cli_inform(c(v = "Saved PHW logos to {.path {dest}}."))
  invisible(dest)
}

#' Path to a PHW brand graphic
#'
#' The graphics are drawn by phwstyle itself and contain no logo.
#'
#' @param name `"band"` (the header gradient band), `"cover"` (the A4
#'   portrait cover background) or `"cover_wide"` (the 16:9 slide
#'   background).
#' @return A file path.
#' @export
phw_graphic <- function(name = c("band", "cover", "cover_wide")) {
  name <- rlang::arg_match(name)
  file <- switch(name, band = "band.png", cover = "cover-a4.jpg", cover_wide = "cover-wide.jpg")
  phw_file("graphics", file)
}

logo_grob <- function(variant = "blue", height = grid::unit(1, "npc"), x = 0, hjust = 0) {
  path <- phw_logo(variant, "png")
  if (is.null(path)) return(grid::nullGrob())
  rlang::check_installed("png", "to draw the PHW logo on plots")
  img <- png::readPNG(path)
  grid::rasterGrob(img, x = x, hjust = hjust, height = height, interpolate = TRUE)
}

# The gradient band with the white logo composited on the left, as a PNG.
# Without a logo, it returns the plain band.
band_with_logo <- function(file = tempfile(fileext = ".png")) {
  logo <- phw_logo("white", "png")
  band <- phw_graphic("band")
  if (is.null(logo) || !requireNamespace("png", quietly = TRUE) ||
      !requireNamespace("ragg", quietly = TRUE)) {
    file.copy(band, file, overwrite = TRUE)
    return(file)
  }
  ragg::agg_png(file, width = 2480, height = 260, background = "transparent")
  on.exit(grDevices::dev.off(), add = TRUE)
  grid::grid.raster(png::readPNG(band), width = grid::unit(1, "npc"), height = grid::unit(1, "npc"))
  img <- png::readPNG(logo)
  h <- 0.62
  w <- h * (dim(img)[2] / dim(img)[1]) * (260 / 2480)
  grid::grid.raster(img, x = grid::unit(0.085, "npc"), y = 0.5, hjust = 0,
                    width = grid::unit(w, "npc"), height = grid::unit(h, "npc"), interpolate = TRUE)
  file
}

logo_data_uri <- function(variant = "white") {
  path <- phw_logo(variant, "svg")
  if (is.null(path)) return(NULL)
  base64_uri(path, "image/svg+xml")
}

#' @noRd
phw_file <- function(...) {
  path <- system.file(..., package = "phwstyle")
  if (!nzchar(path)) cli::cli_abort("File {.file {file.path(...)}} not found in phwstyle.")
  path
}
