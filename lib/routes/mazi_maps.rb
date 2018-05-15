module Sinatra
  module MaziApp
    module Routing
      module MaziMaps

        def self.registered(app)

          app.get '/maps/monitoring_map/?' do
            locals                            = {}
            locals[:local_data]               = {}
            locals[:local_data][:deployments] = enrichDeployments(getAllDeploymentsWithData)
            erb :index_monitoring_map, locals: locals
          end

          app.get '/maps/device/:id/data/?' do |id|
            data = {}
            data[:sensors]      = getSensorDataForDevice(id)
            data[:applications] = getApplicaitonDataForDevice(id)
            data[:users]        = getUserDataForDevice(id)
            data[:system]       = getSystemDataForDevice(id)
            data.to_json
          end

          app.get '/maps/device/:id/data/:type/?' do |id, type|
            data = {}
            case type
            when 'wifi'
              data = getUserDataForDevice(id)
            end
            data.to_json
          end

          app.get '/maps/device/:id/sensor/:sensor_id/data/:type/?' do |id, sensor_id, type|
            sensor_data = getSensorDataForDevice(id)
            data = sensor_data[sensor_id][:data][type.to_sym]
            data.to_json
          end

          app.get '/maps/device/:id/application/:application/data/:type?' do |id, application, type|
            application_data = getApplicationDataForDevice(id)
            data = application_data[application.to_s][:data][type.to_sym]
            data.to_json
          end

        end

      end
    end
  end
end
