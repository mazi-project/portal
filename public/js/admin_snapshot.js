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
        location.reload();
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
});