# == Schema Information
#
# Table name: courses
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  year        :string(255)
#  secret      :string(255)
#  open        :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  description :text(65535)
#

require 'securerandom'

class Course < ApplicationRecord
  has_many :course_memberships
  has_many :series
  has_many :users, through: :course_memberships

  validates :name, presence: true
  validates :year, presence: true

  default_scope { order(year: :desc, name: :asc) }

  before_create :generate_secret

  def formatted_year
    year.sub(/ ?- ?/, '–')
  end

  def generate_secret
    self.secret = SecureRandom.urlsafe_base64(5)
  end
end
