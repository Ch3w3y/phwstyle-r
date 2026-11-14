# Download the PHW logo

Downloads the official bilingual logo (SVG) from phw.nhs.wales. It then
makes blue, white and black versions in SVG and PNG, and stores them in
your user cache folder (see
[`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html)). You only
need to do this once per computer. It isn't needed if you set
`options(phwstyle.logo_dir = ...)` to a folder with your own copies.

## Usage

``` r
phw_download_logos(ask = interactive(), url = logo_url)
```

## Arguments

- ask:

  Ask before downloading? Always `TRUE` in interactive sessions unless
  you set it to `FALSE`.

- url:

  Where to download the white SVG logo from.

## Value

The cache folder, invisibly, or `NULL` if nothing was downloaded.

## Details

The logo is a trade mark of Public Health Wales. Use it only in line
with PHW's brand guidance.

## Examples

``` r
# \donttest{
# Run once per computer. It asks before downloading anything.
if (interactive()) phw_download_logos()
# }
```
