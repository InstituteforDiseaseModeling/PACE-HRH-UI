Shiny.addCustomMessageHandler("done_handler", js_message);

// this function is called by the handler, which passes the message
function js_message(x){
                window.alert("Saving " + x);
              }