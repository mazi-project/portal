var mjpeg_img;
 
function reload_img () {
  mjpeg_img.src = "http://local.mazizone.eu/rpi_cam/cam_pic.php?time=" + new Date().getTime();
}
function error_img () {
  setTimeout("mjpeg_img.src = 'http://local.mazizone.eu/rpi_cam/cam_pic.php?time=' + new Date().getTime();", 100);
}
function init() {
  mjpeg_img = document.getElementById("mjpeg_dest");
  mjpeg_img.onload = reload_img;
  mjpeg_img.onerror = error_img;
  reload_img();
}

$( document ).ready(function() {
  setTimeout('init();', 100);
  jQuery("#gallery").unitegallery(); 
});