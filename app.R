library(shiny)
library(shinyStore)

ui <- fluidPage(
                includeCSS("www/css/styles.css"),
                includeScript("www/js/util.js"),
                useShinyjs(),
                tags$script(HTML("
                  $(document).on('shiny:connected', function(event) {
                  window.resizeTo(1050, 600); // Use optimal window size
                  });
                ")),
                tags$head(
                  tags$link(rel="shortcut icon", href = "assets/favicon.ico"),
                  tags$link(rel ="stylesheet", type="text/css", href = "css/styles.css"),
                  #--------------------------
                  #load project title from global.R
                  tags$title({project_title})
                  #--------------------------
                ),
                #Home and About page UI components are 
                #imported in headerUI component
                headerUI("header"),
                footerUI("footer"),
                # initialize shinyStore
                shinyStore::initStore("store", "PACE-HRH-UI-store")
                
)

server <- function(input, output,session){
  
  # close the app when session ends
  session$onSessionEnded(function() {
    stopApp()
  })
  #---------------------------------------------------
  #display the greeting module if not previously shown 
  greetingModal <- function(){
    showModal(
      modalDialog(
        greetingUI("greeting"),
        footer = tagList(
          actionButton("continue", "Continue" ,
                       width = "100%", class="btn-success"
          )
        )
      )
    )
  }
  
  greeting_already_shown <- reactive({
    capture.output(input$store$greeting_modal_shown)
  })
  
  observeEvent(input$continue,{
    removeModal()
    updateStore(session, "greeting_modal_shown", value = "shown")
    message("setting 'greeting_modal_shown' to TRUE")
    shinyjs::runjs('let r = (Math.random() + 1).toString(36).substring(7); localStorage.setItem("uid", r);')
  })
  
  observeEvent(input$store, {
    if (! grepl("shown", greeting_already_shown(), fixed=TRUE)){
      message("showing greeting modal")
      greetingModal()
    }
  })
  #---------------------------------------------------
  # We need to pass store to modules that require local storage
  store <- reactive({
    input$store
  })
  #---------------------------------------------------
  #Home and About page server functions are
  #imported in headerServer function
  headerServer("header", store=store)
  footerServer("footer")
}



shinyApp(ui=ui, server=server)

