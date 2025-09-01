require 'rswag/ui'
require 'rswag/api'

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :books do
    collection do
      get :search
    end
  end

  # Defines the root path route ("/")
  # root "articles#index"
end
