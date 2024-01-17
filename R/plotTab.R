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


plotTabServer <- function(input, output, session, plotting_function, rv) {

    output$plot <- renderPlotly({

      if (!is.null(rv$results) ) {
        plot <- do.call(plotting_function, list(rv))
        plot %>%  layout(height = 800)
      }else{
        print("no results")
        NULL
      }
    })
}


