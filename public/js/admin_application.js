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

  $('.del_app').click(function(){
    confirm_element_id = $(this).attr('id').split('_').pop();
    console.log(confirm_element_id);
    $( "#delete-dialog-confirm" ).dialog( "open" );
  });

  $('.enabled-switch').click(function(){
    var appId = $(this).attr('id').split('_').pop();
    console.log(appId);
    $.ajax({
      url: '/application/' + appId,
      type: 'PUT',
      success: function(result) {
        id = JSON.parse(result).id;
      }
    });
  });

  $('.start_app:enabled').click(function(){
    var appId = $(this).attr('id').split('_').pop();
    console.log(appId);
  });

  $('.stop_app:enabled').click(function(){
    var appId = $(this).attr('id').split('_').pop();
    console.log(appId);
  });
});