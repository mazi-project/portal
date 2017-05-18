require 'yaml'
require 'zip'

TOPCOMMENTS = <<TEXT
# This is the main configuration file for the mazizone portal.
# If you manually change some values on this file a server restart is
# mandatory for the changes to take effect.
# On the general section:
# - mode: (normal/demo) mode determines if there is an actual mazizone 
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
    @config[:portal_configuration] = {title: 'Mazizone Portal', applications_title: 'Mazizone', applications_subtitle: 'Applications', applications_welcome_text: 'Welcome to the Mazizone Applications Portal, please use the links bellow to navigate to the applications offered by this Mazizone.', applications_background_image: 'mazi-background.jpg', side_panel_color: '222', side_panel_active_color: '080808', top_panel_color:'222', top_panel_active_color: '080808'}
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
    ex = MaziExecCmd.new('sh', '/root/back-end/', 'current.sh', ['-s', '-p', '-c', '-m'], @config[:scripts][:enabled_scripts])
    lines = ex.exec_command.join("\n")
    File.open("/etc/mazi/snapshots/#{filename}.net", 'w') { |file| file.write(lines) }
  end

  def deleteDBSnapshot(filename)
    File.delete("/etc/mazi/snapshots/#{filename}.db") if File.exist?("/etc/mazi/snapshots/#{filename}.db")
    File.delete("/etc/mazi/snapshots/#{filename}.yml") if File.exist?("/etc/mazi/snapshots/#{filename}.yml")
    File.delete("/etc/mazi/snapshots/#{filename}.net") if File.exist?("/etc/mazi/snapshots/#{filename}.net")
  end

  def loadDBSnapshot(filename)
    FileUtils.cp "/etc/mazi/snapshots/#{filename}.db", "database/inventory.db"
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
  end

  def changeSnapshotToDefault
    
  end

  def zip_snapshot(snapshot_name)
    File.delete("public/snapshots/#{snapshot_name}.zip") if File.exist?("public/snapshots/#{snapshot_name}.zip")
    folder = "/etc/mazi/snapshots/"
    input_filenames = ["#{snapshot_name}.db", "#{snapshot_name}.net", "#{snapshot_name}.yml"]

    Zip.on_exists_proc = false
    Zip::File.open("public/snapshots/#{snapshot_name}.zip", Zip::File::CREATE) do |zipfile|
      input_filenames.each do |filename|
        zipfile.add(filename, folder + '/' + filename)
      end
      zipfile.get_output_stream("README.txt") { |os| os.write "Snapshot #{snapshot_name} has been downloaded at #{Time.now}. \nThis is an autogenerated file. \nYou can upload this file back to the mazizone portal through the admin panel in order to achieve a previous state of the portal.\n" }
    end
  end

  def unzip_snapshot(filename, tempfile)
    Zip::File.open(tempfile.path) do |zip_file|
      zip_file.each do |entry|
        next if entry.name == 'README.txt'
        File.delete("/etc/mazi/snapshots/#{entry.name}") if File.exist?("/etc/mazi/snapshots/#{entry.name}")
        entry.extract("/etc/mazi/snapshots/#{entry.name}")
      end
    end
  end

  def zip_app_snapshot(app_name, snapshot_name)
    File.delete("public/snapshots/#{snapshot_name}_#{app_name}.zip") if File.exist?("public/snapshots/#{snapshot_name}_#{app_name}.zip")
    app_dir = {interview: '/var/www/html/archive/src/server/node/files'}

    path = app_dir[app_name.downcase.to_sym] ? app_dir[app_name.downcase.to_sym] : nil
    return nil if path.nil?

    Zip.on_exists_proc = false
    Zip::File.open("public/snapshots/#{snapshot_name}_#{app_name}.zip", Zip::File::CREATE) do |zipfile|
      Dir["#{path}/**/**"].each do |file|
        zipfile.add(file.sub(path+'/',''), file)
      end
      zipfile.get_output_stream("README.txt") { |os| os.write "Snapshot '#{snapshot_name}' for the application '#{app_name}' has been downloaded at #{Time.now}. \nThis is an autogenerated file. \nYou can upload this file back to the mazizone portal through the admin panel in order to achieve a previous state of the application '#{app_name}'.\n" }
    end
    "public/snapshots/#{snapshot_name}_#{app_name}.zip"
  end

  def unzip_app_snapshot(app_name, filename, tempfile)
    app_dir = {interview: '/var/www/html/archive/src/server/node/files'}

    path = app_dir[app_name.downcase.to_sym] ? app_dir[app_name.downcase.to_sym] : nil
    puts path
    return nil if path.nil?
    Zip::File.open(tempfile.path) do |zip_file|
      zip_file.each do |entry|
        next if entry.name == 'README.txt'
        File.delete("#{path}/#{entry.name}") if File.exist?("#{path}/#{entry.name}")
        entry.extract("#{path}/#{entry.name}")
      end
    end
  end

  def update_config_file(file='/etc/mazi/config.yml')
    `cp /etc/mazi/config.yml /etc/mazi/config.yml.bu`
    newfile = YAML.load_file 'etc/config.yml'
    oldfile = YAML.load_file '/etc/mazi/config.yml.bu'
    newfile.keys.each do |key|
      newfile[key].merge! oldfile[key]
    end

    writeConfigFile(newfile, '/etc/mazi/config.yml')
  end
end
