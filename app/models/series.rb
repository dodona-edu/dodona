# == Schema Information
#
# Table name: series
#
#  id               :integer          not null, primary key
#  course_id        :integer
#  name             :string(255)
#  description      :text(65535)
#  visibility       :integer
#  order            :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  deadline         :datetime
#  access_token     :string(255)
#  indianio_token   :string(255)
#  progress_enabled :boolean          default(TRUE), not null
#

require 'csv'

class Series < ApplicationRecord
  enum visibility: { open: 0, hidden: 1, closed: 2 }

  belongs_to :course
  has_many :series_memberships, dependent: :destroy
  has_many :exercises, through: :series_memberships

  validates :name, presence: true
  validates :visibility, presence: true

  before_create :set_access_token

  scope :visible, -> { where(visibility: :open) }
  scope :with_deadline, -> { where.not(deadline: nil) }
  default_scope { order(order: :asc, id: :desc) }

  after_initialize do
    self.visibility ||= 'open'
  end

  def anchor
    "series-#{id}-#{name.parameterize}"
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
    value = false if ['0', 0, 'false'].include? value
    if indianio_token.nil? && value
      generate_token :indianio_token
    elsif !value
      self.indianio_token = nil
    end
  end

  def scoresheet
    sorted_users = course.enrolled_members.order('course_memberships.status ASC')
                         .order(permission: :asc)
                         .order(last_name: :asc, first_name: :asc)
    CSV.generate do |csv|
      csv << [I18n.t('courses.scoresheet.explanation')]
      csv << [User.human_attribute_name('first_name'), User.human_attribute_name('last_name'), User.human_attribute_name('username'), User.human_attribute_name('email'), name].concat(exercises.map(&:name))
      csv << ['Maximum', '', '', '', exercises.count].concat(exercises.map { 1 })
      latest_subs = Submission.where(user_id: sorted_users.map(&:id), course_id: course.id, exercise_id: exercises.map(&:id)).select('MAX(id) as id')
      latest_subs = latest_subs.before_deadline(deadline) unless deadline.nil?
      latest_subs = Submission.where(id: latest_subs.group(:user_id, :exercise_id), accepted: true).group(:user_id, :exercise_id).count
      sorted_users.each do |user|
        row = [user.first_name, user.last_name, user.username, user.email]
        succeeded_exercises = exercises.map { |ex| latest_subs[[user.id, ex.id]].present? ? 1 : 0 }
        row << succeeded_exercises.sum
        row.concat(succeeded_exercises)
        csv << row
      end
    end
  end

  def zip_solutions_for_user(user, with_info: false)
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

  def zip_solutions(with_info: false)
    filename = "#{name.parameterize}.zip"
    stringio = Zip::OutputStream.write_buffer do |zio|
      info = CSV.generate(force_quotes: true) do |csv|
        csv << %w[filename full_name id status submission_id name_en name_nl exercise_id]
        exercises.each do |ex|
          course.users.each do |u|
            submission = ex.last_submission(u, deadline, course)
            zio.put_next_entry("#{u.full_name}-#{u.id}/#{ex.file_name}")
            zio.write submission&.code
            csv << ["#{u.full_name}-#{u.id}/#{ex.file_name}", u.full_name, u.id, submission&.status, submission&.id, ex.name_en, ex.name_nl, ex.id]
          end
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

    self[type] = SecureRandom.urlsafe_base64(16).tr('1lL0oO', '')
  end

  private

  def set_access_token
    generate_token :access_token
  end
end
