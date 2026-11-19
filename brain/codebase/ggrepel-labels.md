# ggrepel labels

- ggrepel's default `max.overlaps = 10` drops labels it cannot place, without a warning. `phw_map()` sets `max.overlaps = getOption("ggrepel.max.overlaps", Inf)`. `phw_funnel()` still uses the default, but drops only with dozens of outliers on a small chart.
- Where labels end up is only known at draw time, inside ggrepel's `makeContent()`. To check placed labels, subclass the geom so its grob gets an extra class, and add a `makeContent` method that calls `NextMethod()` and then reads the placed `roundrect` children (see `map_label_geom()` in `R/maps.R`). The subclass must forward `parameters()` to the parent geom, or ggplot2 drops ggrepel's parameters.
- To count drawn labels in a test, print to a device, then `grid::grid.force()` and count `textrepelgrob` names in `grid::grid.ls(print = FALSE)`. `grid.force()` runs `makeContent()` again, so wrap it in `suppressMessages()`.
