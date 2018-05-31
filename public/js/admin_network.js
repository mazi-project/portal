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
});
