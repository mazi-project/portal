module Sinatra
  module MaziApp
    module Routing
      module MaziApplication

        def self.registered(app)
          # admin create application
          app.post '/application/?' do
            MaziLogger.debug "request: post/application from ip: #{request.ip} creds: #{params.inspect}"
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              redirect '/admin_login?goto=admin_application'
            end
            if params['instance']
              e = Mazi::Model::ApplicationInstance.validate(params)
              unless e.nil?
                MaziLogger.debug "invalid param #{e}"
                session['error'] = e
                redirect '/admin_application'
              end
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode create app"
                session['error'] = "This portal runs on Demo mode! This action would have created a new application."
                redirect '/admin_application'
              end

              a =  Mazi::Model::ApplicationInstance.create(params)
            else
              e = Mazi::Model::Application.validate(params)
              unless e.nil?
                MaziLogger.debug "invalid param #{e}"
                session['error'] = e
                redirect '/admin_application'
              end
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode create app"
                session['error'] = "This portal runs on Demo mode! This action would have created a new application."
                redirect '/admin_application'
              end

              a =  Mazi::Model::Application.create(params)
            end
            redirect '/admin_application'
          end

          # admin edit application
          app.post '/application/edit/?' do
            MaziLogger.debug "request: put/application from ip: #{request.ip} params: #{params.inspect}"
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              redirect '/admin_login?goto=admin_application'
            end
            if params['instance']
              e = Mazi::Model::ApplicationInstance.validate_edit(params)
              unless e.nil?
                MaziLogger.debug "invalid param #{e}"
                session['error'] = e
                redirect '/admin_application'
              end
              id = params['id']
              app =  Mazi::Model::ApplicationInstance.find(id: params['id'].to_i)
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode edit app"
                session['error'] = "This portal runs on Demo mode! This action would have edited the '#{app.name}' application."
                redirect '/admin_application'
              end
              app.name        = params['name'] if params['name']
              app.url         = params['url'] if params['url']
              app.description = params['description'] if params['description']
              app.enabled     = params['enabled'] if params['enabled']
              app.save
            else
              e = Mazi::Model::Application.validate_edit(params)
              unless e.nil?
                MaziLogger.debug "invalid param #{e}"
                session['error'] = e
                redirect '/admin_application'
              end
              id = params['id']
              app =  Mazi::Model::Application.find(id: params['id'].to_i)
              if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode edit app"
                session['error'] = "This portal runs on Demo mode! This action would have edited the '#{app.name}' application."
                redirect '/admin_application'
              end
              app.name        = params['name'] if params['name']
              app.url         = params['url'] if params['url']
              app.description = params['description'] if params['description']
              app.enabled     = params['enabled'] if params['enabled']
              app.save
            end
            redirect '/admin_application'
          end

          # admin delete application
          app.delete '/application/:id/?' do |id|
            MaziLogger.debug "request: delete/application from ip: #{request.ip} id: #{id}"
            if !authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              {error: 'Not Authorized!', id: id}.to_json
            elsif @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode delete app"
              session['error'] = nil
              {error: "This portal runs on Demo mode! This action would have deleted an existing application.", id: id}.to_json
            else
              app = Mazi::Model::Application.find(id: id)
              app.destroy
              {result: 'OK', id: id}.to_json
            end
          end

          # admin delete application
          app.delete '/application/:id/instance/?' do |id|
            MaziLogger.debug "request: delete/application from ip: #{request.ip} id: #{id}"
            if !authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              {error: 'Not Authorized!', id: id}.to_json
            elsif @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode delete app"
              session['error'] = nil
              {error: "This portal runs on Demo mode! This action would have deleted an existing application.", id: id}.to_json
            else
              app = Mazi::Model::ApplicationInstance.find(id: id)
              app.destroy
              {result: 'OK', id: id}.to_json
            end
          end

          # toggles application enable disable
          app.put '/application/:id/?' do |id|
            MaziLogger.debug "request: put/application from ip: #{request.ip} id: #{id}"
            if !authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              {error: 'Not Authorized!', id: id}.to_json
            elsif @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode toggle enabled"
              session['error'] = "This portal runs on Demo mode! This action would have toggled application visibility on the portal."
              {error: "This portal runs on Demo mode! This action would have toggled application visibility on the portal.", id: id}.to_json
            else
              app = Mazi::Model::Application.find(id: id)
              app.enabled = !app.enabled
              app.save
              {result: 'OK', id: id}.to_json
            end
          end

          # toggles application enable disable
          app.put '/application/:id/instance/?' do |id|
            MaziLogger.debug "request: put/application from ip: #{request.ip} id: #{id}"
            if !authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              {error: 'Not Authorized!', id: id}.to_json
            elsif @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode toggle enabled on instance"
              session['error'] = "This portal runs on Demo mode! This action would have toggled application instance visibility on the portal."
              {error: "This portal runs on Demo mode! This action would have toggled application instance visibility on the portal.", id: id}.to_json
            else
              app = Mazi::Model::ApplicationInstance.find(id: id)
              app.enabled = !app.enabled
              app.save
              {result: 'OK', id: id}.to_json
            end
          end

          # toggles application enable disable
          app.put '/application/:id/instance/splash/?' do |id|
            MaziLogger.debug "request: put/application from ip: #{request.ip} id: #{id}"
            if !authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              {error: 'Not Authorized!', id: id}.to_json
            elsif @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode toggle enabled on instance"
              session['error'] = "This portal runs on Demo mode! This action would have toggled application instance as a splash screen on the portal."
              {error: "This portal runs on Demo mode! This action would have toggled application instance visibility on the portal.", id: id}.to_json
            else
              app = Mazi::Model::ApplicationInstance.find(id: id)
              Mazi::Model::ApplicationInstance.all.each do |inst|
                next if inst.id == app.id
                inst.splash_screen = false
                inst.save
              end
              app.splash_screen = !app.splash_screen
              app.save
              {result: 'OK', id: id}.to_json
            end
          end

          # application status/start/stop
          app.put '/application/:id/action/:action/?' do |id, action|
            MaziLogger.debug "request: put/application from ip: #{request.ip} id: #{id} action: #{action}"
            if !authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              {error: 'Not Authorized!', id: id}.to_json
            elsif @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode app acion"
              session['error'] = "This portal runs on Demo mode! This would have run the action '#{action}' to an existing application."
              {error: "This portal runs on Demo mode! This would have run the action '#{action}' to an existing application.", id: id}.to_json
            else
              app = Mazi::Model::Application.find(id: id)
              res = 'FAIL'
              case action
              when 'start'
                res = app.start
              when 'stop'
                res = app.stop
              when 'status'
                res = app.status
              end
              {result: res, id: id}.to_json
            end
          end

          # application counter +1
          app.put '/application/:id/click_counter/?' do |id|
            MaziLogger.debug "request: put/application from ip: #{request.ip} id: #{id}"
            app = Mazi::Model::ApplicationInstance.find(id: id)
            app.application.click_counter += 1
            app.click_counter = app.click_counter + 1
            app.save
            {result: 'OK', id: id}.to_json
          end

          # application counter reset
          app.delete '/application/:id/click_counter/?' do |id|
            MaziLogger.debug "request: delete/application/click_counter from ip: #{request.ip} creds: #{params.inspect}"
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              return {error: 'Not Authorized!', id: id}.to_json
            end
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode reset counter"
              session['error'] = nil
              {error: "This portal runs on Demo mode! This action would have reseted a click counter."}.to_json
            end
            if id == 'all'
              Mazi::Model::Application.all.each do |app|
                app.click_counter = 0
                app.save
              end
              Mazi::Model::ApplicationInstance.all.each do |app|
                app.click_counter = 0
                app.save
              end
            else
              app = Mazi::Model::Application.find(id: id)
              app.click_counter = 0
              app.save
            end
            {result: 'OK', id: id}.to_json
          end

          app.post '/application_admin/:application/:action/?' do |application, action|
            MaziLogger.debug "request: post/application_admin from ip: #{request.ip} application: #{application} action: #{action} params: #{params.inspect}"
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              redirect '/admin_login?goto=admin_guestbook'
            end
            if @config[:general][:mode] == 'demo'
                MaziLogger.debug "Demo mode application action"
                session['error'] = "This portal runs on Demo mode! This action would have changed the configuration of #{application}."
                redirect back
              end

            case application
            when 'guestbook'
              case action
              when 'tags'
                save_guestbook_tags(params['tags'])
              when 'background_image'
                tempfile = params['guestbook_background_image'][:tempfile]
                filename = params['guestbook_background_image'][:filename]
                upload_guestbook_background_image(filename, tempfile)
              when 'maxfilesize'
                set_guestbook_maxfilesize(params['maxfilesize'])
              when 'welcome_message'
                set_guestbook_welcome_message(params['welcome_message'])
              when 'auto_expand_comment'
                value = get_guestbook_auto_expand_comment
                set_guestbook_auto_expand_comment(value == "false" ? "true" : "false")
              when 'submission_name_req'
                value = get_guestbook_submission_name_req
                set_guestbook_submission_name_req(value == "false" ? "true" : "false")
              end
              redirect 'admin_guestbook'
            else
              MaziLogger.debug "Application '#{application}' not supported."
              session['error'] = "Application '#{application}' not supported by this action."
              redirect back
            end
          end
        end

      end
    end
  end
end