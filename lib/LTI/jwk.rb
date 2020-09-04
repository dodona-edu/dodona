module LTI
  module JWK
    KEY_PATH = '/home/dodona/key.pem'.freeze

    def encode_and_sign(payload)
      # Only load the key if it exists (staging / production).
      return "" unless key

      payload.expiration = Time.now.to_i + 3600
      payload.issued_at = Time.now.to_i

      payload, headers = payload.as_json, {kid: key.kid, typ: 'JWT'}
      JWT.encode(payload, key.keypair, 'RS256', headers)
    end

    def keyset
      # Only return something if a key is found.
      return [] unless key

      [key.export.merge({use: 'sig'})]
    end

    def parse_jwks_uri(uri)
      # Download the jwks keyset from the provider.
      keys = JSON.parse(HTTPClient.new.get_content(uri)).with_indifferent_access

      # Parse the keys.
      JSON::JWK::Set.new keys[:keys]
    end

    private

    def key
      # Only load the key if it exists (staging / production).
      return nil unless File.file?(KEY_PATH)

      # Parse the key.
      @key ||= JWT::JWK.create_from(OpenSSL::PKey::RSA.new File.read(KEY_PATH))
    end
  end
end
