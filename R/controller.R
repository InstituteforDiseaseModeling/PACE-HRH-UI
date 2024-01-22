library(shiny)
library(shinyjs)
library(shinyalert)
library(shinyStore)
library(shinycssloaders)
library(shinyWidgets)
library(pacehrh)
library(DT)
library(data.table)
library(jsonlite)
library(dplyr)
library(plotly)
library(readxl)



#UI code
controllerUI <- function(id, input_file) {
  ns <- NS(id)
  all_sheet_names <- readxl::excel_sheets(input_file)
  
  tv_sheet_names <-
    grep("^TaskValues_", all_sheet_names, value = TRUE)
  
  fluidRow(shinyjs::useShinyjs(),
           wellPanel(fluidRow(
             column(
               3,
               numericInput(
                 ns("num_trials"),
                 label = "Number of trials",
                 value = 5,
                 min = 2,
                 max = 200
               )
             ),
             column(
               9,
               sliderInput(
                 ns("end_year"),
                 label = "End year",
                 min = 2021,
                 max = 2050,
                 value = 2035,
                 step = 1,
                 sep = "",
                 width = "100%"
               )
             ),
             tabsetPanel(
               tabPanel("Scenarios",
                        DTOutput(ns("scenarios")),
                        div(
                          tags$hr(style = "margin:10px auto;"),
                          fluidRow(
                            
                            # column(
                            #   2,
                            #   actionButton(
                            #     ns("delete_scenario"),
                            #     label = icon("minus"),
                            #     title = "remove selected row/s",
                            #     width = "100%",
                            #     style = "padding:6px 12px;"
                            #   ),
                            # ),
                            # column(
                            #   2,
                            #   actionButton(
                            #     ns("add_scenario"),
                            #     label = icon("plus"),
                            #     width = "100%",
                            #     style = "padding:6px 12px;",
                            #     title = "add a new row"
                            #   )
                            # ),
                            column(
                              2,
                              actionButton(
                                ns("reset"),
                                label = "Reset",
                                icon = icon("rotate"),
                                width = "100%",
                                style = "padding:6px 12px;",
                                title = "Reset all"
                              )
                            ),
                            column(
                              3,
                              actionButton(
                                ns("simulate"),
                                label = "Simulate",
                                icon = icon("play"),
                                width = "100%",
                                style = "padding:6px 12px;",
                                title = "Run simulation for the selected scenario/s"
                              )
                            ),
                            column(
                              3,
                              actionButton(
                                ns("validate"),
                                label = "Validate Input",
                                icon = icon("check"),
                                width = "100%",
                                style = "padding:6px 12px;",
                                title = "Validate Input Sheet values"
                              )
                            ),
                          ),
                        )),
               #Load task value sheets
               tabPanel("TaskValues",
                        lapply(tv_sheet_names, function(name) {
                          inputSheetUI(tolower(name), name, show_title = TRUE)
                        }),),
               #Load Cadres sheet
               inputSheetUI("cadres", "Cadres"),

               #Load other controllers
               inputSheetUI(
                 "seasonality-curves",
                 "SeasonalityCurves"
               )
             ),
           ),))

}

