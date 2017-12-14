$( document ).ready(function() {
  var log_lines = $(".log-wrapper").text().split("\n");

  function show_log_messages(error_msgs, warn_msgs, debug_msgs){
    var new_lines = "";
    $.each(log_lines, function(n, line) {
      if (error_msgs && line.match("^E")) {
         new_lines += line + "\n";
      }
      if (warn_msgs && line.match("^W")) {
         new_lines += line + "\n";
      }
      if (debug_msgs && line.match("^D")) {
         new_lines += line + "\n";
      }
    });
    $(".log-wrapper").text(new_lines);
  }

  error_checked = true;
  warn_checked = true;
  debug_checked = false;
  if (localStorage.getItem("error_checked") != null){
    if (localStorage.getItem("error_checked") == 'true'){
      error_checked = true;
      $("#error_enabled_cb").prop("checked", true);
    }
    else {
      error_checked = false;
      $("#error_enabled_cb").prop("checked", false);
    }
  }
  if (localStorage.getItem("warn_checked") != null){
    if (localStorage.getItem("warn_checked") == 'true'){
      warn_checked = true;
      $("#warn_enabled_cb").prop("checked", true);
    }
    else {
      warn_checked = false;
      $("#warn_enabled_cb").prop("checked", false);
    }
  }
  if (localStorage.getItem("debug_checked") != null){
    if (localStorage.getItem("debug_checked") == 'true'){
      debug_checked = true;
      $("#debug_enabled_cb").prop("checked", true);
    }
    else {
      debug_checked = false;
      $("#debug_enabled_cb").prop("checked", false);
    }
  }
  localStorage.clear();
  show_log_messages(error_checked, warn_checked, debug_checked);

  $(".msg-lvl-cb").change(function(){
    show_log_messages($("#error_enabled_cb").is(":checked"), $("#warn_enabled_cb").is(":checked"), $("#debug_enabled_cb").is(":checked"));
  });

  $('#refresh-log-btn').click(function(){
    localStorage.setItem("error_checked", $("#error_enabled_cb").is(":checked"));
    localStorage.setItem("warn_checked",  $("#warn_enabled_cb").is(":checked"));
    localStorage.setItem("debug_checked", $("#debug_enabled_cb").is(":checked"));
    location.reload();
  });
});