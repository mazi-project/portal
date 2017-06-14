CAMERA_ENABLED    = true  # a quick way to disable the camera module
RPI_CAM_BASE_LINK = "http://local.mazizone.eu/rpi_cam/"


module MaziCamera
  def init_camera
    MaziLogger.debug "Initializing Camera Module"
    initialize_rpi if rpi_enabled?
  end

  def initialize_rpi
    MaziLogger.debug "Initializing RPI"
    `cd /tmp; /usr/src/RPi_Cam_Web_Interface/stop.sh`
    `cd /tmp; /usr/src/RPi_Cam_Web_Interface/start.sh`
  end

  def rpi_base_link
    RPI_CAM_BASE_LINK
  end

  def camera_enabled?
    CAMERA_ENABLED && @config[:camera] && @config[:camera][:enable]
  end

  def rpi_enabled?
    ['/usr/src/RPi_Cam_Web_Interface/', '/var/www/html/rpi_cam/', '/run/shm/mjpeg/status_mjpeg.txt'].each do |item|
      if item[-1] == '/'
        return false unless File.directory?(item)
      else
        return false unless File.exists?(item)
      end
    end
    res = `ps aux | grep -v grep | grep raspimjpeg`
    return false if res.nil? || res.empty?
    true
  end

  def rpi_saved_files
    rpi_files          = {}
    rpi_files[:photos] = []
    rpi_files[:videos] = []
    `ls /var/www/html/rpi_cam/media/`.split().each do |file|
      next if file.include? ".th."
      if file.split('.')[1] == 'jpg'
        rpi_files[:photos] << "#{RPI_CAM_BASE_LINK}/media/#{file}"
      elsif file.split('.')[1] == 'mp4'
        rpi_files[:videos] << "#{RPI_CAM_BASE_LINK}/media/#{file}"
      end 
    end
    rpi_files
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
    response = 0
    `ls /var/www/html/rpi_cam/media/`.split().each do |file|
      next if file.include? ".th."
      response += 1 if file.split('.')[1] == 'jpg'
    end
    response
  end

  def number_of_videos
    response = 0
    `ls /var/www/html/rpi_cam/media/`.split().each do |file|
      next if file.include? ".th."
      response += 1 if file.split('.')[1] == '.mp4'
    end
    response
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