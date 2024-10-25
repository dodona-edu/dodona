# == Schema Information
#
# Table name: users
#
#  id                   :integer          not null, primary key
#  username             :string(255)
#  first_name           :string(255)
#  last_name            :string(255)
#  email                :string(255)
#  permission           :integer          default("student")
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  lang                 :string(255)      default("nl")
#  token                :string(255)
#  time_zone            :string(255)      default("Brussels")
#  institution_id       :bigint
#  search               :string(4096)
#  seen_at              :datetime
#  sign_in_at           :datetime
#  open_questions_count :integer          default(0), not null
#  theme                :integer          default("system"), not null
#

require 'securerandom'

class User < ApplicationRecord
  include Filterable
  include StringHelper
  include Cacheable
  include Tokenable
  include ActiveModel::Dirty

  ATTEMPTED_EXERCISES_CACHE_STRING = '/courses/%<course_id>s/user/%<id>s/attempted_exercises'.freeze
  CORRECT_EXERCISES_CACHE_STRING = '/courses/%<course_id>s/user/%<id>s/correct_exercises'.freeze

  enum :permission, { student: 0, staff: 1, zeus: 2 }
  enum :theme, { system: 0, light: 1, dark: 2 }

  belongs_to :institution, optional: true

  has_many :activity_read_states, dependent: :restrict_with_error
  has_many :submissions, dependent: :restrict_with_error

  has_many :api_tokens, dependent: :restrict_with_error
  has_many :course_memberships, dependent: :restrict_with_error
  has_many :repository_admins, dependent: :restrict_with_error
  has_many :courses, through: :course_memberships
  has_many :identities, dependent: :destroy, inverse_of: :user
  has_many :providers, through: :identities
  has_many :events, dependent: :restrict_with_error
  has_many :exports, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :evaluation_users, inverse_of: :user, dependent: :restrict_with_error
  has_one  :rights_request, dependent: :destroy
  has_many :announcement_views, dependent: :destroy

  has_many :subscribed_courses,
           lambda {
             where.not course_memberships:
                           { status: %i[pending unsubscribed] }
           },
           through: :course_memberships,
           source: :course

  has_many :favorite_courses,
           lambda {
             where.not course_memberships:
                           { status: %i[pending unsubscribed] }
             where course_memberships:
                       { favorite: true }
           },
           through: :course_memberships,
           source: :course

  has_many :administrating_courses,
           lambda {
             where course_memberships:
                       { status: :course_admin }
           },
           through: :course_memberships,
           source: :course

  has_many :enrolled_courses,
           lambda {
             where course_memberships:
                       { status: :student }
           },
           through: :course_memberships,
           source: :course

  has_many :pending_courses,
           lambda {
             where course_memberships:
                       { status: :pending }
           },
           through: :course_memberships,
           source: :course

  has_many :unsubscribed_courses,
           lambda {
             where course_memberships:
                       { status: :unsubscribed }
           },
           through: :course_memberships,
           source: :course

  has_many :repositories,
           through: :repository_admins,
           source: :repository
  has_many :draft_exercises,
           lambda {
             where activities:
                        { draft: true }
           },
           through: :repositories,
           source: :exercises

  has_many :annotations, dependent: :restrict_with_error
  has_many :questions, dependent: :restrict_with_error

  devise :omniauthable, omniauth_providers: %i[google_oauth2 lti office365 oidc saml smartschool surf elixir]

  validate :max_one_institution
  validate :provider_allows_blank_email

  token_generator :token

  before_save :set_token
  before_save :set_time_zone
  before_save :split_last_name, unless: :first_name?, if: :last_name?
  before_save :nullify_empty_username
  before_save :nullify_empty_email
  before_update :check_permission_change

  accepts_nested_attributes_for :identities, limit: 1

  scope :by_permission, ->(permission) { where(permission: permission) }
  scope :by_institution, ->(institution) { where(institution: institution) }

  scope :in_course, ->(course) { joins(:course_memberships).where(course_memberships: { course_id: course.id }) }
  scope :by_course_labels, ->(labels, course_id) { where(id: CourseMembership.where(course_id: course_id).by_course_labels(labels).select(:user_id)) }
  scope :at_least_one_started_in_series, ->(series) { where(id: Submission.where(course_id: series.course_id, exercise_id: series.exercises).select('DISTINCT(user_id)')) }
  scope :at_least_one_read_in_series, ->(series) { where(id: ActivityReadState.in_series(series).select('DISTINCT(user_id)')) }
  scope :at_least_one_started_in_course, ->(course) { where(id: Submission.where(course_id: course.id, exercise_id: course.exercises).select('DISTINCT(user_id)')) }
  scope :at_least_one_read_in_course, ->(course) { where(id: ActivityReadState.in_course(course).select('DISTINCT(user_id)')) }

  scope :order_by_status_in_course_and_name, ->(direction) { reorder 'course_memberships.status': direction, permission: direction == 'ASC' ? :desc : :asc, last_name: direction, first_name: direction }
  scope :order_by_exercise_submission_status_in_series, lambda { |direction, exercise, series|
    submissions = Submission.in_series(series).of_exercise(exercise)
    submissions = submissions.before_deadline(series.deadline) if series.deadline.present?
    submissions = submissions.group(:user_id).most_recent
    joins("LEFT JOIN (#{submissions.to_sql}) submissions ON submissions.user_id = users.id")
      .reorder 'submissions.status': direction
  }
  scope :order_by_submission_statuses_in_series, lambda { |direction, series|
    submissions = Submission.in_series(series)
    submissions = submissions.before_deadline(series.deadline) if series.deadline.present?
    submissions = submissions.group(:user_id, :exercise_id).most_recent.select(:user_id, :status)
    read_states = ActivityReadState.in_series(series)
    read_states = read_states.before_deadline(series.deadline) if series.deadline.present?
    read_states = read_states.select(:user_id, 'NULL AS status')
    # Create columns for each status with the count of submissions that have that status
    cols = Submission.statuses.map { |k, v| "COUNT(CASE WHEN status = #{v} #{'OR status is NULL' if k == 'correct'} THEN 1 END) AS #{k.parameterize(separator: '_')}" }
    combined_sql = "(SELECT user_id, #{cols.join(',')} FROM ((#{read_states.to_sql}) UNION ALL (#{submissions.to_sql})) AS c GROUP BY user_id)"
    # Order by those status columns
    joins("LEFT JOIN (#{combined_sql}) c ON c.user_id = users.id")
      .reorder Submission.statuses.keys.map { |k| "c.#{k.parameterize(separator: '_')} #{direction}" }.join(',')
  }
  scope :order_by_activity_read_state_in_series, lambda { |direction, content_page, series|
    read_states = ActivityReadState.in_series(series).of_content_page(content_page)
    read_states = read_states.before_deadline(series.deadline) if series.deadline.present?
    joins("LEFT JOIN (#{read_states.to_sql}) read_states ON read_states.user_id = users.id")
      .reorder 'read_states.id': direction
  }
  scope :order_by_solved_exercises_in_series, lambda { |direction, series|
    submissions = Submission.in_series(series)
    submissions = submissions.before_deadline(series.deadline) if series.deadline.present?
    submissions = submissions.group(:user_id, :exercise_id).most_recent.correct.select(:user_id)
    read_states = ActivityReadState.in_series(series)
    read_states = read_states.before_deadline(series.deadline) if series.deadline.present?
    read_states = read_states.select(:user_id)
    combined_sql = "(SELECT user_id, COUNT(*) AS count FROM ((#{read_states.to_sql}) UNION ALL (#{submissions.to_sql})) AS c GROUP BY user_id)"
    joins("LEFT JOIN #{combined_sql} c ON c.user_id = users.id")
      .reorder 'c.count': direction
  }
  scope :order_by_solved_exercises_in_course, lambda { |direction, course|
    # because the deadline can be different for each series and an activity can appear in multiple series
    # we need a subquery for each series
    combined_sql = course.series.map do |series|
      submissions = Submission.in_series(series)
      submissions = submissions.before_deadline(series.deadline) if series.deadline.present?
      submissions = submissions.group(:user_id, :exercise_id).most_recent.correct.select(:user_id)
      read_states = ActivityReadState.in_series(series)
      read_states = read_states.before_deadline(series.deadline) if series.deadline.present?
      read_states = read_states.select(:user_id)
      "(#{read_states.to_sql}) UNION ALL (#{submissions.to_sql})"
    end
    combined_sql = "(SELECT user_id, COUNT(*) AS count FROM (#{combined_sql.join(' UNION ALL ')}) AS c GROUP BY user_id)"
    joins("LEFT JOIN #{combined_sql} c ON c.user_id = users.id")
      .reorder 'c.count': direction
  }
  scope :order_by_progress, lambda { |direction, course = nil|
    submissions = Submission.judged
    submissions = submissions.in_course(course) if course.present?
    correct_exercises = submissions.correct.group(:user_id).select(:user_id, 'COUNT(distinct exercise_id) AS count')
    attempted_exercises = submissions.group(:user_id).select(:user_id, 'COUNT(distinct exercise_id) AS count')
    joins("LEFT JOIN (#{correct_exercises.to_sql}) correct ON correct.user_id = users.id")
      .joins("LEFT JOIN (#{attempted_exercises.to_sql}) attempted ON attempted.user_id = users.id")
      .reorder 'correct.count': direction, 'attempted.count': direction
  }

  def provider_allows_blank_email
    return if institution&.uses_lti? || institution&.uses_oidc? || institution&.uses_smartschool?

    errors.add(:email, 'should not be blank') if email.blank?
  end

  def max_one_institution
    errors.add(:institution, 'must be unique') if identities.map(&:provider).map(&:institution_id).uniq.count > 1
  end

  def full_name
    name = "#{first_name || ''} #{last_name || ''}"
    first_string_present name, 'n/a'
  end

  def pretty_email
    if first_name || last_name
      "#{full_name} <#{email}>"
    else
      email
    end
  end

  def first_name
    return self[:first_name] unless Current.demo_mode && Current.user != self

    Faker::Config.random = Random.new(id + Date.today.yday)
    Faker::Name.first_name
  end

  def last_name
    return self[:last_name] unless Current.demo_mode && Current.user != self

    Faker::Config.random = Random.new(id + Date.today.yday)
    Faker::Name.last_name
  end

  def username
    return self[:username] unless Current.demo_mode && Current.user != self

    (first_name[0] + last_name[0, 7]).downcase
  end

  def email
    return self[:email] unless Current.demo_mode && Current.user != self

    "#{first_name}.#{last_name}@dodona.be"
  end

  def short_name
    first_string_present username, first_name, full_name
  end

  def admin?
    staff? || zeus?
  end

  def course_admin?(course)
    zeus? || admin_of?(course)
  end

  def a_course_admin?
    admin? || administrating_courses.any?
  end

  def repository_admin?(repository)
    return true if zeus?

    @repository_admin ||= Set.new(repositories.pluck(:id))
    @repository_admin.include?(repository.id)
  end

  def a_repository_admin?
    zeus? || repositories.any?
  end

  def personal?
    institution.nil?
  end

  def institutional?
    institution.present?
  end

  def attempted_exercises(options)
    s = submissions.judged
    s = s.in_course(options[:course]) if options[:course].present?
    s.select('distinct exercise_id').count
  end

  invalidateable_instance_cacheable(:attempted_exercises,
                                    ->(this, options) { format(ATTEMPTED_EXERCISES_CACHE_STRING, course_id: options[:course].present? ? options[:course].id.to_s : 'global', id: this.id.to_s) })

  def correct_exercises(options)
    s = submissions.where(status: :correct)
    s = s.in_course(options[:course]) if options[:course].present?
    s.select('distinct exercise_id').count
  end

  invalidateable_instance_cacheable(:correct_exercises,
                                    ->(this, options) { format(CORRECT_EXERCISES_CACHE_STRING, course_id: options[:course].present? ? options[:course].id.to_s : 'global', id: this.id.to_s) })

  def unfinished_exercises(course = nil)
    attempted_exercises(course: course) - correct_exercises(course: course)
  end

  def recent_exercises(limit = 3)
    # If a user has submitted to a content page this will include `nil` values. So we compact to throw those away.
    submissions.group(:exercise_id).reorder('MAX(id) DESC').select('exercise_id').limit(limit).includes(:exercise).map(&:exercise).compact
  end

  def pending_series
    courses.map { |c| c.pending_series(self) }.flatten.sort_by(&:deadline)
  end

  def drawer_courses
    actual_memberships = course_memberships.includes(:course).to_a.select(&:subscribed?)
    return [] if actual_memberships.empty?

    favorites = actual_memberships.select(&:favorite)
    return favorites.map(&:course) if favorites.any?

    sorted_courses = actual_memberships.map(&:course).sort_by(&:year).reverse
    sorted_courses.select { |c| c.year == sorted_courses.first.year }
  end

  def member_of?(course)
    return false if course.blank?

    @member_of ||= Set.new(subscribed_courses.unscope(:order).pluck(:id))
    @member_of.include?(course.id)
  end

  def admin_of?(course)
    return false if course.blank?

    @admin_of ||= Set.new(administrating_courses.unscope(:order).pluck(:id))
    @admin_of.include?(course.id)
  end

  def membership_status_for(course)
    membership = CourseMembership.find_by(course: course, user: self)
    if membership
      membership.status
    else
      'no_membership'
    end
  end

  # Update the user using the data provided in the omniauth hash.
  def update_from_provider(auth_hash, auth_provider)
    tap do |user|
      user.username = auth_hash.info.username || auth_hash.uid
      user.email = auth_hash.info.email
      user.first_name = auth_hash.info.first_name
      user.last_name = auth_hash.info.last_name
      user.institution = auth_provider.institution if user.institution.nil?
      user.save
    end
  end

  def self.from_email_and_institution(email, institution_id)
    return nil if email.blank?

    find_by(email: email, institution_id: institution_id)
  end

  def self.from_username_and_institution(username, institution_id)
    return nil if username.blank?

    find_by(username: username, institution_id: institution_id)
  end

  def set_search
    self.search = "#{username || ''} #{first_name || ''} #{last_name || ''}"
  end

  # Be careful when using force institution. This expects the providers to be updated externally
  def merge_into(other, force: false, force_institution: false)
    errors.add(:merge, 'User belongs to different institution') if !force_institution && other.institution_id != institution_id && other.institution_id.present? && institution_id.present?
    errors.add(:merge, 'User has different permissions') if other.permission != permission && !force
    return false if errors.any?

    transaction do
      other.permission = permission if (permission == 'staff' && other.permission == 'student') ||
                                       (permission == 'zeus' && other.permission != 'zeus')

      other.institution_id = institution_id if other.institution_id.nil?

      identities.each do |i|
        if other.identities.find { |oi| oi.provider_id == i.provider_id }
          i.destroy!
        else
          i.update!(user: other)
        end
      end

      rights_request.update!(user: other) if !rights_request.nil? && other.permission == 'student' && other.rights_request.nil?

      course_memberships.each do |cm|
        other_cm = other.course_memberships.find { |ocm| ocm.course_id == cm.course_id }
        if other_cm.nil?
          cm.update!(user: other)
        elsif other_cm.status == cm.status ||
              other_cm.status == 'course_admin' ||
              (other_cm.status == 'student' && cm.status != 'course_admin') ||
              (other_cm.status == 'unsubscribed' && cm.status == 'pending')
          other_cm.update!(favorite: true) if cm.favorite
          cm.destroy!
        else
          cm.update!(favorite: true) if other_cm.favorite
          other_cm.destroy!
          cm.update!(user: other)
        end
      end

      submissions.each { |s| s.update!(user: other) }
      api_tokens.each { |at| at.update!(user: other) }
      events.each { |e| e.update!(user: other) }
      exports.each { |e| e.update!(user: other) }
      notifications.each { |n| n.update!(user: other) }
      annotations.each { |a| a.update!(user: other, last_updated_by_id: other.id) }
      questions.each { |q| q.update!(user: other) }

      evaluation_users.each do |eu|
        if other.evaluation_users.find { |oeu| oeu.evaluation_id == eu.evaluation_id }
          eu.destroy!
        else
          eu.update!(user: other)
        end
      end

      activity_read_states.each do |ars|
        if other.activity_read_states.find { |oars| oars.activity_id == ars.activity_id }
          ars.destroy!
        else
          ars.update!(user: other)
        end
      end

      repository_admins.each do |ra|
        if other.repository_admins.find { |ora| ora.repository_id == ra.repository_id }
          ra.destroy!
        else
          ra.update!(user: other)
        end
      end

      announcement_views.each do |av|
        if other.announcement_views.find { |oav| oav.announcement_id == av.announcement_id }
          av.destroy!
        else
          av.update!(user: other)
        end
      end

      reload
      destroy!
    end
  end

  def jump_back_in
    latest_submission = submissions.first
    return [] if latest_submission.nil?
    return [] if latest_submission.exercise.nil?

    # Don't give information about the exercise if the submission was within a course, but not within a visible series
    # This is to prevent students from seeing exercises that are not made public explicitly
    if latest_submission.course.present? && !latest_submission.series&.visible_to?(self)
      # Don't show complete courses
      return [] if latest_submission.course.incomplete_series(self).blank?

      return [{
        submission: nil,
        activity: nil,
        series: nil,
        course: latest_submission.course,
        text: I18n.t('pages.clickable_homepage_cards.course')
      }]
    end

    result = []
    unless latest_submission.accepted?
      # The last submission was wrong, continue working on it
      result << {
        submission: latest_submission,
        activity: latest_submission.exercise,
        series: latest_submission.series,
        course: latest_submission.course,
        text: I18n.t('pages.clickable_homepage_cards.last_submission')
      }
    end

    if latest_submission.series.present? && latest_submission.series.visible_to?(self)
      next_activity = latest_submission.series.next_activity(latest_submission.exercise)
      if next_activity.present?
        # start working on the next exercise, if that one was not accepted
        unless next_activity.accepted_for?(self, latest_submission.series)
          result << {
            submission: nil,
            activity: next_activity,
            series: latest_submission.series,
            course: latest_submission.course,
            text: result.empty? ? I18n.t('pages.clickable_homepage_cards.next_exercise_success') : I18n.t('pages.clickable_homepage_cards.next_exercise')
          }
        end

        if latest_submission.series.next_activity(next_activity).present? && !latest_submission.series.completed?(user: self)
          # there is another exercise after the next one and the series is not yet completed, so show the series
          result << {
            submission: nil,
            activity: nil,
            series: latest_submission.series,
            course: latest_submission.course,
            text: I18n.t('pages.clickable_homepage_cards.continue_series')
          }
        end
      end

      next_series = latest_submission.series.next
      if next_series.present? && next_series.visible_to?(self) && !next_series.completed?(user: self)
        # start working on the next series
        result << {
          submission: nil,
          activity: nil,
          series: next_series,
          course: latest_submission.course,
          text: result.empty? ? I18n.t('pages.clickable_homepage_cards.next_series_success') : I18n.t('pages.clickable_homepage_cards.next_series')
        }
      end
    end

    if latest_submission.course.present? && latest_submission.course.incomplete_series(self).present?
      # continue working on this course
      result << {
        submission: nil,
        activity: nil,
        series: nil,
        course: latest_submission.course,
        text: I18n.t('pages.clickable_homepage_cards.course')
      }
    end
    result
  end

  def open_questions?
    open_questions_count > 0
  end

  private

  def set_token
    if identities.present?
      self.token = nil
    elsif token.blank?
      generate_token
    end
  end

  def set_time_zone
    self.time_zone = 'Seoul' if email&.match?(/ghent.ac.kr$/)
  end

  def check_permission_change
    Event.create(event_type: :permission_change, user: self, message: "Granted #{permission}#{Current.user ? " by #{Current.user.full_name} (id: #{Current.user.id})" : ''}") if permission_changed?
  end

  def nullify_empty_email
    self.email = nil if email.blank?
  end

  def nullify_empty_username
    self.username = nil if username.blank?
  end

  def split_last_name
    parts = last_name.split(' ', 2)
    return unless parts.count == 2

    self.first_name = parts[0]
    self.last_name = parts[1]
  end
end
