$( document ).ready(function() {
  $('.enabled-monitoring-switch').click(function(){
    $.ajax({
      url: '/monitor/toggle/overall',
      type: 'POST',
      success: function(result) {
        location.reload(true);
      }
    });
  });

  $('.enabled-monitoring-map-switch').click(function(){
    $.ajax({
      url: '/monitor/toggle/map',
      type: 'POST',
      success: function(result) {
        location.reload(true);
      }
    });
  });

  $('.enabled-hardware-monitoring-switch').click(function(){
    $.ajax({
      url: '/monitor/toggle/hardware',
      type: 'POST',
      success: function(result) {
        location.reload(true);
      }
    });
  });

  $('.enabled-applications-monitoring-switch').click(function(){
    $.ajax({
      url: '/monitor/toggle/applications',
      type: 'POST',
      success: function(result) {
        location.reload(true);
      }
    });
  });

  $('.start-hardware-data-form').submit(function(){
    var vals = $(this).serialize().split('&');
    var values = {}
    for(var i = 0; i < vals.length; i++){
      tmp = vals[i].split('=');
      values[tmp[0]] = tmp[1];
    }
    var data = {};
    data['end_point'] = values.end_point;
    data['temp']      = values.temp;
    data['users']     = values.users;
    data['cpu']       = values.cpu;
    data['ram']       = values.ram;
    data['storage']   = values.storage;
    $("#start-hardware-data-modal").modal('hide');
    $.ajax({
      url: '/monitor/start/hardware_data',
      type: 'POST',
      data: data,
      success: function(result) {

      }
    });
    return false;
  });

  $('.start-application-data-form').submit(function(){
    var vals = $(this).serialize().split('&');
    var values = {}
    for(var i = 0; i < vals.length; i++){
      tmp = vals[i].split('=');
      values[tmp[0]] = tmp[1];
    }
    var data = {};
    data['end_point'] = values.end_point;
    data['etherpad']  = values.etherpad;
    data['guestbook'] = values.guestbook;
    data['framadate'] = values.framadate;
    data['nextcloud'] = values.nextcloud;
    $("#start-application-data-modal").modal('hide');
    $.ajax({
      url: '/monitor/start/application_data',
      type: 'POST',
      data: data,
      success: function(result) {

      }
    });
    return false;
  });

  $('.stop-hardware-monitoring-data-button').click(function(){
    if ($(this).attr('disabled')){return false;}
    $(this).attr('disabled', true);
    $.ajax({
      url: '/monitor/stop/hardware_data',
      type: 'POST',
      success: function(result) {
        // setTimeout(location.reload.bind(location), 1500);
      }
    });
  });

  $('.stop-application-monitoring-data-button').click(function(){
    if ($(this).attr('disabled')){return false;}
    $(this).attr('disabled', true);
    $.ajax({
      url: '/monitor/stop/application_data',
      type: 'POST',
      success: function(result) {
        // setTimeout(location.reload.bind(location), 1500);
      }
    });
  });

  $('.start-hardware-data').click(function(){
    if ($(this).attr('disabled')){return false;}
    $('#start-hardware-data-modal').modal('show');
  });

  $('.start-application-data').click(function(){
    if ($(this).attr('disabled')){return false;}
    $('#start-application-data-modal').modal('show');
  });

  $('.hw-mon-stat-lab').click(function(){
    $('#hw-monitoring-info-modal').modal('show');
  });

  $('.app-mon-stat-lab').click(function(){
    $('#app-monitoring-info-modal').modal('show');
  });

  var intervalID = setInterval(function(){
    $.ajax({
      url: '/monitor/status/hardware_data',
      type: 'GET',
      success: function(result2) {
        result2 = JSON.parse(result2);
        if('error' in result2['status']){
          if(result2['status']['overall']){
            $("#start-monitoring-hardware-data").attr('disabled', true);
            $(".stop-hardware-monitoring-data-button").removeAttr('disabled');
          }
          else{
            $("#start-monitoring-hardware-data").removeAttr('disabled');
            $(".stop-hardware-monitoring-data-button").attr('disabled', true);
          }
          $(".hw-mon-stat-lab").removeClass('label-warning');
          $(".hw-mon-stat-lab").removeClass('label-danger');
          $(".hw-mon-stat-lab").removeClass('label-success');
          $(".hw-mon-stat-lab").addClass('label-danger');
          $(".hw-error-p").show();
          $(".hw-msg-p").hide();
          $(".hw-msg-p").hide();
          $(".hw-tmp-msg-p").hide();
          $(".hw-users-msg-p").hide();
          $(".hw-cpu-msg-p").hide();
          $(".hw-ram-msg-p").hide();
          $(".hw-storage-msg-p").hide();
          $(".hw-mon-stat-lab").html(error_msg);
          return;
        }
        $(".hw-error-p").hide();
        $(".hw-msg-p").show();
        $(".hw-tmp-msg-p").show();
        $(".hw-users-msg-p").show();
        $(".hw-cpu-msg-p").show();
        $(".hw-ram-msg-p").show();
        $(".hw-storage-msg-p").show();
        $("#hw-mon-stat-temp").html(result2['status']['temperature']);
        $("#hw-mon-stat-users").html(result2['status']['users']);
        $("#hw-mon-stat-cpu").html(result2['status']['cpu']);
        $("#hw-mon-stat-ram").html(result2['status']['ram']);
        $("#hw-mon-stat-storage").html(result2['status']['storage']);
        if(result2['status']['overall']){
          $("#start-monitoring-hardware-data").attr('disabled', true);
          $(".stop-hardware-monitoring-data-button").removeAttr('disabled');
          $(".hw-mon-stat-lab").html(active_msg);
          $(".hw-mon-stat-lab").removeClass('label-warning');
          $(".hw-mon-stat-lab").removeClass('label-danger');
          $(".hw-mon-stat-lab").removeClass('label-success');
          $(".hw-mon-stat-lab").addClass('label-success');
        }
        else{
          $("#start-monitoring-hardware-data").removeAttr('disabled');
          $(".stop-hardware-monitoring-data-button").attr('disabled', true);
          $(".hw-mon-stat-lab").html(inactive_msg);
          $(".hw-mon-stat-lab").removeClass('label-warning');
          $(".hw-mon-stat-lab").removeClass('label-danger');
          $(".hw-mon-stat-lab").removeClass('label-success');
          $(".hw-mon-stat-lab").addClass('label-warning');
        }
      }
    });
  }, 2000);

  var intervalID2 = setInterval(function(){
    $.ajax({
      url: '/monitor/status/application_data',
      type: 'GET',
      success: function(result2) {
        result2 = JSON.parse(result2);
        if(result2['status']['error']){
          if(result2['status']['overall']){
            $("#start-monitoring-application-data").attr('disabled', true);
            $(".stop-application-monitoring-data-button").removeAttr('disabled');
          }
          else{
            $("#start-monitoring-application-data").removeAttr('disabled');
            $(".stop-application-monitoring-data-button").attr('disabled', true);
          }
          $(".app-mon-stat-lab").removeClass('label-warning');
          $(".app-mon-stat-lab").removeClass('label-success');
          $(".app-mon-stat-lab").removeClass('label-danger');
          $(".app-mon-stat-lab").addClass('label-danger');
          $(".app-mon-stat-lab").html(error_msg);
          return;
        }
        $("#app-mon-stat-guestbook").html(result2['status']['guestbook']);
        $("#app-mon-stat-etherpad").html(result2['status']['etherpad']);
        $("#app-mon-stat-framadate").html(result2['status']['framadate']);
        $("#app-mon-stat-nextcloud").html(result2['status']['nextcloud']);
        if(result2['status']['overall']){
          $("#start-monitoring-application-data").attr('disabled', true);
          $(".stop-application-monitoring-data-button").removeAttr('disabled');
          $(".app-mon-stat-lab").html(active_msg);
          $(".app-mon-stat-lab").removeClass('label-success');
          $(".app-mon-stat-lab").removeClass('label-warning');
          $(".app-mon-stat-lab").removeClass('label-danger');
          $(".app-mon-stat-lab").addClass('label-success');
        }
        else{
          $("#start-monitoring-application-data").removeAttr('disabled');
          $(".stop-application-monitoring-data-button").attr('disabled', true);
          $(".app-mon-stat-lab").html(inactive_msg);
          $(".app-mon-stat-lab").removeClass('label-warning');
          $(".app-mon-stat-lab").removeClass('label-success');
          $(".app-mon-stat-lab").removeClass('label-danger');
          $(".app-mon-stat-lab").addClass('label-warning');
        }
      }
    });
  }, 2000);

  $('.enabled-sensors-switch').click(function(){
    $.ajax({
      url: '/devices/sensors/toggle',
      type: 'POST',
      success: function(result) {
        error = JSON.parse(result).error;
        if (error != null){
          location.reload(true);
        }
      }
    });
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
        $("#start_sensing_sensehat_" + data['id']).attr('disabled', true);
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
                $("#start_sensing_sensehat_" + result2['id']).removeAttr('disabled');
              }
              else{
                $("#sensor_type_" + result2['id'] + "_td").html('active');
                $("#sensor_entries_" + result2['id'] + "_td").html(result2['nof_entries']);
                $("#start_sensing_sensehat_" + result2['id']).attr('disabled', true);
              }
            }
          });
        }, values.interval * 1000);
      }
    });
    return false;
  });
});
