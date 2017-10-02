require 'sinatra/base'
require 'helpers/mazi_logger'
require 'helpers/mazi_config'
require 'helpers/mazi_version'
MaziVersion.update_dependencies
require 'helpers/authorizer'
require 'helpers/mazi_exec_cmd'
require 'mysql'
require 'helpers/mazi_sensors'
require 'helpers/mazi_camera'
require 'thin'
require 'json'
require 'sequel'
require 'date'
require 'routes/mazi_main'
require 'routes/mazi_sessions'
require 'routes/mazi_config'
require 'routes/mazi_rest'
require 'routes/mazi_application'
require 'routes/mazi_notification'
require 'routes/mazi_exec'
require 'routes/mazi_devices'

class MaziApp < Sinatra::Base
  include MaziConfig
  include Authorizer
  include MaziVersion
  include MaziSensors
  include MaziCamera

  use Rack::Session::Pool #, :expire_after => 60 * 60 * 24
  configure {set :show_exceptions, false}
  configure {set :dump_errors, false}

  def initialize
    super
    @config = loadConfigFile
    if @config[:sensors].nil?
      @config[:sensors] = {}
      @config[:sensors][:enable] = false
      writeConfigFile
    end
    if @config[:camera].nil?
      @config[:camera] = {}
      @config[:camera][:enable] = false
      writeConfigFile
    end
    MaziLogger.debug "INIT with config: #{@config}"
    Sequel.connect('sqlite://database/inventory.db')
    require 'models'
    init_sensors
    init_camera
  end

  error do |err|
    MaziLogger.error "#{err.message}"
    err.backtrace.each do |trace|
      MaziLogger.error "  #{trace}"
    end
    err
  end

  register Sinatra::MaziApp::Routing::MaziMain
  register Sinatra::MaziApp::Routing::MaziConfig
  register Sinatra::MaziApp::Routing::MaziRest
  register Sinatra::MaziApp::Routing::MaziSessions
  register Sinatra::MaziApp::Routing::MaziApplication
  register Sinatra::MaziApp::Routing::MaziNotification
  register Sinatra::MaziApp::Routing::MaziExec
  register Sinatra::MaziApp::Routing::MaziDevices

end

Thin::Server.start MaziApp, '0.0.0.0', 4567
