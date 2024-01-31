# UI for the view runs module
viewRunsUI <- function(id) {
  ns <- NS(id)
  fluidPage(
    shinyjs::useShinyjs(),
    fluidRow(
      column(12, 
             tagList(
                selectInput(ns("run_selector"), "Choose a Run To view", choices =NULL),
                downloadButton(ns("download"), "Download")
            )
      )
    ),
    tabsetPanel(
      id = "main-tabs",
      # --------Insert tabs UI calls here, comma separated --------
      plotTabUI(id = ns("population-tab"),
                title = "Population"),
      plotTabUI(id = ns("fertility-tab"),
                title = "Fertility"),
      plotTabUI(id = ns("slide-4-tab"),
                title = "By Clinical Category"),
      plotTabUI(id = ns("by-ServiceCat-tab"),
                title = "By Service Category"),
      ggplotTabUI(id = ns("by-ServiceTile-tab"),
                  title = "By Service Category Tiles"),
      plotTabUI(id = ns("service-over-time-tab"),
                title = "Service change over time"),
      plotTabUI(id = ns("seasonality-tab"),
                title = "Seasonality"),
    ),
  )
  
}

# Server logic for the view runs module
viewRunsServer <- function(id, rv, store) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    autoInvalidate <- reactiveTimer(2000)
    observe({
      autoInvalidate()
      js_code <- "
      var arr = [];
      var test_names = JSON.parse(localStorage.getItem('test_names')) || [];
      for (let i = 0; i < test_names.length; i++) {
       arr.push(test_names[i].name)
      }
      Shiny.setInputValue('%s', arr);
      "
      shinyjs::runjs(sprintf(js_code, ns("test_names_loaded")))  
      updateSelectInput(session, "run_selector",
                        label = "Choose a Run To view",
                        choices = input$test_names_loaded,
      )
    })
    
    observe ({
        plotTabServer(
        id = "population-tab",
        plotting_function = "get_population_plot",
        rv = rv)
      
        plotTabServer(
        id = "fertility-tab",
        plotting_function = "get_fertility_rates_time_series_plot",
        rv = rv)
  
        plotTabServer(
        id = "slide-4-tab",
        plotting_function = "get_slide_4_plot",
        rv = rv)
      
        plotTabServer(
        id = "by-ServiceCat-tab",
        plotting_function = "byServiceCat_plot",
        rv = rv)
      
        ggplotTabServer(
        id = "by-ServiceTile-tab",
        plotting_function = "byServiceTile_plot",
        rv = rv)
      
        plotTabServer(
        id = "service-over-time-tab",
        plotting_function = "serviceOverTime_plot",
        rv = rv)
      
        plotTabServer(
        id = "seasonality-tab",
        plotting_function = "seasonality_plot",
        rv = rv)
    })
    
    observeEvent(input$download, {
      # Code to handle the file download
      

    })
  })
}
