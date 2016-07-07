# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  username   :string(255)
#  ugent_id   :string(255)
#  first_name :string(255)
#  last_name  :string(255)
#  email      :string(255)
#  permission :integer          default("student")
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class User < ApplicationRecord
  enum permission: [:student, :teacher, :zeus]

  has_many :submissions

  devise :cas_authenticatable

  def full_name
    first_name + ' ' + last_name
  end

  def admin?
    teacher? || zeus?
  end

  def correct_exercises
    submissions.where(status: :correct).distinct.count(:exercise_id)
  end

  def cas_extra_attributes=(extra_attributes)
    extra_attributes.each do |name, value|
      case name.to_sym
      when :mail
        self.email = value
      when :givenname
        self.first_name = value
      when :surname
        self.last_name = value
      when :ugentID
        self.ugent_id = value
      end
    end
  end
end
