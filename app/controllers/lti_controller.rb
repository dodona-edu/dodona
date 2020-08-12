require_relative '../../lib/LTI/jwk.rb'

class LtiController < ApplicationController
  include LTI::JWK

  def jwks
    render json: { keys: keyset }
  end
end
