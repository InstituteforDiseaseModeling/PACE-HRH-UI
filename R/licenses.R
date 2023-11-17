library(shiny)

#load global variables if they don't already exist
if (!exists("desc_content")){
  source("global.R")
}


create_rows <- function() {
  result <- ''
  
  dependencies <- sessionInfo()$otherPkgs
  pkgs <- c()
  versions <- c()
  licenses <- c()
  urls <- c()
  
  for (pkg in dependencies){
    pkgs <- append(pkgs, pkg$Package)
    versions <- append(versions, pkg$Version)
    licenses <- append(licenses, ifelse("License" %in% attributes(pkg)$names, pkg$License, ""))
    urls <- append(urls, ifelse("URL" %in% attributes(pkg)$names, pkg$URL, "") )
  }
  libraries <- data.frame(lapply(list(pkgs, versions, licenses, urls), function(x) Reduce (c,x)))
  colnames(libraries) <- c('Package', 'Version', 'License', 'URL')
  
  for (row in 1:nrow(libraries)) {

    table_row <- paste('<tr><td>',
                 libraries[row, 'Package'],
                 '</td><td>',
                 libraries[row, 'Version'],
                 '</td><td>',
                 libraries[row, 'License'],
                 '</td><td>',
                 libraries[row, 'URL'],
                 '</td></tr>'
    ) 
    result <- paste(result, table_row)
  }
  return (result)
}



licensesUI <- function(id) {
  ns = NS(id)
  rows <- create_rows()
  fluidPage(
    showModal(
      modalDialog(
        fluidPage(
          div(
            tabsetPanel(
              tabPanel("Our License",
                       div(class='license',
                           p({our_license_text},
                             tags$a(
                               href=our_license_link,
                               {our_license_link}
                             ))
                       )
              ),
              tabPanel("Library Licenses",
                       HTML(paste(
                         "<div class='license'>",
                         "<table class='licenseTable'>",
                         "<thead>",
                         "<tr>",
                         "<th>Package</th>",
                         "<th>Verson</th>",
                         "<th>License</th>",
                         "<th>Package url</th>",
                         "</tr>",
                         "</thead>",
                         rows,
                         "</table>",
                         "</div>")
                       )
              )
            )
          )
        )
      )
    )

  )
}

licensesServer <- function(id) {

  moduleServer(id, function(input, output, session) {
  
  })
}
