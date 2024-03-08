library(shiny)
library(readxl)
library(DT)
library(openxlsx)
library(shinyBS)
library(dplyr)


inputSheetUI <-
  function(id,
           sheet_name,
           show_title = FALSE,
           enable_add_row = FALSE,
           enable_delete_row = FALSE,
           editable = FALSE) {
    ns <- NS(id)
    
    tabPanel(sheet_name,
             if (show_title) {
               tags$h3(sheet_name)
             },
             DTOutput(ns(sheet_name)),
             div(
               tags$hr(style = "margin:10px auto;"),
               fluidRow(shinyjs::useShinyjs(),
                        if (enable_delete_row) {
                          column(
                            2,
                            actionButton(
                              ns("delete_row"),
                              label = icon("minus"),
                              title = "remove selected row/s",
                              width = "100%",
                              style = "padding:6px 12px;"
                            ),
                          )
                        },
                        if (enable_add_row) {
                          column(
                            2,
                            actionButton(
                              ns("add_row"),
                              label =  icon("plus"),
                              width = "100%",
                              style = "padding:6px 12px;",
                              title = "add a new row"
                            )
                          )
                        }
                        ,
                        if (editable) {
                          column(
                            4,
                            actionButton(
                              ns("save"),
                              icon = icon("save"),
                              label = "Save",
                              width = "100%",
                              style = "padding:6px 12px;",
                              title = "save changes to config file"
                            )
                          )
                        })
             ),
             tags$hr())
  }



inputSheetServer <-
  function(id,
           sheet_name,
           page_length = 10,
           paging = TRUE,
           round_digits = FALSE,
           input_file = NULL,
           editable = FALSE) {
    sheet <-
      reactiveValues(data = read_excel(input_file, sheet = sheet_name))
    moduleServer(id, function(input, output, session) {
      rows_selected <- paste0(sheet_name, "_rows_selected")
      cell_edit <- paste0(sheet_name, "_cell_edit")
      
      
      observe({
        if (is.null(input[[rows_selected]])) {
          shinyjs::disable(id = "delete_row")
        } else {
          shinyjs::enable(id = "delete_row")
        }
      })
      
      output[[sheet_name]] <- renderDataTable({
        if (round_digits) {
          sheet$data <-
            sheet$data %>% dplyr::mutate_if(is.numeric, round, digits = 4)
        }
        
        DT::datatable(
          sheet$data,
          editable = editable,
          options = list(
            scrollX = TRUE,
            
            paging = paging,
            info = FALSE,
            searching = FALSE,
            pageLength = page_length
            
          ),
          rownames = FALSE,
        )
      })
      
      
      
      observeEvent(input[[cell_edit]], {
        info <- input[[cell_edit]]
        sheet$data <- editData(sheet$data, info, rownames = FALSE)
      })
      
      observeEvent(input$save, {
        tryCatch({
          loggerServer("logger",
                       paste0("Saving updated sheet ", sheet_name),
                       three_dots = TRUE)
          wb <- openxlsx::loadWorkbook(input_file)
          openxlsx::writeData(wb, sheet_name, sheet$data)
          openxlsx::saveWorkbook(wb, input_file, overwrite = TRUE)
          loggerServer("logger",
                       paste0(sheet_name, " saved"), )
          
        }, error = function(e) {
          print("error trying to save file")
          print(e)
          loggerServer("logger",
                       paste0("Error saving updated sheet ", sheet_name, " :", e),)
          
        }, finally = function() {
          
        })
        
      })
      
      observeEvent(input$add_row, {
        isolate(input$add_row)
        
        new_row <-
          data.frame(matrix(ncol = ncol(sheet$data), nrow = 1))
        
        colnames(new_row) <- colnames(sheet$data)
        sheet$data <- dplyr::bind_rows(new_row, sheet$data)
        
      })
      
      observeEvent(input$delete_row, {
        if (!is.null(input[[rows_selected]])) {
          rows <- input[[rows_selected]]
          for (row in rows) {
            sheet$data <- sheet$data[-row, ]
          }
        }
      })
    })
  }