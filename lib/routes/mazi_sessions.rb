module Sinatra
  module MaziApp
    module Routing
      module MaziSessions

        def self.registered(app)
          # admin login post request
          app.post '/admin_login/?' do
            MaziLogger.debug "request: post/admin_login from ip: #{request.ip} creds: #{params.inspect}"
            unless valid_admin_credentials?(params['username'], params['password'])
              session['error'] = 'Password and username missmatch!'
              redirect '/admin_login'
            end
            MaziLogger.debug "valid credential"
            session[:username] = params['username']
            if params['goto']
              redirect "/#{params['goto']}"
            else
              redirect '/admin'
            end
          end

          # admin login post request
          app.delete '/admin_login/?' do
            MaziLogger.debug "request: delete/admin_login from ip: #{request.ip} creds: #{params.inspect}"
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode download snapshot"
              session['error'] = "This portal runs on Demo mode! This action would have logged you out."
              redirect back
            end
            session[:username] = nil
            redirect '/admin'
          end

          # session counter reset
          app.delete '/session/:id/?' do |id|
            MaziLogger.debug "request: delete/session from ip: #{request.ip} creds: #{params.inspect}"
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              return {error: 'Not Authorized!', id: id}.to_json
            end
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode delete session"
              session['error'] = "This portal runs on Demo mode! This action would have reseted portal visits."
              redirect '/admin_snapshot'
            end

            if id == 'all'
              Mazi::Model::Session.all.each do |ses|
                ses.destroy
              end
            else
              ses = Mazi::Model::Session.find(id: id)
              ses.destroy
            end
            {result: 'OK', id: id}.to_json
          end

          app.post '/admin_change_username' do
            MaziLogger.debug "request: post/admin_change_username from ip: #{request.ip} params: #{params.inspect}"
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode change username"
              session['error'] = "This portal runs on Demo mode! This action would have changed the admin username."
              redirect '/admin_change_username'
            end
            unless params['old-username'] == @config[:admin][:admin_username]
              MaziLogger.debug "Incorrect old username"
              session['error'] = "Incorrect old username"
              redirect '/admin_change_username'
            end
            unless valid_admin_credentials?(params['old-username'], params['password'])
              MaziLogger.debug "Password confirmation missmatch"
              session['error'] = "Password confirmation missmatch"
              redirect '/admin_change_username'
            end
            changeConfigFile("admin->admin_username", params['new-username'])
            writeConfigFile
            session['error'] = nil
            session[:username] = nil
            redirect '/admin_login'
          end

          app.post '/admin_change_password' do
            MaziLogger.debug "request: post/admin_change_password from ip: #{request.ip} params: #{params.inspect}"
            if params['password'] == '1234'
              session['error'] = "Password 1234 cannot be used! Please try again."
              redirect '/admin_change_password'
            end
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode change password"
              session['error'] = "This portal runs on Demo mode! This action would have changed the admin password."
              redirect '/admin_change_password'
            end
            unless valid_password?(params['old-password'])
              MaziLogger.debug "Incorrect old password"
              session['error'] = "Incorrect old password"
              redirect '/admin_change_password'
            end
            unless params['new-password'] == params['new-password-confirm']
              MaziLogger.debug "Password confirmation missmatch"
              session['error'] = "Password confirmation missmatch"
              redirect '/admin_change_password'
            end
            changeConfigFile("admin->admin_password", params['new-password'])
            writeConfigFile
            session['error'] = nil
            session[:username] = nil
            redirect '/admin_login'
          end
        end

      end
    end
  end
end
