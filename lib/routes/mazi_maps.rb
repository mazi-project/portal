module Sinatra
  module MaziApp
    module Routing
      module MaziMaps

        def self.registered(app)

          app.get '/maps/monitoring_map' do
            locals                            = {}
            locals[:local_data]               = {}
            locals[:local_data][:deployments] = enrichDeployments(getAllDeploymentsWithData)
            erb :index_monitoring_map, locals: locals
          end

        end

      end
    end
  end
end
