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
  
  ### initialize variables used in simulation steps
  rv <- reactiveValues(page = 1, 
                       region_changed = FALSE,
                       input_file = config_file
  )
 
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # set uid to reactiveValues
    js_code = sprintf("
                function set_uid(){
                  if (localStorage.getItem('uid')) {
                    return localStorage.getItem('uid');
                  } 
                  else {
                    v = (Math.random() + 1).toString(36).substring(7);
                    localStorage.setItem('uid', v);
                    return v;
                  }
                }
                var uid = set_uid(); 
                Shiny.setInputValue('%s', uid);", ns("uid"))
    print(gsub("\n", "", js_code))
    shinyjs::runjs(gsub("\n", "", js_code))
    
    observeEvent(input$uid, {
      # create a inputfile for the current user based on uid 
      prefix <- unlist(strsplit(config_file, "\\."))[1]
      rv$input_file <- paste0(prefix, "_", input$uid, ".xlsx")
      rv$uid <- input$uid
      
      if (!file.exists(rv$input_file)){
        file.copy(config_file, rv$input_file, overwrite = TRUE)
      }
      ### Simplfy to assume only one scenario case
      rv$scenarios_sheet <- "Scenarios"
      rv$scenarios_input <- first(read_excel(rv$input_file, sheet = "Scenarios"))
    })
    
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
      # set up user config file 
      
    })
    
    observeEvent(input$view_runs, {
      updateNavbarPage(session, inputId = "header_options", selected = "View Previous Results")
    })
  })
  runSimulationServer("sim1", return_event = switchToResultEvent, rv =rv, store = store)
  viewRunsServer("view_runs1", rv = rv, store = store)
}

