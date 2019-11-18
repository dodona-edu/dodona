# == Schema Information
#
# Table name: series
#
#  id                :integer          not null, primary key
#  course_id         :integer
#  name              :string(255)
#  description       :text(65535)
#  visibility        :integer
#  order             :integer          default(0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  deadline          :datetime
#  access_token      :string(255)
#  indianio_token    :string(255)
#  progress_enabled  :boolean          default(TRUE), not null
#  exercises_visible :boolean          default(TRUE), not null
#

require 'csv'

class Series < ApplicationRecord
  include ActionView::Helpers::SanitizeHelper

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
      csv << [I18n.t('series.scoresheet.explanation')]
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

  def generate_token(type)
    raise 'unknown token type' unless %i[indianio_token access_token].include? type

    self[type] = SecureRandom.urlsafe_base64(16).tr('1lL0oO', '')
  end

  private

  def set_access_token
    generate_token :access_token
  end
end
