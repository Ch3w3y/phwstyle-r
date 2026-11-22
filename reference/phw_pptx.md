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
  table_fit = TRUE,
  continued = NULL
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

  Slide title, a single string.

- plot:

  A ggplot, or a grob or gtable such as a
  [`phw_finalise()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_finalise.md)
  result. A grob goes on the slide as a picture.

- table:

  A data frame, flextable or summary table (rendered with
  [`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md)).
  A table with no rows, such as one a filter left empty, goes on one
  slide with its header row. A flextable's caption, such as the one
  [`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md)
  adds, goes in a row at the top of the table, because PowerPoint does
  not show table captions. Text in the table is never smaller than 12
  pt, so it can be read when projected. A table too long for the slide
  tightens its row spacing, and if it still does not fit, its rows
  continue on further slides with the same title. Each of them repeats
  the table's header row and marks its caption, or the title if the
  table has none, with `continued`. Any other content goes on the first
  of them, and the source on the last.

- text:

  Character vector of bullet points. On a title slide or section header
  it is plain lines in the template's own colour and size.

- source, date:

  Passed to
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  and shown at the bottom, in white on a dark slide background and in
  the PHW text colour otherwise.

- layout, master:

  Slide layout and slide master names in the template. A slide master is
  the set of layouts a template provides; see them in PowerPoint under
  View \> Slide Master, or with `officer::layout_summary(x)`. The
  default `master = NULL` uses the master in the deck that has the
  layout (the first one, if several do), so you only need `master` when
  two masters share a layout name.

  Give one of `plot`, `table` or `text` for each content area. The PHW
  template has these layouts:

  - `"Title and Content"` (the default): one chart, table or text.

  - `"Two Content"`: two side by side. With one, it goes on the left.
    With two, the first of `plot`, `table` and `text` goes on the left.

  - `"Comparison"`: two side by side, under a heading on each side. The
    headings stay empty for you to fill in.

  - `"Content with Caption"`: one chart, table or text on the right,
    with a narrow text box on the left that stays empty for you to fill
    in.

  - `"Title Only"`: one chart, table or text in the space below the
    title.

  - `"Blank"`: one chart, table or text filling the slide. It has no
    title.

  - `"Title Slide"` and `"Section Header"`: a title and `text` on navy.
    They have no room for a chart or table.

  With your own template, give the layout names it uses.

- editable:

  Add charts as editable vector graphics (needs rvg)?

- title_size:

  Title font size. On a title slide or section header the template sets
  the size and colour, and this applies only when you give it.

- caption_args:

  List of other
  [`phw_caption()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_caption.md)
  arguments.

- alt:

  Alternative text for the chart or table on the slide, read out by
  screen readers. `NULL` adds none, except that a ggplot's own
  `labs(alt = )` text is used when there is one. On a slide with two
  contents, it goes on the first.

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
  it. A grob keeps the sizes it was drawn with.

- table_fit:

  Enlarge a table built here from a data frame or summary table, or made
  with
  [`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md),
  so it fills the slide's content area? Its text grows from 12 pt up to
  18 pt, as far as the area has room, and its columns widen with it. A
  narrow table is then widened by at most another 80% (more for a table
  with more columns), never past the area. A table that continues on
  further slides grows only as far as it can without taking more slides,
  and shows the same size on each. `FALSE` keeps the text at 12 pt. A
  flextable you made with
  [`flextable::flextable()`](https://davidgohel.github.io/flextable/reference/flextable.html)
  is never enlarged. Either way, a table too wide for the area wraps its
  headings, then its cells, and one still too wide gives a warning. The
  text never shrinks below 12 pt.

- continued:

  Text added after the caption, or after the title if the table has no
  caption, on the slides a long table continues on. `NULL` uses the
  `continued` text of a
  [`phw_flextable()`](https://ch3w3y.github.io/phwstyle-r/reference/phw_flextable.md),
  or `"(continued)"`. Give your own wording, for example in Welsh.

## Value

An officer `rpptx` object. Save it with
`print(deck, target = "file.pptx")`.

## Details

Every argument is checked before the slide is added, so a call that
stops leaves the deck as it was.

## Examples

``` r
if (requireNamespace("officer", quietly = TRUE)) {
  deck <- phw_pptx()
  deck <- phw_add_slide(deck, "Key messages",
                        text = c("Point one", "Point two"))
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
    deck <- phw_add_slide(deck, "A chart", plot = p, source = "mtcars", editable = FALSE)
    deck <- phw_add_slide(deck, "A chart and its data", plot = p,
                          table = head(mtcars[, c("wt", "mpg")]),
                          layout = "Two Content", editable = FALSE)
  }
  print(deck, target = tempfile(fileext = ".pptx"))
}
```
