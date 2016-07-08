Rails.application.routes.draw do
  devise_for :users
  root 'pages#home'

  get '/:locale' => 'pages#home'

  scope '(:locale)', locale: /en|nl/ do
    resources :courses do
      member do
        post 'subscribe'
        get 'subscribe/:secret', to: 'courses#subscribe_with_secret', as: "subscribe_with_secret"
      end
    end
    resources :exercises, only: [:index, :show, :edit, :update], param: :name do
      resources :submissions, only: [:index, :create]
      member do
        get 'users'
      end
    end

    resources :submissions, only: [:index, :show, :create] do
      member do
        get 'download'
      end
    end

    resources :users do
      resources :submissions, only: [:index]
    end
  end

  # Webhooks
  match '/webhooks/update_exercises', via: [:get, :post], to: 'webhooks#update_exercises'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'
end
