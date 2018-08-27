function show(tag){
  $('.chooseBranch').hide();
  $('.checking4updates').hide();
  $('.staged-error').hide();
  $('.no-internet-error').hide();
  $('.demo-mode-error').hide();
  $('.up2date').hide();
  $('.update-ready').hide();
  $('.updating').hide();
  $('.staged-done').hide();
  $(tag).show();
}

$( document ).ready(function() {
  $( "#update-channel-sel" ).change(function() {
    $('#loading_message').show();
    var branch = $( "#update-channel-sel" ).val();
    $.ajax({
      url: '/branch/' + branch,
      type: 'PUT',
      success: function(result){
        location.reload(true);
      }
    });
  });

  $('.choose-branch-btn').on( "click", function(){
    show('.checking4updates');
    $.ajax({
      url: '/update/',
      type: 'GET',
      success: function(result) {
        res = JSON.parse(result);
        if(res.error){
          if(res.code == -1){
            show('.staged-error');
          }
          if(res.code == -2){
            show('.no-internet-error');
          }
          if(res.code == -3){
            show('.demo-mode-error');
          }
        }
        else if(res.current_version){
          if(res.commits_behind == 0){
            show('.up2date');
          }
          else{
            $('.update-ready > p').text(update_message_1);
            show('.update-ready');
          }
        }
      }
    });
  });

  $('.update-btn').on( "click", function(){
    show('.updating');
    $.ajax({
      url: '/update/',
      type: 'PUT',
      success: function(result) {
        res = JSON.parse(result);
        if(res.error){
          if(res.code == -1){
            show('.staged-error');
          }
          if(res.code == -2){
            show('.no-internet-error');
          }
        }
        else if(res.status == 'restarting'){
          show('.update-done');
        }
      }
    });
  });
});
