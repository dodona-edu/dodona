module SetCurrentRequestDetails
  extend ActiveSupport::Concern

  included do
    before_action :set_demo

    def set_demo
      ::Current.demo_mode = session[:demo]
    end
  end

  Warden::Manager.after_set_user do |user, _auth, _opts|
    ::Current.user = user
  end
end
