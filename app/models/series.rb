# == Schema Information
#
# Table name: series
#
#  id                 :integer          not null, primary key
#  course_id          :integer
#  name               :string(255)
#  description        :text(16777215)
#  visibility         :integer
#  order              :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  deadline           :datetime
#  access_token       :string(255)
#  indianio_token     :string(255)
#  progress_enabled   :boolean          default(TRUE), not null
#  activities_visible :boolean          default(TRUE), not null
#  activities_count   :integer
#

require 'csv'

class Series < ApplicationRecord
  include ActionView::Helpers::SanitizeHelper
  include Cacheable
  include Tokenable

  USER_COMPLETED_CACHE_STRING = '/series/%<id>s/user/%<user_id>s/completed/%<updated_at>s/%<deadline>s'.freeze
  USER_STARTED_CACHE_STRING = '/series/%<id>s/user/%<user_id>s/started/%<updated_at>s'.freeze
  USER_WRONG_CACHE_STRING = '/series/%<id>s/user/%<user_id>s/wrong/%<updated_at>s'.freeze
  PLAGIARISM_EXPORT_OPTIONS = { all_students: false, group_by: 'exercise', only_last_submission: true, with_info: true, with_labels: true }.freeze

  enum visibility: { open: 0, hidden: 1, closed: 2 }

  before_save :regenerate_activity_tokens, if: :visibility_changed?
  before_create :generate_access_token
  after_save :invalidate_activity_statuses, if: :saved_change_to_deadline?

  belongs_to :course
  has_many :series_memberships, dependent: :destroy
  has_many :activities, through: :series_memberships
  has_many :activity_statuses, dependent: :destroy

  has_one :evaluation, dependent: :destroy

  validates :name, presence: true
  validates :visibility, presence: true

  token_generator :access_token, length: 5
  token_generator :indianio_token

  scope :visible, -> { where(visibility: :open) }
  scope :with_deadline, -> { where.not(deadline: nil) }
  default_scope { order(order: :asc, id: :desc) }

  has_many :content_pages,
           lambda {
             where activities: { type: ContentPage.name }
           },
           through: :series_memberships,
           source: :activity

  has_many :exercises,
           lambda {
             where activities: { type: Exercise.name }
           },
           through: :series_memberships,
           source: :activity

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
    ActivityStatus.add_status_for_user_and_series(options[:user], self)
    if options[:deadline]
      activities.all? { |a| a.accepted_before_deadline_for?(options[:user], self) }
    else
      activities.all? { |a| a.accepted_for?(options[:user], self) }
    end
  end

  invalidateable_instance_cacheable(:completed?,
                                    ->(this, options) { format(USER_COMPLETED_CACHE_STRING, user_id: options[:user].id.to_s, id: this.id.to_s, updated_at: this.updated_at.to_f.to_s, deadline: options[:deadline].present?.to_s) })

  def completed_before_deadline?(user)
    completed?(deadline: deadline, user: user)
  end

  def missed_deadline?(user)
    return false unless deadline&.past?

    !completed_before_deadline?(user)
  end

  def started?(options)
    activities.any? { |a| a.started_for?(options[:user], self) }
  end

  invalidateable_instance_cacheable(:started?,
                                    ->(this, options) { format(USER_STARTED_CACHE_STRING, user_id: options[:user].id.to_s, id: this.id.to_s, updated_at: this.updated_at.to_f.to_s) })

  def wrong?(options)
    activities.any? { |a| a.wrong_for?(options[:user], self) }
  end

  invalidateable_instance_cacheable(:wrong?,
                                    ->(this, options) { format(USER_WRONG_CACHE_STRING, user_id: options[:user].id.to_s, id: this.id.to_s, updated_at: this.updated_at.to_f.to_s) })

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

  def activity_count
    activities_count || series_memberships.size
  end

  def scoresheet
    users = course.subscribed_members
                  .order('course_memberships.status ASC')
                  .order(permission: :asc)
                  .order(last_name: :asc, first_name: :asc)

    submission_hash = Submission.in_series(self).where(user: users)
    submission_hash = submission_hash.before_deadline(deadline) if deadline.present?
    submission_hash = submission_hash.group(%i[user_id exercise_id]).most_recent.index_by { |s| [s.user_id, s.exercise_id] }

    read_state_hash = ActivityReadState.in_series(self).where(user: users)
    read_state_hash = read_state_hash.before_deadline(deadline) if deadline.present?
    read_state_hash = read_state_hash.group(%i[user_id activity_id]).index_by { |s| [s.user_id, s.activity_id] }

    {
      users: users,
      activities: activities,
      read_states: read_state_hash,
      submissions: submission_hash
    }
  end

  def regenerate_activity_tokens
    activities.each do |activity|
      activity.generate_access_token
      activity.save
    end
  end

  def invalidate_activity_statuses
    ActivityStatus.delete_by(series: self)
  end

  def invalidate_caches(user)
    # Delete all caches for this series.
    invalidate_completed?(user: user)
    invalidate_completed?(user: user, deadline: deadline) if deadline.present?
    invalidate_started?(user: user)
    invalidate_wrong?(user: user)
  end

  def plagiarism_check_delayed(exercises, teacher)
    delay(queue: 'exports').plagiarism_check(exercises, teacher)
  end

  private

  def plagiarism_check(exercises, teacher)
    export = Export.create(user: teacher)
                   .make_archive(self, exercises, nil, PLAGIARISM_EXPORT_OPTIONS)
  end

  def push_export(export)

  end
end
