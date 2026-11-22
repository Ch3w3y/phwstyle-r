# Quarto htmlwidget sizing

- knitr gives an htmlwidget `out.width.px = fig.width * dpi` (before `fig.retina`). The extension's `dpi: 200` makes that 1500 x 900 px at the default 7.5 x 4.5 in.
- Quarto's `fig-responsive: true` (default on in HTML and dashboards, off in revealjs) patches `htmlwidgets:::resolveSizing` to `width: 100%` and `height = height / width * 650` px. So `phw-html` widgets are 390 px high, and `phw-revealjs` sets `fig-responsive: true` for the same result (#466).
- Side effect: a widget's own height is divided by knitr's 1500 px width, not Quarto's assumed ~672, so `plot_ly(height = 400)` shows at 173 px (#472).
- The patch lives in Quarto's `share/rmd/execute.R` (`apply_responsive_patch`) from 1.5 on. Revealjs leaves the `img-fluid` class it adds to static images unstyled, so static figures don't change.
- Check sizes in the rendered HTML: `grep -o 'class="[a-z]* html-widget[^>]*style="[^"]*"'`.
