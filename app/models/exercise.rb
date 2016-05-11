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

require 'action_view'
include ActionView::Helpers::DateHelper

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

  def users_correct
    submissions.where(status: :correct).distinct.count(:user_id)
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
    return :correct if submissions.of_user(user).where(status: :correct).count > 0
    return :wrong if submissions.of_user(user).where(status: :wrong).count > 0
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

  def self.refresh(changed)
    msg = `cd #{DATA_DIR} && git pull 2>&1`
    status = $CHILD_STATUS.exitstatus
    Exercise.process_directories(changed)
    [status, msg]
  end

  def self.process_directories(changed)
    Dir.entries(DATA_DIR)
      .select { |entry| File.directory?(File.join(DATA_DIR, entry)) && !entry.start_with?('.') && (changed.include?(entry) || changed.include?('UPDATE_ALL')) }
      .each { |entry| Exercise.process_exercise_directory(entry) }
  end

  def self.process_exercise_directory(dir)
    exercise = Exercise.find_by_name(dir) || Exercise.create(name: dir)
    exercise.copy_media
  end
end
