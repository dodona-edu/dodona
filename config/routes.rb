Rails.application.routes.draw do
  devise_for :users, controllers: {omniauth_callbacks: 'omniauth_callbacks'}
  root 'pages#home'


  authenticated :user, -> user {user.zeus?} do
    mount DelayedJobWeb, at: '/dj'
  end

  get '/:locale' => 'pages#home', locale: /(en)|(nl)/

  scope '(:locale)', locale: /en|nl/ do
    get '/sign_in(/:idp)' => 'pages#sign_in_page', as: 'sign_in'

    get '/institution_not_supported' => 'pages#institution_not_supported'
    get '/about' => 'pages#about'
    get '/data' => 'pages#data'
    get '/privacy' => 'pages#privacy'

    get '/contact' => 'pages#contact'
    post '/contact' => 'pages#create_contact', as: 'create_contact'
    post '/toggle_demo_mode' => 'pages#toggle_demo_mode'
    post '/toggle_dark_mode' => 'pages#toggle_dark_mode'

    concern :mediable do
      member do
        get 'media/*media', to: 'exercises#media', constraints: {media: /.*/}, as: 'media'
      end
    end

    concern :submitable do
      resources :submissions, only: %i[index create]
    end

    resources :series, except: [:new, :index] do
      resources :exercises, only: [:index]
      member do
        get 'available_exercises', to: 'exercises#available'
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

    scope '/export' do
      get '/series/:id', to: 'export#download_submissions_from_series', as: 'export_series'
      post '/series/:id', to: 'export#start_download_from_series'
      get '/courses/:id', to: 'export#download_submissions_from_course', as: 'export_course'
      post '/courses/:id', to: 'export#start_download_from_course'
      get '/users/:id', to: 'export#download_submissions_from_user', as: 'export_user'
      post '/users/:id', to: 'export#start_download_from_user'
    end

    resources :courses do
      resources :series, only: [:new, :index] do
        resources :exercises, only: [:show, :edit, :update], concerns: %i[mediable submitable]
      end
      resources :exercises, only: [:show, :edit, :update], concerns: %i[mediable submitable]
      resources :submissions, only: [:index]
      resources :members, only: [:index, :show, :edit, :update], controller: :course_members do
        get 'download_labels_csv', on: :collection
        post 'upload_labels_csv', on: :collection
      end
      member do
        get 'statistics'
        get 'subscribe/:secret', to: 'courses#registration', as: "registration"
        get 'manage_series'
        get 'scoresheet'
        post 'mass_accept_pending'
        post 'mass_decline_pending'
        post 'reset_token'
        post 'unsubscribe'
        post 'update_membership'
        post 'favorite'
        post 'unfavorite'
        post 'reorder_series'
        match 'subscribe', via: %i[get post]
      end
    end

    resources :exercises, only: %i[index show edit update], concerns: %i[mediable submitable] do
      member do
        scope 'description/:token/' do
          constraints host: Rails.configuration.sandbox_host do
            root to: 'exercises#description', as: 'description'
            get 'media/*media',
                to: 'exercises#media',
                constraints: {media: /.*/},
                as: 'description_media'
          end
        end
      end
    end

    resources :judges do
      resources :submissions, only: [:index]
      member do
        match 'hook', via: %i[get post], to: 'judges#hook', as: 'webhook'
      end
    end

    resources :repositories do
      member do
        match 'hook', via: %i[get post], to: 'repositories#hook', as: 'webhook'
        get 'reprocess'
        get 'admins'
        get 'courses'
        post 'add_admin'
        post 'remove_admin'
        post 'add_course'
        post 'remove_course'
      end
    end

    resources :submissions, only: %i[index show create edit] do
      post 'mass_rejudge', on: :collection
      member do
        get 'download'
        get 'evaluate'
        get 'media/*media', to: 'submissions#media', constraints: {media: /.*/}, as: 'media'
      end
    end

    resources :users do
      resources :api_tokens, only: %i[index create destroy], shallow: true
      resources :submissions, only: [:index]
      get 'stop_impersonating', on: :collection
      get 'available_for_repository', on: :collection
      member do
        get 'impersonate'
        get 'token/:token', to: 'users#token_sign_in', as: 'token_sign_in'
      end
    end

    resources :labels
    resources :programming_languages

    resources :institutions, only: [:index, :show, :edit, :update]
    resources :events, only: [:index]

    scope 'stats', controller: 'statistics' do
      get 'heatmap', to: 'statistics#heatmap'
      get 'punchcard', to: 'statistics#punchcard'
    end
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'
end
