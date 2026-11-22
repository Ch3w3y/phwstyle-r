# Choose readable text colour for a background

Choose readable text colour for a background

## Usage

``` r
phw_text_on(bg)
```

## Arguments

- bg:

  Background colours, or a palette name.

## Value

`"#FFFFFF"` or the PHW text colour, whichever contrasts more, and `NA`
where `bg` is missing.

## Examples

``` r
phw_text_on(phw_col("navy", "light_teal", "gold_465"))
#> [1] "#FFFFFF" "#212B32" "#212B32"
```
