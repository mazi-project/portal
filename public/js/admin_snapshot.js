$( document ).ready(function() {
  console.log( "ready!" );
  $('#download-snapshot').click(function(){
    var snapshot_name = $( "#snapshot-select-download").val();
    $.ajax({
      url: '/snapshot/',
      type: 'POST',
      data: {download: true, snapshotname: snapshot_name},
      success: function(result) {
        console.log(result);
        window.location.href = 'snapshots/' + snapshot_name + '.zip';
      }
    });
  });

  $('#download-interview-snapshot').click(function(){
    var snapshot_name = $( "#interview-snapshotname").val();
    console.log( "aaa!" +  snapshot_name);
    $.ajax({
      url: '/snapshot/',
      type: 'POST',
      data: {export_app: true, snapshotname: snapshot_name, application: 'interview'},
      success: function(result) {
        console.log(result);
        window.location.href = 'snapshots/' + snapshot_name + '_interview.zip';
      }
    });
  });
});