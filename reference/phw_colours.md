# Public Health Wales brand colours

A named character vector of every colour in the PHW identity, as used by
its Communicable Disease Surveillance Centre (CDSC). Each colour and its
role is listed in
`system.file("brand", "palette.csv", package = "phwstyle")`.

## Usage

``` r
phw_colours
```

## Format

A named character vector of hex colours.

## Details

- `navy`, `teal`, `orange`, `pink` are the four chart colours PHW
  reports use today, in that order.

- `blue_534` and `gold_465` are the official NHS Wales logo colours
  (Pantone 534 and 465).

- `blue`, `green`, `magenta` come from the phw.nhs.wales website.

- Greys and `text` are the NHS digital front-end neutrals used on the
  site.

- `mint` and `green_bright` are two of the six strategic priority
  colours in PHW's Long-Term Strategy 2023 to 2035.

## Examples

``` r
phw_colours["navy"]
#>      navy 
#> "#285087" 
```
