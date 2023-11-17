library(shiny)
library(shinyBS)
library(shinycssloaders)



loggerUI <- function(id){
  fluidRow(div(
    class = "sticky-logger row",
    div(
      class = "log-content",
      div(class = "log-header",
          tags$div( style="padding:5px;",
                    tags$h6("● ● ●", style = "margin:0!important; float: right; display: inline;"),
                    tags$h5("Logs", style = "margin:0!important;")
          )),
      tags$div(style = "padding-right:5px;",shinyBS::bsAlert("log-display"))
      
    ),
  ))
}


loggerServer <- function(id, message=NULL, three_dots = FALSE){
  session <- shiny::getDefaultReactiveDomain()
  if(three_dots){
    # message <- paste0(message, "...")
    message <- paste0("<div>",message,'<div class="lds-ellipsis"><div></div><div></div><div></div></div>',"</div>")

  }
  shinyBS::  createAlert(
    session,
    "log-display",
    content = message,
    append = FALSE,
    dismiss = FALSE
  )
  
}