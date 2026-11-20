# Path to a PHW logo file

The bilingual Public Health Wales logo, with Welsh first. Choose the
version that suits the background:

## Usage

``` r
phw_logo(variant = c("blue", "white", "black"), format = c("png", "svg"))
```

## Arguments

- variant:

  One of `"blue"`, `"white"` or `"black"`.

- format:

  `"svg"` or `"png"`.

## Value

A file path, or `NULL` if no logo is available.

## Details

- `"blue"`: Pantone 534, PHW's preferred logo colour, for white
  backgrounds.

- `"white"`: for the gradient band or any dark background.

- `"black"`: for mono print.

The logo is a trade mark of Public Health Wales. phwstyle looks for it
in this order:

1.  the folder in `options(phwstyle.logo_dir = ...)`, for example a copy
    from your organisation's approved logo pack

2.  logos in the package's `logos` folder (none are bundled with the
    released package)

3.  a copy downloaded earlier with
    [`phw_download_logos()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_download_logos.md)

If none is found, `phw_logo()` returns `NULL`. Outputs are then still
branded, just without the logo.

Print guidance (NHS Wales Logo Guidelines, 2022): the minimum height is
24 mm, and the clear space around the logo is half its height.

## Examples

``` r
phw_logo("white", "svg")
#> NULL
```
