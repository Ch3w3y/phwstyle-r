#' Style geoms from ggplot2 extension packages
#'
#' Extension packages such as ggrepel, ggridges, ggalluvial, ggsankey,
#' treemapify and ggtext define their own geoms with their own defaults
#' (black text in the default font, grey fills, black outlines). Colour and
#' fill *scales* from phwstyle already work with them, including colour
#' keys. This function also brings their *defaults* into line with the PHW
#' style:
#'
#' * text geoms use the PHW font ([phw_font()]) and text colour
#' * unmapped grey fills become navy
#' * black outlines on filled shapes become white, as in PHW charts
#' * a few known geoms get tailored defaults: white text on treemap tiles,
#'   white tile borders, and light grey strata with grey borders in
#'   alluvial plots
#'
#' It works on any package, not a fixed list: it looks through every loaded
#' package for geoms. Defaults that already follow the ggplot2 theme
#' (ggplot2 4.0 and later) are left alone. [use_phw_ggplot()] calls it for
#' you, so load extension packages *before* calling `use_phw_ggplot()`, or
#' call `phw_style_extensions()` again after loading one.
#'
#' @param packages Package names to style. Defaults to every loaded package
#'   except ggplot2.
#' @return The names of the geoms that were changed, invisibly.
#' @examples
#' phw_style_extensions()
#' @export
phw_style_extensions <- function(packages = NULL) {
  if (!is.null(packages)) {
    if (!is.character(packages)) cli::cli_abort("{.arg packages} must be package names.")
    gone <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
    if (length(gone)) cli::cli_abort("{.arg packages} names {?a package that is/packages that are} not installed: {.pkg {gone}}.")
  }
  packages <- setdiff(packages %||% loadedNamespaces(), c("ggplot2", "phwstyle"))
  changed <- character()
  for (p in packages) {
    ns <- asNamespace(p)
    for (nm in ls(ns, all.names = FALSE)) {
      obj <- tryCatch(get(nm, envir = ns), error = function(e) NULL)
      if (!inherits(obj, "Geom") || !is.list(obj$default_aes)) next
      new <- extension_defaults(class(obj)[1], obj$default_aes)
      if (length(new)) {
        ok <- tryCatch({
          suppressMessages(ggplot2::update_geom_defaults(obj, new))
          TRUE
        }, error = function(e) FALSE)
        if (ok) changed <- c(changed, paste0(p, "::", nm))
      }
    }
  }
  invisible(changed)
}

is_plain <- function(v) is.atomic(v) && length(v) == 1 && !is.na(v)

extension_defaults <- function(cls, da) {
  col <- phw_colours
  new <- list()
  greys <- c("grey", "gray", sprintf("grey%d", 0:100), sprintf("gray%d", 0:100))
  blacks <- c("black", "#000000", "grey20", "gray20", "grey10", "gray10")
  is_text <- "family" %in% names(da)
  if (is_text && is_plain(da$family) && da$family %in% c("", "sans")) new$family <- phw_font()
  if (is_plain(da$colour) && da$colour %in% blacks) {
    new$colour <- if (is_text) col[["text"]] else if ("fill" %in% names(da)) "#FFFFFF" else col[["text"]]
  }
  if (!is_text && is_plain(da$fill) && da$fill %in% greys) new$fill <- col[["navy"]]
  # Known geoms that need more than the general rules.
  tailored <- list(
    GeomTreemapText = list(colour = "#FFFFFF"),
    GeomSubgroupText = list(colour = "#FFFFFF"),
    GeomTreemap = list(colour = "#FFFFFF"),
    GeomSubgroupBorder = list(colour = "#FFFFFF"),
    GeomStratum = list(fill = col[["grey_bg"]], colour = col[["grey_mid"]])
  )
  if (cls %in% names(tailored)) new[names(tailored[[cls]])] <- tailored[[cls]]
  new
}
