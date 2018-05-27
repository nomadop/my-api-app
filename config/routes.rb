require 'sidekiq/web'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  mount Sidekiq::Web => '/sidekiq'

  resource :authentication
  get '/inventory', to: 'inventory#show'
  get '/inventory/assets', to: 'inventory#assets'
  get '/booster_creators', to: 'booster_creators#show'
  get '/booster_creators/creatable', to: 'booster_creators#creatable'
  post '/inventory/reload', to: 'inventory#reload'
  post '/inventory/sell_by_ppg', to: 'inventory#sell_by_ppg'
  post '/booster_creators/create_and_sell', to: 'booster_creators#create_and_sell'
  post '/booster_creators/create_and_unpack', to: 'booster_creators#create_and_unpack'
  post '/booster_creators/sell_all_assets', to: 'booster_creators#sell_all_assets'
end
