$( document ).ready(function() {
  $('.admin-logout-button').click(function(){

  });

  $('.language-button').click(function(){
    var appId = $(this).attr('id').split('-')[0];
    $.ajax({
      url: '/locales/' + appId,
      type: 'POST',
      success: function(result) {
        location.reload(true);
      }
    });
  });
});
