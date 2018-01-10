$( document ).ready(function() {
  $('.enabled-monitoring-switch').click(function(){
    $.ajax({
      url: '/monitor/toggle/overall',
      type: 'POST',
      success: function(result) {
        location.reload();
      }
    });
  });

  $('.enabled-hardware-monitoring-switch').click(function(){
    $.ajax({
      url: '/monitor/toggle/hardware',
      type: 'POST',
      success: function(result) {
        location.reload();
      }
    });
  });

  $('.enabled-applications-monitoring-switch').click(function(){
    $.ajax({
      url: '/monitor/toggle/applications',
      type: 'POST',
      success: function(result) {
        location.reload();
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
    data['temp']  = values.temp;
    data['users'] = values.users;
    data['cpu']   = values.cpu;
    data['ram']   = values.ram;
    $("#start-hardware-data-modal").modal('hide');
    $.ajax({
      url: '/monitor/start/hardware_data',
      type: 'POST',
      data: data,
      success: function(result) {

      }
    });
    event.preventDefault();
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
    $("#start-application-data-modal").modal('hide');
    $.ajax({
      url: '/monitor/start/application_data',
      type: 'POST',
      data: data,
      success: function(result) {

      }
    });
    event.preventDefault();
  });

  $('.stop-hardware-monitoring-data-button').click(function(){
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
    $(this).attr('disabled', true);
    $.ajax({
      url: '/monitor/stop/application_data',
      type: 'POST',
      success: function(result) {
        // setTimeout(location.reload.bind(location), 1500);
      }
    });
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
        if(result2['status']['overall']){
          $("#start-monitoring-hardware-data").attr('disabled', true);
          $(".stop-hardware-monitoring-data-button").removeAttr('disabled');
          $(".hw-mon-stat-lab").html(active_msg);
          $(".hw-mon-stat-lab").removeClass('label-danger');
          $(".hw-mon-stat-lab").addClass('label-success');
        }
        else{
          $("#start-monitoring-hardware-data").removeAttr('disabled');
          $(".stop-hardware-monitoring-data-button").attr('disabled', true);
          $(".hw-mon-stat-lab").html(inactive_msg);
          $(".hw-mon-stat-lab").removeClass('label-success');
          $(".hw-mon-stat-lab").addClass('label-danger');
        }
      }
    });
  }, 1000);

  var intervalID2 = setInterval(function(){
    $.ajax({
      url: '/monitor/status/application_data',
      type: 'GET',
      success: function(result2) {
        result2 = JSON.parse(result2);
        if(result2['status']['overall']){
          $("#start-monitoring-application-data").attr('disabled', true);
          $(".stop-application-monitoring-data-button").removeAttr('disabled');
          $(".app-mon-stat-lab").html(active_msg);
          $(".app-mon-stat-lab").removeClass('label-danger');
          $(".app-mon-stat-lab").addClass('label-success');
        }
        else{
          $("#start-monitoring-application-data").removeAttr('disabled');
          $(".stop-application-monitoring-data-button").attr('disabled', true);
          $(".app-mon-stat-lab").html(inactive_msg);
          $(".app-mon-stat-lab").removeClass('label-success');
          $(".app-mon-stat-lab").addClass('label-danger');
        }
      }
    });
  }, 1000);
});