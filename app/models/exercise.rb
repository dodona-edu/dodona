# == Schema Information
#
# Table name: activities
#
#  id                      :integer          not null, primary key
#  name_nl                 :string(255)
#  name_en                 :string(255)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  path                    :string(255)
#  description_format      :string(255)
#  repository_id           :integer
#  judge_id                :integer
#  status                  :integer          default("ok")
#  access                  :integer          default("public"), not null
#  programming_language_id :bigint
#  search                  :string(4096)
#  access_token            :string(16)       not null
#  repository_token        :string(64)       not null
#  allow_unsafe            :boolean          default(FALSE), not null
#  type                    :string(255)      default("Exercise"), not null
#  description_nl_present  :boolean          default(FALSE)
#  description_en_present  :boolean          default(FALSE)
#

require 'pathname'
require 'action_view'

class Exercise < Activity
  USERS_CORRECT_CACHE_STRING = '/course/%<course_id>s/exercise/%<id>s/users_correct'.freeze
  USERS_TRIED_CACHE_STRING = '/course/%<course_id>s/exercise/%<id>s/users_tried'.freeze
  SOLUTION_DIR = 'solution'.freeze
  SOLUTION_MAX_BYTES = (2**16) - 1
  BOILERPLATE_DIR = File.join(DESCRIPTION_DIR, 'boilerplate').freeze

  belongs_to :judge
  belongs_to :programming_language, optional: true
  has_many :submissions, dependent: :restrict_with_error

  before_save :check_memory_limit

  def exercise?
    true
  end

  def solutions
    (full_path + SOLUTION_DIR)
      .yield_self { |path| path.directory? ? path.children : [] }
      .filter { |path| path.file? && path.readable? }
      .to_h { |path| [path.basename.to_s, path.read(SOLUTION_MAX_BYTES)&.force_encoding('UTF-8')&.scrub || ''] }
  end

  def boilerplate_localized(lang = I18n.locale.to_s)
    ext = lang ? ".#{lang}" : ''
    file = full_path + BOILERPLATE_DIR + "boilerplate#{ext}"
    file.read if file.exist?
  end

  def boilerplate_default
    boilerplate_localized(nil)
  end

  def boilerplate_nl
    boilerplate_localized('nl')
  end

  def boilerplate_en
    boilerplate_localized('en')
  end

  def boilerplate
    boilerplate_localized || boilerplate_default || boilerplate_nl || boilerplate_en
  end

  def file_name
    "#{name.parameterize}.#{file_extension}"
  end

  def file_extension
    programming_language&.extension || 'txt'
  end

  def scratchpad?
    programming_language&.name == 'python'
  end

  def users_correct(options)
    subs = submissions.where(status: :correct)
    subs = subs.in_course(options[:course]) if options[:course].present?
    subs.distinct.count(:user_id)
  end

  invalidateable_instance_cacheable(:users_correct,
                                    ->(this, options) { format(USERS_CORRECT_CACHE_STRING, course_id: options[:course].present? ? options[:course].id.to_s : 'global', id: this.id.to_s) })

  def users_tried(options)
    subs = submissions.judged
    subs = subs.in_course(options[:course]) if options[:course].present?
    subs.distinct.count(:user_id)
  end

  invalidateable_instance_cacheable(:users_tried,
                                    ->(this, options) { format(USERS_TRIED_CACHE_STRING, course_id: options[:course] ? options[:course].id.to_s : 'global', id: this.id.to_s) })

  def last_submission(user, series = nil)
    activity_status_for(user, series).last_submission
  end

  def last_submission_before_deadline(user, series = nil)
    activity_status_for(user, series).last_submission_deadline
  end

  def best_submission(user, series = nil)
    activity_status_for(user, series).best_submission
  end

  def best_submission_before_deadline(user, series = nil)
    activity_status_for(user, series).best_submission_deadline
  end

  def best_is_last_submission?(user, series = nil)
    activity_status_for(user, series).best_is_last?
  end

  def best_submission!(user, deadline = nil, course = nil)
    last_correct_submission!(user, deadline, course) || last_submission!(user, deadline, course)
  end

  def last_correct_submission!(user, deadline = nil, course = nil)
    s = submissions.of_user(user).where(status: :correct)
    s = s.in_course(course) if course
    s = s.before_deadline(deadline) if deadline
    s.limit(1).first
  end

  def last_submission!(user, deadline = nil, course = nil)
    raise 'Second argument is a deadline, not a course' if deadline.is_a? Course

    s = submissions.of_user(user)
    s = s.in_course(course) if course
    s = s.before_deadline(deadline) if deadline
    s.limit(1).first
  end

  def check_memory_limit
    return unless ok?
    return unless merged_config.fetch('evaluation', {}).fetch('memory_limit', 0) > 500_000_000 # 500MB

    c = config
    c['evaluation'] ||= {}
    c['evaluation']['memory_limit'] = 500_000_000
    store_config(c, "lowered memory limit for #{name}\n\nThe workers running the student's code only have 4 GB of memory " \
                    "and can run 6 students' code at the same time. The maximum memory limit is 500 MB so that if 6 students submit " \
                    'bad code at the same time, there is still 1 GB of memory left for Dodona itself and the operating system.')
  end

  def self.move_relations(from, to)
    from.submissions.each { |s| s.update(exercise: to) }
    super
  end

  def safe_destroy
    return unless removed?
    return if submissions.any?
    return if series_memberships.any?

    destroy
  end

  class << self
    def type
      'exercise'
    end
  end
end
