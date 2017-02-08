$( document ).ready(function() {
  console.log( "ready!" );
  $('[id^=detail-]').hide();
  $('.toggle').click(function() {
    $input = $( this );
    $target = $('#'+$input.attr('data-toggle'));
    $target.slideToggle();
  });
});
