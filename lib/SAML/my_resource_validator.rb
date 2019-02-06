class MyResourceValidator
  def validate(user, saml_response)
    return true if user.present?
    institution = Institution.find_by(entity_id: saml_response.issuers[0], provider: :saml)
    return false if institution.nil?
    user = User.find_by(username: saml_response.attributes["urn:oid:0.9.2342.19200300.100.1.1"], institution: institution)
    return true if user.nil?
    user.email == saml_response.attributes["urn:oid:0.9.2342.19200300.100.1.3"]
  end
end
