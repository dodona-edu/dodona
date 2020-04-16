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
  include Cacheable
  include Tokenable

  USER_COMPLETED_CACHE_STRING = '/series/%<id>s/deadline/%<deadline>s/user/%<user_id>s/completed'.freeze
  USER_STARTED_CACHE_STRING = '/series/%<id>s/user/%<user_id>s/started'.freeze
  USER_WRONG_CACHE_STRING = '/series/%<id>s/user/%<user_id>s/wrong'.freeze

  enum visibility: {open: 0, hidden: 1, closed: 2}

  belongs_to :course
  has_many :series_memberships, dependent: :destroy
  has_many :exercises, through: :series_memberships
  has_many :exercise_statuses

  validates :name, presence: true
  validates :visibility, presence: true

  token_generator :access_token, length: 5
  token_generator :indianio_token

  before_create :generate_access_token
  before_save :regenerate_exercise_tokens, if: :visibility_changed?
  after_save :invalidate_exercise_statuses

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

  # @param [Object] options {deadline (optional), user}
  def completed?(options)
    if options[:deadline]
      exercises.all? { |e| e.exercise_status_for(options[:user], self).accepted_before_deadline? }
    else
      exercises.all? { |e| e.exercise_status_for(options[:user], self).accepted? }
    end
  end

  invalidateable_instance_cacheable(:completed?,
                                    ->(this, options) { format(USER_COMPLETED_CACHE_STRING, user_id: options[:user].id.to_s, deadline: options[:deadline] ? options[:deadline].to_s : 'global', id: this.id.to_s) })

  def completed_before_deadline?(user)
    completed?(deadline: deadline, user: user)
  end

  def missed_deadline?(user)
    return false unless deadline&.past?

    !completed_before_deadline?(user)
  end

  def started?(options)
    exercises.any? { |e| e.exercise_status_for(options[:user], self).started? }
  end

  invalidateable_instance_cacheable(:started?,
                                    ->(this, options) { format(USER_STARTED_CACHE_STRING, user_id: options[:user].id.to_s, id: this.id.to_s) })

  def wrong?(options)
    exercises.any? { |e| e.exercise_status_for(options[:user], self).wrong? }
  end

  invalidateable_instance_cacheable(:wrong?,
                                    ->(this, options) { format(USER_WRONG_CACHE_STRING, user_id: options[:user].id.to_s, id: this.id.to_s) })

  def indianio_support
    indianio_token.present?
  end

  def indianio_support?
    indianio_support
  end

  def indianio_support=(value)
    value = false if ['0', 0, 'false'].include? value
    if indianio_token.nil? && value
      generate_indianio_token
    elsif !value
      self.indianio_token = nil
    end
  end

  def scoresheet
    users = course.subscribed_members
                .order('course_memberships.status ASC')
                .order(permission: :asc)
                .order(last_name: :asc, first_name: :asc)

    submission_hash = Submission.in_series(self).where(user: users)
    submission_hash = submission_hash.before_deadline(deadline) if deadline.present?
    submission_hash = submission_hash.group(%i[user_id exercise_id]).most_recent.index_by { |s| [s.user_id, s.exercise_id] }

    {
        users: users,
        exercises: exercises,
        submissions: submission_hash
    }
  end

  def regenerate_exercise_tokens
    exercises.each do |exercise|
      exercise.generate_access_token
      exercise.save
    end
  end

  def invalidate_exercise_statuses
    exercise_statuses.destroy_all
  end
end
