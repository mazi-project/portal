AUTH_ENABLED = true
module Authorizer
  def authorized?
    if @config[:general][:mode] == 'demo'
      return true
    end
    return true unless AUTH_ENABLED
    !session[:username].nil?
  end

  def valid_admin_credentials?(username, password)
    if @config[:general][:mode] == 'demo'
      return true
    end
    username == readConfigFile[:admin][:admin_username] && password == readConfigFile[:admin][:admin_password]
  end

  def valid_password?(password)
    if @config[:general][:mode] == 'demo'
      return true
    end
    password == readConfigFile[:admin][:admin_password]
  end

  def valid_location?(location)
    if @config[:general][:mode] == 'demo'
      return true
    end
    return false if location.include?('(') || location.include?(')') || location.include?("'") || location.include?('"')
    return false unless location.include?(', ') && location.include?('.')
    true
  end

  def first_time?
    readConfigFile[:admin][:admin_password] == '1234'
  end

  def valid_mysql_password?(password)
    file  = File.read('/etc/mazi/sql.conf')
    data  = JSON.parse(file)
    data["password"] == password
  end
end
