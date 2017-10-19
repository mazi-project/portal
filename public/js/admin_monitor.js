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

  $('.stop-hardware-monitoring-data-button').click(function(){
    $.ajax({
      url: '/monitor/stop/hardware_data',
      type: 'POST',
      success: function(result) {
        location.reload();
      }
    });
  });

  $('.stop-application-monitoring-data-button').click(function(){
    $.ajax({
      url: '/monitor/stop/application_data',
      type: 'POST',
      success: function(result) {
        location.reload();
      }
    });
  });
});