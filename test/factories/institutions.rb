# == Schema Information
#
# Table name: institutions
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  short_name  :string(255)
#  logo        :string(255)
#  sso_url     :string(255)
#  slo_url     :string(255)
#  certificate :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  entity_id   :string(255)
#

FactoryGirl.define do
  factory :institution do
    name { Faker::University.unique.name }
    short_name { name }
    logo "logo.png"
    domain  = Faker::Internet.domain_name
    sso_url { Faker::Internet.url(domain, '/SSO') }
    slo_url { Faker::Internet.url(domain, '/SLO') }
    certificate { Faker::Crypto.sha256 }
    entity_id { Faker::Internet.url(domain, '/entity') }
  end
end
