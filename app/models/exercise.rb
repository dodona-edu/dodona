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
  DESCRIPTION_DIR = 'description'.freeze
  MEDIA_DIR = File.join(DESCRIPTION_DIR, 'media').freeze

  enum visibility: [:open, :hidden, :closed]
  enum status: [:ok, :not_valid, :removed]

  belongs_to :repository
  belongs_to :judge
  has_many :submissions
  has_many :series_memberships
  has_many :series, through: :series_memberships
  has_one :exercise_token

  validates :path, presence: true, uniqueness: { scope: :repository_id, case_sensitive: false }
  validates :repository_id, presence: true
  validates :judge, presence: true
  validates :repository, presence: true

  before_save :check_validity
  before_update :update_config

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

  def update_data(config, j_id)
    self.name_nl = config['description']['names']['nl']
    self.name_en = config['description']['names']['en']
    self.judge_id = j_id if j_id
    self.description_format = determine_format
    self.visibility = Exercise.convert_visibility(config['visibility']) if config['visibility']
    save
  end

  def visibility=(visibility)
    if visibility == 'hidden'
      if !hidden?
        create_exercise_token!
      end
    else
      exercise_token.try :delete
    end
    super(visibility)
  end

  def determine_format
    if ['description.nl.html', 'description.en.html'].any? { |f| FileTest.exists?(File.join(full_path, DESCRIPTION_DIR, f)) }
      return 'html'
    else
      return 'md'
    end
  end

  def config
    JSON.parse(File.read(File.join(full_path, CONFIG_FILE)))
  end

  def merged_config
    result = repository.config
    result.recursive_update(config)
    result
  end

  def store_config(config)
    File.write(File.join(full_path, CONFIG_FILE), JSON.pretty_generate(config))
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
    if course
      subs = subs.in_course(course)
    end
    subs.distinct.count(:user_id)
  end

  def users_tried
    submissions.all.distinct.count(:user_id)
  end

  def last_correct_submission(user)
    submissions.of_user(user).where(status: :correct).limit(1).first
  end

  def last_submission(user)
    submissions.of_user(user).limit(1).first
  end

  def status_for(user)
    return :correct if submissions.of_user(user).where(accepted: true).count.positive?
    return :wrong if submissions.of_user(user).where(accepted: false).count.positive?
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

  def hidden_token_in?(set)
    set.include? exercise_token.token
  end

  def self.process_repository(repository)
    Exercise.process_directory(repository, '/')
  end

  def self.process_directories(repository, directories)
    directories.each { |dir| Exercise.process_directory(repository, dir) }
  end

  def self.process_directory(repository, directory)
    if Exercise.exercise_directory?(repository, directory)
      Exercise.process_exercise(repository, directory)
    else
      path = File.join(repository.full_path, directory)
      Dir.entries(path)
         .select { |entry| File.directory?(File.join(path, entry)) && !entry.start_with?('.') }
         .each { |entry| Exercise.process_directory(repository, File.join(directory, entry)) }
    end
  end

  def self.process_exercise(repository, directory)
    config_file = File.join(repository.full_path, directory, CONFIG_FILE)
    ex = Exercise.find_by(path: directory, repository_id: repository.id)

    if ex && !File.file?(config_file)
      ex.status = :removed
    else
      config = JSON.parse(File.read(config_file))
      j = Judge.find_by_name(config['evaluation']['handler']) if config['evaluation']
      j_id = j.nil? ? repository.judge_id : j.id

      if ex.nil?
        ex = Exercise.create(path: directory, repository_id: repository.id, judge_id: j_id, programming_language: 'python')
      else
        ex.status = :ok
      end

      ex.update_data(config, j_id)
    end
  end

  def self.exercise_directory?(repository, path)
    return true if Exercise.find_by(path: path, repository_id: repository.id)

    path = File.join(repository.full_path, path)
    config_file = File.join(path, CONFIG_FILE)
    File.file? config_file
  end

  def self.convert_visibility(visibility)
    return 'open' if visibility == 'public'
    return 'closed' if visibility == 'private'
    visibility
  end
end
