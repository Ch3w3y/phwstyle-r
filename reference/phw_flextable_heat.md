# Colour flextable cells by value

Fills cells in the given columns with a PHW sequential palette, the way
PHW heat tables do, and picks white or dark text automatically so values
stay readable.

## Usage

``` r
phw_flextable_heat(
  x,
  j,
  palette = "teals",
  domain = NULL,
  breaks = NULL,
  higher_is_better = TRUE,
  symbols = TRUE
)
```

## Arguments

- x:

  A flextable.

- j:

  Columns to colour, chosen as in
  [`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html):
  unquoted names such as `c(rate, cases)`, positions such as `2:5`, or
  strings.

- palette:

  A sequential or diverging palette name, a vector of colours, `"rag"`
  or `"rag_accessible"` (navy instead of green).

- domain:

  Range of values the palette spans. Defaults to the range of the
  selected columns.

- breaks:

  For `palette = "rag"`: two cut points (red below the first, green at
  or above the second).

- higher_is_better:

  For `"rag"`: is a high value good (green)?

- symbols:

  For `"rag"`: add a shape before each value (a down triangle for red, a
  square for amber, an up triangle for green)?

## Value

A flextable.

## Details

For `palette = "rag"`, colour alone doesn't work for colour-blind
readers or in black-and-white print, so `symbols = TRUE` (the default)
adds a shape before each value as well.

## Examples

``` r
if (requireNamespace("flextable", quietly = TRUE)) {
  rates <- data.frame(Area = paste("Area", LETTERS[1:4]),
                      `2024` = c(3.2, 1.5, 3.8, 2.3), `2025` = c(4.4, 0.7, 4.2, 0.2),
                      check.names = FALSE)
  phw_flextable(rates) |>
    phw_flextable_heat(j = 2:3)

  # Red, amber and green, with a shape in each cell as a second cue
  uptake <- data.frame(Area = paste("Area", LETTERS[1:4]),
                       Uptake = c(0.96, 0.93, 0.91, 0.95))
  phw_flextable(uptake, digits = 2) |>
    phw_flextable_heat(Uptake, palette = "rag_accessible", breaks = c(0.92, 0.95))
}


.cl-d8bad469{}.cl-2083cb38{font-family:'Ubuntu';font-size:10pt;font-weight:bold;font-style:normal;text-decoration:none;color:rgba(40, 80, 135, 1.00);background-color:transparent;}.cl-cfb12614{font-family:'Ubuntu';font-size:10pt;font-weight:normal;font-style:normal;text-decoration:none;color:rgba(33, 43, 50, 1.00);background-color:transparent;}.cl-b6eb2270{font-family:'Ubuntu';font-size:10pt;font-weight:normal;font-style:normal;text-decoration:none;color:rgba(255, 255, 255, 1.00);background-color:transparent;}.cl-56907d49{margin:0;text-align:left;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:5pt;padding-right:5pt;line-height: 1;background-color:transparent;}.cl-f3e8aa49{margin:0;text-align:right;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);padding-bottom:3pt;padding-top:3pt;padding-left:5pt;padding-right:5pt;line-height: 1;background-color:transparent;}.cl-8c351af6{width:0.712in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-4287fc46{width:0.767in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 1.5pt solid rgba(40, 80, 135, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-44f27f41{width:0.712in;background-color:transparent;vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-411efafd{width:0.767in;background-color:rgba(40, 80, 135, 1.00);vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-20fb6d35{width:0.767in;background-color:rgba(217, 127, 0, 1.00);vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-188a360d{width:0.767in;background-color:rgba(213, 11, 92, 1.00);vertical-align: middle;border-bottom: 0 solid rgba(0, 0, 0, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-310c0b57{width:0.712in;background-color:transparent;vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}.cl-0ab63a1c{width:0.767in;background-color:rgba(40, 80, 135, 1.00);vertical-align: middle;border-bottom: 1.5pt solid rgba(40, 80, 135, 1.00);border-top: 0 solid rgba(0, 0, 0, 1.00);border-left: 0 solid rgba(0, 0, 0, 1.00);border-right: 0 solid rgba(0, 0, 0, 1.00);margin-bottom:0;margin-top:0;margin-left:0;margin-right:0;}


Area
```
