$( document ).ready(function() {
  $('.enabled-camera-switch').click(function(){
    $.ajax({
      url: '/devices/camera/toggle',
      type: 'POST',
      success: function(result) {
        error = JSON.parse(result).error;
        if (error != null){
          location.reload(true);
        }
      }
    });
  });

  $('#datetimepicker').datetimepicker({
    format:'d/m/Y H:i O'
  });
});
