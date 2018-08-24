require 'yaml'
require 'zip'

TOPCOMMENTS = <<TEXT
# This is the main configuration file for the MAZI Zone portal.
# If you manually change some values on this file a server restart is
# mandatory for the changes to take effect.
# On the general section:
# - mode: (normal/demo) mode determines if there is an actual MAZI Zone
#         or this runs just for demo purposes
# On the admin section:
# - admin_username: admin username for the admin panel
# - admin_password: admin password for the admin panel.
# On the scripts section:
# - backend_scripts_folder: the folder that contains the scripts that the portal
#                           will need to execute for various actions
# - enabled_scripts: the scripts that are allowed to be executed by the
#                    backend (for security reasons)
# On the portal configuration section:
# - title: the title on both the top left corner and on browser title
# - applications_title: title on the applications body page
# - applications_subtitle: subtitle on the applications body page
# - applications_welcome_text: welcome text on the applications body page
# - applications_background_image: background image on the applications body page.
# - side_panel_color: side panel main color (hex value)
# - side_panel_active_color: side panel active and on hover color (hex value)
# - top_panel_color: top panel main color (hex value)
# - side_panel_active_color: top panel active and on hover color (hex value)
# On the sensors section:
# - enable: true/force to enable/disable the sensors tab on the user portal
# On the camera section:
# - enable: true/force to enable/disable the camera tab on the user portal
TEXT

