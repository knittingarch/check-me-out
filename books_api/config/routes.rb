Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :books do
    collection do
      get :search
    end
  end

  # Defines the root path route ("/")
  # root "articles#index"
end
