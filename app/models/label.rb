# == Schema Information
#
# Table name: labels
#
#  id    :bigint           not null, primary key
#  name  :string(255)      not null
#  color :integer          not null
#

class Label < ApplicationRecord
  has_many :activity_labels, dependent: :restrict_with_error
  has_many :activities, through: :activity_labels

  enum color: { red: 0, pink: 1, purple: 2, 'deep-purple': 3, indigo: 4, teal: 5, orange: 6, brown: 7, 'blue-grey': 8 }

  scope :by_name, ->(name) { where('name LIKE ?', "%#{name}%") }

  before_save :downcase_name

  after_initialize do
    self.color ||= :purple
  end

  private

  def downcase_name
    name.downcase!
  end
end
