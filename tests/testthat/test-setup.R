test_that("setup hints show code as code and words as words", {
  local_mocked_bindings(Sys.which = function(names) stats::setNames(rep("", length(names)), names),
                        .package = "base")
  withr::local_options(cli.width = 200)
  msgs <- character()
  withCallingHandlers(res <- phw_setup_check(install = FALSE),
                      message = function(m) {
                        msgs <<- c(msgs, conditionMessage(m))
                        invokeRestart("muffleMessage")
                      })
  out <- paste(msgs, collapse = "")
  expect_match(out, "Quarto: install it from https://quarto.org", fixed = TRUE)
  expect_match(out, "run `tinytex::install_tinytex()`, or use the phw-typst format", fixed = TRUE)
  expect_true(all(nzchar(res$fix[!res$ok])))
})

test_that("phw_install_fonts needs a folder for dest", {
  f <- withr::local_tempfile(lines = "x")
  expect_error(phw_install_fonts(dest = NA, ask = FALSE), "must be a folder path")
  expect_error(phw_install_fonts(dest = f, ask = FALSE), "is a file, not a folder")
})
