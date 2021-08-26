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
#  description       :text(16777215)
#  visibility        :integer
#  registration      :integer
#  color             :integer
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

  belongs_to :institution, optional: true

  has_many :course_memberships, dependent: :destroy
  has_many :series, dependent: :destroy
  has_many :course_repositories, dependent: :destroy

  has_many :activities, -> { distinct }, through: :series
  has_many :series_memberships, through: :series

  has_many :activity_read_states, dependent: :destroy
  has_many :submissions, dependent: :nullify
  has_many :users, through: :course_memberships

  has_many :usable_repositories, through: :course_repositories, source: :repository

  has_many :course_labels, dependent: :destroy

  enum visibility: { visible_for_all: 0, visible_for_institution: 1, hidden: 2 }
  enum registration: { open_for_all: 0, open_for_institution: 1, closed: 2 }

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
           inverse_of: :course

  has_many :in_progress_questions,
           lambda {
             where question_state: :in_progress
           },
           class_name: 'Question',
           inverse_of: :course

  has_many :answered_questions,
           lambda {
             where question_state: :answered
           },
           class_name: 'Question',
           inverse_of: :course

  validates :name, presence: true
  validates :year, presence: true
  validate :should_have_institution_when_visible_for_institution
  validate :should_have_institution_when_open_for_institution

  scope :by_name, ->(name) { where('name LIKE ?', "%#{name}%") }
  scope :by_teacher, ->(teacher) { where('teacher LIKE ?', "%#{teacher}%") }
  scope :by_institution, ->(institution) { where(institution: institution) }
  default_scope { order(year: :desc, name: :asc) }

  token_generator :secret, unique: false, length: 5

  before_create :generate_secret

  # Default year & enum values
  after_initialize do |course|
    self.visibility ||= 'visible_for_all'
    self.registration ||= 'open_for_all'
    unless year
      now = Time.zone.now
      y = now.year
      y -= 1 if now.month < 7 # Before july
      course.year = "#{y}-#{y + 1}"
    end
  end

  def homepage_series(passed_series = 1)
    with_deadlines = series.select(&:open?).reject { |s| s.deadline.nil? }.sort_by(&:deadline)
    passed_deadlines = with_deadlines
                       .select { |s| s.deadline < Time.zone.now && s.deadline > Time.zone.now - 1.week }[-1 * passed_series, 1 * passed_series]
    future_deadlines = with_deadlines.select { |s| s.deadline > Time.zone.now }
    passed_deadlines.to_a + future_deadlines.to_a
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
    sorted_users = subscribed_members.order('course_memberships.status ASC')
                                     .order(permission: :asc)
                                     .order(last_name: :asc, first_name: :asc)

    hash = sorted_series.map { |s| [s, s.scoresheet] }.product(sorted_users).map do |series_info, user|
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
    end.to_h

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
    colors = %w[blue-grey indigo red purple teal orange pink brown deep-purple]
    colors[year.to_i % colors.size]
  end

  private

  def should_have_institution_when_visible_for_institution
    errors.add(:institution, 'should not be blank when only visible for institution') if visible_for_institution? && institution.blank?
  end

  def should_have_institution_when_open_for_institution
    errors.add(:institution, 'should not be blank when only open for institution') if open_for_institution? && institution.blank?
  end
end
