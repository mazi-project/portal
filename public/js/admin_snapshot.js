$( document ).ready(function() {
  $('#download-snapshot').click(function(){
    var snapshot_name = $( "#snapshot-select-download").val();
    $.ajax({
      url: '/snapshot/',
      type: 'POST',
      data: {download: true, snapshotname: snapshot_name},
      success: function(result) {
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
        window.location.href = 'snapshots/' + snapshot_name + '_guestbook.zip';
      }
    });
  });
});
