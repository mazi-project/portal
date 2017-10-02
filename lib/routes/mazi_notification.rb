module Sinatra
  module MaziApp
    module Routing
      module MaziNotification

        def self.registered(app)

          # admin create notification
          app.post '/notification/?' do
            MaziLogger.debug "request: post/notification from ip: #{request.ip} creds: #{params.inspect}"
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode create notification"
              session['error'] = "This portal runs on Demo mode! This action would have created a notification."
              redirect '/admin_notification'
            end
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              redirect '/admin_login'
            end

            a =  Mazi::Model::Notification.create(params)
            redirect '/admin_notification'
          end

          # admin edit notification
          app.post '/notification/edit/?' do
            MaziLogger.debug "request: put/notification from ip: #{request.ip} params: #{params.inspect}"
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode edit notification"
              session['error'] = "This portal runs on Demo mode! This action would have editted a notification."
              redirect '/admin_notification'
            end
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              redirect '/admin_login'
            end
            id = params['id']
            notif         =  Mazi::Model::Notification.find(id: params['id'].to_i)
            notif.title   = params['name'] if params['name']
            notif.body    = params['description'] if params['description']
            notif.enabled = params['enabled'] if params['enabled']
            notif.save
            redirect '/admin_notification'
          end

          # admin delete notification
          app.delete '/notification/:id/?' do |id|
            MaziLogger.debug "request: delete/notification from ip: #{request.ip} id: #{id}"
            if !authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              {error: 'Not Authorized!', id: id}.to_json
            elsif @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode delete notification"
              session['error'] = nil
              {error: "This portal runs on Demo mode! This action would have deleted a notification.", id: id}.to_json
            else
              notif = Mazi::Model::Notification.find(id: id)
              notif.destroy
              {result: 'OK', id: id}.to_json
            end
          end

          # toggles notification enable disable
          app.put '/notification/:id/?' do |id|
            MaziLogger.debug "request: put/notification from ip: #{request.ip} id: #{id}"
            if !authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              {error: 'Not Authorized!', id: id}.to_json
            elsif @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode toggle notification enabled."
              session['error'] = "This portal runs on Demo mode! This action would have toggled notification visibility on the portal"
              {error: "This portal runs on Demo mode! This action would have toggled notification visibility on the portal", id: id}.to_json
            else
              notif = Mazi::Model::Notification.find(id: id)
              notif.enabled = !notif.enabled
              notif.save
              {result: 'OK', id: id}.to_json
            end
          end

          # toggles notification read just in session
          app.put '/notification/:id/read/?' do |id|
            MaziLogger.debug "request: put/notification from ip: #{request.ip} id: #{id}"
            session[:notifications_read] << id.to_i
            {result: 'OK', id: id}.to_json
          end
        end

      end
    end
  end
end