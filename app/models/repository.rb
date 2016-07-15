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
  EXERCISE_LOCATIONS = Rails.root.join('data', 'exercises').freeze

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :remote, presence: true
  validates :path, presence: true, uniqueness: { case_sensitive: false }

  validate :repo_is_accessible, on: :create

  before_create :clone_repo

  belongs_to :judge

  def full_path
    File.join(EXERCISE_LOCATIONS, path)
  end

  def repo_is_accessible
    cmd = ['git', 'ls-remote', remote.shellescape]
    _out, error, status = Open3.capture3(*cmd)
    errors.add(:remote, error) unless status.success?
  end

  def clone_repo
    cmd = ['git', 'clone', remote.shellescape, full_path]
    _out, error, status = Open3.capture3(*cmd)
    unless status.success?
      errors.add(:base, "cloning failed: #{error}")
      throw :abort
    end
  end
end
