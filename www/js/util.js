Shiny.addCustomMessageHandler("notify_handler", js_message);

// this function is called by the handler, which passes the message
function js_message(x){
                window.alert(x);
              }

function set_uid(){
  if (localStorage.getItem('uid')){
    return localStorage.getItem('uid');
  } 
  else {
    v = (Math.random() + 1).toString(36).substring(7);
    localStorage.setItem('uid', v);
    return v;
  }
}

function set_shiny_uid(shiny_input_name){
    var uid = set_uid(); 
    Shiny.setInputValue(shiny_input_name, uid)
}
              
function get_test_names(names, history, notify ="false"){
  var arr = [];
  var arr_history = localStorage.getItem('test_names');
  var test_names = JSON.parse(localStorage.getItem('test_names')) || [];
  for (let i = 0; i < test_names.length; i++) {
    arr.push(test_names[i].name)
  }
  Shiny.setInputValue(names, arr, {priority: 'event'});
  Shiny.setInputValue(history, arr_history, {priority: 'event'});
  if (notify!=="false"){
    Shiny.setInputValue(notify, "true", {priority: 'event'});
  }
}              