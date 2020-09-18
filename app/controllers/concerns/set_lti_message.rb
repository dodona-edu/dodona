require_relative '../../../lib/LTI/jwk.rb'
require_relative '../../../lib/LTI/messages.rb'

module SetLtiMessage
  extend ActiveSupport::Concern

  include LTI::JWK
  include LTI::Messages

  def set_lti_message
    @lti_message = parse_message(params[:id_token], params[:provider_id])
    @lti_launch = @lti_message.is_a?(LTI::Messages::Types::ResourceLaunchRequest)
  end

  def set_lti_provider
    @provider = Provider::Lti.find(params[:provider_id]) if params[:provider_id].present?
  end
end
