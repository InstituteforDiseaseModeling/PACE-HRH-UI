library(shiny)



ggplotTabUI <- function(id=NULL, title=NULL) {
  #namespace ns
  #wrap input and output ids with ns
  ns <- NS(id)
  
  tabPanel(title,
           fluidRow(
             style = "margin: 0 5px;",
             plotOutput(ns("plot")),
             div(class="visual-placeholder-xl")
           ))
}


ggplotTabServer <- function(id, plotting_function, rv) {
  moduleServer(id, function(input, output, session) {
    output$plot <- renderPlot({

      if (!is.null(rv$results) ) {
        plot <- do.call(plotting_function, list(rv))
        plot
      }else{
        print("no results")
        NULL
      }
    })
  })
}


