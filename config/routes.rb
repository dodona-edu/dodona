Rails.application.routes.draw do
  authenticated :user, ->(user) { user.zeus? } do
    mount DelayedJobWeb, at: '/dj'
  end

  # Authentication routes.
  devise_for :users, controllers: {omniauth_callbacks: 'auth/omniauth_callbacks'}
  root 'pages#home'

  devise_scope :user do
    post '/users/saml/auth' => 'auth/omniauth_callbacks#saml' # backwards compatibility
  end

  get '/:locale' => 'pages#home', locale: /(en)|(nl)/

  scope '(:locale)', locale: /en|nl/ do
    namespace :auth, path: '', as: '' do
      devise_scope :user do
        get '/sign_in' => 'authentication#sign_in', as: 'sign_in'
        delete '/sign_out' => 'authentication#destroy', as: 'sign_out'
      end

      get '/users/saml/metadata' => 'saml#metadata'
    end

    get '/institution_not_supported' => 'pages#institution_not_supported'
    get '/about' => 'pages#about'
    get '/data' => 'pages#data'
    get '/privacy' => 'pages#privacy'
    get '/profile' => 'pages#profile', as: 'profile'
    get '/support-us' => 'pages#support'

    get '/contact' => 'pages#contact'
    post '/contact' => 'pages#create_contact', as: 'create_contact'
    post '/toggle_demo_mode' => 'pages#toggle_demo_mode'
    post '/toggle_dark_mode' => 'pages#toggle_dark_mode'

    get '/status' => redirect("https://p.datadoghq.com/sb/sil3oh7xurb0ujwu-3dfa8d0b077b83f3afbee49f0641abfd"), :as => :status

    concern :mediable do
      member do
        constraints host: Rails.configuration.web_hosts do
          get 'media/*media', to: 'activities#media', constraints: {media: /.*/}, as: :media
        end
      end
    end

    concern :infoable do
      member do
        get 'info'
      end
    end

    concern :readable do
      resources :activity_read_states, only: %i[index create]
    end

    concern :submitable do
      resources :submissions, only: %i[index create]
    end

    resources :series, except: %i[new index] do
      resources :activities, only: [:index]
      resources :activities, only: [:index], path: '/exercises'
      member do
        get 'available_activities', to: 'activities#available'
        get 'overview'
        get 'scoresheet'
        post 'add_activity'
        post 'mass_rejudge'
        post 'remove_activity'
        post 'reorder_activities'
        post 'reset_token'
      end
    end
    get 'series/indianio/:token', to: 'series#indianio_download', as: 'indianio_download'

    resources :exports, except: %i[show edit update new destroy create] do
      get 'users/:id', on: :collection, to: 'exports#new_user_export', as: 'users'
      post 'users/:id', on: :collection, to: 'exports#create_user_export'
      get 'courses/:id', on: :collection, to: 'exports#new_course_export', as: 'courses'
      post 'courses/:id', on: :collection, to: 'exports#create_course_export'
      get 'series/:id', on: :collection, to: 'exports#new_series_export', as: 'series'
      post 'series/:id', on: :collection, to: 'exports#create_series_export'
    end

    resources :courses do
      resources :series, only: %i[new index] do
        resources :activities, only: %i[show edit update], concerns: %i[mediable readable submitable infoable]
        resources :activities, only: %i[show edit update], concerns: %i[mediable readable submitable infoable], path: '/exercises', as: 'exercises'
      end
      resources :activities, only: %i[show edit update], concerns: %i[mediable readable submitable infoable]
      resources :activities, only: %i[show edit update], concerns: %i[mediable readable submitable infoable], path: '/exercises', as: 'exercises'
      resources :submissions, only: [:index]
      resources :activity_read_states, only: [:index]
      resources :members, only: %i[index show edit update], controller: :course_members do
        get 'download_labels_csv', on: :collection
        post 'upload_labels_csv', on: :collection
      end
      member do
        get 'statistics'
        get 'subscribe/:secret', to: 'courses#registration', as: 'registration'
        get 'manage_series'
        get 'scoresheet'
        get 'questions'
        get 'ical'
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

    resources :activities, only: %i[index show edit update], concerns: %i[readable mediable submitable infoable] do
      member do
        scope 'description/:token/' do
          constraints host: Rails.configuration.sandbox_host do
            root to: 'activities#description', as: 'description'
            get 'media/*media',
                to: 'activities#media',
                constraints: {media: /.*/},
                as: 'description_media'
          end
        end
      end
    end
    # Allow resolving the required service worker
    get 'inputServiceWorker.js', to: 'activities#isw', as: 'isw'

    resources :activities, only: %i[index show edit update], concerns: %i[mediable readable submitable infoable], path: '/exercises', as: 'exercises' do
      member do
        scope 'description/:token/' do
          constraints host: Rails.configuration.sandbox_host do
            root to: 'activities#description'
            get 'media/*media',
                to: 'activities#media',
                constraints: {media: /.*/}
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
        get 'public/*media', to: 'repositories#public', constraints: {media: /.*/}, as: 'public'
        post 'add_admin'
        post 'remove_admin'
        post 'add_course'
        post 'remove_course'
      end
    end

    resources :annotations, only: %i[index show create update destroy]

    get 'questions', to: 'annotations#question_index'

    resources :submissions, only: %i[index show create edit] do
      resources :annotations, only: %i[index create], as: 'submission_annotations'
      post 'mass_rejudge', on: :collection
      member do
        get 'download'
        get 'evaluate'
        get 'media/*media', to: 'submissions#media', constraints: {media: /.*/}, as: 'media'
      end
      resources :annotations, only: [:index, :create, :update, :destroy], format: :json
    end

    resources :activity_read_states, only: %i[index create]

    resources :users do
      resources :api_tokens, only: %i[index create destroy], shallow: true
      resources :submissions, only: [:index]
      resources :activity_read_states, only: [:index]
      get 'stop_impersonating', on: :collection
      get 'available_for_repository', on: :collection
      member do
        get 'impersonate'
        get 'token/:token', to: 'users#token_sign_in', as: 'token_sign_in'
      end
    end

    resources :labels
    resources :programming_languages

    resources :institutions, only: %i[index show edit update] do
      member do
        get 'merge'
        get 'merge_changes'
        post 'merge', to: 'institutions#do_merge'
      end
    end
    resources :events, only: [:index]
    resources :notifications, only: %i[index update destroy] do
      delete 'destroy_all', on: :collection
    end

    resources :evaluations, only: %i[show new edit create update destroy] do
      member do
        get 'overview'
        get 'export_grades'
        post 'add_user'
        post 'remove_user'
        post 'set_multi_user'
        post 'modify_grading_visibility'
      end
      resources :feedbacks, only: %i[show edit update]
      resources :score_items, only: %i[create destroy update] do
        post 'copy', on: :collection
        post 'add_all', on: :collection
      end
      resources :scores, only: %i[show create update destroy]
    end
    resources :feedbacks, only: %i[show edit update]
    resources :evaluation_exercise, only: %i[update]

    resources :rights_requests, only: %i[index new create] do
      member do
        post 'approve'
        post 'reject'
      end
    end

    scope 'lti', controller: 'lti' do
      get 'redirect', to: 'lti#redirect', as: 'lti_redirect'
      get 'do_redirect', to: 'lti#do_redirect', as: 'lti_do_redirect'
      get 'content_selection', to: 'lti#content_selection'
      get 'series_and_activities', to: 'lti#series_and_activities'
      post 'content_selection', to: 'lti#content_selection_payload'
      get 'jwks', to: 'lti#jwks'
    end

    scope 'stats', controller: 'statistics' do
      get 'heatmap', to: 'statistics#heatmap'
      get 'punchcard', to: 'statistics#punchcard'
      get 'violin', to: 'statistics#violin'
      get 'stacked_status', to: 'statistics#stacked_status'
      get 'timeseries', to: 'statistics#timeseries'
      get 'cumulative_timeseries', to: 'statistics#cumulative_timeseries'
    end
  end

# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

# Serve websocket cable requests in-process
# mount ActionCable.server => '/cable'
end
