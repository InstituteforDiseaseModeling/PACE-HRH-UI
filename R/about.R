library(shiny)

#load global variables if they don't already exist
if (!exists("desc_content")){
  source("global.R")
}
  
aboutUI <- function(id){
  #namespace ns 
  #wrap input and output ids with ns 
  ns <-NS(id)
  
  fluidPage(
    div(class="content",
       h2(class = "title titleText", 
          #-----------------------
          "About ",
          span({project_title}),
          #-----------------------
          ),
       p(class="contentText", 
         span({project_description})
       ),
       h4(class= "titleText",
          "Subheading"
        ),
       p(class="contentText", 
         "Additional text...")
        )
       
      
    
  )
}

aboutServer <- function(id){
  moduleServer(id, function(input, output, session){
    # About page functions
  })
}