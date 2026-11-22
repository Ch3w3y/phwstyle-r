# phwstyle (development version)

This release makes every function check what it is given. Where a call
used to draw a wrong chart, drop content without a word or fail inside
another package, it now does the right thing or stops with a message that
says what to change.

## Changes that may affect existing code

* `phw_add_slide()` and a slide deck made with R Markdown stop with a
  message for a table with bars from `phw_flextable_bars()`. PowerPoint
  tables cannot show pictures, and before, the slide showed the numbers
  without the bars and gave no warning.
* `phw_plotly()` stops with a message for a patchwork, such as a figure
  from `phw_arrange()` or `g1 + g2`, and shows how to combine the charts
  with `phw_plotly(plotly::subplot(g1, g2))`, which gives a group the same
  colour in every panel. Before, it drew only the last chart and dropped
  the others, the figure title and the source without a word.
* The default palette `"main"` now has six colours: navy, teal, orange,
  pink, green and gold. Charts with five or six groups change colour, and
  charts with more than six carry on into `"extended"` after the sixth.
  `"extended"` is now `"main"` followed by wine, mint, bright green, blue,
  dark orange and black. Black comes last, so it no longer appears in a
  chart with five groups, where it read like a total. The three colours
  that were not PHW colours (`#5A82E6`, `#274309`, `#730BB1`) are gone.
  `"accessible"` has the same eight colours, with black and the dark
  rose-brown moved to the end. Gold is below 3:1 contrast on white, so it
  suits bars and areas better than thin lines. A saved colour key keeps the
  colours it already gave its groups.
* Text dates must be ISO dates such as `"2026-11-14"`. `phw_epicurve()`,
  `phw_date()` and the caption `date` stop on text such as `"05/01/2026"`
  instead of misreading it, and show how to convert it. `phw_epicurve()`
  also stops on a numeric date column. A blank text date, as `read.csv()`
  reads an empty cell, counts as a missing date.
* A blank text group, as `read.csv()` reads an empty cell, counts as a
  missing value in `phw_epicurve()`, `phw_pyramid()`, `phw_crosstab()`,
  `phw_group_table()` and `phw_summary_table()`. It shows as "Unknown" (or
  the `missing` label), or is left out with a message when `missing = NULL`.
  Before, it became a group of its own with no name, which stopped
  `phw_epicurve()` when printed and gave tables a made-up column heading.
* Rows with a missing date, count, value, estimate or code are left out with
  one message saying how many. Before, they could turn a whole period into 0
  or blank a chart. `phw_crosstab(missing = NULL)` and
  `phw_group_table(missing = NULL)` now also say how many rows they leave out
  for a missing row or column value. `phw_rate_table()` and
  `phw_risk_table()` handle missing values as before.
* `phw_reactable()` rows are no longer striped by default, to match the
  other tables. Pass `striped = TRUE` to stripe them.
* Tables on PowerPoint slides stay readable when projected. Text in a table
  is never smaller than 12 pt, in a deck made with `phw_add_slide()`, R
  Markdown or the Quarto `phw-pptx` format, so `phw_flextable()`'s 10 pt
  text shows at 12 pt there. A table too long for the slide tightens its
  row spacing, and if it still does not fit, its rows continue on further
  slides. Each slide repeats the header row and the caption, marked
  "(continued)", and the source goes on the last slide. A group or variable
  heading stays on the same slide as its first row. The source line
  `phw_add_slide()` puts at the bottom of a slide is 12 pt too. Set your own wording
  with the new `continued` argument of `phw_flextable()` and
  `phw_add_slide()`, for example for Welsh. Before, rows past the bottom of
  the slide were lost: a knitted deck dropped them without a warning, and
  `phw_add_slide()` warned how many fit. A continued slide in a knitted
  deck has no title, and `phw_add_slide()` repeats the title, marked
  "(continued)" when the table has no caption. A table with no rows, such
  as one a filter left empty in a scheduled report, goes on one slide with
  its caption, header row and source, as in Word and HTML.
* A table on a PowerPoint slide grows to fill the space it has. In a deck
  made with R Markdown or the Quarto `phw-pptx` format, a `phw_flextable()`
  with room to spare below `ft.top` now grows its text from 12 pt up to
  18 pt, and its columns widen with it, never past the slide's content area.
  Before, it stayed at 12 pt and a short table filled a small corner of the
  slide. `phw_add_slide()` grows a table up to 18 pt too, instead of 1.6
  times its size, and now grows a `phw_flextable()` you pass in as well as a
  data frame; `table_fit = FALSE` keeps it at 12 pt. A table that continues
  on further slides grows only as far as it can without taking more slides,
  and shows the same size on each. A table that fits on one slide only with
  its row spacing squeezed below the 12 pt layout now continues on a second
  slide at a larger size.
* A `phw_flextable()` in a deck made with R Markdown or Quarto is sized and
  split for the slides of that deck: those of its reference document, or of
  pandoc's own deck when there is none. Before, tables were sized for the
  13.33 x 7.5 in PHW deck, so in a 10 in wide deck, such as pandoc's default
  one, columns ran off the right of the slide and rows off the bottom.
* `phw_add_slide()` stops when given more content than the layout has room
  for, instead of silently using only the plot. It also refuses a chart or
  table on the navy Title Slide and Section Header layouts.
* A group with an empty name (`""`) stops `phw_colour_key()` and the PHW
  colour scales. Give it a label, or make it `NA` to show it as missing.
* `phw_map()` stops when every fill value is missing.
* `phw_spc()` stops when a time point has more than one row, as when `data`
  holds several areas, and says to filter to one series or to draw one
  chart per series and combine them with `phw_arrange()`. Before, it pooled
  the series into one centre line and one set of limits, so a shift in one
  area could show as common cause variation.
* `phw_boundaries("community")` returns every community as its own row,
  coded with its ONS code (`W04...`), with Welsh names in `name_cy`. Before,
  `code` was the community name, so communities that share a name, such as
  Castle in Cardiff and in Swansea, were merged into one area. Join your data
  by `code`, as names are not unique across Wales. Communities now come
  from the ONS Open Geography Portal (May 2026), in full, generalised and
  super generalised detail.
* `phw_epicurve()` leaves unused factor levels out of the legend unless you
  give a colour `key`. Groups after an unused level take the next colour,
  so pass `key` to keep colours fixed across charts.
* `scale_*_phw_d(reverse = TRUE)` now takes the first `n` colours of the
  palette and then reverses them, giving the same colours as
  `phw_pal(n, reverse = TRUE)`. Reversed charts with fewer groups than the
  palette has colours change colour: with 3 groups, `"main"` gives `#FF5D0C`,
  `#24A2B5`, `#285087` instead of `#F43882`, `#FF5D0C`, `#24A2B5`.
  `"main"` also carries on into `"extended"`, so more than four groups no
  longer take colours from other palettes with a warning.
* `palette = "highlight"` draws the first group in navy and every other
  group in light grey, however many groups there are. This applies to
  `phw_pal()`, `scale_*_phw_d()`, `phw_colour_key()`, `phw_plotly()` and
  the leaflet functions. With `reverse = TRUE` the last group is navy.
  Before, only the second group was grey and later groups took colours from
  other palettes, and `phw_pal()` stopped when asked for more than two.
* `scale_fill_phw_div()` and `scale_colour_phw_div()` take `midpoint` in the
  units of the data, as `ggplot2::scale_fill_gradient2()` does. With
  `transform = "log10"`, `midpoint = 1` now puts the neutral colour on 1, so
  a rate ratio chart shows values below and above 1 in different colours.
  Before, the midpoint was read on the log scale, so most charts came out
  in one colour. A `midpoint` the scale cannot show, such as the default 0
  on a log scale, now stops with a message.
* A sequential or diverging palette given to groups is spread over them,
  as `phw_pal()` does. This applies to `scale_*_phw_d()`, `phw_map()` with
  a text or factor `fill`, `phw_epicurve(palette = )`,
  `phw_leaflet_palette(type = "factor")`, `phw_colour_key()`, and the groups
  and traces of a `plot_ly()` chart in `phw_plotly()`. Traces that map no
  colour, from `split =` or separate `add_trace()` calls, leave out the
  near-white steps, which vanish on white. Before,
  groups took the first colours of the palette: three groups in `"blues"`
  were its three palest, `"orange_navy"` showed only its orange half, and
  ten deciles ran out of blues and took other PHW colours with a warning.
  Charts and maps of groups in these palettes change colour. A saved colour
  key keeps the colours it already gave its groups, and groups it gains
  later take the colours of the same palette furthest from the ones it
  already uses, so no two groups end up looking alike.
* `phw_leaflet_polygons()` and `phw_leaflet_palette(type = "factor")` order
  groups as the PHW ggplot2 scales do: text sorted, factor levels in their
  order, with unused levels and `NA` left out. A group now has the same
  colour on a leaflet map as in a chart of the same data. Before, groups
  took colours in row order. `phw_leaflet_palette()` also no longer counts
  `NA` or unused levels when sizing the palette, which gave colours blended
  between PHW colours. Maps of groups that are not in sorted order change
  colour.
* `phw_leaflet_palette(type = "factor")` gives each group its
  `phw_colour_key()` colour, as `phw_leaflet_polygons()` does: groups such
  as "Unknown" are grey, the other groups take the palette colours in turn,
  and more than twelve groups carry on with the warning the colour key
  gives instead of stopping. Before, "Unknown" took a palette colour and
  pushed the groups after it along by one.
* `phw_leaflet_palette(type = "factor")` with no `palette` uses the
  default palette for groups, as `phw_leaflet_polygons()` and
  `phw_colour_key()` do, and follows `options(phwstyle.palette = )`.
  Before, it used `"blues"`, so the first group was almost white. Numeric,
  binned and quantile palettes still default to `"blues"`.
* `phw_leaflet_polygons(bins = )` reads `bins` as `phw_map()` does: the
  bins run from the lowest to the highest value, rounded out to tidy
  numbers, and are split at the breaks you give, or into that many classes
  for a single number. Before, an area below the first break or
  above the last was drawn grey as if it had no data and was left out of
  the legend, and `bins = 5` gave 6 classes on a leaflet map and 3 in
  `phw_map()`. Binned leaflet maps change colour and legend.
