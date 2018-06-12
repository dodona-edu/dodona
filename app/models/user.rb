# == Schema Information
#
# Table name: users
#
#  id             :integer          not null, primary key
#  username       :string(255)
#  ugent_id       :string(255)
#  first_name     :string(255)
#  last_name      :string(255)
#  email          :string(255)
#  permission     :integer          default("student")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  lang           :string(255)      default("nl")
#  token          :string(255)
#  time_zone      :string(255)      default("Brussels")
#  institution_id :integer
#  provider       :string(255)
#

require 'securerandom'

class User < ApplicationRecord
  include StringHelper
  PHOTOS_LOCATION = Rails.root.join('data', 'user_photos').freeze

  enum permission: %i[student staff zeus]

  belongs_to :institution, optional: true

  has_many :api_tokens
  has_many :submissions
  has_many :course_memberships
  has_many :courses, through: :course_memberships

  has_many :subscribed_courses,
           lambda {
             where.not course_memberships:
                { status: %i[pending unsubscribed] }
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

  devise :saml_authenticatable
  devise :omniauthable, omniauth_providers: %i[smartschool office365]

  validates :username, uniqueness: { case_sensitive: false, allow_blank: true, scope: :institution }
  validates :email, uniqueness: { case_sensitive: false, allow_blank: true }


  before_save :set_token
  before_save :set_time_zone

  scope :by_permission, ->(permission) { where(permission: permission) }
  scope :by_name, ->(name) { where('username LIKE ? OR first_name LIKE ? OR last_name LIKE ?', "%#{name}%", "%#{name}%", "%#{name}%") }

  scope :in_course, ->(course) { joins(:course_memberships).where('course_memberships.course_id = ?', course.id) }

  def full_name
    name = (first_name || '') + ' ' + (last_name || '')
    first_string_present name, 'n/a'
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

  def photo
    photo = PHOTOS_LOCATION.join((ugent_id || '') + '.jpg')
    photo if File.file? photo
  end

  def attempted_exercises(course = nil)
    s = submissions
    s = s.in_course(course) if course
    s.select('distinct exercise_id').count
  end

  def correct_exercises(course = nil)
    s = submissions
    s = s.in_course(course) if course
    s.select('distinct exercise_id').where(status: :correct).count
  end

  def unfinished_exercises(course = nil)
    attempted_exercises(course) - correct_exercises(course)
  end

  def recent_exercises(limit = 3)
    submissions.select('distinct exercise_id').limit(limit).map(&:exercise)
  end

  def pending_series
    courses.map { |c| c.pending_series(self) }.flatten.sort_by(&:deadline)
  end

  def homepage_series
    subscribed_courses.map { |c| c.homepage_series(0) }.flatten.sort_by(&:deadline)
  end

  def current_ay_courses
    return [] if subscribed_courses.empty?
    subscribed_courses.group_by(&:year).first.second
  end

  def member_of?(course)
    subscribed_courses.include? course
  end

  def admin_of?(course)
    administrating_courses.include?(course)
  end

  def membership_status_for(course)
    membership = CourseMembership.find_by(course: course, user: self)
    if membership
      membership.status
    else
      'no_membership'
    end
  end

  def provider
    institution.provider
  end

  def self.default_photo
    Rails.root.join('app', 'assets', 'images', 'unknown_user.jpg')
  end

  def self.from_omniauth(auth)
    where(username: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.first_name = auth.info.first_name
      user.last_name = auth.info.last_name
      # TODO: fix institution
      # user.institution = Institution.find_by(name: auth.info.institution)
    end
  end

  private

  def set_token
    if username.present?
      self.token = nil
    elsif token.blank?
      self.token = SecureRandom.urlsafe_base64(16)
    end
  end

  def set_time_zone
    self.time_zone = 'Seoul' if email&.match?(/ghent.ac.kr$/)
  end
end
