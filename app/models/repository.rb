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

class Repository < ApplicationRecord
  include Gitable

  EXERCISE_LOCATIONS = Rails.root.join('data', 'exercises').freeze

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :remote, presence: true
  validates :path, presence: true, uniqueness: { case_sensitive: false }
  validates :judge, presence: true

  validate :repo_is_accessible, on: :create

  before_create :clone_repo

  belongs_to :judge
  has_many :exercises

  def full_path
    File.join(EXERCISE_LOCATIONS, path)
  end

  def commit(msg)
    _out, error, status = Open3.capture3('git', 'commit', '--author="Dodona <dodona@ugent.be>"', '-am', msg, chdir: full_path)
    if Rails.env.production?
      _out, error, status = Open3.capture3('git push', chdir: full_path) if status.success?
    end
    [status.success?, error]
  end

  def exercise_dirs
    exercise_dirs_below(full_path)
  end

  def affected_exercise_dirs(changed_file)
    changed_file = File.expand_path(changed_file, full_path)
    [] unless changed_file.include? full_path # not in this repo
    if File.basename(changed_file) == Exercise.DIRCONFIG_FILE
      exercises_below(File.dirname(changed_file))
    else
      [exercise_containing(changed_file)].reject { |ex| ex.nil? }
    end
  end

  def exercise_dirs_below(directory)
    if exercise_directory?(directory)
      directory
    else
      Dir.entries(directory)
         .reject   { |entry| entry.start_with?('.') }
         .map      { |entry| File.join(directory, entry) }
         .select   { |entry| File.directory?(entry) }
         .flat_map { |entry| exercise_dirs_below(entry) }
    end
  end

  def exercise_dir_containing(file)
    until exercise_directory?(file) || file == full_path
      file = File.dirname(file)
    end
    file unless file == full_path
  end

  def exercise_directory?(path)
    return true if Exercise.find_by(path: path, repository_id: id)

    path = File.expand_path(path, full_path)
    Exercise.config_file? path
  end

  def process_exercises
    exercise_dirs.each { |dir| process_exercise(dir) }
  end

  def process_exercise(directory)
    ex = Exercise.find_by(path: directory, repository_id: id)

    if ex.nil?
      ex = Exercise.new(path: directory, repository_id: id)
    end

    if !ex.config_file?
      ex.status = :removed
    else
      full_exercise_path = File.expand_path(directory, full_path)
      config = Exercise.merged_config(full_path, full_exercise_path)

      j = Judge.find_by(name: config['evaluation']['handler']) if config['evaluation']

      ex.judge_id = j&.id || judge_id
      ex.programming_language = config['programming_language']
      ex.name_nl = config['description']['names']['nl']
      ex.name_en = config['description']['names']['en']
      ex.description_format = Exercise.determine_format(full_exercise_path)
      ex.visibility = Exercise.convert_visibility(config['visibility'])
      ex.status = :ok
    end

    ex.save
  end
end
