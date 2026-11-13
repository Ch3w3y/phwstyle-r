# Build a library for one cell of the battery.
# Usage: Rscript install-deps.R <package dir> <library> <snapshot> [name@snapshot ...]
#   snapshot: "latest" or a date such as 2024-06-03 (CRAN as it was that day).
#   name@snapshot: take this one package from another snapshot instead, into
#   <library>-pins, which goes first on the library path (e.g. ggplot2@2025-06-02).
args <- commandArgs(TRUE)
pkg_dir <- args[1]; lib <- args[2]; snapshot <- args[3]; pins <- args[-(1:3)]
# "latest" uses Linux binaries. A dated snapshot is built from source: the
# binaries served for old dates were compiled later, against newer versions
# of their dependencies than the snapshot holds, and some of them then fail
# to run (ggplot2 4.0.1 with rlang 1.1.6 gives "object 'ffi_list2' not found").
# PHW_BATTERY_REPO overrides both, with %s for the snapshot: the dated cells
# run in a container of the matching Ubuntu release, where the binaries for
# a date were built on that date.
repo <- function(s) {
  tmpl <- Sys.getenv("PHW_BATTERY_REPO")
  if (nzchar(tmpl)) return(sprintf(tmpl, s))
  if (identical(s, "latest")) "https://packagemanager.posit.co/cran/__linux__/manylinux_2_28/latest"
  else sprintf("https://packagemanager.posit.co/cran/%s", s)
}
# Posit Package Manager serves Linux binaries only when R says which R it is.
options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(),
                                paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])),
        Ncpus = as.integer(Sys.getenv("PHW_BATTERY_NCPUS", "4")), timeout = 600)
desc <- read.dcf(file.path(pkg_dir, "DESCRIPTION"), fields = c("Imports", "Suggests"))
deps <- unlist(strsplit(paste(desc[1, ], collapse = ","), ","))
deps <- unique(trimws(sub("\\(.*\\)", "", deps)))
base <- rownames(installed.packages(priority = "base"))
deps <- setdiff(deps[nzchar(deps)], base)
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
todo <- setdiff(deps, rownames(installed.packages(lib.loc = lib)))
if (length(todo)) install.packages(todo, lib = lib, repos = c(CRAN = repo(snapshot)), quiet = TRUE)
if (length(pins)) {
  plib <- paste0(lib, "-pins")
  dir.create(plib, recursive = TRUE, showWarnings = FALSE)
  for (p in strsplit(pins, "@", fixed = TRUE)) {
    if (!p[1] %in% rownames(installed.packages(lib.loc = plib))) {
      .libPaths(c(plib, lib, .libPaths()))
      install.packages(p[1], lib = plib, repos = c(CRAN = repo(p[2])), dependencies = FALSE, quiet = TRUE)
    }
  }
}
have <- rownames(installed.packages(lib.loc = lib))
cat("installed:", length(intersect(deps, have)), "of", length(deps), "\n")
cat("not installed:", paste(setdiff(deps, have), collapse = " "), "\n")
