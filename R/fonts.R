#' PHW font family
#'
#' PHW publications and the phw.nhs.wales website use **Ubuntu**. The NHS
#' Wales logo guidelines (2022) name Frutiger, with Arial or Verdana as a
#' fallback. This package defaults to Ubuntu, which ships with the package,
#' and falls back to Arial and then to `"sans"` when Ubuntu can't be used.
#'
#' Set `options(phwstyle.font = "Arial")` to force a different family
#' everywhere, for example to follow the NHS Wales Frutiger/Arial rule.
#'
#' @return A font family name.
#' @examples
#' phw_font()
#' @export
phw_font <- function() {
  opt <- getOption("phwstyle.font")
  if (!is.null(opt)) return(opt)
  if (font_available("Ubuntu")) return("Ubuntu")
  if (font_available("Arial")) return("Arial")
  "sans"
}

font_available <- function(family) {
  reg <- tryCatch(systemfonts::registry_fonts(), error = function(e) NULL)
  if (!is.null(reg) && family %in% reg$family) return(TRUE)
  sys <- tryCatch(systemfonts::system_fonts(), error = function(e) NULL)
  !is.null(sys) && family %in% sys$family
}

#' Register the bundled Ubuntu fonts
#'
#' Called automatically when the package loads. It registers Ubuntu with
#' 'systemfonts', so ragg, svglite and the Word/PowerPoint outputs in
#' 'officer'/'flextable' can find it without the font being installed.
#'
#' The base `pdf()` device and LaTeX can't see registered fonts. For those,
#' run [phw_install_fonts()] once.
#'
#' @return `TRUE` invisibly if the fonts were registered.
#' @examples
#' # Runs when phwstyle loads; call it again only if fonts were reset.
#' phw_register_fonts()
#' @export
phw_register_fonts <- function() {
  dir <- system.file("fonts", package = "phwstyle")
  if (!nzchar(dir)) return(invisible(FALSE))
  reg <- systemfonts::registry_fonts()
  if ("Ubuntu" %in% reg$family) return(invisible(TRUE))
  ok <- tryCatch({
    systemfonts::register_font(
      name = "Ubuntu",
      plain = file.path(dir, "Ubuntu-Regular.ttf"),
      bold = file.path(dir, "Ubuntu-Bold.ttf"),
      italic = file.path(dir, "Ubuntu-Italic.ttf"),
      bolditalic = file.path(dir, "Ubuntu-BoldItalic.ttf")
    )
    systemfonts::register_font(
      name = "Ubuntu Light",
      plain = file.path(dir, "Ubuntu-Light.ttf"))
    systemfonts::register_font(
      name = "Ubuntu Medium",
      plain = file.path(dir, "Ubuntu-Medium.ttf"))
    TRUE
  }, error = function(e) FALSE)
  invisible(ok)
}

#' Install the Ubuntu font for your user account
#'
#' Copies the bundled Ubuntu font files into your personal font folder so
#' every program can use them. That includes Word, PowerPoint, LaTeX and the
#' base R `pdf()` device. You only need to do this once per computer.
#'
#' On a managed NHS Wales laptop where you can't install fonts, skip this.
#' The package will still use Ubuntu through 'ragg' and in HTML, and it falls
#' back to Arial elsewhere.
#'
#' @param dest Folder to copy the fonts to. Defaults to the usual per-user
#'   font folder for your operating system, which is only used in an
#'   interactive session.
#' @param ask Ask for confirmation before copying? Defaults to `TRUE` in
#'   interactive sessions.
#' @return The destination folder, invisibly, or `NULL` if cancelled.
#' @examples
#' # Run once per computer. It asks before copying anything.
#' if (interactive()) phw_install_fonts()
#' @export
phw_install_fonts <- function(dest = NULL, ask = interactive()) {
  default_dest <- is.null(dest)
  if (default_dest) {
    sys <- Sys.info()[["sysname"]]
    dest <- switch(sys,
      Windows = file.path(Sys.getenv("LOCALAPPDATA"), "Microsoft", "Windows", "Fonts"),
      Darwin  = file.path(Sys.getenv("HOME"), "Library", "Fonts"),
      file.path(Sys.getenv("HOME"), ".local", "share", "fonts")
    )
  }
  # CRAN policy: never write to the home folder without the user's say-so.
  if (default_dest && !interactive()) {
    cli::cli_abort(c("Fonts are only installed to your font folder in an interactive session.",
                     i = "Run {.code phw_install_fonts()} in the console, or give {.arg dest}."))
  }
  if (ask) {
    ok <- utils::askYesNo(sprintf("Copy the Ubuntu font files to %s?", dest))
    if (!isTRUE(ok)) return(invisible(NULL))
  }
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  files <- list.files(phw_file("fonts"), pattern = "\\.ttf$", full.names = TRUE)
  file.copy(files, dest, overwrite = TRUE)
  if (Sys.info()[["sysname"]] == "Windows") {
    cli::cli_inform(c(
      "Copied {length(files)} font file{?s} to {.path {dest}}.",
      i = "On Windows, double-click each file and choose {.strong Install} so Word can see it."))
  } else {
    if (nzchar(Sys.which("fc-cache"))) system2("fc-cache", c("-f", shQuote(dest)))
    cli::cli_inform("Installed {length(files)} font file{?s} to {.path {dest}}.")
  }
  invisible(dest)
}

#' HTML dependency that serves the Ubuntu web font
#'
#' Attach this to any HTML output (htmlwidgets, Shiny UIs, R Markdown) so
#' Ubuntu works even when the computer doesn't have it installed. The font
#' files are bundled, so nothing is fetched from the internet.
#'
#' @return An [htmltools::htmlDependency()].
#' @examples
#' dep <- phw_font_dependency()
#' dep$name
#' # Attach it to any HTML you build with htmltools
#' page <- htmltools::tagList(dep, htmltools::p("Text in Ubuntu"))
#' @export
phw_font_dependency <- function() {
  htmltools::htmlDependency(
    name = "phw-ubuntu-font",
    version = "0.83",
    src = c(file = system.file(package = "phwstyle")),
    stylesheet = "css/phw-fonts.css",
    attachment = file.path("fonts", list.files(
      system.file("fonts", package = "phwstyle"), pattern = "\\.ttf$")),
    all_files = FALSE
  )
}
