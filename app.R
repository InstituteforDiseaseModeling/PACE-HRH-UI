library(shiny)
library(shinyjs)
library(DT)
library(bsicons)

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
)

server <- function(input, output,session){
  
  # close the app when session ends
  session$onSessionEnded(function() {
    # delete all downloaded files on the server after session ended
    intermediate_files <- list.files(result_root, full.names = TRUE, pattern ="*.zip|*.pdf")
    for (file in intermediate_files) {
      tryCatch(
        {
          file.remove(file)
          cat("File", basename(file), "deleted successfully.\n")
        },
        error = function(e) {
          cat("Error Removing file:", e$message, "\n")
        }
      )
    }
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
  
  firstLoad <- reactiveVal(TRUE)
  observe({
    if(isolate(firstLoad())) {
      # display greeting on first load
      shinyjs::runjs(sprintf("check_greeting('%s')", "greeting_already_shown"))
      # Set to FALSE after first execution
      firstLoad(FALSE)
    }
  })
  
  
  observeEvent(input$continue,{
    removeModal()
    message("setting 'greeting_modal_shown' to TRUE")
    shinyjs::runjs(' localStorage.setItem("greeting_modal_shown", "shown")')
    shinyjs::runjs('let r = (Math.random() + 1).toString(36).substring(7); localStorage.setItem("uid", r);')
  })
  
  observeEvent(input$greeting_already_shown, {
    if (! grepl("shown", input$greeting_already_shown, fixed=TRUE)){
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

