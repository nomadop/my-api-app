require 'sidekiq/web'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  mount Sidekiq::Web => '/sidekiq'

  resource :authentication
  get '/booster_creators', to: 'booster_creators#show'
  get '/booster_creators/creatable', to: 'booster_creators#creatable'
end
