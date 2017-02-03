$( document ).ready(function() {
  console.log( "ready!" );

  $('.del_app').click(function(){
    var appId = $(this).attr('id').split('_').pop();
    console.log(appId);
    $.ajax({
      url: '/application/' + appId,
      type: 'DELETE',
      success: function(result) {
        id = JSON.parse(result).id;
        $('#app_tr_' + id).remove();
      }
    });
  });
});