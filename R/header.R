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
          actionButton(ns("run_previous_config"), "Run from previous config", class='menuButton'),
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
                       input_file = global_config_file,
                       scenarios_sheet = "Scenarios",
                       folder_df = NULL,
                       selected_config_path = NULL,
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
      rv$input_file <-  reload_config(input$uid) 
      rv$uid <- input$uid
      ### Simplfy to assume only one scenario case
      rv$scenarios_input <- first(read_excel(rv$input_file, sheet = rv$scenarios_sheet))
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
      
      rv$input_file <-  reload_config(input$uid)
      rv$scenarios_input <- first(read_excel(rv$input_file, sheet = rv$scenarios_sheet))
      updateNavbarPage(session, inputId = "header_options", selected = "Run Simulation" )
      # set up user config file 
      
    })
    
    observeEvent(input$run_previous_config, {
      rv$folder_df <- get_result_folders_dt()
      if (!is.null(rv$folder_df) & nrow(rv$folder_df) > 0){
        # populate previous run config, let user select it as config
        showModal(
          modalDialog(
            title = "Select config file from previous run",
            "Please note that the region data is not supported.",
            DTOutput(ns("dt_select_prev_config")),
            footer = tagList(
              actionButton(ns("proceedPrevConfigBtn"), "Proceed"),
              modalButton("Cancel")
            )
          )
        )
      }
      else{
        showModal(
          modalDialog(
            title = "Unable to use previous config",
            "You did not have any previous results available yet, please start a new simulation.",
          )
        )
      }
    })
    
    # Render the folder table using DT
    
    output$dt_select_prev_config <- renderDT({
      datatable(rv$folder_df, selection = 'single')
    })
    
    # Store the selected config file path
    observeEvent(input$dt_select_prev_config_rows_selected, {
      rv$selected_config_path <- renderText({
        req(input$dt_select_prev_config_rows_selected)
        selected_row <- input$dt_select_prev_config_rows_selected
        file.path(result_root, rv$folder_df[selected_row, "run_name"], "config.xlsx")
      })
    })

    # Handle the previously used config scenario 
    observeEvent(input$proceedPrevConfigBtn, {
      removeModal()
      if (!is.null(rv$selected_config_path())){
        rv$input_file <- reload_config(input$uid, rv$selected_config_path())
        rv$scenarios_input <- first(read_excel(rv$input_file, sheet = rv$scenarios_sheet))
        updateNavbarPage(session, inputId = "header_options", selected = "Run Simulation" )
      }
    })
    
    
    observeEvent(input$view_runs, {
      updateNavbarPage(session, inputId = "header_options", selected = "View Previous Results")
    })
  })
  runSimulationServer("sim1", return_event = switchToResultEvent, rv =rv, store = store)
  viewRunsServer("view_runs1", rv = rv, store = store)
}

