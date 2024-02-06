Shiny.addCustomMessageHandler("notify_handler", js_message);

// this function is called by the handler, which passes the message
function js_message(x){
                window.alert(x);
              }