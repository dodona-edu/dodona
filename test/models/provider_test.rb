# == Schema Information
#
# Table name: providers
#
#  id                :bigint           not null, primary key
#  type              :string(255)      default("Provider::Saml"), not null
#  institution_id    :bigint           not null
#  identifier        :string(255)
#  certificate       :text(65535)
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
end