* `phw_leaflet_polygons(bins = )` and `phw_leaflet_palette(type = "bin")`
  put an area in the same class, with the same colour, as `phw_map()` and
  `scale_fill_phw_b()`: a value on a break is in the class below it, and
  each class takes the shade the binned scale gives it. Before, a rate of
  exactly 5 with `bins = c(0, 5, 10, 15, 20)` was in the first class on
  `phw_map()` and the second on the leaflet map, and the shades differed.
* `phw_map(bins = )` no longer draws an area grey as missing when a break
  lies outside the data, as in `bins = c(0, 20, 100)` for rates of 5 to 35.
* `phw_map(bins = )` and `phw_leaflet_polygons(bins = )` with a single
  number draw that many classes of equal width with tidy edges, such as
  0, 25, 50, 75 and 100 for `bins = 4` on rates of 12 to 88. Where no tidy
  width gives that number, they draw the nearest number they can and say
  so. Before, they drew fewer classes than asked for without a word:
  `bins = 3` and `bins = 4` both gave 2 classes on rates of 12 to 88.
* `phw_map(bins = 2)` and `phw_leaflet_polygons(bins = 2)` split the areas
  into two classes at the tidy number nearest the median that leaves an
  area in each class. Before, they could draw every area in one colour, or
  put almost every area in one class when the data were skewed.
* `phw_map()` checks `bins` as `phw_leaflet_polygons()` does: a single
  number below 2 stops with a clear error. Before, `bins = 1` gave an
  error from another package and `bins = 0` never returned.
* `phw_map(label = )` draws a label for every area, moving a label off a
  small area with a line to it where needed. Where labels still overlap at
  the size the map is drawn, a message names them and suggests saving the
  map larger or labelling fewer areas. Before, labels in crowded parts of
  the map, such as Caerphilly and Rhondda Cynon Taf, were left out without
  a word. To leave out labels that cannot be placed clear of the others,
  set `options(ggrepel.max.overlaps = 10)`.
* `phw_plotly()` colours the groups of a `plot_ly()` chart as the PHW
  ggplot2 scales do: unused levels are left out, `NA` is grey instead of
  invisible, groups such as "Unknown" are grey, and every group gets its own
  colour, with the warning `phw_colour_key()` gives when the palette runs
  out. Before, more than twelve groups or an unused level gave colours
  blended between PHW colours or shifted along by one. Pie slices take the
  colour of their group, not of their row, so a pie and a bar chart of the
  same data match. Traces added with their own `data` are coloured from
  that data, and all traces share one set of colours.
* `phw_plotly()` gives a ggplot with no colour or fill scale of its own the
  colours the static chart has. Before, a continuous colour started from the
  palest blue, groups such as "Other" turned grey and `NA` was a lighter
  grey than in the static chart. Its groups take their colours from
  `palette`, as in a `plot_ly()` chart, and a group named in the palette,
  such as "Red" with `palette = "rag"`, takes its own colour. Before,
  `palette` was ignored for a ggplot and its groups always had the default
  palette.
* `phw_plotly()` gives a figure combined with `plotly::subplot()` the PHW
  colours. Before, it kept plotly's default colours: groups, traces with no
  colour mapping and heatmaps all came out in plotly's palettes. A group
  now has the same colour in every panel, and a trace that maps no colour,
  such as a Wales line, takes a palette colour no group uses, as in a
  single chart. If a panel sets its own colours,
  `phw_plotly()` keeps them and says how to give the other panels PHW
  colours.
* `phw_plotly()` gives every panel of a figure combined with
  `plotly::subplot()`, or of a faceted ggplot, the PHW axis style. Before,
  only the first panel had it and the others kept plotly's or ggplot2's
  default axes.
* `phw_plotly()` gives the groups of ggplots combined with
  `plotly::subplot()`, or converted with `plotly::ggplotly()`, the PHW
  colours, with a group the same colour in every panel. Before, they kept
  ggplot2's default colours, even after `use_phw_ggplot()`, and a group
  could change colour from one panel to the next. A ggplot that sets its
  own colours with a scale keeps them.
* `phw_plotly()` shades a ggplot coloured or filled by a number with the
  PHW blues when the ggplot was converted with `plotly::ggplotly()` or
  combined with `plotly::subplot()`, light for low values and navy for
  high ones, as in the static chart. Before, it kept ggplot2's default
  gradient, which runs from dark to light, so the shading ran the other way.
* `phw_plotly()` draws a missing group (`NA`) in grey in a figure combined
  with `plotly::subplot()`, as it does in a single chart. Before, its lines,
  bars and markers were invisible and its legend entry had no colour. This
  includes panels that set their own `colors`, such as `phw_colour_key()`
  or `phw_pal()`.
* `phw_plotly()` colours a figure combined with `plotly::subplot()` from
  its data when a colour column shares its name with an object or a
  function, such as `class`. Before, it stopped with an error, or warned
  that the palette had run out.
* `phw_plotly()` shows the labels of `phw_funnel()` and `phw_map()`, and
  of any `ggrepel::geom_text_repel()` or `ggrepel::geom_label_repel()`
  layer, as plain text placed by its `hjust` and `vjust`. Before, plotly
  dropped them with a warning that this geom was not implemented.
* `phw_plotly()` draws the 95% limits of `phw_funnel()` dashed and the
  99.8% limits solid, as in the static chart. Before, plotly drew all four
  limit lines solid, so a reader could not tell the two limits apart.
* `phw_plotly()` gives a label the same colour in every pie of a figure.
  Before, each pie took its colours from its own labels, so a label could
  be orange in one pie and teal in the next, and the shared legend showed
  the wrong colour for it.
* `phw_plotly()` draws rows with a missing group in grey when the chart
  sets `colors`, either as a key such as `phw_colour_key(...)` or as a
  plain vector such as `phw_pal()`. Before, they were invisible: the
  legend showed "NA" with no line or markers. A key that gives `"NA"` its
  own colour keeps it.
* `phw_plotly()` colours a `plot_ly()` chart by a number with the same
  blues as a ggplot2 chart, starting at `#C9D3E1`. This covers markers,
  lines, heatmaps, contours and choropleths, alone or combined with
  `plotly::subplot()`. Before, the scale started at the palest blue, so the
  lowest values almost vanished on white and the same data looked
  different in the two kinds of chart.
* `phw_plotly()` draws a missing value in a `plot_ly()` chart coloured by
  a number in light grey, as the ggplot2 charts do. Before, plotly drew it
  near-black, so it read as the highest value.
* `phw_plotly()` draws a missing heat map cell in light grey, as the
  static chart does, for `geom_tile()`, `geom_raster()` and `plot_ly()`
  heat maps. Before, the cell was left white, so it read as the lowest
  value.
* `phw_plotly()` gives groups the PHW colours, and a number the PHW blues,
  when the chart starts with a trace that maps no colour, such as a Wales
  line added before the health boards. Before, plotly took the colours of
  all traces from the first one, so the groups kept plotly's default
  colours and a number its default scale. A trace that maps no colour now
  takes a palette colour no group uses, so it never shares a colour with a
  group. A line added after the groups may change colour.
* With `palette = "rag"` or `"rag_accessible"`, groups called "Red",
  "Amber" and "Green" (in any case) take the red, amber and green colours,
  whatever order they sort in. Before, they took the colours in sorted
  order, so Red was drawn green, Amber red and Green amber. The same holds
  for the named colours of `"strategy"` and for a named vector of colours,
  in every chart, map and table, with `reverse = TRUE` too. A colour key
  that had stored the wrong colour for such a group is corrected. Colours
  pinned with `values` or `fixed` still win.
* The same name matching now applies to the default colours after
  `use_phw_ggplot(palette = "rag")`, so a chart with no colour scale of
  its own draws Red, Amber and Green in their own colours, as
  `phw_plotly()` does for the same chart. It also applies to
  `phw_key_recolour(name, "rag")` and `phw_key_recolour(name, "strategy")`.
  Before, both handed out colours in the groups' sorted order.

## Charts and maps

* `phw_pyramid()`, `phw_epicurve()`, `phw_map()`, `phw_funnel()`,
  `phw_spc()` and `phw_forest()` stop when given a `table()` or a matrix
  and say what to pass instead. Before, they failed with "Can't select
  within an unnamed vector" or "Column doesn't exist". For counts in a
  `table()`, pass `as.data.frame(as.table(x))` with `value = Freq` to
  `phw_pyramid()`, `count = Freq` to `phw_epicurve()` or `fill = Freq` to
  `phw_map()`.
* A chart's caption, such as the OS and ONS licence line of `phw_map()` or
  a `phw_caption()` source line, now wraps to the width the chart is drawn
  at by `phw_save()`, `phw_finalise()`, `phw_add_slide()` and the
  `phw_*_document()` formats. In a `phw_arrange()` figure, each plot's
  caption wraps to the room under that plot. Captions are right-aligned, so
  before, a line wider than its room lost its start off the left edge or
  printed over the caption beside it: two maps side by side, or one map
  saved at half-page width, cut off their licence line.
* A `phw_arrange()` figure moves its plots' captions under the whole
  figure, each text once, when they do not fit under their plots: a map's
  licence line beside a chart, or under two maps finished with
  `phw_finalise()`. They also move when the room the captions take makes
  maps so narrow that their titles run into each other. Before, the
  captions wrapped narrower on each try and the maps shrank with them: the
  figure collapsed into a strip with titles printed over each other, a map
  became a thumbnail with its licence line cut off at the left, or drawing
  stopped with the error "Viewport has zero dimension(s)".
* In a `phw_arrange()` figure, a plot's title or subtitle wraps when it is
  wider than the room it has, up to the next title in its row or the right
  edge of the figure. Before, a map beside a chart with a legend of groups,
  such as `phw_arrange(phw_epicurve(..., group = board), map)`, lost the
  end of the map's title off the right edge, or printed it over the
  chart's title when the map was on the left.
