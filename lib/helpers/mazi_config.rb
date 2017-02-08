require 'yaml'

module MaziConfig
  # loads the configuration file
  def loadConfigFile(file='etc/config.yml')
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
  def writeConfigFile(conf=nil, file='etc/config.yml')
    @config = conf.nil? ? readConfigFile : conf
    File.open(file, 'w+') { |f| YAML.dump(@config, f) }
    @config
  end
end
