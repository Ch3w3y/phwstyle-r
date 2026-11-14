# Apply PHW styling to a flextable

Styles an existing flextable the way PHW and its Communicable Disease
Surveillance Centre (CDSC) present tables in reports. Four styles are
available:

## Usage

``` r
phw_flextable_theme(
  x,
  style = c("booktabs", "header", "light", "zebra"),
  font_size = 10,
  font_family = phw_font(),
  bold_first_col = FALSE,
  total_row = FALSE,
  accent = phw_colours[["navy"]],
  header_bg = NULL,
  header_colour = NULL,
  text_colour = phw_colours[["text"]],
  stripe_colour = phw_colours[["grey_bg"]],
  padding = c(3, 5),
  align = TRUE
)
```

## Arguments

- x:

  A flextable.

- style:

  `"booktabs"`, `"header"`, `"light"` or `"zebra"`.

- font_size:

  Body font size in points. Header uses the same size.

- font_family:

  Font family.

- bold_first_col:

  Bold the first column? (Area names in many PHW tables.)

- total_row:

  Treat the last row as a total row (bold with a rule above)?

- accent:

  Colour of the rules and header (navy by default).

- header_bg, header_colour:

  Override the header fill and text colour.

- text_colour:

  Body text colour.

- stripe_colour:

  Fill for alternate rows in `"zebra"`.

- padding:

  Cell padding in points: one number, or `c(top_bottom, left_right)`, or
  `NULL` to keep the existing padding (for tables that use padding for
  indents, such as gtsummary output).

- align:

  Align numbers right and text left automatically? Set to `FALSE` to
  keep your own alignment.

## Value

A flextable.

## Details

- `"booktabs"` (default): horizontal rules only, as in printed journal
  tables: a navy rule above and below the header and along the bottom, a
  bold header, no vertical lines and no fill.

- `"header"`: a navy header band with white bold text.

- `"light"`: a light-teal header band with dark text (as in the weekly
  acute respiratory infection report).

- `"zebra"`: `"booktabs"` plus light grey banding on alternate rows.

Numbers are right-aligned and text is left-aligned. In every style the
font is Ubuntu (or the
[`phw_font()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_font.md)
fallback).

## Examples

``` r
if (requireNamespace("flextable", quietly = TRUE)) {
  ft <- flextable::flextable(head(airquality))
  phw_flextable_theme(ft)
}


.cl-d8bad469{}.cl-2083cb38{font-family:'Ubuntu';font-size:10pt;font-weight:bold;font-style:normal;text-decoration:none;color:rgba(40, 80, 135, 1.00);background-color:transparent;}.cl-cfb12614{font-family:'Ubuntu';font-size:10pt;font-weight:normal;font-style:normal;text-decoration:none;color:rgba(33, 43, 50, 1.00);background-color:transparent;}.cl-f3e8aa49{margin:0;text-align:right;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:5pt;padding-right:5pt;line-height: 1;background-color:transparent;}.cl-9bf0c983{width:0.75in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-a18b2e34{width:0.75in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-384fc9ce{width:0.75in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}


Ozone
```
