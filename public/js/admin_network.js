$( document ).ready(function() {
  $('[id^=detail-]').hide();
  $('.toggle').click(function() {
    $input = $( this );
    $target = $('#'+$input.attr('data-toggle'));
    $target.slideToggle();
  });

  $('#qrcodeCanvas').qrcode({
    text  : qrcodetext
  });

  $(".configure-interface-type").on('change', function(){
    var ifc = $(this).attr('id').split('-').pop();
    var type = $(this).children(":selected").attr("value");
    console.log(ifc, type);
    $("#configure-wifi-form-" + ifc).hide();
    $("#configure-internet-form-" + ifc).hide();
    $("#configure-mesh-form-" + ifc).hide();
    $("#configure-" + type + "-form-" + ifc).show();
  });

  $( "#slider-range-min" ).slider({
    range: "min",
    value: bandwidth_limit,
    min: 0,
    max: 100,
    step: 1,
    slide: function( event, ui ) {
      $( "#amount" ).val( ui.value + ' Mbps' );
    },
    stop: function( event, ui ) {
      $('#loading_message').show();
      $.ajax({
        url: '/exec/',
        type: 'POST',
        data: {env: 'bash', cmd: 'internet.sh', limit: ui.value * 10000, no_render: true},
        success: function(result) {
          location.reload(true);
        }
      });
    }
  });
  var amount = bandwidth_limit + ' Mbps';
  if (bandwidth_limit == 0){
    amount = 'No Limit'
  }
  $( "#amount" ).val( amount );
});
