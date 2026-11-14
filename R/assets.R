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
#' @examples
#' f <- phw_reference_docx()
#' file.exists(f)
#' # In Quarto:   format: docx: reference-doc: path/to/that/file.docx
#' # In officer:  officer::read_docx(phw_reference_docx())
#' @export
phw_reference_docx <- function(file = tempfile(fileext = ".docx")) {
  check_out_file(file, "docx")
  src <- phw_file("rmarkdown", "resources", "phw-reference.docx")
  dir <- tempfile("phw-docx-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  utils::unzip(src, exdir = dir)
  # Header band: swap in the band with the logo composited.
  file.copy(band_with_logo(), file.path(dir, "word", "media", "image1.png"), overwrite = TRUE)
  zip_dir(dir, file)
}

#' Path to the PHW PowerPoint template
#'
#' The template behind [phw_pptx()] and the Quarto `phw-pptx` format: 16:9,
#' Ubuntu text (named, not embedded), navy titles, PHW theme colours and the
#' layouts Title Slide, Title and Content, Section Header, Two Content,
#' Title Only and Blank, all in one slide master called `"PHW"`. Use it with
#' any tool that takes a PowerPoint template. Examples are
#' `officer::read_pptx(phw_reference_pptx())` or `reference-doc:` in Quarto.
#'
#' @param file Where to write the template.
#' @return A file path.
#' @examples
#' f <- phw_reference_pptx()
#' file.exists(f)
#' @export
phw_reference_pptx <- function(file = tempfile(fileext = ".pptx")) {
  check_out_file(file, "pptx")
  if (!file.copy(phw_file("rmarkdown", "resources", "phw-reference.pptx"), file, overwrite = TRUE)) {
    cli::cli_abort("Couldn't write {.file {file}}.")
  }
  file
}

# An output file must go in a folder that exists, and with the extension its
# format needs, so the write can't fail part way or make a file Office won't open.
check_out_file <- function(file, ext = NULL, arg = rlang::caller_arg(file), call = rlang::caller_env()) {
  check_one_string(file, arg = arg, call = call)
  if (!dir.exists(dirname(file))) {
    cli::cli_abort("{.arg {arg}}: folder not found: {.path {dirname(file)}}.", call = call)
  }
  if (!is.null(ext) && !identical(tolower(tools::file_ext(file)), ext)) {
    cli::cli_abort("{.arg {arg}} must end in {.file .{ext}}, not {.file {basename(file)}}.", call = call)
  }
  invisible(file)
}

# Escapes the characters LaTeX treats as commands, so text such as a team
# name is printed as written.
latex_escape <- function(x) {
  chars <- strsplit(x, "", fixed = TRUE)[[1]]
  map <- c("\\" = "\\textbackslash{}", "&" = "\\&", "%" = "\\%", "$" = "\\$", "#" = "\\#",
           "_" = "\\_", "{" = "\\{", "}" = "\\}", "~" = "\\textasciitilde{}",
           "^" = "\\textasciicircum{}")
  hit <- chars %in% names(map)
  chars[hit] <- map[chars[hit]]
  paste(chars, collapse = "")
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
  if (!is.null(team)) org <- paste0(org, "\\\\[2pt]", latex_escape(team))
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
