$( document ).ready(function() {
  $('.admin-logout-button').click(function(){

  });

  $('.reset-app-clicks').click(function(){
    $.ajax({
      url: '/application/all/click_counter',
      type: 'DELETE',
      success: function(result) {
        location.reload(true);
      }
    });
  });

  $('.reset-visits').click(function(){
    $.ajax({
      url: '/session/all',
      type: 'DELETE',
      success: function(result) {
        location.reload(true);
      }
    });
  });
});
