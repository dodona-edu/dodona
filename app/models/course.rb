# == Schema Information
#
# Table name: courses
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  year           :string(255)
#  secret         :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  description    :text(65535)
#  visibility     :integer          default("visible_for_all")
#  registration   :integer          default("open_for_all")
#  color          :integer
#  teacher        :string(255)      default("")
#  institution_id :bigint
#  search         :string(4096)
#  moderated      :boolean          default(FALSE), not null
#

require 'securerandom'
require 'csv'

class Course < ApplicationRecord
  include Filterable
  include Cacheable

  SUBSCRIBED_MEMBERS_COUNT_CACHE_STRING = '/courses/%{id}/subscribed_members_count'.freeze
  EXERCISES_COUNT_CACHE_STRING = '/courses/%{id}/exercises_count'.freeze
  CORRECT_SOLUTIONS_CACHE_STRING = '/courses/%{id}/correct_solutions'.freeze

  belongs_to :institution, optional: true

  has_many :course_memberships, dependent: :restrict_with_error
  has_many :series, dependent: :restrict_with_error
  has_many :course_repositories, dependent: :restrict_with_error

  has_many :exercises, -> { distinct }, through: :series
  has_many :series_memberships, through: :series

  has_many :submissions, dependent: :restrict_with_error
  has_many :users, through: :course_memberships

  has_many :usable_repositories, through: :course_repositories, source: :repository

  has_many :course_labels, dependent: :destroy

  enum visibility: { visible_for_all: 0, visible_for_institution: 1, hidden: 2 }
  enum registration: { open_for_all: 0, open_for_institution: 1, closed: 2 }
  enum color: { red: 0, pink: 1, purple: 2, "deep-purple": 3, indigo: 4, teal: 5, orange: 6, brown: 7, "blue-grey": 8 }

  has_many :visible_exercises,
           lambda {
             where(series: { visibility: %i[open hidden] }).distinct
           },
           through: :series,
           source: :exercises

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

  validates :name, presence: true
  validates :year, presence: true
  validate :should_have_institution_when_visible_for_institution
  validate :should_have_institution_when_open_for_institution

  scope :by_name, ->(name) { where('name LIKE ?', "%#{name}%") }
  scope :by_teacher, ->(teacher) { where('teacher LIKE ?', "%#{teacher}%") }
  scope :by_institution, ->(institution) { where(institution: [institution, nil]) }
  default_scope { order(year: :desc, name: :asc) }

  before_create :generate_secret

  # Default year & enum values
  after_initialize do |course|
    self.visibility ||= 'visible_for_all'
    self.registration ||= 'open_for_all'
    self.color ||= Course.colors.keys.sample
    unless year
      now = Time.zone.now
      y = now.year
      y -= 1 if now.month < 7 # Before july
      course.year = "#{y}-#{y + 1}"
    end
  end

  def homepage_series(passed_series = 1)
    with_deadlines = series.visible.with_deadline.sort_by(&:deadline)
    passed_deadlines = with_deadlines
                       .select { |s| s.deadline < Time.zone.now && s.deadline > Time.zone.now - 1.week }[-1 * passed_series, 1 * passed_series]
    future_deadlines = with_deadlines.select { |s| s.deadline > Time.zone.now }
    passed_deadlines.to_a + future_deadlines.to_a
  end

  def pending_series(user)
    series.visible.select { |s| s.pending? && !s.completed?(user) }
  end

  def incomplete_series(user)
    series.visible.reject { |s| s.completed?(user) }
  end

  def formatted_year
    Course.format_year year
  end

  def generate_secret
    self.secret = SecureRandom.urlsafe_base64(5)
  end

  def invalidate_subscribed_members_count_cache
    Rails.cache.delete(format(SUBSCRIBED_MEMBERS_COUNT_CACHE_STRING, id: id))
  end

  def subscribed_members_count
    Rails.cache.fetch(format(SUBSCRIBED_MEMBERS_COUNT_CACHE_STRING, id: id)) do
      subscribed_members.count
    end
  end

  def invalidate_exercises_count_cache
    Rails.cache.delete(format(EXERCISES_COUNT_CACHE_STRING, id: id))
  end

  def exercises_count
    Rails.cache.fetch(format(EXERCISES_COUNT_CACHE_STRING, id: id)) do
      exercises.count
    end
  end

  def correct_solutions(_options = {})
    Submission.where(status: 'correct', course: self)
              .select(:exercise_id, :user_id)
              .distinct
              .count
  end

  create_cacheable(:correct_solutions, ->(this, _options) { format(CORRECT_SOLUTIONS_CACHE_STRING, id: this.id) })

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

  private

  def should_have_institution_when_visible_for_institution
    errors.add(:institution, 'should not be blank when only visible for institution') if visible_for_institution? && institution.blank?
  end

  def should_have_institution_when_open_for_institution
    errors.add(:institution, 'should not be blank when only open for institution') if open_for_institution? && institution.blank?
  end
end
