# phwstyle (development version)

This release makes every function check what it is given. Where a call
used to draw a wrong chart, drop content without a word or fail inside
another package, it now does the right thing or stops with a message that
says what to change.

## Changes that may affect existing code

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
  also stops on a numeric date column.
* Rows with a missing date, count, value, estimate or code are left out with
  one message saying how many. Before, they could turn a whole period into 0
  or blank a chart. `phw_crosstab(missing = NULL)` and
  `phw_group_table(missing = NULL)` now also say how many rows they leave out
  for a missing row or column value. `phw_rate_table()` and
  `phw_risk_table()` handle missing values as before.
* `phw_reactable()` rows are no longer striped by default, to match the
  other tables. Pass `striped = TRUE` to stripe them.
* `phw_add_slide()` stops when given more content than the layout has room
  for, instead of silently using only the plot. It also refuses a chart or
  table on the navy Title Slide and Section Header layouts.
* A group with an empty name (`""`) stops `phw_colour_key()` and the PHW
  colour scales. Give it a label, or make it `NA` to show it as missing.
* `phw_map()` stops when every fill value is missing.
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
  numbers, and are split at the breaks you give, or at about that many tidy
  breaks for a single number. Before, an area below the first break or
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
* `phw_map(bins = 2)` and `phw_leaflet_polygons(bins = 2)` split the areas
  into two classes at a tidy break near the middle of the data. Before,
  they drew every area in one colour.
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
  `palette`, as in a `plot_ly()` chart. Before, `palette` was ignored for a
  ggplot and its groups always had the default palette.
* `phw_plotly()` gives a figure combined with `plotly::subplot()` the PHW
  colours. Before, it kept plotly's default colours: groups, traces with no
  colour mapping and heatmaps all came out in plotly's palettes. A group
  now has the same colour in every panel. If a panel sets its own colours,
  `phw_plotly()` keeps them and says how to give the other panels PHW
  colours.
* `phw_plotly()` draws a missing group (`NA`) in grey in a figure combined
  with `plotly::subplot()`, as it does in a single chart. Before, its lines,
  bars and markers were invisible and its legend entry had no colour.
* `phw_plotly()` draws rows with a missing group in grey when the chart
  sets `colors = phw_colour_key(...)`. Before, they were invisible: the
  legend showed "NA" with no line or markers. A key that gives `"NA"` its
  own colour keeps it.
* With `palette = "rag"` or `"rag_accessible"`, groups called "Red",
  "Amber" and "Green" (in any case) take the red, amber and green colours,
  whatever order they sort in. Before, they took the colours in sorted
  order, so Red was drawn green, Amber red and Green amber. The same holds
  for the named colours of `"strategy"` and for a named vector of colours,
  in every chart, map and table, with `reverse = TRUE` too. A colour key
  that had stored the wrong colour for such a group is corrected. Colours
  pinned with `values` or `fixed` still win.

## Charts and maps

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
* `phw_pyramid()` shows every level of the `age` factor, so an age band
  with nobody in it stays on the axis as a gap. Before, it was dropped when
  `data` had one row per person, or no row for that band.
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
* `phw_finalise()` on a `phw_arrange()` figure keeps every panel, the
  figure title and the panel tags. Before, only the last panel was kept.
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

* Summary and group tables look the same in `phw_flextable()`, `phw_gt()`,
  `phw_reactable()`, `phw_datatable()` and `phw_write_xlsx()`. Variable rows
  are shaded unless `highlight = FALSE`. `phw_datatable()` gains the
  spanner, two-level column headers, group separators and right-aligned
  statistics.
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
* `phw_datatable()` keeps the `columnDefs` you give in `options` for a
  summary table. Before, the table's own column settings replaced them.
* `phw_datatable()` accepts columns renamed with a named `colnames`, such as
  `colnames = c(Cases = "cases")`, and still rounds the numbers and styles
  a summary table's renamed columns. Before, it stopped with an error from
  DT, or a summary table lost the styling of a renamed column.
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
* `phw_flextable_heat(symbols = TRUE)` keeps the table's number format, so
  `phw_flextable(digits = 1)` shows "▼ 92.3", not "▼ 92.34568".
* On a summary, cross-tab or group table, `phw_flextable_heat()` and
  `phw_col_heat()` colour only the level rows. Before, totals and subtotals
  were coloured too and set the top of the scale, so every other cell came
  out pale, and headings lost their grey band in the coloured columns.
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
* `phw_gt(gt_args = list(rowname_col = ))` takes a summary, cross-tab or
  group table's column name as it prints, such as `"Characteristic"`, and a
  label column used as row names keeps its indents, bold headings and navy
  header. A name that is not a column stops with a message listing the
  columns. `groupname_col` stops with a message on these tables, because
  their label columns name a group on its first row only. Before, any column name failed inside gt
  with a list of columns the table does not show.
