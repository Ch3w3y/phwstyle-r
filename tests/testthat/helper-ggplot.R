# ggplot2::get_labs() arrived after 3.5.1. Before it, the labels sit on the plot.
plot_labs <- function(p) {
  if (exists("get_labs", envir = asNamespace("ggplot2"), inherits = FALSE)) ggplot2::get_labs(p) else p$labels
}
