VERSION = '2.2.0'

class ConfigCaller
  include MaziConfig
  def update_config
    @config = loadConfigFile
    @config[:scripts][:enabled_scripts] << 'mazi-router.sh' unless @config[:scripts][:enabled_scripts].include? 'mazi-router.sh'
    @config[:scripts][:enabled_scripts] << 'mazi-domain.sh' unless @config[:scripts][:enabled_scripts].include? 'mazi-domain.sh'
    writeConfigFile
  end
end

module MaziVersion
  def getVersion
    VERSION
  end

  def fetch
    `git fetch`
  end

  def current_version?
    fetch
    status = `git status`
    status.split("\n").each do |line|
      if line.start_with? "Your branch"
        return true if line.include? "up-to-date"
        return false
      end
    end
  end

  def version_difference
    fetch
    status = `git status`
    status.split("\n").each do |line|
      if line.start_with? "Your branch"
        return 0 if line.include? "up-to-date"
        return line.split[6] if line.include? 'fast-forwarded'
        return line.split[-2]
      end
    end
  end

  def staged?
    fetch
    status = `git status`
    status.split("\n").each do |line|
      return true  if line.start_with? "Changes not staged for commit:"
    end
    false
  end

  def no_internet?
    o = `ping github.com -c 3 -W 1`
    return true if o.nil? || o.empty?
    o.split("\n").each do |line|
      if line.include? 'packets transmitted'
        return true if line.split[3] == '0'
        break
      end
    end
    false
  end

  def version_update
    MaziLogger.debug "Version Update Started"
    fetch
    MaziLogger.debug "Fetch done."
    diff   = version_difference
    staged = staged?
    if diff.to_i > 0 && !staged
      MaziLogger.debug "pull origin master"
      `git pull origin master`
      MaziLogger.debug "done."
      MaziLogger.debug "db migrate"
      `rake db:migrate`
      MaziLogger.debug "done."
      `cp /etc/mazi/config.yml /etc/mazi/config.yml.bu`
      MaziLogger.debug "Updating back-end scripts"
      `cd /root/back-end && git pull origin master`
      MaziLogger.debug "done."
    end
    nil
  end

  def self.guestbook_version
    JSON.parse(File.read('/var/www/html/mazi-board/src/node/package.json'))['version']
  end

  def self.get_guestbook_config_file_version(filename, type)
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

  def self.update_guestbook_config_file_version(filename, type)
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
          if line.strip.start_with? 'tags:'
            flag = true
            lines += line.gsub("\n", ",\n")
          else
            lines += line
          end
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

  def self.update_dependencies
    MaziLogger.debug "Updating Dependencies"
    begin
      MaziLogger.debug "  Checking MySQL gem"
      Gem::Specification.find_by_name("mysql")# version 1.6.6 requires mysql gem
    rescue Gem::LoadError
       MaziLogger.debug "mysql gem not found. Installing."
       MaziLogger.debug "updating."
        `apt-get -y update`
        MaziLogger.debug "Installing mysql library."
        `apt-get -y install libmysqlclient-dev`
        MaziLogger.debug "Installing mysql gem."
        `gem install mysql --no-ri --no-rdoc`
        MaziLogger.debug "done"
        `service mazi-portal restart`
    rescue
      unless Gem.available?("mysql")
        MaziLogger.debug "mysql gem not found. Installing."
        MaziLogger.debug "updating."
        `apt-get -y update`
        MaziLogger.debug "Installing mysql library."
        `apt-get -y install libmysqlclient-dev`
        MaziLogger.debug "Installing mysql gem."
        `gem install mysql --no-ri --no-rdoc`
        MaziLogger.debug "done"
        `service mazi-portal restart`
      end
    end

    # version 2.0
    unless File.exists?('/usr/bin/install-wifi')
      MaziLogger.debug "install-wifi script not found. Installing."
      `wget http://www.fars-robotics.net/install-wifi -O /usr/bin/install-wifi`
      `chmod +x /usr/bin/install-wifi`
      MaziLogger.debug "Done Installing install-wifi script."
    end

    # version 1.8.5
    MaziLogger.debug "  Checking sshpass package"
    unless `dpkg -s sshpass | grep Status`.include? "install ok installed"
      MaziLogger.debug "sshpass package not found. Installing."
      `sh /root/back-end/update.sh`
      MaziLogger.debug "Done Installing sshpass."
      ConfigCaller.new.update_config
      `service mazi-portal restart`
    end

    # version 2.0
    MaziLogger.debug "  Checking jq package"
    unless `dpkg -s jq | grep Status`.include? "install ok installed"
      MaziLogger.debug "jq package not found. Installing."
      `apt-get -y install jq`
      MaziLogger.debug "Done Installing jq."
      `service mazi-portal restart`
    end

    # version 2.2
    begin
      MaziLogger.debug "  Checking i18n gem"
      Gem::Specification.find_by_name("i18n")# version 2.2 requires i18n gem
    rescue Gem::LoadError
      MaziLogger.debug "i18n gem not found. Installing."
      MaziLogger.debug "Installing i18n gem."
      `gem install i18n --no-ri --no-rdoc`
      MaziLogger.debug "done"
      `service mazi-portal restart`
    rescue
      unless Gem.available?("i18n")
        MaziLogger.debug "i18n gem not found. Installing."
        MaziLogger.debug "Installing i18n gem."
        `gem install i18n --no-ri --no-rdoc`
        MaziLogger.debug "done"
        `service mazi-portal restart`
      end
    end

    # version 2.3
    MaziLogger.debug "  Checking Guestbook version"
    if self.guestbook_version == '0.0.1'
      MaziLogger.debug "New Guestbook version found. Updating!!!"
      FileUtils.cp("/var/www/html/mazi-board/src/www/js/config.js", "/root/tmp_fe_config.js")
      FileUtils.cp("/var/www/html/mazi-board/src/node/config.js", "/root/tmp_be_config.js")
      `cd /var/www/html/mazi-board/; git stash; git pull; git stash clear`
      self.update_guestbook_config_file_version("/root/tmp_fe_config.js", 'front-end') if self.get_guestbook_config_file_version("/root/tmp_fe_config.js", 'front-end') == '0.0.1'
      self.update_guestbook_config_file_version("/root/tmp_be_config.js", 'back-end') if self.get_guestbook_config_file_version("/root/tmp_be_config.js", 'back-end') == '0.0.1'
      FileUtils.cp("/root/tmp_fe_config.js", "/var/www/html/mazi-board/src/www/js/config.js")
      FileUtils.cp("/root/tmp_be_config.js", "/var/www/html/mazi-board/src/node/config.js")
      File.delete("/root/tmp_fe_config.js")
      File.delete("/root/tmp_be_config.js")
      lines = ''
      File.readlines('/etc/init.d/mazi-board').each do |line|
        if line.strip.start_with? 'sudo pm2 start main.js'
          lines += line.gsub("--watch", "").gsub("\n", " --watch\n")
        else
          lines += line
        end
      end
      File.open('/etc/init.d/mazi-board', "w") {|file| file.puts lines }
      `systemctl daemon-reload`
      MaziLogger.debug "done"
      `service mazi-board restart`
    end
  end
end

