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
#' a whole key to a different palette on purpose, use [phw_key_recolour()].
#'
#' The one exception is the colour-blind safe `"accessible"` palette, which
#' can be switched on for a whole document (see [phw_default_palette()]). A
#' key then keeps a second set of colours, stored as `name@accessible`, with
#' the groups in the same order. So the same report can be rendered in
#' default and in accessible colours, and each version keeps its colours
#' from one run to the next.
#'
#' `"main"` carries on into `"extended"` after four groups. When a palette
#' runs out altogether, the key carries on with unused colours from the
#' other PHW palettes, then lighter tints, and warns you. `"extended"` keeps
#' twelve colours apart, but past about eight groups a chart is hard to read
#' by colour alone: use facets, direct labels or [scale_shape_phw()] as well.
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
  check_key_name(name, null_ok = TRUE)
  lv <- if (is.factor(levels)) levels(levels) else unique(as.character(levels))
  lv <- lv[!is.na(lv)]
  if (any(!nzchar(lv))) {
    cli::cli_abort(c("A group has an empty name ({.val {\"\"}}), which can't keep a colour.",
                     i = "Give the group a label, or make it {.code NA} to show it as missing."))
  }
  check_colours(neutral_colour, "neutral_colour")
  if (length(neutral_colour) != 1) cli::cli_abort("{.arg neutral_colour} must be one colour.")
  # A palette function is asked once for every group, so its colours stay
  # in its own order.
  if (is.function(palette) && length(lv)) palette <- phw_pal(length(lv), palette)
  # "main" is the start of "extended", so groups past the fourth carry on
  # into it. A key grows over time, so it can't wait to see how many groups
  # there are.
  if (identical(palette, "main")) palette <- "extended"
  id <- key_id(name, palette)
  old <- if (is.null(id)) character() else phw_key(id)
  vals <- old
  if (!length(vals) && !identical(id, name)) {
    vals <- key_mirror(phw_key(name), palette, neutral_colour)
  }
  if (length(fixed)) {
    check_named_colours(fixed, "fixed")
    vals[names(fixed)] <- unname(fixed)
  }
  new <- setdiff(lv, names(vals))
  is_neutral <- tolower(new) %in% tolower(neutral)
  vals[new[is_neutral]] <- neutral_colour
  todo <- new[!is_neutral]
  for (l in todo) vals[[l]] <- next_colour(vals, palette, neutral_colour)
  if (!is.null(id) && save && !identical(vals, old)) key_store(id, vals)
  vals[lv]
}

# The accessible palette keeps its own copy of each key, so switching a
# document to it changes keyed charts too, without losing the colours the
# default version of the report uses.
key_id <- function(name, palette) {
  if (!is.null(name) && identical(palette, "accessible")) paste0(name, "@accessible") else name
}

# Start the accessible copy of a key from the default one, with the groups
# in the same order so the two versions of a report line up. Colours that
# are in both palettes (navy, teal, orange), grey and hand-picked colours
# stay as they are; the rest take the next free accessible colour.
key_mirror <- function(default, palette, neutral_colour) {
  if (!length(default)) return(default)
  col <- toupper(default)
  house <- toupper(c(phw_palettes$extended, phw_palettes$accessible))
  keep <- col %in% toupper(palette_colours(palette)) | !col %in% house |
    col == toupper(neutral_colour)
  out <- default
  out[!keep] <- NA
  for (l in names(default)[!keep]) {
    out[[l]] <- next_colour(out[!is.na(out)], palette, neutral_colour)
  }
  out
}

next_colour <- function(used, palette, neutral_colour) {
  pal <- palette_colours(palette)
  pool <- unique(toupper(c(pal, phw_palettes$accessible, phw_palettes$extended)))
  taken <- toupper(c(used, neutral_colour))
  free <- setdiff(pool, taken)
  first_extra <- setdiff(pool, toupper(pal))
  if (length(free) && !(free[1] %in% first_extra)) return(free[1])
  if (length(free)) {
    cli::cli_warn(c("The palette has run out, so new groups take colours from other PHW palettes.",
                    i = "With this many groups, add facets, direct labels or {.fn scale_shape_phw}."),
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
  cli::cli_abort("Too many groups for a colour key.", class = "phwstyle_too_many_groups")
}

#' Manage colour keys
#'
#' * `phw_key()` returns a stored key. The accessible copy of a key is
#'   called `name@accessible` (see [phw_colour_key()]).
#' * `phw_keys()` lists every key as a data frame.
#' * `phw_key_set()` adds or changes colours by hand.
#' * `phw_key_recolour()` reassigns a whole key from a new palette, keeping
#'   the group order. Use it on purpose, e.g. to move to the
#'   `"accessible"` palette, because every report after that changes.
#' * `phw_key_reset()` forgets a key (and its accessible copy), or all of
#'   them.
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
  check_key_name(name)
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
  check_key_name(name)
  check_named_colours(values, "values")
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
  if (is.function(palette)) palette <- phw_pal(max(sum(!neutral), 1), palette)
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
  nms <- if (is.null(name)) ls(phw_key_env) else c(name, paste0(name, "@accessible"))
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
  if (!rlang::is_string(path) || !nzchar(path)) cli::cli_abort("{.arg path} must be a file path or {.code NULL}.")
  if (dir.exists(path)) cli::cli_abort("{.arg path} is a folder: give a CSV file in it, such as {.file {file.path(path, 'keys.csv')}}.")
  if (!dir.exists(dirname(path))) cli::cli_abort("The folder {.file {dirname(path)}} does not exist. Create it first.")
  options(phwstyle.key_file = path)
  load_key_file(force = TRUE)
  invisible(path)
}

load_key_file <- function(force = FALSE) {
  file <- getOption("phwstyle.key_file")
  if (is.null(file) || !file.exists(file)) return(invisible())
  stamp <- paste(normalizePath(file), file.mtime(file))
  if (!force && identical(phw_key_state$stamp, stamp)) return(invisible())
  # An empty file has no keys yet; the first key saved writes the header.
  if (file.size(file) == 0) {
    phw_key_state$stamp <- stamp
    return(invisible())
  }
  df <- utils::read.csv(file, colClasses = "character", check.names = FALSE)
  if (!all(c("key", "level", "colour") %in% names(df))) {
    cli::cli_abort("{.file {file}} needs columns {.field key}, {.field level} and {.field colour}.")
  }
  bad <- is.na(df$colour) | !is_colour(df$colour)
  if (any(bad)) {
    cli::cli_abort(c("{.file {file}} has values in {.field colour} that are not colours: {.val {df$colour[bad]}}.",
                     i = "Fix them in the file, e.g. {.val #285087}."))
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
  keep <- if (file.exists(file) && file.size(file) > 0) utils::read.csv(file, colClasses = "character") else NULL
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

check_key_name <- function(name, null_ok = FALSE, call = rlang::caller_env()) {
  if (null_ok && is.null(name)) return(invisible())
  if (!rlang::is_string(name) || !nzchar(name)) {
    cli::cli_abort("{.arg name} must be one key name, such as {.val age_group}.", call = call)
  }
}

check_named_colours <- function(x, arg, call = rlang::caller_env()) {
  if (is.null(names(x)) || anyNA(names(x)) || any(!nzchar(names(x)))) {
    cli::cli_abort("{.arg {arg}} must be a named vector of colours, e.g. {.code c(Wales = \"#285087\")}.", call = call)
  }
  check_colours(x, arg, call = call)
}
