
module Authorizer
  def authorized?
    !session[:username].nil?  
  end

  def valid_admin_credentials?(username, password)
    username == readConfigFile[:admin][:admin_username] && password == readConfigFile[:admin][:admin_password]
  end

  def valid_password?(password)
    password == readConfigFile[:admin][:admin_password]
  end
end