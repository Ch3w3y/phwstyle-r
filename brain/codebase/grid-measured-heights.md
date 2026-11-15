# Measured heights in grid layouts

- **gtable drops measured text heights.** `heightDetails.gtable()` is `absolute.size(gtable_height(x))`, and `absolute.size()` turns `grobheight` units into `null`. A gtable whose row height uses `grid::grobHeight(text)` lays out fine itself, but `grobHeight()` of the whole gtable (what gridExtra's `top =` uses) keeps only the fixed parts. `phw_title_grob()` adds the class `phw_title` with a `heightDetails()` method that returns `sum(x$heights)`.
- `strheight` units survive `absolute.size()`, but they are measured in the caller's font, not the text grob's, so they do not help.
- `grobHeight()` of a multi-line text grob is the first line's ascent plus one line spacing per extra line. It leaves out the last line's descent, so leave a gap below it.
- To check a layout height in a test, open `grDevices::pdf(NULL)` and use `grid::convertHeight(..., "pt", valueOnly = TRUE)`.
