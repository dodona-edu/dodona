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

class Institution < ApplicationRecord
  NEW_INSTITUTION_NAME = 'n/a'.freeze
  enum provider: { smartschool: 0, office365: 1, saml: 2, google_oauth2: 3 }

  has_many :users, dependent: :restrict_with_error
  has_many :providers, inverse_of: :institution, dependent: :restrict_with_error
  has_many :courses, dependent: :restrict_with_error

  validates :identifier, uniqueness: { allow_blank: true, case_sensitive: false }
  validates :logo, :short_name, :provider, presence: true
  validates :sso_url, :slo_url, :certificate, :entity_id, presence: true, if: :saml?

  scope :of_course_by_members, ->(course) { joins(users: :courses).where(courses: { id: course.id }).distinct }

  def self.from_identifier(identifier)
    find_by(identifier: identifier) if identifier.present?
  end
end
