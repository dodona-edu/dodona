module LTI
  module JWK
    def parse_jwks_uri(uri)
      # Download the jwks keyset from the provider.
      keys = JSON.parse(HTTPClient.new.get_content(uri)).with_indifferent_access

      # Parse the keys.
      JSON::JWK::Set.new keys[:keys]
    end
  end
end
