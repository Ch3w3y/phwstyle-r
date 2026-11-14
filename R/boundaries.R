#' Boundaries of Welsh areas for maps
#'
#' Downloads boundaries for one level of geography in Wales, from the Office
#' for National Statistics (ONS) Open Geography Portal or DataMapWales, and returns them as an `sf` data
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
#'
#' Where a geography is published by more than one source, the others are
#' tried in turn if the first cannot be reached, and a warning says which
#' boundaries you were given. MSOAs and LSOAs come from DataMapWales, with
#' the super generalised ONS boundaries as the alternative.
#'
#' Publishers sometimes replace or withdraw a layer after a version of
#' phwstyle is released. If none of the layers listed in your version can be
#' downloaded, the function fetches the current list from the phwstyle
#' repository on GitHub (a small text file, checked every week) and tries the
#' layers in it, so an older installation keeps working. Set
#' `options(phwstyle.boundary_update = FALSE)` to stop it looking. If that
#' fails too and boundaries for the level were saved from an earlier
#' release, those are returned with a warning.
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
  if (!rlang::is_string(level)) {
    cli::cli_abort(c("{.arg level} must be one level.", i = "Levels are {.val {unique(reg$level)}}."))
  }
  level <- rlang::arg_match(level, unique(reg$level))
  check_crs(crs)
  # The layer to use, followed by the others for this level. They are tried
  # in turn, so one source being down does not stop the download.
  rows <- boundary_candidates(reg[reg$level == level, , drop = FALSE], detail)
  # Large layers can take more than R's default 60 seconds.
  op <- options(timeout = max(600, getOption("timeout")))
  on.exit(options(op), add = TRUE)
  got <- boundary_fetch(rows, level, reg, refresh, cache, quiet)
  if (is.null(got$row)) {
    # None of the layers listed in this copy of phwstyle could be downloaded.
    # They may have been replaced since it was installed, so look for the
    # current list and try the layers that are new in it.
    newer <- boundary_list_update(cache)
    extra <- if (!is.null(newer)) boundary_candidates(newer[newer$level == level, , drop = FALSE], detail)
    extra <- extra[!extra$layer %in% rows$layer, , drop = FALSE]
    if (length(extra) && nrow(extra)) {
      again <- boundary_fetch(extra, level, newer, refresh, cache, quiet)
      got <- list(row = again$row, file = again$file, problems = c(got$problems, again$problems),
                  how = "updated")
    }
  }
  # Last, boundaries saved from an older release are better than none.
  if (is.null(got$row)) got <- boundary_saved_earlier(level, rows, reg, got$problems)
  row <- got$row
  file <- got$file
  if (is.null(row)) {
    hosts <- unique(vapply(seq_len(nrow(rows)), function(k) boundary_host(rows[k, ]), ""))
    cli::cli_abort(c("Could not download {rows$label[1]} from {.or {hosts}}.",
                     "i" = "Check your internet connection, or try again later.",
                     "i" = "If it keeps failing, the layer may have been replaced: update phwstyle.",
                     stats::setNames(got$problems, rep("x", length(got$problems)))), call = NULL)
  }
  if (got$how == "updated") {
    cli::cli_warn(c("The boundary layers listed in this version of phwstyle could not be downloaded.",
                    "i" = "Used {.val {row$layer}} from the current list of sources instead.",
                    "i" = "Update phwstyle when you can."))
  } else if (got$how == "saved") {
    cli::cli_warn(c("Could not download {rows$label[1]}.",
                    "i" = "Using boundaries saved earlier ({.file {basename(file)}}), which may be an older release."))
  } else if (!identical(row$layer, rows$layer[1]) && length(got$problems)) {
    cli::cli_warn(c("Could not download {rows$label[1]} from {boundary_host(rows[1, ])}.",
                    "i" = "Using the {row$detail} boundaries from {boundary_host(row)} instead."))
  }
  simplify <- row$source == "datamapwales" && detail != "full"
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
  if (anyDuplicated(out$code)) out <- combine_parts(out)
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
  check_true_false(detail, "detail")
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
  check_true_false(clear, "clear")
  dir <- getOption("phwstyle.boundary_dir", file.path(tools::R_user_dir("phwstyle", which = "cache"), "boundaries"))
  if (clear) {
    files <- list.files(dir, pattern = "\\.geojson$", full.names = TRUE)
    unlink(c(files, boundary_list_file()))
    cli::cli_inform("Removed {length(files)} cached boundary file{?s}.")
    return(invisible(dir))
  }
  dir
}

