module SetCurrentRequestDetails
  extend ActiveSupport::Concern

  included do
    before_action :set_anonymous

    def set_anonymous
      ::Current.anonymous_mode = !!session[:anonymous]
    end
  end

  Warden::Manager.after_set_user do |user, _auth, _opts|
    ::Current.user = user
  end
end
