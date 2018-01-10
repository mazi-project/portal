$( document ).ready(function() {
  $('.enabled-sensors-switch').click(function(){
    $.ajax({
      url: '/devices/sensors/toggle',
      type: 'POST',
      success: function(result) {
        error = JSON.parse(result).error;
        if (error != null){
          location.reload();
        }
      }
    });
  });

  $('.enabled-camera-switch').click(function(){
    $.ajax({
      url: '/devices/camera/toggle',
      type: 'POST',
      success: function(result) {
        error = JSON.parse(result).error;
        if (error != null){
          location.reload();
        }
      }
    });
  });

  $('#datetimepicker').datetimepicker({
    format:'d/m/Y H:i O'
  });

  $('.start-sensing-form').submit(function(){
    var vals = $(this).serialize().split('&');
    var values = {}
    for(var i = 0; i < vals.length; i++){
      tmp = vals[i].split('=');
      values[tmp[0]] = tmp[1];
    }
    var data = {};
    var type = values.type;
    data['id'] = values.id;
    data['duration'] = values.duration;
    data['interval'] = values.interval;
    data['end_point'] = values.end_point;
    data['until_date'] = values.until_date;
    $("#start-sensing-modal-" + values.id).modal('hide');
    $.ajax({
      url: '/devices/' + type + '/start',
      type: 'POST',
      data: data,
      success: function(result) {
        $("#sensor_type_" + data['id'] + "_td").html('active');
        var intervalID = setInterval(function(){
          $.ajax({
            url: '/devices/sensors/status/' + values.id,
            type: 'GET',
            success: function(result2) {
              result2 = JSON.parse(result2);
              if(result2['status'] == 'inactive'){
                clearInterval(intervalID);
                $("#sensor_type_" + result2['id'] + "_td").html('inactive');
                $("#sensor_entries_" + result2['id'] + "_td").html(result2['nof_entries']);
              }
              else{
                $("#sensor_type_" + result2['id'] + "_td").html('active');
                $("#sensor_entries_" + result2['id'] + "_td").html(result2['nof_entries']);
              }
            }
          });
        }, values.interval * 1000);
      }
    });
    event.preventDefault();
  });
});