module MaziLocales
  def init_locales
    I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
    I18n.load_path = Dir[File.join(settings.root, 'locales', '*.yml')]
    I18n.backend.load_translations
    I18n.available_locales = [:en, :el]
    set_locale(:en)
  end

  def set_locale(locale)
    I18n.locale = locale
  end

  def get_locale
    I18n.locale || I18n.default_locale
  end
end