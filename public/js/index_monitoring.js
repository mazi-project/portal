$(document).ready(function () {
  $('#world-map').vectorMap({
    map: 'world_mill',
    scaleColors: ['#C8EEFF', '#0071A4'],
    normalizeFunction: 'polynomial',
    hoverOpacity: 0.7,
    hoverColor: false,
    markerStyle: {
      initial: {
        fill: '#F8E23B',
        stroke: '#383f47'
      }
    },
    backgroundColor: '#383f47',
    markers: points,
    onMarkerClick: function(e, code){
      var id = points[code]['id'];
      $('#deployment-modal-for-' + id).modal('show');
    }
  });

  $.each(device_ids, function(i, id){
    $("#open-device-" + id + "-btn").on('click', function(e) {
      $('.modal').modal('hide');
      $('#show-device-' + id + '-modal').modal('show');
    });
  });

  $.each(temperature_data, function(device_id, sensors) {
    $.each(sensors, function(sensor_name, measurements){
      Morris.Line({
        element: 'morris-line-chart-temp-' + device_id + '-' + sensor_name,
        data: measurements,
        xkey: 'date',
        ykeys: ['temp'],
        labels: ['Temperature(Celcius)', 'Date'],
        smooth: true,
        resize: true,
        ymax: 50,
        ymin: -20,
        hideHover: 'auto'
      });
    });

    $('#show-device-' + device_id + '-modal').on('shown.bs.modal', function(e) {
      $(window).trigger('resize');
    });
  });

  $.each(humidity_data, function(device_id, sensors) {
    $.each(sensors, function(sensor_name, measurements){
      Morris.Line({
        element: 'morris-line-chart-hum-' + device_id + '-' + sensor_name,
        data: measurements,
        xkey: 'date',
        ykeys: ['hum'],
        labels: ['Humidity(Percent)', 'Date'],
        smooth: true,
        resize: true,
        ymax: 100,
        ymin: 0,
        hideHover: 'auto'
      });
    });
  });

  $.each(pressure_data, function(device_id, sensors) {
    $.each(sensors, function(sensor_name, measurements){
      Morris.Line({
        element: 'morris-line-chart-press-' + device_id + '-' + sensor_name,
        data: measurements,
        xkey: 'date',
        ykeys: ['pres'],
        labels: ['Pressure(millibars)', 'Date'],
        smooth: true,
        resize: true,
        ymax: 1200,
        ymin: 800,
        hideHover: 'auto'
      });
    });
  });

  $.each(etherpad_data, function(device_id, sensors) {
    $.each(sensors, function(sensor_name, measurements){
      switch(sensor_name) {
        case 'pads':
          Morris.Line({
            element: 'morris-line-chart-etherpad-pads-' + device_id,
            data: measurements,
            xkey: 'date',
            ykeys: ['pads'],
            labels: ['Number of Pads', 'Date'],
            smooth: true,
            resize: true,
            ymax: 50,
            ymin: 0,
            hideHover: 'auto'
          });
          break;
        case 'users':
          Morris.Line({
            element: 'morris-line-chart-etherpad-users-' + device_id,
            data: measurements,
            xkey: 'date',
            ykeys: ['users'],
            labels: ['Number of Users', 'Date'],
            smooth: true,
            resize: true,
            ymax: 50,
            ymin: 0,
            hideHover: 'auto'
          });
          break;
        case 'datasize':
          Morris.Line({
            element: 'morris-line-chart-etherpad-datasize-' + device_id,
            data: measurements,
            xkey: 'date',
            ykeys: ['datasize'],
            labels: ['Datasize', 'Date'],
            smooth: true,
            resize: true,
            ymin: 0,
            hideHover: 'auto'
          });
          break;
      }
    });
  });

  $.each(guestbook_data, function(device_id, sensors) {
    $.each(sensors, function(sensor_name, measurements){
      switch(sensor_name) {
        case 'submissions':
          Morris.Line({
            element: 'morris-line-chart-guestbook-submissions-' + device_id,
            data: measurements,
            xkey: 'date',
            ykeys: ['submissions'],
            labels: ['Number of Submissions', 'Date'],
            smooth: true,
            resize: true,
            ymax: 50,
            ymin: 0,
            hideHover: 'auto'
          });
          break;
        case 'comments':
          Morris.Line({
            element: 'morris-line-chart-guestbook-comments-' + device_id,
            data: measurements,
            xkey: 'date',
            ykeys: ['comments'],
            labels: ['Number of Comments', 'Date'],
            smooth: true,
            resize: true,
            ymax: 50,
            ymin: 0,
            hideHover: 'auto'
          });
          break;
        case 'images':
          Morris.Line({
            element: 'morris-line-chart-guestbook-images-' + device_id,
            data: measurements,
            xkey: 'date',
            ykeys: ['images'],
            labels: ['Number of Images', 'Date'],
            smooth: true,
            resize: true,
            ymax: 50,
            ymin: 0,
            hideHover: 'auto'
          });
          break;
        case 'datasize':
          Morris.Line({
            element: 'morris-line-chart-guestbook-datasize-' + device_id,
            data: measurements,
            xkey: 'date',
            ykeys: ['datasize'],
            labels: ['Datasize', 'Date'],
            smooth: true,
            resize: true,
            ymin: 0,
            hideHover: 'auto'
          });
          break;
      }
    });
  });

  $.each(framadate_data, function(device_id, sensors) {
    $.each(sensors, function(sensor_name, measurements){
      switch(sensor_name) {
        case 'polls':
          Morris.Line({
            element: 'morris-line-chart-framadate-polls-' + device_id,
            data: measurements,
            xkey: 'date',
            ykeys: ['polls'],
            labels: ['Number of Polls', 'Date'],
            smooth: true,
            resize: true,
            ymin: 0,
            hideHover: 'auto'
          });
          break;
        case 'votes':
          Morris.Line({
            element: 'morris-line-chart-framadate-votes-' + device_id,
            data: measurements,
            xkey: 'date',
            ykeys: ['votes'],
            labels: ['Number of Votes', 'Date'],
            smooth: true,
            resize: true,
            ymin: 0,
            hideHover: 'auto'
          });
          break;
        case 'comments':
          Morris.Line({
            element: 'morris-line-chart-framadate-comments-' + device_id,
            data: measurements,
            xkey: 'date',
            ykeys: ['comments'],
            labels: ['Number of Comments', 'Date'],
            smooth: true,
            resize: true,
            ymin: 0,
            hideHover: 'auto'
          });
          break;
      }
    });
  });
});
