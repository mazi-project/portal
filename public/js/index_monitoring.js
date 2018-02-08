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

      // $('#export-temperatures-' + id).click(function(){
      //   var result = [['date', 'temperature']];
      //   tLen = data.length;
      //   for (i = 0; i < tLen; i++) {
      //     result.push([data[i].date, data[i].temp]);
      //   }
      //   exportToCsv('temperatures.csv', result);
      // });
    });
  });
});
