$( document ).ready(function() {
  var confirm_element_id = null;

  $( "#delete-dialog-confirm" ).dialog({
    resizable: false,
    height: "auto",
    width: 400,
    modal: true,
    autoOpen: false,
    buttons: {
      Yes: function() {
        $.ajax({
          url: '/application/' + confirm_element_id,
          type: 'DELETE',
          success: function(result) {
            id = JSON.parse(result).id;
            error = JSON.parse(result).error;
            if (error != null){
              $("<div class='alert alert-danger'><p>" +  error + "</p></div>").prependTo('#page-wrapper > div > div:nth-child(2)');
            }
            else{
              $('#app_tr_' + id).remove();
            }
          }
        });
        $( this ).dialog( "close" );
      },
      No: function() {
        confirm_element_id = null;
        $( this ).dialog( "close" );
      }
    }
  });

  $( "#delete-instance-dialog-confirm" ).dialog({
    resizable: false,
    height: "auto",
    width: 400,
    modal: true,
    autoOpen: false,
    buttons: {
      Yes: function() {
        $.ajax({
          url: '/application/' + confirm_element_id + '/instance/',
          type: 'DELETE',
          success: function(result) {
            id = JSON.parse(result).id;
            error = JSON.parse(result).error;
            if (error != null){
              $("<div class='alert alert-danger'><p>" +  error + "</p></div>").prependTo('#page-wrapper > div > div:nth-child(2)');
            }
            else{
              $('#app_inst_tr_' + id).remove();
            }
          }
        });
        $( this ).dialog( "close" );
      },
      No: function() {
        confirm_element_id = null;
        $( this ).dialog( "close" );
      }
    }
  });


  $('.del_app').click(function(){
    confirm_element_id = $(this).attr('id').split('_').pop();
    $( "#delete-dialog-confirm" ).dialog( "open" );
  });

  $('.del_app_inst').click(function(){
    confirm_element_id = $(this).attr('id').split('_').pop();
    $( "#delete-instance-dialog-confirm" ).dialog( "open" );
  });

  $('.enabled-switch').click(function(){
    var appId = $(this).attr('id').split('_').pop();
    $.ajax({
      url: '/application/' + appId,
      type: 'PUT',
      success: function(result) {
        id = JSON.parse(result).id;
        error = JSON.parse(result).error;
        if (error != null){
          location.reload(true);
        }
      }
    });
  });

  $('.enabled-instance-switch').click(function(){
    var appId = $(this).attr('id').split('_').pop();
    $.ajax({
      url: '/application/' + appId + '/instance/',
      type: 'PUT',
      success: function(result) {
        id = JSON.parse(result).id;
        error = JSON.parse(result).error;
        if (error != null){
          location.reload(true);
        }
      }
    });
  });

  $('.splash-instance-switch').click(function(){
    console.log('1111');
    var appId = $(this).attr('id').split('_').pop();
    console.log('2222');
    $.ajax({
      url: '/application/' + appId + '/instance/splash',
      type: 'PUT',
      success: function(result) {
        id = JSON.parse(result).id;
        error = JSON.parse(result).error;
        location.reload(true);
      }
    });
  });

  $('.start_app').click(function(){
    if ($(this).attr('disabled')){
      return;
    }
    var appId = $(this).attr('id').split('_').pop();
    $.ajax({
      url: '/application/' + appId + '/action/start/',
      type: 'PUT',
      success: function(result) {
        id = JSON.parse(result).id;
        error = JSON.parse(result).error;
        if (error != null){
          location.reload(true);
        }
        else{
          window.setTimeout(function(){location.reload()}, 3000);
        }
      }
    });
  });

  $('.stop_app').click(function(){
    if ($(this).attr('disabled')){
      return;
    }
    var appId = $(this).attr('id').split('_').pop();
    $.ajax({
      url: '/application/' + appId + '/action/stop/' ,
      type: 'PUT',
      success: function(result) {
        id = JSON.parse(result).id;
        error = JSON.parse(result).error;
        if (error != null){
          location.reload(true);
        }
        else{
          window.setTimeout(function(){location.reload()}, 3000);
        }
      }
    });
  });

  $("#create_inst_app_name_sl").change(function() {
    optionSelected = $("option:selected", this).text();
    new_url        = eval(optionSelected.toLowerCase().replace('-', '_') + "_url");
    new_icon       = eval(optionSelected.toLowerCase().replace('-', '_') + "_icon");
    new_color      = eval(optionSelected.toLowerCase().replace('-', '_') + "_color");
    $("#create_inst_app_url_in").val(new_url);
    $("#create_inst_app_icon_in").val(new_icon);
    $("#create_inst_app_color_sl").val(new_color);
  });
});