controllerServer <- function(id, store = NULL, input_file) {
  
  #Get the Task Value sheet names from the input file
  all_sheet_names <- readxl::excel_sheets(input_file)
  
  tv_sheet_names <-
    grep("^TaskValues_", all_sheet_names, value = TRUE)
  
  #load task value servers
  lapply(tv_sheet_names, function(name) {
    inputSheetServer(tolower(name), name, input_file = input_file)
  })

  #load cadres server
  inputSheetServer("cadres", "Cadres", input_file = input_file)

  #load other contoller servers
  inputSheetServer(
    "seasonality-curves",
    "SeasonalityCurves",
    page_length = 12,
    paging = FALSE,
    round_digits = TRUE,
    input_file = input_file
  )

  moduleServer(id, function(input, output, session) {
    # initialize reactiveValues

    v <- reactiveValues(scenarios = readxl::read_xlsx(input_file,
                                                      sheet = "Scenarios"))

    # output the datatable based on the dataframe (and make it editable)
    output$scenarios <- renderDataTable({
      DT::datatable(
        v$scenarios,
        editable = FALSE,
        options = list(
          scrollX = TRUE,
          paging = FALSE,
          info = FALSE,
          searching = FALSE
        ),
        rownames = FALSE,
        selection = "multiple"
      )
    })

    observe({
      if (is.null(input$scenarios_rows_selected)) {
        shinyjs::disable(id = "simulate")
        shinyjs::disable(id = "delete_scenario")
      } else {
        shinyjs::enable(id = "simulate")
        shinyjs::enable(id = "delete_scenario")
      }
    })

    observeEvent(input$reset, {
      # reload_original_config()
      session$reload()
    })

     observeEvent(input$delete_scenario, {
      if (!is.null(input$scenarios_rows_selected)) {
        rows <- input$scenarios_rows_selected
        for (row in rows) {
          v$scenarios <- v$scenarios[-row, ]
        }
      }
    })

    observeEvent(input$add_scenario, {

      isolate(input$add_scenario)

        new_scenario <-
          data.frame(
            UniqueID = paste("Scenario", nrow(v$scenarios)+1, sep = "-"),
            WeeksPerYr = 48, 
            HrsPerWeek = 32,
            BaselinePop = 5000,
            o_PopGrowth = TRUE,
            o_Fertility_decr = TRUE,
            o_MHIVTB_decr = TRUE, 
            o_ChildDis_decr = TRUE,
            sheet_TaskValues = "TaskValues_basic",
            sheet_PopValues = "PopValues",
            sheet_SeasonalityCurves = "SeasonalityCurves",
            sheet_Cadre = "Cadres",
            deliveryModel = "Basic"
          )

        colnames(new_scenario) <- colnames(v$scenarios)
        new_scenario$UniqueID <- paste("Scenario", nrow(v$scenarios)+1, sep = "-")
        v$scenarios <- dplyr::bind_rows(new_scenario, v$scenarios)
    })

    # when there is any edit to a cell, write that edit to the initial dataframe
    # observeEvent(input$scenarios_cell_edit, {
    #   # typecast string to logical
    #   info <- input$scenarios_cell_edit
    #   col_types <- pacehrh:::.scenarioColumnTypes
    #   col_names <- pacehrh:::.scenarioColumnNames
    #   # plus 1 because JS indexes from 0
    #   prev <- v$scenarios[info$row, info$col + 1]
    #   if (col_types[info$col + 1] == "logical") {
    #     if (is.na(as.logical(info$value))) {
    #       info$value <- as.logical(prev)
    #       shinyalert(
    #         type = "error",
    #         text = paste0(
    #           "Incorrect entry for ",
    #           col_names[info$col + 1],
    #           ", row ",
    #           info$row,
    #           ". ",
    #           "Using previous value: ",
    #           v$scenarios[info$row, info$col + 1] %>% tolower(),
    #           ". Please enter 'true' or 'false' to update the value."
    #         )
    #       )
    #     } else {
    #       info$value <- as.logical(info$value)
    #     }
    #   } else if (col_types[info$col + 1] == "double") {
    #     if (is.na(as.numeric(info$value))) {
    #       info$value <- as.numeric(prev)
    #       shinyalert(
    #         type = "error",
    #         text = paste0(
    #           "Incorrect entry for ",
    #           col_names[info$col + 1],
    #           ", row ",
    #           info$row,
    #           ". ",
    #           "Using previous value: ",
    #           v$scenarios[info$row, info$col + 1],
    #           ". Please enter a number."
    #         )
    #       )
    #     } else {
    #       info$value <- as.numeric(info$value)
    #     }
    #   }
    #   v$scenarios <- editData(v$scenarios, info, rownames = FALSE)
    #   # output the datatable based on the dataframe (and make it editable)
    #   output$scenarios <- renderDataTable({
    #     DT::datatable(
    #       v$scenarios,
    #       editable = TRUE,
    #       options = list(
    #         scrollX = TRUE,
    #         paging = FALSE,
    #         info = FALSE,
    #         searching = FALSE
    #       ),
    #       rownames = FALSE,
    #       selection = "multiple"
    #     )
    #   })
    # })


    module_output <- reactive({
      scenarios <-
        isolate(v$scenarios[isolate(input$scenarios_rows_selected), , drop = FALSE])
      simulate <- input$simulate
      validate <- input$validate
      num_trials <- isolate(input$num_trials)
      year_range <- c(2020, isolate(input$end_year))
      list(
        scenarios = scenarios,
        simulate = simulate,
        validate = validate,
        num_trials = num_trials,
        year_range = year_range
      )
    })

  })

}
