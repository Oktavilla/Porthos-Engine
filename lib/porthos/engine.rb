module Porthos
  class Engine < Rails::Engine
    config.autoload_paths += Dir[Porthos.root.join('app', 'models', '{**}')]
    config.i18n.default_locale = "sv-SE"
    config.i18n.fallbacks = true
    config.use_fulltext_search = false

    config.active_record.identity_map = true

    initializer "porthos.redirects" do |app|
      app.middleware.use Porthos::Redirects
    end

    initializer 'porthos.helpers' do |app|
      ActiveSupport.on_load :action_view do
        include Porthos::ApplicationHelper
      end
    end

    initializer 'porthos.active_record' do |app|
      ActiveSupport.on_load :active_record do
        include Porthos::ActiveRecord::Restrictions
        include Porthos::ActiveRecord::Settingable
      end
    end

    initializer 'porthos.tanking' do |app|
      app.config.to_prepare do
        Porthos::Tanking::Indexes.setup
      end
    end

    initializer 'porthos.authentication' do |app|
      app.middleware.use ::Warden::Manager do |manager|
        manager.default_strategies :password
        manager.failure_app = Porthos::Authentication::UnauthorizedRequest
      end
      ActiveSupport.on_load :action_controller do
        include Porthos::Authentication::Helpers
      end
    end
  end
end