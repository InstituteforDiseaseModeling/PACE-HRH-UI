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


function delete_tests(namesToDelete, history, history_shiny_table) {
  // Get the JSON string from local storage
  var arr_history = localStorage.getItem("test_names");
  
  // Parse the JSON string into an array
  var data = JSON.parse(arr_history);
  
  // Filter out entries with names specified in namesToDelete array
  var filteredData = data.filter(function(entry) {
    return !namesToDelete.includes(entry.name);
  });
  
  // Convert the filtered data back to JSON string
  var filteredDataString = JSON.stringify(filteredData);
  
  // Save the filtered data back to local storage
  localStorage.setItem("test_names", filteredDataString);
  
  var table_element = document.getElementById(history_shiny_table);
  // Delete test_names if empty
  // hide the caller shinytable if data does not exist
  if (filteredData.length === 0) {
    localStorage.removeItem("test_names");
    if (table_element) {
        table_element.style.display = 'none';
    }
  }
  else{
    if (table_element) {
        table_element.style.display = 'block';
    }
  }
  var arr_history = localStorage.getItem('test_names');
  Shiny.setInputValue(history, arr_history, {priority: 'event'});
}

function check_greeting(shiny_input_name) {
  var greeting = "none"
  if (localStorage.getItem('greeting_modal_shown')){
    greeting = localStorage.getItem('greeting_modal_shown');
  }
  Shiny.setInputValue(shiny_input_name, greeting);
}