* `phw_group_table(drop = FALSE)` keeps factor levels that have no records,
  such as an empty age band or year, as rows and columns of zeros, as
  `phw_crosstab()` does. Before, it left them out.
* `phw_flextable()`, `phw_gt()`, `phw_reactable()`, `phw_datatable()` and
  `phw_write_xlsx()` show a `phw_group_table()` with the decimal places
  set by its `digits`, unless you give them their own `digits`. Before,
  `digits` was ignored without `percent`, so `fun = mean` values showed
  with one decimal place.
* `phw_summary_table()` shows a blank, not "( to )", when a statistic can't
  be calculated, and `labels` can be a named character vector.
* Filtering the rows of a summary, cross-tab or group table, or selecting
  some of its columns, with `[`, `head()`, `subset()` or dplyr's
  `filter()`, `slice()`, `arrange()` and `select()`, keeps the bold
  headings, indents, rules and column headers on the rows and columns
  kept. Before, every renderer styled the wrong rows or stopped with an
  error. A table without its label columns becomes a plain data frame. A
  table whose rows no longer match its styling, for example after
  `rbind()`, stops with a message suggesting `as.data.frame()`.
* `phw_rate_table()` stops with a message naming the column when the count
  or population column is text, instead of failing inside `sum()`.
* Table and column helpers give clear errors for duplicated column names,
  negative bar values, a data frame where a flextable is needed, or an
  unknown style.

## Slides and documents

* A grey PNG logo with transparency now works like a colour one in
  `phw_finalise()`, `phw_word_document()`, `phw_pdf_document()`,
  `phw_latex_header()`, `phw_reference_docx()` and `use_phw_quarto()`.
  Before, it stopped with "a raster array must have exactly 3 or 4 planes".
* `phw_add_slide()` places content on every layout. Two Content fills the
  left side first, and Title Only and Blank place the chart, table or text
  in the free space.
* `phw_add_slide()` puts content into a layout's content placeholders and
  leaves text-only ones empty, so on a template's Comparison layout the chart
  and table fill the left and right areas. Before, the first went into the
  small heading above the left area.
* `phw_add_slide()` checks its arguments before it adds a slide, so a call
  that stops leaves the deck unchanged. It warns when a table has more rows
  than fit on the slide, and accepts a `phw_finalise()` chart as a picture.
* `phw_add_slide(table_fit = TRUE)` no longer grows a table that fits the
  slide until it runs off the bottom. Before, tables of about 10 to 12 rows
  grew past the content area, and the warning asked you to split them. A
  cell with more than one line now counts as that many lines when the table
  is sized.
* `phw_add_slide(table_fit = TRUE)` no longer narrows the columns of a table
  that is wider than the content area until numbers and labels break across
  lines. It shrinks the text instead, down to 8 points. A table still too
  wide at 8 points keeps its column widths and gives a warning that names
  how many columns it has.
* `phw_add_slide()` scales the text of a `phw_arrange()` figure as one: every
  panel, the figure title and the source line. Before, only the last panel
  was scaled.
* A flextable's caption, such as "Table 1 ..." from `phw_flextable()`, now
  shows on a `phw_add_slide()` slide, in a row at the top of the table.
  Before, PowerPoint left it out without a word.
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
* `phw_pdf_document()` keeps the `dev` you give it instead of always using
  `"ragg_png"`.
* `phw_pdf_document()` uses `fontsize`, `documentclass`, `geometry` and
  `colorlinks` from the YAML header or from `pandoc_args` in place of the PHW
  ones. Before, the PHW values silently won, and a `fontsize` in
  `pandoc_args` gave LaTeX an option it doesn't know, so the text was 10pt.
* `phw_download_logos()` saves nothing when the reply isn't an SVG.

## Interactive outputs and colours

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
* `phw_leaflet_polygons()`, `phw_boundaries()`, `phw_plotly()` and the
  colour key functions check their input first. `phw_boundaries()` checks
  `crs` before downloading anything.
* `phw_key_recolour()` carries `"main"` on into `"extended"` past four
  groups, as `phw_colour_key()` does. It keeps the colour of neutral groups
  such as "Other", including one set with `neutral_colour`. Its new
  `neutral` argument names which groups those are.
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
