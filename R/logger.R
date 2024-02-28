library(shiny)
library(shinyBS)
library(shinycssloaders)



loggerUI <- function(id){
  ns <- NS(id)
  fluidRow(
    shinyjs::useShinyjs(),
      div(
        id = ns("log"),
        div(class= "log-header",
          tags$div(tags$h5("Pace-HRH UI Logs")
        )),
      tags$div(class="log-content", shinyBS::bsAlert("log-display")),
    ),
  )
}


loggerServer <- function(id, message=NULL){
  moduleServer(id, function(input, output, session) {
    current_session <- shiny::getDefaultReactiveDomain()
    shinyBS::  createAlert(
      current_session,
      "log-display",
      content = message,
      append = TRUE,
      dismiss = FALSE
    )
  })
}