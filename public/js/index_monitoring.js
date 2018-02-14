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
      var name = points[code]['name'];
      var description = points[code]['description'];
      var admin = points[code]['admin'];
      var deployment = points[code]['deployment'];
      $('#monitoring-modal-for-' + id).modal('show');
    }
  });

  $.each(temperature_data, function(device_id, sensors) {
    var charts = [];
    $.each(sensors, function(sensor_name, measurements){
      var temp_chart = Morris.Line({
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

      charts.push(temp_chart);
    });

    $("#monitoring-modal-for-" + device_id).on('shown.bs.modal', function(e) {
      $.each(charts, function(index, chart){
        chart.redraw();
        $(window).trigger('resize');
      });
    });
  });

  $.each(humidity_data, function(device_id, sensors) {
    var charts = [];
    $.each(sensors, function(sensor_name, measurements){
      var hum_chart = Morris.Line({
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

      charts.push(hum_chart);
    });

    $("#monitoring-modal-for-" + device_id).on('shown.bs.modal', function(e) {
      $.each(charts, function(index, chart){
        chart.redraw();
        $(window).trigger('resize');
      });
    });
  });

  $.each(pressure_data, function(device_id, sensors) {
    var charts = [];
    $.each(sensors, function(sensor_name, measurements){
      var press_chart = Morris.Line({
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

      charts.push(press_chart);
    });

    $("#monitoring-modal-for-" + device_id).on('shown.bs.modal', function(e) {
      $.each(charts, function(index, chart){
        chart.redraw();
        $(window).trigger('resize');
      });
    });
  });

  $.each(etherpad_data, function(device_id, sensors) {
    var charts = [];
    $.each(sensors, function(sensor_name, measurements){
      switch(sensor_name) {
        case 'pads':
          var pads_chart = Morris.Line({
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
          charts.push(pads_chart);
          break;
        case 'users':
          var users_chart = Morris.Line({
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
          charts.push(users_chart);
          break;
        case 'datasize':
          var datasize_chart = Morris.Line({
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
          charts.push(datasize_chart);
          break;
      }
    });

    $("#monitoring-modal-for-" + device_id).on('shown.bs.modal', function(e) {
      $.each(charts, function(index, chart){
        chart.redraw();
        $(window).trigger('resize');
      });
    });
  });

  $.each(guestbook_data, function(device_id, sensors) {
    var charts = [];
    $.each(sensors, function(sensor_name, measurements){
      switch(sensor_name) {
        case 'submissions':
          var submissions_chart = Morris.Line({
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
          charts.push(submissions_chart);
          break;
        case 'comments':
          var comments_chart = Morris.Line({
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
          charts.push(comments_chart);
          break;
        case 'images':
          var images_chart = Morris.Line({
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
          charts.push(images_chart);
          break;
        case 'datasize':
          var datasize_chart = Morris.Line({
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
          charts.push(datasize_chart);
          break;
      }
    });

    $("#monitoring-modal-for-" + device_id).on('shown.bs.modal', function(e) {
      $.each(charts, function(index, chart){
        chart.redraw();
        $(window).trigger('resize');
      });
    });
  });

  $.each(framadate_data, function(device_id, sensors) {
    var charts = [];
    $.each(sensors, function(sensor_name, measurements){
      switch(sensor_name) {
        case 'polls':
          var polls_chart = Morris.Line({
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
          charts.push(polls_chart);
          break;
        case 'votes':
          var votes_chart = Morris.Line({
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
          charts.push(votes_chart);
          break;
        case 'comments':
          var comments_chart = Morris.Line({
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
          charts.push(comments_chart);
          break;
      }
    });

    $("#monitoring-modal-for-" + device_id).on('shown.bs.modal', function(e) {
      $.each(charts, function(index, chart){
        chart.redraw();
        $(window).trigger('resize');
      });
    });
  });
});
