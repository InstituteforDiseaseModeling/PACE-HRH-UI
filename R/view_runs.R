# UI for the view runs module
viewRunsUI <- function(id) {
  ns <- NS(id)
  fluidPage(
    shinyjs::useShinyjs(),
    tags$head(
      tags$script(
        HTML(
          'Shiny.addCustomMessageHandler("uncheckCheckbox", function(index) {',
          '  $("input[name=\'row_selected\']").eq(index).prop("checked", false);',
          '});'
        )
      )
    ),
    fluidRow(
      column(12, 
             tagList(
                # selectInput(ns("run_selector"), "Choose a Run To view", choices =NULL),
                dataTableOutput(ns("history_table")),
                actionButton(ns("compare_btn"), "Show / Compare Result"),
                downloadButton(ns("download"), "Download")
            )
      )
    ),
    tabsetPanel(
      id = "main-tabs",
      # --------Insert tabs UI calls here, comma separated --------
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
    
    selectedRows <- reactiveVal(c(TRUE))
    redraw <- reactiveVal(FALSE)
    rv_results <- reactiveValues()
    
    autoInvalidate <- reactiveTimer(2000)
    observe({
      autoInvalidate()
      js_code <- "
      var arr = [];
      var arr_history = localStorage.getItem('test_names');
      var test_names = JSON.parse(localStorage.getItem('test_names')) || [];
      for (let i = 0; i < test_names.length; i++) {
       arr.push(test_names[i].name)
      }
      Shiny.setInputValue('%s', arr);
      Shiny.setInputValue('%s', arr_history);
      "
      shinyjs::runjs(sprintf(js_code, ns("test_names_loaded"), ns("test_history")))  
      updateSelectInput(session, "run_selector",
                        label = "Choose a Run To view",
                        choices = input$test_names_loaded,
      )
    })
    
    observeEvent(input$test_history, {
      df_history <- jsonlite::fromJSON(input$test_history)
      df_history$datetime <- as.POSIXct(df_history$date, format = "%m/%d/%Y, %I:%M:%S %p", tz = "UTC")
      rv$df_history <-  df_history%>% arrange(desc(datetime))  %>% select(-(datetime))
      selectedRows <- reactiveVal(c(TRUE, rep(FALSE, nrow(rv$df_history)-1)))
      
      output$history_table <- renderDT({
        checkboxData <- transform(rv$df_history, Select = sprintf('<input type="checkbox" name="row_selected" %s/>', ifelse(selectedRows(), "checked", "")))
        datatable(
          checkboxData,
          class ='compact',
          escape = FALSE,
          filter = 'top',
          selection = 'none',
          options = list(
            pageLength = 10,
            preDrawCallback = JS('function() { Shiny.unbindAll(this.api().table().node()); }'),
            drawCallback = JS(
              'function() {',
              '  Shiny.bindAll(this.api().table().node());',
              '}'
            )
          ),
          callback = JS(
            'function updateSelectedRows(checkbox) {',
            '  var row = $(checkbox).closest("tr");',
            '  var rowIdx = row[0]._DT_RowIndex;',
            '  var selected = $(checkbox).prop("checked");',
            sprintf('  Shiny.setInputValue("%s", {index: rowIdx, selected: selected}, {priority: "event"});', ns("rowSelected")),
            '}',
            '$(document).on("change", "input[name=\'row_selected\']", function() {',
            '  updateSelectedRows(this);',
            '});'
          )
        )
      }, server = FALSE)
    },ignoreNULL = TRUE)
    
    observeEvent(input$rowSelected, {
      selections <- selectedRows()
      selections[input$rowSelected$index + 1] <- input$rowSelected$selected
      selectedRows(selections)
      
      if (sum(selections) > 2) {
        selections[input$rowSelected$index + 1] <- FALSE
        selectedRows(selections)
        session$sendCustomMessage(type = "uncheckCheckbox", input$rowSelected$index)
      }
    })
    
    
    observeEvent(input$compare_btn, {
      
      selected <- which(selectedRows())
      print(paste0("selected ", length(selected)))
      test_selected <- rv$df_history[selected, 'name']
      
      # Check of start/end year is consistent for all data
      if (length(unique(rv$df_history[selected, 'start_year'])) == 1 &
          length(unique(rv$df_history[selected, 'end_year'])) == 1){
        data_is_valid <- TRUE
        rv_results$start_year <- as.integer(unique(rv$df_history[selected, 'start_year']))
        rv_results$end_year <- as.integer(unique(rv$df_history[selected, 'end_year']))
      }

      if(all(file.exists(file.path(result_root, rv$df_history[selected, 'name'])))){
        filenames <- unique(list.files(file.path(result_root, rv$df_history[selected, 'name']), pattern = "\\.csv$"))
        # filenames <- filenames[filenames != "result.csv"] # exclude results
        directories <- file.path(result_root, rv$df_history[selected, 'name'])
        
        # Function to read and combine files for each filename
        read_and_combine <- function(filename, directories) {
          filepaths <- paste0(directories, "/", filename)
          combined_data <- do.call(rbind, lapply(filepaths, read.csv, stringsAsFactors = FALSE))
          return(combined_data)
        }
        for (filename in filenames) {
          combined_data <- read_and_combine(filename, directories)
          # Remove file extension and use it as the name for the reactiveVal
          name <- tools::file_path_sans_ext(filename)
          rv_results[[name]] <- combined_data
        }
        redraw(data_is_valid )
      }
    
    })
    
    observe ({
        if (redraw()){
          plotTabServer(
            id = "slide-4-tab",
            plotting_function = "get_slide_4_plot",
            rv = rv_results)
          
          plotTabServer(
            id = "by-ServiceCat-tab",
            plotting_function = "byServiceCat_plot",
            rv = rv_results)
          
          ggplotTabServer(
            id = "by-ServiceTile-tab",
            plotting_function = "byServiceTile_plot",
            rv = rv_results)
          
          plotTabServer(
            id = "service-over-time-tab",
            plotting_function = "serviceOverTime_plot",
            rv = rv_results)
          
          plotTabServer(
            id = "seasonality-tab",
            plotting_function = "seasonality_plot",
            rv = rv_results)
          
          redraw(FALSE)
        }
       
    })
    
    observeEvent(input$download, {
      # Code to handle the file download
      

    })
  })
}