boundary_cache_file <- function(level, layer) {
  file.path(phw_boundaries_cache(), sprintf("%s_%s.geojson", level, gsub("[^A-Za-z0-9]+", "_", layer)))
}

# Get the first of `rows` that is cached or can be downloaded. Returns the
# row used and its file, or a NULL row and the reasons each download failed.
boundary_fetch <- function(rows, level, reg, refresh, cache, quiet) {
  problems <- character()
  for (i in seq_len(nrow(rows))) {
    r <- rows[i, ]
    f <- boundary_cache_file(level, r$layer)
    if (!refresh && file.exists(f)) return(list(row = r, file = f, problems = problems, how = "listed"))
    if (!quiet) cli::cli_inform("Downloading {r$label} ({r$layer}) ...")
    # Download to a temporary file first, so a failed download never
    # replaces a good cached copy.
    tmp <- tempfile(fileext = ".geojson")
    # A failed download warns before it errors. The error is kept in
    # `problems`, so the warning would only repeat it.
    ok <- tryCatch(suppressWarnings({
      if (r$source == "ons") download_ons(r, tmp) else download_dmw(r, tmp)
      TRUE
    }), error = function(e) e)
    if (isTRUE(ok)) {
      if (cache) {
        dir.create(dirname(f), recursive = TRUE, showWarnings = FALSE)
        file.copy(tmp, f, overwrite = TRUE)
        remove_outdated(level, reg, f)
        tmp <- f
      }
      return(list(row = r, file = tmp, problems = problems, how = "listed"))
    }
    problems <- c(problems, sprintf("%s: %s", boundary_host(r), conditionMessage(ok)))
    if (file.exists(f)) {
      cli::cli_warn(c("Could not download {r$label} from {boundary_host(r)}, so the cached copy is used.",
                      "i" = conditionMessage(ok)))
      return(list(row = r, file = f, problems = problems, how = "listed"))
    }
  }
  list(row = NULL, file = NULL, problems = problems, how = "listed")
}

# The newest cached file for a level from a layer that is no longer listed
# (an older release). The list no longer says which fields it has, so they
# are worked out from their names.
boundary_saved_earlier <- function(level, rows, reg, problems) {
  none <- list(row = NULL, file = NULL, problems = problems, how = "saved")
  files <- list.files(phw_boundaries_cache(), pattern = sprintf("^%s_.*\\.geojson$", level), full.names = TRUE)
  files <- files[order(file.mtime(files), decreasing = TRUE)]
  for (f in files) {
    fields <- tryCatch(guess_boundary_fields(names(sf::read_sf(f, quiet = TRUE))), error = function(e) NULL)
    if (is.null(fields)) next
    layer <- sub(sprintf("^%s_", level), "", tools::file_path_sans_ext(basename(f)))
    source <- if (startsWith(layer, "geonode_")) "datamapwales" else "ons"
    row <- rows[1, ]
    like <- reg[reg$source == source, , drop = FALSE]
    row$source <- source
    row$layer <- layer
    row$detail <- "full"
    row$code_field <- fields[["code"]]
    row$name_field <- fields[["name"]]
    row$name_cy_field <- fields[["name_cy"]]
    if (nrow(like)) row$attribution <- like$attribution[1]
    return(list(row = row, file = f, problems = problems, how = "saved"))
  }
  none
}

