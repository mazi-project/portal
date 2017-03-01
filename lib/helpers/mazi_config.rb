require 'yaml'

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
# - side_panel_color: side panel main color (hex value)
# - side_panel_active_color: side panel active and on hover color (hex value)
# - top_panel_color: top panel main color (hex value)
# - side_panel_active_color: top panel active and on hover color (hex value)
TEXT

DEFAULTPORTALCONF = {title: 'Mazizone Portal', applications_title: 'Mazizone', applications_subtitle: 'Applications', applications_welcome_text: 'Welcome to the Mazizone Applications Portal, please
    use the links bellow to navigate to the applications offered by this Mazizone.', side_panel_color: '222', side_panel_active_color: '080808', top_panel_color:'222', top_panel_active_color: '080808'}

module MaziConfig
  # loads the configuration file
  def loadConfigFile(file='/etc/mazi/config.yml')
    @config = YAML::load(File.open(file))
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
    @config[:portal_configuration] = DEFAULTPORTALCONF
  end
end
