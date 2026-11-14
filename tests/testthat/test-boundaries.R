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

test_that("a level with two sources tries them in order", {
  reg <- boundary_registry()
  for (level in c("msoa", "lsoa")) {
    rows <- reg[reg$level == level, ]
    # DataMapWales is full detail and is simplified, so it comes first for any detail.
    for (detail in c("generalised", "super", "ultra", "full")) {
      cand <- boundary_candidates(rows, detail)
      expect_equal(cand$source, c("datamapwales", "ons"), info = paste(level, detail))
    }
  }
  # A level with one source keeps choosing the closest detail.
  hb <- reg[reg$level == "health_board", ]
  expect_equal(pick_boundary(hb, "generalised")$detail, "generalised")
  expect_equal(pick_boundary(hb, "super")$detail, "generalised")
})

test_that("when the first source fails the next is used, with a warning", {
  skip_if_not_installed("sf")
  skip_if_not_installed("jsonlite")
  withr::local_options(phwstyle.boundary_dir = withr::local_tempdir())
  point <- function(code, name, x) {
    sprintf('{"type":"Feature","properties":{"MSOA21CD":"%s","MSOA21NM":"%s","MSOA21NMW":"%s"},"geometry":{"type":"Point","coordinates":[%s,52]}}',
            code, name, name, x)
  }
  local_mocked_bindings(
    download_dmw = function(row, file) stop("DataMapWales is down"),
    download_ons = function(row, file) {
      writeLines(sprintf('{"type":"FeatureCollection","features":[%s,%s]}',
                         point("W02000002", "B", -3.4), point("W02000001", "A", -3.5)), file)
    })
  expect_warning(x <- phw_boundaries("msoa", quiet = TRUE), "Using the super boundaries from the ONS")
  expect_equal(x$code, c("W02000001", "W02000002"))
  expect_equal(attr(x, "source"), "ons")
  # With every source down and nothing cached, the error names them all.
  withr::local_options(phwstyle.boundary_dir = withr::local_tempdir())
  local_mocked_bindings(download_ons = function(row, file) stop("ONS is down"))
  expect_error(phw_boundaries("msoa", quiet = TRUE), "DataMapWales is down")
  expect_error(phw_boundaries("msoa", quiet = TRUE), "ONS is down")
})

test_that("an area held as several rows becomes one row", {
  skip_if_not_installed("sf")
  skip_if_not_installed("jsonlite")
  withr::local_options(phwstyle.boundary_dir = withr::local_tempdir())
  square <- function(code, x) {
    sprintf('{"type":"Feature","properties":{"lsoa21cd":"%s","lsoa21nm":"n %s","lsoa21nmw":"e %s"},"geometry":{"type":"Polygon","coordinates":[[[%d,200000],[%d,200000],[%d,201000],[%d,201000],[%d,200000]]]}}',
            code, code, code, x, x + 1000L, x + 1000L, x, x)
  }
  local_mocked_bindings(download_dmw = function(row, file) {
    # DataMapWales sends British National Grid coordinates and says so.
    writeLines(sprintf('{"type":"FeatureCollection","crs":{"type":"name","properties":{"name":"urn:ogc:def:crs:EPSG::27700"}},"features":[%s,%s,%s]}',
                       square("W01000002", 300000L), square("W01000001", 310000L), square("W01000002", 320000L)), file)
  })
  x <- phw_boundaries("lsoa", detail = "full", quiet = TRUE)
  expect_equal(x$code, c("W01000001", "W01000002"))
  expect_equal(x$name_cy, c("e W01000001", "e W01000002"))
  expect_equal(as.numeric(sf::st_area(x)), c(1e6, 2e6))
})

test_that("MSOA boundaries download from DataMapWales", {
  skip_on_cran()
  skip_if_offline("datamap.gov.wales")
  skip_if_not_installed("sf")
  skip_if_not_installed("jsonlite")
  withr::local_options(phwstyle.boundary_dir = withr::local_tempdir())
  msoa <- phw_boundaries("msoa", detail = "super", quiet = TRUE)
  expect_s3_class(msoa, "sf")
  expect_equal(nrow(msoa), 408)
  expect_true(all(startsWith(msoa$code, "W02")))
  expect_false(anyDuplicated(msoa$code) > 0)
  expect_equal(attr(msoa, "source"), "datamapwales")
})

# One health board as GeoJSON, with the fields of the given release.
one_board <- function(prefix = "LHB23") {
  sprintf('{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"%sCD":"W11000001","%sNM":"A","%sNMW":"B"},"geometry":{"type":"Point","coordinates":[-3.5,52]}}]}',
          prefix, prefix, prefix)
}

test_that("a replaced layer is found in the current list of sources", {
  skip_if_not_installed("sf")
  skip_if_not_installed("jsonlite")
  dir <- withr::local_tempdir()
  withr::local_options(phwstyle.boundary_dir = dir, phwstyle.boundary_update = TRUE)
  packaged <- boundary_registry()
  current <- packaged[packaged$level != "health_board" | packaged$detail == "generalised", ]
  hb <- current$level == "health_board"
  current$layer[hb] <- "LHB_DEC_2030_WA_BGC"
  current[hb, c("code_field", "name_field", "name_cy_field")] <- list("LHB30CD", "LHB30NM", "LHB30NMW")
  asked <- character()
  local_mocked_bindings(
    download_boundary_list = function(url, file) {
      asked <<- c(asked, url)
      utils::write.csv(current, file, row.names = FALSE)
    },
    download_ons = function(row, file) {
      if (row$layer != "LHB_DEC_2030_WA_BGC") stop("Token Required")
      writeLines(one_board("LHB30"), file)
    })
  expect_warning(x <- phw_boundaries("health_board", quiet = TRUE), "current list of sources")
  expect_equal(x$code, "W11000001")
  expect_equal(x$name_cy, "B")
  expect_equal(attr(x, "layer"), "LHB_DEC_2030_WA_BGC")
  expect_match(asked, "^https://raw.githubusercontent.com/.*/inst/extdata/boundaries.csv$")
  # The list is kept, so the next call goes straight to the new layer.
  expect_equal(unique(boundary_registry()$layer[hb]), "LHB_DEC_2030_WA_BGC")
  expect_no_warning(y <- phw_boundaries("health_board", quiet = TRUE))
  expect_equal(attr(y, "layer"), "LHB_DEC_2030_WA_BGC")
  expect_length(asked, 1)
  # Clearing the cache goes back to the list in the package.
  suppressMessages(phw_boundaries_cache(clear = TRUE))
  expect_equal(boundary_registry(), packaged)
})

