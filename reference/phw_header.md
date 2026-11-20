# PHW branded header band for HTML pages

The navy-to-cyan gradient band with the white PHW logo, as used across
the top of PHW reports. Use it as the first element of a Shiny UI, or in
any htmltools page.

## Usage

``` r
phw_header(
  title = NULL,
  subtitle = NULL,
  href = "https://phw.nhs.wales/",
  logo = TRUE,
  org = phw_org
)
```

## Arguments

- title:

  Page or app title shown in the band.

- subtitle:

  Optional second line, e.g. the team name.

- href:

  Where the logo links to.

- logo:

  Show the logo? With `FALSE`, or when no logo is available, `org` is
  shown as text instead.

- org:

  Organisation name used as the text fallback and alt text.

## Value

An HTML tag.

## Examples

``` r
phw_header("Weekly surveillance", subtitle = "Team name")
#> <header class="phw-header">
#>   <a href="https://phw.nhs.wales/" class="phw-header-logo">
#>     <span class="phw-header-name">Public Health Wales</span>
#>   </a>
#>   <div class="phw-header-text">
#>     <div class="phw-header-title">Weekly surveillance</div>
#>     <div class="phw-header-subtitle">Team name</div>
#>   </div>
#> </header>
```
