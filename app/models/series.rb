# == Schema Information
#
# Table name: series
#
#  id          :integer          not null, primary key
#  course_id   :integer
#  name        :string(255)
#  description :text(65535)
#  visibility  :integer
#  order       :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Series < ApplicationRecord
  enum visibility: [:open, :hidden, :closed]

  belongs_to :course
  has_many :series_memberships
  has_many :exercises, through: :series_memberships

  validates :course, presence: true
  validates :name, presence: true
end