guess_boundary_fields <- function(x) {
  first <- function(pattern) {
    hit <- grep(pattern, x, value = TRUE, ignore.case = TRUE)
    if (length(hit)) hit[1] else ""
  }
  code <- first("^(code|.*[0-9]{2}cd)$")
  name <- first("^(name_en|name|community|.*[0-9]{2}nm)$")
  if (!nzchar(code)) code <- name
  if (!nzchar(name)) name <- code
  if (!nzchar(code)) return(NULL)
  c(code = code, name = name, name_cy = first("^(name_cy|enw_cy|enw|.*[0-9]{2}nmw)$"))
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

# The list of layers: the one in the package, or a newer one that
# phw_boundaries() fetched after this copy of phwstyle was installed.
boundary_registry <- function() {
  packaged <- system.file("extdata", "boundaries.csv", package = "phwstyle")
  saved <- boundary_list_file()
  if (file.exists(saved) && isTRUE(file.mtime(saved) > file.mtime(packaged))) {
    x <- tryCatch(read_boundary_list(saved), error = function(e) NULL)
    if (valid_boundary_list(x)) return(x)
  }
  read_boundary_list(packaged)
}

read_boundary_list <- function(file) {
  utils::read.csv(file, stringsAsFactors = FALSE, na.strings = character(), encoding = "UTF-8")
}

boundary_list_file <- function() file.path(phw_boundaries_cache(), "boundaries.csv")

# A fetched list is used only if it has the columns this version reads and
# nothing but layer and field names in them, as they go into web addresses.
valid_boundary_list <- function(x) {
  need <- c("level", "label", "detail", "source", "layer", "code_field", "name_field",
            "name_cy_field", "filter", "release", "attribution")
  plain <- function(v, pattern) all(grepl(pattern, v))
  is.data.frame(x) && nrow(x) > 0 && all(need %in% names(x)) &&
    all(x$source %in% c("ons", "datamapwales")) &&
    all(x$detail %in% c("full", "generalised", "super", "ultra")) &&
    plain(x$level, "^[a-z_]+$") && plain(x$layer, "^[A-Za-z0-9_:]+$") &&
    plain(x$code_field, "^[A-Za-z0-9_]+$") && plain(x$name_field, "^[A-Za-z0-9_]+$") &&
    plain(x$name_cy_field, "^[A-Za-z0-9_]*$") && plain(x$filter, "^[A-Z0-9]*$")
}

# The current list of layers, from the phwstyle repository. It is checked
# every week, so it knows about layers that were replaced after a version of
# phwstyle was released. Returns NULL if it cannot be fetched or is not valid.
boundary_list_update <- function(cache = TRUE) {
  if (!isTRUE(getOption("phwstyle.boundary_update", TRUE))) return(NULL)
  url <- getOption("phwstyle.boundary_list_url",
                   "https://raw.githubusercontent.com/Ch3w3y/phwstyle-r/main/inst/extdata/boundaries.csv")
  tmp <- tempfile(fileext = ".csv")
  x <- tryCatch({
    download_boundary_list(url, tmp)
    read_boundary_list(tmp)
  }, error = function(e) NULL)
  if (!valid_boundary_list(x)) return(NULL)
  if (cache) {
    saved <- boundary_list_file()
    dir.create(dirname(saved), recursive = TRUE, showWarnings = FALSE)
    file.copy(tmp, saved, overwrite = TRUE)
  }
  x
}

download_boundary_list <- function(url, file) {
  suppressWarnings(utils::download.file(url, file, quiet = TRUE, mode = "wb"))
}

# The layers for one level, best match for the requested detail first. A
# DataMapWales layer is full detail and is simplified to any other, so it
# serves every request. Ties keep the order of the registry.
boundary_candidates <- function(rows, detail) {
  order_pref <- list(
    generalised = c("generalised", "super", "full", "ultra"),
    super = c("super", "generalised", "ultra", "full"),
    ultra = c("ultra", "super", "generalised", "full"),
    full = c("full", "generalised", "super", "ultra"))[[detail]]
  rank <- match(rows$detail, order_pref)
  rank[rows$source == "datamapwales"] <- 1L
  rows[order(rank), , drop = FALSE]
}

check_crs <- function(crs, call = rlang::caller_env()) {
  ok <- !is.null(crs) && length(crs) == 1 &&
    !is.na(tryCatch(suppressWarnings(sf::st_crs(crs)), error = function(e) sf::NA_crs_))
  if (!ok) {
    cli::cli_abort(c("{.arg crs} must be a coordinate reference system that {.pkg sf} knows.",
                     i = "Use {.code 27700} for British National Grid or {.code 4326} for longitude and latitude."),
                   call = call)
  }
}

pick_boundary <- function(rows, detail) boundary_candidates(rows, detail)[1, ]

boundary_host <- function(row) {
  if (row$source == "ons") "the ONS Open Geography Portal" else "DataMapWales"
}

# Some layers hold an area that has islands as several rows, one per part.
# Make each area one row.
combine_parts <- function(x) {
  parts <- split(sf::st_geometry(x), x$code)
  out <- x[match(names(parts), x$code), ]
  sf::st_geometry(out) <- do.call(c, lapply(parts, sf::st_combine))
  out
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
