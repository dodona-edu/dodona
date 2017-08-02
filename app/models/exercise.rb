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

  enum visibility: %i[open hidden closed]
  enum status: %i[ok not_valid removed]

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

  scope :in_repository, ->(repository) { where repository_id: repository.id }

  scope :by_name, ->(name) { where('name_nl LIKE ? OR name_en LIKE ? OR path LIKE ?', "%#{name}%", "%#{name}%", "%#{name}%") }
  scope :by_status, ->(status) { where(status: status.in?(statuses) ? status : -1) }
  scope :by_visibility, ->(visibility) { where(visibility: visibility.in?(visibilities) ? visibility : -1) }
  scope :by_filter, ->(query) { by_name(query).or(by_status(query)).or(by_visibility(query)) }

  def full_path
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
                         path.split('/').last
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
    desc = description_localized || description_nl || description_en
    desc = markdown(desc) if description_format == 'md'
    desc.html_safe
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
    repository.remote.sub(':', '/').sub(/^git@/, 'https://').sub(/\.git$/, '') + '/tree/master/' + path
  end

  def config
    Exercise.read_config_file(config_file)
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
    Pathname.new(path).parent.descend         # all parent directories
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

  def best_is_last_submission?(user, deadline = nil)
    last_correct = last_correct_submission(user, deadline)
    return true if last_correct.nil?
    last_correct == last_submission(user, deadline)
  end

  def best_submission(user, deadline = nil)
    last_correct_submission(user, deadline) || last_submission(user, deadline)
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

  def accepted_for(user, deadline = nil)
    last_submission(user, deadline).try(:accepted)
  end

  def number_of_submissions_for(user)
    submissions.of_user(user).count
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

  def self.determine_format(full_exercise_path)
    if !Dir.glob(full_exercise_path + DESCRIPTION_DIR + 'description.*.html').empty?
      'html'
    else
      'md'
    end
  end

  private

  def self.read_config_file(file)
    JSON.parse(file.read) if file.file?
  end

  #takes a relative path
  def read_dirconfig(subdir)
    Exercise.read_config_file(repository.full_path + subdir + DIRCONFIG_FILE)
  end

  def generate_id
    begin
      new = SecureRandom.random_number(2_147_483_646)
    end until Exercise.find_by(id: new).nil?
    self.id = new
  end
end
