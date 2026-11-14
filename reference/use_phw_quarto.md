# Add the PHW Quarto extension to a project

Copies the `phw` Quarto extension into `_extensions/phw` inside `path`.
This is the same as running `quarto add`, but it works offline. You can
also write a starter document.

## Usage

``` r
use_phw_quarto(
  path = ".",
  template = c("report", "slides", "dashboard", "none"),
  overwrite = FALSE
)
```

## Arguments

- path:

  Project folder.

- template:

  Also write a starter document: `"report"`, `"slides"`, `"dashboard"`,
  or `"none"`.

- overwrite:

  Replace an existing extension or template?

## Value

The extension path, invisibly.

## Details

The extension provides these formats:

|                 |                                                           |
|-----------------|-----------------------------------------------------------|
| Format          | Output                                                    |
| `phw-html`      | Web report with the gradient header band and logo         |
| `phw-docx`      | Word report built from the PHW reference document         |
| `phw-pptx`      | PowerPoint slides built from the PHW template             |
| `phw-typst`     | PDF via Typst (fast, no LaTeX needed) with cover and band |
| `phw-pdf`       | PDF via XeLaTeX with cover and band                       |
| `phw-revealjs`  | 16:9 slides with gradient title slide, logo and footer    |
| `phw-dashboard` | Quarto dashboard with gradient navbar and PHW cards       |

Use them in the document's YAML:

    format:
      phw-html: default
      phw-docx: default
      phw-typst: default

Typst options: `phw-team: "Communicable Disease Surveillance Centre"`
adds a team line to the cover, and `phw-no-cover: true` drops the cover.
`phw-org`, `phw-page-label` and `phw-of-label` change the footer wording
("Public Health Wales", "Page", "of").

The extension styles the document. The charts and tables your R code
makes are styled by phwstyle itself, so call
[`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md)
(and
[`use_phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_flextable.md)
for flextable) once in the setup chunk, as the starter documents do.

**Accessible colours.** Add `phw-palette: accessible` to the document's
YAML header and every chart, table and widget made with phwstyle uses
the colour-blind safe palette:

    title: "Report title"
    phw-palette: accessible
    format: phw-docx

To make both versions from one unchanged document, set the environment
variable `PHWSTYLE_PALETTE` for the second render instead:

    quarto render report.qmd --to phw-docx
    PHWSTYLE_PALETTE=accessible quarto render report.qmd --to phw-docx -o report-accessible.docx

In PowerShell, set it first with `$env:PHWSTYLE_PALETTE = "accessible"`
(and clear it afterwards with `Remove-Item Env:PHWSTYLE_PALETTE`). From
R, use `Sys.setenv(PHWSTYLE_PALETTE = "accessible")` before rendering
and `Sys.unsetenv("PHWSTYLE_PALETTE")` after. The key has to be in the
document itself: Quarto doesn't pass `-M` values or `_quarto.yml`
settings on to R. See
[`phw_default_palette()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_default_palette.md).

## Examples

``` r
project <- file.path(tempdir(), "phw-quarto-example")
use_phw_quarto(project, template = "report")
#> ✔ Added the PHW Quarto extension to
#>   /tmp/RtmpYgLnk6/phw-quarto-example/_extensions/phw.
#> ℹ No PHW logo found, so outputs won't show one. See `phw_download_logos()`.
#> ✔ Wrote /tmp/RtmpYgLnk6/phw-quarto-example/report.qmd.
list.files(project)
#> [1] "_extensions" "report.qmd" 
# Then render report.qmd with Quarto, e.g. the Render button in RStudio.
unlink(project, recursive = TRUE)
```
