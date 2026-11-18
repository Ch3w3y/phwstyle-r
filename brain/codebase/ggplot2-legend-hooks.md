# Choosing a legend for every chart

- **A theme can't choose a legend.** No theme element sets `nrow` or the guide class, and ggplot2 4.0 resolves each scale's guide (`Guides$setup()`) before any palette runs, so a theme palette that receives the scale as `self` is too late to change `self$guide`.
- **The `ggplot2.discrete.*` options clash with theme palettes on 4.0.** `theme()` warns "options(...) setting is incompatible with the palette theme setting" whenever a discrete palette element is set while the option is set, so `use_phw_ggplot()` sets those options only before 4.0. Every later `theme_phw()` would warn.
- So `wrap_legends()` swaps in `phw_guide_legend()` where phwstyle draws a chart: `phw_save()`, `phw_finalise()`, `phw_arrange()`, `phw_add_slide()`, and knitr's `render` chunk option in the `phw_*_document()` formats. Plain `print()`, `ggsave()` and Quarto don't go through it.
- A guide's `draw()` runs while the target device is open, so `grid::unit(1, "npc")` there is the width the chart is drawn at. `phw_finalise()` builds its gtable before that size is known, so `makeContext.phw_finalised()` builds it again when drawn.
- knitr's default `render` adds the class `knit_asis_htmlwidget` to htmlwidget output (for figure captions); a custom `render` has to do the same.
