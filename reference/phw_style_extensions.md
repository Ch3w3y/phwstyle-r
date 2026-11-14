# Style geoms from ggplot2 extension packages

Extension packages such as ggrepel, ggridges, ggalluvial, ggsankey,
treemapify and ggtext define their own geoms with their own defaults
(black text in the default font, grey fills, black outlines). Colour and
fill *scales* from phwstyle already work with them, including colour
keys. This function also brings their *defaults* into line with the PHW
style:

## Usage

``` r
phw_style_extensions(packages = NULL)
```

## Arguments

- packages:

  Package names to style. Defaults to every loaded package except
  ggplot2.

## Value

The names of the geoms that were changed, invisibly.

## Details

- text geoms use the PHW font
  ([`phw_font()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_font.md))
  and text colour

- unmapped grey fills become navy

- black outlines on filled shapes become white, as in PHW charts

- a few known geoms get tailored defaults: white text on treemap tiles,
  white tile borders, and light grey strata with grey borders in
  alluvial plots

It works on any package, not a fixed list: it looks through every loaded
package for geoms. Defaults that already follow the ggplot2 theme
(ggplot2 4.0 and later) are left alone.
[`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md)
calls it for you, so load extension packages *before* calling
[`use_phw_ggplot()`](https://ch3w3y.github.io/phwstyle-r/reference/use_phw_ggplot.md),
or call `phw_style_extensions()` again after loading one.

## Examples

``` r
phw_style_extensions()
```
