module Sinatra
  module MaziApp
    module Routing
      module MaziDevices

        def self.registered(app)
          app.post '/devices/:device/:action' do |device, action|
            MaziLogger.debug "request: post/action from ip: #{request.ip} device: #{device} action: #{action} params: #{params.inspect}"
            unless authorized?
              MaziLogger.debug "Not authorized"
              session['error'] = nil
              return {error: 'Not Authorized!', device: device, action: action}.to_json
            end
            if @config[:general][:mode] == 'demo'
              MaziLogger.debug "Demo mode exec script"
              session['error'] = "This portal runs on Demo mode! This action would have effected a device."
              redirect back
            end

            case device
            when 'sensors'
              if action == 'toggle'
                toggle_sensors_enabled
              elsif action == 'init'
                initialize_sensors_module(params['root-password'])
                redirect back
              end
            when 'camera'
              if action == 'toggle'
                toggle_camera_enabled
              elsif action == 'init'
                initialize_camera_module
                redirect back
              elsif action == 'capture'
                capture_image
                redirect back
              elsif action == 'start_capturing'
                start_image_capturing(params['duration'], params['interval'])
                redirect back
              elsif action == 'capture_video'
                start_video_capturing(params['duration'])
                redirect back
              elsif action == 'delete'
                clear_photos if params['type'] == 'photos'
                clear_videos if params['type'] == 'videos'
                redirect back
              end
            when 'sht11', 'sensehat', 'sht22'
              if action == 'start'
                duration = 0
                if !params['duration'].nil? && !params['duration'].empty?
                  duration = params['duration'].to_i
                elsif !params['until_date'].nil? && !params['until_date'].empty?
                  dt_now = DateTime.now
                  dt_target = DateTime.parse(params['until_date'])
                  duration = ((dt_target - dt_now) * 24 * 60 * 60).to_i
                else
                  MaziLogger.debug "Sensing proccedure did not start. You need to specify either a duration or an end date."
                  session['error'] = "Sensing proccedure did not start. You need to specify either a duration or an end date."
                  redirect back
                end
                unless duration > 0
                  MaziLogger.debug "Duration cannot be zero or negative."
                  session['error'] = "Duration cannot be zero or negative."
                  redirect back
                end
                start_sensing(device, duration, params['interval'], params['end_point'])
                redirect back
              elsif action == 'delete'
                delete_measurements(params['id'])
                redirect back
              end
            end
            {result: 'OK', device: device, action: action}.to_json
          end

          app.get '/devices/sensors/status/:id/?' do |sensor_id|
            MaziLogger.debug "request: post/devices/sensors/status from ip: #{request.ip} id: #{sensor_id} params: #{params.inspect}"
            out               = {}
            out[:id]          = sensor_id
            out[:status]      = get_sensor_status(sensor_id)
            out[:nof_entries] = get_nof_sensor_measurements(sensor_id)

            out.to_json
          end

          app.get '/devices/sensors/sensehat/get_metrics' do
            # MaziLogger.debug "request: get/devices/sensors/sensehat/get_metrics from ip: #{request.ip} params: #{params.inspect}"
            get_sensehat_metrics.to_json
          end

          app.post '/devices/sensors/sensehat/start_metrics' do
            MaziLogger.debug "request: post/devices/sensors/sensehat/get_metrics from ip: #{request.ip} params: #{params.inspect}"
            start_sensehat_metrics
          end

          app.delete '/devices/sensors/sensehat/stop_metrics' do
            MaziLogger.debug "request: delete/devices/sensors/sensehat/get_metrics from ip: #{request.ip} params: #{params.inspect}"
            stop_sensehat_metrics
          end
        end

      end
    end
  end
end
