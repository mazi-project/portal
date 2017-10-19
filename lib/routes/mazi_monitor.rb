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
              puts @config
            when "hardware"
              toggle_hardware_monitoring_enable
              puts @config
            else

            end
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
              return {error: 'Not Authorized!', action: action}.to_json
            end
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode exec script"
              session['error'] = "This portal runs on Demo mode! This action would have toggled the monitoring feature."
              redirect back
            end
            case type
            when 'hardware_data'
              puts "Hardware start"
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
              puts "Application start"
              if params['end_point'].nil? || params['end_point'].empty?
                MaziLogger.debug "End point url not specified."
                session['error'] = "Target server is mandatory, plese try again and make sure you specify the target server!"
                redirect back
              end
              url = params['end_point']
              arguements = ""
              arguements += "-n guestbook " if params[:guestbook] == 'on'
              arguements += "-n etherpad "  if params[:etherpad]  == 'on'
              arguements += "-n framadate " if params[:framadate] == 'on'

              if arguements == ""
                MaziLogger.debug "No metrics selected."
                session['error'] = "At least one metric must be selected."
                redirect back
              end

              start_application_monitoring(url, arguements)
            end
            redirect "/admin_monitor"
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
        end
      end
    end
  end
end