module Constants
  OAUTH_PROVIDERS = %i[gsuite_provider office365_provider smartschool_provider].freeze
  AUTH_PROVIDERS = %i[lti_provider saml_provider].concat(OAUTH_PROVIDERS).freeze
end
