module Constants
  OAUTH_PROVIDERS = %i[gsuite_provider office365_provider smartschool_provider].freeze
  AUTH_PROVIDERS = %i[saml_provider].concat(OAUTH_PROVIDERS).freeze
end
