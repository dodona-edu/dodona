Rails.application.routes.draw do
  devise_for :users
  root 'pages#home'

  match '/dj' => DelayedJobWeb, :anchor => false, via: [:get, :post]

  get '/:locale' => 'pages#home', locale: /(en)|(nl)/

  scope '(:locale)', locale: /en|nl/ do
    resources :series do
      member do
        post 'add_exercise'
        post 'remove_exercise'
        post 'reorder_exercises'
        get 'download_solutions'
        get 'token/:token', to: 'series#token_show', as: 'token_show'
        get 'scoresheet'
      end
    end

    resources :courses do
      resources :series
      member do
        post 'subscribe'
        get 'scoresheet'
        get 'subscribe/:secret', to: 'courses#subscribe_with_secret', as: "subscribe_with_secret"
      end
    end

    resources :exercises, only: [:index, :show, :edit, :update] do
      resources :submissions, only: [:index, :create]
      member do
        get 'media/*media', to: 'exercises#media', constraints: { media: /.*/ }, as: "media"
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

    resources :submissions, only: [:index, :show, :create, :edit] do
      post 'mass_rejudge', on: :collection
      member do
        get 'download'
        get 'evaluate'
        get 'media/*media', to: 'submissions#media', constraints: { media: /.*/ }
      end
    end

    resources :users do
      resources :submissions, only: [:index]
      get 'stop_impersonating', on: :collection
      member do
        get 'impersonate'
        get 'photo'
        get 'token/:token', to: 'users#token_sign_in', as: 'token_sign_in'
      end
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'
end
