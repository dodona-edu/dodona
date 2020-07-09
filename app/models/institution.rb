# == Schema Information
#
# Table name: institutions
#
#  id         :bigint           not null, primary key
#  name       :string(255)
#  short_name :string(255)
#  logo       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Institution < ApplicationRecord
  NEW_INSTITUTION_NAME = 'n/a'.freeze

  has_many :users, dependent: :restrict_with_error
  has_many :providers, inverse_of: :institution, dependent: :restrict_with_error
  has_many :courses, dependent: :restrict_with_error

  validates :logo, :short_name, presence: true

  scope :of_course_by_members, ->(course) { joins(users: :courses).where(courses: { id: course.id }).distinct }

  def preferred_provider
    Provider.find_by(institution: self, mode: :prefer)
  end

  def uses_lti?
    providers.any? { |provider| provider.type == Provider::Lti.name }
  end

  def uses_smartschool?
    providers.any? { |provider| provider.type == Provider::Smartschool.name }
  end
end
