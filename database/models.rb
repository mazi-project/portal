module Mazi
  module Model; end
end

Sequel.default_timezone = :utc
Dir['./database/models/*.rb'].each{|f| require f}
