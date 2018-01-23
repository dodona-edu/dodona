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
#

FactoryGirl.define do
  factory :institution do
    name "Some University"
    short_name "USome"
    logo "logo.png"
    sso_url "http://something.be"
    slo_url "http://something.be"
    certificate "this is a cert"
  end
end
