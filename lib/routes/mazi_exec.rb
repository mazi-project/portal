module Sinatra
  module MaziApp
    module Routing
      module MaziExec

        def self.registered(app)
          # executing a script
          app.post '/exec/?' do
            MaziLogger.debug "request: post/exec from ip: #{request.ip} params: #{params.inspect}"
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              redirect '/admin_login'
            end
            env = params['env']
            path = params['path'] || @config[:scripts][:backend_scripts_folder]
            cmd = "#{params['cmd']}"
            case cmd
            when 'wifiap.sh'
              args = []
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode exec script"
                # md, vl = params['ssid'] ? ['ssid', params['ssid']] : params['channel'] ? ['channel', params['channel']] : params['password'] ? ['password', params['password']] : ['wpa', 'off']
                session['error'] = "This portal runs on Demo mode! This action would have changed the WiFi network parameters."
                redirect '/admin_network'
              end
              args << "-i '#{params['interface']}'" if params['interface']
              args << "-s '#{params['ssid']}'" if params['ssid']
              args << "-c #{params['channel']}" if params['channel']
              if params['password'].nil? || params['password'].empty? || params['password'] == '' || params['password'] == ' ' || params['password'] == '-'
                args << "-w off"
              elsif params['password']
                if params['password'].length < 8
                  MaziLogger.debug "WiFi password must be more than 8 characters long"
                  session['error'] = "WiFi password must be more than 8 characters long"
                  redirect '/admin_network'
                end
                args << "-p #{params['password']}"
              end
            when 'internet.sh'
              args = []
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode exec script"
                session['error'] = "This portal runs on Demo mode! This action would have changed the 'network mode' to '#{params['mode']}'" if params['mode']
                redirect '/admin_network'
              end
              args << "-m #{params['mode']}" if params['mode']
              args << "-a #{params['activate']}" if params['activate']
              args << "-d #{params['deactivate']}" if params['deactivate']
              redirect '/admin_network' if args.empty?
            when 'antenna.sh'
              args = []
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode exec script"
                session['error'] = "This portal runs on Demo mode! This action would have connected the second wireless interface to a wireless network."
                redirect '/admin_network'
              end
              # ssid = params['ssid'].nil? || params['ssid'].empty? ? params['hidden-ssid'] : params['ssid']
              unless params['ssid'].nil? || params['ssid'].empty?
                args << "-s '#{params['ssid']}'"
              else
                unless params['hidden-ssid'].nil? || params['hidden-ssid'].empty?
                  args << "-s '#{params['hidden-ssid']}' -h"
                end
              end
              args << "-i '#{params['interface']}'" if params['interface']
              args << "-d " if params['disconnect']
              args << "-p #{params['password']}" unless params['password'].nil? || params['password'].empty?
            when 'mazi-router.sh'
              args = []
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode exec script"
                session['error'] = "This portal runs on Demo mode! This action would have changed the Access Point Device."
                redirect '/admin_network'
              end
              args << '-a' if params['action'] == 'activate'
              args << '-d' if params['action'] == 'deactivate'
            when 'mazi-domain.sh'
              args = []
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode exec script"
                session['error'] = "This portal runs on Demo mode! This action would have changed the Portal's Domain."
                redirect '/admin_network'
              end
              vdom_msg = verify_domain(params['domain'])
              unless vdom_msg.nil?
                MaziLogger.debug "Domain #{params['domain']} is invalid! Message: #{vdom_msg}"
                session['error'] = "Domain #{params['domain']} is invalid! The domain must '#{vdom_msg}'"
                redirect '/admin_network'
              end
              args << "-d #{params['domain']}" unless params['domain'].nil? || params['domain'].empty?
            when 'mazi-mesh.sh'
              args = []
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode exec script"
                session['error'] = "This portal runs on Demo mode! This action would have changed the Portal's Domain."
                redirect '/admin_network'
              end
              args << params['mode'] unless params['mode'].nil? || params['mode'].empty?
              args << "-i #{params['interface']}" unless params['interface'].nil? || params['interface'].empty?
              args << "-s #{params['ssid']}" unless params['ssid'].nil? || params['ssid'].empty?
              args << "-b #{params['bridge']}" if !(params['bridge'].nil? || params['bridge'].empty?) && params['bridge'] == 'node'
              args << "--ip #{params['ip']}" unless params['ip'].nil? || params['ip'].empty?
            else
              args = []
            end
            begin
              ex = MaziExecCmd.new(env, path, cmd, args, @config[:scripts][:enabled_scripts])
              lines = ex.exec_command
              sleep 5 if cmd == 'antenna.sh'
              redirect '/admin_network'
            rescue ScriptNotEnabled => e
              MaziLogger.debug "Not enabled script '#{cmd}'"
              session['error'] = "#{cmd} is not enabled"
              redirect '/admin'
            end
          end

          app.post '/action/:action/?' do |action|
            MaziLogger.debug "request: put/action from ip: #{request.ip} action: #{action}"
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              return {error: 'Not Authorized!', action: action}.to_json
            end
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode exec script"
              session['error'] = "This portal runs on Demo mode! This action would have #{action == 'shutdown' ? 'shutted down' : 'restarted'} this MAZI Zone."
              redirect back
            end

            if action == 'shutdown'
              Thread.new do
                sleep 2
                MaziLogger.debug 'Shutting down'
                `shutdown -h now`
              end
            elsif action == 'restart' || action == 'reboot'
              Thread.new do
                sleep 2
                MaziLogger.debug 'Restarting'
                `reboot`
              end
            else
              return {error: 'Invalid action', action: action}.to_json
            end
            redirect '/admin'
          end
        end

      end
    end
  end
end
