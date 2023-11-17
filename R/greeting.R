library(shiny)


#load global variables if they don't already exist
if (!exists("desc_content")){
  source("global.R")
}

greetingUI <- function(id){
  
  fluidPage(
    h1(
      {project_title}
    ),
    p(
      {project_description}
    ),
    div(
        p({our_license_text},
          tags$a(
            href=our_license_link,
            {our_license_link}
          ))
    ),
    p("This site uses cookies and similar technologies to store information 
      on your computer or device. By continuing to use this site, you agree 
      to the placement of these cookies and similar technologies. Read our ",
      tags$a(
        href="https://www.gatesfoundation.org/Privacy-and-Cookies-Notice",
        target="_blank",
        "Privacy & Cookies Notice"
        ), 
      " to learn more."
      )
  )
  
}

greetingServer <- function(id){
  moduleServer(id, function(input, output, session){
    #greeting module functions
    
  })
}