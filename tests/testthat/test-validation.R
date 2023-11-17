test_that("test validation report", {
  setwd("../../")
  print(paste0("current directory:", getwd()))
  if (dir.exists("testlog")){
    unlink("testlog", recursive = TRUE)
  }
  rmarkdown::render(input = "validation_report.Rmd",
                    output_format = "html_document",
                    output_dir = "testlog",
                    params=list(inputFile="config/model_inputs.xlsx", outputDir="testlog"))
  expect_true(file.exists("testlog/validation_report.html"))

})