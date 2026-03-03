Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "magic/:token", to: "magic_links#show", as: :magic_link

  namespace :api do
    namespace :v1 do
      resources :deals, only: [:index, :show]
      resources :contacts, only: [:index, :show]
      resources :companies, only: [:index, :show]
      resources :pipelines, only: [:index, :show]
      post "sync", to: "sync#create"
    end
  end

  root "pages#index"
  get "*path", to: "pages#index", constraints: ->(req) { !req.xhr? && req.format.html? }
end
