require "porthos"
require "rails"

module Porthos
  class Engine < Rails::Engine
    config.autoload_paths += Dir[Porthos.root.join('app', 'models', '{**}')]
    config.i18n.default_locale = "sv-SE"
    config.i18n.fallbacks = true

    config.use_fulltext_search = false

    initializer "static assets" do |app|
      if app.config.serve_static_assets
        app.middleware.insert_after ::ActionDispatch::Static, ::ActionDispatch::Static, "#{root}/public"
      end
    end

    initializer "redirects" do |app|
      app.middleware.use Porthos::Redirects
    end

    initializer 'helpers' do |app|
      ActionView::Base.send :include, PorthosApplicationHelper
    end

    initializer 'authentication' do |app|
      app.middleware.use Warden::Manager do |manager|
        manager.default_strategies :password
        manager.failure_app = Porthos::Authentication::UnauthorizedRequest
      end

      class ::ActionController::Base
        include Porthos::Authentication::Helpers
      end
    end
  end
end
