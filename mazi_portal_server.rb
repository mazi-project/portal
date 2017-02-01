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
    case index
    when 'index'
      locals = {}
      locals[:local_data] = {}
      locals[:main_body] = :index_application
      erb :index_main, locals: locals
    when 'admin'
      unless authorized?
        MaziLogger.debug "Not authorized"
        main_body = :admin_login
        session['error'] = 'username and password missmatch!'
        redirect '/admin_login'
      end
      MaziLogger.debug "Authorized"
      locals = {}
      locals[:local_data] = {}
      locals[:main_body] = :admin_application
      locals[:local_data][:applications]  = Mazi::Model::Application.all
      erb :admin_main, locals: locals
    when 'admin_application'
      unless authorized?
        main_body = :admin_login
        session['error'] = 'username and password missmatch!'
        redirect '/admin_login'
      end
      locals = {}
      locals[:local_data] = {}
      locals[:main_body] = :admin_application
      erb :admin_main, locals: locals
    when 'admin_login'
      locals = {}
      locals[:local_data] = {}
      locals[:main_body] = :admin_login
      unless session['error'].nil?
        locals[:error]  = session["error"]
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
    redirect '/admin_login' unless valid_admin_credentials?(params['username'], params['password'])
    MaziLogger.debug "valid credential"
    session[:username] = params['username']
    redirect '/admin'
  end

  # admin login post request
  delete '/admin_login' do
    session[:username] = nil
    redirect '/admin'
  end
end

Thin::Server.start MaziApp, '0.0.0.0', 4567
