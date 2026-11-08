# Example PHW-branded Shiny app.
# Run with: shiny::runApp(system.file("examples", "shiny", package = "phwstyle"))
library(shiny)
library(bslib)
library(ggplot2)
library(phwstyle)

use_phw_ggplot(base_size = 13)

set.seed(1)
hb <- paste("Area", LETTERS[1:7])
weekly <- expand.grid(week = 1:26, board = hb)
weekly$rate <- round(30 + 20 * sin(weekly$week / 4) + rnorm(nrow(weekly), 0, 6) +
                       as.integer(factor(weekly$board)) * 2, 1)

ui <- phw_page_navbar(
  title = "App title",
  subtitle = "Team name",
  nav_panel(
    "Overview",
    layout_sidebar(
      sidebar = sidebar(
        title = "Filters",
        selectInput("board", "Area", choices = hb, selected = hb[1:3], multiple = TRUE),
        sliderInput("weeks", "Weeks", min = 1, max = 26, value = c(1, 26))
      ),
      layout_column_wrap(
        width = 1 / 3, fill = FALSE,
        value_box("Highest value this week", textOutput("top"), theme = "primary"),
        value_box("Areas above 50", textOutput("above"), theme = "info"),
        value_box("Weeks shown", textOutput("nweeks"), theme = "light")
      ),
      layout_columns(
        col_widths = c(7, 5),
        card(card_header("Value by week"), plotOutput("trend")),
        card(card_header("Latest week"), reactable::reactableOutput("table"))
      )
    )
  ),
  nav_panel("By area", card(card_header("Small multiples"), plotOutput("facets", height = 520)))
)

server <- function(input, output, session) {
  d <- reactive(subset(weekly, board %in% input$board & week >= input$weeks[1] & week <= input$weeks[2]))
  latest <- reactive(subset(d(), week == max(week)))
  output$top <- renderText(max(latest()$rate))
  output$above <- renderText(sum(latest()$rate > 50))
  output$nweeks <- renderText(diff(input$weeks) + 1)
  output$trend <- renderPlot({
    ggplot(d(), aes(week, rate, colour = board)) + geom_line(linewidth = 1) +
      scale_colour_phw_d(key = "area") +
      labs(x = "Week", y = "Value", caption = phw_caption("Example data"))
  }, res = 96)
  output$table <- reactable::renderReactable({
    l <- latest()[, c("board", "rate")]
    names(l) <- c("Area", "Value")
    phw_reactable(l, compact = TRUE, group_col = "Area", key = "area")
  })
  output$facets <- renderPlot({
    ggplot(weekly, aes(week, rate)) +
      geom_area(fill = phw_col("light_teal"), alpha = 0.5) +
      geom_line(colour = phw_col("navy"), linewidth = 0.8) +
      facet_wrap(~board, ncol = 4) +
      labs(x = "Week", y = "Value")
  }, res = 96)
}

shinyApp(ui, server)
