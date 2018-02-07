module Sinatra
  module MaziApp
    module Routing
      module MaziLocales

        def self.registered(app)
          # set locale
          app.post '/locales/:locale/?' do |locale|
            session['locale'] = locale.to_sym
            set_locale(locale.to_sym)
          end
        end

      end
    end
  end
end
