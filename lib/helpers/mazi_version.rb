VERSION = '2.5.0'

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
      create_lock_update_file
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

  def create_lock_update_file
    MaziLogger.debug "create update lock file"
    `touch /etc/mazi/update-lock`
    MaziLogger.debug "done."
  end

  def self.delete_lock_update_file
    MaziLogger.debug "delete update lock file"
    `rm /etc/mazi/update-lock 2> /dev/null`
    MaziLogger.debug "done."
  end

  def self.rc_local_updated?
    response = false
    File.readlines("/etc/rc.local").each do |line|
      response = true if line.include? 'FILE="/etc/mazi/update-lock"'
    end
    response
  end

  def self.guestbook_version
    JSON.parse(File.read('/var/www/html/mazi-board/src/node/package.json'))['version']
  end

  def self.nextcloud_version
    File.readlines('/var/www/html/nextcloud/version.php').each do |line|
      return line.split('=').last.strip if line.start_with?('$OC_VersionString')
    end
  end

  def self.etherpad_version
    JSON.parse(File.read('/var/www/html/etherpad-lite/src/package.json'))['version']
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

  def self.captive_portal_updated?
    response = false
    File.readlines("/var/www/html/index.html").each do |line|
      response = true if line.include? "<title>Success"
    end
    response
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
      FileUtils.cp("/var/www/html/mazi-board/src/www/js/templates/header_tmpl.html", "/root/tmp_header_tmpl.html")
      welcome_msg = ""
      File.readlines('/var/www/html/mazi-board/src/www/js/templates/submission_input_tmpl.html').each do |line|
        line = line.strip
        if line.include? 'submission-headline'
          welcome_msg = line.split('>')[2].split('<').first
        end
      end
      `cd /var/www/html/mazi-board/; git stash; git pull; git stash clear`
      self.update_guestbook_config_file_version("/root/tmp_fe_config.js", 'front-end') if self.get_guestbook_config_file_version("/root/tmp_fe_config.js", 'front-end') == '0.0.1'
      self.update_guestbook_config_file_version("/root/tmp_be_config.js", 'back-end') if self.get_guestbook_config_file_version("/root/tmp_be_config.js", 'back-end') == '0.0.1'
      FileUtils.cp("/root/tmp_fe_config.js", "/var/www/html/mazi-board/src/www/js/config.js")
      FileUtils.cp("/root/tmp_be_config.js", "/var/www/html/mazi-board/src/node/config.js")
      FileUtils.cp("/root/tmp_header_tmpl.html", "/var/www/html/mazi-board/src/www/js/templates/header_tmpl.html")
      File.delete("/root/tmp_fe_config.js")
      File.delete("/root/tmp_be_config.js")
      File.delete("/root/tmp_header_tmpl.html")
      `sudo pm2 stop main`
      `sudo pm2 delete main`
      lines = ''
      File.readlines('/etc/init.d/mazi-board').each do |line|
        if line.strip.start_with? 'sudo pm2 start main.js'
          lines += "        sudo pm2 start main.config.js\n"
        elsif line.strip.start_with? 'sudo pm2 stop main.js'
          lines += "        sudo pm2 stop guestbook-back-end\n"
        else
          lines += line
        end
      end
      File.open('/etc/init.d/mazi-board', "w") {|file| file.puts lines }
      lines = ''
      File.readlines('/var/www/html/mazi-board/src/www/js/config.js').each do |line|
        if line.strip.start_with? 'welcome_msg:'
          lines += line.split(':').first + ": \"#{welcome_msg}\",\n"
        else
          lines += line
        end
      end
      File.open('/var/www/html/mazi-board/src/www/js/config.js', "w") {|file| file.puts lines }
      `systemctl daemon-reload`
      MaziLogger.debug "done"
      `cd /var/www/html/mazi-board/src/node/; sudo pm2 start main.config.js`
      `sudo pm2 save`
    end

    # version 2.4
    MaziLogger.debug "  Checking Nextcloud version"
    if self.nextcloud_version == "'11.0.1';"
      MaziLogger.debug "New Nextcloud version found. Updating!!!"

      `cd /var/www/html/nextcloud/updater; sudo -u www-data php updater.phar --no-interaction`
      `cd /var/www/html/nextcloud/updater; sudo -u www-data php updater.phar --no-interaction`
      `cd /var/www/html/nextcloud; sudo -u www-data php occ app:enable files_external`
    elsif self.nextcloud_version == "'12.0.5';"
      MaziLogger.debug "New Nextcloud version found. Updating!!!"

      `cd /var/www/html/nextcloud/updater; sudo -u www-data php updater.phar --no-interaction`
    end
    if self.etherpad_version == '1.6.0'
      Dir.chdir('/var/www/html/etherpad-lite/'){
        `git fetch`
        `git checkout master`
        `git pull origin`
        `npm install ep_page_view`
        `git clone https://github.com/JohnMcLear/ep_comments.git node_modules/ep_comments_page`
        `cd node_modules/ep_comments_page/; npm install`
        `service etherpad-lite restart`
      }
    end
    unless File.exists?('/etc/init.d/mazi-rest')
      MaziLogger.debug "REST service not found. Installing!!!"
      FileUtils.cp("/root/portal/init/mazi-portal", "/etc/init.d/mazi-portal")
      FileUtils.cp("/root/portal/init/mazi-rest", "/etc/init.d/mazi-rest")
      `chmod +x /etc/init.d/mazi-portal`
      `chmod +x /etc/init.d/mazi-rest`
      `systemctl daemon-reload`
      `update-rc.d mazi-rest defaults`
      `update-rc.d mazi-rest enable`
      `service mazi-rest start`
    end
    unless captive_portal_updated?
      MaziLogger.debug "Old version of captive portal found. Updating!!!"
      lines = ''
      File.readlines("/var/www/html/index.html").each do |line|
        if line.include? "<meta HTTP"
          lines += "          <title>Success</title>\n"
          lines += line
        else
          lines += line
        end
      end
      File.open("/var/www/html/index.html", "w") {|file| file.puts lines }
      MaziLogger.debug "done"
      `service mazi-portal restart`
    end

    # version 2.4.3
    MaziLogger.debug "  Checking sqlite3 package"
    unless `dpkg -s sqlite3 | grep Status`.include? "install ok installed"
     MaziLogger.debug "sqlite3 package not found. Installing."
     `apt-get -y install sqlite3`
     MaziLogger.debug "Done Installing sqlite3."
    end

    # version 2.4.5
    MaziLogger.debug "  Checking rc.local file"
    unless rc_local_updated?
      MaziLogger.debug "rc.local older version found. Updating."
      `cp /root/portal/init/rc.local /etc/rc.local`
      MaziLogger.debug "Done Updating rc.local."
    end

    # version 2.5.0
    MaziLogger.debug "  Checking nodogsplash"
    unless File.directory?('/root/nodogsplash')
      MaziLogger.debug "nodogsplash does not exist. Updating!"
      `bash /root/back-end/update.sh`
      MaziLogger.debug "done."
    end

    delete_lock_update_file
  end
end