* In a `phw_arrange()` figure, a map keeps its size when its title is
  wider than the map: the title wraps only to the width each plot in the
  row would have if all were as wide, and the plot beside the map gives up
  the width the rest needs. Titles side by side also keep a space between them. Before,
  with `phw_finalise()`, a figure title, a half-slide size or two maps side
  by side, the map's title wrapped to one word per line and printed over
  the next title, the map shrank to a thumbnail, and the licence line of
  two maps could run off the left edge.
* When a map makes a `phw_arrange()` figure narrower than the image, as
  it does stacked with `ncol = 1`, the legend collected under the figure
  wraps to the room from the figure's left edge to the right edge of the
  image. Before, a legend of health boards ran off the right edge.
* A legend of groups across the bottom or top of a chart takes more rows
  when one row is wider than the chart. Before, a legend of health boards
  at the default sizes stayed on one row and its last boards were cut off.
  This applies to charts saved with `phw_save()`, finished with
  `phw_finalise()`, arranged with `phw_arrange()`, placed with
  `phw_add_slide()` or drawn in a document made with the `phw_*_document()`
  formats. A legend given its own number of rows or columns, as in
  `guide_legend(nrow = 1)`, keeps them.
* `theme_phw_map(legend = "bottom")` and `legend = "top"` centre the
  legend under the map. Before, the legend started at the map's left edge,
  which is narrower than the image because a map keeps its shape, so a
  legend of health boards saved at the default size ran off the right edge.
* `theme_phw()` puts each legend across the bottom or top of a chart on a
  row of its own, so a second legend no longer runs off the right edge.
  Before, the average line's key in `phw_epicurve(average = )` and the
  legends of a `phw_arrange()` figure that do not merge were placed beside
  the first legend and cut off. With `phw_arrange(guides = "keep")`, each
  plot's legend now wraps to the width of that plot instead of the whole
  figure, so the legends no longer overprint each other.
* The legend that `phw_arrange()` collects across the bottom or top of a
  figure starts at the left of the figure, under the title, and wraps to
  the figure's width, as the legend of a single chart does with
  `theme_phw()`. Before, it started at the first chart's y axis but
  wrapped to the whole figure width, so a legend of health boards at the
  default size ran off the right edge and its last board was cut off. Two
  legends of health boards, such as a line chart beside a bar chart, also
  took so many rows that the charts had no height left. With a theme that
  sets `legend.location = "panel"`, the legend stays under the charts and
  wraps to their width.
* A colour bar or colour steps legend across the bottom or top of a chart
  is long enough for its labels to be read. Before, it was about 2 cm
  long, so labels such as 600 to 1600 ran into each other and the first
  was cut off at the left edge. The bar is now at least twice as long, and
  longer when its labels need the room. This applies to
  `scale_*_phw_c()`, `scale_*_phw_b()` and `scale_*_phw_div()` wherever
  the chart is drawn, and to any colour bar in a chart saved with
  `phw_save()`, finished with `phw_finalise()`, arranged with
  `phw_arrange()`, placed with `phw_add_slide()` or drawn in a
  `phw_*_document()`. A bar on the right, as in `phw_map()`, and a bar
  given its own `guide`, keep their size.
* `phw_funnel()` draws the same chart whatever the columns are called.
  Before, a denominator column named `value` was replaced by the computed
  percentage, so the points were drawn at the wrong place along the x-axis,
  and a `label` column named `zone` showed the zone names instead of the
  units. The added `value` and `zone` columns in `$data` now get a dot in
  front (`.value`, `.zone`) when `data` already has a column of that name.
* `phw_map()` fills every part of an area when `level` is an sf data frame
  that holds the area as several rows, one per island or part, as some
  boundary files do. Before, only the first part took the area's colour and
  the others were drawn grey, as areas with no data.
* `phw_map()` follows the settings given to `use_phw_ggplot()`, such as
  `base_size = 14` or `accessible = TRUE`, as the other ready-made charts
  do. Before, maps always used the `theme_phw_map()` defaults, so in a report
  set up for larger text they had smaller text than every other chart. Maps
  keep their legend on the right and have no gridlines.
* The ready-made charts and maps, and the titles and source lines from
  `phw_arrange()`, `phw_finalise()` and `phw_title_grob()`, keep following
  the settings given to `use_phw_ggplot()` after a `theme_update()` or
  `theme_replace()`. Before, any such tweak sent them back to size 11 and
  `accessible = FALSE` without a word, while plain ggplots kept the
  settings. Setting a whole new theme, such as `theme_set(theme_grey())`,
  still sends them back to the defaults.
* `phw_arrange()` no longer draws the legend of a plot that turned its own
  legend off with `theme(legend.position = "none")`. Before, collecting
  legends at `legend` turned it back on and drew it under the figure.
* `phw_arrange()` draws the figure title, subtitle and source line with
  the settings given to `use_phw_ggplot()`, such as `base_size = 16` or
  `accessible = TRUE`. Before, they kept the `theme_phw()` defaults, so the
  figure title could be smaller than the panel titles under it.
* The source line added by `phw_finalise()` and the figure title from
  `phw_title_grob()` follow the settings given to `use_phw_ggplot()`, such
  as `base_size = 16` or `accessible = TRUE`. Before, they were always
  8.5 pt and 14 pt, so finalising an accessible chart made its source text
  smaller, and a figure title could be smaller than the panel titles under
  it. Give `text_size` or `size` to set the size yourself.
* After `use_phw_ggplot()`, and so in every `phw_*_document()` format,
  groups from an ordered factor (from `factor(..., ordered = TRUE)`,
  `cut(..., ordered_result = TRUE)` or `lubridate::month(label = TRUE)`)
  get the PHW palette, as unordered groups do. Before, they got ggplot2's
  viridis colours. `theme_phw()` on its own still leaves them in viridis,
  because ggplot2 does not take their colours from the theme.
* Ready-made charts check their data first. Text where numbers are needed,
  negative counts and impossible settings (funnel limits, targets, SPC
  baseline, pyramid `left`) stop with a message that says what to change.
  Epidemic curves say how many cases fall outside `range`.
* `phw_map()` lists codes it could not match, and says when an area is drawn
  twice in one panel or when `bins` or `key` do not apply. `phw_forest()`
  says when a unit has more than one row in a panel. Faceting by period
  stays quiet in both.
* Faceted `phw_map()` panels draw every area. An area with no data in a
  panel is drawn in the missing-value colour instead of being left out.
* `scale_shape_phw()` and `scale_linetype_phw()` keep missing groups on the
  chart (new `na.value`). Past eight groups they stop with a clear message.
* `scale_fill_phw_d(na.translate = FALSE)` and
  `scale_colour_phw_d(na.translate = FALSE)` leave missing groups off the
  chart, as ggplot2's own scales do. Before, they were still drawn in grey,
  with no legend entry.
* `reverse = TRUE` now works when the palette is a function, and a palette
  function gives groups its colours in its own order.
* `width` and other bar settings passed through `...` work in
  `phw_epicurve()` and `phw_pyramid()`.
* `phw_pyramid()` gives each sex the colour named after it in `palette`,
  as in `palette = c(Female = "#24A2B5", Male = "#285087")`. Before, it
  dropped the names and gave the colours out in the order of the sexes, so
  each sex could be drawn in the other's colour. Its colours now come from
  `scale_fill_phw_d()`, so a sex value such as "Unknown" is drawn in grey,
  as in the other charts.
* `phw_pyramid(compare = )` stops when `value` is not given and `compare`
  has one row per age and sex, as a population table does, and says to
  count `data` and pass `value`. Before, each row of the population was
  counted as one person, so every outline was drawn the same size.
* `phw_pyramid()` shows every level of the `age` factor, so an age band
  with nobody in it stays on the axis as a gap. Before, it was dropped when
  `data` had one row per person, or no row for that band.
* `phw_epicurve(average = )` repeats the average line in every panel when
  the chart is faceted by `group`. It is the total of all groups, so it
  belongs in each one. Before, it was drawn in the first group's panel
  only, where it read as that group's own average.
* `phw_epicurve(position = "dodge")` draws each period's bars inside the
  period, as stacked bars are, with the average line over their centre.
  Before, they were drawn half a period early.
* `phw_epicurve()` labels the x axis at period starts, in a short format
  that suits `interval`: `"6 Jan"` for days and weeks, `"Jan"` for months
  and quarters and `"2025"` for years, with the year under the first label
  and wherever it changes. The first period is always labelled, so cases
  that all fall in one week or month still get a date. Labels that would
  overlap on a narrow chart are left out. Before, such a chart could have
  no date labels, and weekly labels fell on month starts rather than week
  starts.
* `theme_phw()`, `theme_phw_map()`, `phw_arrange()`, `phw_style_extensions()`
  and the colour scales check their arguments when called, not when the
  plot is drawn.
* `phw_finalise()` shows the organisation name when no logo is installed
  (change it with the new `org`), and stops with "file not found" for a
  missing logo file.
* `phw_finalise()` keeps the footer readable on narrow charts. When the
  source does not fit beside the logo or organisation name, it moves above
  them and wraps to the width of the chart.
* `phw_finalise()` on a map lays the footer out at the width of the map,
  which is often narrower than the image. The source stays beside the
  organisation name or logo, or moves above it, the whole footer stays on
  the image, and the map's licence wraps as one paragraph. Before, at
  every default `phw_save()` size, the licence was printed over the
  organisation name, ran off the bottom of the image and left short lines
  such as "Open".
* `phw_finalise()` on a `phw_arrange()` figure keeps every panel, the
  figure title and the panel tags. Before, only the last panel was kept.
* `phw_finalise()` on a `phw_arrange()` figure of maps, or of other plots
  that keep their shape, draws and saves. Before, printing or saving it
  failed with "'respect' must be logical or an 'nrow' by 'ncol' matrix".
* `phw_finalise(note = )` with no `source` or `date` adds the note under
  the caption already on the plot. Before, the plot's caption was dropped
  and only the note was shown.
* `phw_title_grob()` makes room for a title or subtitle on more than one
  line. Before, the subtitle was drawn over the second title line, and
  without a subtitle the second line ran into the plot.
