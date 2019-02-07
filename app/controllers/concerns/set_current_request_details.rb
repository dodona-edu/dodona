module SetCurrentRequestDetails
  extend ActiveSupport::Concern

  Warden::Manager.after_set_user do |user, _auth, _opts|
    Current.user = user
  end
end
