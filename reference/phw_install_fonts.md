# Install the Ubuntu font for your user account

Copies the bundled Ubuntu font files into your personal font folder so
every program can use them. That includes Word, PowerPoint, LaTeX and
the base R [`pdf()`](https://rdrr.io/r/grDevices/pdf.html) device. You
only need to do this once per computer.

## Usage

``` r
phw_install_fonts(dest = NULL, ask = interactive())
```

## Arguments

- dest:

  Folder to copy the fonts to. Defaults to the usual per-user font
  folder for your operating system, which is only used in an interactive
  session.

- ask:

  Ask for confirmation before copying? Defaults to `TRUE` in interactive
  sessions.

## Value

The destination folder, invisibly, or `NULL` if cancelled.

## Details

On a managed NHS Wales laptop where you can't install fonts, skip this.
The package will still use Ubuntu through 'ragg' and in HTML, and it
falls back to Arial elsewhere.

## Examples

``` r
# Run once per computer. It asks before copying anything.
if (interactive()) phw_install_fonts()
```
