ActionController::Routing::Routes.draw do |map|
  # Sample resource route with options:
  # map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  # map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.

  map.with_options :controller => 'assets', :action => 'show' do |asset|
    asset.resized_image  '/images/:size/:id.:format'
    asset.display_video  '/videos/:id.:format'
    asset.download_asset '/assets/:id.:format'
  end

  map.resources :pages,
                :collection => { :search => :get },
                :member => {
                  :preview => :get,
                  :comment => :post
                }
  
  map.login  '/login',  :controller => 'user/sessions', :action => 'new'
  map.logout '/logout', :controller => 'user/sessions', :action => 'destroy'
  map.forgot_password '/forgot_password', :controller => 'user/sessions', :action => 'forgot_password'
  map.send_password '/send_password', :controller => 'user/sessions', :action => 'send_new_password'
  
  map.new_user  '/skapa-konto',  :controller => 'user/users', :action => 'new'
  map.namespace(:user) do |user|
    user.resources :sessions, :collection => { :token => :get, :send_new_password => :get, :forgot_password => :get }
  end
  
  map.namespace(:admin) do |admin|
    admin.login  '/login',  :controller => 'admin/sessions', :action => 'new'
    admin.logout '/logout', :controller => 'admin/sessions', :action => 'destroy'
    admin.resources :sessions, :collection => { :token => :get }
    admin.dashboard '/', :controller => 'pages'

    admin.resources :users, :collection => { :admins => :get, :public => :get, :new_public => :get, :search => :get }

    admin.resources :nodes, 
      :member => { :place => :get },
      :collection => { :sort => :put }

    admin.resources :field_sets, :collection => { :sort => :put }, :member => { :pages => :get } do |field_sets|
      field_sets.resources :fields, :collection => { :sort => :put }
    end

    admin.resources(:contents, {
      :collection => {
        :sort => :put
      },
      :member => {
        :toggle   => :put,
        :settings => :get
      }
    })
    admin.resources :content_modules
    admin.resources :content_lists

    admin.resources :assets, :collection => { :search => :get, :incomplete => :get, :update_multiple => :put }
    admin.resources :asset_usages,
                    :collection => { :sort => :put }
    admin.resources :tags,
                    :collection => { :search => :get }
        
    admin.resources :comments,
                    :member => {
                      :report_as_spam => :put,
                      :report_as_ham => :put
                    },
                    :collection => {
                      :destroy_all_spam => :delete
                    }
    
    admin.resources(:pages, {
      :collection => {
        :search => :get,
        :sort => :put
      },
      :member => {
        :toggle   => :put,
        :comments => :get
      }
    }) do |pages|
      pages.resources :custom_attributes
      pages.resources :custom_associations
    end
    admin.resources :custom_associations, {
      :collection => { :sort => :put }
    }
    admin.resources :redirects
    admin.resources :site_settings
  end
end