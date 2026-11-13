# Run the installed package's tests and write one row of results.
# Usage: Rscript run-tests.R <package dir> <cell name> <results csv> [test filter]
args <- commandArgs(TRUE)
pkg_dir <- args[1]; cell <- args[2]; out <- args[3]; filter <- if (length(args) > 3) args[4] else NULL
# Run the tests marked skip_on_cran() too: they are the ones that render
# Quarto and PDF documents and download boundaries.
Sys.setenv(NOT_CRAN = "true")
suppressPackageStartupMessages(library(testthat))
ver <- function(p) tryCatch(as.character(utils::packageVersion(p)), error = function(e) "-")
res <- as.data.frame(test_dir(file.path(pkg_dir, "tests", "testthat"), package = "phwstyle",
                              load_package = "installed", reporter = "silent",
                              stop_on_failure = FALSE, filter = filter))
bad <- res[res$failed > 0 | res$error, ]
skipped <- res[res$skipped, ]
pandoc <- tryCatch(as.character(rmarkdown::pandoc_version()), error = function(e) "-")
quarto <- Sys.which("quarto")
quarto <- if (nzchar(quarto)) tryCatch(system2(quarto, "--version", stdout = TRUE, stderr = FALSE)[1], error = function(e) "-") else "-"
row <- data.frame(
  cell = cell, r = as.character(getRversion()), ggplot2 = ver("ggplot2"), flextable = ver("flextable"),
  gt = ver("gt"), gtsummary = ver("gtsummary"), rmarkdown = ver("rmarkdown"), pandoc = pandoc, quarto = quarto,
  passed = sum(res$passed), failed = sum(res$failed), errors = sum(res$error), skipped = sum(res$skipped),
  warnings = sum(res$warning),
  failing = paste(sprintf("%s: %s", bad$file, bad$test), collapse = " | "),
  stringsAsFactors = FALSE)
write.table(row, out, sep = ",", row.names = FALSE, col.names = !file.exists(out), append = file.exists(out), qmethod = "double")
cat(sprintf("%-28s R %s ggplot2 %s | pass %d fail %d error %d skip %d warn %d\n", cell, row$r, row$ggplot2,
            row$passed, row$failed, row$errors, row$skipped, row$warnings))
if (nrow(bad)) cat(paste0("  FAIL ", bad$file, ": ", bad$test, collapse = "\n"), "\n")
if (nrow(skipped)) writeLines(sprintf("  skip %s: %s", skipped$file, skipped$test), paste0(out, ".", cell, ".skips.txt"))
