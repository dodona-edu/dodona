# == Schema Information
#
# Table name: providers
#
#  id                :bigint           not null, primary key
#  type              :string(255)      default("Provider::Saml"), not null
#  institution_id    :bigint
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
FactoryBot.define do
  factory :gsuite_provider, class: 'Provider::GSuite' do
    institution
    identifier { SecureRandom.uuid }
  end

  factory :lti_provider, class: 'Provider::Lti' do
    institution

    authorization_uri { Faker::Internet.url }
    client_id { SecureRandom.uuid }
    issuer { Faker::Internet.url }
    jwks_uri { Faker::Internet.url }
  end

  factory :office365_provider, class: 'Provider::Office365' do
    institution
    identifier { SecureRandom.uuid }
  end

  factory :oidc_provider, class: 'Provider::Oidc' do
    institution

    client_id { SecureRandom.uuid }
    issuer { Faker::Internet.url }
  end

  factory :provider, aliases: [:saml_provider], class: 'Provider::Saml' do
    institution

    entity_id { Faker::Internet.url }
    sso_url { "#{entity_id}/SSO" }
    slo_url { "#{entity_id}/SLO" }
    certificate { Faker::Crypto.sha256 }
  end

  factory :smartschool_provider, class: 'Provider::Smartschool' do
    institution
    identifier { "https://#{institution.short_name}.smartschool.be" }
  end
end
