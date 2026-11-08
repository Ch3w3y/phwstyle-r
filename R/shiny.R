#' PHW Bootstrap theme for Shiny, R Markdown and Quarto HTML
#'
#' A [bslib::bs_theme()] with PHW colours and the Ubuntu font. The mapping
#' follows phw.nhs.wales:
#'
#' * navy is `primary`
#' * the website green is `success`
#' * `danger`, `warning` and `info` use the accessible RAG red, amber and
#'   teal
#' * links are the website blue, with magenta on hover
#'
#' Navbars are navy, and focus outlines are the NHS yellow.
#'
#' Use it in `bslib::page_navbar(theme = phw_bs_theme())`,
#' `fluidPage(theme = phw_bs_theme())`, or as the `theme` of
#' [phw_html_document()].
#'
#' @param version Bootstrap version.
#' @param ... Extra variables passed to [bslib::bs_theme()]. They override
#'   the PHW values, e.g. `primary = "#24A2B5"` or `"navbar-bg" = "#1B3660"`.
#' @return A bslib theme.
#' @export
phw_bs_theme <- function(version = 5, ...) {
  rlang::check_installed("bslib")
  col <- phw_colours
  fam <- c("Ubuntu", "Arial", "sans-serif")
  args <- list(
    version = version,
    bg = "#FFFFFF", fg = col[["text"]],
    primary = col[["navy"]], secondary = col[["text_secondary"]],
    success = col[["green"]], info = col[["teal"]],
    warning = col[["amber"]], danger = col[["magenta"]],
    light = col[["grey_bg"]], dark = col[["navy_dark"]],
    base_font = bslib::font_collection(fam),
    heading_font = bslib::font_collection(fam),
    code_font = bslib::font_collection("Ubuntu Mono", "Consolas", "monospace"),
    "font-size-base" = "1rem",
    "headings-color" = col[["navy"]],
    "headings-font-weight" = 700,
    "link-color" = col[["blue"]],
    "link-hover-color" = col[["magenta"]],
    "border-color" = col[["grey_border"]],
    "border-radius" = "0.25rem",
    "navbar-bg" = col[["navy"]],
    "focus-ring-color" = col[["focus"]],
    "focus-ring-opacity" = 1
  )
  extra <- list(...)
  args[names(extra)] <- extra
  theme <- do.call(bslib::bs_theme, args)
  theme <- bslib::bs_add_rules(theme, phw_scss_rules())
  bslib::bs_bundle(theme, sass::sass_layer(html_deps = phw_font_dependency()))
}

phw_scss_rules <- function() {
  paste(readLines(phw_file("css", "phw-bootstrap.scss"), warn = FALSE), collapse = "\n")
}

#' PHW branded header band for HTML pages
#'
#' The navy-to-cyan gradient band with the white PHW logo, as used across
#' the top of PHW reports. Use it as the first element of a Shiny UI, or in
#' any htmltools page.
#'
#' @param title Page or app title shown in the band.
#' @param subtitle Optional second line, e.g. the team name.
#' @param href Where the logo links to.
#' @param logo Show the logo? With `FALSE`, or when no logo is available,
#'   `org` is shown as text instead.
#' @param org Organisation name used as the text fallback and alt text.
#' @return An HTML tag.
#' @export
phw_header <- function(title = NULL, subtitle = NULL, href = "https://phw.nhs.wales/",
                       logo = TRUE, org = phw_org) {
  uri <- if (isTRUE(logo)) logo_data_uri("white") else NULL
  brand <- if (is.null(uri)) {
    htmltools::span(class = "phw-header-name", org)
  } else {
    htmltools::tags$img(src = uri, alt = "Iechyd Cyhoeddus Cymru / Public Health Wales")
  }
  htmltools::tagList(
    phw_font_dependency(),
    htmltools::tags$header(
      class = "phw-header",
      htmltools::tags$a(href = href, class = "phw-header-logo", brand),
      htmltools::div(class = "phw-header-text",
        if (!is.null(title)) htmltools::div(class = "phw-header-title", title),
        if (!is.null(subtitle)) htmltools::div(class = "phw-header-subtitle", subtitle))
    )
  )
}

base64_uri <- function(path, mime) {
  raw <- readBin(path, "raw", file.info(path)$size)
  paste0("data:", mime, ";base64,", base64enc(raw))
}

base64enc <- function(raw) {
  if (requireNamespace("base64enc", quietly = TRUE)) return(base64enc::base64encode(raw))
  if (requireNamespace("jsonlite", quietly = TRUE)) return(jsonlite::base64_enc(raw))
  cli::cli_abort("Install {.pkg base64enc} or {.pkg jsonlite} to embed images.")
}

#' A complete PHW Shiny page
#'
#' A thin wrapper around [bslib::page_navbar()] that applies
#' [phw_bs_theme()], puts the PHW header band above the navigation and adds
#' a footer. Use [bslib::nav_panel()] for each tab, exactly as you would with
#' `page_navbar()`.
#'
#' @param ... Tabs and other arguments passed to [bslib::page_navbar()].
#' @param title App title, shown in the header band and the browser tab.
#' @param subtitle Optional subtitle, e.g. the team name.
#' @param footer Footer text or tags. Defaults to the organisation name.
#'   `FALSE` drops the footer.
#' @param theme A bslib theme. Use [phw_bs_theme()] with your own overrides.
#' @param header_args List of extra [phw_header()] arguments.
#' @param navbar_bg Navigation bar colour.
#' @return A Shiny UI.
#' @export
phw_page_navbar <- function(..., title = NULL, subtitle = NULL, footer = NULL,
                            theme = phw_bs_theme(), header_args = list(),
                            navbar_bg = phw_colours[["navy"]]) {
  rlang::check_installed("bslib")
  footer <- if (isFALSE(footer)) NULL else htmltools::tags$footer(class = "phw-footer", footer %||% phw_org)
  args <- list(...)
  defaults <- list(title = NULL, window_title = title %||% phw_org, theme = theme,
                   navbar_options = bslib::navbar_options(bg = navbar_bg, theme = "dark"),
                   footer = footer, fillable = TRUE, lang = "en")
  for (nm in names(defaults)) if (!nm %in% names(args)) args[nm] <- list(defaults[[nm]])
  page <- do.call(bslib::page_navbar, args)
  prepend_header(page, do.call(phw_header, c(list(title, subtitle), header_args)))
}

prepend_header <- function(page, header) {
  htmltools::tagList(header, page)
}
