module LTI
  module JWK
    KEY_PATH = '/home/dodona/key.pem'.freeze

    def keyset
      # Only load the key if it exists (staging / production).
      return {} unless File.file?(KEY_PATH)

      # Parse the key.
      jwk = JWT::JWK.create_from(OpenSSL::PKey::RSA.new File.read(KEY_PATH))
      [jwk.export]
    end

    def parse_jwks_uri(uri)
      # Download the jwks keyset from the provider.
      keys = JSON.parse(HTTPClient.new.get_content(uri)).with_indifferent_access

      # Parse the keys.
      JSON::JWK::Set.new keys[:keys]
    end
  end
end
