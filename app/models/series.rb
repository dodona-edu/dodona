# == Schema Information
#
# Table name: series
#
#  id              :integer          not null, primary key
#  course_id       :integer
#  name            :string(255)
#  description     :text(65535)
#  visibility      :integer
#  order           :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  deadline        :datetime
#  access_token    :string(255)
#  indianio_token  :string(255)
#

require 'csv'

class Series < ApplicationRecord
  enum visibility: %i[open hidden closed]

  belongs_to :course
  has_many :series_memberships, dependent: :destroy
  has_many :exercises, through: :series_memberships

  validates :name, presence: true
  validates :visibility, presence: true

  before_save :set_access_token

  default_scope { order(created_at: :desc) }

  after_initialize do
    self.visibility ||= 'open'
  end

  def deadline?
    deadline.present?
  end

  def pending?
    deadline? && deadline > Time.zone.now
  end

  def completed?(user)
    exercises.all? { |e| e.accepted_for(user) }
  end

  def solved_exercises(user)
    exercises.select { |e| e.accepted_for(user) }
  end

  def indianio_support
    indianio_token.present?
  end

  def indianio_support?
    indianio_support
  end

  def indianio_support=(value)
    value = false if value == '0' || value == 0 || value == 'false'
    if indianio_token.nil? && value
      generate_token :indianio_token
    elsif !value
      self.indianio_token = nil
    end
  end

  def zip_solutions(user, with_info: false)
    filename = "#{name.parameterize}-#{user.full_name.parameterize}.zip"
    stringio = Zip::OutputStream.write_buffer do |zio|
      info = CSV.generate(force_quotes: true) do |csv|
        csv << %w[filename status submission_id name_en name_nl exercise_id]
        exercises.each do |ex|
          submission = ex.last_submission(user, deadline, course)
          # write the submission
          zio.put_next_entry(ex.file_name)
          zio.write submission&.code
          # write some extra information to the csv
          csv << [ex.file_name, submission&.status, submission&.id, ex.name_en, ex.name_nl, ex.id]
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

  def generate_token(type)
    raise 'unknown token type' unless %i[indianio_token access_token].include? type
    self[type] = SecureRandom.urlsafe_base64(16)
  end

  private

  def set_access_token
    if !hidden?
      self.access_token = nil
    elsif access_token.blank?
      generate_token :access_token
    end
  end
end
