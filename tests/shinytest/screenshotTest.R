app <- ShinyDriver$new("../../")
app$snapshotInit("screenshottest")


app$setInputs(continue = "click")
app$snapshot()

app$setInputs(`header-view_runs` = "click")
app$snapshot()

app$setInputs(`header-header_options` = "Home")
app$setInputs(`header-run_simulation` = "click")
app$snapshot()
app$setInputs(`sim1-skipBtn` = "click")
app$snapshot()
app$setInputs(`sim1-prevBtn` = "click")
app$snapshot()
app$setInputs(`sim1-prevBtn` = "click")
app$snapshot()
app$setInputs(`sim1-optional_params` = "click")
app$snapshot()
app$setInputs(`sim1-cancelDataChange` = "click")
app$setInputs(`sim1-nextBtn` = "click")
app$setInputs(`sim1-skipBtn` = "click")
app$setInputs(`sim1-run_simBtn` = "click")
app$snapshot()

