$( document ).ready(function() {  $('.enabled-monitoring-switch').click(function(){
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
    $(this).attr('disabled', true);
    $.ajax({
      url: '/monitor/stop/hardware_data',
      type: 'POST',
      success: function(result) {
        setTimeout(location.reload.bind(location), 1500);
      }
    });
  });

  $('.stop-application-monitoring-data-button').click(function(){
    $(this).attr('disabled', true);
    $.ajax({
      url: '/monitor/stop/application_data',
      type: 'POST',
      success: function(result) {
        setTimeout(location.reload.bind(location), 1500);
      }
    });
  });

  $('.hw-mon-stat-lab').click(function(){
    console.log('aa');
    $('#hw-monitoring-info-modal').modal('show');
  });

  $('.app-mon-stat-lab').click(function(){
    console.log('aa');
    $('#app-monitoring-info-modal').modal('show');
  });
});