module Sinatra
  module MaziApp
    module Routing
      module MaziMain

        def self.registered(app)
          app.get '/' do
            redirect 'index'
          end

          # this is the main routing configuration that routes all the erb files
          app.get '/:index/?' do |index|
            MaziLogger.debug "request: get/#{index} from ip: #{request.ip} params: #{params.inspect}"
            if session['uuid'].nil?
              s = Mazi::Model::Session.create
              s.ip = request.ip
              s.save
              session['uuid'] = s.uuid
            end
            if first_time? && index != 'setup'
              redirect '/setup'
            end
            if session['locale'].nil?
              session['locale'] = :en
            end
            set_locale(session['locale'])
            locals                           = {}
            locals[:local_data]              = {}
            locals[:local_data][:mode]       = @config[:general][:mode]
            locals[:local_data][:authorized] = authorized?
            locals[:version]                 = getVersion
            locals[:js]                      = []
            locals[:error_msg]               = nil
            locals[:sensors_enabled]         = sensors_enabled?
            locals[:camera_enabled]          = camera_enabled?
            locals[:monitoring_enabled]      = monitoring_enabled?
            locals[:monitoring_map_enabled]  = monitoring_map_enabled?
            locals[:locale]                  = session['locale']
            locals[:locales]                 = I18n.available_locales
            unless session['error'].nil?
              locals[:error_msg] = session["error"]
              session[:error] = nil
            end
            case index
            when 'index'
              app = Mazi::Model::ApplicationInstance.find(splash_screen: true)
              unless app.nil?
                redirect app.url
              end
              session['notifications_read'] = [] if session['notifications_read'].nil?
              locals[:js] << "js/index_application.js"
              locals[:main_body] = :index_application
              locals[:local_data][:applications]          = Mazi::Model::Application.all
              locals[:local_data][:notifications]         = Mazi::Model::Notification.all
              locals[:local_data][:application_instances] = Mazi::Model::ApplicationInstance.dataset.order(:order).all
              locals[:local_data][:notifications_read]    = session['notifications_read']
              locals[:local_data][:config_data]           = @config[:portal_configuration]
              erb :index_main, locals: locals
            when 'index_system' #used to be statistics
              session['notifications_read'] = [] if session['notifications_read'].nil?
              locals[:js] << "js/index_statistics.js"
              locals[:main_body] = :index_statistics
              locals[:local_data][:notifications]      = Mazi::Model::Notification.all
              locals[:local_data][:notifications_read] = session['notifications_read']
              locals[:local_data][:config_data]        = @config[:portal_configuration]
              ex = MaziExecCmd.new('bash', '/root/back-end/', 'mazi-stat.sh', ['-u'], @config[:scripts][:enabled_scripts], @config[:general][:mode])
              lines = ex.exec_command
              users = ex.parseFor('wifi users')
              locals[:local_data][:users]          = {}
              locals[:local_data][:users][:online] = users[2] if users.kind_of? Array
              locals[:local_data][:clicks]         = 0
              Mazi::Model::ApplicationInstance.all.each do |app|
                locals[:local_data][:clicks] += app.click_counter
              end
              ex = MaziExecCmd.new('bash', '/root/back-end/', 'mazi-stat.sh', ['-t', '-c', '-r', '-s'], @config[:scripts][:enabled_scripts], @config[:general][:mode])
              ex.exec_command
              locals[:local_data][:temp]     = ex.parseFor("temp:").last
              locals[:local_data][:cpu]      = ex.parseFor("cpu:").last
              locals[:local_data][:ram]      = ex.parseFor("ram:").last
              locals[:local_data][:storage]  = ex.parseFor("storage:").last
              erb :index_main, locals: locals
            when 'index_sensors'
              MaziLogger.debug "params: #{params.inspect}"
              redirect back unless sensors_enabled?
              session['notifications_read']            = [] if session['notifications_read'].nil?
              locals[:js] << "js/plugins/morris/raphael.min.js"
              locals[:js] << "js/plugins/morris/morris.min.js"
              locals[:js] << "js/jquery.datetimepicker.min.js"
              locals[:js] << "js/index_sensors.js"
              locals[:local_data][:notifications]      = Mazi::Model::Notification.all
              locals[:local_data][:notifications_read] = session['notifications_read']
              locals[:local_data][:config_data]        = @config[:portal_configuration]
              locals[:local_data][:sensors]            = []
              getDevicesAllAvailableSensorsFromDB.each do |sensor|
                tmp                = {}
                tmp[:id]           = sensor[:id]
                tmp[:type]         = sensor[:type]
                tmp[:temperatures] = getTemperatures(sensor[:id], sensor[:type], params['start_date'], params['end_date'])
                tmp[:humidity]     = getHumidities(sensor[:id], sensor[:type], params['start_date'], params['end_date'])
                tmp[:pressures]    = getPressures(sensor[:id], sensor[:type], params['start_date'], params['end_date'])
                next if tmp[:temperatures].nil? || tmp[:humidity].nil? || tmp[:temperatures].empty? || tmp[:humidity].empty?
                locals[:local_data][:sensors] << tmp
              end
              locals[:main_body] = :index_sensors
              erb :index_main, locals: locals
            when 'index_monitoring'
              session['notifications_read'] = [] if session['notifications_read'].nil?
              locals[:js] << "js/index_monitoring.js"
              locals[:js] << "js/plugins/jvectormap/jquery-jvectormap-2.0.3.min.js"
              locals[:js] << "js/plugins/jvectormap/jquery-jvectormap-world-mill.js"
              locals[:js] << "js/plugins/morris/raphael.min.js"
              locals[:js] << "js/plugins/morris/morris.min.js"
              locals[:js] << "js/plugins/jq_responsive_tabs/jquery.responsiveTabs.min.js"
              start_date = nil
              end_date = nil
              locals[:main_body]                       = :index_monitoring
              locals[:local_data][:notifications]      = Mazi::Model::Notification.all
              locals[:local_data][:notifications_read] = session['notifications_read']
              locals[:local_data][:config_data]        = @config[:portal_configuration]
              locals[:local_data][:deployments]        = enrichDeployments(getAllDeploymentsWithData)
              erb :index_main, locals: locals
            when 'index_devices_map'
              session['notifications_read'] = [] if session['notifications_read'].nil?
              locals[:js] << "js/index_devices_map.js"
              locals[:js] << "http://www.openlayers.org/api/OpenLayers.js"
              locals[:js] << "js/plugins/morris/raphael.min.js"
              locals[:js] << "js/plugins/morris/morris.min.js"
              locals[:main_body]                       = :monitoring_map
              locals[:local_data][:deployments]        = enrichDeployments(getAllDeploymentsWithData)
              locals[:local_data][:notifications]      = Mazi::Model::Notification.all
              locals[:local_data][:notifications_read] = session['notifications_read']
              locals[:local_data][:config_data]        = @config[:portal_configuration]
              erb :index_main, locals: locals
            when 'index_documentation'
              session['notifications_read']            = [] if session['notifications_read'].nil?
              locals[:main_body]                       = :index_documentation
              locals[:local_data][:notifications]      = Mazi::Model::Notification.all
              locals[:local_data][:notifications_read] = session['notifications_read']
              locals[:local_data][:config_data]        = @config[:portal_configuration]
              erb :index_main, locals: locals
            when 'index_camera'
              session['notifications_read']            = [] if session['notifications_read'].nil?
              locals[:main_body]                       = :index_camera
              locals[:js]                              << "js/index_camera.js"
              locals[:local_data][:notifications]      = Mazi::Model::Notification.all
              locals[:local_data][:notifications_read] = session['notifications_read']
              locals[:local_data][:config_data]        = @config[:portal_configuration]
              locals[:local_data][:nof_photos]         = number_of_photos
              locals[:local_data][:nof_videos]         = number_of_videos
              locals[:local_data][:rpi_files]          = rpi_saved_files
              locals[:local_data][:camera_installed]   = camera_installed?
              locals[:local_data][:rpi_enabled]        = rpi_enabled?
              erb :index_main, locals: locals
            when 'setup'
              locals[:main_body] = :setup
              locals[:js] << "js/setup.js"
              locals[:js] << "js/jquery.datetimepicker.min.js"
              locals[:timezones] = all_supported_timezones
              erb :setup, locals: locals
            when 'splash'
              MaziLogger.debug "Splash Page "
              locals[:main_body] = :splash
              locals[:tok] = "#{params['tok']}"
 	            locals[:redir] = "#{params['redir']}"
              locals[:authaction] = "#{params['authaction']}"
              locals[:mac] = "#{params['mac']}"
              locals[:apps] = Mazi::Model::ApplicationInstance.all
              locals[:name] = @config[:portal_configuration][:applications_title]
              ex = MaziExecCmd.new('bash', '/root/back-end/', 'current.sh', ['-s', '-m', '-d'], @config[:scripts][:enabled_scripts])
              lines = ex.exec_command
              mode = ex.parseFor('mode').last.gsub('"', '')
              ssid = ex.parseFor('ssid').last
              domain = ex.parseFor('domain').last
              if mode == "offline"
                 locals[:message_mode] = "so it does NOT provide internet access."
              else
                 locals[:message_mode] = "so it does provide internet access."
              end
              locals[:mode] = mode
              locals[:ssid] = ssid
              locals[:domain] = "http://#{domain}"
              erb :splash, locals: locals
            when 'splashEnter'
               mac = "#{params['mac']}"
               redir = "#{params['redir']}"
               redir = redir.gsub( /http?:\/\//, 'http%3A%2F%2F')
               authtarget = "#{params['authaction']}?redir=#{redir}&tok=#{params['tok']}"
               unless File.exist?('/etc/mazi/users.dat') then
                  File.new "/etc/mazi/users.dat", "w"
               end
               File.write('/etc/mazi/users.dat',"#{mac} #{Time.now}\n", mode: 'a')
               redirect "#{authtarget}"
            when 'admin'
              redirect 'admin_dashboard'
            when 'admin_dashboard'
              unless authorized?
                MaziLogger.debug "Not authorized"
                session['error'] = nil
                redirect "/admin_login"
              end
              locals[:js] << "js/admin_dashboard.js"
              locals[:main_body] = :admin_dashboard
              ex = MaziExecCmd.new('bash', '/root/back-end/', 'current.sh', ['-s', '-p', '-c', '-m'], @config[:scripts][:enabled_scripts], @config[:general][:mode])
              lines = ex.exec_command
              locals[:local_data][:net_info] = {}
              ssid = ex.parseFor('ssid')
              ssid.shift
              locals[:local_data][:net_info][:ssid] = ssid.join(' ') if ssid.kind_of? Array
              mode = ex.parseFor('mode')
              ex2 = MaziExecCmd.new('bash', '/root/back-end/', 'mazi-stat.sh', ['-u', '-t', '-c', '-r', '-s', '--sd'], @config[:scripts][:enabled_scripts], @config[:general][:mode])
              ex2.exec_command
              users_online = ex2.parseFor('wifi users') ? ex2.parseFor('wifi users').last : nil
              temp         = ex2.parseFor("temp:") ? ex2.parseFor("temp:").last : nil
              cpu          = ex2.parseFor("cpu:") ? ex2.parseFor("cpu:").last : nil
              ram          = ex2.parseFor("ram:") ? ex2.parseFor("ram:").last : nil
              storage      = ex2.parseFor("storage:") ? "#{ex2.parseFor("storage:")[-2]} #{ex2.parseFor("storage:")[-1]}" : nil
              sd_size      = ex2.parseFor("ram:") ? ex2.parseFor("SD size:").last : nil
              expanded     = ex2.parseFor("expand:") ? ex2.parseFor("expand:").last : nil
              users_online = 0 if users_online == 'users:'
              locals[:local_data][:users]                 = {}
              locals[:local_data][:users][:online]        = users_online
              locals[:local_data][:temp]                  = temp
              locals[:local_data][:cpu]                   = cpu
              locals[:local_data][:ram]                   = ram
              locals[:local_data][:storage]               = storage
              locals[:local_data][:sd_size]               = sd_size
              locals[:local_data][:expanded]              = expanded
              locals[:local_data][:net_info][:mode]       = mode[1] if mode.kind_of? Array
              locals[:local_data][:applications]          = Mazi::Model::Application.all
              locals[:local_data][:application_instances] = Mazi::Model::ApplicationInstance.all
              locals[:local_data][:notifications]         = Mazi::Model::Notification.all
              locals[:local_data][:sessions]              = Mazi::Model::Session.all
              locals[:local_data][:rasp_date]             = Time.now.strftime("%d %b %Y")
              locals[:local_data][:rasp_time]             = Time.now.strftime("%H:%M")
              locals[:local_data][:version]               = getVersion
              ex3 = MaziExecCmd.new('bash', '/root/back-end/', 'current.sh', ['-n'], @config[:scripts][:enabled_scripts], @config[:general][:mode])
              line = ex3.exec_command
              locals[:local_data][:version_difference] = line == 'OK' ? version_difference : 0
              erb :admin_main, locals: locals
            when 'admin_application'
              unless authorized?
                MaziLogger.debug "Not authorized"
                session['error'] = nil
                redirect "/admin_login?goto=#{index}"
              end
              locals[:js] << "js/admin_application.js"
              locals[:main_body] = :admin_application
              locals[:local_data][:applications]                = Mazi::Model::Application.all
              locals[:local_data][:application_instances]       = Mazi::Model::ApplicationInstance.dataset.order(:order).all
              locals[:local_data][:can_have_multiple_instances] = ['NextCloud', 'Etherpad', 'FramaDate']
              erb :admin_main, locals: locals
            when 'admin_documentation'
              unless authorized?
                MaziLogger.debug "Not authorized"
                session['error'] = nil
                redirect "/admin_login?goto=#{index}"
              end
              locals[:main_body] = :admin_documentation
              erb :admin_main, locals: locals
            when 'admin_network'
              unless authorized?
                MaziLogger.debug "Not authorized"
                session['error'] = nil
                redirect "/admin_login?goto=#{index}"
              end
              locals[:js] << "js/admin_network.js"
              locals[:js] << "js/plugins/qrcode/jquery.qrcode.js"
              locals[:js] << "js/plugins/qrcode/qrcode.js"
              locals[:main_body] = :admin_network
              interfaces = get_interfaces
              populate_interfaces(interfaces)
              locals[:local_data][:interfaces] = interfaces
              locals[:local_data][:net_info]   = {}
              locals[:local_data][:net_info][:ap] = nil
              interfaces.each do |ifn, ifd|
                locals[:local_data][:net_info][:ap] = ifn if ifd[:mode] == 'wifi'
              end
              locals[:local_data][:users] = get_network_users
              ex3 = MaziExecCmd.new('bash', '/root/back-end/', 'mazi-router.sh', ['-s'], @config[:scripts][:enabled_scripts])
              router_stat = ex3.exec_command.first.split
              locals[:local_data][:net_info][:owrt_router_available] = router_stat.last
              ex4 = MaziExecCmd.new('bash', '/root/back-end/', 'current.sh', ['-m'], @config[:scripts][:enabled_scripts])
              mode = ex4.exec_command.first.split
              locals[:local_data][:net_info][:mode] = mode[1].gsub('"', '')
              ex5 = MaziExecCmd.new('bash', '/root/back-end/', 'current.sh', ['-d'], @config[:scripts][:enabled_scripts])
              cur_out = ex5.exec_command.first.split
              locals[:local_data][:net_info][:domain] = cur_out[1]
              ex6 = MaziExecCmd.new('bash', '/root/back-end/', 'current.sh', ['-w'], @config[:scripts][:enabled_scripts])
              cur_out = ex6.exec_command.first.split
              locals[:local_data][:net_info][:current_wifi_interface] = cur_out[1]
              ex7 = MaziExecCmd.new('bash', '/root/back-end/', 'current.sh', ['-n'], @config[:scripts][:enabled_scripts])
              cur_out = ex7.exec_command
              locals[:local_data][:net_info][:current_internet_connection_on] = cur_out.include?('ok')
              erb :admin_main, locals: locals
            when 'admin_configuration'
              unless authorized?
                MaziLogger.debug "Not authorized"
                session['error'] = nil
                redirect "/admin_login?goto=#{index}"
              end
              locals[:js] << "js/admin_configuration.js"
              locals[:js] << "js/jscolor.min.js"
              locals[:main_body] = :admin_configuration
              locals[:local_data][:portal_configuration] = @config[:portal_configuration]
              locals[:local_data][:config_files] = getAllConfigSaves
              erb :admin_main, locals: locals
            when 'admin_notification'
              unless authorized?
                MaziLogger.debug "Not authorized"
                session['error'] = nil
                redirect "/admin_login?goto=#{index}"
              end
              locals[:js] << "js/admin_notification.js"
              locals[:main_body] = :admin_notification
              locals[:local_data][:notifications] = Mazi::Model::Notification.all
              erb :admin_main, locals: locals
            when 'admin_snapshot'
              unless authorized?
                MaziLogger.debug "Not authorized"
                session['error'] = nil
                redirect "/admin_login?goto=#{index}"
              end
              locals[:js] << "js/admin_snapshot.js"
              locals[:main_body] = :admin_snapshot
              locals[:local_data][:dbs] = getAllDBSnapshots
              ex = MaziExecCmd.new('bash', '/root/back-end/', 'mazi-stat.sh', ['--usb'], @config[:scripts][:enabled_scripts])
              ex.exec_command.each do |line|
                locals[:local_data][:usb] = false if line == 'usb -'
                locals[:local_data][:usb_target] = '' if locals[:local_data][:usb_target].nil?
                locals[:local_data][:free] = 0 if locals[:local_data][:free].nil?
                if line.start_with?('usb_target')
                  locals[:local_data][:usb] = true
                  locals[:local_data][:usb_target] = line.split.last
                end
                if line.start_with?('free_space')
                  free = line.split.last
                  free = free.length > 6 ? "#{free[0..-7]}.#{free[-6]} GB" : "#{free[0..2]} MB"
                  locals[:local_data][:free] = free
                end
              end
              locals[:local_data][:zip_files] = locals[:local_data][:usb_target] ? get_all_zip_files_in_device(locals[:local_data][:usb_target]) : []
              erb :admin_main, locals: locals
            when 'admin_devices'
              unless authorized?
                MaziLogger.debug "Not authorized"
                session['error'] = nil
                redirect "/admin_login?goto=#{index}"
              end
              locals[:js] << "js/admin_devices.js"
              locals[:js] << "js/jquery.datetimepicker.min.js"
              locals[:main_body] = :admin_devices
              locals[:local_data][:camera_enabled]    = @config[:camera][:enable]
              locals[:local_data][:camera_installed]  = camera_installed?
              locals[:local_data][:photos_link]       = @config[:camera][:photos_link]
              locals[:local_data][:nof_photos]        = number_of_photos
              locals[:local_data][:video_link]        = @config[:camera][:video_link]
              locals[:local_data][:nof_videos]        = number_of_videos
              locals[:local_data][:media_link]        = rpi_base_link
              locals[:local_data][:rpi_enabled]       = rpi_enabled?
              erb :admin_main, locals: locals
            when 'admin_guestbook'
              unless authorized?
                MaziLogger.debug "Not authorized"
                session['error'] = nil
                redirect "/admin_login?goto=#{index}"
              end
              locals[:js] << "js/admin_guestbook.js"
              locals[:js] << "js/tag-it.js"
              locals[:main_body] = :admin_guestbook
              locals[:local_data][:tags]                = get_guestbook_tags
              locals[:local_data][:maximumFileSize]     = get_guestbook_maxfilesize
              locals[:local_data][:welcomeMessage]      = get_guestbook_welcome_message
              locals[:local_data][:auto_expand_comment] = get_guestbook_auto_expand_comment
              locals[:local_data][:submision_name_req]  = get_guestbook_submission_name_req
              locals[:local_data][:cur_background_img]  = get_guestbook_background_image_name
              erb :admin_main, locals: locals
            when 'admin_monitor'
              unless authorized?
                MaziLogger.debug "Not authorized"
                session['error'] = nil
                redirect "/admin_login?goto=#{index}"
              end
              locals[:js] << "js/admin_monitor.js"
              locals[:main_body] = :admin_monitor
              locals[:local_data][:monitoring_enabled]              = @config[:monitoring][:enable]
              locals[:local_data][:monitoring_hardware_enabled]     = @config[:monitoring][:hardware_enable]
              locals[:local_data][:monitoring_applications_enabled] = @config[:monitoring][:applications_enable]
              locals[:local_data][:monitoring_map_enabled]          = @config[:monitoring][:map]
              locals[:local_data][:details]                         = get_monitoring_details
              locals[:local_data][:details_changed]                 = details_changed?
              if details_changed?
                locals[:local_data][:hardware_monitoring_status]      = get_hardware_monitoring_status
                locals[:local_data][:application_monitoring_status]   = get_application_monitoring_status
                locals[:local_data][:hardware_nof_entries]            = get_nof_hardware_data_entries
                locals[:local_data][:application_nof_entries]         = get_nof_application_data_entries
                locals[:local_data][:sensors_enabled]                 = @config[:sensors][:enable]
                locals[:local_data][:sensors_db_exist]                = true #sensors_db_exist?
                locals[:local_data][:available_sensors]               = getAllAvailableSensors
              end

              erb :admin_main, locals: locals
            when 'admin_logs'
              unless authorized?
                MaziLogger.debug "Not authorized"
                session['error'] = nil
                redirect "/admin_login?goto=#{index}"
              end
              locals[:js] << "js/admin_logs.js"
              locals[:main_body] = :admin_logs
              locals[:local_data][:portal_log] = MaziLogger.read_log_file(500)

              erb :admin_main, locals: locals
            when 'admin_set_date'
              locals[:main_body] = :admin_set_time
              locals[:local_data][:first_login] = false
              locals[:js] << "js/jquery.datetimepicker.min.js"
              locals[:js] << "js/admin_set_date.js"
              locals[:main_body] = :admin_set_date
              locals[:local_data][:timezones] = all_supported_timezones
              erb :admin_main, locals: locals
            when 'admin_change_password'
              unless authorized?
                MaziLogger.debug "Not authorized"
                session['error'] = nil
                redirect "/admin_login?goto=#{index}"
              end
              locals[:main_body] = :admin_change_password
              erb :admin_main, locals: locals
            when 'admin_change_mysql_password'
              unless authorized?
                MaziLogger.debug "Not authorized"
                session['error'] = nil
                redirect "/admin_login?goto=#{index}"
              end
              locals[:main_body] = :admin_change_mysql_password
              erb :admin_main, locals: locals
             when 'admin_change_username'
              unless authorized?
                MaziLogger.debug "Not authorized"
                session['error'] = nil
                redirect "/admin_login?goto=#{index}"
              end
              locals[:main_body] = :admin_change_username
              erb :admin_main, locals: locals
            when 'admin_settings'
              unless authorized?
                MaziLogger.debug "Not authorized"
                session['error'] = nil
                redirect "/admin_login?goto=#{index}"
              end
              locals[:js] << "js/jquery.datetimepicker.min.js"
              locals[:js] << "js/admin_settings.js"
              locals[:main_body]                        = :admin_settings
              locals[:local_data][:rasp_date]           = Time.now.strftime("%d %b %Y")
              locals[:local_data][:rasp_time]           = Time.now.strftime("%H:%M")
              locals[:local_data][:apache_max_filesize] = get_apache_max_filesize
              locals[:local_data][:timezones]           = all_supported_timezones
              erb :admin_main, locals: locals
            when 'admin_login'
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode download snapshot"
                session['error'] = "This portal runs on Demo mode!"
                redirect back
              end
              locals[:main_body] = :admin_login
              locals[:local_data][:goto] = params['goto']
              erb :admin_main, locals: locals
            when 'admin_logout'
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode download snapshot"
                session['error'] = "This portal runs on Demo mode! This action would have logged you out."
                redirect back
              end
              session[:username] = nil
              redirect '/admin_login'
            when 'admin_update'
              unless authorized?
                MaziLogger.debug "Not authorized"
                session['error'] = nil
                redirect "/admin_login?goto=#{index}"
              end
              locals[:js] << "js/admin_update.js"
              locals[:main_body] = :admin_update
              locals[:local_data][:current_branch] = get_current_branch
              erb :admin_main, locals: locals
            when 'update'
              return {error: 'No active internet connection.', code: -2}.to_json        if no_internet?
              return {error: 'Staged code exist in the repository.', code: -1}.to_json  if staged?
              return {error: 'Demo mode.', code: -3}.to_json                            if @config[:general][:mode] == 'demo'
              return {current_version: getVersion, commits_behind: version_difference}.to_json
            else
              MaziLogger.warn "#{index} is not supported." unless index == 'favicon.ico'
              redirect back unless index == 'favicon.ico'
            end
          end
        end

      end
    end
  end
end
