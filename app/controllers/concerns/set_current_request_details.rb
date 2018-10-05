module SetCurrentRequestDetails
  extend ActiveSupport::Concern

  included do
    before_action do
      Current.ip_address = request.remote_ip
    end
  end

  Warden::Manager.after_set_user do |user, _auth, _opts|
    Current.user = user
  end
end
