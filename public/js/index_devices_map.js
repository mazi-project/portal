$( document ).ready(function() {
  $( '.mon_map_row' ).height($( window ).height() - $( '.navbar-fixed-top' ).height() - 10);
  $( window ).resize(function() {
    $( '.mon_map_row' ).height($( window ).height() - $( '.navbar-fixed-top' ).height() - 10);
  });
});
