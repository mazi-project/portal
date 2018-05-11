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

        end

      end
    end
  end
end
