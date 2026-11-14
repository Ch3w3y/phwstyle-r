# Column formats for reactable

Ready-made
[`reactable::colDef()`](https://glin.github.io/reactable/reference/colDef.html)s
for common PHW table columns. Pass them in `columns = list(...)` of
[`phw_reactable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reactable.md)
or
[`reactable::reactable()`](https://glin.github.io/reactable/reference/reactable.html).

## Usage

``` r
phw_col_bar(
  data,
  column,
  colour = phw_colours[["light_teal"]],
  digits = 0,
  ...
)

phw_col_heat(data, column, palette = "teals", domain = NULL, digits = 1, ...)

phw_col_rag(
  breaks,
  higher_is_better = TRUE,
  rag_palette = "rag_accessible",
  digits = 1,
  ...
)

phw_col_number(digits = 0, ...)

phw_col_percent(digits = 1, ...)
```

## Arguments

- data:

  The data frame (bar and heat columns need it to find the range).

- column:

  The column, unquoted as in dplyr. A string works too.

- colour:

  Bar colour.

- digits:

  Decimal places.

- ...:

  Other
  [`reactable::colDef()`](https://glin.github.io/reactable/reference/colDef.html)
  arguments, e.g. `name`.

- palette:

  Palette name or vector of colours.

- domain:

  Range for the heat colours. Defaults to the column range.

- breaks, higher_is_better:

  See
  [`phw_flextable_heat()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable_heat.md).

- rag_palette:

  `"rag"` or `"rag_accessible"`.

## Value

A
[`reactable::colDef()`](https://glin.github.io/reactable/reference/colDef.html).

## Details

- `phw_col_bar()`: the value with a horizontal bar behind it, scaled to
  the column's largest value. Good for counts and rates.

- `phw_col_heat()`: cell background from a sequential or diverging
  palette, with readable text.

- `phw_col_rag()`: red, amber or green cells with a shape, so status
  doesn't rely on colour alone.

- `phw_col_number()` and `phw_col_percent()`: thousands separators and
  fixed decimals.

## Examples

``` r
if (requireNamespace("reactable", quietly = TRUE)) {
  df <- data.frame(area = paste("Area", LETTERS[1:5]), cases = c(120, 85, 64, 19, 23),
                   rate = c(4.1, 2.2, 6.3, 1.0, 2.5), share = c(.38, .27, .2, .06, .07))
  phw_reactable(df, columns = list(
    cases = phw_col_bar(df, cases, name = "Cases"),
    rate = phw_col_heat(df, rate, name = "Rate"),
    share = phw_col_percent(name = "Share")
  ))
}

{"x":{"tag":{"name":"Reactable","attribs":{"data":{"area":["Area A","Area B","Area C","Area D","Area E"],"cases":[120,85,64,19,23],"rate":[4.1,2.2,6.3,1,2.5],"share":[0.38,0.27,0.2,0.06,0.07]},"columns":[{"id":"area","name":"area","type":"character","format":{"cell":{"separators":true},"aggregated":{"separators":true}},"headerVAlign":"bottom"},{"id":"cases","name":"Cases","type":"numeric","format":{"cell":{"digits":0,"separators":true},"aggregated":{"digits":0,"separators":true}},"headerVAlign":"bottom","cell":[{"name":"div","attribs":{"style":{"display":"flex","align-items":"center","gap":"6px"}},"children":[{"name":"div","attribs":{"style":{"flex":"1 1 auto","background":"transparent"}},"children":[{"name":"div","attribs":{"style":{"width":"100%","height":"14px","background":"#7CC7D3","border-radius":"2px"}},"children":[]}]},{"name":"span","attribs":{"style":{"min-width":"3.5em","text-align":"right","font-variant-numeric":"tabular-nums"}},"children":["120"]}]},{"name":"div","attribs":{"style":{"display":"flex","align-items":"center","gap":"6px"}},"children":[{"name":"div","attribs":{"style":{"flex":"1 1 auto","background":"transparent"}},"children":[{"name":"div","attribs":{"style":{"width":"70.8%","height":"14px","background":"#7CC7D3","border-radius":"2px"}},"children":[]}]},{"name":"span","attribs":{"style":{"min-width":"3.5em","text-align":"right","font-variant-numeric":"tabular-nums"}},"children":["85"]}]},{"name":"div","attribs":{"style":{"display":"flex","align-items":"center","gap":"6px"}},"children":[{"name":"div","attribs":{"style":{"flex":"1 1 auto","background":"transparent"}},"children":[{"name":"div","attribs":{"style":{"width":"53.3%","height":"14px","background":"#7CC7D3","border-radius":"2px"}},"children":[]}]},{"name":"span","attribs":{"style":{"min-width":"3.5em","text-align":"right","font-variant-numeric":"tabular-nums"}},"children":["64"]}]},{"name":"div","attribs":{"style":{"display":"flex","align-items":"center","gap":"6px"}},"children":[{"name":"div","attribs":{"style":{"flex":"1 1 auto","background":"transparent"}},"children":[{"name":"div","attribs":{"style":{"width":"15.8%","height":"14px","background":"#7CC7D3","border-radius":"2px"}},"children":[]}]},{"name":"span","attribs":{"style":{"min-width":"3.5em","text-align":"right","font-variant-numeric":"tabular-nums"}},"children":["19"]}]},{"name":"div","attribs":{"style":{"display":"flex","align-items":"center","gap":"6px"}},"children":[{"name":"div","attribs":{"style":{"flex":"1 1 auto","background":"transparent"}},"children":[{"name":"div","attribs":{"style":{"width":"19.2%","height":"14px","background":"#7CC7D3","border-radius":"2px"}},"children":[]}]},{"name":"span","attribs":{"style":{"min-width":"3.5em","text-align":"right","font-variant-numeric":"tabular-nums"}},"children":["23"]}]}],"align":"left"},{"id":"rate","name":"Rate","type":"numeric","format":{"cell":{"digits":1,"separators":true},"aggregated":{"digits":1,"separators":true}},"headerVAlign":"bottom","style":[{"background":"#2EA5B7","color":"#212B32"},{"background":"#ABDDE4","color":"#212B32"},{"background":"#285087","color":"#FFFFFF"},{"background":"#E6F5F7","color":"#212B32"},{"background":"#9CD6DF","color":"#212B32"}]},{"id":"share","name":"Share","type":"numeric","format":{"cell":{"digits":1,"percent":true},"aggregated":{"digits":1,"percent":true}},"headerVAlign":"bottom","align":"right"}],"highlight":true,"striped":true,"compact":true,"theme":{"color":"#212B32","backgroundColor":"#FFFFFF","borderColor":"#D8DDE0","stripedColor":"#F0F4F5","highlightColor":"#E8EDF4","cellPadding":"6px 10px","style":{"fontFamily":"Ubuntu, Arial, sans-serif","fontSize":"14px"},"headerStyle":{"color":"#285087","borderTop":"2px solid #285087","borderBottom":"2px solid #285087","fontWeight":700,"fontSize":"14px","&:hover[aria-sort]":{"background":"#F0F4F5","color":"#285087"},"&[aria-sort='ascending'], &[aria-sort='descending']":{"background":"#F0F4F5","color":"#285087"}},"footerStyle":{"fontWeight":700,"borderTop":"2px solid #285087"},"inputStyle":{"&:focus":{"outline":"3px solid #FFEB3B"}},"searchInputStyle":{"borderColor":"#768692","width":"100%","&:focus":{"outline":"3px solid #FFEB3B","borderColor":"#212B32"}},"pageButtonHoverStyle":{"background":"#F0F4F5"},"pageButtonActiveStyle":{"background":"#E8EDF4"},"pageButtonCurrentStyle":{"background":"#285087","color":"#FFFFFF"}},"dataKey":"52622bd12a64c3889dd31b476fcc51ba"},"children":[]},"class":"reactR_markup"},"evals":[],"jsHooks":[]}
```
