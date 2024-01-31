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
    )
  )
  
}

# Server logic for the view runs module
viewRunsServer <- function(id, store) {
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
    
    
    observeEvent(input$download, {
      # Code to handle the file download
      

    })
  })
}
