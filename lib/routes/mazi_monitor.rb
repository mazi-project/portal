module Sinatra
  module MaziApp
    module Routing
      module MaziMonitor

        def self.registered(app)
          app.post '/monitor/toggle/:action/?' do |action|
            MaziLogger.debug "request: post/monitor/action from ip: #{request.ip} action: #{action} params: #{params.inspect}"
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              return {error: 'Not Authorized!', action: action}.to_json
            end
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode exec script"
              session['error'] = "This portal runs on Demo mode! This action would have toggled the monitoring feature."
              redirect back
            end

            case action
            when "overall"
              toggle_monitoring_enable
              disable_monitorings
            when "applications"
              toggle_applications_monitoring_enable
            when "hardware"
              toggle_hardware_monitoring_enable
            when "map"
              toggle_monitoring_map_enable
            else

            end
          end

          app.get '/maps/device/:id/data/?' do |id|
            data = {}
            data[:sensors]      = getSensorDataForDevice(id)
            data[:applications] = getApplicationDataForDevice(id)
            data[:users]        = getUserDataForDevice(id)
            data[:system]       = getSystemDataForDevice(id)
            data.to_json
          end

          app.post '/monitor/change/details/?' do
            MaziLogger.debug "request: post/monitor/details from ip: #{request.ip} params: #{params.inspect}"
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              return {error: 'Not Authorized!', action: action}.to_json
            end
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode exec script"
              session['error'] = "This portal runs on Demo mode! This action would have toggled the monitoring feature."
              redirect back
            end
            write_monitoring_details(params)
            redirect "/admin_monitor"
          end

          app.post '/monitor/start/:type/?' do |type|
            MaziLogger.debug "request: post/monitor/start/data from ip: #{request.ip} type: #{type} params: #{params.inspect}"
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              return {error: 'Not Authorized!', type: type}.to_json
            end
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode exec script"
              session['error'] = "This portal runs on Demo mode! This action would have toggled the monitoring feature."
              return {error: 'Demo!', type: type}.to_json
            end
            case type
            when 'hardware_data'
              if params['end_point'].nil? || params['end_point'].empty?
                MaziLogger.debug "End point url not specified."
                session['error'] = "Target server is mandatory, plese try again and make sure you specify the target server!"
                redirect back
              end
              url = params['end_point']
              arguements = ""
              arguements += "-t " if params[:temp] == 'on'
              arguements += "-u " if params[:users] == 'on'
              arguements += "-c " if params[:cpu] == 'on'
              arguements += "-r " if params[:ram] == 'on'
              arguements += "-s " if params[:storage] == 'on'

              if arguements == ""
                MaziLogger.debug "No metrics selected."
                session['error'] = "At least one metric must be selected."
                redirect back
              end

              start_hardware_monitoring(url, arguements)
            when 'application_data'
              if params['end_point'].nil? || params['end_point'].empty?
                MaziLogger.debug "End point url not specified."
                session['error'] = "Target server is mandatory, plese try again and make sure you specify the target server!"
                redirect back
              end
              url = params['end_point']
              arguements = "-n '"
              arguements += "guestbook " if params[:guestbook] == 'on'
              arguements += "etherpad "  if params[:etherpad]  == 'on'
              arguements += "framadate " if params[:framadate] == 'on'
              arguements += "nextcloud " if params[:nextcloud] == 'on'
              arguements += "'"

              if arguements == "-n ''"
                MaziLogger.debug "No metrics selected."
                session['error'] = "At least one metric must be selected."
                redirect back
              end

              start_application_monitoring(url, arguements)
            end
            {status: 'OK'}.to_json
          end

          app.post '/monitor/stop/:type/?' do |type|
            MaziLogger.debug "request: post/monitor/stop/data from ip: #{request.ip} type: #{type} params: #{params.inspect}"
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              return {error: 'Not Authorized!', action: action}.to_json
            end
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode exec script"
              session['error'] = "This portal runs on Demo mode! This action would have toggled the monitoring feature."
              redirect back
            end
            case type
            when 'hardware_data'
              stop_hardware_monitoring
            when 'application_data'
              stop_application_monitoring
            end
            redirect "/admin_monitor"
          end

          app.post '/monitor/flush/:type/?' do |type|
            MaziLogger.debug "request: post/monitor/flush/data from ip: #{request.ip} type: #{type} params: #{params.inspect}"
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              return {error: 'Not Authorized!', type: type}.to_json
            end
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode exec script"
              session['error'] = "This portal runs on Demo mode! This action would have toggled the monitoring feature."
              redirect back
            end
            case type
            when 'hardware_data'
              flush_hardware_data
            when 'application_data'
              flush_application_data(params['guestbook'], params['etherpad'], params['framadate'], params['nextcloud'])
            end
            redirect "/admin_monitor"
          end

          app.get '/monitor/status/:type/?' do |type|
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              return {error: 'Not Authorized!', type: type}.to_json
            end
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode exec script"
              session['error'] = "This portal runs on Demo mode! This action would have toggled the monitoring feature."
              redirect back
            end
            case type
            when 'hardware_data'
              status = get_hardware_monitoring_status
              {type: type, status: status}.to_json
            when 'application_data'
              status = get_application_monitoring_status
              {type: type, status: status}.to_json
            end
          end
        end
      end
    end
  end
end
