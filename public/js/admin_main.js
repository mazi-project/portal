$( document ).ready(function() {
  $('#loading_message').hide();

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

  $(".load_btn").click(function(){
    $('#loading_message').show();
  });
});
