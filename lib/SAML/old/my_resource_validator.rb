class MyResourceValidator
  def validate(user, saml_response)
    return true if user.present?

    institution = Institution.find_by(entity_id: saml_response.issuers[0], provider: :saml)
    return false if institution.nil?

    username = saml_response.attributes['urn:oid:0.9.2342.19200300.100.1.1'] || saml_response.attributes['urn:oid:1.3.6.1.4.1.5923.1.1.1.6']
    # If we don't have a username it can't conflict either
    # The user will get a new account, but won't see errors
    return true if username.nil?

    user = User.find_by(username: username, institution: institution)
    return true if user.nil?

    valid = user.email == saml_response.attributes['urn:oid:0.9.2342.19200300.100.1.3']
    unless valid
      ExceptionNotifier.notify_exception Exception.new("Someone's email adress changed"),
                                         data: {
                                           user: user,
                                           old_email: user.email,
                                           new_email: saml_response.attributes['urn:oid:0.9.2342.19200300.100.1.3']
                                         }
    end
    valid
  end
end
