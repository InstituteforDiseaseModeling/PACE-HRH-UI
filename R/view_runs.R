# UI for the view runs module
viewRunsUI <- function(id) {
  ns <- NS(id)
  tagList(
    fileInput(ns("file_selector"), "Choose a Folder"),
    downloadButton(ns("download"), "Download")
  )
}

# Server logic for the view runs module
viewRunsServer <- function(id, store) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$download, {
      # Code to handle the file download
    })
  })
}
