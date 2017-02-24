$( document ).ready(function() {
  console.log('ready!');
  $('.show-notification-button').click(function(){
    var appId = $(this).attr('id').split('-').pop();
    var elem = $(this);
    console.log(appId);
    $.ajax({
      url: '/notification/' + appId + '/read',
      type: 'PUT',
      success: function(result) {
        id = JSON.parse(result).id;
        console.log($(this));
        elem.children('span').text('Read');
        elem.children('span').addClass('label-default').removeClass('label-success')
      }
    });
  });

  var heights = $(".panel-desc-txt-block").map(function() {
    return $(this).height();
  }).get(),
  maxHeight = Math.max.apply(null, heights);

  $(".panel-desc-txt-block").height(maxHeight);
});