# == Schema Information
#
# Table name: institutions
#
#  id          :bigint           not null, primary key
#  name        :string(255)
#  short_name  :string(255)
#  logo        :string(255)
#  sso_url     :string(255)
#  slo_url     :string(255)
#  certificate :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  entity_id   :string(255)
#  provider    :integer
#  identifier  :string(255)
#

FactoryBot.define do
  factory :base_institution, class: Institution do
    name { Faker::University.unique.name }
    short_name { name.gsub(/\s+/, '') }
    logo { 'logo.png' }
  end

  factory :institution, aliases: [:saml_institution], parent: :base_institution do
    domain = Faker::Internet.domain_name
    sso_url { Faker::Internet.url(host: domain, path: '/SSO') }
    slo_url { Faker::Internet.url(host: domain, path: '/SLO') }
    certificate { Faker::Crypto.sha256 }
    entity_id { Faker::Internet.url(host: domain, path: '/entity') }
    provider { :saml }
  end

  factory :smartschool_institution, parent: :base_institution do
    identifier { "https://#{short_name}.smartschool.be" }
    provider { :smartschool }
  end

  factory :office365_institution, parent: :base_institution do
    identifier { SecureRandom.uuid }
    provider { :office365 }
  end
end
