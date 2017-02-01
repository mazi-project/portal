
module Authorizer
  def authorized?
    !session[:username].nil?  
  end

  def valid_admin_credentials?(username, password)
    username == @config[:admin][:admin_username] && password == @config[:admin][:admin_password]
  end
end