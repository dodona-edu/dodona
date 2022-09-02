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
#  category       :integer          default("secondary"), not null
#

class Institution < ApplicationRecord
  NEW_INSTITUTION_NAME = 'n/a'.freeze

  enum category: { secondary: 0, higher: 1, other: 2 }

  has_many :users, dependent: :restrict_with_error
  has_many :providers, inverse_of: :institution, dependent: :restrict_with_error
  has_many :courses, dependent: :restrict_with_error

  validates :logo, :short_name, presence: true
  validates_associated :providers

  accepts_nested_attributes_for :providers

  scope :of_course_by_members, ->(course) { joins(users: :courses).where(courses: { id: course.id }).distinct }
  scope :by_name, ->(name) { where('name LIKE ?', "%#{name}%").or(where('short_name LIKE ?', "%#{name}%")) }

  before_update :unmark_generated, if: :will_save_change_to_name?

  def name
    return self[:name] unless Current.demo_mode

    Faker::Config.random = Random.new(id + Date.today.yday)
    Faker::University.name
  end

  def preferred_provider
    providers.find_by(mode: :prefer)
  end

  def uses_lti?
    providers.any? { |provider| provider.type == Provider::Lti.name }
  end

  def uses_oidc?
    providers.any? { |provider| provider.type == Provider::Oidc.name }
  end

  def uses_smartschool?
    providers.any? { |provider| provider.type == Provider::Smartschool.name }
  end

  def unmark_generated
    self.generated_name = false
  end

  def merge_into(other)
    errors.add(:merge, "has overlapping usernames. Run `bin/rake merge_institutions[#{id},#{other.id}]` on the server to solve this using an interactive script.") if other.users.exists?(username: users.pluck(:username))
    errors.add(:merge, 'has link provider') if providers.any?(&:link?)
    return false if errors.any?

    providers.each do |p|
      if p.prefer?
        p.update(institution: other, mode: :secondary)
      else # secondary or redirect
        p.update(institution: other)
      end
    end
    courses.each { |c| c.update(institution: other) }
    users.each { |u| u.update(institution: other) }
    reload
    destroy
  end
end
