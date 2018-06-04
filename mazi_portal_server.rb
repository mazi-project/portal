require 'sinatra/base'
require 'helpers/mazi_logger'
require 'helpers/mazi_config'
require 'helpers/mazi_version'
require 'json'
require 'fileutils'
MaziVersion.update_dependencies
require 'helpers/authorizer'
require 'helpers/mazi_exec_cmd'
require 'mysql'
require 'helpers/mazi_sensors'
require 'helpers/mazi_camera'
require 'helpers/mazi_monitor'
require 'helpers/mazi_network'
require 'i18n'
require 'i18n/backend/fallbacks'
require 'helpers/mazi_locales'
require 'thin'
require 'sequel'
require 'date'
require 'pty'
require 'routes/mazi_main'
require 'routes/mazi_sessions'
require 'routes/mazi_config'
require 'routes/mazi_rest'
require 'routes/mazi_application'
require 'routes/mazi_notification'
require 'routes/mazi_exec'
require 'routes/mazi_devices'
require 'routes/mazi_monitor'
require 'routes/mazi_locales'

class MaziApp < Sinatra::Base
  include MaziConfig
  include Authorizer
  include MaziVersion
  include MaziSensors
  include MaziCamera
  include MaziMonitor
  include MaziLocales
  include MaziNetwork

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
    if @config[:monitoring].nil?
      @config[:monitoring] = {}
      @config[:monitoring][:enable]              = false
      @config[:monitoring][:hardware_enable]     = false
      @config[:monitoring][:applications_enable] = false
      @config[:monitoring][:map]                 = false
      writeConfigFile
    end
    if @config[:monitoring][:map].nil?
      @config[:monitoring][:map] = false
      writeConfigFile
    end
    unless File.exists?('/etc/mazi/mazi.conf')
      tmp = {}
      tmp[:deployment]  = 'MAZI Zone'
      tmp[:admin]       = 'John Doe'
      tmp[:title]       = 'Default MAZI Zone'
      tmp[:description] = 'This is a default MAZI Zone'
      tmp[:loc]         = '0.000000, 0.000000'
      tmp[:mode]        = 'offline'
      File.open("/etc/mazi/mazi.conf","w") do |f|
        f.write(tmp.to_json)
      end
    else
      mode = File.read('/etc/mazi/mazi.conf')
      begin
        JSON.parse(mode)
      rescue JSON::ParserError
        tmp = {}
        tmp[:deployment]  = 'MAZI Zone'
        tmp[:admin]       = 'John Doe'
        tmp[:title]       = 'Default MAZI Zone'
        tmp[:description] = 'This is a default MAZI Zone'
        tmp[:loc]         = '0.000000, 0.000000'
        tmp[:mode]        = mode.strip
        File.open("/etc/mazi/mazi.conf","w") do |f|
          f.write(tmp.to_json)
        end
      end
    end
    unless File.exists?('/etc/mazi/sql.conf')
      tmp = {}
      tmp[:username] = 'root'
      tmp[:password] = 'm@z1'
      File.open("/etc/mazi/sql.conf","w") do |f|
        f.write(tmp.to_json)
      end
    end
    MaziLogger.debug "INIT with config: #{@config}"
    Sequel.connect('sqlite://database/inventory.db')
    require 'models'
    init_sensors
    init_camera
    init_locales
    Mazi::Model::Application.all.each do |app|
      if app.icon.nil?
        case app.name
        when "Etherpad"
          app.icon  = "fa fa-5x fa-file-alt"
          app.color = "green"
          app.type  = "standalone"
        when "NextCloud"
          app.icon  = "fa fa-5x fa-cloud"
          app.color = "red"
          app.type  = "web"
        when "GuestBook"
          app.icon  = "fa fa-5x fa-book"
          app.color = "yellow"
          app.type  = "standalone"
        when "WordPress"
          app.icon  = "fab fa-5x fa-wordpress-simple"
          app.color = "blue"
          app.type  = "web"
        when "FramaDate"
          app.icon  = "fa fa-5x fa-question"
          app.color = "purple"
          app.type  = "web"
        when "Interview-archive"
          app.icon  = "fa fa-5x fa-file-audio"
          app.color = "teal"
          app.type  = "standalone"
        end
        app.save
      end
    end
  end

  error do |err|
    MaziLogger.error "#{err.message}"
    err.backtrace.each do |trace|
      MaziLogger.error "  #{trace}"
    end
    err
  end

  at_exit do
    MaziLogger.debug "Exiting"
    pid = `ps aux | grep -v grep | grep 'bash /root/back-end/mazi-sense.sh -n sensehat -m -ac -g' | awk '{print $2}'`
    `kill -9 #{pid}`
  end

  register Sinatra::MaziApp::Routing::MaziMain
  register Sinatra::MaziApp::Routing::MaziConfig
  register Sinatra::MaziApp::Routing::MaziRest
  register Sinatra::MaziApp::Routing::MaziSessions
  register Sinatra::MaziApp::Routing::MaziApplication
  register Sinatra::MaziApp::Routing::MaziNotification
  register Sinatra::MaziApp::Routing::MaziExec
  register Sinatra::MaziApp::Routing::MaziDevices
  register Sinatra::MaziApp::Routing::MaziMonitor
  register Sinatra::MaziApp::Routing::MaziLocales
end

Thin::Server.start MaziApp, '0.0.0.0', 4567
