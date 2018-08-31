# == Schema Information
#
# Table name: labels
#
#  id         :integer      not null, primary key
#  name       :string       not null, unique
#  color      :string       not null
class Label < ApplicationRecord
  has_many :exercise_labels, dependent: :destroy
  has_many :exercises, through: :exercise_labels

  enum color: %i[red pink purple deep-purple indigo teal
                 orange brown blue-grey]

  scope :by_name, ->(name) { where('name LIKE ?', "%#{name}%") }

  after_initialize do
    self.color ||= Label.colors.keys.sample
  end
end
