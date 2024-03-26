library(shinytest2)

test_that("validation_check", {
  app <- AppDriver$new(variant = platform_variant(), name = "validation_check", height = 759, 
      width = 1993)
  tryCatch(
    expr = {app$setInputs(continue = "click")
    },
    error = function(e){
      print("ignore the starting message")
    }
  ) 
  app$set_inputs(store = "{\"encV\":false,\"data\":\"shown\"}")
  app$click("controller-validate")
  app$set_inputs(`main-tabs` = "Validation Report")
  # todo: use simpler check for the report
  # app$expect_values()
})
