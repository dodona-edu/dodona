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
#  description       :text(65535)
#  visibility        :integer          default("visible")
#  registration      :integer          default("open")
#  correct_solutions :integer
#  color             :integer
#  teacher           :string(255)      default("")
#

require 'securerandom'
require 'csv'

class Course < ApplicationRecord
  has_many :course_memberships
  has_many :series
  has_many :course_repositories

  has_many :exercises, -> { distinct }, through: :series
  has_many :series_memberships, through: :series

  has_many :submissions
  has_many :users, through: :course_memberships

  has_many :usable_repositories, through: :course_repositories, source: :repository

  enum visibility: %i[visible hidden]
  enum registration: %i[open moderated closed]
  enum color: %i[red pink purple deep-purple indigo teal
                 orange brown blue-grey]

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

  scope :by_name, ->(name) { where('name LIKE ?', "%#{name}%")}
  default_scope { order(year: :desc, name: :asc) }

  before_create :generate_secret

  # Default year & enum values
  after_initialize do |course|
    self.visibility   ||= 'visible'
    self.registration ||= 'open'
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

  def invalidate_stats_cache
    update(correct_solutions: nil)
  end

  def correct_solutions_cached
    if correct_solutions.nil?
      self.correct_solutions = Submission.where(status: 'correct',
                                                course: self)
                                         .select(:exercise_id,
                                                 :user_id)
                                         .distinct
                                         .count
      save
    end
    correct_solutions
  end

  def average_progress
    avg = ((100 * correct_solutions_cached).to_d / (users.count * exercises.count).to_d)
    avg.nan? ? 0 : avg
  end

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

  def scoresheet(options = {})
    sorted_series = series.reverse
    sorted_users = users.order('course_memberships.status ASC')
                        .order(permission: :asc)
                        .order(last_name: :asc, first_name: :asc)
    CSV.generate(options) do |csv|
      csv << [I18n.t('courses.scoresheet.explanation')]
      csv << [User.human_attribute_name('first_name'), User.human_attribute_name('last_name'), User.human_attribute_name('username'), User.human_attribute_name('email')].concat(sorted_series.map(&:name))
      csv << ['Maximum', '', '', ''].concat(sorted_series.map { |s| s.exercises.count })
      sorted_users.each do |user|
        row = [user.first_name, user.last_name, user.username, user.email]
        sorted_series.each do |s|
          row << s.exercises.map { |ex| ex.accepted_for(user, s.deadline, self) }.count(true)
        end
        csv << row
      end
    end
  end

  def self.format_year year
    year.sub(/ ?- ?/, '–')
  end
end
