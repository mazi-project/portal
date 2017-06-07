require 'sinatra/base'
require 'helpers/mazi_logger'
require 'helpers/mazi_version'
MaziVersion.update_dependencies
require 'helpers/authorizer'
require 'helpers/mazi_exec_cmd'
require 'helpers/mazi_config'
require 'mysql'
require 'helpers/mazi_sensors'
require 'helpers/mazi_camera'
require 'thin'
require 'json'
require 'sequel'
require 'date'

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
 
  get '/' do
    redirect 'index'
  end

  # this is the main routing configuration that routes all the erb files
  get '/:index/?' do |index|
    MaziLogger.debug "request: get/#{index} from ip: #{request.ip}"
    if session['uuid'].nil?
      s = Mazi::Model::Session.create
      s.ip = request.ip
      s.save
      session['uuid'] = s.uuid
    end
    if first_time? && index != 'setup'
      redirect '/setup'
    end
    locals                           = {}
    locals[:local_data]              = {}
    locals[:local_data][:mode]       = @config[:general][:mode]
    locals[:local_data][:authorized] = authorized?
    locals[:version]                 = getVersion
    locals[:js]                      = []
    locals[:error_msg]               = nil
    locals[:sensors_enabled]         = sensors_enabled?
    locals[:camera_enabled]          = camera_enabled?
    unless session['error'].nil?
      locals[:error_msg] = session["error"]
      session[:error] = nil
    end
    case index
    when 'index'
      session['notifications_read'] = [] if session['notifications_read'].nil?
      locals[:js] << "js/index_application.js"
      locals[:main_body] = :index_application
      locals[:local_data][:applications]          = Mazi::Model::Application.all
      locals[:local_data][:notifications]         = Mazi::Model::Notification.all
      locals[:local_data][:application_instances] = Mazi::Model::ApplicationInstance.all
      locals[:local_data][:notifications_read]    = session['notifications_read']
      locals[:local_data][:config_data]           = @config[:portal_configuration]
      erb :index_main, locals: locals
    when 'index_statistics'
      session['notifications_read'] = [] if session['notifications_read'].nil?
      locals[:js] << "js/index_statistics.js"
      locals[:main_body] = :index_statistics
      locals[:local_data][:notifications]      = Mazi::Model::Notification.all
      locals[:local_data][:notifications_read] = session['notifications_read']
      locals[:local_data][:config_data]        = @config[:portal_configuration]
      ex = MaziExecCmd.new('sh', '/root/back-end/', 'mazi-stat.sh', ['-u'], @config[:scripts][:enabled_scripts], @config[:general][:mode])
      lines = ex.exec_command
      users = ex.parseFor('wifi users')
      locals[:local_data][:users]          = {}
      locals[:local_data][:users][:online] = users[2] if users.kind_of? Array
      locals[:local_data][:clicks]         = 0
      Mazi::Model::ApplicationInstance.all.each do |app|
        locals[:local_data][:clicks] += app.click_counter
      end
      ex = MaziExecCmd.new('sh', '/root/back-end/', 'mazi-stat.sh', ['-t'], @config[:scripts][:enabled_scripts], @config[:general][:mode])
      lines = ex.exec_command
      temp = ex.parseFor("'C").first.split('=').last
      locals[:local_data][:temp] = temp
      ex = MaziExecCmd.new('sh', '/root/back-end/', 'mazi-stat.sh', ['-c'], @config[:scripts][:enabled_scripts], @config[:general][:mode])
      cpu = ex.exec_command.first
      locals[:local_data][:cpu] = cpu
      ex = MaziExecCmd.new('sh', '/root/back-end/', 'mazi-stat.sh', ['-r'], @config[:scripts][:enabled_scripts], @config[:general][:mode])
      ram = ex.exec_command.first
      locals[:local_data][:ram] = ram
      ex = MaziExecCmd.new('sh', '/root/back-end/', 'mazi-stat.sh', ['-s'], @config[:scripts][:enabled_scripts], @config[:general][:mode])
      storage = ex.exec_command.first
      locals[:local_data][:storage] = storage
      puts locals
      erb :index_main, locals: locals
    when 'index_sensors'
      MaziLogger.debug "params: #{params.inspect}"
      redirect back unless sensors_enabled?
      session['notifications_read']            = [] if session['notifications_read'].nil?
      locals[:js] << "js/plugins/morris/raphael.min.js"
      locals[:js] << "js/plugins/morris/morris.min.js"
      locals[:js] << "js/jquery.datetimepicker.min.js"
      locals[:js] << "js/index_sensors.js"
      locals[:local_data][:notifications]      = Mazi::Model::Notification.all
      locals[:local_data][:notifications_read] = session['notifications_read']
      locals[:local_data][:config_data]        = @config[:portal_configuration]
      locals[:local_data][:sensors]            = []
      getAllAvailableSensors.each do |sensor|
        tmp                = {}
        tmp[:id]           = sensor[:id]
        tmp[:type]         = sensor[:type]
        tmp[:temperatures] = getTemperatures(sensor[:id], params['start_date'], params['end_date'])
        tmp[:humidity]     = getHumidities(sensor[:id], params['start_date'], params['end_date'])
        next if tmp[:temperatures].empty? || tmp[:humidity].empty?
        locals[:local_data][:sensors] << tmp
      end
      locals[:main_body] = :index_sensors
      erb :index_main, locals: locals
    when 'index_documentation'
      session['notifications_read']            = [] if session['notifications_read'].nil?
      locals[:main_body]                       = :index_documentation
      locals[:local_data][:notifications]      = Mazi::Model::Notification.all
      locals[:local_data][:notifications_read] = session['notifications_read']
      locals[:local_data][:config_data]        = @config[:portal_configuration]
      erb :index_main, locals: locals
    when 'index_camera'
      session['notifications_read']            = [] if session['notifications_read'].nil?
      locals[:main_body]                       = :index_camera
      locals[:local_data][:notifications]      = Mazi::Model::Notification.all
      locals[:local_data][:notifications_read] = session['notifications_read']
      locals[:local_data][:config_data]        = @config[:portal_configuration]
      locals[:local_data][:photos_link]        = @config[:camera][:photos_link]
      locals[:local_data][:nof_photos]         = number_of_photos
      locals[:local_data][:video_link]         = @config[:camera][:video_link]
      locals[:local_data][:nof_videos]         = number_of_videos
      erb :index_main, locals: locals
    when 'setup'
      locals[:main_body] = :setup
      locals[:js] << "js/setup.js"
      locals[:js] << "js/jquery.datetimepicker.min.js"
      erb :setup, locals: locals
    when 'admin'
      redirect 'admin_dashboard'
    when 'admin_dashboard'
      unless authorized?
        MaziLogger.debug "Not authorized"
        session['error'] = nil
        redirect '/admin_login'
      end
      locals[:js] << "js/admin_dashboard.js"
      locals[:main_body] = :admin_dashboard
      ex = MaziExecCmd.new('sh', '/root/back-end/', 'current.sh', ['-s', '-p', '-c', '-m'], @config[:scripts][:enabled_scripts], @config[:general][:mode])
      lines = ex.exec_command
      locals[:local_data][:net_info] = {}
      ssid = ex.parseFor('ssid')
      ssid.shift
      locals[:local_data][:net_info][:ssid] = ssid.join(' ') if ssid.kind_of? Array
      mode = ex.parseFor('mode')
      ex2 = MaziExecCmd.new('sh', '/root/back-end/', 'mazi-stat.sh', ['-u'], @config[:scripts][:enabled_scripts], @config[:general][:mode])
      lines = ex2.exec_command
      users = ex2.parseFor('wifi users')
      locals[:local_data][:users]                 = {}
      locals[:local_data][:users][:online]        = users[2] if users.kind_of? Array
      locals[:local_data][:net_info][:mode]       = mode[1] if mode.kind_of? Array
      locals[:local_data][:applications]          = Mazi::Model::Application.all
      locals[:local_data][:application_instances] = Mazi::Model::ApplicationInstance.all
      locals[:local_data][:notifications]         = Mazi::Model::Notification.all
      locals[:local_data][:sessions]              = Mazi::Model::Session.all
      locals[:local_data][:rasp_date]             = Time.now.strftime("%d %b %Y")
      locals[:local_data][:rasp_time]             = Time.now.strftime("%H:%M")
      locals[:local_data][:version]               = getVersion
      locals[:local_data][:version_difference]    = version_difference
      erb :admin_main, locals: locals
    when 'admin_application'
      unless authorized?
        MaziLogger.debug "Not authorized"
        session['error'] = nil
        redirect '/admin_login'
      end
      locals[:js] << "js/admin_application.js"
      locals[:main_body] = :admin_application
      locals[:local_data][:applications]  = Mazi::Model::Application.all
      locals[:local_data][:application_instances]  = Mazi::Model::ApplicationInstance.all
      erb :admin_main, locals: locals
    when 'admin_documentation'
      unless authorized?
        MaziLogger.debug "Not authorized"
        session['error'] = nil
        redirect '/admin_login'
      end
      locals[:main_body] = :admin_documentation
      erb :admin_main, locals: locals
    when 'admin_network'
      unless authorized?
        MaziLogger.debug "Not authorized"
        session['error'] = nil
        redirect '/admin_login'
      end
      locals[:js] << "js/admin_network.js"
      locals[:main_body] = :admin_network
      ex = MaziExecCmd.new('sh', '/root/back-end/', 'current.sh', ['-s', '-p', '-c', '-m'], @config[:scripts][:enabled_scripts])
      lines = ex.exec_command
      locals[:local_data][:net_info] = {}
      ssid = ex.parseFor('ssid')
      ssid.shift
      locals[:local_data][:net_info][:ssid] = ssid.join(' ') if ssid.kind_of? Array
      channel = ex.parseFor('channel')
      locals[:local_data][:net_info][:channel] = channel[1] if channel.kind_of? Array
      password = ex.parseFor('password')
      locals[:local_data][:net_info][:password] = password[1] if password.kind_of? Array
      mode = ex.parseFor('mode')
      locals[:local_data][:net_info][:mode] = mode[1] if mode.kind_of? Array
      ex2 = MaziExecCmd.new('sh', '/root/back-end/', 'antenna.sh', ['-a'], @config[:scripts][:enabled_scripts])
      locals[:local_data][:net_info][:second_antenna] = ex2.exec_command.last
      ex3 = MaziExecCmd.new('sh', '/root/back-end/', 'antenna.sh', ['-l'], @config[:scripts][:enabled_scripts])
      locals[:local_data][:net_info][:available_ssids] = ex3.exec_command
      locals[:local_data][:net_info][:available_ssids].map! {|ssid| ssid.gsub('ESSID:', '').gsub('"', '')}
      locals[:local_data][:net_info][:available_ssids].reject! {|ssid| ssid.empty?}
      erb :admin_main, locals: locals
    when 'admin_configuration'
      unless authorized?
        MaziLogger.debug "Not authorized"
        session['error'] = nil
        redirect '/admin_login'
      end
      locals[:js] << "js/admin_network.js"
      locals[:js] << "js/jscolor.min.js"
      locals[:main_body] = :admin_configuration
      locals[:local_data][:portal_configuration] = @config[:portal_configuration]
      locals[:local_data][:config_files] = getAllConfigSaves
      erb :admin_main, locals: locals
    when 'admin_notification'
      unless authorized?
        MaziLogger.debug "Not authorized"
        session['error'] = nil
        redirect '/admin_login'
      end
      locals[:js] << "js/admin_notification.js"
      locals[:main_body] = :admin_notification
      locals[:local_data][:notifications] = Mazi::Model::Notification.all
      erb :admin_main, locals: locals
    when 'admin_snapshot'
      unless authorized?
        MaziLogger.debug "Not authorized"
        session['error'] = nil
        redirect '/admin_login'
      end
      locals[:js] << "js/admin_snapshot.js"
      locals[:main_body] = :admin_snapshot
      locals[:local_data][:dbs] = getAllDBSnapshots
      erb :admin_main, locals: locals
    when 'admin_devices'
      unless authorized?
        MaziLogger.debug "Not authorized"
        session['error'] = nil
        redirect '/admin_login'
      end
      locals[:js] << "js/admin_devices.js"
      locals[:main_body] = :admin_devices
      locals[:local_data][:sensors_enabled]   = @config[:sensors][:enable]
      locals[:local_data][:sensors_db_exist]  = sensors_db_exist?
      locals[:local_data][:available_sensors] = getAllAvailableSensors
      locals[:local_data][:camera_enabled]    = false
      locals[:local_data][:photos_link]       = @config[:camera][:photos_link]
      locals[:local_data][:nof_photos]        = number_of_photos
      locals[:local_data][:video_link]        = @config[:camera][:video_link]
      locals[:local_data][:nof_videos]        = number_of_videos
      erb :admin_main, locals: locals
    when 'admin_set_date'
      locals[:main_body] = :admin_set_time
      locals[:local_data][:first_login] = false
      locals[:js] << "js/jquery.datetimepicker.min.js"
      locals[:js] << "js/admin_set_date.js"
      locals[:main_body] = :admin_set_date
      erb :admin_main, locals: locals
    when 'admin_change_password'
      unless authorized?
        MaziLogger.debug "Not authorized"
        session['error'] = nil
        redirect '/admin_login'
      end
      locals[:main_body] = :admin_change_password
      erb :admin_main, locals: locals
     when 'admin_change_username'
      unless authorized?
        MaziLogger.debug "Not authorized"
        session['error'] = nil
        redirect '/admin_login'
      end
      locals[:main_body] = :admin_change_username
      erb :admin_main, locals: locals
    when 'admin_login'
      if @config[:general][:mode] == 'demo'
        MaziLogger.debug "Demo mode download snapshot"
        session['error'] = "This portal runs on Demo mode!"
        redirect back
      end
      locals[:main_body] = :admin_login
      erb :admin_main, locals: locals
    when 'admin_logout'
      if @config[:general][:mode] == 'demo'
        MaziLogger.debug "Demo mode download snapshot"
        session['error'] = "This portal runs on Demo mode! This action would have logged you out."
        redirect back
      end
      session[:username] = nil
      redirect '/admin_login'
    when 'update'
      return {error: 'No active internet connection.', code: -2}.to_json        if no_internet?
      return {error: 'Staged code exist in the repository.', code: -1}.to_json  if staged?
      return {error: 'Demo mode.', code: -3}.to_json                            if @config[:general][:mode] == 'demo'
      return {current_version: getVersion, commits_behind: version_difference}.to_json
    else
      MaziLogger.warn "#{index} is not supported." unless index == 'favicon.ico'
      redirect back unless index == 'favicon.ico'
    end
  end

  get '/snapshots/mazi-snapshot.zip' do
    if @config[:general][:mode] == 'demo'
      MaziLogger.debug "Demo mode download snapshot"
      session['error'] = "This portal runs on Demo mode! This action would have downloaded a snapshot."
      redirect back
    end
    send_file File.join('public/snapshots/', 'mazi-snapshot.zip')
  end

  # admin login post request
  post '/admin_login/?' do
    MaziLogger.debug "request: post/admin_login from ip: #{request.ip} creds: #{params.inspect}"
    unless valid_admin_credentials?(params['username'], params['password'])
      session['error'] = 'Password and username missmatch!'
      redirect '/admin_login' 
    end
    MaziLogger.debug "valid credential"
    session[:username] = params['username']
    redirect '/admin'
  end

  # admin login post request
  delete '/admin_login/?' do
    MaziLogger.debug "request: delete/admin_login from ip: #{request.ip} creds: #{params.inspect}"
    if @config[:general][:mode] == 'demo'
      MaziLogger.debug "Demo mode download snapshot"
      session['error'] = "This portal runs on Demo mode! This action would have logged you out."
      redirect back
    end
    session[:username] = nil
    redirect '/admin'
  end

  # admin login post request
  post '/set_date/?' do
    MaziLogger.debug "request: post/set_date from ip: #{request.ip} params: #{params.inspect}"
    if @config[:general][:mode] == 'demo'
      MaziLogger.debug "Demo mode set app"
      session['error'] = "This portal runs on Demo mode! This action would have changed the time/date of the mazizone."
      redirect back
    end
    ex = MaziExecCmd.new('', '', 'date', ['-s', "'#{params['date']}'"], @config[:scripts][:enabled_scripts])
    lines = ex.exec_command
    redirect '/admin'
  end

  # admin create application
  post '/application/?' do
    MaziLogger.debug "request: post/application from ip: #{request.ip} creds: #{params.inspect}"
    unless authorized?
      MaziLogger.debug "Not authorized"
      session['error'] = nil
      redirect '/admin_login'
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
  post '/application/edit/?' do
    MaziLogger.debug "request: put/application from ip: #{request.ip} params: #{params.inspect}"
    unless authorized?
      MaziLogger.debug "Not authorized"
      session['error'] = nil
      redirect '/admin_login'
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
  delete '/application/:id/?' do |id| 
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
  delete '/application/:id/instance/?' do |id| 
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
  put '/application/:id/?' do |id|
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
  put '/application/:id/instance/?' do |id|
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

  # application status/start/stop
  put '/application/:id/action/:action/?' do |id, action|
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
  put '/application/:id/click_counter/?' do |id|
    MaziLogger.debug "request: put/application from ip: #{request.ip} id: #{id}"
    app = Mazi::Model::ApplicationInstance.find(id: id)
    app.application.click_counter += 1 
    app.click_counter = app.click_counter + 1
    app.save
    {result: 'OK', id: id}.to_json
  end

  # application counter reset
  delete '/application/:id/click_counter/?' do |id|
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

  # admin create notification
  post '/notification/?' do
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
  post '/notification/edit/?' do
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
  delete '/notification/:id/?' do |id| 
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
  put '/notification/:id/?' do |id|
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
  put '/notification/:id/read/?' do |id|
    MaziLogger.debug "request: put/notification from ip: #{request.ip} id: #{id}"
    session[:notifications_read] << id.to_i
    {result: 'OK', id: id}.to_json
  end

  # executing a script
  post '/exec/?' do
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
        args << "-s #{params['ssid']}"
      else
        unless params['hidden-ssid'].nil? || params['hidden-ssid'].empty?
          args << "-s #{params['hidden-ssid']} -h"
        end
      end
      args << "-p #{params['password']}" unless params['password'].nil? || params['password'].empty?
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

  # saving configurations
  post '/conf/?' do
    MaziLogger.debug "request: post/conf from ip: #{request.ip} params: #{params.inspect}"
    unless authorized?
      MaziLogger.debug "Not authorized"
      session['error'] = nil
      redirect '/admin_login'
    end
    if params['reset']
      if @config[:general][:mode] == 'demo'
        MaziLogger.debug "Demo mode saving configuration"
        session['error'] = "This portal runs on Demo mode! This action would have reset the theme."
        redirect '/admin_configuration'
      end
      changePortalConfigToDefault
      writeConfigFile
      redirect '/admin_configuration'
    elsif params['save']
      if @config[:general][:mode] == 'demo'
        MaziLogger.debug "Demo mode saving configuration"
        session['error'] = "This portal runs on Demo mode! This action would have saved a theme."
        redirect '/admin_configuration'
      end
      saveTheme(params[:filename])
      redirect '/admin_configuration'
    elsif params['load']
      if @config[:general][:mode] == 'demo'
        MaziLogger.debug "Demo mode saving configuration"
        session['error'] = "This portal runs on Demo mode! This action would have loaded a theme."
        redirect '/admin_configuration'
      end
      loadTheme(params[:filename])
      redirect '/admin_configuration'
    end
    if @config[:general][:mode] == 'demo'
      MaziLogger.debug "Demo mode saving configuration"
      session['error'] = "This portal runs on Demo mode! This action would have made a theme change."
      redirect '/admin_configuration'
    end
    data = {}
    data[:title]                     = params['title'] unless params['title'].nil? || params['title'].empty?
    data[:applications_title]        = params['applications_title'] unless params['applications_title'].nil?  || params['applications_title'].empty?
    data[:applications_subtitle]     = params['applications_subtitle'] unless params['applications_subtitle'].nil?  || params['applications_subtitle'].empty?
    data[:applications_welcome_text] = params['applications_welcome_text'] unless params['applications_welcome_text'].nil?  || params['applications_welcome_text'].empty?
    data[:side_panel_color]          = params['side_panel_color'] unless params['side_panel_color'].nil?  || params['side_panel_color'].empty?
    data[:side_panel_active_color]   = params['side_panel_active_color'] unless params['side_panel_active_color'].nil?  || params['side_panel_active_color'].empty?
    data[:top_panel_color]           = params['top_panel_color'] unless params['top_panel_color'].nil?  || params['top_panel_color'].empty?
    data[:top_panel_active_color]    = params['top_panel_active_color'] unless params['top_panel_active_color'].nil?  || params['top_panel_active_color'].empty?
    unless params['applications_background_image'].nil? || params['applications_background_image'].empty?
      tempfile = params['applications_background_image'][:tempfile]
      filename = params['applications_background_image'][:filename]
      data[:applications_background_image] = filename
      FileUtils.cp tempfile.path, "public/images/#{filename}"
    end
    data.each do |key, value|
      changeConfigFile("portal_configuration->#{key}", value)
    end
    writeConfigFile
    redirect '/admin_configuration'
  end

  # saving configurations without a refresh
  put '/conf/?' do
    request.body.rewind
    body = JSON.parse(request.body.read)
    MaziLogger.debug "request: put/conf from ip: #{request.ip} body: #{body}"
    if !authorized?
      MaziLogger.debug "Not authorized"
      session['error'] = nil
      {error: 'Not Authorized!'}.to_json
    elsif  @config[:general][:mode] == 'demo'
      MaziLogger.debug "Demo mode save configuration"
      session['error'] = nil
      {error: "This portal runs on Demo mode! This action would have made a theme change."}.to_json
    else
      data = {}
      data[:title]                     = body['title'] unless body['title'].nil? || body['title'].empty?
      data[:applications_title]        = body['applications_title'] unless body['applications_title'].nil?  || body['applications_title'].empty?
      data[:applications_subtitle]     = body['applications_subtitle'] unless body['applications_subtitle'].nil?  || body['applications_subtitle'].empty?
      data[:applications_welcome_text] = body['applications_welcome_text'] unless body['applications_welcome_text'].nil?  || body['applications_welcome_text'].empty?
      data[:side_panel_color]          = body['side_panel_color'] unless body['side_panel_color'].nil?  || body['side_panel_color'].empty?
      data[:side_panel_active_color]   = body['side_panel_active_color'] unless body['side_panel_active_color'].nil?  || body['side_panel_active_color'].empty?
      data[:top_panel_color]           = body['top_panel_color'] unless body['top_panel_color'].nil?  || body['top_panel_color'].empty?
      data[:top_panel_active_color]    = body['top_panel_active_color'] unless body['top_panel_active_color'].nil?  || body['top_panel_active_color'].empty?
      data.each do |key, value|
        changeConfigFile("portal_configuration->#{key}", value)
      end
      writeConfigFile
      {result: 'OK'}.to_json
    end
  end

  # session counter reset
  delete '/session/:id/?' do |id|
    MaziLogger.debug "request: delete/session from ip: #{request.ip} creds: #{params.inspect}"
    unless authorized?
      MaziLogger.debug "Not authorized"
      session['error'] = nil
      return {error: 'Not Authorized!', id: id}.to_json
    end
    if @config[:general][:mode] == 'demo'
      MaziLogger.debug "Demo mode delete session"
      session['error'] = "This portal runs on Demo mode! This action would have reseted portal visits."
      redirect '/admin_snapshot'
    end

    if id == 'all'
      Mazi::Model::Session.all.each do |ses|
        ses.destroy
      end
    else
      ses = Mazi::Model::Session.find(id: id)
      ses.destroy
    end
    {result: 'OK', id: id}.to_json
  end

   # taking/loading snapshots
  post '/snapshot/?' do
    MaziLogger.debug "request: post/snapshot from ip: #{request.ip} params: #{params.inspect}"
    unless authorized?
      MaziLogger.debug "Not authorized"
      session['error'] = nil
      redirect '/admin_login'
    end
    if params['save']
      if @config[:general][:mode] == 'demo'
        MaziLogger.debug "Demo mode save snapshot"
        session['error'] = "This portal runs on Demo mode! This action would have saved a snapshot."
        redirect '/admin_snapshot'
      end
      takeDBSnapshot(params[:snapshotname])
      redirect '/admin_snapshot'
    elsif params['load']
      if @config[:general][:mode] == 'demo'
        MaziLogger.debug "Demo mode load snapshot"
        session['error'] = "This portal runs on Demo mode! This action would have loaded a snapshot."
        redirect '/admin_snapshot'
      end
      loadDBSnapshot(params[:snapshotname])
      loadTheme("#{params[:snapshotname]}.yml")
      redirect '/admin_snapshot'
    elsif params['download']
      if @config[:general][:mode] == 'demo'
        MaziLogger.debug "Demo mode download snapshot"
        session['error'] = "This portal runs on Demo mode! This action would have downloaded a snapshot."
        redirect '/admin_snapshot'
      end
      zip_snapshot(params[:snapshotname])
      return {result: 'OK', file: "#{params[:snapshotname]}.zip"}
    elsif params['upload']
      if @config[:general][:mode] == 'demo'
        MaziLogger.debug "Demo mode upload snapshot"
        session['error'] = "This portal runs on Demo mode! This action would have uploaded a snapshot."
        redirect '/admin_snapshot'
      end
      tempfile = params['snapshot'][:tempfile]
      filename = params['snapshot'][:filename]
      unzip_snapshot(filename, tempfile)
      loadTheme(filename.gsub('.zip', '.yml'))
      redirect '/admin_snapshot'
    elsif params['export_app']
      if @config[:general][:mode] == 'demo'
        MaziLogger.debug "Demo mode upload snapshot"
        session['error'] = "This portal runs on Demo mode! This action would have imported an application snapshot."
        redirect '/admin_snapshot'
      end
      zip_app_snapshot(params[:application], params['snapshotname'])
      return {result: 'OK', file: "#{params[:snapshotname]}_#{params[:application]}.zip"}
    elsif params['import_app']
      if @config[:general][:mode] == 'demo'
        MaziLogger.debug "Demo mode upload snapshot"
        session['error'] = "This portal runs on Demo mode! This action would have exported an application snapshot."
        redirect '/admin_snapshot'
      end
      tempfile = params['snapshot'][:tempfile]
      filename = params['snapshot'][:filename]
      unzip_app_snapshot(params[:application], filename, tempfile)
      redirect '/admin_snapshot'
    end

    redirect '/admin_snapshot'
  end

  delete '/snapshot/?' do 
    MaziLogger.debug "request: delete/snapshot from ip: #{request.ip} params: #{params.inspect}"
    deleteDBSnapshot(params['snapshotname'])
    {result: "OK"}.to_json
  end

  post '/admin_change_username' do
    MaziLogger.debug "request: post/snapshot from ip: #{request.ip} params: #{params.inspect}"
    if @config[:general][:mode] == 'demo'
      MaziLogger.debug "Demo mode change username"
      session['error'] = "This portal runs on Demo mode! This action would have changed the admin username."
      redirect '/admin_change_username'
    end
    unless params['old-username'] == @config[:admin][:admin_username]
      MaziLogger.debug "Incorrect old username"
      session['error'] = "Incorrect old username"
      redirect '/admin_change_username'
    end
    unless valid_admin_credentials?(params['old-username'], params['password'])
      MaziLogger.debug "Password confirmation missmatch"
      session['error'] = "Password confirmation missmatch"
      redirect '/admin_change_username'
    end
    changeConfigFile("admin->admin_username", params['new-username'])
    writeConfigFile
    session['error'] = nil
    session[:username] = nil
    redirect '/admin_login'
  end

  post '/admin_change_password' do
    MaziLogger.debug "request: post/snapshot from ip: #{request.ip} params: #{params.inspect}"
    if params['password'] == '1234'
      session['error'] = "Password 1234 cannot be used! Please try again."
      redirect '/admin_change_password'
    end
    if @config[:general][:mode] == 'demo'
      MaziLogger.debug "Demo mode change password"
      session['error'] = "This portal runs on Demo mode! This action would have changed the admin password."
      redirect '/admin_change_password'
    end
    unless valid_password?(params['old-password'])
      MaziLogger.debug "Incorrect old password"
      session['error'] = "Incorrect old password"
      redirect '/admin_change_password'
    end
    unless params['new-password'] == params['new-password-confirm']
      MaziLogger.debug "Password confirmation missmatch"
      session['error'] = "Password confirmation missmatch"
      redirect '/admin_change_password'
    end
    changeConfigFile("admin->admin_password", params['new-password'])
    writeConfigFile
    session['error'] = nil
    session[:username] = nil
    redirect '/admin_login'
  end

  post '/setup' do
    MaziLogger.debug "request: post/setup from ip: #{request.ip} creds: #{params.inspect}"
    if @config[:general][:mode] == 'demo'
      MaziLogger.debug "Demo mode exec script"
      session['error'] = "This portal runs on Demo mode! This action would have initiated the setup mechanism."
      redirect '/admin'
    end
    if params['password'].nil? || params['password'].empty?
      session['error'] = "Field Password is mandatory! Please try again."
      redirect '/setup'
    end
    if params['confirm-password'].nil? || params['confirm-password'].empty?
      session['error'] = "Field Confirm Password is mandatory! Please try again."
      redirect '/setup'
    end
    if params['confirm-password'] != params['password']
      session['error'] = "Password and confirm Password fields missmatch! Please try again."
      redirect '/setup'
    end
    if params['password'] == '1234'
      session['error'] = "Password 1234 cannot be used! Please try again."
      redirect '/setup'
    end
    if params['date'].nil? || params['date'].empty?
      session['error'] = "Field Date is mandatory! Please try again."
      redirect '/setup'
    end

    changeConfigFile("admin->admin_password", params['password'])
    writeConfigFile

    ex = MaziExecCmd.new('', '', 'date', ['-s', "'#{params['date']}'"], @config[:scripts][:enabled_scripts])
    lines = ex.exec_command

    unless params['ssid'].nil? || params['ssid'].empty?
      env = 'sh'
      path = @config[:scripts][:backend_scripts_folder]
      cmd = "wifiap.sh"
      args = []
      args << "-s '#{params['ssid']}'" if params['ssid']

      ex1 = MaziExecCmd.new(env, path, cmd, args, @config[:scripts][:enabled_scripts])
      lines = ex1.exec_command
    end

    session['error'] = nil
    session[:username] = nil
    redirect '/admin_login'
  end

  put '/update/?' do
    MaziLogger.debug "request: put/update from ip: #{request.ip} params: #{params.inspect}"

    version_update
    update_config_file

    Thread.new do
      sleep 2
      MaziLogger.debug 'Restarting'
      `service mazi-portal restart`
    end

    {status: "restarting"}.to_json
  end

  post '/action/:action/?' do |action|
    MaziLogger.debug "request: put/action from ip: #{request.ip} action: #{action}"
    unless authorized?
      MaziLogger.debug "Not authorized"
      session['error'] = nil
      return {error: 'Not Authorized!', action: action}.to_json
    end
    if @config[:general][:mode] == 'demo'
      MaziLogger.debug "Demo mode exec script"
      session['error'] = "This portal runs on Demo mode! This action would have #{action == 'shutdown' ? 'shutted down' : 'restarted'} this Mazizone."
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
   
  post '/sensors/register/?' do
    request.body.rewind
    body = JSON.parse(request.body.read)
    MaziLogger.debug "Register sensor: #{body["name"]} from ip: #{body["ip"]}" 
    
    begin
    #connect to DATABASE mydb
    con = Mysql.new('localhost', 'mazi_user', '1234', 'sensors')
     
    con.query("INSERT INTO type(name, ip) VALUES('#{body["name"]}', '#{body["ip"]}')")
    id = con.query("SELECT max(id) FROM type")
    return id.fetch_row       

    rescue Mysql::Error => e
      MaziLogger.error e.message 
    ensure
      con.close if con
    end
  end

  get '/sensors/id/?' do
    request.body.rewind
    body = JSON.parse(request.body.read)
    MaziLogger.debug "Search ID for sensor: #{body["name"]} with ip: #{body["ip"]}"  
    begin
    #connect to DATABASE mydb
    con = Mysql.new('localhost', 'mazi_user', '1234', 'sensors')
    id = con.query("SELECT id FROM type WHERE name LIKE '#{body["name"]}' AND ip='#{body["ip"]}'")
    
    if( id != nil )
       return id.fetch_row
    end
    rescue Mysql::Error => e
      MaziLogger.error e.message
    ensure
      con.close if con
    end
  end

  post '/sensors/store/?' do
    request.body.rewind
    body = JSON.parse(request.body.read)
    date = DateTime.strptime("#{body["date"]}", '%H%M%S%d%m%y')   
    MaziLogger.debug "request: post/sensors [#{date.hour}:#{date.minute}:#{date.second}], from sensor_id: #{body["sensor_id"]}"
    begin  
    #connect to DATABASE mydb
    con = Mysql.new('localhost', 'mazi_user', '1234', 'sensors')

    #Find the name of the sensor
    name = con.query("SELECT name FROM type WHERE id=#{body["sensor_id"]}").fetch_row.first

    case name
    when "sht11"
       #create TABLE "sensor_SensorId" ==> | ID | TIME | TEMPERATURE | HUMIDITY |
       con.query("CREATE TABLE IF NOT EXISTS sensor_#{body["sensor_id"]}(id INT PRIMARY KEY AUTO_INCREMENT, time DATETIME, temperature VARCHAR(4), humidity VARCHAR(4))")       
       con.query("INSERT INTO sensor_#{body["sensor_id"]}(time, temperature, humidity) VALUES('#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}', '#{body["value"]["temp"]}', '#{body["value"]["hum"]}')")
    when "sensehat"
       #create TABLE "sensor_SensorId" ==> | ID | TIME | TEMPERATURE | HUMIDITY |
       con.query("CREATE TABLE IF NOT EXISTS sensor_#{body["sensor_id"]}(id INT PRIMARY KEY AUTO_INCREMENT, time DATETIME, temperature VARCHAR(4), humidity VARCHAR(4))")       
       con.query("INSERT INTO sensor_#{body["sensor_id"]}(time, temperature, humidity) VALUES('#{date.year}-#{date.month}-#{date.day} #{date.hour}:#{date.minute}:#{date.second}', '#{body["value"]["temp"]}', '#{body["value"]["hum"]}')")
    end	

    rescue Mysql::Error => e
      MaziLogger.error e.message
    ensure
      con.close if con
    end
  end

  post '/devices/:device/:action' do |device, action|
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
    when 'sht11', 'sensehat'
      if action == 'start'
        start_sensing(device, params['duration'], params['interval'])
        redirect back
      elsif action == 'delete'
        delete_measurements(params['id'])
        redirect back
      end
    end
    {result: 'OK', device: device, action: action}.to_json
  end
end

Thin::Server.start MaziApp, '0.0.0.0', 4567
