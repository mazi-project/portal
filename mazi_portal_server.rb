require 'sinatra/base'
require 'helpers/mazi_logger'
require 'helpers/authorizer'
require 'yaml'
require 'thin'
require 'json'
require 'sequel'

class MaziApp < Sinatra::Base
  include Authorizer

  use Rack::Session::Pool, :expire_after => 60 * 60 * 24

  def initialize
    super
    @config = YAML::load(File.open('etc/config.yml'))
    Sequel.connect('sqlite://database/inventory.db')
    require 'models'
  end

  # this is the main routing configuration that routes all the erb files
  get '/:index' do |index|
    MaziLogger.debug "request: get/#{index} from ip: #{request.ip}"
    locals = {}
    locals[:local_data] = {}
    locals[:js] = []
    locals[:error_msg] = nil
    case index
    when 'index'
      locals[:js] << "js/index_application.js"
      locals[:main_body] = :index_application
      locals[:local_data][:applications] = Mazi::Model::Application.all
      erb :index_main, locals: locals
    when 'admin'
      redirect 'admin_application'
    when 'admin_application'
      unless authorized?
        MaziLogger.debug "Not authorized"
        session['error'] = nil
        redirect '/admin_login'
      end
      locals[:js] << "js/admin_application.js"
      locals[:main_body] = :admin_application
      locals[:local_data][:applications]  = Mazi::Model::Application.all
      unless session['error'].nil?
        locals[:error_msg]  = session["error"]
        session[:error] = nil
      end
      erb :admin_main, locals: locals
    when 'admin_login'
      locals[:main_body] = :admin_login
      unless session['error'].nil?
        locals[:error_msg]  = session["error"]
        session[:error] = nil
      end
      erb :admin_main, locals: locals
    else
      MaziLogger.warn "#{index} is not supported." unless index == 'favicon.ico'
    end
  end 

  # admin login post request
  post '/admin_login' do
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
  delete '/admin_login' do
    session[:username] = nil
    redirect '/admin'
  end

  # admin create application
  post '/application' do
    MaziLogger.debug "request: post/application from ip: #{request.ip} creds: #{params.inspect}"
    unless authorized?
      MaziLogger.debug "Not authorized"
      session['error'] = nil
      redirect '/admin_login'
    end
    e = Mazi::Model::Application.validate(params)
    unless e.nil?
      MaziLogger.debug "invalid param #{e}"
      session['error'] = e
      redirect '/admin_application'
    end

    a =  Mazi::Model::Application.create(params)
    redirect '/admin_application'
  end

  # admin edit application
  post '/application/edit' do
    MaziLogger.debug "request: put/application from ip: #{request.ip} params: #{params.inspect}"
    unless authorized?
      MaziLogger.debug "Not authorized"
      session['error'] = nil
      redirect '/admin_login'
    end
    e = Mazi::Model::Application.validate_edit(params)
    unless e.nil?
      MaziLogger.debug "invalid param #{e}"
      session['error'] = e
      redirect '/admin_application'
    end
    id = params['id']
    app =  Mazi::Model::Application.find(id: params['id'].to_i)
    app.name = params['name']
    app.url = params['url']
    app.description = params['description']
    app.save
    redirect '/admin_application'
  end

  # admin delete application
  delete '/application/:id' do |id| 
    MaziLogger.debug "request: delete/application from ip: #{request.ip} id: #{id}"
    if !authorized?
      MaziLogger.debug "Not authorized"
      session['error'] = nil
      {error: 'Unauthorized', id: id}.to_json
    else
      app = Mazi::Model::Application.first(id)
      app.destroy
      {result: 'OK', id: id}.to_json
    end
  end
end

Thin::Server.start MaziApp, '0.0.0.0', 4567
