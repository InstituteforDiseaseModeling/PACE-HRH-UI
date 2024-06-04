
ValidateUI <- function(id, title="Validation report"){
  ns <- NS(id)
  tabPanel(title,
           fluidRow(
             column(12, actionButton(ns("run_validation_report_now"), "Run Advanced Validation Report"))
           ),
           fluidRow(
             column(
               4,
               uiOutput(ns("download_validation_report"))
             )
           ),
           fluidRow(
             style = "margin: 0 5px;",
             htmlOutput(ns("validate_result_html"))
           )
  )
}

ValidateServer <- function(id, input_file){
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    logdir <- tempdir()
    outfilename <- basename(sub("\\.xlsx$", ".html", input_file))
    
    observeEvent(input$run_validation_report_now, {
      print("Button clicked!")  # Debugging line
      rmarkdown::render(input = "validation_report.Rmd",
                        output_format = "html_document",
                        output_file = outfilename, 
                        output_dir = logdir,
                        params = list(inputFile = input_file, outputDir = logdir))
      
      report <- file.path(logdir, outfilename)
      if (file.exists(report)){
        output$validate_result_html <- renderUI({
          includeHTML(report)
        })
        output$download_validation_report <- renderUI({
          downloadButton(ns("downloadData"),
                         "Download Validation Report",
                         icon = icon("download"))
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
    })
  })
}
