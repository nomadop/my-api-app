require 'sidekiq/web'

Rails.application.routes.draw do

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'admin_sessions#new'
  mount Sidekiq::Web => '/sidekiq'

  resource :authentication
  resources :admin_sessions
  get 'login' => 'admin_sessions#new', :as => :login
  post 'logout' => 'admin_sessions#destroy', :as => :logout
  get '/accounts', to: 'accounts#list'
  get '/inventory', to: 'inventory#show'
  get '/my_listings', to: 'my_listings#show'
  get '/account_histories', to: 'account_histories#show'
  get '/booster_creators', to: 'booster_creators#show'
  get '/order_histograms/:id', to: 'order_histograms#show'
  get '/order_histograms/:id/json', to: 'order_histograms#json'
  post '/tor/reset', to: 'tor#reset_instance_pool'
  post '/accounts/asf', to: 'accounts#asf_command'
  post '/order_histograms/ids', to: 'order_histograms#list'

  get 'inventory/assets'
  get 'buy_orders/list'
  get 'my_listings/list'
  get 'market_assets/orderable'
  get 'account_histories/all'
  get 'booster_creators/detail'
  get 'booster_creators/creatable'
  post 'inventory/reload'
  post 'inventory/sell_by_ppg'
  post 'inventory/grind_into_goo'
  post 'inventory/send_trade_offer'
  post 'buy_orders/import'
  post 'my_listings/cancel'
  post 'my_listings/reload'
  post 'my_listings/reload_confirming'
  post 'booster_creators/create_and_sell'
  post 'booster_creators/create_and_unpack'
  post 'booster_creators/sell_all_assets'
end
