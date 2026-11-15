# plotly attrs traps

What `phw_plotly()` has to know about an unbuilt `plot_ly()` object.

- Each entry of `p$x$attrs` is evaluated against the data stored under its own name: `plotly::plotly_data(p, names(p$x$attrs)[i])`. There is no `visdat` field on an attr. Reading `visdat[[1]]` gives every `add_trace(data = ...)` trace the first trace's data.
- Discrete `color` mapping uses only the first trace's `colors`, for every trace. Give all traces one shared vector.
- A named `colors` vector is matched by name (`scales::col_factor(levels = names(pal))`). An unnamed one is spread over all levels, unused ones included, and interpolated when it is shorter.
- Missing values are always `transparent`: `map_color()` hard-codes `na.color`. Map them to an "NA" group instead. plotly already names that trace "NA".
- `phw_colour_key()` overflow warnings fire at most once every 8 hours, so a test that expects one needs `withr::local_options(rlib_warning_verbosity = "verbose")`. With verbose on, it warns once per overflow group: use `capture_warnings()`, not `expect_warning()`.
