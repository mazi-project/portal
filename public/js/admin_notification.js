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
          url: '/notification/' + confirm_element_id,
          type: 'DELETE',
          success: function(result) {
            id = JSON.parse(result).id;
            error = JSON.parse(result).error;
            if (error != null){
              $("<div class='alert alert-danger'><p>" +  error + "</p></div>").prependTo('#page-wrapper > div > div:nth-child(2)');
            }
            else{
              $('#notification_tr_' + id).remove();
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

  $('.del_notification').click(function(){
    confirm_element_id = $(this).attr('id').split('_').pop();
    $( "#delete-dialog-confirm" ).dialog( "open" );
  });

  $('.enabled-switch').click(function(){
    var appId = $(this).attr('id').split('_').pop();
    $.ajax({
      url: '/notification/' + appId,
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
});
