module Mazi
  module Model; end
end

Sequel.default_timezone = :utc
Dir['./lib/models/*.rb'].each{|f| require f}
