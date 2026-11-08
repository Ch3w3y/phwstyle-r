phw_key_env <- new.env(parent = emptyenv())
phw_key_state <- new.env(parent = emptyenv())

default_neutral <- c("Other", "Others", "Unknown", "Not known", "Not stated", "Missing")

#' Fixed colours for groups that stay the same across reports
#'
#' A colour key gives every group (an age band, a health board, an
#' organism) its own colour and remembers it. Each time you plot, groups
#' already in the key keep their colour. New groups get the next palette
#' colour that the key isn't using yet. So adding a "90+" age band next
#' month doesn't reshuffle the colours of the other bands.
#'
#' * **In one session**, keys live in memory. Use the same `name` in every
#'   chart.
#' * **Across reports**, point phwstyle at a CSV file with [phw_key_file()].
#'   Keys are then read from and written to that file, which you can keep
#'   with the project (and in version control). The file is plain text:
#'   `key,level,colour`. You can edit it by hand.
#'
#' The key stores the colour itself, not a position in a palette. Changing
#' `palette` later only affects groups that don't have a colour yet. To move
#' a whole key to a different palette on purpose, for example to the
#' colour-blind safe `"accessible"` palette, use [phw_key_recolour()].
#'
#' When the palette runs out, the key carries on with unused colours from
#' `"accessible"`, then `"extended"`, then lighter tints, and warns you. Past
#' about eight groups, colour alone can't separate them: use facets, direct
#' labels or [scale_shape_phw()] as well.
#'
#' Groups called "Other", "Unknown", "Not known" and similar are drawn in
#' grey so they don't compete with real groups. Change this with `neutral`.
#'
#' @param levels The groups: a factor (its levels are used, in order), or a
#'   character vector.
#' @param name Key name, e.g. `"age_group"`. `NULL` gives colours in order
#'   with no memory.
#' @param palette Palette for new groups: a name from [phw_palettes], or a
#'   vector of colours.
#' @param fixed Named vector of colours to pin, e.g.
#'   `c(Wales = "#285087")`. Pinned colours replace any stored colour.
#' @param neutral Group names to draw in `neutral_colour`. Matching ignores
#'   case.
#' @param neutral_colour Colour for neutral groups.
#' @param save Store new colours in the key?
#' @return A named character vector of colours, one per group in `levels`.
#' @seealso [scale_colour_phw_d()] with `key = "name"` to use a key in
#'   ggplot2. The returned vector also works directly in plotly (`colors =`),
#'   flextable and reactable.
#' @examples
#' ages <- c("0-4", "5-14", "15-44", "45-64", "65+")
#' phw_colour_key(ages, "age_example")
#' # A new band keeps the others where they were:
#' phw_colour_key(c(ages, "Unknown", "85+"), "age_example")
#' phw_key_reset("age_example")
#' @export
phw_colour_key <- function(levels, name = NULL, palette = phw_default_palette(),
                           fixed = NULL, neutral = default_neutral,
                           neutral_colour = phw_colours[["grey_mid"]], save = TRUE) {
  lv <- if (is.factor(levels)) levels(levels) else unique(as.character(levels))
  lv <- lv[!is.na(lv)]
  old <- if (is.null(name)) character() else phw_key(name)
  vals <- old
  if (length(fixed)) {
    if (is.null(names(fixed))) cli::cli_abort("{.arg fixed} must be a named vector, e.g. {.code c(Wales = \"#285087\")}.")
    vals[names(fixed)] <- unname(fixed)
  }
  new <- setdiff(lv, names(vals))
  is_neutral <- tolower(new) %in% tolower(neutral)
  vals[new[is_neutral]] <- neutral_colour
  todo <- new[!is_neutral]
  if (is.null(name) && identical(palette, "main") &&
      length(todo) > length(phw_palettes$main)) {
    palette <- "accessible"
  }
  for (l in todo) vals[[l]] <- next_colour(vals, palette, neutral_colour)
  if (!is.null(name) && save && !identical(vals, old)) key_store(name, vals)
  vals[lv]
}

next_colour <- function(used, palette, neutral_colour) {
  pal <- if (is.function(palette)) palette(length(used) + 1) else palette_colours(palette)
  pool <- unique(toupper(c(pal, phw_palettes$accessible, phw_palettes$extended)))
  taken <- toupper(c(used, neutral_colour))
  free <- setdiff(pool, taken)
  first_extra <- setdiff(pool, toupper(pal))
  if (length(free) && !(free[1] %in% first_extra)) return(free[1])
  if (length(free)) {
    cli::cli_warn(c("The palette has run out, so new groups take colours from other PHW palettes.",
                    i = "Past about 8 groups, add facets, direct labels or {.fn scale_shape_phw}."),
                  .frequency = "regularly", .frequency_id = "phw_key_overflow")
    return(free[1])
  }
  # Every PHW colour is in use: make lighter tints, one round at a time.
  for (mix in c(0.45, 0.65, 0.25)) {
    tints <- toupper(vapply(pool, function(c) grDevices::colorRampPalette(c(c, "#FFFFFF"))(100)[round(mix * 100)], ""))
    free <- setdiff(tints, taken)
    if (length(free)) {
      cli::cli_warn("More groups than PHW colours, so using lighter tints. These are hard to tell apart.",
                    .frequency = "regularly", .frequency_id = "phw_key_tints")
      return(free[1])
    }
  }
  cli::cli_abort("Too many groups for a colour key.")
}

