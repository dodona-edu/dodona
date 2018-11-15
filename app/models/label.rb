# == Schema Information
#
# Table name: labels
#
#  id    :bigint(8)        not null, primary key
#  name  :string(255)      not null
#  color :integer          not null
#

class Label < ApplicationRecord
  has_many :exercise_labels, dependent: :restrict_with_error
  has_many :exercises, through: :exercise_labels

  enum color: %i[red pink purple deep-purple indigo teal
                 orange brown blue-grey]

  scope :by_name, ->(name) {where('name LIKE ?', "%#{name}%")}

  after_initialize do
    self.color ||= :purple
  end
end
