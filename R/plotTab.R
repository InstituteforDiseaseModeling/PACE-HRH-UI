library(shiny)



plotTabUI <- function(id=NULL, title=NULL) {
  #namespace ns
  #wrap input and output ids with ns
  ns <- NS(id)
  
  tabPanel(title,
           fluidRow(
             style = "margin: 0 5px;",
             plotlyOutput(ns("plot")),
             # div(class="visual-placeholder-xl")
           ))
}


plotTabServer <- function(id, plotting_function, rv) {
    moduleServer(id, function(input, output, session) {
    output$plot <- renderPlotly({

      if (!is.null(rv$results) ) {
        plot <- do.call(plotting_function, list(rv))
        plot %>%  layout(height = 800)
      }else{
        print("no results")
        NULL
      }
    })
  })
}


# Define the simple plot Module without tabpanel
simpleplotUI <- function(id,title) {
  ns <- NS(id)
  plotOutput(ns("plot"))
}

simpleplotServer <- function(id, plotFunction, rv) {
  moduleServer(id, function(input, output, session) {
    output$plot <- renderPlot({
      plotFunction(rv)  # Call the function to get the ggplot object
    })
  })
}
