library(shiny)

homeUI <- function(id){

  fluidPage(
    mainPageUI("main"),
  )
}

homeServer <- function(id, store = NULL){
  mainPageServer("main", store)
  moduleServer(id, function(input, output, session){
    #module code
  })

}