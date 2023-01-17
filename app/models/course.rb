# == Schema Information
#
# Table name: courses
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  year              :string(255)
#  secret            :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  description       :text(4294967295)
#  visibility        :integer          default("visible_for_all")
#  registration      :integer          default("open_for_institutional_users")
#  teacher           :string(255)
#  institution_id    :bigint
#  search            :string(4096)
#  moderated         :boolean          default(FALSE), not null
#  enabled_questions :boolean          default(TRUE), not null
#  featured          :boolean          default(FALSE), not null
#

require 'securerandom'
require 'csv'

class Course < ApplicationRecord
  include Filterable
  include Cacheable
  include Tokenable
  include ActionView::Helpers::SanitizeHelper

  SUBSCRIBED_MEMBERS_COUNT_CACHE_STRING = '/courses/%<id>d/subscribed_members_count'.freeze
  ACTIVITIES_COUNT_CACHE_STRING = '/courses/%<id>d/activities_count'.freeze
  CONTENT_PAGES_COUNT_CACHE_STRING = '/courses/%<id>d/content_pages_count'.freeze
  EXERCISES_COUNT_CACHE_STRING = '/courses/%<id>d/exercises_count'.freeze
  CORRECT_SOLUTIONS_CACHE_STRING = '/courses/%<id>d/correct_solutions'.freeze

  before_create :generate_secret
  before_destroy :nullify_submissions

  belongs_to :institution, optional: true

  has_many :course_memberships, dependent: :destroy
  has_many :series, dependent: :destroy
  has_many :course_repositories, dependent: :destroy

  has_many :activities, -> { distinct }, through: :series
  has_many :series_memberships, through: :series

  has_many :activity_read_states, dependent: :destroy
  has_many :submissions, dependent: :restrict_with_error
  has_many :users, through: :course_memberships

  has_many :usable_repositories, through: :course_repositories, source: :repository

  has_many :course_labels, dependent: :destroy

  enum visibility: { visible_for_all: 0, visible_for_institution: 1, hidden: 2 }
  enum registration: { open_for_all: 3, open_for_institutional_users: 0, open_for_institution: 1, closed: 2 }

  # TODO: Remove and use activities?
  has_many :content_pages,
           lambda {
             where activities: { type: ContentPage.name }
           },
           through: :series_memberships,
           source: :activity

  # TODO: Remove and use activities?
  has_many :exercises,
           lambda {
             where activities: { type: Exercise.name }
           },
           through: :series_memberships,
           source: :activity

  has_many :accessible_activities,
           lambda {
             where(series: { visibility: %i[open hidden] }).distinct
           },
           through: :series,
           source: :activities

  has_many :visible_activities,
           lambda {
             where(series: { visibility: %i[open] }).distinct
           },
           through: :series,
           source: :activities

  has_many :subscribed_members,
           lambda {
             where.not course_memberships:
                           { status: %i[pending unsubscribed] }
           },
           through: :course_memberships,
           source: :user

  has_many :administrating_members,
           lambda {
             where course_memberships:
                       { status: :course_admin }
           },
           through: :course_memberships,
           source: :user

  has_many :enrolled_members,
           lambda {
             where course_memberships:
                       { status: :student }
           },
           through: :course_memberships,
           source: :user

  has_many :pending_members,
           lambda {
             where course_memberships:
                       { status: :pending }
           },
           through: :course_memberships,
           source: :user

  has_many :unsubscribed_members,
           lambda {
             where course_memberships:
                       { status: :unsubscribed }
           },
           through: :course_memberships,
           source: :user

  has_many :annotations, dependent: :restrict_with_error
  has_many :questions, dependent: :restrict_with_error
  has_many :unanswered_questions,
           lambda {
             where question_state: :unanswered
           },
           class_name: 'Question',
           inverse_of: :course,
           dependent: :restrict_with_error

  has_many :in_progress_questions,
           lambda {
             where question_state: :in_progress
           },
           class_name: 'Question',
           inverse_of: :course,
           dependent: :restrict_with_error

  has_many :answered_questions,
           lambda {
             where question_state: :answered
           },
           class_name: 'Question',
           inverse_of: :course,
           dependent: :restrict_with_error

  has_many :evaluations, through: :series, class_name: 'Evaluation'
  has_many :feedbacks, through: :evaluations, class_name: 'Feedback'

  validates :name, presence: true
  validates :year, presence: true
  validate :should_have_institution_when_visible_for_institution
  validate :should_have_institution_when_open_for_institution

  scope :by_name, ->(name) { where('name LIKE ?', "%#{name}%") }
  scope :by_teacher, ->(teacher) { where('teacher LIKE ?', "%#{teacher}%") }
  scope :by_institution, ->(institution) { where(institution: institution) }
  scope :can_register, lambda { |user|
    if user&.institutional?
      where(registration: %i[open_for_all open_for_institutional_users])
        .or(where(registration: :open_for_institution, institution_id: user.institution_id))
        .or(where(id: user.subscribed_courses.pluck(:id)))
    else
      where(registration: :open_for_all)
        .or(where(id: user&.subscribed_courses&.pluck(:id)))
    end
  }
  default_scope { order(year: :desc, name: :asc) }

  token_generator :secret, unique: false, length: 5

  # Default year & enum values
  after_initialize do |course|
    self.visibility ||= 'visible_for_all'
    self.registration ||= 'open_for_institutional_users'
    unless year
      now = Time.zone.now
      y = now.year
      y -= 1 if now.month < 7 # Before july
      course.year = "#{y}-#{y + 1}"
    end
  end

  def homepage_series(passed_series = 1)
    with_deadlines = series
    with_deadlines = with_deadlines.visible unless Current.user&.course_admin?(self)
    with_deadlines = with_deadlines.reject { |s| s.deadline.nil? }.sort_by(&:deadline)
    passed_deadlines = with_deadlines
                       .select { |s| s.deadline < Time.zone.now && s.deadline > 1.week.ago }[-1 * passed_series, 1 * passed_series]
    future_deadlines = with_deadlines.select { |s| s.deadline > Time.zone.now }
    passed_deadlines.to_a + future_deadlines.to_a
  end

  def series_being_worked_on(limit = 3, exclude = [])
    return [] if limit < 1

    candidates = series.where.not(id: exclude)
    candidates = candidates.visible unless Current.user&.course_admin?(self)
    result = ActivityStatus
             .joins("JOIN (#{ActivityStatus
                                 .where(series: candidates, started: true)
                                 .group(:user_id)
                                 .select('MAX(last_submission_id) as m').to_sql}) AS ls ON ls.m = activity_statuses.last_submission_id")
             .where(series: candidates, started: true)
             .group(:series_id)
             .order(Arel.sql('COUNT(*) DESC'))
             .limit(1)
             .map(&:series)
    result += [candidates.first] if result.empty? && candidates.any?
    result += series_being_worked_on(limit - 1, exclude + result)
    result
  end

  def homepage_admin_notifications
    return unless Current.user&.course_admin?(self)

    result = []
    if unanswered_questions.count > 0
      result << {
        title: I18n.t('pages.course_card.unanswered-questions', count: unanswered_questions.count),
        link: Rails.application.routes.url_helpers.questions_course_path(I18n.locale, self),
        icon: 'mdi-account-question',
        subtitle: I18n.t('pages.course_card.unanswered-questions-subtitle', count: unanswered_questions.count)
      }
    end

    if pending_members.count > 0
      result << {
        title: I18n.t('pages.course_card.pending-members', count: pending_members.count),
        link: Rails.application.routes.url_helpers.course_members_path(I18n.locale, self),
        icon: 'mdi-account-clock',
        subtitle: I18n.t('pages.course_card.pending-members-subtitle', count: pending_members.count)
      }
    end

    if feedbacks.incomplete.count > 0
      linked_feedback = feedbacks.incomplete.first
      result << {
        title: I18n.t('pages.course_card.incomplete-feedbacks', count: feedbacks.incomplete.count),
        link: Rails.application.routes.url_helpers.evaluation_feedback_path(I18n.locale, linked_feedback.evaluation, linked_feedback),
        icon: 'mdi-comment-multiple-outline',
        subtitle: I18n.t('pages.course_card.incomplete-feedbacks-subtitle', count: feedbacks.incomplete.count)
      }
    end

    result
  end

  def homepage_activities(user, limit = 3)
    result = []
    incomplete_activities = series.visible.joins(:activities) # all activities in visible series
                                  .joins("LEFT JOIN activity_statuses ON activities.id = activity_statuses.activity_id AND series.id = activity_statuses.series_id AND activity_statuses.user_id = #{user.id}")
                                  .where('activity_statuses.accepted IS NULL OR activity_statuses.accepted = false') # filter out completed activities
                                  .reorder('series.order': :asc, 'series.id': :desc, 'series_memberships.order': :asc, 'series_memberships.id': :asc)

    # try to find the latest activity by the user in this course
    latest_activity_status = ActivityStatus.where(user: user, series: series.visible, started: true).order('last_submission_id DESC').limit(1).first
    if latest_activity_status.present?
      series = latest_activity_status.series
      series_membership = SeriesMembership.find_by(series: series, activity: latest_activity_status.activity)

      if series_membership.present?
        # first list only activities after or equal to the last worked on activity
        result += incomplete_activities
                  .where('series.order > ? OR (series.order = ? AND series.id < ?) OR (series.order = ? AND series.id = ? AND (series_memberships.order >= ? OR series_memberships.id >= ?))', series.order, series.order, series.id, series.order, series.id, series_membership.order, series_membership.id)
                  .limit(limit)
                  .pluck('series.id', 'activities.id', 'activity_statuses.last_submission_id')

      end
    end

    # if no activity was found or the limit is not reached, add more activities starting from the beginning of the course
    if result.length < limit
      result += incomplete_activities
                .limit(limit - result.length)
                .pluck('series.id', 'activities.id', 'activity_statuses.last_submission_id')
    end

    # Map the ids to the actual objects
    result = result.map do |a|
      {
        series: Series.find(a[0]),
        activity: Activity.find(a[1]),
        submission: a[2].present? ? Submission.find(a[2]) : nil
      }
    end

    # We could have duplicates when only few unsolved activities are left
    result.uniq { |a| a[:activity] }
  end

  def pending_series(user)
    series.visible.select { |s| s.pending? && !s.completed?(user: user) }
  end

  def incomplete_series(user)
    series.visible.reject { |s| s.completed?(user: user) }
  end

  def formatted_year
    Course.format_year year
  end

  def formatted_attribution
    result = teacher || ''
    result += ' · ' if teacher.present? && institution&.name.present?
    result + (institution&.name || '')
  end

  def secret_required?(user = nil)
    return false if visible_for_all?
    return false if visible_for_institution? && user&.institution == institution

    true
  end

  def all_activities_accessible?
    activities.where(access: :private).where.not(repository_id: usable_repositories).count.zero?
  end

  def open_for_user?(user)
    open_for_all? || (open_for_institution? && institution == user&.institution) || (open_for_institutional_users? && user&.institutional?)
  end

  def invalidate_subscribed_members_count_cache
    Rails.cache.delete(format(SUBSCRIBED_MEMBERS_COUNT_CACHE_STRING, id: id))
  end

  def subscribed_members_count
    Rails.cache.fetch(format(SUBSCRIBED_MEMBERS_COUNT_CACHE_STRING, id: id)) do
      subscribed_members.count
    end
  end

  def activities_count
    Rails.cache.fetch(format(ACTIVITIES_COUNT_CACHE_STRING, id: id)) do
      activities.count
    end
  end

  def content_pages_count
    Rails.cache.fetch(format(CONTENT_PAGES_COUNT_CACHE_STRING, id: id)) do
      content_pages.count
    end
  end

  def exercises_count
    Rails.cache.fetch(format(EXERCISES_COUNT_CACHE_STRING, id: id)) do
      exercises.count
    end
  end

  def invalidate_activities_count_cache
    Rails.cache.delete(format(ACTIVITIES_COUNT_CACHE_STRING, id: id))
    Rails.cache.delete(format(CONTENT_PAGES_COUNT_CACHE_STRING, id: id))
    Rails.cache.delete(format(EXERCISES_COUNT_CACHE_STRING, id: id))
  end

  def correct_solutions(_options = {})
    Submission.where(status: 'correct', course: self)
              .select(:exercise_id, :user_id)
              .distinct
              .count
  end

  invalidateable_instance_cacheable(:correct_solutions, ->(this, _options) { format(CORRECT_SOLUTIONS_CACHE_STRING, id: this.id) })

  def pending_memberships
    CourseMembership.where(course_id: id,
                           status: :pending)
  end

  def accept_all_pending
    pending_memberships.update(status: :student)
  end

  def decline_all_pending
    pending_memberships.each do |cm|
      if Submission.where(user: cm.user, course: cm.course).empty?
        cm.delete
      else
        cm.update(status: :unsubscribed)
      end
    end
  end

  def scoresheet
    sorted_series = series
    sorted_users = subscribed_members.order_by_status_in_course_and_name 'ASC'

    hash = sorted_series.map { |s| [s, s.scoresheet] }.product(sorted_users).to_h do |series_info, user|
      scores = series_info[1]
      data = {
        accepted: series_info[0].activities.count do |a|
          if a.exercise?
            scores[:submissions][[user.id, a.id]]&.accepted
          elsif a.content_page?
            scores[:read_states][[user.id, a.id]].present?
          end
        end,
        started: series_info[0].activities.count do |a|
          if a.exercise?
            scores[:submissions][[user.id, a.id]].present?
          elsif a.content_page?
            scores[:read_states][[user.id, a.id]].present?
          end
        end
      }
      [[user.id, series_info[0].id], data]
    end

    {
      users: sorted_users,
      series: sorted_series,
      hash: hash
    }
  end

  def labels_csv
    sorted_course_memberships = course_memberships
                                .where.not(status: %i[unsubscribed pending])
                                .includes(:user)
                                .order(status: :asc)
                                .order(Arel.sql('users.permission ASC'))
                                .order(Arel.sql('users.last_name ASC'), Arel.sql('users.first_name ASC'))
    data = CSV.generate(force_quotes: true) do |csv|
      csv << %w[id username last_name first_name email labels]
      sorted_course_memberships.each do |cm|
        csv << [cm.user.id, cm.user.username, cm.user.last_name, cm.user.first_name, cm.user.email, cm.course_labels.map(&:name).join(';')]
      end
    end
    { filename: "#{name}-users-labels.csv", data: data }
  end

  def self.format_year(year)
    year.sub(/ ?- ?/, '–')
  end

  def set_search
    self.search = "#{teacher || ''} #{name || ''} #{year || ''}"
  end

  def color
    colors = %w[blue-gray orange cyan purple teal pink indigo brown deep-purple]
    colors[year.to_i % colors.size]
  end

  def activity_count
    series.visible.map(&:activity_count).sum
  end

  def completed_activity_count(user)
    ActivityStatus.where(accepted: true, user: user, series: series.visible).count
  end

  def started_activity_count(user)
    ActivityStatus.where(started: true, user: user, series: series.visible).count
  end

  private

  def nullify_submissions
    # We can't use rails' `dependent: :nullify`, since this skips the
    # submission's callbacks
    submissions.each { |s| s.update(course_id: nil) }
    # Because we update the submissions above, we need to make sure
    # this object knows it doesn't have submissions anymore, otherwise
    # the course isn't actually removed
    reload
  end

  def should_have_institution_when_visible_for_institution
    errors.add(:institution, 'should not be blank when only visible for institution') if visible_for_institution? && institution.blank?
  end

  def should_have_institution_when_open_for_institution
    errors.add(:institution, 'should not be blank when only open for institution') if open_for_institution? && institution.blank?
  end
end
