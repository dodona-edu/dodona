module LTI
  module JWK
    KEY_PATH = '/home/dodona/key.pem'.freeze

    def encode_and_sign(payload)
      Rails.logger.info "=====================================#{self.class}##{__method__}"
      # Only load the key if it exists (staging / production).
      return "" unless key

      payload, headers = payload.as_json, {kid: key.kid, typ: 'JWT'}
      JWT.encode(payload, key.keypair, 'RS256', headers)
    end

    def keyset
      Rails.logger.info "=====================================#{self.class}##{__method__}"
      # Only return something if a key is found.
      return [] unless key

      [key.export.merge({use: 'sig'})]
    end

    def parse_jwks_uri(uri)
      Rails.logger.info "=====================================#{self.class}##{__method__}"
      # Download the jwks keyset from the provider.
      keys = JSON.parse(get_jwks_content(uri)).with_indifferent_access

      # Parse the keys.
      JSON::JWK::Set.new keys[:keys]
    end

    def get_jwks_content(uri)
      Rails.logger.info "=====================================#{self.class}##{__method__}"
      HTTPClient.new.get_content(uri)
    end

    private

    def key
      Rails.logger.info "=====================================#{self.class}##{__method__}"
      # Only load the key if it exists (staging / production).
      return nil unless File.file?(KEY_PATH)

      # Parse the key.
      @key ||= JWT::JWK.create_from(OpenSSL::PKey::RSA.new File.read(KEY_PATH))
    end
  end
end
