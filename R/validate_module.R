library(shiny)
ValidateUI <- function(id, title="Validation report"){
  ns <- NS(id)
  tabPanel(title,
           fluidRow(
             column(
               4,
               uiOutput(ns("download"))
             ),
           ),
           fluidRow(
             style = "margin: 0 5px;",
             
             htmlOutput(ns("validate_result")),
           ))

}

ValidateServer <- function(input, output, session, filename){
  session$userData$logdir <- tempdir()
  print(paste0("logdir", session$userData$logdir))
  rmarkdown::render(input = "validation_report.Rmd",
                    output_format = "html_document",
                    output_dir = session$userData$logdir,
                    params=list(inputFile=filename, outputDir=session$userData$logdir))
  report = file.path(session$userData$logdir, "validation_report.html")
  if (file.exists(report)){
    output$validate_result <- renderUI(includeHTML(report))
    output$download <- renderUI({
      downloadButton("downloadData",
                     "Download Validation Report",
                     icon = icon("download"),
      )
    })
    output$downloadData <- downloadHandler(
      filename = function() {
        paste("validation_report.html")
      },
      content = function(file) {
        file.copy(report, file)
      }
    ) 
  }
}





























