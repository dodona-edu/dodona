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

  # TODO: remove this after 4.0 has been deployed. Will break
  #       migration 20200619201239_extract_institution_auth_to_providers.
  enum provider: { smartschool: 0, office365: 1, saml: 2, google_oauth2: 3 }

  has_many :users, dependent: :restrict_with_error
  has_many :providers, inverse_of: :institution, dependent: :restrict_with_error
  has_many :courses, dependent: :restrict_with_error

  validates :logo, :short_name, presence: true

  scope :of_course_by_members, ->(course) { joins(users: :courses).where(courses: { id: course.id }).distinct }

  def preferred_provider
    Provider.find_by(institution: self, mode: :prefer)
  end

  def uses_smartschool?
    providers.any? { |provider| provider.type == Provider::Smartschool.name }
  end
end
