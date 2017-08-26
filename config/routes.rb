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

    resources :series, except: :new do
      member do
        get 'download_solutions'
        get 'overview'
        get 'scoresheet'
        post 'add_exercise'
        post 'mass_rejudge'
        post 'remove_exercise'
        post 'reorder_exercises'
        post 'reset_token'
      end
    end
    get 'series/indianio/:token', to: 'series#indianio_download', as: 'indianio_download'

    resources :courses do
      resources :series, only: :new
      resources :exercises, only: [:show], concerns: %i[mediable submitable]
      member do
        get 'list_members'
        get 'scoresheet'
        get 'subscribe/:secret', to: 'courses#registration', as: "registration"
        post 'mass_accept_pending'
        post 'mass_decline_pending'
        post 'reset_token'
        post 'unsubscribe'
        post 'update_membership'
        match 'subscribe', via: %i[get post]
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
      resources :courses, only: [:index]
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
