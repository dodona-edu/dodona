# == Schema Information
#
# Table name: judges
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  image      :string(255)
#  path       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Judge < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :image, presence: true
  validates :path, presence: true
end
