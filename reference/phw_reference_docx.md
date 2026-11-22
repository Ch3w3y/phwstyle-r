# Path to the PHW Word reference document

The Word template behind
[`phw_word_document()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_formats.md)
and the Quarto `phw-docx` format. It sets Ubuntu, navy headings,
booktabs tables, a gradient header band (with the logo when one is
available) and a "Page x of y" footer. Use it with any tool that takes a
Word template. Examples are `officer::read_docx(phw_reference_docx())`
or `reference-doc:` in Quarto.

## Usage

``` r
phw_reference_docx(file = tempfile(fileext = ".docx"))
```

## Arguments

- file:

  Where to write the document.

## Value

A file path.

## Examples

``` r
f <- phw_reference_docx()
file.exists(f)
#> [1] TRUE
# In Quarto:   format: docx: reference-doc: path/to/that/file.docx
# In officer:  officer::read_docx(phw_reference_docx())
```
