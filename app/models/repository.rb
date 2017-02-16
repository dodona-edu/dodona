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

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :remote, presence: true
  validates :path, presence: true, uniqueness: { case_sensitive: false }
  validates :judge, presence: true

  validate :repo_is_accessible, on: :create

  before_create :clone_repo

  belongs_to :judge
  has_many :exercises

  def full_path
    Pathname.new File.join(EXERCISE_LOCATIONS, path)
  end

  def commit(msg)
    _out, error, status = Open3.capture3('git', 'commit', '--author="Dodona <dodona@ugent.be>"', '-am', msg, chdir: full_path.to_path)
    if Rails.env.production?
      _out, error, status = Open3.capture3('git push', chdir: full_path.to_path) if status.success?
    end
    [status.success?, error]
  end

  def exercise_dirs
    exercise_dirs_below(full_path)
  end

  def affected_exercise_dirs(changed_file)
    changed_file = Pathname.new(changed_file)
    return if changed_file.absolute?
    changed_file = changed_file.expand_path(full_path)

    if Exercise.dirconfig_file? changed_file
      exercise_dirs_below(changed_file.dirname)
    else
      [exercise_dir_containing(changed_file)].reject(&:nil?)
    end
  end

  def process_exercises
    exercise_dirs.each { |dir| process_exercise(dir) }
  end

  def process_exercise(directory)
    relative = directory.relative_path_from(full_path).cleanpath.to_path
    ex = Exercise.find_by(path: relative, repository_id: id)
    ex = Exercise.new(path: relative, repository_id: id) if ex.nil?

    if !ex.config_file?
      ex.status = :removed
    else
      config = ex.merged_config

      j = Judge.find_by(name: config['evaluation']['handler']) if config['evaluation']

      ex.judge_id = j&.id || judge_id
      ex.programming_language = config['programming_language']
      ex.name_nl = config['description']['names']['nl']
      ex.name_en = config['description']['names']['en']
      ex.description_format = Exercise.determine_format(directory)
      ex.visibility = Exercise.convert_visibility(config['visibility'])
      ex.status = :ok
    end

    ex.save
  end

  private

  def exercise_dirs_below(directory)
    if exercise_directory?(directory)
      directory.cleanpath
    else
      directory.entries
               .reject   { |entry| entry.basename.to_path.start_with?('.') }
               .map      { |entry| entry.expand_path(directory) }
               .select(&:directory?)
               .flat_map { |entry| exercise_dirs_below(entry) }
    end
  end

  def exercise_dir_containing(file)
    file = file.dirname until exercise_directory?(file) || file == full_path
    file unless file == full_path
  end

  def exercise_directory?(file)
    file = file.cleanpath.relative_path_from(full_path)
    return true if Exercise.find_by(path: file.to_path, repository_id: id)

    Exercise.config_file? file.expand_path(full_path)
  end
end
