$( document ).ready(function() {
  $('#download-snapshot').click(function(){
    var snapshot_name = $( "#snapshot-select-download").val();
    $.ajax({
      url: '/snapshot/',
      type: 'POST',
      data: {download: true, snapshotname: snapshot_name},
      success: function(result) {
        $('#loading_message').hide();
        window.location.href = 'snapshots/' + snapshot_name + '.zip';
      }
    });
  });

  $('#delete-snapshot').click(function(){
    var snapshot_name = $( "#snapshot-select").val();
    $.ajax({
      url: '/snapshot/',
      type: 'DELETE',
      data: {snapshotname: snapshot_name},
      success: function(result) {
        location.reload(true);
      }
    });
  });

  $('#download-interview-snapshot').click(function(){
    var snapshot_name = $( "#interview-snapshotname").val();
    $.ajax({
      url: '/snapshot/',
      type: 'POST',
      data: {export_app: true, snapshotname: snapshot_name, application: 'interview'},
      success: function(result) {
        $('#loading_message').hide();
        window.location.href = 'snapshots/' + snapshot_name + '_interview.zip';
      }
    });
  });

  $('#download-etherpad-snapshot').click(function(){
    var snapshot_name = $( "#etherpad-snapshotname").val();
    $.ajax({
      url: '/snapshot/',
      type: 'POST',
      data: {export_app: true, snapshotname: snapshot_name, application: 'etherpad'},
      success: function(result) {
        $('#loading_message').hide();
        window.location.href = 'snapshots/' + snapshot_name + '_etherpad.zip';
      }
    });
  });

  $('#download-guestbook-snapshot').click(function(){
    var snapshot_name = $( "#guestbook-snapshotname").val();
    $.ajax({
      url: '/snapshot/',
      type: 'POST',
      data: {export_app: true, snapshotname: snapshot_name, application: 'guestbook'},
      success: function(result) {
        $('#loading_message').hide();
        window.location.href = 'snapshots/' + snapshot_name + '_guestbook.zip';
      }
    });
  });

  $('#download-wordpress-snapshot').click(function(){
    var snapshot_name = $( "#wordpress-snapshotname").val();
    $.ajax({
      url: '/snapshot/',
      type: 'POST',
      data: {export_app: true, snapshotname: snapshot_name, application: 'wordpress'},
      success: function(result) {
        $('#loading_message').hide();
        window.location.href = 'snapshots/' + snapshot_name + '_wordpress.zip';
      }
    });
  });

  $('#download-nextcloud-snapshot').click(function(){
    var snapshot_name = $( "#nextcloud-snapshotname").val();
    $.ajax({
      url: '/snapshot/',
      type: 'POST',
      data: {export_app: true, snapshotname: snapshot_name, application: 'nextcloud'},
      success: function(result) {
        $('#loading_message').hide();
        window.location.href = 'snapshots/' + snapshot_name + '_nextcloud.zip';
      }
    });
  });

  $('#download-full-snapshot').click(function(){
    var snapshot_name = $( "#full-snapshotname").val();
    $.ajax({
      url: '/snapshot/',
      type: 'POST',
      data: {export_app: true, snapshotname: snapshot_name, application: 'full'},
      success: function(result) {
        $('#loading_message').hide();
        window.location.href = 'snapshots/' + snapshot_name + '.zip';
      }
    });
  });

  $('#download-config-snapshot').click(function(){
    var snapshot_name = $( "#config-snapshotname").val();
    $.ajax({
      url: '/snapshot/',
      type: 'POST',
      data: {export_app: true, snapshotname: snapshot_name, application: 'config'},
      success: function(result) {
        $('#loading_message').hide();
        window.location.href = 'snapshots/' + snapshot_name + '_config.zip';
      }
    });
  });

   $('.form-upload').submit(function(e) {
    var id = $(this).attr('id');
    var modal = id.replace('form', 'modal');
    $('#' + modal).modal('hide');
    return true;
  });
});
