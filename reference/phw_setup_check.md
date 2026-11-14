# Check what phwstyle needs on this computer

phwstyle works straight after installation, but some outputs need extra
packages or tools. R can't ask questions while installing a package, so
run this once afterwards. It lists what is ready, what is missing, and
the command that fixes each item:

## Usage

``` r
phw_setup_check(install = interactive())
```

## Arguments

- install:

  In an interactive session, offer to install missing R packages and the
  font?

## Value

A data frame of checks, invisibly.

## Details

- the Ubuntu font, for Word, LaTeX and base R devices on your computer
  (charts made with 'ragg', HTML and Office tables already use the
  bundled copy)

- the logo

- optional R packages for each type of output

- external tools: Pandoc (R Markdown), Quarto, and XeLaTeX (PDF via
  LaTeX; Typst PDFs don't need it)

Functions that need an optional package also offer to install it the
first time you use them.

## Examples

``` r
phw_setup_check(install = FALSE)
#> 
#> ── phwstyle setup ──
#> 
#> ✖ Ubuntu font installed on this computer: run `phw_install_fonts()`
#> ✖ PHW logo available: run `phw_download_logos() or options(phwstyle.logo_dir =
#>   ...)`
#> ✔ PNG charts in the bundled font (knitr, phw_save)
#> ✔ Word and PowerPoint tables and slides
#> ✔ gt and gtsummary tables
#> ✔ Interactive tables
#> ✔ Interactive charts and maps
#> ✔ Maps and boundaries
#> ✔ Excel workbooks
#> ✔ Shiny apps and HTML themes
#> ✔ R Markdown documents
#> ✔ Multi-plot figures
#> ✔ Logos on charts and slides
#> ✔ Pandoc (R Markdown)
#> ✔ Quarto
#> ✖ XeLaTeX (PDF via LaTeX): run `tinytex::install_tinytex(), or use the
#>   phw-typst format instead`
```
