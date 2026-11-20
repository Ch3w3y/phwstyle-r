# Installation and setup

This guide gets phwstyle installed and ready on your computer. It covers
the install routes, what to do when an install fails, a check of what is
ready, the Ubuntu font, the Public Health Wales logo and the package
options. Once it is done, [Getting
started](https://ch3w3y.github.io/phwstyle-r/articles/phwstyle.md) shows
what to make first.

phwstyle needs R 4.3 or later and ggplot2 3.5 or later. The Quarto
formats need Quarto 1.5 or later.

## Install phwstyle

phwstyle is not on CRAN yet, so install it from GitHub:

``` r

install.packages("remotes")
remotes::install_github("Ch3w3y/phwstyle-r", dependencies = TRUE)
```

`dependencies = TRUE` also installs the optional packages for every
output type (flextable, reactable, plotly, bslib, ragg and others).
Leave it out for a smaller install. Functions that need an optional
package offer to install it the first time you use them.

### Faster installs with Posit Package Manager

Posit Package Manager (P3M) has ready-built copies of the packages
phwstyle uses, so nothing needs compiling. Point R at it before
installing. On Linux, use the address for your distribution from the
[P3M setup
page](https://packagemanager.posit.co/client/#/repos/cran/setup).

``` r

options(repos = c(CRAN = "https://packagemanager.posit.co/cran/latest"))
remotes::install_github("Ch3w3y/phwstyle-r", dependencies = TRUE)
```

### With uvr

In a [uvr](https://nbafrank.github.io/uvr/) project, add the package
from GitHub:

``` sh
uvr add Ch3w3y/phwstyle-r@main
```

### From the release file

If GitHub can’t be reached from your computer, install the built package
from the [releases page](https://github.com/Ch3w3y/phwstyle-r/releases).
Change the version in the address to the latest release.

``` r

install.packages(c("cli", "ggplot2", "gtable", "htmltools", "rlang",
                   "scales", "systemfonts", "tidyselect", "zip"))
install.packages(
  "https://github.com/Ch3w3y/phwstyle-r/releases/download/v0.3.0/phwstyle_0.3.0.tar.gz",
  repos = NULL, type = "source")
```

Once phwstyle is on CRAN,
`install.packages("phwstyle", dependencies = TRUE)` will work too.

## If the install fails on a managed computer

The last line of the error names a file in your Temp folder, such as
`installation of package 'C:/Users/.../Temp/.../phwstyle_0.3.0.tar.gz' had non-zero exit status`.
That is only where R unpacked the download. The cause is a few lines
further up. Find it in this list.

**`LoadLibrary failure: This program is blocked by group policy`**
(Windows). Your organisation only lets code run from approved folders,
and the folder R installs packages into is not one of them. Nothing is
wrong with phwstyle, because any package with compiled code fails the
same way. Try [`library(rlang)`](https://rlang.r-lib.org) to see. Moving
the temporary folder or installing from the release file does not help.
Ask IT which folder is approved for R packages, or to approve your R
library, which `.libPaths()[1]` shows. If they give you a folder, add it
to your `.Renviron` file and restart R.
[`usethis::edit_r_environ()`](https://usethis.r-lib.org/reference/edit.html)
opens the file.

    R_LIBS_USER=C:/the/approved/folder

**“Do you want to install from sources the package which needs
compilation?”** Answer no. R then uses the ready-built version, which is
what you want unless Rtools is installed.

**`'configure' exists but is not executable`** (Linux servers). The
packages phwstyle depends on compile from source by default, and the
temporary folder does not allow programs to run. Install the
dependencies from Posit Package Manager, as above, which avoids
compiling. Or give R a temporary folder you control by adding
`TMPDIR=/home/your.name/tmp` to `.Renviron`. Create the folder first.

**GitHub cannot be reached.** Use the release file above.

A policy that only blocks programs in the Temp folder doesn’t stop
phwstyle installing, and neither does an accented letter in your user
name.

## Check your setup

Run the check once after installing. It lists what is ready and what is
missing, with the command that fixes each item.

``` r

library(phwstyle)
phw_setup_check(install = FALSE)
```

It checks the Ubuntu font on your computer, the logo, the optional R
packages for each type of output, Pandoc, Quarto and XeLaTeX, and marks
each one ready or missing. In an interactive session,
[`phw_setup_check()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_setup_check.md)
with no arguments also offers to install the missing R packages and the
font. The function returns the checks as a data frame, invisibly.

If you skip the check, phwstyle reminds you when it loads and something
is missing. Set `options(phwstyle.quiet = TRUE)` to hide the reminder.

## Fonts

phwstyle uses the Ubuntu typeface, which ships with the package.
[`phw_font()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_font.md)
returns the family name that phwstyle will use. It falls back to Arial
and then to `"sans"` when Ubuntu can’t be used.

``` r

phw_font()
#> [1] "Ubuntu"
```

Most outputs need nothing from you. phwstyle registers the bundled font
with systemfonts when the package loads, so ragg, svglite and the Word
and PowerPoint outputs in officer and flextable can find it. That is
[`phw_register_fonts()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_register_fonts.md),
which you can also call yourself. It returns `TRUE` invisibly when the
fonts are registered.

``` r

phw_register_fonts()
```

HTML outputs and the phwstyle PDF formats carry the font with them.

Run
[`phw_install_fonts()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_install_fonts.md)
once per computer when you open phwstyle’s output in Word or PowerPoint
on your own computer, draw with base R devices such as
[`pdf()`](https://rdrr.io/r/grDevices/pdf.html), or build LaTeX
documents outside the phwstyle formats. It copies the font files into
your personal font folder and asks first.

``` r

phw_install_fonts()
```

If you build HTML by hand, attach
[`phw_font_dependency()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_font_dependency.md)
so the font works on computers that don’t have it. The font files are
bundled, so nothing is fetched from the internet.

``` r

phw_font_dependency()$name
#> [1] "phw-ubuntu-font"
```

For example, `htmltools::tagList(phw_font_dependency(), your_html)`
attaches it to a piece of HTML.

To use another family everywhere, set
`options(phwstyle.font = "Arial")`.

## Logos

The Public Health Wales logo is a trade mark and is not included in the
package. Without a logo, every output is still styled and shows the
organisation name instead.
[`phw_has_logo()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_has_logo.md)
tells you whether phwstyle can find one.

``` r

phw_has_logo()
#> [1] FALSE
```

There are two ways to provide the logo:

- Run
  [`phw_download_logos()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_download_logos.md)
  once per computer. It downloads the bilingual logo from phw.nhs.wales,
  makes blue, white and black versions in SVG and PNG, and stores them
  in your user cache folder. It asks before it downloads.
- Set `options(phwstyle.logo_dir = "path/to/folder")` to a folder with
  your own copies of the files.

``` r

phw_download_logos()
```

[`phw_logo()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_logo.md)
returns the path of one version, or `NULL` when no logo is available.
Choose the `"blue"` version for white backgrounds, `"white"` for the
gradient band or any dark background, and `"black"` for mono print. Pass
`format = "svg"` for the vector file.

``` r

phw_logo("white", format = "svg")
#> NULL
```

[`phw_graphic()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_graphic.md)
returns the path of a graphic phwstyle draws itself, which contains no
logo. The `"band"` is the header gradient, `"cover"` is the A4 portrait
cover background and `"cover_wide"` is the 16:9 slide background.

``` r

basename(phw_graphic("band"))
#> [1] "band.png"
```

The examples in these guides run without the logo. See `inst/COPYRIGHTS`
in the package for the licences of the bundled files.

## Package options

Set an option once, for example in your `.Rprofile` or at the top of a
script. Each one has a default that works without you doing anything.

| Option | What it does | More in |
|----|----|----|
| `phwstyle.palette` | The default palette name, such as `"accessible"`, used by every chart, table and widget. | [Colours](https://ch3w3y.github.io/phwstyle-r/articles/colours.html#colour-blind-safe-colours) |
| `PHWSTYLE_PALETTE` (environment variable) | The same switch for one render, such as `PHWSTYLE_PALETTE=accessible quarto render report.qmd`. | [Reports, slides and dashboards](https://ch3w3y.github.io/phwstyle-r/articles/documents.html#default-and-accessible-colours) |
| `phwstyle.font` | The font family to use instead of Ubuntu. | [Fonts](#fonts) |
| `phwstyle.logo_dir` | The folder with your own logo files. | [Logos](#logos) |
| `phwstyle.key_file` | The CSV file that colour keys are read from and saved to, so colours stay the same across sessions. [`phw_key_file()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_key.md) sets it for you. | [Colours](https://ch3w3y.github.io/phwstyle-r/articles/colours.html#colours-that-stay-with-their-groups) |
| `phwstyle.boundary_dir` | The folder where downloaded boundaries are cached. | [Maps](https://ch3w3y.github.io/phwstyle-r/articles/maps.html#keeping-boundaries-up-to-date) |
| `phwstyle.boundary_update` | `FALSE` stops [`phw_boundaries()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_boundaries.md) checking each week for a newer list of boundary releases. | [Maps](https://ch3w3y.github.io/phwstyle-r/articles/maps.html#keeping-boundaries-up-to-date) |
| `phwstyle.boundary_list_url` | The address of that list. Point it at your own copy of `boundaries.csv` if your network blocks GitHub. | [Maps](https://ch3w3y.github.io/phwstyle-r/articles/maps.html#keeping-boundaries-up-to-date) |
| `phwstyle.quiet` | `TRUE` hides the reminder that appears when the package loads. | [Check your setup](#check-your-setup) |

For example:

``` r

options(
  phwstyle.palette = "accessible",
  phwstyle.key_file = "phw-colours.csv",
  phwstyle.quiet = TRUE
)
```
