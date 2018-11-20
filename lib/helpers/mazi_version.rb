VERSION = '2.6.0'

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
    `cd /root/back-end && git fetch`
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
    0
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

  def get_current_branch
    o = `git status`
    o.split("\n").each do |line|
      if line.include? 'On branch'
        return line.split.last
        break
      end
    end
    'stretch'
  end

  def change_update_branch(branch="stretch")
    fetch
    `cd /root/back-end && git checkout #{branch}`
    `git checkout #{branch}`
  end

  def version_update
    MaziLogger.debug "Version Update Started"
    fetch
    MaziLogger.debug "Fetch done."
    diff   = version_difference
    staged = staged?
    if diff.to_i > 0 && !staged
      create_lock_update_file
      branch = get_current_branch
      MaziLogger.debug "pull origin #{branch}"
      `git pull origin #{branch}`
      MaziLogger.debug "done."
      MaziLogger.debug "db migrate"
      `rake db:migrate`
      MaziLogger.debug "done."
      `cp /etc/mazi/config.yml /etc/mazi/config.yml.bu`
      MaziLogger.debug "Updating back-end scripts"
      `cd /root/back-end && git pull origin #{branch}`
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

  def self.remove_old_snapshots
    MaziLogger.debug "deleting old snapshots"
    `rm -rf public/snapshots/* 2> /dev/null`
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

  def self.update_dependencies
    MaziLogger.debug "Updating Dependencies"

    remove_old_snapshots
    delete_lock_update_file
  end
end

