test_that("boundary registry lists every level with valid fields", {
  lv <- phw_boundary_levels()
  expect_true(all(c("health_board", "local_authority", "gp_cluster", "lsoa", "msoa",
                    "senedd_constituency", "electoral_ward") %in% lv$level))
  reg <- phw_boundary_levels(detail = TRUE)
  expect_true(all(reg$detail %in% c("full", "generalised", "super", "ultra")))
  expect_true(all(reg$source %in% c("ons", "datamapwales")))
  full <- boundary_registry()
  expect_false(anyNA(full$code_field))
  expect_true(all(nzchar(full$attribution)))
})

test_that("the nearest level of detail is used", {
  reg <- boundary_registry()
  hb <- reg[reg$level == "health_board", ]
  expect_equal(pick_boundary(hb, "generalised")$detail, "generalised")
  gp <- reg[reg$level == "gp_cluster", ]
  expect_equal(pick_boundary(gp, "ultra")$detail, "full")
  url <- ons_query_url(hb[1, ], 0, 10)
  expect_match(url, "LIKE%20%27W11%25%27")
})

test_that("cache folder can be set and cleared", {
  dir <- withr::local_tempdir()
  withr::local_options(phwstyle.boundary_dir = dir)
  expect_equal(phw_boundaries_cache(), dir)
  file.create(file.path(dir, "x.geojson"))
  expect_message(phw_boundaries_cache(clear = TRUE), "Removed 1")
  expect_length(list.files(dir), 0)
})

test_that("health board boundaries download", {
  skip_on_cran()
  skip_if_offline("services1.arcgis.com")
  skip_if_not_installed("sf")
  skip_if_not_installed("jsonlite")
  withr::local_options(phwstyle.boundary_dir = withr::local_tempdir())
  hb <- phw_boundaries("health_board", detail = "ultra", quiet = TRUE)
  expect_s3_class(hb, "sf")
  expect_equal(nrow(hb), 7)
  expect_true(all(startsWith(hb$code, "W11")))
  expect_equal(sf::st_crs(hb)$epsg, 27700)
  expect_match(attr(hb, "attribution"), "Open Government Licence")
})

test_that("a failed download gives a clear error, or falls back to the cache", {
  skip_if_not_installed("sf")
  skip_if_not_installed("jsonlite")
  dir <- withr::local_tempdir()
  withr::local_options(phwstyle.boundary_dir = dir)
  local_mocked_bindings(download_ons = function(row, file) stop("offline"))
  expect_error(phw_boundaries("health_board", quiet = TRUE), "Could not download")
  # With a cached copy, refresh = TRUE warns and keeps the cache.
  reg <- boundary_registry()
  row <- pick_boundary(reg[reg$level == "health_board", ], "generalised")
  gj <- '{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"LHB23CD":"W11000001","LHB23NM":"A","LHB23NMW":"A"},"geometry":{"type":"Point","coordinates":[-3.5,52]}}]}'
  f <- file.path(dir, sprintf("health_board_%s.geojson", gsub("[^A-Za-z0-9]+", "_", row$layer)))
  writeLines(sub("LHB23", substr(row$code_field, 1, 5), gj, fixed = TRUE), f)
  expect_warning(x <- phw_boundaries("health_board", refresh = TRUE, quiet = TRUE), "cached copy")
  expect_equal(nrow(x), 1)
})

test_that("outdated cached files for a level are removed", {
  dir <- withr::local_tempdir()
  reg <- data.frame(level = "lsoa", layer = "LSOA_2021_NEW")
  keep <- file.path(dir, "lsoa_LSOA_2021_NEW.geojson")
  old <- file.path(dir, "lsoa_LSOA_2011_OLD.geojson")
  other <- file.path(dir, "msoa_MSOA_2011_OLD.geojson")
  for (f in c(keep, old, other)) writeLines("{}", f)
  remove_outdated("lsoa", reg, keep)
  expect_true(file.exists(keep))
  expect_false(file.exists(old))
  expect_true(file.exists(other))
})

test_that("installing fonts to the default folder needs an interactive session", {
  skip_if(interactive())
  expect_error(phw_install_fonts(), "interactive")
})
