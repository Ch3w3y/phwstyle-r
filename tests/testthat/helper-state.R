# use_phw_ggplot() changes the session: the default theme, ggplot2's scale
# options, the default aesthetics of geoms and the phwstyle palette. Put
# them all back when the calling test finishes.
local_ggplot_state <- function(env = parent.frame()) {
  old_theme <- ggplot2::theme_get()
  opts <- c("ggplot2.discrete.colour", "ggplot2.discrete.fill", "ggplot2.continuous.colour",
            "ggplot2.continuous.fill", "ggplot2.binned.colour", "ggplot2.binned.fill",
            "phwstyle.palette")
  old_opts <- options(stats::setNames(vector("list", length(opts)), opts))
  ns <- asNamespace("ggplot2")
  geoms <- Filter(function(g) inherits(g, "Geom"), mget(ls(ns, pattern = "^Geom"), envir = ns))
  old_aes <- lapply(geoms, function(g) g$default_aes)
  withr::defer({
    ggplot2::theme_set(old_theme)
    options(old_opts)
    for (g in names(geoms)) geoms[[g]]$default_aes <- old_aes[[g]]
  }, envir = env)
  # Geoms of extension packages can't be listed ahead of time (a package
  # may be loaded part way through), so leave them alone. test-extensions.R
  # tests phw_style_extensions() directly.
  testthat::local_mocked_bindings(phw_style_extensions = function(...) invisible(character()),
                                  .env = env)
  invisible()
}

# The colours a plot draws with, in order of first appearance.
plot_colours <- function(p, aesthetic = "fill", layer = 1) {
  unique(ggplot2::layer_data(p, layer)[[aesthetic]])
}

groups <- function(n) {
  data.frame(g = factor(paste("Group", seq_len(n))), v = seq_len(n))
}

# The text of a Word document, to check what a render wrote.
docx_text <- function(file) {
  dir <- withr::local_tempdir()
  utils::unzip(file, "word/document.xml", exdir = dir)
  xml <- paste(readLines(file.path(dir, "word", "document.xml"), warn = FALSE, encoding = "UTF-8"),
               collapse = "")
  gsub("\\s+", " ", gsub("<[^>]+>", " ", xml))
}
