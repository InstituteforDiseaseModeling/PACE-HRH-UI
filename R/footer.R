library(shiny)

footerUI <- function(id){
    #namespace ns 
    #wrap input and output ids with ns 
    ns <-NS(id)
    
    tags$footer(
      div( class = "sticky-footer row",
           column(2, 
                  tags$a(
                    href="https://www.gatesfoundation.org/",
                    target="_blank",
                    img(class="logo", src="assets/bmgf-logo-white.png")
                    )
                  ),
           column(3, div(
             title = paste0("No reproduction or distribution without written permission of Bill & Melinda Gates foundation. Attribution-Noncommercial-ShareAlike 4.0 License."),
             class="copy-text",
             span("© 1999-"),
             span({format(Sys.Date(), "%Y")}),
             span("Bill & Melinda Gates Foundation"),
             tags$br(),
             span("All Rights Reserved")
           )),
           column(3, div(
             class="terms",
             tags$a(class = "terms", 
                    href="https://www.gatesfoundation.org/Terms-of-Use",
                    target="_blank", "Terms of Use"),
             tags$br(),
             tags$a(class = "terms",
                    href="https://www.gatesfoundation.org/Privacy-and-Cookies-Notice",
                    target="_blank", "Privacy & Cookies Notice")
           )),
           column(1, actionLink(ns("display_licenses"), "Licenses", class="terms")),
           column(3, 
                  tags$a(
                    href="https://www.idmod.org/",
                    target="_blank",
                    img(class="logo", src="assets/idmlogo55.png")
                    )
                  )
      )
    )
}

footerServer <- function(id){
  moduleServer(id, function(input, output,session){
    observeEvent(input$display_licenses,{
        licensesUI("licenses")
    })
  })
  licensesServer("licenses")
}