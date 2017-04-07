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
#  deadline    :datetime
#  token       :string(255)
#

require 'csv'

class Series < ApplicationRecord
  enum visibility: [:open, :hidden, :closed]

  belongs_to :course
  has_many :series_memberships, dependent: :destroy
  has_many :exercises, through: :series_memberships

  validates :course, presence: true
  validates :name, presence: true

  before_save :set_token

  default_scope { order(created_at: :desc) }
  scope :in_teachers, ->(user) { joins('LEFT JOIN course_memberships ON series.course_id = course_memberships.course_id').where('course_memberships.status = 1 AND course_memberships.user_id = ?', user.id) }

  def deadline?
    !deadline.blank?
  end

  def zip_solutions(user, with_info: false)
    filename = "#{name.parameterize}-#{user.full_name.parameterize}.zip"
    stringio = Zip::OutputStream.write_buffer do |zio|
      info = CSV.generate(force_quotes: true) do |csv|
        csv << %w(filename status submission_id name)
        exercises.each do |ex|
          submission = ex.last_submission(user, deadline)
          # write the submission
          zio.put_next_entry(ex.file_name)
          zio.write submission&.code
          # write some extra information to the csv
          csv << [ex.file_name, submission&.status, submission&.id, ex.name]
        end
      end
      if with_info
        zio.put_next_entry('info.csv')
        zio.write info
      end
    end
    stringio.rewind
    zip_data = stringio.sysread
    { filename: filename, data: zip_data }
  end

  def teacher?(user)
    course.teacher?(user)
  end

  private

  def set_token
    if !hidden?
      self.token = nil
    elsif token.blank?
      self.token = SecureRandom.urlsafe_base64(6)
    end
  end
end