* `phw_save(bg = )` sets the background of the saved file, so
  `bg = "transparent"` gives a transparent PNG. Before, the white
  `theme_phw()` background covered it, and a `phw_finalise()` chart took
  `bg` only under its footer. With no `bg`, a chart keeps its own
  background as before.
* `phw_save()` writes `.eps` and `.ps` files. Before, it failed with
  "family 'Ubuntu' not included in postscript() device". Like `.pdf`, they
  use Ubuntu once it is installed with `phw_install_fonts()`. On macOS
  they need XQuartz, and without it `phw_save()` says so.

* `phw_number(big.mark = )` and `phw_percent(big.mark = )` change the
  thousands separator, so `phw_number(big.mark = "")` labels years as
  `2024`. Before, `big.mark` stopped with "matched by multiple actual
  arguments".

## Tables

* In a Quarto document, the `caption` of `phw_flextable()` shows above the
  table in HTML, Word, PDF and Typst output, as it does in R Markdown.
  Before, Quarto dropped it without a word. A chunk that sets the `tbl-cap`
  option keeps Quarto's caption instead.
* `phw_flextable()` brings the Ubuntu web font into an HTML document, a
  Quarto HTML page and the RStudio Viewer, as `phw_gt()`, `phw_reactable()`
  and `phw_datatable()` do. Before, a computer without Ubuntu installed drew
  the table in a serif font unless another phwstyle output on the page
  loaded the font. `htmltools::as.tags()` on a `phw_flextable()` carries the
  font too.
* Summary and group tables look the same in `phw_flextable()`, `phw_gt()`,
  `phw_reactable()`, `phw_datatable()` and `phw_write_xlsx()`. Variable rows
  are shaded unless `highlight = FALSE`. `phw_datatable()` gains the
  spanner, two-level column headers, group separators and right-aligned
  statistics.
* `phw_flextable()`, `phw_gt()`, `phw_datatable()` and `phw_write_xlsx()`
  keep labels held in row names, as `as.data.frame()` gives for a matrix or
  `do.call(rbind, ...)` for split data. They show as a first column with a
  blank header, as `phw_reactable()` already showed them. Before, the
  labels were dropped without a word, leaving numbers with no area names.
  Row names a column already holds, as `data.frame(x = names(v), n = v)`
  gives for a named `tapply()` or `sapply()` result, are not shown again,
  and `phw_reactable()` no longer shows them twice. Whole-number labels,
  such as the years, weeks or ages of a `table()` or `tapply()` result, show
  too, oldest or newest first. Row numbers are not labels and are not shown,
  including those `rbind()` keeps as text, such as `"31"`, when filtered
  subsets share row numbers. Whole-number labels out of number order, such
  as rows sorted by a count, or sparse ones whose last few jump far above
  the rest, can look the same as those row numbers and are not shown: put
  them in a column instead.
* `phw_flextable()`, `phw_gt()`, `phw_reactable()` and `phw_write_xlsx()`
  show a column whose name is missing, as a crosstab made with
  `table(useNA = "ifany")` or `xtabs(addNA = TRUE)` has, under the header
  "NA", as `phw_datatable()` already did. Before, they failed with an error
  from another package. Rename the column to show another header.
* `phw_reactable()` tables close with a navy rule and have a navy spanner.
* `phw_reactable()` merges your `columns` into a summary table's own column
  settings, so restyling one column keeps the indents, navy headings,
  alignment and blank missing values of the rest. A `format` in
  `defaultColDef` now applies to every column instead of being replaced by
  `digits`.
* `phw_reactable(group_col = )` and `phw_flextable_groups()` give each group
  the colour it has in a chart of the same data: the groups in use, sorted
  or in factor order. Before, colours followed the order of the rows, and
  an unused factor level took a colour. A `colDef` you give for the group
  column in `columns` now keeps the group colours.
* `phw_flextable_groups()` leaves a row with a missing group uncoloured, as
  `phw_reactable(group_col = )` does. Before, the row was given an `NA`
  colour and the table could not be saved to Word.
* On a summary table such as one from `phw_crosstab()`,
  `phw_flextable_groups()` and `phw_reactable(group_col = )` colour only the
  level rows. Before, the Total row took the next colour, so it read as one
  more group, and "Total" was added to the colour key. `phw_reactable()`
  also kept its own style for the label column and coloured no rows. The
  groups take the order of the table's level rows, which is the factor
  order, as in a chart of the same data. Before, they were sorted as text,
  so age groups such as "5-14" and "15-44" got each other's colours. In a
  table from `phw_group_table()`, each level keeps its colour when the first
  group has no rows for a level. Before, every level took the colour of the
  one before it.
* `phw_flextable_groups()` and `phw_reactable(group_col = )` can colour a
  table from `phw_group_table(layout = "columns")` by an outer column, such
  as the board in `rows = c(board, sex)`. Each level row takes the colour of
  the group it sits under. Before, both stopped with a message about a group
  with an empty name.
* `phw_datatable()` keeps the `columnDefs` you give in `options` for a
  summary table. Before, the table's own column settings replaced them.
* `phw_datatable()` accepts columns renamed with a named `colnames`, such as
  `colnames = c(Cases = "cases")`, and still rounds the numbers and styles
  a summary table's renamed columns. Before, it stopped with an error from
  DT, or a summary table lost the styling of a renamed column.
* `phw_datatable()` shows the names you give in `colnames` in the header of
  a summary table with a spanner or a multi-level header, such as a
  `phw_crosstab()`. An unnamed `colnames` now renames a summary table's
  columns in order. Before, a spanner table kept its old names, and an
  unnamed `colnames` moved every name one column to the right.
* `phw_col_heat()` shows whole-number columns, such as counts and totals,
  without decimals, and otherwise the `digits` of a summary table. Before,
  it showed every value with one decimal, as `61.0`. `phw_col_rag()` takes
  the table as `data`. Given it, only the level rows of a summary table get
  a colour and a shape, and whole numbers show without decimals, as in
  `phw_flextable_heat()`.
* `phw_reactable()` and `phw_datatable()` show date-times at the clock time
  of their own time zone, as `2026-07-01 10:00:00`, like `phw_flextable()`.
  Before, they showed them in UTC.
* `phw_write_xlsx()` writes the spanner, navy labels, italic subtotals, a rule
  above the total, ISO dates and a bold right-aligned source. It checks `x`
  and accepts `header_fill = "navy"`.
* `phw_write_xlsx(digits = 0)` writes whole numbers as `1,235`. Before, the
  number format had a trailing point, so Excel showed `1,235.`.
* `phw_write_xlsx()` stops when two sheet names become the same once
  cleaned for Excel, such as `"North/South"` and `"North?South"`, `"Cases"`
  and `"cases"`, or two long names that share their first 31 characters.
  Before, the second table was written over the first sheet.
* `phw_write_xlsx()` stops when the folder for `file` doesn't exist, when
  `file` doesn't end in `.xlsx`, and when `title` is neither one string nor
  one per sheet. Before, a missing folder gave an error from openxlsx2, a
  `.xls` name gave a file Excel complained about, and a short `title` was
  repeated, so a sheet could get another sheet's title.
* `phw_flextable_heat(symbols = TRUE)` keeps the table's number format, so
  `phw_flextable(digits = 1)` shows "▼ 92.3", not "▼ 92.34568".
* In a PDF report, the ▲ ■ ▼ shapes that `phw_flextable_heat()` adds to red,
  amber and green cells show as they do in HTML and Word. The Ubuntu font
  has no such shapes, so the PDF sets them in DejaVu Sans, or in Latin
  Modern Math when DejaVu Sans is not installed. Before, each shape was a
  missing-character box.
* On a summary, cross-tab or group table, `phw_flextable_heat()` and
  `phw_col_heat()` colour only the level rows. Before, totals and subtotals
  were coloured too and set the top of the scale, so every other cell came
  out pale, and headings lost their grey band in the coloured columns.
  The total columns of a cross-tab or group table stay out of the scale
  too, so `phw_flextable_heat(j = -1)` no longer colours the Total column
  navy and every other cell near-white. Choose only total columns to colour
  them on a scale of their own.
* With a fixed `domain`, `phw_flextable_heat()` and `phw_col_heat()` give a
  value beyond it the colour at the nearer end, as a chart does with
  `oob = scales::squish`. Before, the cell was left unfilled, so it read as
  no data, and scales gave a warning.
* On a summary, cross-tab or group table, `phw_flextable_bars()` and
  `phw_col_bar()` draw bars on the level rows only, scaled to the largest
  level. Headings, subtotals and totals show the number only. Before, the
  grand total set the scale, so every level bar came out a sliver.
* On a group table with `totals = "subgroup"`, the "Total by ..." block
  stays out of the heat and bar scales too, in `phw_flextable_heat()`,
  `phw_flextable_bars()`, `phw_col_heat()` and `phw_col_bar()`. Before, its
  rows set the top of the scale, so the group levels came out pale with
  short bars. The block looks the same as before.
* `phw_col_bar()` and `phw_col_heat()` stop with a message when `data` is
  not a data frame, as `phw_col_rag()` does, and say how to convert a
  `table()` or a matrix. Before, a `table()` gave "Column `Freq` doesn't
  exist".
* `phw_flextable_heat()` and `phw_flextable_bars()` choose `j` from the
  columns the table shows, so `j = -1` or `where(is.numeric)` works on a
  table whose `col_keys` hides a column. Before, they stopped with an error
  from flextable about the hidden column.
* Bars from `phw_flextable_bars()` show in a Word report made with
  `phw_word_document()`, as do links in a flextable. Before, Word called the
  file corrupt, and flextable's warning was printed in the report. A
  flextable caption numbered with `set_caption(autonum = )` now shows its
  number there too.
* In `phw_flextable()`, the spanner above a summary, cross-tab or group
  table's columns takes the same colour as the column labels below it. With
  `style = "header"` it is white on the navy band, with a white rule under
  it. Before, it was navy on navy and could not be read. It also follows
  `accent` and `header_colour`, and uses dark text with `style = "light"`.
