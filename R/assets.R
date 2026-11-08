# Run-time assembly of branded resources. The logo is a PHW trade mark that
# may or may not be available (see phw_logo()), so anything that contains it
# is built here rather than shipped pre-made.

blank_svg <- '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>'

write_blank_png <- function(file) {
  if (requireNamespace("png", quietly = TRUE)) {
    png::writePNG(array(0, dim = c(1, 1, 4)), file)
  } else {
    file.copy(phw_graphic("band"), file, overwrite = TRUE)
  }
  file
}

#' Path to the PHW Word reference document
#'
#' The Word template behind [phw_word_document()] and the Quarto `phw-docx`
#' format. It sets Ubuntu, navy headings, booktabs tables, a gradient header
#' band (with the logo when one is available) and a "Page x of y" footer.
#' Use it with any tool that takes a Word template. Examples are
#' `officer::read_docx(phw_reference_docx())` or `reference-doc:` in Quarto.
#'
#' @param file Where to write the document.
#' @return A file path.
#' @export
phw_reference_docx <- function(file = tempfile(fileext = ".docx")) {
  src <- phw_file("rmarkdown", "resources", "phw-reference.docx")
  dir <- tempfile("phw-docx-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  utils::unzip(src, exdir = dir)
  # Header band: swap in the band with the logo composited.
  file.copy(band_with_logo(), file.path(dir, "word", "media", "image1.png"), overwrite = TRUE)
  zip_dir(dir, file)
}

zip_dir <- function(dir, file) {
  file <- file.path(normalizePath(dirname(file), mustWork = TRUE), basename(file))
  if (file.exists(file)) unlink(file)
  files <- list.files(dir, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  # [Content_Types].xml must come first in a valid Office file.
  files <- c("[Content_Types].xml", setdiff(files, "[Content_Types].xml"))
  zip::zip(file, files = files, root = dir, mode = "mirror")
  file
}

# Fill in the LaTeX header placeholders.
fill_latex_header <- function(paths, team = NULL, cover = TRUE) {
  tex <- readLines(phw_file("rmarkdown", "resources", "phw-header.tex"), warn = FALSE)
  org <- phw_org
  if (!is.null(team)) org <- paste0(org, "\\\\[2pt]", team)
  subs <- c(
    "%%FONTDIR%%" = paths$fontdir,
    "%%BAND%%" = paths$band,
    "%%COVER%%" = paths$cover,
    "%%LOGO%%" = paths$logo,
    "%%FOOTER%%" = phw_org,
    "%%ORG%%" = org,
    "%%PAGE%%" = "Page",
    "%%OF%%" = "of"
  )
  for (k in names(subs)) tex <- gsub(k, subs[[k]], tex, fixed = TRUE)
  if (is.null(paths$logo_ok) || !paths$logo_ok) {
    tex <- tex[!grepl("phw-logo-line", tex, fixed = TRUE)]
  }
  if (!cover) tex <- tex[seq_len(grep("^% Cover page", tex) - 1)]
  tex
}

html_band <- function() {
  uri <- logo_data_uri("white")
  logo <- if (is.null(uri)) {
    sprintf('<span class="phw-band-name">%s</span>', phw_org)
  } else {
    sprintf('<img src="%s" alt="Iechyd Cyhoeddus Cymru / Public Health Wales">', uri)
  }
  sprintf(paste0('<div class="phw-band"><a href="https://phw.nhs.wales/" class="phw-band-logo">%s</a>',
                 '<div class="phw-band-org">%s</div></div>'),
          logo, if (is.null(uri)) "" else phw_org)
}

# 16:9 slide cover with the white logo composited top left.
cover_wide_with_logo <- function(file) {
  logo <- phw_logo("white", "png")
  if (is.null(logo) || !requireNamespace("png", quietly = TRUE) ||
      !requireNamespace("ragg", quietly = TRUE) || !requireNamespace("jpeg", quietly = TRUE)) {
    file.copy(phw_graphic("cover_wide"), file, overwrite = TRUE)
    return(file)
  }
  ragg::agg_jpeg(file, width = 1920, height = 1080, quality = 90)
  on.exit(grDevices::dev.off(), add = TRUE)
  grid::grid.raster(jpeg::readJPEG(phw_graphic("cover_wide")),
                    width = grid::unit(1, "npc"), height = grid::unit(1, "npc"))
  img <- png::readPNG(logo)
  h <- 150 / 1080
  w <- h * (dim(img)[2] / dim(img)[1]) * (1080 / 1920)
  grid::grid.raster(img, x = grid::unit(110 / 1920, "npc"), y = grid::unit(1 - 90 / 1080, "npc"),
                    hjust = 0, vjust = 1, width = grid::unit(w, "npc"), height = grid::unit(h, "npc"),
                    interpolate = TRUE)
  file
}
