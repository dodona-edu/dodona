# == Schema Information
#
# Table name: exercises
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  visibility :integer          default("0")
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Exercise < ApplicationRecord
  DATA_DIR = Rails.root.join('data', 'exercises').freeze
  TESTS_FILE = 'tests.js'.freeze
  DESCRIPTION_FILE = 'NL.md'.freeze
  MEDIA_DIR = 'media'.freeze
  PUBLIC_DIR = Rails.root.join('public', 'exercises').freeze

  enum visibility: [:open, :hidden, :closed]

  has_many :submissions

  def tests
    file = File.join(DATA_DIR, name, TESTS_FILE)
    File.read(file) if FileTest.exists?(file)
  end

  def description
    file = File.join(DATA_DIR, name, DESCRIPTION_FILE)
    File.read(file) if FileTest.exists?(file)
  end

  def copy_media
    media_src = File.join(DATA_DIR, name, MEDIA_DIR)
    media_dst = File.join PUBLIC_DIR, name
    if FileTest.exists? media_src
      Dir.mkdir media_dst unless FileTest.exists? media_dst
      FileUtils.cp_r media_src, media_dst
    end
  end

  def self.refresh
    msg = `cd #{DATA_DIR} && git pull 2>&1`
    status = $CHILD_STATUS.exitstatus
    Exercise.process_directories
    [status, msg]
  end

  def self.process_directories
    Dir.entries(DATA_DIR)
      .select { |entry| File.directory?(File.join(DATA_DIR, entry)) && !entry.start_with?('.') }
      .each { |entry| Exercise.process_exercise_directory(entry) }
  end

  def self.process_exercise_directory(dir)
    exercise = Exercise.find_by_name(dir) || Exercise.create(name: dir)
    exercise.copy_media
  end
end
