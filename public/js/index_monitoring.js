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
      console.log(id, name, description, admin, deployment);
      $('#monitoring-modal-for-' + id).modal('show');
    }
  });

  $.each(temperature_data, function(device_id, sensors) {
    var charts = [];
    $.each(sensors, function(sensor_name, measurements){
      console.log(sensor_name, device_id);
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
      console.log(sensor_name, device_id);
      console.log(measurements);
      // if (measurements == ){

      // }
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
        default:
          // console.log(sensor_name);
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
    console.log(device_id, sensors);
    $.each(sensors, function(sensor_name, measurements){
      console.log(sensor_name, measurements);
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
        default:
          // console.log(sensor_name);
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
            ymax: 50,
            ymin: 0,
            hideHover: 'auto'
          });
          charts.push(polls_chart);
          break;
        default:
          // console.log(sensor_name);
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
