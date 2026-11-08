phw_org <- "Public Health Wales"
phw_cdsc <- "Communicable Disease Surveillance Centre"

#' Format a date the PHW way
#'
#' Reports write dates as dd/mm/yyyy in captions ("Data correct as of
#' 03/11/2026") and as "3 November 2026" in text.
#'
#' @param x A Date, or anything [as.Date()] accepts.
#' @param style `"short"` (03/11/2026) or `"long"` (3 November 2026), or a
#'   [format()] string such as `"%B %Y"`.
#' @return A character vector.
#' @examples
#' phw_date(as.Date("2026-11-03"))
#' phw_date(as.Date("2026-11-03"), "long")
#' phw_date(as.Date("2026-11-03"), "%b %Y")
#' @export
phw_date <- function(x, style = "short") {
  x <- as.Date(x)
  if (identical(style, "short")) return(format(x, "%d/%m/%Y"))
  if (identical(style, "long")) {
    return(paste(as.integer(format(x, "%d")), month.name[as.integer(format(x, "%m"))],
                 format(x, "%Y")))
  }
  format(x, style)
}

#' Build a PHW source caption
#'
#' PHW reports put a bold, right-aligned line under each chart and table,
#' such as "Source: Example system, 2024". Surveillance reports add "Data correct as of
#' dd/mm/yyyy". Use the result in `labs(caption = ...)` or pass the same
#' arguments to [phw_finalise()], [phw_flextable()], [phw_reactable()] or
#' [phw_plotly()].
#'
#' Every piece of wording can be changed, so the line can say anything your
#' output needs, in any language.
#'
#' @param source Data source, e.g. `"Example system, 2024"`. Can be `NULL`.
#' @param date Optional extraction date. Adds "Data correct as of ...". A
#'   Date is formatted with `date_format`; a string is used as it is.
#' @param source_prefix,date_prefix Text before the source and the date.
#' @param date_format Passed to [phw_date()] as `style`.
#' @param note Optional extra lines, e.g. a footnote or a team name.
#' @param sep How the lines are joined. Use `" | "` for a single line.
#' @return A string, or `NULL` if there is nothing to show.
#' @examples
#' phw_caption("Example system, 2024")
#' phw_caption("Sentinel GP network", date = as.Date("2026-11-03"))
#' phw_caption("Example system", source_prefix = "Data: ", note = "Provisional figures")
#' @export
phw_caption <- function(source = NULL, date = NULL, source_prefix = "Source: ",
                        date_prefix = "Data correct as of ", date_format = "short",
                        note = NULL, sep = "\n") {
  parts <- character()
  if (!is.null(source)) parts <- c(parts, paste0(source_prefix, source))
  if (!is.null(date)) {
    d <- if (inherits(date, c("Date", "POSIXt"))) phw_date(date, date_format) else date
    parts <- c(parts, paste0(date_prefix, d))
  }
  parts <- c(parts, note)
  if (!length(parts)) return(NULL)
  paste(parts, collapse = sep)
}

#' Number formatting in PHW style
#'
#' Thousands separated with commas and a fixed number of decimals.
#'
#' @param accuracy Rounding, as in [scales::label_number()].
#' @param ... Passed to [scales::label_number()] or [scales::label_percent()].
#' @return A labelling function.
#' @examples
#' phw_number()(c(1234.5, 98765))
#' phw_percent()(0.432)
#' @export
phw_number <- function(accuracy = 1, ...) {
  scales::label_number(accuracy = accuracy, big.mark = ",", ...)
}

#' @rdname phw_number
#' @export
phw_percent <- function(accuracy = 0.1, ...) {
  scales::label_percent(accuracy = accuracy, big.mark = ",", ...)
}

# Pull caption arguments out of `...` so wrappers can forward them.
caption_from <- function(source, date, caption_args) {
  do.call(phw_caption, c(list(source = source, date = date), caption_args))
}
