# Write the PHW LaTeX header to a file

Fills in the font, logo and image paths in the bundled LaTeX header.
[`phw_pdf_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md)
calls this for you. Use it directly to brand other LaTeX-based formats,
e.g. `includes: in_header:` in bookdown.

## Usage

``` r
phw_latex_header(file = tempfile(fileext = ".tex"), team = NULL, cover = TRUE)
```

## Arguments

- file:

  Where to write the header.

- team:

  Optional team line for the cover.

- cover:

  Keep the full-page cover?

## Value

The file path.

## Examples

``` r
f <- phw_latex_header(team = "Team name")
head(readLines(f))
#> [1] "% ---------------------------------------------------------------------------"
#> [2] "% Public Health Wales LaTeX styling (used by phw_pdf_document() and the"      
#> [3] "% Quarto phw-pdf format). Placeholders in %%...%% are filled in by R."        
#> [4] "% ---------------------------------------------------------------------------"
#> [5] "\\usepackage{xcolor}"                                                         
#> [6] "\\definecolor{phwnavy}{HTML}{285087}"                                         
```
