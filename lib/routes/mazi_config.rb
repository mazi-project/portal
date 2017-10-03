module Sinatra
  module MaziApp
    module Routing
      module MaziConfig

        def self.registered(app)
          app.get '/snapshots/:file' do |file|
            MaziLogger.debug "request: get/snapshots/#{file}: #{request.ip}"
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode download snapshot"
              session['error'] = "This portal runs on Demo mode! This action would have downloaded a snapshot."
              redirect back
            end
            send_file File.join('public/snapshots/', file)
          end

          # admin login post request
          app.post '/set_date/?' do
            MaziLogger.debug "request: post/set_date from ip: #{request.ip} params: #{params.inspect}"
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode set app"
              session['error'] = "This portal runs on Demo mode! This action would have changed the time/date of the MAZI Zone."
              redirect back
            end
            unless params['date'].nil? || params['date'].empty?
              ex = MaziExecCmd.new('', '', 'date', ['-s', "'#{params['date']}'"], @config[:scripts][:enabled_scripts])
            end
            unless params['timezone'].nil? || params['timezone'].empty?
              update_timezone(params['timezone'])
            end
            lines = ex.exec_command
            redirect '/admin'
          end

          # saving configurations
          app.post '/conf/?' do
            MaziLogger.debug "request: post/conf from ip: #{request.ip} params: #{params.inspect}"
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              redirect '/admin_login?goto=admin_configuration'
            end
            if params['reset']
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode saving configuration"
                session['error'] = "This portal runs on Demo mode! This action would have reset the theme."
                redirect '/admin_configuration'
              end
              changePortalConfigToDefault
              writeConfigFile
              redirect '/admin_configuration'
            elsif params['save']
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode saving configuration"
                session['error'] = "This portal runs on Demo mode! This action would have saved a theme."
                redirect '/admin_configuration'
              end
              saveTheme(params[:filename])
              redirect '/admin_configuration'
            elsif params['load']
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode saving configuration"
                session['error'] = "This portal runs on Demo mode! This action would have loaded a theme."
                redirect '/admin_configuration'
              end
              loadTheme(params[:filename])
              redirect '/admin_configuration'
            end
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode saving configuration"
              session['error'] = "This portal runs on Demo mode! This action would have made a theme change."
              redirect '/admin_configuration'
            end
            data = {}
            data[:title]                     = params['title'] unless params['title'].nil? || params['title'].empty?
            data[:applications_title]        = params['applications_title'] unless params['applications_title'].nil?  || params['applications_title'].empty?
            data[:applications_subtitle]     = params['applications_subtitle'] unless params['applications_subtitle'].nil?  || params['applications_subtitle'].empty?
            data[:applications_welcome_text] = params['applications_welcome_text'] unless params['applications_welcome_text'].nil?  || params['applications_welcome_text'].empty?
            data[:side_panel_color]          = params['side_panel_color'] unless params['side_panel_color'].nil?  || params['side_panel_color'].empty?
            data[:side_panel_active_color]   = params['side_panel_active_color'] unless params['side_panel_active_color'].nil?  || params['side_panel_active_color'].empty?
            data[:top_panel_color]           = params['top_panel_color'] unless params['top_panel_color'].nil?  || params['top_panel_color'].empty?
            data[:top_panel_active_color]    = params['top_panel_active_color'] unless params['top_panel_active_color'].nil?  || params['top_panel_active_color'].empty?
            unless params['applications_background_image'].nil? || params['applications_background_image'].empty?
              tempfile = params['applications_background_image'][:tempfile]
              filename = params['applications_background_image'][:filename]
              data[:applications_background_image] = filename
              FileUtils.cp tempfile.path, "public/images/#{filename}"
            end
            data.each do |key, value|
              changeConfigFile("portal_configuration->#{key}", value)
            end
            writeConfigFile
            redirect '/admin_configuration'
          end

          # saving configurations without a refresh
          app.put '/conf/?' do
            request.body.rewind
            body = JSON.parse(request.body.read)
            MaziLogger.debug "request: put/conf from ip: #{request.ip} body: #{body}"
            if !authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              {error: 'Not Authorized!'}.to_json
            elsif  @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode save configuration"
              session['error'] = nil
              {error: "This portal runs on Demo mode! This action would have made a theme change."}.to_json
            else
              data = {}
              data[:title]                     = body['title'] unless body['title'].nil? || body['title'].empty?
              data[:applications_title]        = body['applications_title'] unless body['applications_title'].nil?  || body['applications_title'].empty?
              data[:applications_subtitle]     = body['applications_subtitle'] unless body['applications_subtitle'].nil?  || body['applications_subtitle'].empty?
              data[:applications_welcome_text] = body['applications_welcome_text'] unless body['applications_welcome_text'].nil?  || body['applications_welcome_text'].empty?
              data[:side_panel_color]          = body['side_panel_color'] unless body['side_panel_color'].nil?  || body['side_panel_color'].empty?
              data[:side_panel_active_color]   = body['side_panel_active_color'] unless body['side_panel_active_color'].nil?  || body['side_panel_active_color'].empty?
              data[:top_panel_color]           = body['top_panel_color'] unless body['top_panel_color'].nil?  || body['top_panel_color'].empty?
              data[:top_panel_active_color]    = body['top_panel_active_color'] unless body['top_panel_active_color'].nil?  || body['top_panel_active_color'].empty?
              data.each do |key, value|
                changeConfigFile("portal_configuration->#{key}", value)
              end
              writeConfigFile
              {result: 'OK'}.to_json
            end
          end

          # taking/loading snapshots
          app.post '/snapshot/?' do
            MaziLogger.debug "request: post/snapshot from ip: #{request.ip} params: #{params.inspect}"
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              redirect '/admin_login?goto=admin_snapshot'
            end
            if params['save']
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode save snapshot"
                session['error'] = "This portal runs on Demo mode! This action would have saved a snapshot."
                redirect '/admin_snapshot'
              end
              takeDBSnapshot(params[:snapshotname])
              redirect '/admin_snapshot'
            elsif params['load']
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode load snapshot"
                session['error'] = "This portal runs on Demo mode! This action would have loaded a snapshot."
                redirect '/admin_snapshot'
              end
              loadDBSnapshot(params[:snapshotname])
              loadTheme("#{params[:snapshotname]}.yml")
              redirect '/admin_snapshot'
            elsif params['download']
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode download snapshot"
                session['error'] = "This portal runs on Demo mode! This action would have downloaded a snapshot."
                redirect '/admin_snapshot'
              end
              zip_snapshot(params[:snapshotname])
              return {result: 'OK', file: "#{params[:snapshotname]}.zip"}
            elsif params['upload']
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode upload snapshot"
                session['error'] = "This portal runs on Demo mode! This action would have uploaded a snapshot."
                redirect '/admin_snapshot'
              end
              tempfile = params['snapshot'][:tempfile]
              filename = params['snapshot'][:filename]
              unzip_snapshot(filename, tempfile)
              loadTheme(filename.gsub('.zip', '.yml'))
              redirect '/admin_snapshot'
            elsif params['export_app']
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode upload snapshot"
                session['error'] = "This portal runs on Demo mode! This action would have exported an application snapshot."
                redirect '/admin_snapshot'
              end
              zip_app_snapshot(params[:application], params['snapshotname'])
              return {result: 'OK', file: "#{params[:snapshotname]}_#{params[:application]}.zip"}
            elsif params['import_app']
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode upload snapshot"
                session['error'] = "This portal runs on Demo mode! This action would have imported an application snapshot."
                redirect '/admin_snapshot'
              end
              tempfile = params['snapshot'][:tempfile]
              filename = params['snapshot'][:filename]
              unzip_app_snapshot(params[:application], filename, tempfile)
              redirect '/admin_snapshot'
            end

            redirect '/admin_snapshot'
          end

          app.delete '/snapshot/?' do
            MaziLogger.debug "request: delete/snapshot from ip: #{request.ip} params: #{params.inspect}"
            deleteDBSnapshot(params['snapshotname'])
            {result: "OK"}.to_json
          end

          app.post '/setup' do
            MaziLogger.debug "request: post/setup from ip: #{request.ip} creds: #{params.inspect}"
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode exec script"
              session['error'] = "This portal runs on Demo mode! This action would have initiated the setup mechanism."
              redirect '/admin'
            end
            if params['current-password'].nil? || params['current-password'].empty?
              session['error'] = "Field Current Password is mandatory! Please try again."
              redirect '/setup'
            end
            if params['password'].nil? || params['password'].empty?
              session['error'] = "Field Password is mandatory! Please try again."
              redirect '/setup'
            end
            if params['confirm-password'].nil? || params['confirm-password'].empty?
              session['error'] = "Field Confirm Password is mandatory! Please try again."
              redirect '/setup'
            end
            if params['confirm-password'] != params['password']
              session['error'] = "Password and confirm Password fields missmatch! Please try again."
              redirect '/setup'
            end
            if params['password'] == '1234'
              session['error'] = "Password 1234 cannot be used! Please try again."
              redirect '/setup'
            end
            unless valid_password?(params['current-password'])
              session['error'] = "Current Password missmatch! Please try again."
              redirect '/setup'
            end

            changeConfigFile("admin->admin_password", params['password'])
            writeConfigFile

            unless params['date'].nil? || params['date'].empty?
              ex = MaziExecCmd.new('', '', 'date', ['-s', "'#{params['date']}'"], @config[:scripts][:enabled_scripts])
              lines = ex.exec_command
            end

            unless params['timezone'].nil? || params['timezone'].empty?
              update_timezone(params['timezone'])
            end

            unless params['ssid'].nil? || params['ssid'].empty?
              env = 'sh'
              path = @config[:scripts][:backend_scripts_folder]
              cmd = "wifiap.sh"
              args = []
              args << "-s '#{params['ssid']}'" if params['ssid']

              ex1 = MaziExecCmd.new(env, path, cmd, args, @config[:scripts][:enabled_scripts])
              lines = ex1.exec_command
            end

            session['error'] = nil
            session[:username] = nil
            redirect '/admin_login'
          end

          app.put '/update/?' do
            MaziLogger.debug "request: put/update from ip: #{request.ip} params: #{params.inspect}"

            version_update
            update_config_file

            Thread.new do
              sleep 2
              MaziLogger.debug 'Restarting'
              `service mazi-portal restart`
            end

            {status: "restarting"}.to_json
          end
        end

      end
    end
  end
end