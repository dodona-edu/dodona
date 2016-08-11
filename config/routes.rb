Rails.application.routes.draw do
  devise_for :users
  root 'pages#home'

  match '/dj' => DelayedJobWeb, :anchor => false, via: [:get, :post]

  get '/:locale' => 'pages#home'

  scope '(:locale)', locale: /en|nl/ do
    resources :courses do
      member do
        post 'subscribe'
        get 'subscribe/:secret', to: 'courses#subscribe_with_secret', as: "subscribe_with_secret"
      end
    end

    resources :exercises, only: [:index, :show, :edit, :update] do
      resources :submissions, only: [:index, :create]
      member do
        get 'users'
        get 'media/*media', to: 'exercises#media', constraints: { media: /.*/ }
      end
    end

    resources :judges do
      member do
        match 'hook', via: [:get, :post], to: 'judges#hook', as: "webhook"
      end
    end

    resources :repositories do
      member do
        match 'hook', via: [:get, :post], to: 'repositories#hook', as: "webhook"
        get 'reprocess'
      end
    end

    resources :submissions, only: [:index, :show, :create] do
      member do
        get 'download'
        get 'evaluate'
      end
    end

    resources :users do
      resources :submissions, only: [:index]
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'
end
