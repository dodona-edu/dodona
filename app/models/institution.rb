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

class Institution < ApplicationRecord
  enum provider: %i[smartschool office365 saml]

  validates :identifier, uniqueness: true, presence: false
  validates :logo, :short_name, :provider, presence: true
  validates :sso_url, :slo_url, :certificate, :entity_id, presence: true, if: :saml?
end
