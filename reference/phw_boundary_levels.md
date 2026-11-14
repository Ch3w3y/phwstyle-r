# Boundary levels available for Wales

Lists the geographies
[`phw_boundaries()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundaries.md)
can download, with the source, release and level of detail of each.

## Usage

``` r
phw_boundary_levels(detail = FALSE)
```

## Arguments

- detail:

  Show one row per level of detail, rather than one per geography?

## Value

A data frame.

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
```
