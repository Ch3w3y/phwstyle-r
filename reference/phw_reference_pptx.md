# Path to the PHW PowerPoint template

The template behind
[`phw_pptx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_pptx.md)
and the Quarto `phw-pptx` format: 16:9, Ubuntu text (named, not
embedded), navy titles, PHW theme colours and the layouts Title Slide,
Title and Content, Section Header, Two Content, Comparison, Title Only,
Blank and Content with Caption, all in one slide master called `"PHW"`.
These include every layout pandoc uses, so all slides from Quarto or R
Markdown take the PHW style. Use it with any tool that takes a
PowerPoint template. Examples are
`officer::read_pptx(phw_reference_pptx())` or `reference-doc:` in
Quarto.

## Usage

``` r
phw_reference_pptx(file = tempfile(fileext = ".pptx"))
```

## Arguments

- file:

  Where to write the template.

## Value

A file path.

## Examples

``` r
f <- phw_reference_pptx()
file.exists(f)
#> [1] TRUE
```
