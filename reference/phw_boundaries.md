# Boundaries of Welsh areas for maps

Downloads boundaries for one level of geography in Wales, from the
Office for National Statistics (ONS) Open Geography Portal or
DataMapWales, and returns them as an `sf` data frame ready for
[`ggplot2::geom_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html),
with
[`theme_phw_map()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw_map.md).
Each download is saved in your user cache folder, so later calls work
offline.

## Usage

``` r
phw_boundaries(
  level,
  detail = c("generalised", "super", "ultra", "full"),
  crs = 27700,
  refresh = FALSE,
  cache = TRUE,
  quiet = FALSE
)
```

## Arguments

- level:

  The geography, e.g. `"health_board"`, `"local_authority"`,
  `"gp_cluster"`, `"lsoa"`. See
  [`phw_boundary_levels()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundary_levels.md).

- detail:

  How detailed the outlines are: `"generalised"` (20 m, the default and
  best for most maps), `"super"` (200 m), `"ultra"` (500 m, small
  files), or `"full"` (clipped to the coastline at full resolution).
  Where a level has no layer at that detail, the nearest one is used.
  DataMapWales layers come at full detail and are simplified with
  [`sf::st_simplify()`](https://r-spatial.github.io/sf/reference/geos_unary.html).

- crs:

  Coordinate reference system of the result. Defaults to British
  National Grid (27700); use 4326 for longitude and latitude (e.g. for
  leaflet).

- refresh:

  Download again even if a cached copy exists? If the download fails,
  the cached copy is used with a warning.

- cache:

  Save the download in the cache folder?

- quiet:

  Hide progress messages?

## Value

An `sf` data frame with columns `code`, `name` and, where the source has
one, `name_cy` (Welsh name), plus the geometry. Attributes `source`,
`layer` and `attribution` say where it came from; use
`attr(x, "attribution")` in your caption.

## Details

See
[`phw_boundary_levels()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundary_levels.md)
for the levels and the release used for each. The list of releases is
updated in the package when new boundaries are published, so you get the
newest boundaries by updating phwstyle and calling with
`refresh = TRUE`.

Nothing is downloaded when phwstyle is installed. The first call for a
level downloads it; later calls read the cached copy, so they are fast
and work offline. Without an internet connection and without a cached
copy, the function stops with an informative error. When a newer release
of a level is downloaded, cached files from older releases of that level
are deleted, so the cache stays small. Clear it all with
`phw_boundaries_cache(clear = TRUE)`.

Where a geography is published by more than one source, the others are
tried in turn if the first cannot be reached, and a warning says which
boundaries you were given. MSOAs and LSOAs come from DataMapWales, with
the super generalised ONS boundaries as the alternative.

Publishers sometimes replace or withdraw a layer after a version of
phwstyle is released. If none of the layers listed in your version can
be downloaded, the function fetches the current list from the phwstyle
repository on GitHub (a small text file, checked every week) and tries
the layers in it, so an older installation keeps working. Set
`options(phwstyle.boundary_update = FALSE)` to stop it looking. If that
fails too and boundaries for the level were saved from an earlier
release, those are returned with a warning.

## See also

[`phw_boundary_levels()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundary_levels.md),
[`phw_boundaries_cache()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundaries_cache.md)

## Examples

``` r
phw_boundary_levels()
#>                       level                                          label
#> 1                   country                                Country (Wales)
#> 2              health_board                            Local health boards
#> 3           local_authority                              Local authorities
#> 4                gp_cluster                     GP (primary care) clusters
#> 5       senedd_constituency                          Senedd constituencies
#> 6  westminster_constituency                   UK Parliament constituencies
#> 7            electoral_ward                                Electoral wards
#> 8                 community Communities (community and town council areas)
#> 9                      msoa         Middle layer super output areas (2021)
#> 10                     lsoa          Lower layer super output areas (2021)
#> 11              output_area                            Output areas (2021)
#> 12              fire_rescue                    Fire and rescue authorities
#> 13             police_force                             Police force areas
#>          source release                          detail
#> 1           ons    2025 full, generalised, super, ultra
#> 2           ons    2023        full, generalised, ultra
#> 3           ons    2026 full, generalised, super, ultra
#> 4  datamapwales    2024                            full
#> 5           ons    2026        full, generalised, super
#> 6           ons    2024 full, generalised, super, ultra
#> 7           ons    2026        full, generalised, super
#> 8  datamapwales    2022                            full
#> 9  datamapwales    2021                     full, super
#> 10 datamapwales    2021                     full, super
#> 11          ons    2021                     generalised
#> 12          ons    2024        full, generalised, ultra
#> 13          ons    2024        full, generalised, ultra
# \donttest{
if (requireNamespace("sf", quietly = TRUE) && interactive()) {
  hb <- phw_boundaries("health_board")
  library(ggplot2)
  ggplot(hb) +
    geom_sf(aes(fill = name)) +
    scale_fill_phw_d() +
    theme_phw_map() +
    labs(caption = attr(hb, "attribution"))
}
# }
```
