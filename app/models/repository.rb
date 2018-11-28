# == Schema Information
#
# Table name: repositories
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  remote     :string(255)
#  path       :string(255)
#  judge_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'open3'
require 'pathname'

class Repository < ApplicationRecord
  include Gitable

  EXERCISE_LOCATIONS = Rails.root.join('data', 'exercises').freeze
  MEDIA_DIR = 'public'.freeze

  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validates :remote, presence: true

  validate :repo_is_accessible, on: :create

  before_create :clone_repo

  belongs_to :judge
  has_many :exercises
  has_many :repository_admins
  has_many :admins,
           through: :repository_admins,
           source: :user
  has_many :course_repositories
  has_many :allowed_courses,
           through: :course_repositories,
           source: :course

  def full_path
    Pathname.new File.join(EXERCISE_LOCATIONS, path)
  end

  def media_path
    full_path + MEDIA_DIR
  end

  def commit(msg)
    author = if Current.user&.full_name && Current.user&.email
               "#{Current.user.full_name} <#{Current.user.email}>"
             else
               'Dodona <dodona@ugent.be>'
             end
    _out, error, status = Open3.capture3('git', 'commit', "--author=\"#{author}\"", '-am', "#{msg}\n\nThis commit was created automatically by Dodona.", chdir: full_path.to_path)
    if Rails.env.production?
      _out, error, status = Open3.capture3('git push', chdir: full_path.to_path) if status.success?
    end
    [status.success?, error]
  end

  def exercise_dirs
    exercise_dirs_below(full_path)
  end

  def process_exercises_email_errors(user: nil, name: nil, email: nil)
    process_exercises
  rescue AggregatedConfigErrors => error
    ErrorMailer.json_error(error, user: user, name: name, email: email).deliver
  end

  def process_exercises
    dirs = exercise_dirs
    errors = []

    exercise_dirs_and_configs = dirs.map do |d|
      [d, read_config_file(Exercise.config_file(d))]
    rescue ConfigParseError => e
      errors.push e
      nil
    end.compact

    existing_exercises = exercise_dirs_and_configs
                             .reject {|_, c| c['internals'].nil? || c['internals']['token'].nil?}
                             .map {|d, c| [d, Exercise.find_by(token: c['internals']['token'], repository_id: id)]}
                             .reject {|_, e| e.nil?}
                             .group_by {|_, e| e}
                             .map {|e, l| [e, l.map {|elem| elem[0]}]}
                             .to_h
    handled_directories = []
    handled_exercises = []
    new_exercises = []

    existing_exercises.each do |ex, directories|
      orig_path = directories.select {|dir| dir == ex.full_path}.first || directories.first
      ex.path = exercise_relative_path orig_path
      update_exercise ex
      handled_exercises.push ex
      handled_directories.push orig_path
      directories.reject {|dir| dir == orig_path}.each do |dir|
        new_ex = Exercise.new(path: exercise_relative_path(dir), repository_id: id)
        new_exercises.push new_ex
        update_exercise new_ex
        handled_exercises.push new_ex
        handled_directories.push dir
      end
    end

    repository_exercises = Exercise.where(repository_id: id)
    repository_exercises.reject {|e| handled_exercises.include? e}.each do |ex|
      if dirs.include?(ex.full_path) && !handled_directories.include?(ex.full_path)
        handled_directories.push ex.full_path
        if exercise_dirs_and_configs.select {|d, _| d == ex.full_path}.first.nil?
          ex.update(status: :not_valid)
        else
          update_exercise ex
          ex.update_config
        end
      else
        ex.update(status: :removed, path: nil)
      end
    end

    exercise_dirs_and_configs.reject {|d, _| handled_directories.include? d}.each do |dir, c|
      token = c['internals'] && c['internals']['token']
      if token && token.is_a?(String) && token.length == 64 && Exercise.find_by(token: token).nil?
        ex = Exercise.new(path: exercise_relative_path(dir), repository_id: id, token: token)
      else
        ex = Exercise.new(path: exercise_relative_path(dir), repository_id: id)
        new_exercises.push ex
      end
      update_exercise ex
    end

    new_exercises.each do |ex|
      c = ex.config
      c['internals'] = {}
      c['internals']['token'] = ex.token
      c['internals']['_info'] = 'These fields are used for internal bookkeeping in Dodona, please do not change them.'
      ex.config_file.write(JSON.pretty_generate(c))
    end
    unless new_exercises.empty?
      commit 'stored tokens in new exercises'
    end

    raise AggregatedConfigErrors.new(self, errors) if errors.any?
  end

  def update_exercise(ex)
    config = ex.merged_config

    j = nil
    j = Judge.find_by(name: config['evaluation']['handler']) if config['evaluation']
    programming_language_name = config['programming_language']
    programming_language = nil
    if programming_language_name
      programming_language = ProgrammingLanguage.find_by(name: programming_language_name)
      programming_language ||= ProgrammingLanguage.create(name: programming_language_name)
    end

    labels = config['labels']&.map do |name|
      Label.find_by(name: name) || Label.create(name: name)
    end || []

    ex.judge = j || judge
    ex.programming_language = programming_language
    ex.name_nl = config['description']&.fetch('names', nil)&.fetch('nl', nil)
    ex.name_en = config['description']&.fetch('names', nil)&.fetch('en', nil)
    ex.description_format = Exercise.determine_format(ex.full_path)
    ex.access = Exercise.convert_visibility_to_access(config['visibility']) if config['visibility']
    ex.access = config['access'] if config['access']
    ex.access ||= :private
    ex.status = :ok
    ex.labels = labels

    ex.save
  end

  def github_url(path = nil)
    if github_remote?
      url = remote.sub(':', '/').sub(/^git@/, 'https://').sub(/\.git$/, '')
      url += '/tree/master/' + path.to_s if path
      url
    end
  end

  def read_config_file(file)
    file = full_path + file if file.relative?
    JSON.parse file.read if file.file?
  rescue JSON::ParserError => e
    rel_path = file.relative_path_from(full_path)
    raise ConfigParseError.new(self, rel_path, e.to_s)
  end

  private

  def exercise_dirs_below(directory)
    if exercise_directory?(directory)
      directory.cleanpath
    else
      directory.entries
          .reject {|entry| entry.basename.to_path.start_with?('.')}
          .map {|entry| entry.expand_path(directory)}
          .select(&:directory?)
          .flat_map {|entry| exercise_dirs_below(entry)}
    end
  end

  def exercise_dir_containing(file)
    file = file.dirname until exercise_directory?(file) || file == full_path
    file unless file == full_path
  end

  def exercise_directory?(file)
    Exercise.config_file? file
  end

  def exercise_relative_path(path)
    path.cleanpath.relative_path_from full_path
  end
end
