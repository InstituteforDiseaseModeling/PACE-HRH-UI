library(shinythemes)
library(shiny)

# load global variables if they don't already exist
if (!exists("desc_content")) {
  source("global.R")
}

headerUI <- function(id) {

  # wrap input and output ids with ns
  # namespace ns
  ns <- NS(id)

  navbarPage(
    id = ns("header_options"),
    #------------------------
    # load project title from global.R
    {
      project_title
    },
    #------------------------
    theme = shinytheme("flatly"),
    # theme = shinytheme("united"),
    tabPanel(
      "Home",
      # homeUI("home-page")
      fluidPage(
        tagList(
          tags$br(),
          actionButton(ns("run_simulation"), "Run new simulation", class='menuButton'),
          tags$br(),
          tags$br(),
          tags$br(),
          actionButton(ns("view_runs"), "View previous runs", class='menuButton'),
        ))
    ),
    navbarMenu("Options",
               tabPanel("Run Simulation", runSimulationUI("sim1")),
               tabPanel("View Previous Results", viewRunsUI("view_runs1")),
               selected = NULL,
               ),
    
    tabPanel(
      "About",
      aboutUI("about-page")
    ),
    selected = NULL,
    position = "fixed-top",
    fluid = TRUE,
    collapsible = TRUE
  )
}

headerServer <- function(id, store=NULL) {
  aboutServer("about-page")
  
  # Reactive value to trigger a when return to result
  switchToResultEvent <- reactiveVal(FALSE)
  
  moduleServer(id, function(input, output, session) {
    
    # Observe the event and switch to result
    observeEvent(switchToResultEvent(), {
      if(switchToResultEvent()) {
        updateNavbarPage(session, inputId = "header_options", selected = "View Previous Results")
        switchToResultEvent(FALSE)  # Reset the event
      }
    })
    
    # navbarPage functions
    observeEvent(input$run_simulation, {
      updateNavbarPage(session, inputId = "header_options", selected = "Run Simulation" )
      # print(input$store$unique_uid)
    })
    
    observeEvent(input$view_runs, {
      updateNavbarPage(session, inputId = "header_options", selected = "View Previous Results")
    })
  })
  runSimulationServer("sim1", config_file, return_event = switchToResultEvent, store = store)
  viewRunsServer("view_runs1", store)
}

