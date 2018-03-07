require 'sinatra/base'
require 'helpers/mazi_logger'
require 'json'
require 'fileutils'
require 'mysql'
require 'thin'
require 'date'
require 'routes/mazi_rest'

class MaziRestApp < Sinatra::Base
  configure {set :show_exceptions, false}
  configure {set :dump_errors, false}

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

  register Sinatra::MaziApp::Routing::MaziRest
end

Thin::Server.start MaziRestApp, '0.0.0.0', 7654
