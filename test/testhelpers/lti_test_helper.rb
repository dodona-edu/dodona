module LtiTestHelper
  FILES_LOCATION = Rails.root.join('test/files')

  def lti_payload(nonce, target, type)
    exp = Time.now.to_i + 600
    iat = Time.now.to_i
    payload = {
      iss: @provider.issuer,
      aud: @provider.client_id,
      exp: exp,
      iat: iat,
      sub: 'test-user-123',
      nonce: nonce,
      'https://purl.imsglobal.org/spec/lti/claim/message_type': type,
      'https://purl.imsglobal.org/spec/lti/claim/version': '1.3.0',
      'https://purl.imsglobal.org/spec/lti/claim/deployment_id': 'c5899818-7062-44d1-b377-5a08097daeb3',
      'https://purl.imsglobal.org/spec/lti/claim/target_link_uri': target,
      'https://purl.imsglobal.org/spec/lti/claim/resource_link': {
        id: '5B0748E6-E75C-4A93-8875-E034639B31CD-513799_107172',
        title: 'Oef 3-2 - vierkantsvergelijking',
        description: nil
      }
    }
    if type == 'LtiDeepLinkingRequest'
      payload[:'https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings'] = {
        accept_types: %w[link file html ltiResourceLink image],
        accept_media_types: 'image/*,text/html',
        accept_presentation_document_targets: %w[iframe window embed],
        accept_multiple: true,
        auto_create: true,
        title: 'This is the default title',
        text: 'This is the default text',
        data: 'Some random opaque data that MUST be sent back',
        deep_link_return_url: 'https://www.example.com/deep_links'
      }
    end

    payload
  end
end
