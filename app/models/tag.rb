# == Schema Information
#
# Table name: tags
#
#  id         :integer      not null, primary key
#  name       :string       not null, unique
#  color      :string       not null
class Tag < ApplicationRecord
  has_many :exercise_tags, dependent: :destroy
  has_many :exercises, through: :exercise_tags

  enum color: %i[red pink purple deep-purple indigo teal
                 orange brown blue-grey]

  scope :by_name, ->(name) { where('name LIKE ?', "%#{name}%") }

  after_initialize do
    self.color ||= Tag.colors.keys.sample
  end
end
