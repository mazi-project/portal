CAMERA_ENABLED    = true  # a quick way to disable the camera module

module MaziCamera
  def init_camera

  end

  def initialize_camera_module

  end

  def camera_enabled?
    CAMERA_ENABLED && @config[:camera] && @config[:camera][:enable]
  end

  def toggle_camera_enabled
    current_value = @config[:camera][:enable]
    changeConfigFile("camera->enable", !current_value)
    writeConfigFile
  end

  def capture_image
    img_name = "#{Time.now.strftime('%Y_%m_%d_%H_%M_%S')}.jpg"
    MaziLogger.debug "Capturing image #{img_name}"
    `raspistill -o #{@config[:camera][:photos_folder]}/#{img_name}`
    MaziLogger.debug "Image captured. Refreshing nextcloud."
    refresh_nextcloud
  end

  def start_image_capturing(duration, interval)
    MaziLogger.debug "Start capturing images: #{duration} - #{interval}"
    duration = duration.to_i * 1000
    interval = interval.to_i * 1000
    img_name = "#{Time.now.strftime('%Y_%m_%d_%H_%M_%S')}"
    Thread.new do
      MaziLogger.debug "Capturing images"
      `raspistill -t #{duration} -tl #{interval} -o #{@config[:camera][:photos_folder]}/#{img_name}%04d.jpg`
      MaziLogger.debug "Images captured. Refreshing nextcloud."
      refresh_nextcloud
    end
    sleep 1
  end

  def start_video_capturing(duration)
    video_name = "#{Time.now.strftime('%Y_%m_%d_%H_%M_%S')}.jpg"
    duration = duration.to_i * 1000
    MaziLogger.debug "Capturing video #{video_name} for #{duration} ms"
    `raspivid -t #{duration} -o #{@config[:camera][:videos_folder]}/#{video_name}.h264`
    MaziLogger.debug "Video captured. Refreshing nextcloud."
    refresh_nextcloud
  end

  def number_of_photos
    `ls #{@config[:camera][:photos_folder]}`.split.size
  end

  def number_of_videos
    `ls #{@config[:camera][:video_folder]}`.split.size
  end

  def clear_photos
    MaziLogger.debug "Deleting all photos"
    `rm #{@config[:camera][:photos_folder]}/*`
    MaziLogger.debug "Refreshing nextcloud."
    refresh_nextcloud
  end

  def clear_videos
    MaziLogger.debug "Deleting all videos"
    `rm #{@config[:camera][:photos_folder]}/*`
    MaziLogger.debug "Refreshing nextcloud."
    refresh_nextcloud
  end

  def refresh_nextcloud
    `sudo -u www-data php /var/www/html/nextcloud/occ files:scan --all`
  end
end