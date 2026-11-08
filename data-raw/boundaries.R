# Build inst/extdata/boundaries.csv: the list of Welsh boundary layers that
# phw_boundaries() downloads.
#
# Run from the package root:  Rscript data-raw/boundaries.R
#
# It looks up the newest release of each boundary set on the ONS Open
# Geography Portal and DataMapWales, and records the service name and the
# code and name fields for each level of detail. The scheduled GitHub
# Actions workflow (.github/workflows/update-boundaries.yaml) runs it every
# month and opens a pull request when a new release appears.
#
# Needs: jsonlite. Network access to services1.arcgis.com and
# datamap.gov.wales.

ons_root <- "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services"
dmw_wfs <- "https://datamap.gov.wales/geoserver/ows"

# One entry per level. `ons` patterns match both ONS naming schemes, e.g.
# "LAD_MAY_2025_UK_BGC_V2" and "Local_Health_Boards_December_2023_WA_BGC".
# `filter` keeps Welsh areas from UK or England and Wales layers.
levels <- list(
  list(level = "country", label = "Country (Wales)",
       ons = c("^Countries_[A-Za-z]+_(\\d{4})_Boundaries_UK_(B[FGSU][CE])", "^CTRY_[A-Z]+_(\\d{4})_UK_(B[FGSU][CE])"),
       filter = "W92"),
  list(level = "health_board", label = "Local health boards",
       ons = c("^Local_Health_Boards_[A-Za-z]+_(\\d{4})_WA_(B[FGSU][CE])", "^LHB_[A-Z]+_(\\d{4})_WA_(B[FGSU][CE])"),
       filter = "W11"),
  list(level = "local_authority", label = "Local authorities",
       ons = c("^LAD_[A-Z]+_(\\d{4})_UK_(B[FGSU][CE])", "^Local_Authority_Districts_[A-Za-z]+_(\\d{4})_Boundaries_UK_(B[FGSU][CE])"),
       filter = "W06"),
  list(level = "gp_cluster", label = "GP (primary care) clusters",
       dmw = "^geonode:primary_care_clusters_(\\d{4})"),
  list(level = "senedd_constituency", label = "Senedd constituencies",
       ons = c("^SENC_[A-Z]+_(\\d{4})_WA_(B[FGSU][CE])", "^Senedd_Cymru_Constituencies_[A-Za-z]+_(\\d{4})_Boundaries_WA_(B[FGSU][CE])"),
       filter = "W09"),
  list(level = "westminster_constituency", label = "UK Parliament constituencies",
       ons = c("^Westminster_Parliamentary_Constituencies_[A-Za-z]+_(\\d{4})_Boundaries_UK_(B[FGSU][CE])", "^PCON_[A-Z]+_(\\d{4})_UK_(B[FGSU][CE])"),
       filter = "W07"),
  list(level = "electoral_ward", label = "Electoral wards",
       ons = c("^WD_[A-Z]+_(\\d{4})_UK_(B[FGSU][CE])", "^Wards_[A-Za-z]+_(\\d{4})_Boundaries_UK_(B[FGSU][CE])"),
       filter = "W05"),
  list(level = "community", label = "Communities (community and town council areas)",
       dmw = "^geonode:communities_wales_[a-z]+_(\\d{4})$"),
  list(level = "msoa", label = "Middle layer super output areas (2021)",
       ons = c("^Middle_layer_Super_Output_Areas_December_(2021)_Boundaries_EW_(B[FGSU][CE])", "^MSOA_(2021)_EW_(B[FGSU][CE])"),
       filter = "W02"),
  list(level = "lsoa", label = "Lower layer super output areas (2021)",
       ons = c("^Lower_layer_Super_Output_Areas_December_(2021)_Boundaries_EW_(B[FGSU][CE])", "^LSOA_(2021)_EW_(B[FGSU][CE])"),
       filter = "W01"),
  list(level = "output_area", label = "Output areas (2021)",
       ons = c("^Output_Areas_December_(2021)_Boundaries_EW_(B[FGSU][CE])", "^OA_(2021)_EW_(B[FGSU][CE])"),
       filter = "W00"),
  list(level = "fire_rescue", label = "Fire and rescue authorities",
       ons = c("^Fire_and_Rescue_Authorities_[A-Za-z]+_(\\d{4})_Boundaries_EW_(B[FGSU][CE])", "^FRA_[A-Z]+_(\\d{4})_(?:UK|EW)_(B[FGSU][CE])"),
       filter = "W25"),
  list(level = "police_force", label = "Police force areas",
       ons = c("^Police_Force_Areas_[A-Za-z]+_(\\d{4})_EW_(B[FGSU][CE])", "^PFA_[A-Z]+_(\\d{4})_EW_(B[FGSU][CE])"),
       filter = "W15")
)

detail_codes <- c(BFC = "full", BGC = "generalised", BSC = "super", BUC = "ultra")
month_rank <- function(x) {
  m <- match(toupper(substr(regmatches(x, regexpr("(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)", toupper(x))), 1, 3)),
             toupper(month.abb))
  if (length(m) == 0 || is.na(m)) 0 else m
}

fetch_json <- function(url) jsonlite::fromJSON(url, simplifyVector = FALSE)

