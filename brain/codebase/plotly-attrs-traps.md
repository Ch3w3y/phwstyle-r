# plotly attrs traps

What `phw_plotly()` has to know about an unbuilt `plot_ly()` object.

- Each entry of `p$x$attrs` is evaluated against the data stored under its own name: `plotly::plotly_data(p, names(p$x$attrs)[i])`. There is no `visdat` field on an attr. Reading `visdat[[1]]` gives every `add_trace(data = ...)` trace the first trace's data.
- Discrete `color` mapping uses only the first trace's `colors`, for every trace. Give all traces one shared vector.
- A named `colors` vector is matched by name (`scales::col_factor(levels = names(pal))`). An unnamed one is spread over all levels, unused ones included, and interpolated when it is shorter.
- Missing values are always `transparent`: `map_color()` hard-codes `na.color`. Map them to an "NA" group instead. plotly already names that trace "NA".
- `phw_colour_key()` overflow warnings fire at most once every 8 hours, so a test that expects one needs `withr::local_options(rlib_warning_verbosity = "verbose")`. With verbose on, it warns once per overflow group: use `capture_warnings()`, not `expect_warning()`.
- A `subplot()` figure is already built: `p$x$data` holds the traces and `p$x$attrs` are marked `plotly_eval` with no data left to evaluate them. plotly marks the colours it picked with the classes `colorway` (no colour mapping) and `plotly_default` (groups, scales). `colors =` and `I()` colours are `plotly_default` too, so the attrs are the only way to tell them apart. `plotly_default` also marks non-colours such as `colorbar$title` and numeric `marker$color`.
- When you replace a classed value, keep its class. A plain value makes plotly think the user set `marker` or `textfont`, and it warns and adds them to the trace's `mode`.
- `plotly_build()` merges `p$x$layout` and each `layout()` call with `modify_list()`: a list value replaces a string one, so `title = list(font = ...)` deletes a string title's text. An axis title from `x = ~col` is set with `%||%` after the merge, so any `xaxis$title` you set blocks it. Colour axis titles with the axis `color` instead: plotly.js uses it as the default title and tick label colour. Those automatic titles carry the class `plotly_default`, so compare them with `unclass()` in tests.
- Leave `showlegend` unset unless you mean it. plotly sets it to `sum(trace showlegend) > 1` (or a single pie) only when nothing set it before.
