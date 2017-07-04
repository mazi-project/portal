$( document ).ready(function() {
  $('.show-notification-button').click(function(){
    var appId = $(this).attr('id').split('-').pop();
    var elem = $(this);
    $.ajax({
      url: '/notification/' + appId + '/read',
      type: 'PUT',
      success: function(result) {
        id = JSON.parse(result).id;
        elem.children('span').text('Read');
        elem.children('span').addClass('label-default').removeClass('label-success')
        var nof_notif = Number($(".notif-span").text()) - 1;
        if (nof_notif <= 0){
          nof_notif = '';
        }
        $(".notif-span").text( nof_notif);
      }
    });
  });

  var heights = $(".panel-desc-txt-block").map(function() {
    return $(this).height();
  }).get(),
  maxHeight = Math.max.apply(null, heights);

  $(".panel-desc-txt-block").height(maxHeight);
});