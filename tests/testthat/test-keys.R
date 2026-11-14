test_that("colour keys keep colours when groups are added", {
  phw_key_reset("t_age")
  withr::defer(phw_key_reset("t_age"))
  a <- phw_colour_key(c("0-4", "5-14", "15-44"), "t_age")
  b <- phw_colour_key(c("Under 1", "0-4", "5-14", "15-44", "Unknown"), "t_age")
  expect_equal(b[names(a)], a)
  expect_false(b[["Under 1"]] %in% a)
  expect_equal(b[["Unknown"]], phw_colours[["grey_mid"]])
})

test_that("keys switch palette only for new groups, and recolour on request", {
  phw_key_reset("t_pal")
  withr::defer(phw_key_reset("t_pal"))
  a <- phw_colour_key(c("x", "y"), "t_pal", palette = "main")
  b <- phw_colour_key(c("x", "y", "z"), "t_pal", palette = c("#123456", "#654321"))
  expect_equal(b[c("x", "y")], a)
  expect_equal(b[["z"]], "#123456")
  r <- phw_key_recolour("t_pal", "accessible")
  expect_equal(unname(r), phw_palettes$accessible[1:3])
})

test_that("keys overflow into other palettes with a warning", {
  phw_key_reset("t_many")
  withr::defer(phw_key_reset("t_many"))
  expect_warning(k <- phw_colour_key(paste0("g", 1:14), "t_many", palette = "main"), "run out")
  expect_equal(anyDuplicated(k), 0)
  expect_warning(k2 <- phw_colour_key(paste0("h", 1:25)), "tints|run out")
  expect_equal(anyDuplicated(k2), 0)
})

test_that("pinned colours and phw_key_set work", {
  phw_key_reset("t_set")
  withr::defer(phw_key_reset("t_set"))
  phw_key_set("t_set", c(Wales = "#285087"))
  k <- phw_colour_key(c("Wales", "Other area"), "t_set", fixed = c("Other area" = "#000000"))
  expect_equal(unname(k), c("#285087", "#000000"))
  expect_error(phw_key_set("t_set", "#000000"), "named")
})

test_that("keys persist to a CSV file", {
  f <- withr::local_tempfile(fileext = ".csv")
  withr::defer(phw_key_file(NULL))
  phw_key_file(f)
  phw_colour_key(c("A", "B"), "t_file")
  expect_true(file.exists(f))
  saved <- utils::read.csv(f)
  expect_equal(saved$level, c("A", "B"))
  # Simulate a new session: forget memory, read from the file.
  rm(list = "t_file", envir = phwstyle:::phw_key_env)
  phw_key_file(f)
  expect_equal(names(phw_key("t_file")), c("A", "B"))
  phw_key_reset("t_file")
  expect_false("t_file" %in% utils::read.csv(f)$key)
})

test_that("CVD simulation and colour checks work", {
  expect_length(phw_cvd(phw_pal(4), "deutan"), 4)
  expect_equal(phw_cvd("#000000", "protan"), "#000000")
  res <- suppressMessages(phw_check_colours("accessible"))
  expect_true(all(res$pass))
  expect_true(all(attr(res, "contrast") >= 3))
  bad <- suppressMessages(phw_check_colours(c("#FF0000", "#00AA00")))
  expect_false(all(bad$pass))
  expect_s3_class(show_phw_palettes("main", cvd = "tritan"), "ggplot")
  expect_s3_class(scale_shape_phw(), "ScaleDiscrete")
  expect_s3_class(scale_linetype_phw(), "ScaleDiscrete")
})

test_that("palettes accept vectors and functions, and the default can be changed", {
  expect_equal(phw_pal(2, c("#000000", "#FFFFFF")), c("#000000", "#FFFFFF"))
  expect_length(phw_pal(5, c("#000000", "#FFFFFF"), type = "sequential"), 5)
  expect_equal(phw_pal(3, function(n) rep("#123456", n)), rep("#123456", 3))
  expect_error(phw_pal(2, "nope"), "Unknown palette")
  withr::local_options(phwstyle.palette = "accessible")
  expect_equal(phw_pal(5), phw_palettes$accessible[1:5])
})

test_that("the accessible RAG palette separates red and good for deuteranopes", {
  res <- suppressMessages(phw_check_colours("rag_accessible", min_distance = 25))
  expect_true(res$pass[res$vision == "deuteranopia"])
})

test_that("a function palette gives groups its colours in its own order", {
  pal <- function(n) c("#111111", "#222222", "#333333")[seq_len(n)]
  expect_equal(unname(phw_colour_key(c("A", "B", "C"), palette = pal)), pal(3))
})

test_that("an empty group name stops instead of losing its colour", {
  expect_error(phw_colour_key(c("", "a")), "empty name")
})

test_that("key colours are checked and the argument is named", {
  expect_error(phw_colour_key("a", fixed = c(a = "notacolour")), "`fixed` must be colours")
  expect_error(phw_colour_key("a", fixed = c(a = NA)), "`fixed` must be colours")
  expect_error(phw_colour_key("a", neutral_colour = "nope"), "`neutral_colour` must be colours")
  expect_error(phw_key_set("k", c(a = "notacolour")), "`values` must be colours")
  expect_error(phw_key_set("k", stats::setNames("#285087", NA)), "named vector")
})

test_that("key names must be one string", {
  expect_error(phw_key(NULL), "one key name")
  expect_error(phw_key(c("a", "b")), "one key name")
  expect_error(phw_colour_key("a", name = 1), "one key name")
})

test_that("phw_key_file checks the folder, takes an empty file and rejects bad colours", {
  withr::defer(phw_key_file(NULL))
  dir <- withr::local_tempdir()
  expect_error(phw_key_file(file.path(dir, "missing", "keys.csv")), "does not exist")
  expect_error(phw_key_file(dir), "is a folder")
  f <- file.path(dir, "keys.csv")
  file.create(f)
  phw_key_file(f)
  expect_equal(unname(phw_colour_key(c("A", "B"), "file_demo")), phw_palettes$main[1:2])
  expect_equal(read.csv(f)$level, c("A", "B"))
  phw_key_reset("file_demo")
  bad <- file.path(dir, "bad.csv")
  writeLines(c("key,level,colour", "k,a,notacolour"), bad)
  expect_error(phw_key_file(bad), "not colours")
})
