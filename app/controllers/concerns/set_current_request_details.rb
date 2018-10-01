module SetCurrentRequestDetails
  extend ActiveSupport::Concern

  included do
    before_action do
      Current.ip_address = request.remote_ip
    end
  end
end
