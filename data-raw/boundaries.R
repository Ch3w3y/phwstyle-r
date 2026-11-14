# Build inst/extdata/boundaries.csv: the list of Welsh boundary layers that
# phw_boundaries() downloads.
#
# Run from the package root:  Rscript data-raw/boundaries.R
#
# It looks up the newest release of each boundary set on the ONS Open
# Geography Portal and DataMapWales, and records the service name and the
# code and name fields for each level of detail. The scheduled GitHub
# Actions workflow (.github/workflows/update-boundaries.yaml) runs it every
# week and opens a pull request when a new release appears.
#
# Three rules keep the list safe to merge:
#   * a layer is listed only after a test query shows it can be downloaded
#     without a token and has Welsh areas in it;
#   * a new ONS release is used once its generalised boundaries are out, not
#     while only the full resolution ones are;
#   * a source that cannot be reached keeps the layers it already has in the
#     list, and the problem is reported.
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
  # MSOAs and LSOAs come from DataMapWales first: the ONS portal no longer
  # publishes its plain 2021 boundary layers, only a super generalised one.
  list(level = "msoa", label = "Middle layer super output areas (2021)",
       dmw = "^geonode:msoa_(\\d{4})_w_hwm$",
       ons = c("^Middle_layer_Super_Output_Areas_December_(2021)_Boundaries_EW_(B[FGSU][CE])", "^MSOA_(2021)_EW_(B[FGSU][CE])"),
       filter = "W02"),
  list(level = "lsoa", label = "Lower layer super output areas (2021)",
       dmw = "^geonode:lsoa_(\\d{4})_w_hwm$",
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

# Three tries, so one dropped connection does not look like a missing layer.
retry <- function(expr_fun) {
  for (i in 1:3) {
    out <- tryCatch(expr_fun(), error = function(e) e)
    if (!inherits(out, "error")) return(out)
    Sys.sleep(2 * i)
  }
  stop(out)
}
fetch_json <- function(url) retry(function() jsonlite::fromJSON(url, simplifyVector = FALSE))
fetch_text <- function(url) retry(function() paste(readLines(url, warn = FALSE), collapse = ""))

# The list as it is now. A source that cannot be checked today keeps the
# rows it has here, so an outage never removes a level from the package.
current <- utils::read.csv("inst/extdata/boundaries.csv", stringsAsFactors = FALSE,
                           na.strings = character(), encoding = "UTF-8")
problems <- character()
problem <- function(...) {
  msg <- paste0(...)
  message("PROBLEM: ", msg)
  problems <<- c(problems, msg)
}

ons_services <- vapply(fetch_json(paste0(ons_root, "?f=json"))$services, `[[`, "", "name")
ons_services <- unique(ons_services)

# The code and name fields of an ONS layer, or NULL if the layer cannot be
# used: the catalogue also lists layers that need a token, and layers with
# no Welsh areas.
ons_layer <- function(service, filter) {
  info <- tryCatch(fetch_json(sprintf("%s/%s/FeatureServer/0?f=json", ons_root, service)), error = function(e) NULL)
  if (is.null(info) || !is.null(info$error) || !length(info$fields)) return(NULL)
  f <- vapply(info$fields, `[[`, "", "name")
  code <- grep("^[A-Z0-9]+\\d{2}CD$", f, value = TRUE)[1]
  if (is.na(code)) return(NULL)
  where <- utils::URLencode(sprintf("%s LIKE '%s%%'", code, filter), reserved = TRUE)
  n <- tryCatch(fetch_json(sprintf("%s/%s/FeatureServer/0/query?where=%s&returnCountOnly=true&f=json",
                                   ons_root, service, where))$count, error = function(e) NULL)
  if (is.null(n) || n < 1) return(NULL)
  # The name fields share the code's prefix (output areas have none).
  stem <- sub("CD$", "", code)
  name <- if (paste0(stem, "NM") %in% f) paste0(stem, "NM") else code
  name_cy <- if (paste0(stem, "NMW") %in% f) paste0(stem, "NMW") else ""
  list(code = code, name = name, name_cy = name_cy, areas = n)
}

dmw_caps <- NULL
dmw_layers <- function() {
  if (is.null(dmw_caps)) {
    caps <- fetch_text(paste0(dmw_wfs, "?service=WFS&version=2.0.0&request=GetCapabilities"))
    dmw_caps <<- gsub("</?Name>", "", regmatches(caps, gregexpr("<Name>geonode:[^<]+</Name>", caps))[[1]])
  }
  dmw_caps
}

# The fields of a DataMapWales layer, or NULL if it has no areas.
dmw_layer <- function(layer) {
  hits <- tryCatch(fetch_text(sprintf("%s?service=WFS&version=2.0.0&request=GetFeature&typeNames=%s&resultType=hits",
                                      dmw_wfs, layer)), error = function(e) "")
  n <- suppressWarnings(as.integer(sub('.*numberMatched="(\\d+)".*', "\\1", hits)))
  if (is.na(n) || n < 1) return(NULL)
  desc <- fetch_text(sprintf("%s?service=WFS&version=2.0.0&request=DescribeFeatureType&typeNames=%s", dmw_wfs, layer))
  f <- gsub('name="|"', "", regmatches(desc, gregexpr('name="[^"]+"', desc))[[1]])
  code <- intersect(c("code", "Code", "CODE", grep("cd$", f, value = TRUE, ignore.case = TRUE)), f)[1]
  name <- intersect(c("name_en", "name", "Name", "NAME", "community", grep("nm$", f, value = TRUE, ignore.case = TRUE)), f)[1]
  if (is.na(name)) return(NULL)
  if (is.na(code)) code <- name
  name_cy <- intersect(c("name_cy", "enw_cy", "enw", grep("nmw$", f, value = TRUE, ignore.case = TRUE)), f)[1]
  list(code = code, name = name, name_cy = if (is.na(name_cy)) "" else name_cy, areas = n)
}

dmw_rows <- function(lv) {
  layers <- dmw_layers()
  m <- regmatches(layers, regexec(lv$dmw, layers))
  ok <- lengths(m) == 2
  cand <- data.frame(layer = layers[ok], year = as.integer(vapply(m[ok], `[`, "", 2)), stringsAsFactors = FALSE)
  cand <- cand[order(-cand$year, nchar(cand$layer)), ]
  # The newest layer that has areas in it.
  for (i in seq_len(nrow(cand))) {
    fl <- dmw_layer(cand$layer[i])
    if (is.null(fl)) next
    message(lv$level, ": ", cand$layer[i], " (", fl$areas, " areas)")
    return(data.frame(
      level = lv$level, label = lv$label, detail = "full", source = "datamapwales",
      layer = cand$layer[i], code_field = fl$code, name_field = fl$name, name_cy_field = fl$name_cy,
      filter = "", release = cand$year[i],
      attribution = "Source: Welsh Government (DataMapWales) licensed under the Open Government Licence v3.0. Contains OS data (c) Crown copyright and database right.",
      stringsAsFactors = FALSE))
  }
  NULL
}

ons_rows <- function(lv) {
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
  if (is.null(hits) || !nrow(hits)) return(NULL)
  hits$month <- vapply(hits$service, month_rank, 0)
  hits$version <- as.integer(sub(".*_V(\\d+).*", "\\1", ifelse(grepl("_V\\d+", hits$service), hits$service, "_V1")))
  hits$ruc <- grepl("_RUC$", hits$service)
  # Newest release first, then plain layers before RUC variants, then the highest version.
  hits <- hits[order(-hits$year, -hits$month, hits$ruc, -hits$version), ]
  releases <- unique(hits[, c("year", "month")])
  # The layers of one release that can be downloaded, one per level of detail.
  release_rows <- function(year, month) {
    rel <- hits[hits$year == year & hits$month == month, ]
    out <- list()
    for (dc in names(detail_codes)) {
      for (svc in rel$service[rel$code == dc]) {
        fl <- ons_layer(svc, lv$filter)
        if (is.null(fl)) next
        out[[length(out) + 1]] <- data.frame(
          level = lv$level, label = lv$label, detail = detail_codes[[dc]], source = "ons",
          layer = svc, code_field = fl$code, name_field = fl$name, name_cy_field = fl$name_cy,
          filter = lv$filter, release = year,
          attribution = "Source: Office for National Statistics licensed under the Open Government Licence v3.0. Contains OS data (c) Crown copyright and database right.",
          stringsAsFactors = FALSE)
        break
      }
    }
    if (length(out)) do.call(rbind, out)
  }
  # ONS often publishes the full resolution boundaries of a new release
  # before the generalised ones. Moving to a release like that would take
  # the default (generalised) boundaries away, so use the newest release that
  # has them. If none has, use the newest release with anything.
  first <- NULL
  for (i in seq_len(nrow(releases))) {
    rr <- release_rows(releases$year[i], releases$month[i])
    if (is.null(rr)) next
    if (is.null(first)) first <- rr
    if ("generalised" %in% rr$detail) {
      if (!identical(rr$layer, first$layer)) {
        message(lv$level, ": a newer release has only ", paste(first$detail, collapse = ", "),
                " boundaries so far (", first$layer[1], "); keeping ", rr$layer[1])
      }
      first <- rr
      break
    }
  }
  if (!is.null(first)) for (k in seq_len(nrow(first))) message(lv$level, " ", first$detail[k], ": ", first$layer[k])
  first
}

rows <- list()
# A level can have a DataMapWales layer, ONS layers, or both. The first row
# written for a level is the one phw_boundaries() tries first.
for (lv in levels) {
  for (src in c("datamapwales", "ons")) {
    pattern <- if (src == "ons") lv$ons else lv$dmw
    if (is.null(pattern)) next
    found <- tryCatch(if (src == "ons") ons_rows(lv) else dmw_rows(lv), error = function(e) {
      problem(lv$level, " (", src, "): ", conditionMessage(e))
      NULL
    })
    if (is.null(found)) {
      found <- current[current$level == lv$level & current$source == src, , drop = FALSE]
      problem(lv$level, ": no layer on ", src, " could be downloaded today; ",
              if (nrow(found)) "kept the layers already listed" else "nothing is listed for this source")
    }
    rows[[length(rows) + 1]] <- found[, names(current), drop = FALSE]
  }
}

reg <- do.call(rbind, rows)
rownames(reg) <- NULL
missing_levels <- setdiff(vapply(levels, `[[`, "", "level"), reg$level)
if (length(missing_levels)) stop("No source at all for: ", paste(missing_levels, collapse = ", "))
utils::write.csv(reg, "inst/extdata/boundaries.csv", row.names = FALSE, fileEncoding = "UTF-8")
message("Wrote ", nrow(reg), " rows to inst/extdata/boundaries.csv")

# The workflow reads this file: it adds the problems to the pull request and
# then fails, so a source that has stopped working is noticed.
report <- Sys.getenv("PHW_BOUNDARY_REPORT")
if (nzchar(report)) writeLines(problems, report)
if (length(problems)) message(length(problems), " problem(s) found; see above.")
