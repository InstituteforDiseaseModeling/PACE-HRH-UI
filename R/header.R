library(shinythemes)
library(shiny)

# load global variables if they don't already exist
if (!exists("desc_content")) {
  source("global.R")
}

headerUI <- function(id) {

  # wrap input and output ids with ns
  # namespace ns
  ns <- NS(id)

  navbarPage(
    #------------------------
    # load project title from global.R
    {
      project_title
    },
    #------------------------
    theme = shinytheme("flatly"),
    tabPanel(
      "Home",
      homeUI("home-page")
    ),
    tabPanel(
      "About",
      aboutUI("about-page")
    ),
    selected = NULL,
    position = "fixed-top",
    fluid = TRUE,
    collapsible = TRUE
  )
}

headerServer <- function(id, store=NULL) {
  homeServer("home-page", store)
  aboutServer("about-page")
  moduleServer(id, function(input, output, session) {
    # navbarPage functions
  })
}

