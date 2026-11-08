#' Boundaries of Welsh areas for maps
#'
#' Downloads boundaries for one level of geography in Wales, from the ONS
#' Open Geography Portal or DataMapWales, and returns them as an `sf` data
#' frame ready for [ggplot2::geom_sf()], with [theme_phw_map()]. Each
#' download is saved in your user cache folder, so later calls work offline.
#'
#' See [phw_boundary_levels()] for the levels and the release used for
#' each. The list of releases is updated in the package when new
#' boundaries are published, so you get the newest boundaries by updating
#' phwstyle and calling with `refresh = TRUE`.
#'
#' @param level The geography, e.g. `"health_board"`, `"local_authority"`,
#'   `"gp_cluster"`, `"lsoa"`. See [phw_boundary_levels()].
#' @param detail How detailed the outlines are: `"generalised"` (20 m, the
#'   default and best for most maps), `"super"` (200 m), `"ultra"` (500 m,
#'   small files), or `"full"` (clipped to the coastline at full
#'   resolution). Where a level has no layer at that detail, the nearest
#'   one is used. DataMapWales layers come at full detail and are simplified
#'   with [sf::st_simplify()].
#' @param crs Coordinate reference system of the result. Defaults to
#'   British National Grid (27700); use 4326 for longitude and latitude
#'   (e.g. for leaflet).
#' @param refresh Download again even if a cached copy exists? If the
#'   download fails, the cached copy is used with a warning.
#' @param cache Save the download in the cache folder?
#' @param quiet Hide progress messages?
#' @return An `sf` data frame with columns `code`, `name` and, where the
#'   source has one, `name_cy` (Welsh name), plus the geometry. Attributes
#'   `source`, `layer` and `attribution` say where it came from; use
#'   `attr(x, "attribution")` in your caption.
#' @details Nothing is downloaded when phwstyle is installed. The first call
#'   for a level downloads it; later calls read the cached copy, so they are
#'   fast and work offline. Without an internet connection and without a
#'   cached copy, the function stops with an informative error. When a
#'   newer release of a level is downloaded, cached files from older releases
#'   of that level are deleted, so the cache stays small. Clear it all with
#'   `phw_boundaries_cache(clear = TRUE)`.
#' @seealso [phw_boundary_levels()], [phw_boundaries_cache()]
#' @examples
#' phw_boundary_levels()
#' \donttest{
#' if (requireNamespace("sf", quietly = TRUE) && interactive()) {
#'   hb <- phw_boundaries("health_board")
#'   library(ggplot2)
#'   ggplot(hb) +
#'     geom_sf(aes(fill = name)) +
#'     scale_fill_phw_d() +
#'     theme_phw_map() +
#'     labs(caption = attr(hb, "attribution"))
#' }
#' }
#' @export
phw_boundaries <- function(level, detail = c("generalised", "super", "ultra", "full"),
                           crs = 27700, refresh = FALSE, cache = TRUE, quiet = FALSE) {
  detail <- rlang::arg_match(detail)
  rlang::check_installed(c("sf", "jsonlite"), reason = "to download boundaries.")
  reg <- boundary_registry()
  level <- rlang::arg_match(level, unique(reg$level))
  row <- pick_boundary(reg[reg$level == level, , drop = FALSE], detail)

  file <- file.path(phw_boundaries_cache(), sprintf("%s_%s.geojson", level,
                                                    gsub("[^A-Za-z0-9]+", "_", row$layer)))
  simplify <- row$source == "datamapwales" && detail != "full"
  if (refresh || !file.exists(file)) {
    if (!quiet) cli::cli_inform("Downloading {row$label} ({row$layer}) ...")
    # Download to a temporary file first, so a failed download never
    # replaces a good cached copy.
    tmp <- tempfile(fileext = ".geojson")
    # Large layers can take more than R's default 60 seconds.
    op <- options(timeout = max(600, getOption("timeout")))
    on.exit(options(op), add = TRUE)
    ok <- tryCatch({
      if (row$source == "ons") download_ons(row, tmp) else download_dmw(row, tmp)
      TRUE
    }, error = function(e) e)
    if (!isTRUE(ok)) {
      host <- if (row$source == "ons") "the ONS Open Geography Portal" else "DataMapWales"
      if (file.exists(file)) {
        cli::cli_warn(c("Could not download {row$label} from {host}, so the cached copy is used.",
                        "i" = conditionMessage(ok)))
      } else {
        cli::cli_abort(c("Could not download {row$label} from {host}.",
                         "i" = "Check your internet connection, or try again later.",
                         "i" = "If it keeps failing, the layer may have been replaced: update phwstyle.",
                         "x" = conditionMessage(ok)), call = NULL)
      }
    } else if (cache) {
      dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
      file.copy(tmp, file, overwrite = TRUE)
      remove_outdated(level, reg, file)
    } else {
      file <- tmp
    }
  }
  x <- sf::read_sf(file, quiet = TRUE)
  # DataMapWales layers come in British National Grid.
  if (row$source == "datamapwales" && (is.na(sf::st_crs(x)) || max(abs(sf::st_bbox(x))) > 1000)) {
    x <- sf::st_set_crs(x, 27700)
  }
  keep <- c(code = row$code_field, name = row$name_field,
            name_cy = if (nzchar(row$name_cy_field)) row$name_cy_field)
  out <- x[, unname(keep)]
  names(out)[seq_along(keep)] <- names(keep)
  sf::st_geometry(out) <- "geometry"
  out <- sf::st_transform(out, crs)
  if (simplify) {
    tol <- c(generalised = 20, super = 200, ultra = 500)[[detail]]
    out <- sf::st_transform(sf::st_simplify(sf::st_transform(out, 27700), preserveTopology = TRUE,
                                            dTolerance = tol), crs)
  }
  out <- out[order(out$code), ]
  attr(out, "source") <- row$source
  attr(out, "layer") <- row$layer
  attr(out, "attribution") <- row$attribution
  out
}

