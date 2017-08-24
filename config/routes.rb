Rails.application.routes.draw do
  devise_for :users
  root 'pages#home'

  match '/dj' => DelayedJobWeb, :anchor => false, via: %i[get post]

  get '/:locale' => 'pages#home', locale: /(en)|(nl)/

  scope '(:locale)', locale: /en|nl/ do
    concern :mediable do
      member do
        get 'media/*media', to: 'exercises#media', constraints: { media: /.*/ }, as: 'media'
      end
    end

    concern :submitable do
      resources :submissions, only: %i[index create]
    end

    resources :series do
      member do
        post 'add_exercise'
        post 'remove_exercise'
        post 'reorder_exercises'
        post 'mass_rejudge'
        get 'download_solutions'
        get 'token/:token', to: 'series#token_show', as: 'token_show'
        get 'scoresheet'
        get 'indianio/:token', to: 'series#indianio_download', as: 'indianio_download'
      end
    end

    resources :courses do
      resources :series
      resources :exercises, only: [:show], concerns: %i[mediable submitable]
      member do
        post 'subscribe'
        get 'scoresheet'
        get 'subscribe/:secret', to: 'courses#subscribe_with_secret', as: 'subscribe_with_secret'
      end
    end

    resources :exercises, only: %i[index show edit update], concerns: %i[mediable submitable]

    resources :judges do
      member do
        match 'hook', via: %i[get post], to: 'judges#hook', as: 'webhook'
      end
    end

    resources :repositories do
      member do
        match 'hook', via: %i[get post], to: 'repositories#hook', as: 'webhook'
        get 'reprocess'
      end
    end

    resources :submissions, only: %i[index show create edit], concerns: :mediable do
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
