require 'test_helper'

class SamlControllerTest < ActionDispatch::IntegrationTest
  test 'SAML metadata' do
    # Validate whether the request works.
    get users_saml_metadata_path

    assert_response :success

    # Validate that actual metadata is returned.
    assert_includes response.content_type, 'application/xml'
  end

  test 'SAML metadata contains Belnet requested attributes' do
    get users_saml_metadata_path

    assert_response :success

    # parse the xml
    doc = Nokogiri::XML(response.body)

    # check if the xml contains the correct elements
    assert_not_nil doc.at_xpath('//md:Organization')
    assert_equal 'UGent - Dodona', doc.at_xpath('//md:OrganizationName[@xml:lang="en"]').children.first.content
    assert_equal 'UGent - Dodona', doc.at_xpath('//md:OrganizationName[@xml:lang="nl"]').children.first.content
    assert_equal 'UGent - Dodona', doc.at_xpath('//md:OrganizationName[@xml:lang="fr"]').children.first.content
    assert_equal 'UGent - Dodona', doc.at_xpath('//md:OrganizationDisplayName[@xml:lang="en"]').children.first.content
    assert_equal 'UGent - Dodona', doc.at_xpath('//md:OrganizationDisplayName[@xml:lang="nl"]').children.first.content
    assert_equal 'UGent - Dodona', doc.at_xpath('//md:OrganizationDisplayName[@xml:lang="fr"]').children.first.content
    assert_equal 'https://dodona.be', doc.at_xpath('//md:OrganizationURL[@xml:lang="en"]').children.first.content
    assert_equal 'https://dodona.be', doc.at_xpath('//md:OrganizationURL[@xml:lang="nl"]').children.first.content
    assert_equal 'https://dodona.be', doc.at_xpath('//md:OrganizationURL[@xml:lang="fr"]').children.first.content

    assert_not_nil doc.at_xpath('//md:ContactPerson[@contactType="technical"]')
    assert_not_nil doc.at_xpath('//md:ContactPerson[@contactType="technical"]/md:GivenName')
    assert_not_nil doc.at_xpath('//md:ContactPerson[@contactType="technical"]/md:SurName')
    assert_not_nil doc.at_xpath('//md:ContactPerson[@contactType="technical"]/md:EmailAddress')
  end

  test 'SAML Metadata supports belnet namespace' do
    get users_saml_metadata_path

    assert_response :success

    # parse the xml
    doc = Nokogiri::XML(response.body)

    # check if the xml contains the correct elements
    assert_not_nil doc.at_xpath('//md:EntityDescriptor', 'md' => 'urn:oasis:names:tc:SAML:2.0:metadata')
    assert_not_nil doc.at_xpath('//md:EntityDescriptor', 'md' => 'urn:oasis:names:tc:SAML:2.0:metadata', 'ds' => 'http://www.w3.org/2000/09/xmldsig#')
  end

  test 'SAML metadata should exactly match the metadata expected by KULeuven' do
    cert = mock
    cert.stubs(:to_der).returns('cert')
    OneLogin::RubySaml::Settings.any_instance.stubs(:get_sp_cert).returns(cert)

    get users_saml_metadata_path

    assert_response :success

    response_without_id = response.body.gsub(/ID='[^']*'/, "ID='ID'")
    expected = Rails.root.join('test/controllers/auth/ku_leuven_metadata.xml').read.gsub(/ID='[^']*'/, "ID='ID'")

    assert_equal expected, response_without_id
  end
end
