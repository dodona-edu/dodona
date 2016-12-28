# == Schema Information
#
# Table name: exercises
#
#  id                   :integer          not null, primary key
#  name_nl              :string(255)
#  name_en              :string(255)
#  visibility           :integer          default("open")
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  path                 :string(255)
#  description_format   :string(255)
#  programming_language :string(255)
#  repository_id        :integer
#  judge_id             :integer
#  status               :integer          default("ok")
#

require 'action_view'
include ActionView::Helpers::DateHelper

class Exercise < ApplicationRecord
  CONFIG_FILE = 'config.json'.freeze
  DIRCONFIG_FILE = 'dirconfig.json'.freeze
  DESCRIPTION_DIR = 'description'.freeze
  MEDIA_DIR = File.join(DESCRIPTION_DIR, 'media').freeze
  BOILERPLATE_DIR = File.join(DESCRIPTION_DIR, 'boilerplate').freeze

  enum visibility: [:open, :hidden, :closed]
  enum status: [:ok, :not_valid, :removed]

  belongs_to :repository
  belongs_to :judge
  has_many :submissions
  has_many :series_memberships
  has_many :series, through: :series_memberships

  validates :path, presence: true, uniqueness: { scope: :repository_id, case_sensitive: false }
  validates :repository_id, presence: true
  validates :judge, presence: true
  validates :repository, presence: true

  before_create :generate_id
  before_save :check_validity
  before_update :update_config

  scope :in_repository, -> (repository) { where repository_id: repository.id }

  scope :by_name, -> (name) { where('name_nl LIKE ? OR name_en LIKE ? OR path LIKE ?', "%#{name}%", "%#{name}%", "%#{name}%") }
  scope :by_status, -> (status) { where(status: status.in?(statuses) ? status : -1) }
  scope :by_visibility, -> (visibility) { where(visibility: visibility.in?(visibilities) ? visibility : -1) }
  scope :by_filter, -> (query) { by_name(query).or(by_status(query)).or(by_visibility(query)) }

  def full_path
    File.join(repository.full_path, path)
  end

  def media_path
    File.join(full_path, MEDIA_DIR)
  end

  def name
    name = send('name_' + I18n.locale.to_s) || name_nl || name_en
    name.blank? ? path.split('/').last : name
  end

  def description_localized(lang = I18n.locale.to_s)
    file = File.join(full_path, DESCRIPTION_DIR, "description.#{lang}.#{description_format}")
    File.read(file) if FileTest.exists?(file)
  end

  def description_nl
    description_localized('nl')
  end

  def description_en
    description_localized('en')
  end

  def description
    desc = description_localized || description_nl || description_en
    desc = markdown(desc) if description_format == 'md'
    desc.html_safe
  end

  def boilerplate_localized(lang = I18n.locale.to_s)
    ext = lang ? ".#{lang}" : ''
    file = File.join(full_path, BOILERPLATE_DIR, "boilerplate#{ext}")
    File.read(file).strip if FileTest.exists?(file)
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
    repository.remote.sub(':', '/').sub(/^git@/, 'https://').sub(/\.git$/, '') + '/tree/master' + path
  end

  def config
    Exercise.read_config(full_path)
  end

  def file_name
    "#{name.parameterize}.#{file_extension}"
  end

  def file_extension
    return 'py' if programming_language == 'python'
    return 'js' if programming_language == 'JavaScript'
    'txt'
  end

  def merged_config
    Exercise.merged_config(repository.full_path, full_path)
  end

  def config_file?
    Exercise.config_file? full_path
  end

  def self.config_file?(directory)
    File.file?(File.join(directory, CONFIG_FILE))
  end

  def self.dirconfig_file?(file)
    File.basename(file) == DIRCONFIG_FILE
  end

  def store_config(new_config)
    return if new_config == config
    File.write(File.join(full_path, CONFIG_FILE), JSON.pretty_generate(new_config))
    success, error = repository.commit "updated config for #{name}"
    unless success || error.empty?
      errors.add(:base, "commiting changes failed: #{error}")
      throw :abort
    end
  end

  def update_config
    return unless ok?
    c = config
    c['visibility'] = visibility
    c['description']['names']['nl'] = name_nl
    c['description']['names']['en'] = name_en
    store_config c
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

  def best_last_submission(user, deadline = nil)
    status = status_for(user, deadline)
    if status == :correct
      last_correct_submission(user, deadline)
    else
      last_submission(user, deadline)
    end
  end

  def last_correct_submission(user, deadline = nil)
    s = submissions.of_user(user).where(status: :correct)
    s = s.before_deadline(deadline) if deadline
    s.limit(1).first
  end

  def last_submission(user, deadline = nil)
    s = submissions.of_user(user)
    s = s.before_deadline(deadline) if deadline
    s.limit(1).first
  end

  def status_for(user, deadline = nil)
    if deadline
      status_with_deadline_for(user, deadline)
    else
      status_without_deadline_for(user)
    end
  end

  def status_with_deadline_for(user, deadline)
    return :correct if submissions.of_user(user).where(accepted: true).before_deadline(deadline).count.positive?
    :deadline_missed
  end

  def status_without_deadline_for(user)
    subs = submissions.of_user(user).group(:accepted).except(:order).count
    return :correct if subs[true].to_i.positive?
    return :wrong if subs[false].to_i.positive?
    :unknown
  end

  def number_of_submissions_for(user)
    submissions.of_user(user).count
  end

  def solving_speed_for(user)
    subs = submissions.of_user(user)
    return '' if subs.count < 2
    distance_of_time_in_words(subs.first.created_at, subs.last.created_at)
  end

  def check_validity
    return if removed?
    self.status = if !(name_nl || name_en)
                    :not_valid
                  elsif !(description_nl || description_en)
                    :not_valid
                  else
                    :ok
                  end
  end

  def self.convert_visibility(visibility)
    return 'open' if visibility == 'public'
    return 'closed' if visibility == 'private'
    visibility
  end

  def self.merged_config(full_repository_path, full_exercise_path)
    dirconfig = Exercise.dirconfig(full_repository_path, File.dirname(full_exercise_path))
    dirconfig.recursive_update(Exercise.read_config(full_exercise_path))
  end

  def self.dirconfig(full_repository_path, subpath)
    return unless subpath.start_with? full_repository_path
    config = if subpath == full_repository_path
             then {}
             else Exercise.dirconfig(full_repository_path, File.dirname(subpath))
             end
    config.recursive_update(Exercise.read_dirconfig(subpath))
  end

  def self.read_config(path)
    Exercise.read_config_file(path, CONFIG_FILE)
  end

  def self.read_dirconfig(path)
    Exercise.read_config_file(path, DIRCONFIG_FILE)
  end

  def self.read_config_file(path, file)
    file = File.join(path, file)
    JSON.parse(File.read(file)) if File.file?(file)
  end

  def self.determine_format(full_exercise_path)
    if !Dir.glob(File.join(full_exercise_path, DESCRIPTION_DIR, 'description.*.html')).empty?
      'html'
    else
      'md'
    end
  end

  private

  def generate_id
    begin
      new = SecureRandom.random_number(2_147_483_646)
    end until Exercise.find_by(id: new).nil?
    self.id = new
  end
end