* On a summary, cross-tab or group table with a spanner, `phw_reactable()`
  and `phw_flextable()` draw the navy top rule above the spanner and no navy
  rule inside the header, as do `phw_gt()`, `phw_datatable()` and
  `phw_write_xlsx()`. Before, `phw_reactable()` drew its top rule under the
  spanner, and `phw_flextable()` drew a short rule over the label column
  between the header rows.
* `phw_flextable(flextable_args = list(col_keys = ))` can leave out or
  reorder the columns of a summary table, keeping the label columns first.
  Before, it failed inside flextable.
* `phw_flextable(col_labels = )` relabels the bottom header row of a group
  table with two or more column levels, as it does with one. Before, the
  labels were dropped without a message.
* `phw_gt()` tables carry the bundled Ubuntu web font, dates are
  left-aligned and subtotals are italic.
* `phw_gt()` and `phw_gt_theme()` tables in a Word document use the PHW
  font, with bold spanners and bold, shaded row groups. Before, Word showed
  them in Calibri. gt can't make the column labels bold or indent the
  levels of a summary table in Word, so the first gt table knitted to Word
  in a session prints a note on the console suggesting `phw_flextable()`,
  the table renderer for Word. The note is for the author and is not
  written into the document.
* `phw_gt()` and `phw_gt_theme()` tables render in Quarto `phw-typst`
  and `phw-pptx` documents and in R Markdown PowerPoint decks, as plain gt
  tables do. Before, the web font made the render stop with "Functions
  that produce HTML output found in document". R Markdown PowerPoint
  can't show gt tables, so the first one knitted in a session prints a note
  on the console suggesting `phw_flextable()`.
* `phw_gt()` left-aligns factor and logical columns, such as a health
  board stored as a factor or the label columns of a `table()` turned into
  a data frame, as the other table functions do. Before, gt centred them.
* In a PDF report, the source line of a `phw_gt()` table now reads as it
  does in HTML: "Source:" and "Data correct as of" on separate lines, and
  characters such as `&` and `%` shown as typed. Before, the PDF showed a
  literal `<br>`, an `&` stopped the PDF from building and a `%` cut the
  line short.
* A `phw_gt()` chunk in a Quarto `phw-pdf` document that sets `tbl-cap`
  without a `tbl-` label renders, with the chunk's caption above the
  table, as it does with a label. Before, the PDF stopped building with
  "Not in outer par mode" and held only the title page.
* `phw_gt_theme(...)` and `phw_gt(theme_args = )` can change a setting
  phwstyle already sets, such as `heading.align` or `data_row.padding`.
  Your value replaces the PHW one. Before, these stopped with "matched by
  multiple actual arguments".
* `phw_gt(gt_args = list(rowname_col = ))` takes a summary, cross-tab or
  group table's column name as it prints, such as `"Characteristic"`, and a
  label column used as row names keeps its indents, bold headings and navy
  header. A name that is not a column stops with a message listing the
  columns. `groupname_col` stops with a message on these tables, because
  their label columns name a group on its first row only. Before, any column name failed inside gt
  with a list of columns the table does not show.
* gt steps added after `phw_gt()` on a summary, cross-tab or group table,
  such as `gt::cols_width()`, `gt::cols_label()`, `gt::cols_hide()` or
  `gt::fmt_number()`, find its columns by the names the table shows, such
  as `Characteristic` or `Total`, as they do on a data frame. Before, they
  stopped with "Can't select columns that don't exist".
* `phw_group_table(totals = "subgroup")` heads the subgroup block with the
  variable label as you gave it, so "MRSA or MSSA (NHS lab)" is no longer
  printed as "mrsa or mssa (nhs lab)". The new `subgroup_label` sets the
  heading, with `{variable}` for the label (default `"Total by {variable}"`),
  so all its words can be replaced, for example in Welsh. It no longer uses
  `total_label`.
* `phw_group_table(drop = FALSE)` keeps factor levels that have no records,
  such as an empty age band or year, as rows and columns of zeros, as
  `phw_crosstab()` does. Before, it left them out.
* `phw_crosstab()` gives a table of zeros for data a filter left with no
  rows, such as a scheduled report in a week when nothing matched, with
  the levels of a factor column variable as columns. Before, it stopped
  with "length of 'dimnames' [2] not equal to array extent" when the column
  variable was a factor, and with a "'names' attribute" error for
  `totals = FALSE`. `phw_group_table()` with `totals = "none"` and
  `col_totals = "none"` gives an empty table for such data too, instead of
  "'data' must be of a vector type".
* `phw_flextable()`, `phw_gt()`, `phw_reactable()`, `phw_datatable()` and
  `phw_write_xlsx()` show `NaN`, `Inf` and `-Inf` as blank cells, as they
  show `NA`. Before, each showed them its own way, and `phw_write_xlsx()`
  wrote them as the Excel errors `#VALUE!` and `#NUM!`, so a `SUM` over the
  column failed.
* `phw_write_xlsx()` writes a missing row label in a summary table as an
  empty cell, as the other renderers show it. Before, the cell held the
  text `NA` after the indent.
* A `phw_group_table()` cell with no records is blank when `fun` gives no
  number for it, as `max` and `mean` do, and any `NaN` or `Inf` from `fun`
  is blank too. Counts and sums still show 0. Before, `fun = max` warned
  and showed `-Inf`.
* `phw_group_table(layout = "columns")` with three or more row variables
  puts the levels of the subgroup block ("Total by ...") in the innermost
  variable's column. Before, they sat in the second column.
* `phw_flextable()`, `phw_gt()`, `phw_reactable()`, `phw_datatable()` and
  `phw_write_xlsx()` show a `phw_group_table()` with the decimal places
  set by its `digits`, unless you give them their own `digits`. Before,
  `digits` was ignored without `percent`, so `fun = mean` values showed
  with one decimal place.
* `phw_flextable()`, `phw_gt()`, `phw_reactable()`, `phw_datatable()` and
  `phw_write_xlsx()` show a year column without a thousands separator, as
  2021, not 2,021. A year column holds whole numbers from 1800 to 2200 and
  has the word "year", "yr" or "blwyddyn" in its name, such as `Year`,
  `year_of_onset` or `Blwyddyn`. Other numbers keep their separator.
* `phw_summary_table()` shows a blank, not "( to )", when a statistic can't
  be calculated, and `labels` can be a named character vector.
* `phw_summary_table()` summarises a `difftime` column, such as a length of
  stay made by subtracting two dates, as a number in its own units: one
  median (IQR) or mean (SD) row. Before, each value became its own row.
* `phw_summary_table()` summarises a date or date-time column, such as an
  onset date, as one median (IQR) or mean (SD) row shown as dates
  (dd/mm/yyyy). Before, each date became its own row, so a line list with a
  date column gave a table of hundreds of rows.
* Filtering the rows of a summary, cross-tab or group table, or selecting
  some of its columns, with `[`, `head()`, `subset()` or dplyr's
  `filter()`, `slice()`, `arrange()` and `select()`, keeps the bold
  headings, indents, rules and column headers on the rows and columns
  kept. Before, every renderer styled the wrong rows or stopped with an
  error. A table without its label columns becomes a plain data frame. A
  table whose rows no longer match its styling, for example after
  `rbind()`, stops with a message suggesting `as.data.frame()`.
* A column added to a summary, cross-tab or group table, with dplyr's
  `mutate()` or with `$<-`, shows in every renderer with an empty cell
  above it. Before, `mutate()` and every renderer failed with "subscript
  out of bounds" on a table with column levels, and on a table with one
  spanner the new column sat under the spanner. Spanners and column
  levels follow their columns when they are moved or renamed.
* `phw_rate_table()` stops with a message naming the column when the count
  or population column is text, instead of failing inside `sum()`.
* Table and column helpers give clear errors for duplicated column names,
  negative bar values, a data frame where a flextable is needed, or an
  unknown style.
* `phw_flextable()`, `phw_gt()`, `phw_reactable()`, `phw_datatable()` and
  `phw_write_xlsx()` stop when given a `table()` or a matrix and suggest
  converting it with `as.data.frame()`. Before, flextable and reactable
  failed with "subscript out of bounds" and `phw_gt()` drew an empty
  table. `phw_datatable()`, which converted them itself, now stops the
  same way.
* `phw_as_summary()`, `phw_summary_table()`, `phw_crosstab()` and
  `phw_group_table()` stop when given a `table()` or a matrix and say what
  to pass instead. Before, `phw_as_summary()` dropped the row names,
  `phw_summary_table()` counted the cells as records, and `phw_crosstab()`
  and `phw_group_table()` failed with "Can't select within an unnamed
  vector". For counts you already have, `phw_crosstab()` takes
  `as.data.frame(as.table(x))` with `count = Freq`, and `phw_group_table()`
  takes it with `value = Freq`.
* `phw_flextable()`, `phw_gt()`, `phw_reactable()`, `phw_datatable()` and
  `phw_write_xlsx()` leave out the geometry of an sf data frame, such as
  `phw_boundaries()` joined to case counts, and show the other columns.
  Before, the geometry showed as a column of coordinates, "[[XY]]" or
  "[object Object]", and in Excel it ran past the cell size limit.
  `phw_summary_table()`, `phw_crosstab()`, `phw_group_table()` and
  `phw_as_summary()` also leave it out, so an sf line list or area table is
  summarised by its other columns. Before, areas stopped with an error from
  the units package, and points added a "geometry" variable with one row per
  point.
* `phw_flextable()`, `phw_gt()`, `phw_reactable()`, `phw_datatable()` and
  `phw_write_xlsx()` show a `difftime` column, such as a length of stay made
  by subtracting two dates, as a plain number in its own units. It is
  right-aligned like other numbers, and a missing value is blank. Before,
  flextable showed "4 days", gt centred the column and reactable showed a
  missing stay as "NA". Name the unit in the column heading, for example
  "Length of stay (days)".
* `phw_summary_table()`, `phw_crosstab()` and `phw_group_table()` keep
  the `label` attributes of columns when rows are left out for a missing
  value. Before, the headings fell back to the column names.

## Slides and documents

