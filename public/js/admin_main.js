function show(tag){
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
  $('.admin-logout-button').click(function(){

  });

  $('.check-updates-menu').on( "click", function(){
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
            $('.update-ready > p').text('Your server is ' + res.commits_behind + ' commits behind. Please use the button bellow to start the update proccess.');
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
