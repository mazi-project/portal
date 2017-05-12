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
  Morris.Line({
    element: 'morris-line-chart-temp',
    data: temperature_data,
    xkey: 'date',
    ykeys: ['temp'],
    labels: ['Date', 'Temperature (Celcius)'],
    smooth: false,
    resize: true,
    ymax: 50,
    ymin: -20,
    hideHover: 'auto'
  });

  Morris.Line({
    element: 'morris-line-chart-hum',
    data: humidity_data,
    xkey: 'date',
    ykeys: ['hum'],
    labels: ['Date', 'Humidity (%)'],
    smooth: false,
    resize: true,
    ymax: 100,
    ymin: 0,
    hideHover: 'auto'
  });

  $('.export-temperatures').click(function(){
    var result = [['date', 'temperature']];
    tLen = temperature_data.length;
    for (i = 0; i < tLen; i++) {
      result.push([temperature_data[i].date, temperature_data[i].temp]);
    }
    exportToCsv('temperatures.csv', result);
  });

  $('.export-humidity').click(function(){
    var result = [['date', 'humidity']];
    tLen = humidity_data.length;
    for (i = 0; i < tLen; i++) {
      result.push([humidity_data[i].date, humidity_data[i].hum]);
    }
    exportToCsv('humidity.csv', result);
  });

  jQuery('#datetimepicker_start').datetimepicker();
  jQuery('#datetimepicker_end').datetimepicker();
});