* The PowerPoint template from `phw_reference_pptx()`, used by `phw_pptx()`
  and the Quarto `phw-pptx` format, now has Comparison and Content with
  Caption layouts. pandoc uses these for a slide with text followed by a
  chart, and for two columns that hold text and a chart. Before, those
  slides fell back to pandoc's own plain layout, with a small unstyled
  title.
* The date from a deck's YAML header is now light on the navy title slide
  of the PowerPoint template from `phw_reference_pptx()`, like the
  subtitle. Before, it was grey on navy and hard to read. A footer or slide
  number on the title slide or a Section Header slide is light too.
* A grey PNG logo with transparency now works like a colour one in
  `phw_finalise()`, `phw_word_document()`, `phw_pdf_document()`,
  `phw_latex_header()`, `phw_reference_docx()` and `use_phw_quarto()`.
  Before, it stopped with "a raster array must have exactly 3 or 4 planes".
* In the Quarto `phw-docx` format, a captioned figure shows in full, with
  its source line. Before, the right edge of each chart was cut off, and
  navy rules were drawn above and below it. Charts are now drawn 6.3 by
  3.9 inches by default, as in `phw_word_document()`. Quarto lays out a
  captioned figure or table in a Word table, which now has the Layout
  Table style from `phw_reference_docx()`, with no rules or cell padding.
  With Quarto 1.5, whose pandoc cannot style that table, a figure or
  table on its own is taken out of it instead.
  Run `use_phw_quarto(template = "none", overwrite = TRUE)` to update the
  extension in an existing project.
* `phw_reference_docx()` writes a document with no text in it. A Word file
  made with `officer::read_docx(phw_reference_docx())` now starts with your
  own content. Before, it started with a page of sample text from pandoc.
* `phw_add_slide()` places content on every layout. Two Content fills the
  left side first, and Title Only and Blank place the chart, table or text
  in the free space.
* `phw_add_slide()` puts content into a layout's content placeholders and
  leaves text-only ones empty, so on a template's Comparison layout the chart
  and table fill the left and right areas. Before, the first went into the
  small heading above the left area.
* `phw_add_slide()` checks its arguments before it adds a slide, so a call
  that stops leaves the deck unchanged. It accepts a `phw_finalise()` chart
  as a picture.
* `phw_add_slide(table_fit = TRUE)` no longer grows a table that fits the
  slide until it runs off the bottom. Before, tables of about 10 to 12 rows
  grew past the content area, and the warning asked you to split them. A
  cell with more than one line now counts as that many lines when the table
  is sized.
* `phw_add_slide(table_fit = TRUE)` no longer narrows the columns of a table
  that is wider than the content area until numbers and labels break across
  lines. Its headings wrap first, then its cells, at no less than 12 points.
  A table still too wide gives a warning that names how many columns it
  has.
* `phw_add_slide()` scales the text of a `phw_arrange()` figure as one: every
  panel, the figure title and the source line. Before, only the last panel
  was scaled.
* `phw_add_slide()` wraps a chart's caption to fit the slide when its
  enlarged lines are too wide. Before, the start of each line was cut off,
  so a `phw_map()` on a half-width slide lost the start of its OS and ONS
  licence line.
* A flextable's caption, such as "Table 1 ..." from `phw_flextable()`, now
  shows on a `phw_add_slide()` slide, in a row at the top of the table.
  Before, PowerPoint left it out without a word.
* A `phw_flextable()` caption now shows above the table when the table is
  knitted into a PowerPoint deck, from R Markdown
  `powerpoint_presentation()` or the Quarto `phw-pptx` format. Before, the
  slide kept the table and its source line but dropped the caption.
* In the Quarto `phw-pptx` format, a table chunk with a `tbl-` label, as in
  the starter report from `use_phw_quarto()`, now shows its table. Before,
  the slide kept its title and lost the table, with only a warning from
  Quarto about images. A `phw_flextable()` shows the chunk's `tbl-cap` as
  its caption row, with or without a label, and a long one continues on
  further slides; a `phw_gt()` takes `tbl-cap` as its caption. A
  cross-reference such as `@tbl-cases` still reads "Table 1".
* In a PDF document, a `phw_flextable()` caption reads as it does in Word
  and HTML: "Table 1 Counts by board", or no number when you give none.
  Before, LaTeX added its own label, giving "Table 1. Table 1 Counts by
  board".
* In a Word document, a `phw_gt()` caption reads as it does in HTML and
  PDF: "Table 2 Cases by area", or no number when you give none. Before,
  gt added its own number, giving "Table 1: Table 2 Cases by area".
* In a Word or PDF document, a `phw_flextable()` table wider than the page
  now fits the text width. Its headings wrap first, then its cells, and its
  text shrinks to no less than 8 pt if the words alone are still too wide.
  A table that cannot fit even then gives a warning. Before, a summary
  table or cross-tab by the seven health boards ran past the right margin
  and lost its last columns.
* In the Quarto `phw-typst` format, a `phw_flextable()` table wider than
  the page fits the text width in the same way, as do the tables from
  `phw_flextable_heat()`, `phw_flextable_groups()` and
  `phw_flextable_bars()`. Before, a summary table by four health boards ran
  off the right edge of the page, cutting off its last columns and its
  source line.
* In a PowerPoint deck made with R Markdown or Quarto, a `phw_flextable()`
  table wider than the slide now fits the slide's content area, in the
  same way, except that its text stays at 12 pt or larger. A table that
  cannot fit gives a warning. Before, a
  summary table by the seven health boards ran off the right edge of the
  slide and lost its last columns without a warning.
* In a PDF document, a `phw_gt()` table stays where it is in the text, a
  table longer than the page carries on over the next pages with its title
  and column labels repeated, and a table wider than the text shrinks to
  fit it. Before, LaTeX moved the table, often to the next page after the
  paragraph that follows it, a table longer than the page ran over the
  footer and lost its last rows and source line, and a summary table by
  health board ran past the right margin and lost its Total column.
* In `phw_pdf_document()`, and in other LaTeX formats that use
  `phw_latex_header()`, a captioned chart stays where it is in the text,
  under its heading, as in Word and HTML. Before, LaTeX could move it past
  later sections, so a section had no chart and the chart appeared under
  another heading. Set the chunk option `fig.pos` to place a chart
  yourself.
* On the title slide and section header of your own template,
  `phw_add_slide()` gives `text` the template's colour and size, and the
  source line is white only when the slide background is dark. Before, both
  were near-white on every such slide, so they vanished on a white one.
* The title and `text` on a title slide or section header are in the PHW
  font, the title is bold, and `title_size` applies when you give it.
  Before, both used the template's font and size and the title was not bold.
* Captions leave out a missing or empty source, date or note instead of
  printing "NA", and name a misspelt caption argument. A `caption_args`
  list without names stops with a message that asks for a named list.
* The R Markdown formats add your own `css`, `includes` and `pandoc_args` to
  the PHW ones, and LaTeX characters in `team` print as typed.
* `phw_latex_header(file)` writes the page band image beside `file`, as
  `<name>-band.png`, and points the header at it. Before, the header pointed
  at a temporary image that was gone in the next R session, so a saved
  header stopped the PDF build with "File not found".
* In `phw_pdf_document()`, a document whose sections are `##` headings, as
  in the R Markdown file RStudio creates, is numbered 1, 2, 3, and its
  sections look like top-level sections. Before, they were numbered 0.1,
  0.2, 0.3. The top heading level a document uses is numbered from 1.
* `phw_pdf_document()` keeps the `dev` you give it instead of always using
  `"ragg_png"`.
* `phw_pdf_document()` uses `fontsize`, `documentclass`, `geometry` and
  `colorlinks` from the YAML header or from `pandoc_args` in place of the PHW
  ones. Before, the PHW values silently won, and a `fontsize` in
  `pandoc_args` gave LaTeX an option it doesn't know, so the text was 10pt.
  A `geometry` that sets only the margins keeps A4 pages: set `papersize` to
  change the paper. The Quarto `phw-pdf` format works the same way.
* `phw_pdf_document()` and the Quarto `phw-pdf` format colour links in PHW
  colours: web links in PHW blue, as in Word and HTML, and cross-references
  in navy. Before, pandoc's own blue and maroon replaced them. Set
  `linkcolor`, `urlcolor`, `citecolor` or `filecolor` in the YAML header to
  change them.
* `phw_pdf_document()` and the Quarto `phw-pdf` format build a document with
  two or more authors, and the cover lists each author on its own line.
  Before, LaTeX failed to compile and no PDF was written.
* `phw_download_logos()` saves nothing when the reply isn't an SVG.
* A logo folder with only PNG logos now shows the logo in
  `phw_html_document()`, `phw_header()`, `phw_page_navbar()` and the Quarto
  dashboard, slide and Typst formats. Before, they showed the organisation
  name or nothing, and `phw_has_logo()` returned `FALSE`. `phw_has_logo()`
  is now `TRUE` whenever the white PNG logo is available.

## Interactive outputs and colours

* `phw_plotly()` spaces the legend of a ggplot correctly in Chrome, Edge
  and the RStudio and Positron Viewer. Before, on a computer without the Ubuntu font installed,
  each label ran into the next item and the last label was cut off, as in
  "4-week averag" on an epidemic curve. The legend, axis titles, tick
  labels and facet strips now fall back to Arial while the Ubuntu font
  loads, as a `plot_ly()` chart already did. This holds for a chart made
  with `plotly::ggplotly()` and for a `plotly::subplot()` of ggplots too.
* `phw_plotly()` draws an empty chart for a ggplot whose data a filter left
  with no rows, as `plotly::ggplotly()` does, so a scheduled report still
  knits in a week where nothing matched. Before, it stopped with the error
  "values must be length 1". The same holds for a layer with no rows next
  to layers with data, and for a chart made with `plotly::ggplotly()`.
* `phw_plotly()` also draws the empty chart, with its title, axis titles and
  source, for a line, step, error bar, boxplot or point range layer with no
  rows, alone or next to layers with data. Before, plotly stopped with
  errors such as "argument 1 is not a vector" or "'by' must specify a
  uniquely valid column".
