# == Schema Information
#
# Table name: institutions
#
#  id          :bigint(8)        not null, primary key
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

class Institution < ApplicationRecord
  NEW_INSTITUTION_NAME = "n/a"
  enum provider: %i[smartschool office365 saml]

  has_many :users
  has_many :courses

  validates :identifier, uniqueness: {allow_blank: true}
  validates :logo, :short_name, :provider, presence: true
  validates :sso_url, :slo_url, :certificate, :entity_id, presence: true, if: :saml?

  def self.from_identifier(identifier)
    find_by(identifier: identifier) if identifier.present?
  end
end
