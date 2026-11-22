# Maps and boundaries

``` r

library(phwstyle)
library(ggplot2)
library(dplyr)
library(tibble)
```

All data on this page is made up. The boundaries are real, and they
download the first time you use a level.

## Draw a map with `phw_map()`

[`phw_map()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_map.md)
joins your data to Welsh boundaries and draws a styled map in one call.
Give it your data, the column of area codes (`by`), the column to colour
by (`fill`) and the boundary level. Areas with no row in your data are
grey. The boundary attribution becomes the caption unless you set your
own with [`labs()`](https://ggplot2.tidyverse.org/reference/labs.html).

Made-up values for real areas look more convincing when neighbours have
similar values. This helper gives each area a value that changes
smoothly across Wales, with a hot spot and some noise. It only makes up
numbers for the examples. Your own maps use your own data.

``` r

set.seed(1)
made_up_rate <- function(level, lo = 20, hi = 80) {
  b <- phw_boundaries(level)
  xy <- sf::st_coordinates(suppressWarnings(sf::st_centroid(sf::st_geometry(b))))
  x <- (xy[, 1] - min(xy[, 1])) / diff(range(xy[, 1]))
  y <- (xy[, 2] - min(xy[, 2])) / diff(range(xy[, 2]))
  s <- 0.5 * y + 0.2 * (1 - x) + 0.5 * exp(-((x - 0.8)^2 + (y - 0.15)^2) / 0.08)
  s <- (s - min(s)) / diff(range(s))
  tibble(code = b$code, rate = round(lo + (hi - lo) * s + rnorm(nrow(b), 0, 3), 1))
}
la <- made_up_rate("local_authority")
```

### Continuous fills

A numeric `fill` gets a continuous scale in the `"blues"` palette.
Change it with `palette`.

``` r

phw_map(la, by = code, fill = rate, level = "local_authority") +
  labs(fill = "Rate per\n100,000", title = "Rate by local authority")
```

![A map of the 22 local authorities of Wales, shaded from light to dark
blue by a made-up rate that changes smoothly across the
country.](maps_files/figure-html/unnamed-chunk-4-1.png)

### Binned fills

Give `bins` a set of breaks, or a single number of bins, to colour by
band. The legend also shows the lowest and highest values, rounded out
to tidy numbers, so both ends of your data are covered.

``` r

phw_map(la, by = code, fill = rate, level = "local_authority", bins = c(30, 40, 50, 60)) +
  labs(fill = "Rate per\n100,000", title = "Rate by local authority")
```

![The same local authority map with the rate in five bands, and a legend
whose first and last bands run from the lowest to the highest
value.](maps_files/figure-html/unnamed-chunk-5-1.png)

### Groups, with a colour key

A text or factor column gives one colour per group. Give `key` the name
of a colour key and each group keeps its colour in every map, chart and
table that uses it. See [colour
keys](https://ch3w3y.github.io/phwstyle-r/articles/colours.html#colours-that-stay-with-their-groups).

``` r

la$group <- paste("Group", cut(la$rate, quantile(la$rate, 0:4 / 4), labels = 1:4, include.lowest = TRUE))
phw_map(la, by = code, fill = group, level = "local_authority", key = "map_groups") +
  labs(fill = NULL, title = "Local authorities by group")
```

![A map of the 22 local authorities of Wales with each area coloured by
one of four made-up
groups.](maps_files/figure-html/unnamed-chunk-6-1.png)

### Labels

`label` prints text on each area. Give it a column, or an expression
built from the columns of your data and the boundary `name`. When
ggrepel is installed, labels on small areas are moved apart so they stay
readable.

``` r

phw_map(la, by = code, fill = rate, level = "local_authority",
        label = paste(name, rate), bins = c(30, 40, 50, 60)) +
  labs(fill = "Rate", title = "Rate by local authority")
```

![A map of the local authorities of Wales shaded by a made-up rate, with
each area labelled by its name and
rate.](maps_files/figure-html/unnamed-chunk-7-1.png)

### One map per period

[`phw_map()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_map.md)
takes one row per area and period. Add
[`facet_wrap()`](https://ggplot2.tidyverse.org/reference/facet_wrap.html)
to draw one map for each period, on the same scale.

``` r

la_years <- tidyr::expand_grid(code = la$code, year = 2023:2025) |>
  left_join(la[c("code", "rate")], by = "code") |>
  mutate(rate = round(rate * (1 + 0.08 * (year - 2023)) + rnorm(n(), 0, 2), 1))
phw_map(la_years, by = code, fill = rate, level = "local_authority", bins = c(30, 40, 50, 60, 70)) +
  facet_wrap(vars(year)) +
  labs(fill = "Rate", title = "Rate by local authority")
```

![Three maps of the local authorities of Wales side by side, one for
each of 2023, 2024 and 2025, shaded on the same blue scale by a made-up
rate that rises each
year.](maps_files/figure-html/unnamed-chunk-8-1.png)

### Level of detail

`detail` sets how finely the outlines are drawn. The default
`"generalised"` suits most maps. `"super"` and `"ultra"` give smaller
files, and `"full"` is clipped to the coastline.

``` r

phw_map(la, by = code, fill = rate, level = "local_authority", detail = "ultra") +
  labs(fill = "Rate", title = "ultra")
```

![A map of the local authorities of Wales drawn with ultra detail, so
the outlines are smooth and
simple.](maps_files/figure-html/unnamed-chunk-9-1.png)

``` r

phw_map(la, by = code, fill = rate, level = "local_authority", detail = "full") +
  labs(fill = "Rate", title = "full")
```

![The same local authority map with full detail, so the outlines follow
the coastline closely.](maps_files/figure-html/unnamed-chunk-10-1.png)

### Smaller areas

The same call works for the smaller geographies. A map of the middle
layer super output areas (MSOAs) has about 400 areas, so the pattern of
a made-up rate shows in detail. `colour = NA` leaves out the outlines to
keep the map clean.

``` r

msoa <- made_up_rate("msoa")
phw_map(msoa, by = code, fill = rate, level = "msoa", bins = c(30, 40, 50, 60, 70),
        colour = NA) +
  labs(fill = "Rate per\n100,000", title = "Rate by MSOA")
```

![A map of the MSOAs of Wales, about 400 small areas, shaded in bands of
blue by a made-up rate that changes smoothly across the
country.](maps_files/figure-html/unnamed-chunk-11-1.png)

## Build your own map

[`phw_boundaries()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundaries.md)
returns an `sf` data frame with `code`, `name`, `name_cy` (where the
source has Welsh names) and the geometry. Join your own data on `code`,
then draw it with
[`geom_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html).
[`scale_fill_phw_b()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_scales.md)
gives a binned scale and
[`theme_phw_map()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw_map.md)
removes the axes and grid.

``` r

la_sf <- phw_boundaries("local_authority") |>
  left_join(la, by = "code")

ggplot(la_sf) +
  geom_sf(aes(fill = rate), colour = "white", linewidth = 0.3) +
  scale_fill_phw_b(name = "Rate per\n100,000") +
  theme_phw_map() +
  labs(title = "Rate by local authority",
       caption = paste(strwrap(attr(la_sf, "attribution"), 60), collapse = "\n"))
```

![A map of the local authorities of Wales shaded in blue bands by a
made-up rate, drawn with
geom_sf.](maps_files/figure-html/unnamed-chunk-12-1.png)

## Levels

[`phw_boundary_levels()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundary_levels.md)
lists every level and the release used for it. GP clusters and the other
levels work like the examples above.

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
#> 8           ons    2026        full, generalised, super
#> 9  datamapwales    2021                     full, super
#> 10 datamapwales    2021                     full, super
#> 11          ons    2021                     generalised
#> 12          ons    2024        full, generalised, ultra
#> 13          ons    2024        full, generalised, ultra
```

``` r

gp <- phw_boundaries("gp_cluster")
ggplot(gp) +
  geom_sf(fill = phw_colours[["light_teal"]], colour = "white", linewidth = 0.2) +
  theme_phw_map() +
  labs(title = paste(nrow(gp), "GP clusters"))
```

![A map of the GP clusters of Wales in one light teal
colour.](maps_files/figure-html/unnamed-chunk-14-1.png)

## Interactive maps

[`phw_leaflet()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_leaflet.md)
starts a leaflet map on Wales, with a light grey base map.
[`phw_leaflet_polygons()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_leaflet.md)
adds your areas. It takes the same `fill`, `bins` and `key` as
[`phw_map()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_map.md),
plus `label` and `popup` for what appears on hover and click. Ask for
longitude and latitude with `crs = 4326`.

``` r

la_ll <- phw_boundaries("local_authority", crs = 4326) |>
  left_join(la, by = "code")
phw_leaflet() |>
  phw_leaflet_polygons(la_ll, fill = rate, bins = 5, label = name, legend_title = "Rate")
```

[`phw_leaflet_palette()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_leaflet.md)
makes the colour function that
[`phw_leaflet_polygons()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_leaflet.md)
uses. Use it when you add layers with leaflet itself and want the same
colours.

``` r

pal <- phw_leaflet_palette("blues", domain = la_ll$rate, type = "bin", bins = 5)
phw_leaflet() |>
  leaflet::addPolygons(data = la_ll, fillColor = ~pal(rate), fillOpacity = 0.8,
                       weight = 1, color = "#FFFFFF", label = ~name) |>
  leaflet::addLegend(pal = pal, values = la_ll$rate, title = "Rate")
```

For more interactive output, see [the interactive
article](https://ch3w3y.github.io/phwstyle-r/articles/interactive.md).
For finished examples, see the
[gallery](https://ch3w3y.github.io/phwstyle-r/articles/gallery.html#maps).

## Keeping boundaries up to date

When ONS or the Welsh Government publish new boundaries, a new version
of phwstyle points to them. After updating phwstyle, refresh your cached
copies:

``` r

phw_boundaries("electoral_ward", refresh = TRUE)
phw_boundaries_cache(clear = TRUE)   # or clear everything
```

You don’t have to update phwstyle for your maps to keep working:

- Boundaries you have already downloaded are read from your cache, so
  they don’t change and don’t need a connection.
- Where a geography has two sources, the second is used if the first
  can’t be reached.
- If a publisher withdraws a layer that your version of phwstyle lists,
  [`phw_boundaries()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundaries.md)
  fetches the current list of layers from the phwstyle repository on
  GitHub and uses that. The list is checked against both publishers
  every week. Set `options(phwstyle.boundary_update = FALSE)` if you’d
  rather it didn’t look.
- If nothing can be downloaded, boundaries saved from an earlier release
  are returned with a warning.

In each of those cases a warning says what you were given.