* `phw_reactable()` and `phw_plotly()` now bring the Ubuntu web font into
  the page, as `phw_datatable()` and `phw_leaflet()` do. Before, a table
  without a caption and every chart fell back to Arial.
* Leaflet maps draw areas with a missing value in the house grey, matching
  the legend, and give one clear message when a numeric fill has no values
  to colour by.
* `phw_plotly()` colours traces that map `color` with the PHW palette, gives
  heatmaps and contours the PHW sequential scale, and keeps your own
  `annotations`.
* `phw_plotly()` keeps the chart title and axis titles of a `plot_ly()`
  chart, whether set with `layout()` or taken from the columns, and styles
  them in the PHW font and colours. Before, it removed them. A chart with
  one trace no longer gets a legend reading "trace 0": `legend` now sets
  where a legend goes, and only `legend = "none"` decides whether there is
  one.
* `phw_plotly()` with the legend at the bottom places the legend under the
  axis title and the source line under the legend, however many rows the
  legend wraps to and whatever the chart's size. Before, a legend of seven
  health boards ran under the source line, and on a short chart it sat on
  the axis title. Other annotations, including the axis titles of a
  faceted ggplot, stay where they are. A bottom margin you set with
  `margin = list(b = )` is kept as the least space under the chart.
* `phw_plotly(legend = "right")` puts the legend of a ggplot to the right
  of the plot, as it does for a `plot_ly()` chart. Before, a chart with
  `theme_phw()` kept its legend under the chart, as a vertical list next
  to the source line.
* `phw_plotly()` names the legend of a ggplot the way the static chart
  does, with one entry per group. Before, a chart with a second layer in
  the legend, such as `phw_epicurve(average = )` or
  `phw_forest(target = )`, read "(A,1)" and "(3-week average,1)", and the
  forest plot listed each group twice.
* `phw_plotly()` keeps a legend title set with `plotly::layout()`, and the
  legend title a ggplot or `phw_map()` shows. Before, it removed every
  legend title. A ggplot whose theme hides the legend title, as
  `theme_phw()` does, still has none.
* `phw_plotly()` keeps a ggplot's subtitle, under the title, and its
  caption, as the source line under the chart. Before, both were dropped,
  so a chart captioned with `labs(caption = phw_caption(...))` lost its
  source. A `source` or `date` you pass still replaces the caption.
* `phw_plotly()` makes room above the plot for every line of the title and
  subtitle and for the facet strips of a ggplot. Before, the strips were
  drawn over the subtitle, and a subtitle on more than one line ran into
  the plot.
* `phw_plotly()` shows each bar of `phw_pyramid()` on hover by its sex, age
  band and value, formatted as on the axis: "Female, 0-4: 240,000" or
  "Female, 0-4: 25.5%". Before, the left-hand sex read as a negative,
  unrounded number such as "x: -240000". A ggplot that maps the `text`
  aesthetic now shows only that text on hover, as
  `plotly::ggplotly(tooltip = "text")` does.
* `phw_plotly()` gives a chart converted with `plotly::ggplotly()` first
  the same legend names and hover as the ggplot itself. Before,
  `phw_plotly(plotly::ggplotly(g))` read "(Cardiff,1)" and "(Target,1)"
  in the legend, and the hover of `phw_pyramid()` showed the left-hand sex
  as negative values.
* `phw_plotly()` gives ggplots combined with `plotly::subplot()` the same
  legend names as each chart on its own. Before, a panel with an average
  or target line, such as `phw_epicurve(average = )`, read "(Cardiff,1)"
  and "(4-week average,1)". A group now also keeps one colour across the
  panels when a line maps a colour of its own next to filled bars. Before,
  the first group could be navy in one panel and pink in the next.
* `phw_plotly()` draws the secondary axis of a ggplot, such as one from
  `phw_sec_axis()`, on the right (or the top) with its own breaks and
  title, and it stays with its own chart in a `plotly::subplot()` figure
  passed to `phw_plotly()`. Before, the axis was dropped without a word, so
  the second measure was read against the main axis: a positivity of 30%
  read as 184 cases. Hover still shows the second measure in the units of
  the main axis; map the `text` aesthetic to show it in its own. A faceted
  chart can't show the axis and now warns.
* `phw_leaflet_polygons()`, `phw_boundaries()`, `phw_plotly()` and the
  colour key functions check their input first. `phw_boundaries()` checks
  `crs` before downloading anything.
* `phw_key_recolour()` carries `"main"` on into `"extended"` past four
  groups, as `phw_colour_key()` does. It keeps the colour of neutral groups
  such as "Other", including one set with `neutral_colour`. Its new
  `neutral` argument names which groups those are.
* Pointing `phw_key_file()` at another file, or at `NULL`, forgets the keys
  read from the old file. Before, a second report rendered in the same
  session used the first report's colours and saved them into its own key
  file. Keys made before any key file was set are kept.
* `phw_key_set()` changes the accessible copy of a key (`name@accessible`)
  too, when there is one. Before, once a key file held that copy from an
  earlier accessible render, a colour set by hand reached only the default
  version of the report. Colours go into the copy as they do when it is
  first made: a default-palette colour that isn't in `"accessible"` keeps
  the group's accessible colour, or takes the next free one.
* `phw_plotly_colorscale()` and `phw_pal()` take a whole number for `n`.
  Before, `phw_plotly_colorscale(n = 2.5)` made a scale whose last stop was
  0.67, not 1.
* `phw_contrast()`, `phw_text_on()` and `phw_cvd()` return `NA` for a missing
  colour instead of treating it as white, and accept palette names.
* `show_phw_palettes()` picks each swatch's label colour with
  `phw_text_on()`, so mid-tone swatches such as teal, orange and pink get
  dark labels, which contrast more than white.
* `phw_page_navbar(header_args = )` overrides the title and subtitle by name,
  so the logo link keeps its address.
* `phw_bs_theme()` takes Bootstrap version 4 or 5 only.
* `phw_header()` brings its own styles, so the gradient band, white logo and
  Ubuntu titles show on any page. Before, they showed only on a page themed
  with `phw_bs_theme()`, and elsewhere the white logo was invisible.

## Documentation

* The gallery, the demo script and the website articles use larger made-up
  data: line lists in the thousands, weekly and monthly series over several
  years, 22 areas, 5-year age bands and maps of every local authority or
  MSOA. The charts now look as they do on real outputs. Help-page examples
  and the package vignette stay small.

## Requirements

* PowerPoint slides need officer 0.6.7 or later (was 0.6.6).
  `phw_add_slide()` places content in the layout's own placeholders, which
  needs `officer::ph_location_id()`. With officer 0.6.6 it stopped with
  "'ph_location_id' is not an exported object".

# phwstyle 0.3.0

## New charts and maps

* `phw_forest()` draws your own estimates and intervals by unit, sorted by
  value. With `target`, a dashed line marks the target and units are
  coloured and shaped Higher, Similar or Lower. It calculates nothing.
* `phw_map()` joins your data to Welsh boundaries by area code and returns a
  styled choropleth for Word and PDF. Fills can be continuous, binned or
  by group, areas with no data are grey, and the boundary attribution is the
  default caption. It works with `facet_wrap()`. Area labels are moved
  apart when ggrepel is installed.
* `phw_epicurve()` gains `average` and `average_label`, which draw a
  trailing average of the total count as a black line with its own legend
  entry. `$data` gains an `average` column. Its default date labels now
  stay within the data, so the last label is no longer cut off.
* `phw_funnel()` and `phw_spc()` gain `labels`, a named vector that renames
  zones or signals, and pass `...` to their points.

## Tables

* `phw_as_summary()` gives a table you built yourself, for example with
  dplyr, the bold variable rows, indented levels and total rows of the
  built-in summary tables in every renderer.
* `phw_datatable()` now styles summary tables like `phw_reactable()`: bold
  variable, subtotal and total rows, indented levels, and no paging or
  sorting by default.
* `phw_reactable()` rounds numbers like the other renderers: whole-number
  columns show no decimals and other numbers show `digits` (default 1), with
  thousands separators.

## Slides

* `phw_pptx()` opens a bundled 16:9 PHW template with Ubuntu text and navy
  titles. `phw_reference_pptx()` writes it to a file, like
  `phw_reference_docx()`.
* `phw_add_slide()` gains `alt`, the screen-reader text for the chart or
  table, and `caption_args`. It takes the slide master from the layout, so
  your own templates work.
* `phw_add_slide()` makes charts and tables readable on a slide. Chart text
  is enlarged 1.5 times (`plot_scale`), and tables built from a data frame or
  summary grow to fill the content area (`table_fit`). A tall table tightens
  its row spacing so the text can still grow.
* The Quarto extension gains a `phw-pptx` format.

# phwstyle 0.2.0

## Tidyverse-style column arguments

* Functions that take columns now take them the way dplyr does: unquoted
  names, `c(a, b)` for several, and helpers such as `starts_with()`. For
  example `phw_epicurve(cases, onset, group = organism)` and
  `phw_group_table(dat, rows = c(group, type), cols = year)`. They work in a
  pipe after dplyr verbs, and accept tibbles. This covers `phw_epicurve()`,
  `phw_pyramid()`, `phw_funnel()`, `phw_spc()`, `phw_summary_table()`,
  `phw_crosstab()`, `phw_rate_table()`, `phw_risk_table()`,
  `phw_group_table()`, `phw_flextable_heat()`, `phw_flextable_groups()`,
  `phw_flextable_bars()`, `phw_reactable(group_col = )`, `phw_col_bar()`,
  `phw_col_heat()` and `phw_leaflet_polygons()`.
* Code that passes column names as strings keeps working, including names
  held in a variable.
* `phw_leaflet_polygons()` labels and popups can be built from columns, e.g.
  `label = paste(name, rate)`.
* phwstyle now imports tidyselect. The examples, vignettes and starter
  documents are written with dplyr and tidyr.

## Requirements

* phwstyle now needs R 4.3 or later (was 4.1). R 4.3 is the oldest version
  for which Windows users can install, without compiling, versions of
  ggplot2, flextable, rmarkdown and the other packages phwstyle works with.
* DESCRIPTION states the oldest version of each optional package that
  phwstyle works with.

