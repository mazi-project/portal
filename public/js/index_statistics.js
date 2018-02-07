$(document).ready(function () {
  var points = [{name: 'Volos', coords: [39.366071, 22.923611], status: 'working', offsets: [0, 2]}];
  // $('#world-map').vectorMap({map: 'world_mill'});
  // new jvm.Map({
  //   container: $('#world-map'),
  //   map: 'world_mill',
  //   markers: points.map(function(h){ return {name: h.name, latLng: h.coords} })
  // });
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
    markers: [
      {latLng: [39.366071, 22.923611], name: 'Volos'}
    ]
  });
});
