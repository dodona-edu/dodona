# == Schema Information
#
# Table name: exercises
#
#  id                   :integer          not null, primary key
#  name_nl              :string(255)
#  name_en              :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  path                 :string(255)
#  description_format   :string(255)
#  programming_language :string(255)
#  repository_id        :integer
#  judge_id             :integer
#  status               :integer          default("ok")
#  token                :string(64)       not null, unique
#  access               :integer          not null, default("public")
#

require 'pathname'
require 'action_view'
include ActionView::Helpers::DateHelper

class Exercise < ApplicationRecord
  include StringHelper

  CONFIG_FILE = 'config.json'.freeze
  DIRCONFIG_FILE = 'dirconfig.json'.freeze
  DESCRIPTION_DIR = 'description'.freeze
  MEDIA_DIR = File.join(DESCRIPTION_DIR, 'media').freeze
  BOILERPLATE_DIR = File.join(DESCRIPTION_DIR, 'boilerplate').freeze

  # We need to prefix, otherwise Rails can't generate the public? method
  enum access: %i[public private], _prefix: true
  enum status: %i[ok not_valid removed]

  belongs_to :repository
  belongs_to :judge
  has_many :submissions
  has_many :series_memberships
  has_many :series, through: :series_memberships
  has_many :exercise_labels, dependent: :destroy
  has_many :labels, through: :exercise_labels

  validates :path, uniqueness: { scope: :repository_id, case_sensitive: false }

  before_create :generate_id
  before_create :generate_token
  before_save :check_validity
  before_update :update_config

  scope :in_repository, ->(repository) { where repository_id: repository.id }

  scope :by_name, ->(name) { where('name_nl LIKE ? OR name_en LIKE ? OR path LIKE ?', "%#{name}%", "%#{name}%", "%#{name}%") }
  scope :by_status, ->(status) { where(status: status.in?(statuses) ? status : -1) }
  scope :by_access, ->(access) { where(access: access.in?(accesses) ? access : -1) }
  scope :by_labels, ->(labels) { joins(:labels).includes(:labels).where(labels: {name: labels}).group(:id).having('COUNT(DISTINCT(exercise_labels.label_id)) = ?', labels.uniq.length) }
  scope :by_filter, ->(query) { by_name(query).or(by_status(query)).or(by_access(query)) }

  def full_path
    return '' unless path
    Pathname.new File.join(repository.full_path, path)
  end

  def media_path
    full_path + MEDIA_DIR
  end

  def config_file
    full_path + CONFIG_FILE
  end

  def name
    first_string_present send('name_' + I18n.locale.to_s),
                         name_nl,
                         name_en,
                         path&.split('/')&.last
  end

  def description_localized(lang = I18n.locale.to_s)
    file = full_path + DESCRIPTION_DIR + "description.#{lang}.#{description_format}"
    file.read if file.exist?
  end

  def description_nl
    description_localized('nl')
  end

  def description_en
    description_localized('en')
  end

  def description
    description_localized || description_nl || description_en || ''
  end

  def boilerplate_localized(lang = I18n.locale.to_s)
    ext = lang ? ".#{lang}" : ''
    file = full_path + BOILERPLATE_DIR + "boilerplate#{ext}"
    file.read.strip if file.exist?
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

  def github_url
    repository.github_url(path)
  end

  def config
    repository.read_config_file(config_file)
  end

  def file_name
    "#{name.parameterize}.#{file_extension}"
  end

  def file_extension
    return 'py' if programming_language == 'python'
    return 'js' if programming_language == 'JavaScript'
    return 'hs' if programming_language == 'haskell'
    return 'sh' if programming_language == 'bash'
    return 'sh' if programming_language == 'shell'
    return 'sh' if programming_language == 'sh'
    'txt'
  end

  def merged_config
    Pathname.new('./' + path).parent.descend  # all parent directories
            .map { |dir| read_dirconfig dir } # try reading their dirconfigs
            .compact                          # remove nil entries
            .push(config)                     # add exercise config file
            .reduce(&:deep_merge)             # reduce into single hash
  end

  def config_file?
    Exercise.config_file? full_path
  end

  def self.config_file?(directory)
    (directory + CONFIG_FILE).file?
  end

  def self.config_file(directory)
    directory + CONFIG_FILE
  end

  def self.dirconfig_file?(file)
    file.basename.to_s == DIRCONFIG_FILE
  end

  def store_config(new_config)
    return if new_config == config
    config_file.write(JSON.pretty_generate(new_config))
    success, error = repository.commit "updated config for #{name}"
    unless success || error.empty?
      errors.add(:base, "commiting changes failed: #{error}")
      throw :abort
    end
  end

  def update_config
    return unless ok?
    c = config
    c.delete('visibility')
    c['access'] = access if defined?(access) && access != merged_config['access']
    c['description']['names']['nl'] = name_nl
    c['description']['names']['en'] = name_en
    c['internals'] = {}
    c['internals']['token'] = token
    c['internals']['_info'] = 'These fields are used for internal bookkeeping in Dodona, please do not change them.'
    store_config c
  end

  def usable_by?(course)
    access_public? || course.usable_repositories.include?(repository)
  end

  def users_correct(course = nil)
    subs = submissions.where(status: :correct)
    subs = subs.in_course(course) if course
    subs.distinct.count(:user_id)
  end

  def users_tried(course = nil)
    subs = submissions.all
    subs = subs.in_course(course) if course
    subs.distinct.count(:user_id)
  end

  def best_is_last_submission?(user, deadline = nil, course = nil)
    last_correct = last_correct_submission(user, deadline, course)
    return true if last_correct.nil?
    last_correct == last_submission(user, deadline, course)
  end

  def best_submission(user, deadline = nil, course = nil)
    last_correct_submission(user, deadline, course) || last_submission(user, deadline, course)
  end

  def last_correct_submission(user, deadline = nil, course = nil)
    s = submissions.of_user(user).where(status: :correct)
    s = s.in_course(course) if course
    s = s.before_deadline(deadline) if deadline
    s.limit(1).first
  end

  def last_submission(user, deadline = nil, course = nil)
    raise 'Second argument is a deadline, not a course' if deadline.is_a? Course
    s = submissions.of_user(user)
    s = s.in_course(course) if course
    s = s.before_deadline(deadline) if deadline
    s.limit(1).first
  end

  def accepted_for(user, deadline = nil, course = nil)
    last_submission(user, deadline, course).try(:accepted)
  end

  def number_of_submissions_for(user, course = nil)
    s = submissions.of_user(user)
    s = s.in_course(course) if course
    s.count
  end

  def check_validity
    return unless ok?
    self.status = if !(name_nl || name_en)
                    :not_valid
                  elsif !(description_nl || description_en)
                    :not_valid
                  else
                    :ok
                  end
  end

  def self.convert_visibility_to_access(visibility)
    return 'public' if visibility == 'visible'
    return 'public' if visibility == 'open'
    return 'private' if visibility == 'invisible'
    return 'private' if visibility == 'hidden'
    return 'private' if visibility == 'closed'
    visibility
  end

  def self.determine_format(full_exercise_path)
    if !Dir.glob(full_exercise_path + DESCRIPTION_DIR + 'description.*.html').empty?
      'html'
    else
      'md'
    end
  end

  # not private so we can use this in the migration
  def generate_token
    begin
      new_token = Base64.strict_encode64 SecureRandom.random_bytes(48)
    end until Exercise.find_by(token: new_token).nil?
    self.token ||= new_token
  end

  private

  # takes a relative path
  def read_dirconfig(subdir)
    repository.read_config_file(subdir + DIRCONFIG_FILE)
  end

  def generate_id
    begin
      new = SecureRandom.random_number(2_147_483_646)
    end until Exercise.find_by(id: new).nil?
    self.id = new
  end
end
