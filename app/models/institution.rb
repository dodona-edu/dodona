# == Schema Information
#
# Table name: institutions
#
#  id             :bigint           not null, primary key
#  name           :string(255)
#  short_name     :string(255)
#  logo           :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  generated_name :boolean          default(TRUE), not null
#

class Institution < ApplicationRecord
  NEW_INSTITUTION_NAME = 'n/a'.freeze

  has_many :users, dependent: :restrict_with_error
  has_many :providers, inverse_of: :institution, dependent: :restrict_with_error
  has_many :courses, dependent: :restrict_with_error

  validates :logo, :short_name, presence: true

  scope :of_course_by_members, ->(course) { joins(users: :courses).where(courses: { id: course.id }).distinct }
  scope :by_name, ->(name) { where('name LIKE ?', "%#{name}%").or(where('short_name LIKE ?', "%#{name}%")) }

  before_update :unmark_generated, if: :will_save_change_to_name?

  def name
    return self[:name] unless Current.demo_mode

    Faker::Config.random = Random.new(id + Date.today.yday)
    Faker::University.name
  end

  def preferred_provider
    Provider.find_by(institution: self, mode: :prefer)
  end

  def uses_lti?
    providers.any? { |provider| provider.type == Provider::Lti.name }
  end

  def uses_smartschool?
    providers.any? { |provider| provider.type == Provider::Smartschool.name }
  end

  def unmark_generated
    self.generated_name = false
  end
end
