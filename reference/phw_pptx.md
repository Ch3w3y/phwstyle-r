# PowerPoint slides with officer

`phw_pptx()` starts a PowerPoint deck, from the PHW template (16:9,
Ubuntu text, navy titles) or from your own. `phw_add_slide()` adds a
slide with a PHW-styled title and a chart, table or text, so a set of
results becomes a deck in a few lines. Charts are added as editable
vector graphics when the rvg package is installed, so colleagues can
tweak them in PowerPoint.

## Usage

``` r
phw_pptx(template = NULL)

phw_add_slide(
  x,
  title = NULL,
  plot = NULL,
  table = NULL,
  text = NULL,
  source = NULL,
  date = NULL,
  layout = "Title and Content",
  master = NULL,
  editable = TRUE,
  title_size = 28,
  caption_args = list(),
  alt = NULL,
  plot_scale = 1.5,
  table_fit = TRUE
)
```

## Arguments

- template:

  Path to a `.pptx` template, e.g. the PHW corporate template. `NULL`
  uses the PHW template from
  [`phw_reference_pptx()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_reference_pptx.md).

- x:

  An `rpptx` object from `phw_pptx()`.

- title:

  Slide title.

- plot:

  A ggplot (or anything
  [`officer::ph_with()`](https://davidgohel.github.io/officer/reference/ph_with.html)
  accepts as a graphic).

- table:

  A data frame, flextable or summary table (rendered with
  [`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md)).

- text:

  Character vector of bullet points.

- source, date:

  Passed to
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  and shown at the bottom.

- layout, master:

  Slide layout and slide master names in the template. A slide master is
  the set of layouts a template provides; see them in PowerPoint under
  View \> Slide Master, or with `officer::layout_summary(x)`. The
  default layout suits the PHW template, which also has `"Title Slide"`
  (the title and `text` as a subtitle), `"Section Header"`,
  `"Two Content"`, `"Title Only"` and `"Blank"`. With your own template,
  give the layout names it uses. The default `master = NULL` uses the
  master in the deck that has the layout (the first one, if several do),
  so you only need `master` when two masters share a layout name.

- editable:

  Add charts as editable vector graphics (needs rvg)?

- title_size:

  Title font size. On a layout with a dark background (the title slide
  and section header) the template sets the size and colour, and this
  applies only when you give it.

- caption_args:

  List of other
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  arguments.

- alt:

  Alternative text for the chart or table on the slide, read out by
  screen readers. `NULL` adds none, except that a ggplot's own
  `labs(alt = )` text is used when there is one.

- plot_scale:

  How much to enlarge a chart's text on the slide, as a multiple of the
  size the chart already uses. The default `1.5` brings axis and legend
  text to about 14 points, which reads from the back of a room. `1`
  leaves the chart as it is. It scales the text and legend keys that
  follow the plot's base size, as
  [`theme_phw()`](https://ch3w3y.github.io/phwstyle-r/reference/theme_phw.md)
  and the ggplot2 themes do, and the size of text drawn by
  [`geom_text()`](https://ggplot2.tidyverse.org/reference/geom_text.html)
  with ggplot2 4.0.0 or later. Text you gave an exact size in your own
  [`theme()`](https://ggplot2.tidyverse.org/reference/theme.html) keeps
  it.

- table_fit:

  Enlarge a table built here from a data frame or summary table so it
  fills the width of the slide's content area? The text grows with it,
  by up to 1.6 times, and a narrow table is widened by at most another
  80% (more for a table with more columns). A tall table tightens its
  row spacing so the text can grow. `FALSE` keeps the table at the size
  [`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md)
  gives it. A flextable you pass in is never resized.

## Value

An officer `rpptx` object. Save it with
`print(deck, target = "file.pptx")`.

## Examples

``` r
if (requireNamespace("officer", quietly = TRUE)) {
  deck <- phw_pptx()
  deck <- phw_add_slide(deck, "Key messages",
                        text = c("Point one", "Point two"))
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
    deck <- phw_add_slide(deck, "A chart", plot = p, source = "mtcars", editable = FALSE)
  }
  print(deck, target = tempfile(fileext = ".pptx"))
}
```
