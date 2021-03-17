# == Schema Information
#
# Table name: providers
#
#  id                :bigint           not null, primary key
#  type              :string(255)      default("Provider::Saml"), not null
#  institution_id    :bigint           not null
#  identifier        :string(255)
#  certificate       :text(16777215)
#  entity_id         :string(255)
#  slo_url           :string(255)
#  sso_url           :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  mode              :integer          default("prefer"), not null
#  active            :boolean          default(TRUE)
#  authorization_uri :string(255)
#  client_id         :string(255)
#  issuer            :string(255)
#  jwks_uri          :string(255)
#
require 'test_helper'

class ProviderTest < ActiveSupport::TestCase
  DEFAULT_NAMES = [Institution::NEW_INSTITUTION_NAME, Institution::NEW_INSTITUTION_NAME].freeze

  test 'provider factories' do
    AUTH_PROVIDERS.each do |provider|
      create provider
    end
  end

  test 'at least one preferred provider per institution' do
    institution = create :institution

    redirect_prov = build :provider, institution: institution, mode: :redirect
    assert_not redirect_prov.valid?

    create :provider, institution: institution
  end

  test 'at most one preferred provider per institution' do
    institution = create :institution
    create :provider, institution: institution

    second = build :provider, institution: institution
    assert_not second.valid?
  end

  test 'gsuite extracts name of institution' do
    # This hash is extracted from the one we receive when logging in.
    provider = Provider::GSuite
    hash = {
      provider: 'google_oauth2',
      uid: 'something',
      info: {
        name: 'Jan Janssens',
        email: 'janssens@example.com',
        first_name: 'Jan',
        last_name: 'Janssens',
        institution: 'example.com'
      }
    }
    hash = OmniAuth::AuthHash.new(hash)
    assert_equal %w[example.com example.com], provider.extract_institution_name(hash)

    assert_equal DEFAULT_NAMES, provider.extract_institution_name(OmniAuth::AuthHash.new({}))
    assert_equal DEFAULT_NAMES, provider.extract_institution_name(OmniAuth::AuthHash.new({ info: {} }))
  end

  test 'smartschool extracts name of institution' do
    provider = Provider::Smartschool
    # This hash is extracted from the one we receive when logging in.
    hash = {
      provider: 'smartschool',
      uid: 'something',
      info: {
        username: 'janj',
        first_name: 'Jan',
        last_name: 'Janssens',
        email: 'example@example.com',
        institution: 'https://test.smartschool.be'
      }
    }
    hash = OmniAuth::AuthHash.new(hash)
    assert_equal %w[test test], provider.extract_institution_name(hash)

    # Do tests to ensure it works for "invalid" input
    hash.info.institution = 'not-url'
    assert_equal DEFAULT_NAMES, provider.extract_institution_name(hash)

    hash.info.institution = 'http://www.example.com'
    assert_equal DEFAULT_NAMES, provider.extract_institution_name(hash)

    assert_equal DEFAULT_NAMES, provider.extract_institution_name(OmniAuth::AuthHash.new({}))
    assert_equal DEFAULT_NAMES, provider.extract_institution_name(OmniAuth::AuthHash.new({ info: {} }))
  end

  test 'office365 extracts name of institution' do
    provider = Provider::Office365
    # This hash is extracted from the one we receive when logging in.
    hash = {
      provider: 'office365',
      uid: 'something',
      info: {
        username: 'janj',
        first_name: 'Jan',
        last_name: 'Janssens',
        email: 'example@example.com',
        institution: 'useless-for-human-identifier'
      }
    }
    hash = OmniAuth::AuthHash.new(hash)
    assert_equal %w[example.com example.com], provider.extract_institution_name(hash)

    hash.info.email = 'not an email anymore'
    assert_equal DEFAULT_NAMES, provider.extract_institution_name(hash)

    assert_equal DEFAULT_NAMES, provider.extract_institution_name(OmniAuth::AuthHash.new({}))
    assert_equal DEFAULT_NAMES, provider.extract_institution_name(OmniAuth::AuthHash.new({ info: {} }))
  end

  test 'other providers use default' do
    [Provider::Lti, Provider::Saml].each do |provider|
      assert_equal DEFAULT_NAMES, provider.extract_institution_name(OmniAuth::AuthHash.new({}))
    end
  end
end