#' Boundary levels available for Wales
#'
#' Lists the geographies [phw_boundaries()] can download, with the source,
#' release and level of detail of each.
#'
#' @param detail Show one row per level of detail, rather than one per
#'   geography?
#' @return A data frame.
#' @examples
#' phw_boundary_levels()
#' @export
phw_boundary_levels <- function(detail = FALSE) {
  reg <- boundary_registry()
  if (detail) return(reg[, c("level", "label", "detail", "source", "layer", "release")])
  out <- do.call(rbind, lapply(split(reg, factor(reg$level, unique(reg$level))), function(r) {
    data.frame(level = r$level[1], label = r$label[1], source = r$source[1],
               release = r$release[1], detail = paste(r$detail, collapse = ", "),
               stringsAsFactors = FALSE)
  }))
  rownames(out) <- NULL
  out
}

#' Boundary cache folder
#'
#' Where [phw_boundaries()] keeps downloaded boundaries.
#'
#' @param clear Delete the cached files?
#' @return The folder path, invisibly when `clear = TRUE`.
#' @examples
#' phw_boundaries_cache()
#' @export
phw_boundaries_cache <- function(clear = FALSE) {
  dir <- getOption("phwstyle.boundary_dir", file.path(tools::R_user_dir("phwstyle", which = "cache"), "boundaries"))
  if (clear) {
    files <- list.files(dir, pattern = "\\.geojson$", full.names = TRUE)
    unlink(files)
    cli::cli_inform("Removed {length(files)} cached boundary file{?s}.")
    return(invisible(dir))
  }
  dir
}

# Keep the cache small: once a level is downloaded, delete cached files for
# that level from layers the registry no longer lists (older releases).
remove_outdated <- function(level, reg, keep) {
  current <- sprintf("%s_%s.geojson", level, gsub("[^A-Za-z0-9]+", "_", reg$layer[reg$level == level]))
  old <- list.files(dirname(keep), pattern = sprintf("^%s_.*\\.geojson$", level), full.names = TRUE)
  old <- old[!basename(old) %in% current]
  if (length(old)) unlink(old)
  invisible(old)
}

boundary_registry <- function() {
  utils::read.csv(system.file("extdata", "boundaries.csv", package = "phwstyle"),
                  stringsAsFactors = FALSE, na.strings = character(), encoding = "UTF-8")
}

pick_boundary <- function(rows, detail) {
  order_pref <- list(
    generalised = c("generalised", "super", "full", "ultra"),
    super = c("super", "generalised", "ultra", "full"),
    ultra = c("ultra", "super", "generalised", "full"),
    full = c("full", "generalised", "super", "ultra"))[[detail]]
  rows[order(match(rows$detail, order_pref)), , drop = FALSE][1, ]
}

ons_query_url <- function(row, offset, n) {
  where <- if (nzchar(row$filter)) sprintf("%s LIKE '%s%%'", row$code_field, row$filter) else "1=1"
  sprintf(paste0("https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/%s/FeatureServer/0/query",
                 "?where=%s&outFields=%s&outSR=4326&f=geojson&resultOffset=%d&resultRecordCount=%d&orderByFields=%s"),
          row$layer, utils::URLencode(where, reserved = TRUE),
          paste(c(row$code_field, row$name_field, if (nzchar(row$name_cy_field)) row$name_cy_field), collapse = ","),
          offset, n, row$code_field)
}

download_ons <- function(row, file) {
  n <- 1000
  offset <- 0
  feats <- list()
  repeat {
    page <- jsonlite::fromJSON(ons_query_url(row, offset, n), simplifyVector = FALSE)
    if (!is.null(page$error)) cli::cli_abort("The ONS service returned an error: {page$error$message}")
    feats <- c(feats, page$features)
    more <- isTRUE(page$exceededTransferLimit) || isTRUE(page$properties$exceededTransferLimit)
    if (!more || !length(page$features)) break
    offset <- offset + length(page$features)
  }
  if (!length(feats)) cli::cli_abort("No boundaries found for {.val {row$level}}.")
  jsonlite::write_json(list(type = "FeatureCollection", features = feats), file,
                       auto_unbox = TRUE, digits = NA, null = "null")
  invisible(file)
}

download_dmw <- function(row, file) {
  url <- sprintf(paste0("https://datamap.gov.wales/geoserver/ows?service=WFS&version=2.0.0&request=GetFeature",
                        "&typeNames=%s&outputFormat=application/json&srsName=EPSG:27700"), row$layer)
  utils::download.file(url, file, quiet = TRUE, mode = "wb")
  # Errors come back as XML, not GeoJSON.
  first <- readChar(file, 200, useBytes = TRUE)
  if (!grepl("FeatureCollection", first, fixed = TRUE)) {
    stop("DataMapWales did not return boundaries for layer ", row$layer, call. = FALSE)
  }
  invisible(file)
}