#' Manage colour keys
#'
#' * `phw_key()` returns a stored key.
#' * `phw_keys()` lists every key as a data frame.
#' * `phw_key_set()` adds or changes colours by hand.
#' * `phw_key_recolour()` reassigns a whole key from a new palette, keeping
#'   the group order. Use it on purpose, e.g. to move to the
#'   `"accessible"` palette, because every report after that changes.
#' * `phw_key_reset()` forgets a key, or all of them.
#' * `phw_key_file()` sets a CSV file that keys are read from and saved to,
#'   so colours stay the same across sessions and reports. Call it at the
#'   top of your script or in a setup chunk, or set
#'   `options(phwstyle.key_file = "...")`.
#'
#' @param name Key name.
#' @param values Named vector of colours, e.g. `c("65+" = "#285087")`.
#' @param palette Palette to reassign from.
#' @param path Path to the CSV file. `NULL` stops using a file.
#' @return `phw_key()`: a named vector (empty if the key doesn't exist).
#'   `phw_keys()`: a data frame. The others return their input invisibly.
#' @examples
#' phw_key_set("sex_example", c(Female = "#FF5D0C", Male = "#285087"))
#' phw_key("sex_example")
#' phw_key_reset("sex_example")
#'
#' # Keep keys with a project:
#' f <- tempfile(fileext = ".csv")
#' phw_key_file(f)
#' phw_colour_key(c("A", "B"), "demo")
#' read.csv(f)
#' phw_key_file(NULL)
#' @name phw_key
NULL

#' @rdname phw_key
#' @export
phw_key <- function(name) {
  load_key_file()
  phw_key_env[[name]] %||% stats::setNames(character(), character())
}

#' @rdname phw_key
#' @export
phw_keys <- function() {
  load_key_file()
  phw_keys_raw()
}

#' @rdname phw_key
#' @export
phw_key_set <- function(name, values) {
  if (is.null(names(values)) || any(!nzchar(names(values)))) {
    cli::cli_abort("{.arg values} must be a named vector of colours.")
  }
  palette_colours(values)
  vals <- phw_key(name)
  vals[names(values)] <- unname(values)
  key_store(name, vals)
  invisible(vals)
}

#' @rdname phw_key
#' @export
phw_key_recolour <- function(name, palette = "accessible") {
  old <- phw_key(name)
  if (!length(old)) cli::cli_abort("No key called {.val {name}}.")
  neutral <- old == phw_colours[["grey_mid"]]
  vals <- old
  fresh <- character()
  for (l in names(old)[!neutral]) {
    fresh[[l]] <- next_colour(c(old[neutral], fresh), palette, phw_colours[["grey_mid"]])
  }
  vals[names(fresh)] <- fresh
  key_store(name, vals)
  invisible(vals)
}

#' @rdname phw_key
#' @export
phw_key_reset <- function(name = NULL) {
  load_key_file()
  nms <- name %||% ls(phw_key_env)
  rm(list = intersect(nms, ls(phw_key_env)), envir = phw_key_env)
  file <- getOption("phwstyle.key_file")
  if (!is.null(file) && file.exists(file)) write_key_file(file, drop = nms)
  invisible(name)
}

#' @rdname phw_key
#' @export
phw_key_file <- function(path) {
  if (is.null(path)) {
    options(phwstyle.key_file = NULL)
    return(invisible(NULL))
  }
  options(phwstyle.key_file = path)
  load_key_file(force = TRUE)
  invisible(path)
}

load_key_file <- function(force = FALSE) {
  file <- getOption("phwstyle.key_file")
  if (is.null(file) || !file.exists(file)) return(invisible())
  stamp <- paste(normalizePath(file), file.mtime(file))
  if (!force && identical(phw_key_state$stamp, stamp)) return(invisible())
  df <- utils::read.csv(file, colClasses = "character", check.names = FALSE)
  if (!all(c("key", "level", "colour") %in% names(df))) {
    cli::cli_abort("{.file {file}} needs columns {.field key}, {.field level} and {.field colour}.")
  }
  for (k in unique(df$key)) {
    rows <- df[df$key == k, ]
    assign(k, stats::setNames(rows$colour, rows$level), envir = phw_key_env)
  }
  phw_key_state$stamp <- stamp
  invisible()
}

key_store <- function(name, vals) {
  assign(name, vals, envir = phw_key_env)
  file <- getOption("phwstyle.key_file")
  if (!is.null(file)) write_key_file(file)
}

write_key_file <- function(file, drop = character()) {
  # Keep keys in the file that this session hasn't loaded or changed.
  keep <- if (file.exists(file)) utils::read.csv(file, colClasses = "character") else NULL
  mine <- phw_keys_raw()
  if (!is.null(keep)) keep <- keep[!keep$key %in% c(mine$key, drop), c("key", "level", "colour")]
  out <- rbind(keep, mine)
  utils::write.csv(out, file, row.names = FALSE)
  phw_key_state$stamp <- paste(normalizePath(file), file.mtime(file))
}

phw_keys_raw <- function() {
  nms <- sort(ls(phw_key_env))
  if (!length(nms)) return(data.frame(key = character(), level = character(), colour = character()))
  do.call(rbind, lapply(nms, function(k) {
    v <- phw_key_env[[k]]
    data.frame(key = rep(k, length(v)), level = names(v), colour = unname(v))
  }))
}
