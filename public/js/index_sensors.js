function exportToCsv(filename, rows) {
  var processRow = function (row) {
    var finalVal = '';
    for (var j = 0; j < row.length; j++) {
      var innerValue = row[j] === null ? '' : row[j].toString();
      if (row[j] instanceof Date) {
        innerValue = row[j].toLocaleString();
      };
      var result = innerValue.replace(/"/g, '""');
      if (result.search(/("|,|\n)/g) >= 0)
        result = '"' + result + '"';
      if (j > 0)
        finalVal += ',';
      finalVal += result;
    }
    return finalVal + '\n';
  };

  var csvFile = '';
  for (var i = 0; i < rows.length; i++) {
    csvFile += processRow(rows[i]);
  }

  var blob = new Blob([csvFile], { type: 'text/csv;charset=utf-8;' });
  if (navigator.msSaveBlob) { // IE 10+
    navigator.msSaveBlob(blob, filename);
  }
  else {
    var link = document.createElement("a");
    if (link.download !== undefined) {
      var url = URL.createObjectURL(blob);
      link.setAttribute("href", url);
      link.setAttribute("download", filename);
      link.style.visibility = 'hidden';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    }
  }
}

$(function() {
  $.each(temperature_data, function (id, data) {
    Morris.Line({
      element: 'morris-line-chart-temp-' + id,
      data: data,
      xkey: 'date',
      ykeys: ['temp'],
      labels: ['Temperature(Celcius)', 'Date'],
      smooth: false,
      resize: true,
      ymax: 50,
      ymin: -20,
      hideHover: 'auto'
    });

    $('#export-temperatures-' + id).click(function(){
      var result = [['date', 'temperature']];
      tLen = data.length;
      for (i = 0; i < tLen; i++) {
        result.push([data[i].date, data[i].temp]);
      }
      exportToCsv('temperatures.csv', result);
    });
  });

  $.each(humidity_data, function (id, data) {
    Morris.Line({
      element: 'morris-line-chart-hum-' + id,
      data: data,
      xkey: 'date',
      ykeys: ['hum'],
      labels: ['Humidity(%)', 'Date'],
      smooth: false,
      resize: true,
      ymax: 100,
      ymin: 0,
      hideHover: 'auto'
    });

    $('#export-humidity-' + id).click(function(){
      var result = [['date', 'humidity']];
      tLen = data.length;
      for (i = 0; i < tLen; i++) {
        result.push([data[i].date, data[i].hum]);
      }
      exportToCsv('humidity.csv', result);
    });
  });

  $.ajax({
    url: '/devices/sensors/sensehat/start_metrics',
    type: 'POST',
    success: function(result) {
    }
  });

  var intervalID = setInterval(function(){
    console.log('mpam');
    $.ajax({
      url: '/devices/sensors/sensehat/get_metrics',
      type: 'GET',
      success: function(result) {
        if ($(".special-metrics-panel").length <= 0){
          $.ajax({
            url: '/devices/sensors/sensehat/stop_metrics',
            type: 'DELETE',
            success: function(result) {
              clearInterval(intervalID);
            }
          });
        }
        result = JSON.parse(result);
        $(".metrics-direction-span").html(result['comp']);
        var compassDisc = document.getElementById("compassDiscImg");
        compassDisc.style.webkitTransform = "rotate("+ result['comp'] +"deg)";
        compassDisc.style.MozTransform = "rotate("+ result['comp'] +"deg)";
        compassDisc.style.transform = "rotate("+ result['comp'] +"deg)";
        $(".metrics-acceleration-span").html(result['acc'][0] + ', ' + result['acc'][1] + ', ' + result['acc'][2]);
        $(".metrics-gyroscope-span").html(result['gyro'][0] + ', ' + result['gyro'][1] + ', ' + result['gyro'][2]);
      }
    });
  }, 50);

  $(window).bind('beforeunload', function(){
    $.ajax({
      url: '/devices/sensors/sensehat/stop_metrics',
      type: 'DELETE',
      success: function(result) {
        clearInterval(intervalID);
      }
    });
    return;
  });

  $( window ).unload(function() {
    $.ajax({
      url: '/devices/sensors/sensehat/stop_metrics',
      type: 'DELETE',
      success: function(result) {
        clearInterval(intervalID);
      }
    });
  });

  $('#datetimepicker_start').datetimepicker();
  $('#datetimepicker_end').datetimepicker();
});
