$( document ).ready(function() {
  $('.app-link').click(function(){
    var appID = $(this).attr('id').split('_').pop();
    console.log(appID);
    $.ajax({
      url: '/application/' + appID + '/click_counter/',
      type: 'PUT',
      success: function(result) {
        console.log(result);
      }
    });
  });
});