## New palettes

* `"extended"` now has twelve colours instead of eight: the four `"main"`
  colours; then black, green and gold from the NHS Wales logo guidelines and
  the phw.nhs.wales website; then mint and bright green from the Long-Term
  Strategy; then a blue, a dark green and a violet chosen to stay distinct
  from the rest. Every pair stays apart for colour-blind readers. **Charts
  with five or more groups change colour**: the fifth to eighth colours were
  gold, purple, green and grey.
* `"strategy"`: the colours of the six strategic priorities in the
  Long-Term Strategy 2023 to 2035, for work reported by priority.
* `"greens"`: a sequential green palette, from a pale tint to the website
  green, for `scale_*_phw_c()`, `scale_*_phw_b()`, heat tables, maps and
  plotly colour scales.
* New colours in `phw_colours`: `mint` and `green_bright`.

## Changes to default colours

* **The default palette no longer switches to `"accessible"` above four
  groups.** Charts with more than four groups now carry on from `"main"`
  into `"extended"` (navy, teal, orange, pink, then black, green, gold and more), so
  every chart in a report starts with the same colours however many groups
  it has. Before, a five-group chart was drawn in the accessible palette
  next to four-group charts in the main one. This applies everywhere groups
  are coloured: ggplot2 defaults, `scale_*_phw_d()`, `phw_epicurve()`,
  `phw_colour_key()`, `phw_pal()`, `phw_plotly()`, `phw_reactable()`,
  `phw_flextable_groups()` and `phw_leaflet_polygons()`. Charts with five or
  more groups that relied on the old switch will change colour. To keep the
  colour-blind safe palette, switch it on (next item).
* **Accessible colours are now a switch.** Turn it on once and every chart,
  table and widget uses the `"accessible"` palette, for any number of
  groups, so one document can be rendered both ways:
  * R Markdown: new `palette` argument for `phw_html_document()`,
    `phw_word_document()` and `phw_pdf_document()`, e.g.
    `rmarkdown::render("report.Rmd", output_options = list(palette = "accessible"))`.
    The palette is put back when the render finishes.
  * Quarto: `phw-palette: accessible` in the document's YAML header.
  * Any route: the environment variable `PHWSTYLE_PALETTE=accessible`, for
    switching one render from the command line.
  * `use_phw_ggplot(palette = "accessible")` and
    `options(phwstyle.palette = "accessible")` work as before.

  `theme_phw(accessible = TRUE)` (larger text, thicker lines) is separate
  and unchanged: it doesn't change colours, and the palette switch doesn't
  change sizes. See `?phw_default_palette`.
* Colour keys keep a separate copy for the accessible palette, stored as
  `name@accessible` with the groups in the same order, so a keyed chart
  follows the switch and both versions of a report keep their colours
  between runs. A key used with `palette = "accessible"` before this
  version is carried over. `phw_key_reset()` clears both copies.
* `use_phw_ggplot()` now gives the same result on ggplot2 3.5 and 4.0. A
  layer with no colour of its own (`geom_col()`, `geom_line()`,
  `geom_point()`...) is navy on both; before, it was navy on 3.5 but grey
  or near-black on 4.0. Text, reference lines (`geom_hline()` and friends)
  and box plot outlines use the PHW text colour, and box plots and violins
  keep a white fill. Line widths, point sizes and text sizes now match too,
  so `accessible = TRUE` thickens lines on ggplot2 3.5 as well.
* A plot left on the default colours now gets exactly the colours
  `scale_*_phw_d()` would give the same number of groups. Past the end of a
  palette that means spare colours from the other PHW palettes and a
  warning, instead of blended in-between colours.

## Boundaries

* `phw_boundaries("msoa")` and `phw_boundaries("lsoa")` work again. The ONS
  Open Geography Portal stopped publishing the layers they used, so both now
  come from DataMapWales (Welsh Government), with the super generalised ONS
  boundaries as the alternative. MSOAs from DataMapWales have no Welsh
  names, so `name_cy` is missing for them.
* Where a geography is published by more than one source,
  `phw_boundaries()` tries the others if the first cannot be reached, and
  warns which boundaries it returned.
* An area that a source holds as several rows, such as an LSOA with
  islands, is returned as one row.
* `phw_boundaries()` keeps working when a publisher replaces or withdraws a
  layer after phwstyle was installed. If none of the layers it lists can be
  downloaded, it fetches the current list of layers from the phwstyle
  repository and tries those, and failing that returns boundaries saved from
  an earlier release, with a warning in both cases. Set
  `options(phwstyle.boundary_update = FALSE)` to stop it fetching the list.
* The list of layers is now checked every week instead of every month. A
  layer is listed only once a test download works, and a new ONS release is
  used once its generalised boundaries are published, so the default level
  of detail is never lost while a release is part way out.

## Fixes for older versions of other packages

* `use_phw_ggplot()`, and so every `phw_*_document()` R Markdown format, no
  longer fails with "Can't find geom called "histogram"" on ggplot2 older
  than 4.0. The geom defaults are now set one by one, so a geom that an
  installed ggplot2 doesn't have is skipped.
* On ggplot2 older than 4.0, a plot that mapped a variable to `colour` or
  `fill` and had no scale of its own failed with "argument "n" is missing"
  after `use_phw_ggplot()`, which meant most charts in a `phw_*_document()`.
  The default scales are now set up correctly there, and continuous and
  binned defaults use the same blues as on ggplot2 4.0.
* The R Markdown formats no longer stop a whole render if styling the
  charts or the flextables fails. The document is rendered and a warning
  says what was left unstyled and why.
* `phw_gt()` works with gt older than 0.11.1, which doesn't export
  `all_of()`.
* `phw_page_navbar()` works with bslib older than 0.9.0, which has no
  `navbar_options()`.
* `phw_write_xlsx()` no longer fails with "Failed to save workbook" on
  computers where R names a zip program that isn't installed.
* The Quarto `phw-typst` format works with Quarto 1.5 and 1.6. It failed
  there with "unexpected argument: spacing", and top-level headings came out
  numbered "0.1" and too small.
* `phw_pdf_document()` no longer fails on a document with a flextable when
  the Ubuntu font is not installed on the computer. Tables now use the
  bundled font, as the rest of the document does.

## Other changes

* The ready-made charts (`phw_epicurve()`, `phw_pyramid()`, `phw_funnel()`,
  `phw_spc()`) follow the settings given to `use_phw_ggplot()`, such as
  `base_size = 14` or `accessible = TRUE`. Before, they always used the
  `theme_phw()` defaults.
* `vignette("phwstyle")` has a new section, "How the pieces fit together":
  what each function switches on, what you still need to add to a plot
  after setup, and how your own scales and theme settings take priority.
* New `phw_sec_axis()` draws a second measure against its own axis, on linear
  and log scales, without working out the rescaling by hand. `theme_phw()`
  spaces the titles of top and right axes like the bottom and left ones.

# phwstyle 0.1.2

* Resubmission to CRAN. The `phw_datatable()` example no longer opens a
  browser when examples are run non-interactively.

# phwstyle 0.1.1

* First CRAN submission. Fixes the notes from the automated CRAN checks on
  0.1.0 (wording in DESCRIPTION and links in the README).

# phwstyle 0.1.0

* First release.
* Brand colours and palettes (`phw_colours`, `phw_pal()`), with WCAG contrast
  helpers. Every `palette` argument also takes your own colours.
* A colour-blind safe `accessible` palette, `phw_cvd()`, `phw_check_colours()`,
  `scale_shape_phw()` and `scale_linetype_phw()`.
* Colour keys that keep each group's colour across charts and reports
  (`phw_colour_key()`, `scale_*_phw_d(key = )`, `phw_key_file()`).
* Extension geoms styled automatically (`phw_style_extensions()`), and
  multi-plot figures with `phw_arrange()` and `phw_title_grob()`.
  `phw_finalise()` accepts patchworks and grobs.
* Summary tables for reports and epidemiology (`phw_summary_table()`,
  `phw_crosstab()`, `phw_rate_table()`, `phw_risk_table()`,
  `phw_group_table()` for nested row and column groups with group, subgroup
  and table totals), rendered by
  `phw_flextable()` and `phw_reactable()`, plus column formats
  (`phw_flextable_bars()`, `phw_col_bar()`, `phw_col_heat()`, `phw_col_rag()`).
* `phw_plotly()` styles every plotly chart type; `phw_plotly_colorscale()`.
* Public health charts: `phw_epicurve()`, `phw_pyramid()`, `phw_funnel()` and
  `phw_spc()`.
* More outputs: gt (`phw_gt()`, `phw_gt_theme()`), gtsummary
  (`use_phw_gtsummary()`), DT (`phw_datatable()`), leaflet (`phw_leaflet()`,
  `phw_leaflet_polygons()`, `phw_leaflet_palette()`), Excel
  (`phw_write_xlsx()`) and PowerPoint (`phw_pptx()`, `phw_add_slide()`).
* `phw_boundaries()` downloads and caches boundaries for 13 Welsh geographies
  from the ONS Open Geography Portal and DataMapWales, including health boards
  and GP clusters; `phw_boundary_levels()` lists them.
* `phw_setup_check()` lists missing fonts, packages and tools and offers to
  install them.
* Bundled Ubuntu font with Arial fallback (`phw_font()`, `phw_install_fonts()`).
* ggplot2 theme and scales (`theme_phw()`, `theme_phw_map()`,
  `scale_*_phw_*()`, `use_phw_ggplot()`, `phw_finalise()`, `phw_save()`).
* Tables and widgets: `phw_flextable()`, `phw_flextable_heat()`,
  `phw_reactable()`, `phw_plotly()`.
* Shiny: `phw_bs_theme()`, `phw_header()`, `phw_page_navbar()`.
* R Markdown formats: `phw_html_document()`, `phw_word_document()`,
  `phw_pdf_document()`.
* Quarto extension with HTML, Word, Typst, LaTeX PDF, revealjs and dashboard
  formats (`use_phw_quarto()`).
* Captions and dates (`phw_caption()`, `phw_date()`), with every word
  changeable.
