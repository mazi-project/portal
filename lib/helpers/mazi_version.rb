VERSION = '1.8'

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

    MaziLogger.debug "  Checking sshpass package"
    unless `dpkg -s sshpass | grep Status`.include? "install ok installed"
      MaziLogger.debug "sshpass package not found. Installing."
      `sh /root/back-end/update.sh`
    end
  end
end