ons_services <- vapply(fetch_json(paste0(ons_root, "?f=json"))$services, `[[`, "", "name")
ons_services <- unique(ons_services)

ons_fields <- function(service) {
  info <- fetch_json(sprintf("%s/%s/FeatureServer/0?f=json", ons_root, service))
  f <- vapply(info$fields, `[[`, "", "name")
  code <- grep("^[A-Z0-9]+\\d{2}CD$", f, value = TRUE)[1]
  # The name fields share the code's prefix (output areas have none).
  stem <- sub("CD$", "", code)
  name <- if (paste0(stem, "NM") %in% f) paste0(stem, "NM") else code
  name_cy <- if (paste0(stem, "NMW") %in% f) paste0(stem, "NMW") else NA
  c(code = code, name = name, name_cy = if (is.na(name_cy)) "" else name_cy)
}

rows <- list()
for (lv in levels) {
  if (!is.null(lv$ons)) {
    hits <- do.call(rbind, lapply(lv$ons, function(p) {
      m <- regmatches(ons_services, regexec(p, ons_services, perl = TRUE))
      ok <- lengths(m) == 3
      if (!any(ok)) return(NULL)
      data.frame(service = ons_services[ok],
                 year = as.integer(vapply(m[ok], `[`, "", 2)),
                 code = vapply(m[ok], `[`, "", 3),
                 stringsAsFactors = FALSE)
    }))
    hits <- hits[hits$code %in% names(detail_codes), , drop = FALSE]
    hits$month <- vapply(hits$service, month_rank, 0)
    hits$version <- as.integer(sub(".*_V(\\d+).*", "\\1", ifelse(grepl("_V\\d+", hits$service), hits$service, "_V1")))
    hits$ruc <- grepl("_RUC$", hits$service)
    # Newest release first, then plain layers before RUC variants, then the highest version.
    hits <- hits[order(-hits$year, -hits$month, hits$ruc, -hits$version), ]
    newest <- hits[hits$year == hits$year[1] & hits$month == hits$month[1], ]
    for (dc in names(detail_codes)) {
      h <- newest[newest$code == dc, , drop = FALSE]
      if (!nrow(h)) next
      svc <- h$service[1]
      fl <- ons_fields(svc)
      rows[[length(rows) + 1]] <- data.frame(
        level = lv$level, label = lv$label, detail = detail_codes[[dc]], source = "ons",
        layer = svc, code_field = fl[["code"]], name_field = fl[["name"]], name_cy_field = fl[["name_cy"]],
        filter = lv$filter, release = h$year[1],
        attribution = "Source: Office for National Statistics licensed under the Open Government Licence v3.0. Contains OS data (c) Crown copyright and database right.",
        stringsAsFactors = FALSE)
      message(lv$level, " ", detail_codes[[dc]], ": ", svc)
    }
  } else {
    caps <- readLines(paste0(dmw_wfs, "?service=WFS&version=2.0.0&request=GetCapabilities"), warn = FALSE)
    caps <- paste(caps, collapse = "")
    layers <- regmatches(caps, gregexpr("<Name>geonode:[^<]+</Name>", caps))[[1]]
    layers <- gsub("</?Name>", "", layers)
    m <- regmatches(layers, regexec(lv$dmw, layers))
    ok <- lengths(m) == 2
    cand <- data.frame(layer = layers[ok], year = as.integer(vapply(m[ok], `[`, "", 2)), stringsAsFactors = FALSE)
    cand <- cand[order(-cand$year, nchar(cand$layer)), ]
    layer <- cand$layer[1]
    desc <- paste(readLines(sprintf("%s?service=WFS&version=2.0.0&request=DescribeFeatureType&typeNames=%s", dmw_wfs, layer),
                            warn = FALSE), collapse = "")
    f <- gsub('name="|"', "", regmatches(desc, gregexpr('name="[^"]+"', desc))[[1]])
    code <- intersect(c("code", "Code", "CODE", grep("cd$", f, value = TRUE, ignore.case = TRUE)), f)[1]
    name <- intersect(c("name_en", "name", "Name", "NAME", "community", grep("nm$", f, value = TRUE, ignore.case = TRUE)), f)[1]
    if (is.na(code)) code <- name
    name_cy <- intersect(c("name_cy", "enw_cy", "enw", grep("nmw$", f, value = TRUE, ignore.case = TRUE)), f)[1]
    rows[[length(rows) + 1]] <- data.frame(
      level = lv$level, label = lv$label, detail = "full", source = "datamapwales",
      layer = layer, code_field = code, name_field = name, name_cy_field = if (is.na(name_cy)) "" else name_cy,
      filter = "", release = cand$year[1],
      attribution = "Source: Welsh Government (DataMapWales) licensed under the Open Government Licence v3.0. Contains OS data (c) Crown copyright and database right.",
      stringsAsFactors = FALSE)
    message(lv$level, ": ", layer)
  }
}

reg <- do.call(rbind, rows)
utils::write.csv(reg, "inst/extdata/boundaries.csv", row.names = FALSE, fileEncoding = "UTF-8")
message("Wrote ", nrow(reg), " rows to inst/extdata/boundaries.csv")
