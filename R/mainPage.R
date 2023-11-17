library(shiny)
library(shinyBS)
library(pacehrh)
source("R/utils.R")

input_file <- load_working_config()
pacehrh::SetInputExcelFile(input_file)

perform_cleanup <- function(){
  if (file.exists(input_file)) {
    file.remove(input_file)
  }
  if (file.exists(file.path("working_config", "model_inputs.xlsx"))){
    file.remove(file.path("working_config", "model_inputs.xlsx"))
  }
}

#optional perform cleanup 
onStop(function() {
  perform_cleanup()
})

mainPageUI <- function(id) {
  ns <- NS(id)
  
  
  fluidRow(
    fluidRow(
      column(12,
             tags$h4(
              "Optioin A: Download Original Config, edit, and upload to run simulations" 
             ),
             tags$small("Original Config is loaded by default when the page is loaded"),
             ),
    
      column(
        6, 
        tags$div(
          class="btn btn-default action-button",
          tags$a(href = "https://github.com/InstituteforDiseaseModeling/PACE-HRH/raw/main/config/model_inputs_demo.xlsx", download = "model_inputs.xlsx", "Download Original Config")
          
        )
              ),

      column(
        12, 
        fileInput(ns("upload"),"Upload edited config", accept=c(".xlsx")),
      ),
      column(12,
             tags$h4(
               "Option B: Load Original Config by clicking 'Reset'" 
             )),
      
    ), 

    controllerUI("controller", input_file),
    loggerUI("logger"),
    tabsetPanel(
      id = "main-tabs",
      # --------Insert tabs UI calls here, comma separated --------
      plotTabUI(id = "population-tab",
                title = "Population"),
      plotTabUI(id = "fertility-tab",
                title = "Fertility"),
      plotTabUI(id = "slide-4-tab",
                title = "By Clinical Category"),
      plotTabUI(id = "by-ServiceCat-tab",
                title = "By Service Category"),
      ggplotTabUI(id = "by-ServiceTile-tab",
                title = "By Service Category Tiles"),
      plotTabUI(id = "service-over-time-tab",
                title = "Service change over time"),
      plotTabUI(id = "seasonality-tab",
                title = "Seasonality"),
      ValidateUI(id = "v1",
                 title = "Validation Report"),
      # ------------------------------------------------------------
    ),
  )
}

mainPageServer <- function(id, store = NULL) {

  #where collated simulation result tables and scenario names will be stored
  rv <- reactiveValues()
  
  
  controllerValues <-
    controllerServer("controller", store, input_file)
  
  
  observeEvent(controllerValues()$simulate, {
    #-----Insert tab plotting logic calls here --------
    # the id's here must match those inside the UI portion of the code
    # the plotting_function names must match those insde the plotting scripts
    
    
    callModule(
      plotTabServer,
      id = "population-tab",
      plotting_function = "get_population_plot",
      rv = rv
    )
    
    callModule(
      plotTabServer,
      id = "fertility-tab",
      plotting_function = "get_fertility_rates_time_series_plot",
      rv = rv
    )
    
    callModule(
      plotTabServer,
      id = "slide-4-tab",
      plotting_function = "get_slide_4_plot",
      rv = rv
    )
    
    callModule(
      plotTabServer,
      id = "by-ServiceCat-tab",
      plotting_function = "byServiceCat_plot",
      rv = rv
    )
    
    callModule(
      ggplotTabServer,
      id = "by-ServiceTile-tab",
      plotting_function = "byServiceTile_plot",
      rv = rv
    )
    
    callModule(
      plotTabServer,
      id = "service-over-time-tab",
      plotting_function = "serviceOverTime_plot",
      rv = rv
    )
    
    callModule(
      plotTabServer,
      id = "seasonality-tab",
      plotting_function = "seasonality_plot",
      rv = rv
    )
    # -------------------------------------------------
  })
  
  observeEvent(controllerValues()$validate,{
    callModule(
      ValidateServer,
      id = "v1",
      filename=input_file
    )
  })
  
  
  moduleServer(id, function(input, output, session) {
    

    observeEvent(input$upload, {

      if (!is.null(input$upload)){
        file.copy(input$upload$datapath, input_file, overwrite = TRUE)
        session$reload()
        }
      
    })
    
    observeEvent(controllerValues()$simulate, {
      scenarios <- controllerValues()$scenarios
      num_trials <- controllerValues()$num_trials
      year_range <- controllerValues()$year_range
      
      response <-
        run_pacehrh_simulation(scenarios, num_trials, year_range, input_file = input_file)
      #map the key value pairs from the response to the reactive value
      keys <- names(response)
      
      for (key in keys) {
        rv[[key]] <- response[[key]]
      }
      
    })
  })
  
  
}