test_that("a list that is not a plain list of layers is ignored", {
  skip_if_not_installed("sf")
  skip_if_not_installed("jsonlite")
  dir <- withr::local_tempdir()
  withr::local_options(phwstyle.boundary_dir = dir, phwstyle.boundary_update = TRUE)
  bad <- boundary_registry()
  bad$layer[bad$level == "health_board"] <- "x/FeatureServer/0/query?where=1=1&y"
  expect_false(valid_boundary_list(bad))
  expect_false(valid_boundary_list(bad[0, ]))
  expect_false(valid_boundary_list(bad["level"]))
  expect_true(valid_boundary_list(boundary_registry()))
  local_mocked_bindings(
    download_boundary_list = function(url, file) utils::write.csv(bad, file, row.names = FALSE),
    download_ons = function(row, file) stop("offline"))
  expect_error(phw_boundaries("health_board", quiet = TRUE), "Could not download")
  expect_false(file.exists(boundary_list_file()))
  # No list at all (offline) gives the same error.
  local_mocked_bindings(download_boundary_list = function(url, file) stop("offline"))
  expect_error(phw_boundaries("health_board", quiet = TRUE), "Could not download")
  # And the option stops it looking.
  withr::local_options(phwstyle.boundary_update = FALSE)
  local_mocked_bindings(download_boundary_list = function(url, file) stop("should not be called"))
  expect_null(boundary_list_update())
})

test_that("boundaries saved from an older release are used when nothing downloads", {
  skip_if_not_installed("sf")
  skip_if_not_installed("jsonlite")
  dir <- withr::local_tempdir()
  withr::local_options(phwstyle.boundary_dir = dir)
  local_mocked_bindings(download_ons = function(row, file) stop("offline"))
  writeLines(one_board("LHB19"), file.path(dir, "health_board_Local_Health_Boards_April_2019_WA_BGC.geojson"))
  # A file for another level is not used.
  writeLines(one_board("LAD19"), file.path(dir, "local_authority_LAD_2019.geojson"))
  expect_warning(x <- phw_boundaries("health_board", quiet = TRUE), "saved earlier")
  expect_equal(nrow(x), 1)
  expect_equal(c(x$code, x$name, x$name_cy), c("W11000001", "A", "B"))
  expect_equal(attr(x, "source"), "ons")
  expect_match(attr(x, "attribution"), "Office for National Statistics")
})

test_that("the fields of a saved file are found from their names", {
  reg <- boundary_registry()
  for (i in seq_len(nrow(reg))) {
    fields <- unique(c("FID", "id", reg$code_field[i], reg$name_field[i],
                       if (nzchar(reg$name_cy_field[i])) reg$name_cy_field[i], "geometry"))
    expect_equal(guess_boundary_fields(fields),
                 c(code = reg$code_field[i], name = reg$name_field[i], name_cy = reg$name_cy_field[i]),
                 info = reg$layer[i])
  }
  # The fields DataMapWales layers have, with their other columns.
  expect_equal(guess_boundary_fields(c("lsoa21cd", "lsoa21nm", "lsoa21nmw", "lsoaalternativeenglish", "id", "geometry")),
               c(code = "lsoa21cd", name = "lsoa21nm", name_cy = "lsoa21nmw"))
  expect_equal(guess_boundary_fields(c("community", "local_authority", "area_description", "geometry")),
               c(code = "community", name = "community", name_cy = ""))
  expect_null(guess_boundary_fields(c("FID", "geometry")))
})

test_that("crs and level are checked before any download", {
  skip_if_not_installed("sf")
  skip_if_not_installed("jsonlite")
  local_mocked_bindings(boundary_fetch = function(...) stop("should not download"))
  for (crs in list(99999, "notacrs", NA, NULL)) {
    expect_error(phw_boundaries("health_board", crs = crs), "`crs` must be a coordinate reference system")
  }
  expect_error(phw_boundaries(c("health_board", "local_authority")), "`level` must be one level")
  expect_error(phw_boundary_levels(NA), "`detail` must be")
  expect_error(phw_boundaries_cache(NA), "`clear` must be")
})

test_that("a failed download shows only the clean error, not the download warnings", {
  skip_if_not_installed("sf")
  skip_if_not_installed("jsonlite")
  withr::local_options(phwstyle.boundary_dir = withr::local_tempdir(), phwstyle.boundary_update = FALSE)
  local_mocked_bindings(download_ons = function(row, file) {
    warning("URL status was 'Couldn't connect to server'")
    stop("cannot open URL")
  }, download_dmw = function(row, file) stop("cannot open URL"))
  expect_no_warning(expect_error(phw_boundaries("health_board", quiet = TRUE), "Could not download"))
})
