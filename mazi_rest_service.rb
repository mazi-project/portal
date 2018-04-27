require 'sinatra/base'
require 'helpers/mazi_logger'
require 'json'
require 'fileutils'
require 'mysql'
require 'thin'
require 'date'
require 'i18n'
require 'i18n/backend/fallbacks'
require 'helpers/mazi_config'
require 'helpers/mazi_sensors'
require 'helpers/mazi_locales'
require 'routes/mazi_rest'
require 'routes/mazi_maps'

class MaziRestApp < Sinatra::Base
  include MaziConfig
  include MaziSensors
  include MaziLocales

  configure {set :show_exceptions, false}
  configure {set :dump_errors, false}

  error do |err|
    MaziLogger.error "#{err.message}"
    err.backtrace.each do |trace|
      MaziLogger.error "  #{trace}"
    end
    err
  end

  def initialize
    super
    @config = loadConfigFile
    init_locales
  end

  at_exit do
    MaziLogger.debug "Exiting"
    pid = `ps aux | grep -v grep | grep 'bash /root/back-end/mazi-sense.sh -n sensehat -m -ac -g' | awk '{print $2}'`
    `kill -9 #{pid}`
  end

  register Sinatra::MaziApp::Routing::MaziRest
  register Sinatra::MaziApp::Routing::MaziMaps
end

Thin::Server.start MaziRestApp, '0.0.0.0', 7654