module MaziConfig
  # loads the configuration file
  def loadConfigFile(file='/etc/mazi/config.yml')
    @config = YAML::load(File.open(file))
    @config[:portal_configuration][:applications_background_image] = 'mazi-background.jpg' if @config[:portal_configuration][:applications_background_image].nil?
    @config
  end

  # returns the current configuration (in memory)
  def readConfigFile
    @config
  end

  # changes the current configuration (in memory)
  # use -> to change deeper values (eg admin->admin_password)
  def changeConfigFile(key, value)
    keys = key.split('->')
    i = 0
    conf = nil
    keys.each do |k|
      next if i == keys.length - 1
      conf = conf.nil? ? @config[k.to_sym] : conf[k.to_sym]
      i += 1
    end
    conf[keys.last.to_sym] = value

    @config
  end

  # saves the changes on the current configuration file
  def writeConfigFile(conf=nil, file='/etc/mazi/config.yml')
    @config = conf.nil? ? readConfigFile : conf
    File.open(file, 'w+') { |f| YAML.dump(@config, f) }
    f = File.open(file, "r+")
      lines = f.readlines
    f.close

    str = TOPCOMMENTS
    lines.each  { |line| str += line }

    output = File.new(file, "w")
      output.write str
    output.close
    @config
  end

  def changePortalConfigToDefault
    @config[:portal_configuration] = {title: 'MAZI Zone Portal', applications_title: 'MAZI Zone', applications_subtitle: 'Applications', applications_welcome_text: 'Welcome to the MAZI Zone Applications Portal, please use the links bellow to navigate to the applications offered by this MAZI Zone.', applications_background_image: 'mazi-background.jpg', side_panel_color: '222', side_panel_active_color: '080808', top_panel_color:'222', top_panel_active_color: '080808'}
  end

  def getAllConfigSaves
    if @config[:general][:mode] == 'demo'
      return ['black-white.yml']
    end
    files = Dir.entries("/etc/mazi/snapshots/")
    out = []
    files.each {|file| out << file if file.include?('.yml') && file != 'default.yml'}
    out
  end

  def saveTheme(filename)
    FileUtils.cp "/etc/mazi/config.yml", "/etc/mazi/snapshots/#{filename}.yml"
  end

  def loadTheme(filename)
    YAML::load(File.open("/etc/mazi/snapshots/#{filename}"))[:portal_configuration].each do |key, value|
      changeConfigFile("portal_configuration->#{key}", value)
    end
    writeConfigFile
  end

  def getAllDBSnapshots
    if @config[:general][:mode] == 'demo'
      return ['mazi-snapshot.db']
    end
    files = Dir.entries("/etc/mazi/snapshots/")
    out = []
    files.each {|file| out << file if file.include?('.db')}
    out
  end

  def takeDBSnapshot(filename)
    FileUtils.cp "database/inventory.db", "/etc/mazi/snapshots/#{filename}.db"
    FileUtils.cp "/etc/mazi/config.yml", "/etc/mazi/snapshots/#{filename}.yml"
    FileUtils.cp "/etc/mazi/mazi.conf", "/etc/mazi/snapshots/#{filename}.conf"
    FileUtils.cp "/etc/mazi/sql.conf", "/etc/mazi/snapshots/#{filename}_sql.conf"
    ex = MaziExecCmd.new('sh', '/root/back-end/', 'current.sh', ['-s', '-p', '-c', '-m'], @config[:scripts][:enabled_scripts])
    lines = ex.exec_command.join("\n")
    File.open("/etc/mazi/snapshots/#{filename}.net", 'w') { |file| file.write(lines) }
  end

  def deleteDBSnapshot(filename)
    File.delete("/etc/mazi/snapshots/#{filename}.db") if File.exist?("/etc/mazi/snapshots/#{filename}.db")
    File.delete("/etc/mazi/snapshots/#{filename}.yml") if File.exist?("/etc/mazi/snapshots/#{filename}.yml")
    File.delete("/etc/mazi/snapshots/#{filename}.net") if File.exist?("/etc/mazi/snapshots/#{filename}.net")
    File.delete("/etc/mazi/snapshots/#{filename}.conf") if File.exist?("/etc/mazi/snapshots/#{filename}.conf")
    File.delete("/etc/mazi/snapshots/#{filename}_sql.conf") if File.exist?("/etc/mazi/snapshots/#{filename}_sql.conf")
  end

  def loadDBSnapshot(filename)
    FileUtils.cp "/etc/mazi/snapshots/#{filename}.db", "database/inventory.db"
    FileUtils.cp "/etc/mazi/snapshots/#{filename}.conf", "/etc/mazi/mazi.conf"
    FileUtils.cp "/etc/mazi/snapshots/#{filename}_sql.conf", "/etc/mazi/sql.conf"
    args = []
    File.readlines("/etc/mazi/snapshots/#{filename}.net").each do |line|
      line = line.split
      case line.shift
      when 'ssid'
        arg = line.join(' ')
        args << "-s '#{arg}'"
      when 'channel'
        arg = line.join(' ')
        args << "-c '#{arg}'"
      when 'password'
        arg = line.join(' ')
        args << (arg == '-' ? "-w off" : "-p #{arg}")
      when 'mode'
        arg = line.join(' ')
        MaziExecCmd.new('sh', '/root/back-end/', 'internet.sh', ["-m #{arg}"], @config[:scripts][:enabled_scripts]).exec_command
      end
    end
    MaziExecCmd.new('sh', '/root/back-end/', 'wifiap.sh', args, @config[:scripts][:enabled_scripts]).exec_command
    `rake db:migrate`
    `service mazi-portal restart`
  end

  def changeSnapshotToDefault

  end

  def zip_snapshot(snapshot_name)
    File.delete("public/snapshots/#{snapshot_name}.zip") if File.exist?("public/snapshots/#{snapshot_name}.zip")
    folder = "/etc/mazi/snapshots/"
    input_filenames = ["#{snapshot_name}.db", "#{snapshot_name}.net", "#{snapshot_name}.yml", "#{snapshot_name}.conf", "#{snapshot_name}_sql.conf"]

    Zip.on_exists_proc = false
    Zip::File.open("public/snapshots/#{snapshot_name}.zip", Zip::File::CREATE) do |zipfile|
      input_filenames.each do |filename|
        zipfile.add(filename, folder + '/' + filename)
      end
      zipfile.add(@config[:portal_configuration][:applications_background_image], "public/images/#{@config[:portal_configuration][:applications_background_image]}")
      zipfile.get_output_stream("README.txt") { |os| os.write "Snapshot #{snapshot_name} has been downloaded at #{Time.now}. \nThis is an autogenerated file. \nYou can upload this file back to the MAZI Zone portal through the admin panel in order to achieve a previous state of the portal.\n" }
    end
  end

  def unzip_snapshot(filename, tempfile)
    Zip::File.open(tempfile.path) do |zip_file|
      zip_file.each do |entry|
        next if entry.name == 'README.txt'
        if entry.name.include?('.jpg') || entry.name.include?('.png')
          File.delete("public/images/#{entry.name}") if File.exist?("public/images/#{entry.name}")
          entry.extract("public/images/#{entry.name}")
        else
          File.delete("/etc/mazi/snapshots/#{entry.name}") if File.exist?("/etc/mazi/snapshots/#{entry.name}")
          entry.extract("/etc/mazi/snapshots/#{entry.name}")
        end
      end
    end
  end

  def zip_full_snapshot(snapshot_name, usb_target)
    mysql_user, mysql_password = get_mysql_details
    File.delete("#{usb_target}/#{snapshot_name}.zip") if File.file?("#{usb_target}/#{snapshot_name}.zip")
    Dir.mkdir("#{usb_target}/#{snapshot_name}_tmp") unless Dir.exist?("#{usb_target}/#{snapshot_name}_tmp")
    input_filenames = ["database/inventory.db", "/etc/mazi/config.yml", "/etc/mazi/mazi.conf", "/etc/mazi/sql.conf", "/etc/mazi/users.dat",
                       "/etc/hostapd/replace.sed", "/etc/hostapd/hostapd.conf", "/etc/hostapd/template_80211n.txt ", "/etc/nodogsplash/nodogsplash.conf",
                       "/etc/nodogsplash/offline.txt", "/etc/nodogsplash/online.txt", "/etc/wpa_supplicant/wpa_supplicant.conf", "/etc/dnsmasq.conf",
                       "/etc/apache2/sites-available/portal.conf", "/tmp/network.net"]

    ex = MaziExecCmd.new('bash', '/root/back-end/', 'current.sh', ['-s', '-p', '-c', '-m'], @config[:scripts][:enabled_scripts])
    lines = ex.exec_command.join("\n")
    File.open("/tmp/network.net", 'w') { |file| file.write(lines) }
    MaziLogger.debug('Zipping Etherpad')
    db = "etherpad"
    `mysqldump -u #{mysql_user} -p#{mysql_password} #{db} > #{usb_target}/#{snapshot_name}_tmp/#{snapshot_name}_etherpad.sql`
    MaziLogger.debug('Zipping Nextcloud')
    db = "nextcloud"
    `sudo -u www-data php occ maintenance:mode --on`
    `mysqldump -u #{mysql_user} -p#{mysql_password} #{db} > #{usb_target}/#{snapshot_name}_tmp/#{snapshot_name}_nextcloud.sql`
    `cd /var/www/html/nextcloud/ && zip -r -1 #{usb_target}/#{snapshot_name}_tmp/#{snapshot_name}_nextcloud_config.zip config/`
    `cd /var/www/html/nextcloud/ && zip -r -1 #{usb_target}/#{snapshot_name}_tmp/#{snapshot_name}_nextcloud_data.zip data/`
    `cd /var/www/html/nextcloud/ && zip -r -1 #{usb_target}/#{snapshot_name}_tmp/#{snapshot_name}_nextcloud_themes.zip themes/`
    MaziLogger.debug('Zipping WordPress')
    db = "wordpress"
    `mysqldump -u #{mysql_user} -p#{mysql_password} #{db} > #{usb_target}/#{snapshot_name}_tmp/#{snapshot_name}_wordpress.sql`
    `cd /var/www/html/ && zip -r -1 #{usb_target}/#{snapshot_name}_tmp/#{snapshot_name}_wordpress_files.zip wordpress/`
    MaziLogger.debug('Zipping Guestbook')
    db = "letterbox"
    `mongoexport --db #{db} -c submissions --out #{usb_target}/#{snapshot_name}_tmp/#{snapshot_name}_guestbook.json`
    guestbook_path = "/var/www/html/mazi-board/src/files"
    interview_path = '/var/www/html/mazi-princess/src/server/node/files'

    Zip.on_exists_proc = false
    MaziLogger.debug('Creating final zip file')
    Zip::File.open("#{usb_target}/#{snapshot_name}.zip", Zip::File::CREATE) do |zipfile|
      input_filenames.each do |filename|
        zipfile.add('config/' + filename.split('/').last, filename) if File.file?(filename)
      end
      zipfile.add('config/' + @config[:portal_configuration][:applications_background_image], "public/images/#{@config[:portal_configuration][:applications_background_image]}")
      zipfile.add("etherpad/#{snapshot_name}_etherpad.sql", "#{usb_target}/#{snapshot_name}_tmp/#{snapshot_name}_etherpad.sql")
      zipfile.add("nextcloud/#{snapshot_name}_nextcloud.sql", "#{usb_target}/#{snapshot_name}_tmp/#{snapshot_name}_nextcloud.sql")
      zipfile.add("nextcloud/config.zip", "#{usb_target}/#{snapshot_name}_tmp/#{snapshot_name}_nextcloud_config.zip")
      zipfile.add("nextcloud/data.zip", "#{usb_target}/#{snapshot_name}_tmp/#{snapshot_name}_nextcloud_data.zip")
      zipfile.add("nextcloud/themes.zip", "#{usb_target}/#{snapshot_name}_tmp/#{snapshot_name}_nextcloud_themes.zip")
      zipfile.add("wordpress/#{snapshot_name}_wordpress.sql", "#{usb_target}/#{snapshot_name}_tmp/#{snapshot_name}_wordpress.sql")
      zipfile.add("wordpress/files.zip", "#{usb_target}/#{snapshot_name}_tmp/#{snapshot_name}_wordpress_files.zip")
      Dir["#{guestbook_path}/**/**"].each do |file|
        zipfile.add("guestbook/" + file.sub(guestbook_path+'/',''), file)
      end
      zipfile.add("guestbook/#{snapshot_name}_guestbook.json", "#{usb_target}/#{snapshot_name}_tmp/#{snapshot_name}_guestbook.json")
      zipfile.add("guestbook/config.js", "/var/www/html/mazi-board/src/www/js/config.js")
      zipfile.add("guestbook/main.config.js", "/var/www/html/mazi-board/src/node/main.config.js")
      zipfile.add("guestbook/be.config.js", "/var/www/html/mazi-board/src/node/config.js")
      zipfile.add('guestbook/submission_input_tmpl.html', '/var/www/html/mazi-board/src/www/js/templates/submission_input_tmpl.html')
      zipfile.add('guestbook/header_tmpl.html', '/var/www/html/mazi-board/src/www/js/templates/header_tmpl.html')
      bgimgname = get_guestbook_background_image_name
      zipfile.add("guestbook/mzbgimg_#{bgimgname}", "/var/www/html/mazi-board/src/www/images/#{bgimgname}")
      Dir["#{interview_path}/**/**"].each do |file|
        zipfile.add("interview/" + file.sub(interview_path+'/', ''), file)
      end
      zipfile.add('interview/attachments.db', '/var/www/html/mazi-princess/src/server/node/data/attachments.db')
      zipfile.add('interview/interviews.db', '/var/www/html/mazi-princess/src/server/node/data/interviews.db')
      zipfile.get_output_stream("README.txt") { |os| os.write "Snapshot #{snapshot_name} has been downloaded at #{Time.now}. \nThis is an autogenerated file. \nYou can upload this file back to the MAZI Zone portal through the admin panel in order to achieve a previous state of the portal.\n" }
    end

    MaziLogger.debug('Removing tmp files')
    `rm -f /tmp/network.net`
    `rm -rf #{usb_target}/#{snapshot_name}_tmp`
    `sudo -u www-data php occ maintenance:mode --off`
    MaziLogger.debug("done with snapshot #{usb_target}/#{snapshot_name}.zip")
    "#{usb_target}/#{snapshot_name}.zip"
  end

  def unzip_full_snapshot(usb_target, filename)
    mysql_user, mysql_password = get_mysql_details
    Dir.mkdir("#{usb_target}/.mazi_tmp") unless Dir.exist?("#{usb_target}/.mazi_tmp")
    input_filenames = { "inventory.db" => "database/inventory.db", "config.yml" => "/etc/mazi/config.yml", "mazi.conf" => "/etc/mazi/mazi.conf", "sql.conf" => "/etc/mazi/sql.conf",
                        "users.dat" => "/etc/mazi/users.dat", "replace.sed" => "/etc/hostapd/replace.sed", "hostapd.conf" => "/etc/hostapd/hostapd.conf", "template_80211n.txt" => "/etc/hostapd/template_80211n.txt ",
                        "nodogsplash.conf" => "/etc/nodogsplash/nodogsplash.conf", "offline.txt" => "/etc/nodogsplash/offline.txt", "online.txt" => "/etc/nodogsplash/online.txt",
                        "wpa_supplicant.conf" => "/etc/wpa_supplicant/wpa_supplicant.conf", "dnsmasq.conf" => "/etc/dnsmasq.conf", "portal.conf" => "/etc/apache2/sites-available/portal.conf",
                        "network.net" => "/tmp/network.net"}
    File.delete("#{usb_target}/.mazi_tmp/network.net") if File.file?("#{usb_target}/.mazi_tmp/network.net")
    Zip::File.open(filename) do |zip_file|
      zip_file.each do |entry|
        next if entry.name == 'README.txt'
        if entry.name.start_with?('config/')
          filename = entry.name.gsub('config/', '')
          if filename.include?('.jpg') || filename.include?('.png')
            File.delete("public/images/#{filename}") if File.exist?("public/images/#{filename}")
            entry.extract("public/images/#{filename}")
          else
            target = input_filenames[filename]
            File.delete(target) if File.file?(target)
            entry.extract(target)
            `chmod +w #{target}` if filename.include?('.db')
          end
        elsif entry.name.start_with?('etherpad/')
          db = 'etherpad'
          filename = entry.name.gsub('etherpad/', '')
          File.delete("#{usb_target}/.mazi_tmp/#{filename}") if File.exist?("#{usb_target}/.mazi_tmp/#{filename}")
          entry.extract("#{usb_target}/.mazi_tmp/#{filename}")
          `mysql -u #{mysql_user} -p#{mysql_password} #{db} < #{usb_target}/.mazi_tmp/#{filename}`
        elsif entry.name.start_with?('nextcloud/')
          db = 'nextcloud'
          filename = entry.name.gsub('nextcloud/', '')
          `sudo -u www-data php occ maintenance:mode --on`
          File.delete("#{usb_target}/.mazi_tmp/#{filename}") if File.exist?("#{usb_target}/.mazi_tmp/#{filename}")
          entry.extract("#{usb_target}/.mazi_tmp/#{filename}")
          if filename.include?('.zip')
            `rm -rf /var/www/html/nextcloud/#{filename.gsub('.zip', '')}`
            `unzip #{usb_target}/.mazi_tmp/#{filename} -d /var/www/html/nextcloud/`
            `chown -R www-data:www-data /var/www/html/nextcloud/#{filename.gsub('.zip', '')}/`
          else
            `mysql -u #{mysql_user} -p#{mysql_password} #{db} < #{usb_target}/.mazi_tmp/#{filename}`
          end
          `sudo -u www-data php occ maintenance:mode --off`
        elsif entry.name.start_with?('wordpress/')
          db = "wordpress"
          filename = entry.name.gsub('wordpress/', '')
          File.delete("#{usb_target}/.mazi_tmp/#{filename}") if File.exist?("#{usb_target}/.mazi_tmp/#{filename}")
          entry.extract("#{usb_target}/.mazi_tmp/#{filename}")
          if filename.include?('.zip')
            `rm -rf /var/www/html/wordpress`
            `unzip #{usb_target}/.mazi_tmp/#{filename} -d /var/www/html/`
            `chown -R www-data:www-data /var/www/html/wordpress/`
          else
            `mysql -u #{mysql_user} -p#{mysql_password} #{db} < #{usb_target}/.mazi_tmp/#{filename}`
          end
        elsif entry.name.start_with?('guestbook/')
          path = "/var/www/html/mazi-board/src/files"
          filename = entry.name.gsub('guestbook/', '')
          if filename.include?('.json')
            File.delete("#{usb_target}/.mazi_tmp/#{filename}") if File.exist?("#{usb_target}/.mazi_tmp/#{filename}")
            entry.extract("#{usb_target}/.mazi_tmp/#{filename}")
            `mongoimport --db letterbox --collection submissions --drop --file #{usb_target}/.mazi_tmp/#{filename}`
          elsif filename.include?('mzbgimg_')
            img_name = filename.gsub('mzbgimg_', '')
            File.delete("/var/www/html/mazi-board/src/www/images/#{img_name}") if File.exist?("/var/www/html/mazi-board/src/www/images/#{img_name}")
            entry.extract("/var/www/html/mazi-board/src/www/images/#{img_name}")
          elsif filename == 'main.config.js'
            File.delete("/var/www/html/mazi-board/src/node/main.config.js") if File.exist?("/var/www/html/mazi-board/src/node/main.config.js")
            if get_guestbook_version == '0.1'
              File.delete("/root/tmp_config.js") if File.exist?("/root/tmp_config.js")
              entry.extract("/root/tmp_config.js")
              if get_guestbook_config_file_version("/root/tmp_config.js", "back-end") == "0.0.1"
                update_guestbook_config_file_version("/root/tmp_config.js", "back-end")
                FileUtils.cp("/root/tmp_config.js", "/var/www/html/mazi-board/src/node/main.config.js")
              end
              File.delete("/root/tmp_config.js")
            else
              entry.extract("/var/www/html/mazi-board/src/node/main.config.js")
            end
          elsif filename == 'be.config.js'
            File.delete("/var/www/html/mazi-board/src/node/config.js") if File.exist?("/var/www/html/mazi-board/src/node/config.js")
            entry.extract("/var/www/html/mazi-board/src/node/config.js")
          elsif filename == 'config.js'
            File.delete("/var/www/html/mazi-board/src/www/js/config.js") if File.exist?("/var/www/html/mazi-board/src/www/js/config.js")
            if get_guestbook_version == '0.1'
              File.delete("/root/tmp_config.js") if File.exist?("/root/tmp_config.js")
              entry.extract("/root/tmp_config.js")
              if get_guestbook_config_file_version("/root/tmp_config.js", "front-end") == "0.0.1"
                update_guestbook_config_file_version("/root/tmp_config.js", "front-end")
                FileUtils.cp("/root/tmp_config.js", "/var/www/html/mazi-board/src/www/js/config.js")
              else
                FileUtils.cp("/root/tmp_config.js", "/var/www/html/mazi-board/src/www/js/config.js")
              end
              File.delete("/root/tmp_config.js")
            else
              entry.extract("/var/www/html/mazi-board/src/www/js/config.js")
            end
          elsif filename == 'submission_input_tmpl.html'
            File.delete("/var/www/html/mazi-board/src/www/js/templates/submission_input_tmpl.html") if File.exist?("/var/www/html/mazi-board/src/www/js/templates/submission_input_tmpl.html")
            entry.extract("/var/www/html/mazi-board/src/www/js/templates/submission_input_tmpl.html")
          elsif filename == 'header_tmpl.html'
            File.delete("/var/www/html/mazi-board/src/www/js/templates/header_tmpl.html") if File.exist?("/var/www/html/mazi-board/src/www/js/templates/header_tmpl.html")
            entry.extract("/var/www/html/mazi-board/src/www/js/templates/header_tmpl.html")
          else
            if File.directory?("#{path}/#{filename}")
              FileUtils.rm_rf("#{path}/#{filename}")
            elsif File.exist?("#{path}/#{filename}")
              File.delete("#{path}/#{filename}")
            end
            entry.extract("#{path}/#{filename}")
          end
        elsif entry.name.start_with?('interview/')
          path = '/var/www/html/mazi-princess/src/server/node/files'
          filename = entry.name.gsub('interview/', '')
          if filename.include?('.db')
            if filename == 'interviews.db'
              STDOUT.flush
              File.delete("/var/www/html/mazi-princess/src/server/node/data/interviews.db") if File.exist?("/var/www/html/mazi-princess/src/server/node/data/interviews.db")
              entry.extract("/var/www/html/mazi-princess/src/server/node/data/interviews.db")
            elsif filename == 'attachments.db'
              File.delete("/var/www/html/mazi-princess/src/server/node/data/attachments.db") if File.exist?("/var/www/html/mazi-princess/src/server/node/data/attachments.db")
              entry.extract("/var/www/html/mazi-princess/src/server/node/data/attachments.db")
            end
          else
            if File.directory?("#{path}/#{filename}")
              FileUtils.rm_rf("#{path}/#{filename}")
            elsif File.exist?("#{path}/#{filename}")
              File.delete("#{path}/#{filename}")
            end
            entry.extract("#{path}/#{filename}")
          end
        end
      end
    end
    if File.file?("#{usb_target}/.mazi_tmp/network.net")
      args = []
      File.readlines("#{usb_target}/.mazi_tmp/network.net").each do |line|
        line = line.split
        case line.shift
        when 'ssid'
          arg = line.join(' ')
          args << "-s '#{arg}'"
        when 'channel'
          arg = line.join(' ')
          args << "-c '#{arg}'"
        when 'password'
          arg = line.join(' ')
          args << (arg == '-' ? "-w off" : "-p #{arg}")
        when 'mode'
          arg = line.join(' ')
          MaziExecCmd.new('bash', '/root/back-end/', 'internet.sh', ["-m #{arg}"], @config[:scripts][:enabled_scripts]).exec_command
        end
      end
      MaziExecCmd.new('bash', '/root/back-end/', 'wifiap.sh', args, @config[:scripts][:enabled_scripts]).exec_command
    end
    `rm -rf #{usb_target}/.mazi_tmp/`
    `rake db:migrate`
    `reboot`
  end

  def zip_config_snapshot(snapshot_name)
    File.delete("public/snapshots/#{snapshot_name}_config.zip") if File.file?("public/snapshots/#{snapshot_name}_config.zip")
    input_filenames = ["database/inventory.db", "/etc/mazi/config.yml", "/etc/mazi/mazi.conf", "/etc/mazi/sql.conf", "/etc/mazi/users.dat",
                       "/etc/hostapd/replace.sed", "/etc/hostapd/hostapd.conf", "/etc/hostapd/template_80211n.txt ", "/etc/nodogsplash/nodogsplash.conf",
                       "/etc/nodogsplash/offline.txt", "/etc/nodogsplash/online.txt", "/etc/wpa_supplicant/wpa_supplicant.conf", "/etc/dnsmasq.conf",
                       "/etc/apache2/sites-available/portal.conf", "/tmp/network.net"]

    ex = MaziExecCmd.new('bash', '/root/back-end/', 'current.sh', ['-s', '-p', '-c', '-m'], @config[:scripts][:enabled_scripts])
    lines = ex.exec_command.join("\n")
    File.open("/tmp/network.net", 'w') { |file| file.write(lines) }

    Zip.on_exists_proc = false
    Zip::File.open("public/snapshots/#{snapshot_name}_config.zip", Zip::File::CREATE) do |zipfile|
      input_filenames.each do |filename|
        zipfile.add(filename.split('/').last, filename) if File.file?(filename)
      end
      zipfile.add(@config[:portal_configuration][:applications_background_image], "public/images/#{@config[:portal_configuration][:applications_background_image]}")
      zipfile.get_output_stream("README.txt") { |os| os.write "Snapshot #{snapshot_name} has been downloaded at #{Time.now}. \nThis is an autogenerated file. \nYou can upload this file back to the MAZI Zone portal through the admin panel in order to achieve a previous state of the portal.\n" }
    end
    `rm -f /tmp/network.net`
  end

  def unzip_config_snapshot(filename, tempfile)
    input_filenames = { "inventory.db" => "database/inventory.db", "config.yml" => "/etc/mazi/config.yml", "mazi.conf" => "/etc/mazi/mazi.conf", "sql.conf" => "/etc/mazi/sql.conf",
                        "users.dat" => "/etc/mazi/users.dat", "replace.sed" => "/etc/hostapd/replace.sed", "hostapd.conf" => "/etc/hostapd/hostapd.conf", "template_80211n.txt" => "/etc/hostapd/template_80211n.txt ",
                        "nodogsplash.conf" => "/etc/nodogsplash/nodogsplash.conf", "offline.txt" => "/etc/nodogsplash/offline.txt", "online.txt" => "/etc/nodogsplash/online.txt",
                        "wpa_supplicant.conf" => "/etc/wpa_supplicant/wpa_supplicant.conf", "dnsmasq.conf" => "/etc/dnsmasq.conf", "portal.conf" => "/etc/apache2/sites-available/portal.conf",
                        "network.net" => "/tmp/network.net"}

    File.delete("/tmp/network.net") if File.file?("/tmp/network.net")
    Zip::File.open(tempfile.path) do |zip_file|
      zip_file.each do |entry|
        next if entry.name == 'README.txt'
        if entry.name.include?('.jpg') || entry.name.include?('.png')
          File.delete("public/images/#{entry.name}") if File.exist?("public/images/#{entry.name}")
          entry.extract("public/images/#{entry.name}")
        else
          target = input_filenames[entry.name]
          File.delete(target) if File.file?(target)
          entry.extract(target)
          `chmod +w #{target}` if entry.name.include?('.db')
        end
      end
    end
    if File.file?("/tmp/network.net")
      args = []
      File.readlines("/tmp/network.net").each do |line|
        line = line.split
        case line.shift
        when 'ssid'
          arg = line.join(' ')
          args << "-s '#{arg}'"
        when 'channel'
          arg = line.join(' ')
          args << "-c '#{arg}'"
        when 'password'
          arg = line.join(' ')
          args << (arg == '-' ? "-w off" : "-p #{arg}")
        when 'mode'
          arg = line.join(' ')
          MaziExecCmd.new('bash', '/root/back-end/', 'internet.sh', ["-m #{arg}"], @config[:scripts][:enabled_scripts]).exec_command
        end
      end
      MaziExecCmd.new('bash', '/root/back-end/', 'wifiap.sh', args, @config[:scripts][:enabled_scripts]).exec_command
      `rm -f /tmp/network.net`
    end
    `rake db:migrate`
    `service mazi-portal restart`
  end

  def zip_app_snapshot(app_name, snapshot_name)
    mysql_user, mysql_password = get_mysql_details
    File.delete("public/snapshots/#{snapshot_name}_#{app_name}.zip") if File.exist?("public/snapshots/#{snapshot_name}_#{app_name}.zip")
    if app_name == 'etherpad'
      db = "etherpad"
      `mysqldump -u #{mysql_user} -p#{mysql_password} #{db} > /tmp/#{snapshot_name}_#{app_name}.sql`

      Zip.on_exists_proc = false
      Zip::File.open("public/snapshots/#{snapshot_name}_#{app_name}.zip", Zip::File::CREATE) do |zipfile|
        zipfile.add("#{snapshot_name}_#{app_name}.sql", "/tmp/#{snapshot_name}_#{app_name}.sql")
        zipfile.get_output_stream("README.txt") { |os| os.write "Snapshot '#{snapshot_name}' for the application '#{app_name}' has been downloaded at #{Time.now}. \nThis is an autogenerated file. \nYou can upload this file back to the MAZI Zone portal through the admin panel in order to achieve a previous state of the application '#{app_name}'.\n" }
      end
      `rm /tmp/#{snapshot_name}_#{app_name}.sql`
    elsif app_name == 'nextcloud'
      db = "nextcloud"
      `sudo -u www-data php occ maintenance:mode --on`
      `mysqldump -u #{mysql_user} -p#{mysql_password} #{db} > /tmp/#{snapshot_name}_#{app_name}.sql`
      `cd /var/www/html/nextcloud/ && zip -r -1 /tmp/#{snapshot_name}_#{app_name}_config.zip config/`
      `cd /var/www/html/nextcloud/ && zip -r -1 /tmp/#{snapshot_name}_#{app_name}_data.zip data/`
      `cd /var/www/html/nextcloud/ && zip -r -1 /tmp/#{snapshot_name}_#{app_name}_themes.zip themes/`
      Zip.on_exists_proc = false
      Zip::File.open("public/snapshots/#{snapshot_name}_#{app_name}.zip", Zip::File::CREATE) do |zipfile|
        zipfile.add("#{snapshot_name}_#{app_name}.sql", "/tmp/#{snapshot_name}_#{app_name}.sql")
        zipfile.add("config.zip", "/tmp/#{snapshot_name}_#{app_name}_config.zip")
        zipfile.add("data.zip", "/tmp/#{snapshot_name}_#{app_name}_data.zip")
        zipfile.add("themes.zip", "/tmp/#{snapshot_name}_#{app_name}_themes.zip")
        zipfile.get_output_stream("README.txt") { |os| os.write "Snapshot '#{snapshot_name}' for the application '#{app_name}' has been downloaded at #{Time.now}. \nThis is an autogenerated file. \nYou can upload this file back to the MAZI Zone portal through the admin panel in order to achieve a previous state of the application '#{app_name}'.\n" }
      end
      `sudo -u www-data php occ maintenance:mode --off`
      `rm /tmp/#{snapshot_name}_#{app_name}.sql`
      `rm /tmp/#{snapshot_name}_#{app_name}_themes.zip`
      `rm /tmp/#{snapshot_name}_#{app_name}_data.zip`
      `rm /tmp/#{snapshot_name}_#{app_name}_config.zip`
    elsif app_name == 'wordpress'
      db = "wordpress"

      `mysqldump -u #{mysql_user} -p#{mysql_password} #{db} > /tmp/#{snapshot_name}_#{app_name}.sql`
      `cd /var/www/html/ && zip -r -1 /tmp/#{snapshot_name}_#{app_name}_files.zip wordpress/`
      Zip.on_exists_proc = false
      Zip::File.open("public/snapshots/#{snapshot_name}_#{app_name}.zip", Zip::File::CREATE) do |zipfile|
        zipfile.add("#{snapshot_name}_#{app_name}.sql", "/tmp/#{snapshot_name}_#{app_name}.sql")
        zipfile.add("files.zip", "/tmp/#{snapshot_name}_#{app_name}_files.zip")
        zipfile.get_output_stream("README.txt") { |os| os.write "Snapshot '#{snapshot_name}' for the application '#{app_name}' has been downloaded at #{Time.now}. \nThis is an autogenerated file. \nYou can upload this file back to the MAZI Zone portal through the admin panel in order to achieve a previous state of the application '#{app_name}'.\n" }
      end
      `rm /tmp/#{snapshot_name}_#{app_name}.sql`
      `rm /tmp/#{snapshot_name}_#{app_name}_files.zip`
    elsif app_name == 'guestbook'
      `mongoexport --db letterbox -c submissions --out /tmp/#{snapshot_name}_#{app_name}.json`
      path = "/var/www/html/mazi-board/src/files"

      Zip.on_exists_proc = false
      Zip::File.open("public/snapshots/#{snapshot_name}_#{app_name}.zip", Zip::File::CREATE) do |zipfile|
        Dir["#{path}/**/**"].each do |file|
          zipfile.add(file.sub(path+'/',''), file)
        end
        zipfile.add("#{snapshot_name}_#{app_name}.json", "/tmp/#{snapshot_name}_#{app_name}.json")
        zipfile.add("config.js", "/var/www/html/mazi-board/src/www/js/config.js")
        zipfile.add("main.config.js", "/var/www/html/mazi-board/src/node/main.config.js")
        zipfile.add("be.config.js", "/var/www/html/mazi-board/src/node/config.js")
        zipfile.add('submission_input_tmpl.html', '/var/www/html/mazi-board/src/www/js/templates/submission_input_tmpl.html')
        zipfile.add('header_tmpl.html', '/var/www/html/mazi-board/src/www/js/templates/header_tmpl.html')
        bgimgname = get_guestbook_background_image_name
        zipfile.add("mzbgimg_#{bgimgname}", "/var/www/html/mazi-board/src/www/images/#{bgimgname}")
        zipfile.get_output_stream("README.txt") { |os| os.write "Snapshot '#{snapshot_name}' for the application '#{app_name}' has been downloaded at #{Time.now}. \nThis is an autogenerated file. \nYou can upload this file back to the MAZI Zone portal through the admin panel in order to achieve a previous state of the application '#{app_name}'.\n" }
      end
      `rm /tmp/#{snapshot_name}_#{app_name}.json`
    elsif  app_name == 'interview'
      app_dir = {interview: '/var/www/html/mazi-princess/src/server/node/files'}

      path = app_dir[app_name.downcase.to_sym] ? app_dir[app_name.downcase.to_sym] : nil
      return nil if path.nil?

      Zip.on_exists_proc = false
      Zip::File.open("public/snapshots/#{snapshot_name}_#{app_name}.zip", Zip::File::CREATE) do |zipfile|
        Dir["#{path}/**/**"].each do |file|
          zipfile.add(file.sub(path+'/', ''), file)
        end
        zipfile.add('attachments.db', '/var/www/html/mazi-princess/src/server/node/data/attachments.db')
        zipfile.add('interviews.db', '/var/www/html/mazi-princess/src/server/node/data/interviews.db')
        zipfile.get_output_stream("README.txt") { |os| os.write "Snapshot '#{snapshot_name}' for the application '#{app_name}' has been downloaded at #{Time.now}. \nThis is an autogenerated file. \nYou can upload this file back to the MAZI Zone portal through the admin panel in order to achieve a previous state of the application '#{app_name}'.\n" }
      end
    end
    "public/snapshots/#{snapshot_name}_#{app_name}.zip"
  end

  def unzip_app_snapshot(app_name, filename, tempfile)
    if app_name.downcase == 'etherpad'
      db = "etherpad"

      Zip::File.open(tempfile.path) do |zip_file|
        zip_file.each do |entry|
          next if entry.name == 'README.txt'
          File.delete("/tmp/#{entry.name}") if File.exist?("/tmp/#{entry.name}")
          entry.extract("/tmp/#{entry.name}")
          `mysql -u #{mysql_user} -p#{mysql_password} #{db} < /tmp/#{entry.name}`
          `rm /tmp/#{entry.name}`
        end
      end
    elsif app_name.downcase == 'nextcloud'
      db = "nextcloud"

      `sudo -u www-data php occ maintenance:mode --on`
      Zip::File.open(tempfile.path) do |zip_file|
        zip_file.each do |entry|
          next if entry.name == 'README.txt'
          File.delete("/tmp/#{entry.name}") if File.exist?("/tmp/#{entry.name}")
          entry.extract("/tmp/#{entry.name}")
          if entry.name.include?('.zip')
            `rm -rf /var/www/html/nextcloud/#{entry.name.gsub('.zip', '')}`
            `unzip /tmp/#{entry.name} -d /var/www/html/nextcloud/`
            `chown -R www-data:www-data /var/www/html/nextcloud/#{entry.name.gsub('.zip', '')}/`
          else
            `mysql -u #{mysql_user} -p#{mysql_password} #{db} < /tmp/#{entry.name}`
          end
          `rm /tmp/#{entry.name}`
        end
      end
      `sudo -u www-data php occ maintenance:mode --off`
    elsif app_name.downcase == 'wordpress'
      db = "wordpress"

      Zip::File.open(tempfile.path) do |zip_file|
        zip_file.each do |entry|
          next if entry.name == 'README.txt'
          File.delete("/tmp/#{entry.name}") if File.exist?("/tmp/#{entry.name}")
          entry.extract("/tmp/#{entry.name}")
          if entry.name.include?('.zip')
            `rm -rf /var/www/html/wordpress`
            `unzip /tmp/#{entry.name} -d /var/www/html/`
            `chown -R www-data:www-data /var/www/html/wordpress/`
          else
            `mysql -u #{mysql_user} -p#{mysql_password} #{db} < /tmp/#{entry.name}`
          end
          `rm /tmp/#{entry.name}`
        end
      end
    elsif app_name.downcase == 'guestbook'
      path = "/var/www/html/mazi-board/src/files"

      Zip::File.open(tempfile.path) do |zip_file|
        zip_file.each do |entry|
          next if entry.name == 'README.txt'
          if entry.name.include?('.json')
            File.delete("/tmp/#{entry.name}") if File.exist?("/tmp/#{entry.name}")
            entry.extract("/tmp/#{entry.name}")
            `mongoimport --db letterbox --collection submissions --drop --file /tmp/#{entry.name}`
            `rm /tmp/#{entry.name}`
          elsif entry.name.include?('mzbgimg_')
            img_name = entry.name.gsub('mzbgimg_', '')
            File.delete("/var/www/html/mazi-board/src/www/images/#{img_name}") if File.exist?("/var/www/html/mazi-board/src/www/images/#{img_name}")
            entry.extract("/var/www/html/mazi-board/src/www/images/#{img_name}")
          elsif entry.name == 'config.js'
            File.delete("/var/www/html/mazi-board/src/www/js/config.js") if File.exist?("/var/www/html/mazi-board/src/www/js/config.js")
            if get_guestbook_version == '0.1'
              File.delete("/root/tmp_config.js") if File.exist?("/root/tmp_config.js")
              entry.extract("/root/tmp_config.js")
              if get_guestbook_config_file_version("/root/tmp_config.js", "front-end") == "0.0.1"
                update_guestbook_config_file_version("/root/tmp_config.js", "front-end")
                FileUtils.cp("/root/tmp_config.js", "/var/www/html/mazi-board/src/www/js/config.js")
              else
                FileUtils.cp("/root/tmp_config.js", "/var/www/html/mazi-board/src/www/js/config.js")
              end
              File.delete("/root/tmp_config.js")
            else
              entry.extract("/var/www/html/mazi-board/src/www/js/config.js")
            end
          elsif entry.name == 'main.config.js'
            File.delete("/var/www/html/mazi-board/src/node/main.config.js") if File.exist?("/var/www/html/mazi-board/src/node/main.config.js")
            if get_guestbook_version == '0.1'
              File.delete("/root/tmp_config.js") if File.exist?("/root/tmp_config.js")
              entry.extract("/root/tmp_config.js")
              if get_guestbook_config_file_version("/root/tmp_config.js", "back-end") == "0.0.1"
                update_guestbook_config_file_version("/root/tmp_config.js", "back-end")
                FileUtils.cp("/root/tmp_config.js", "/var/www/html/mazi-board/src/node/main.config.js")
              end
              File.delete("/root/tmp_config.js")
            else
              entry.extract("/var/www/html/mazi-board/src/node/main.config.js")
            end
          elsif entry.name == 'be.config.js'
            File.delete("/var/www/html/mazi-board/src/node/config.js") if File.exist?("/var/www/html/mazi-board/src/node/config.js")
            entry.extract("/var/www/html/mazi-board/src/node/config.js")
          elsif entry.name == 'submission_input_tmpl.html'
            File.delete("/var/www/html/mazi-board/src/www/js/templates/submission_input_tmpl.html") if File.exist?("/var/www/html/mazi-board/src/www/js/templates/submission_input_tmpl.html")
            entry.extract("/var/www/html/mazi-board/src/www/js/templates/submission_input_tmpl.html")
          elsif entry.name == 'header_tmpl.html'
            File.delete("/var/www/html/mazi-board/src/www/js/templates/header_tmpl.html") if File.exist?("/var/www/html/mazi-board/src/www/js/templates/header_tmpl.html")
            entry.extract("/var/www/html/mazi-board/src/www/js/templates/header_tmpl.html")
          else
            if File.directory?("#{path}/#{entry.name}")
              FileUtils.rm_rf("#{path}/#{entry.name}")
            elsif File.exist?("#{path}/#{entry.name}")
              File.delete("#{path}/#{entry.name}")
            end
            entry.extract("#{path}/#{entry.name}")
          end
        end
      end
    elsif app_name.downcase == 'interview'
      path = '/var/www/html/mazi-princess/src/server/node/files'
      Zip::File.open(tempfile.path) do |zip_file|
        zip_file.each do |entry|
          next if entry.name == 'README.txt'
          if entry.name.include?('.db')
            if entry.name == 'interviews.db'
              STDOUT.flush
              File.delete("/var/www/html/mazi-princess/src/server/node/data/interviews.db") if File.exist?("/var/www/html/mazi-princess/src/server/node/data/interviews.db")
              entry.extract("/var/www/html/mazi-princess/src/server/node/data/interviews.db")
            elsif entry.name == 'attachments.db'
              File.delete("/var/www/html/mazi-princess/src/server/node/data/attachments.db") if File.exist?("/var/www/html/mazi-princess/src/server/node/data/attachments.db")
              entry.extract("/var/www/html/mazi-princess/src/server/node/data/attachments.db")
            end
          else
            if File.directory?("#{path}/#{entry.name}")
              FileUtils.rm_rf("#{path}/#{entry.name}")
            elsif File.exist?("#{path}/#{entry.name}")
              File.delete("#{path}/#{entry.name}")
            end
            entry.extract("#{path}/#{entry.name}")
          end
        end
      end
    end
  end

  def update_config_file(file='/etc/mazi/config.yml')
    `cp /etc/mazi/config.yml /etc/mazi/config.yml.bu`
    newfile = YAML.load_file 'etc/config.yml'
    oldfile = YAML.load_file '/etc/mazi/config.yml.bu'
    excluded_keys = [:scripts]
    newfile.keys.each do |key|
      next if excluded_keys.include? key
      newfile[key].merge! oldfile[key] unless oldfile[key].nil? || oldfile[key].empty?
    end

    writeConfigFile(newfile, '/etc/mazi/config.yml')
  end

  def change_mysql_password(old_password, new_password)
    `mysqladmin -u root -p'#{old_password}' password #{new_password}`
    old_details = JSON.parse(File.read('/etc/mazi/sql.conf'), symbolize_names: true)
    old_details[:password] = new_password
    File.open("/etc/mazi/sql.conf","w") do |f|
      f.write(old_details.to_json)
    end
    lines = ''
    File.readlines('/var/www/html/wordpress/wp-config.php').each do |line|
      if line.strip.start_with? "define('DB_PASSWORD',"
        lines += "define('DB_PASSWORD', '#{new_password}');"
      else
        lines += line
      end
    end
    File.open('/var/www/html/wordpress/wp-config.php', "w") {|file| file.puts lines }
  end

  def update_timezone(timezone)
    `echo "#{timezone}" > /etc/timezone`
    `dpkg-reconfigure -f noninteractive tzdata`
  end

  def get_guestbook_tags
    File.readlines('/var/www/html/mazi-board/src/www/js/config.js').each do |line|
      line = line.strip
      if line.start_with? 'tags:'
        return line.split(':').last.gsub('[', '').gsub(']', '').gsub("'", '')
      end
    end
  end

  def save_guestbook_tags(tags)
    tags = tags.gsub("'", '').split(',')
    tags = tags.map {|item| "'#{item}'"}
    tags = tags.join(", ")
    lines = ''
    File.readlines('/var/www/html/mazi-board/src/www/js/config.js').each do |line|
      if line.strip.start_with? 'tags:'
        lines += line.split(':').first + ": [#{tags}],\n"
      else
        lines += line
      end
    end
    File.open('/var/www/html/mazi-board/src/www/js/config.js', "w") {|file| file.puts lines }
  end

  def get_guestbook_background_image_name
    File.readlines('/var/www/html/mazi-board/src/www/js/templates/header_tmpl.html').each do |line|
      if line.include? 'header-image'
        return line.split('"')[3].split('/').last
      end
    end
  end

  def upload_guestbook_background_image(filename, file)
    FileUtils.cp file.path, "/var/www/html/mazi-board/src/www/images/#{filename}"

    lines = ''
    old_image = ''
    File.readlines('/var/www/html/mazi-board/src/www/js/templates/header_tmpl.html').each do |line|
      if line.include? 'header-image'
        old_image = line.split('"')[3].split('/').last
        lines += line.split('src=').first + "src=\"images/#{filename}\"></div>"
      else
        lines += line
      end
    end
    File.open('/var/www/html/mazi-board/src/www/js/templates/header_tmpl.html', "w") {|file| file.puts lines }
    File.delete("/var/www/html/mazi-board/src/www/images/#{old_image}") if File.file?("/var/www/html/mazi-board/src/www/images/#{old_image}") && old_image != "toolkit.fw.png"
  end

  def get_guestbook_maxfilesize
    File.readlines('/var/www/html/mazi-board/src/node/config.js').each do |line|
      line = line.strip
      if line.start_with? 'maxFileSize:'
        return line.split(',').first.split('*').last
      end
    end
  end

  def set_guestbook_maxfilesize(maxfilesize)
    lines = ''
    File.readlines('/var/www/html/mazi-board/src/node/config.js').each do |line|
      if line.strip.start_with? 'maxFileSize:'
        lines += line.split(':').first + ": 1024*1024*#{maxfilesize}, //in bytes\n"
      else
        lines += line
      end
    end
    File.open('/var/www/html/mazi-board/src/node/config.js', "w") {|file| file.puts lines }
  end

  def get_guestbook_welcome_message
    if get_guestbook_config_file_version("/var/www/html/mazi-board/src/www/js/config.js", 'front-end') == '0.0.1'
      File.readlines('/var/www/html/mazi-board/src/www/js/templates/submission_input_tmpl.html').each do |line|
        line = line.strip
        if line.include? 'submission-headline'
          return line.split('>')[2].split('<').first
        end
      end
    else
      File.readlines("/var/www/html/mazi-board/src/www/js/config.js").each do |line|
        line = line.strip
        if line.include? 'welcome_msg:'
          return line.split(':').last.strip
        end
      end
    end
  end

  def set_guestbook_welcome_message(welcome_message)
    if get_guestbook_config_file_version("/var/www/html/mazi-board/src/www/js/config.js", 'front-end') == '0.0.1'
      lines = ''
      File.readlines('/var/www/html/mazi-board/src/www/js/templates/submission_input_tmpl.html').each do |line|
        if line.strip.include? 'submission-headline'
          lines += line.split('<h1>').first + "<h1> #{welcome_message}<span class=\"blinking-cursor\">|</span></h1></div>\n"
        else
          lines += line
        end
      end
      File.open('/var/www/html/mazi-board/src/www/js/templates/submission_input_tmpl.html', "w") {|file| file.puts lines }
    else
      lines = ''
      File.readlines('/var/www/html/mazi-board/src/www/js/config.js').each do |line|
        if line.strip.start_with? 'welcome_msg:'
          lines += line.split(':').first + ": \"#{welcome_message}\",\n"
        else
          lines += line
        end
      end
      File.open('/var/www/html/mazi-board/src/www/js/config.js', "w") {|file| file.puts lines }
    end
  end

  def get_guestbook_auto_expand_comment
    File.readlines('/var/www/html/mazi-board/src/www/js/config.js').each do |line|
      line = line.strip
      if line.start_with? 'auto_expand_comment:'
        return line.split(':').last.split('/').first.strip!
      end
    end
  end

  def set_guestbook_auto_expand_comment(value)
    lines = ''
    File.readlines('/var/www/html/mazi-board/src/www/js/config.js').each do |line|
      if line.strip.start_with? 'auto_expand_comment:'
        lines += line.split(':').first + ": #{value}\n"
      else
        lines += line
      end
    end
    File.open('/var/www/html/mazi-board/src/www/js/config.js', "w") {|file| file.puts lines }
  end

  def get_guestbook_submission_name_req
    File.readlines('/var/www/html/mazi-board/src/node/config.js').each do |line|
      line = line.strip
      if line.start_with? 'submission_name_required:'
        return line.split(':').last.split(',').first.strip!
      end
    end
  end

  def set_guestbook_submission_name_req(value)
    lines = ''
    File.readlines('/var/www/html/mazi-board/src/node/config.js').each do |line|
      if line.strip.start_with? 'submission_name_required:'
        lines += line.gsub(',', '').split(':').first + ": #{value}\n"
      else
        lines += line
      end
    end
    File.open('/var/www/html/mazi-board/src/node/config.js', "w") {|file| file.puts lines }
  end

  def get_guestbook_config_file_version(filename, type)
    case type
    when 'front-end'
      File.readlines(filename).each do |line|
        return "0.1" if line.include?('welcome_msg')
      end
    when 'back-end'
      File.readlines(filename).each do |line|
        return "0.1" if line.include?('submission_name_required')
      end
    end
    return "0.0.1"
  end

  def update_guestbook_config_file_version(filename, type)
    lines = ''
    case type
    when 'front-end'
      flag = false
      File.readlines(filename).each do |line|
        if flag
          lines += "\t\tbackground_img: \"TODO\",\n"
          lines += "\t\twelcome_msg: \"Click here to comment on the MAZI toolkit\",\n"
          lines += "\t\tauto_expand_comment: false\n"
          lines += line
          flag = false
        else
          flag = true if line.strip.start_with? 'tags:'
          lines += line
        end
      end
      File.open(filename, "w") {|file| file.puts lines }
    when 'back-end'
      flag = false
      File.readlines(filename).each do |line|
        if flag
          lines += "\n"
          lines += "\tsubmission_name_required: true,\n"
          lines += line
          flag = false
        else
          if line.strip.start_with? 'testPort:'
            flag = true
            lines += line.gsub("\n", ",\n")
          else
            lines += line
          end
        end
      end
      File.open(filename, "w") {|file| file.puts lines }
    end
  end

  def get_guestbook_version
    JSON.parse(File.read('/var/www/html/mazi-board/src/node/package.json'))['version']
  end

  def get_apache_max_filesize
    output = '0M'
    begin
      File.readlines('/etc/php5/apache2/php.ini').each do |line|
        output = line.split('=').last.strip if line.start_with?('upload_max_filesize')
        output = line.split('=').last.strip if line.start_with?('post_max_size')
      end
    rescue Errno::ENOENT => e
      File.readlines('/etc/php/7.0/apache2/php.ini').each do |line|
        output = line.split('=').last.strip if line.start_with?('upload_max_filesize')
        output = line.split('=').last.strip if line.start_with?('post_max_size')
      end
    end
    output
  end

  def set_apache_max_filesize(size)
    lines = ''
    filename = '/etc/php5/apache2/php.ini'
    begin
      File.readlines(filename).each do |line|
        if line.start_with?('upload_max_filesize')
          lines += "upload_max_filesize = #{size}M\n"
        elsif line.start_with?('post_max_size')
          lines += "post_max_size = #{size}M\n"
        else
          lines += line
        end
      end
    rescue Errno::ENOENT => e
      filename = '/etc/php/7.0/apache2/php.ini'
      File.readlines(filename).each do |line|
        if line.start_with?('upload_max_filesize')
          lines += "upload_max_filesize = #{size}M\n"
        elsif line.start_with?('post_max_size')
          lines += "post_max_size = #{size}M\n"
        else
          lines += line
        end
      end
    end
    File.open(filename, "w") {|file| file.puts lines }
    lines = ''
    File.readlines('/var/www/html/nextcloud/.htaccess').each do |line|
      if line.include?('upload_max_filesize')
        lines += "  php_value upload_max_filesize #{size}M\n"
      elsif line.include?('post_max_size')
        lines += "  php_value post_max_size #{size}M\n"
      else
        lines += line
      end
    end
    File.open('/var/www/html/nextcloud/.htaccess', "w") {|file| file.puts lines }
  end

  def get_mysql_details
    data = JSON.parse(File.read("/etc/mazi/sql.conf"))
    [data['username'], data['password']]
  end

  def get_all_zip_files_in_device(device='/media/usb0')
    files = []
    Dir["#{device}/*.zip"].each do |file|
      files << file
    end
    files
  end

  def all_supported_timezones
    ['Africa/Abidjan', 'Africa/Accra', 'Africa/Addis_Ababa', 'Africa/Algiers', 'Africa/Asmara', 'Africa/Asmera',
     'Africa/Bamako', 'Africa/Bangui', 'Africa/Banjul', 'Africa/Bissau', 'Africa/Blantyre', 'Africa/Brazzaville',
     'Africa/Bujumbura', 'Africa/Cairo', 'Africa/Casablanca', 'Africa/Ceuta', 'Africa/Conakry', 'Africa/Dakar',
     'Africa/Dar_es_Salaam', 'Africa/Djibouti', 'Africa/Douala', 'Africa/El_Aaiun', 'Africa/Freetown', 'Africa/Gaborone',
     'Africa/Harare', 'Africa/Johannesburg', 'Africa/Kampala', 'Africa/Khartoum', 'Africa/Kigali', 'Africa/Kinshasa',
     'Africa/Lagos', 'Africa/Libreville', 'Africa/Lome', 'Africa/Luanda', 'Africa/Lubumbashi', 'Africa/Lusaka', 'Africa/Malabo',
     'Africa/Maputo', 'Africa/Maseru', 'Africa/Mbabane', 'Africa/Mogadishu', 'Africa/Monrovia', 'Africa/Nairobi', 'Africa/Ndjamena',
     'Africa/Niamey', 'Africa/Nouakchott', 'Africa/Ouagadougou', 'Africa/Porto-Novo', 'Africa/Sao_Tome', 'Africa/Timbuktu',
     'Africa/Tripoli', 'Africa/Tunis', 'Africa/Windhoek', 'America/Adak', 'America/Anchorage', 'America/Anguilla', 'America/Antigua',
     'America/Araguaina', 'America/Argentina/Buenos_Aires', 'America/Argentina/Catamarca', 'America/Argentina/ComodRivadavia',
     'America/Argentina/Cordoba', 'America/Argentina/Jujuy', 'America/Argentina/La_Rioja', 'America/Argentina/Mendoza',
     'America/Argentina/Rio_Gallegos', 'America/Argentina/San_Juan', 'America/Argentina/Tucuman', 'America/Argentina/Ushuaia',
     'America/Aruba', 'America/Asuncion', 'America/Atikokan', 'America/Atka', 'America/Bahia', 'America/Barbados', 'America/Belem',
     'America/Belize', 'America/Blanc-Sablon', 'America/Boa_Vista', 'America/Bogota', 'America/Boise', 'America/Buenos_Aires',
     'America/Cambridge_Bay', 'America/Campo_Grande', 'America/Cancun', 'America/Caracas', 'America/Catamarca', 'America/Cayenne',
     'America/Cayman', 'America/Chicago', 'America/Chihuahua', 'America/Coral_Harbour', 'America/Cordoba', 'America/Costa_Rica',
     'America/Cuiaba', 'America/Curacao', 'America/Danmarkshavn', 'America/Dawson', 'America/Dawson_Creek', 'America/Denver',
     'America/Detroit', 'America/Dominica', 'America/Edmonton', 'America/Eirunepe', 'America/El_Salvador', 'America/Ensenada',
     'America/Fort_Wayne', 'America/Fortaleza', 'America/Glace_Bay', 'America/Godthab', 'America/Goose_Bay', 'America/Grand_Turk',
     'America/Grenada', 'America/Guadeloupe', 'America/Guatemala', 'America/Guayaquil', 'America/Guyana', 'America/Halifax',
     'America/Havana', 'America/Hermosillo', 'America/Indiana/Indianapolis', 'America/Indiana/Knox', 'America/Indiana/Marengo',
     'America/Indiana/Petersburg', 'America/Indiana/Tell_City', 'America/Indiana/Vevay', 'America/Indiana/Vincennes',
     'America/Indiana/Winamac', 'America/Indianapolis', 'America/Inuvik', 'America/Iqaluit', 'America/Jamaica', 'America/Jujuy',
     'America/Juneau', 'America/Kentucky/Louisville', 'America/Kentucky/Monticello', 'America/Knox_IN', 'America/La_Paz',
     'America/Lima', 'America/Los_Angeles', 'America/Louisville', 'America/Maceio', 'America/Managua', 'America/Manaus',
     'America/Marigot', 'America/Martinique', 'America/Mazatlan', 'America/Mendoza', 'America/Menominee', 'America/Merida',
     'America/Mexico_City', 'America/Miquelon', 'America/Moncton', 'America/Monterrey', 'America/Montevideo', 'America/Montreal',
     'America/Montserrat', 'America/Nassau', 'America/New_York', 'America/Nipigon', 'America/Nome', 'America/Noronha',
     'America/North_Dakota/Center', 'America/North_Dakota/New_Salem', 'America/Panama', 'America/Pangnirtung', 'America/Paramaribo',
     'America/Phoenix', 'America/Port-au-Prince', 'America/Port_of_Spain', 'America/Porto_Acre', 'America/Porto_Velho',
     'America/Puerto_Rico', 'America/Rainy_River', 'America/Rankin_Inlet', 'America/Recife', 'America/Regina', 'America/Resolute',
     'America/Rio_Branco', 'America/Rosario', 'America/Santiago', 'America/Santo_Domingo', 'America/Sao_Paulo', 'America/Scoresbysund',
     'America/Shiprock', 'America/St_Barthelemy', 'America/St_Johns', 'America/St_Kitts', 'America/St_Lucia', 'America/St_Thomas',
     'America/St_Vincent', 'America/Swift_Current', 'America/Tegucigalpa', 'America/Thule', 'America/Thunder_Bay', 'America/Tijuana',
     'America/Toronto', 'America/Tortola', 'America/Vancouver', 'America/Virgin', 'America/Whitehorse', 'America/Winnipeg', 'America/Yakutat',
     'America/Yellowknife', 'Antarctica/Casey', 'Antarctica/Davis', 'Antarctica/DumontDUrville', 'Antarctica/Mawson', 'Antarctica/McMurdo',
     'Antarctica/Palmer', 'Antarctica/Rothera', 'Antarctica/South_Pole', 'Antarctica/Syowa', 'Antarctica/Vostok', 'Arctic/Longyearbyen',
     'Asia/Aden', 'Asia/Almaty', 'Asia/Amman', 'Asia/Anadyr', 'Asia/Aqtau', 'Asia/Aqtobe', 'Asia/Ashgabat', 'Asia/Ashkhabad',
     'Asia/Baghdad', 'Asia/Bahrain', 'Asia/Baku', 'Asia/Bangkok', 'Asia/Beirut', 'Asia/Bishkek', 'Asia/Brunei', 'Asia/Calcutta',
     'Asia/Choibalsan', 'Asia/Chongqing', 'Asia/Chungking', 'Asia/Colombo', 'Asia/Dacca', 'Asia/Damascus', 'Asia/Dhaka',
     'Asia/Dili', 'Asia/Dubai', 'Asia/Dushanbe', 'Asia/Gaza', 'Asia/Harbin', 'Asia/Hong_Kong', 'Asia/Hovd', 'Asia/Irkutsk',
     'Asia/Istanbul', 'Asia/Jakarta', 'Asia/Jayapura', 'Asia/Jerusalem', 'Asia/Kabul', 'Asia/Kamchatka', 'Asia/Karachi',
     'Asia/Kashgar', 'Asia/Katmandu', 'Asia/Krasnoyarsk', 'Asia/Kuala_Lumpur', 'Asia/Kuching', 'Asia/Kuwait', 'Asia/Macao',
     'Asia/Macau', 'Asia/Magadan', 'Asia/Makassar', 'Asia/Manila', 'Asia/Muscat', 'Asia/Nicosia', 'Asia/Novosibirsk', 'Asia/Omsk',
     'Asia/Oral', 'Asia/Phnom_Penh', 'Asia/Pontianak', 'Asia/Pyongyang', 'Asia/Qatar', 'Asia/Qyzylorda', 'Asia/Rangoon', 'Asia/Riyadh',
     'Asia/Riyadh87 ', 'Asia/Riyadh88 ', 'Asia/Riyadh89 ', 'Asia/Saigon', 'Asia/Sakhalin', 'Asia/Samarkand', 'Asia/Seoul', 'Asia/Shanghai',
     'Asia/Singapore', 'Asia/Taipei', 'Asia/Tashkent', 'Asia/Tbilisi', 'Asia/Tehran', 'Asia/Tel_Aviv ', 'Asia/Thimbu', 'Asia/Thimphu',
     'Asia/Tokyo', 'Asia/Ujung_Pandang', 'Asia/Ulaanbaatar', 'Asia/Ulan_Bator', 'Asia/Urumqi', 'Asia/Vientiane', 'Asia/Vladivostok',
     'Asia/Yakutsk', 'Asia/Yekaterinburg', 'Asia/Yerevan', 'Atlantic/Azores', 'Atlantic/Bermuda', 'Atlantic/Canary', 'Atlantic/Cape_Verde',
     'Atlantic/Faeroe', 'Atlantic/Faroe', 'Atlantic/Jan_Mayen', 'Atlantic/Madeira', 'Atlantic/Reykjavik', 'Atlantic/South_Georgia', 'Atlantic/St_Helena',
     'Atlantic/Stanley', 'Australia/ACT', 'Australia/Adelaide', 'Australia/Brisbane', 'Australia/Broken_Hill', 'Australia/Canberra', 'Australia/Currie',
     'Australia/Darwin', 'Australia/Eucla', 'Australia/Hobart', 'Australia/LHI', 'Australia/Lindeman', 'Australia/Lord_Howe', 'Australia/Melbourne',
     'Australia/NSW', 'Australia/North', 'Australia/Perth', 'Australia/Queensland', 'Australia/South', 'Australia/Sydney', 'Australia/Tasmania',
     'Australia/Victoria', 'Australia/West', 'Australia/Yancowinna', 'Brazil/Acre', 'Brazil/DeNoronha', 'Brazil/East', 'Brazil/West', 'CET',
     'CST6CDT', 'Canada/Atlantic', 'Canada/Central', 'Canada/East-Saskatchewan', 'Canada/Eastern', 'Canada/Mountain', 'Canada/Newfoundland',
     'Canada/Pacific', 'Canada/Saskatchewan', 'Canada/Yukon', 'Chile/Continental', 'Chile/EasterIsland', 'Cuba', 'EET', 'EST', 'EST5EDT',
     'Egypt', 'Eire', 'Etc/GMT', 'Etc/GMT+0', 'Etc/GMT+1', 'Etc/GMT+10', 'Etc/GMT+11', 'Etc/GMT+12', 'Etc/GMT+2', 'Etc/GMT+3', 'Etc/GMT+4',
     'Etc/GMT+5', 'Etc/GMT+6', 'Etc/GMT+7', 'Etc/GMT+8', 'Etc/GMT+9', 'Etc/GMT-0', 'Etc/GMT-1', 'Etc/GMT-10', 'Etc/GMT-11', 'Etc/GMT-12',
     'Etc/GMT-13', 'Etc/GMT-14', 'Etc/GMT-2', 'Etc/GMT-3', 'Etc/GMT-4', 'Etc/GMT-5', 'Etc/GMT-6', 'Etc/GMT-7', 'Etc/GMT-8', 'Etc/GMT-9',
     'Etc/GMT0', 'Etc/Greenwich', 'Etc/UCT', 'Etc/UTC', 'Etc/Universal', 'Etc/Zulu', 'Europe/Amsterdam', 'Europe/Andorra', 'Europe/Athens',
     'Europe/Belfast', 'Europe/Belgrade', 'Europe/Berlin', 'Europe/Bratislava', 'Europe/Brussels', 'Europe/Bucharest', 'Europe/Budapest',
     'Europe/Chisinau', 'Europe/Copenhagen', 'Europe/Dublin', 'Europe/Gibraltar', 'Europe/Guernsey', 'Europe/Helsinki', 'Europe/Isle_of_Man',
     'Europe/Istanbul', 'Europe/Jersey', 'Europe/Kaliningrad', 'Europe/Kiev', 'Europe/Lisbon', 'Europe/Ljubljana', 'Europe/London',
     'Europe/Luxembourg', 'Europe/Madrid', 'Europe/Malta', 'Europe/Mariehamn', 'Europe/Minsk', 'Europe/Monaco', 'Europe/Moscow', 'Europe/Nicosia',
     'Europe/Oslo', 'Europe/Paris', 'Europe/Podgorica', 'Europe/Prague', 'Europe/Riga', 'Europe/Rome', 'Europe/Samara', 'Europe/San_Marino',
     'Europe/Sarajevo', 'Europe/Simferopol', 'Europe/Skopje', 'Europe/Sofia', 'Europe/Stockholm', 'Europe/Tallinn', 'Europe/Tirane',
     'Europe/Tiraspol', 'Europe/Uzhgorod', 'Europe/Vaduz', 'Europe/Vatican', 'Europe/Vienna', 'Europe/Vilnius', 'Europe/Volgograd',
     'Europe/Warsaw', 'Europe/Zagreb', 'Europe/Zaporozhye', 'Europe/Zurich', 'Factory', 'GB', 'GB-Eire', 'GMT', 'GMT+0', 'GMT-0',
     'GMT0', 'Greenwich', 'HST', 'Hongkong', 'Iceland', 'Indian/Antananarivo', 'Indian/Chagos', 'Indian/Christmas', 'Indian/Cocos',
     'Indian/Comoro', 'Indian/Kerguelen', 'Indian/Mahe', 'Indian/Maldives', 'Indian/Mauritius', 'Indian/Mayotte', 'Indian/Reunion',
     'Iran', 'Israel', 'Jamaica', 'Japan', 'Kwajalein', 'Libya', 'MET', 'MST', 'MST7MDT', 'Mexico/BajaNorte', 'Mexico/BajaSur',
     'Mexico/General', 'Mideast/Riyadh87', 'Mideast/Riyadh88', 'Mideast/Riyadh89', 'NZ', 'NZ-CHAT', 'Navajo', 'PRC', 'PST8PDT',
     'Pacific/Apia', 'Pacific/Auckland', 'Pacific/Chatham', 'Pacific/Easter', 'Pacific/Efate', 'Pacific/Enderbury', 'Pacific/Fakaofo',
     'Pacific/Fiji', 'Pacific/Funafuti', 'Pacific/Galapagos', 'Pacific/Gambier', 'Pacific/Guadalcanal', 'Pacific/Guam', 'Pacific/Honolulu',
     'Pacific/Johnston', 'Pacific/Kiritimati', 'Pacific/Kosrae', 'Pacific/Kwajalein', 'Pacific/Majuro', 'Pacific/Marquesas', 'Pacific/Midway',
     'Pacific/Nauru', 'Pacific/Niue', 'Pacific/Norfolk', 'Pacific/Noumea', 'Pacific/Pago_Pago', 'Pacific/Palau', 'Pacific/Pitcairn',
     'Pacific/Ponape', 'Pacific/Port_Moresby', 'Pacific/Rarotonga', 'Pacific/Saipan', 'Pacific/Samoa', 'Pacific/Tahiti', 'Pacific/Tarawa',
     'Pacific/Tongatapu', 'Pacific/Truk', 'Pacific/Wake', 'Pacific/Wallis', 'Pacific/Yap', 'Poland', 'Portugal', 'ROC', 'ROK', 'Singapore',
     'Turkey', 'UCT', 'US/Alaska', 'US/Aleutian', 'US/Arizona', 'US/Central', 'US/East-Indiana', 'US/Eastern', 'US/Hawaii', 'US/Indiana-Starke',
     'US/Michigan', 'US/Mountain', 'US/Pacific', 'US/Pacific-New', 'US/Samoa', 'UTC', 'Universal', 'W-SU', 'WET' ]
  end
end
