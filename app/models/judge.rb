# == Schema Information
#
# Table name: judges
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  image      :string(255)
#  path       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  renderer   :string(255)      not null
#  remote     :string(255)
#  status     :integer
#

class Judge < ApplicationRecord
  include Gitable

  CONFIG_FILE = 'config.json'.freeze
  JUDGE_LOCATIONS = Rails.root.join('data/judges')

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :image, presence: true
  validates :remote, presence: true

  validate :renderer_is_renderer
  validate :repo_is_accessible, on: :create

  before_create :create_full_path
  after_create :clone_repo_delayed

  has_many :repositories, dependent: :restrict_with_error
  has_many :exercises, dependent: :restrict_with_error

  def full_path
    Pathname.new File.join(JUDGE_LOCATIONS, path)
  end

  def config
    JSON.parse(File.read(File.join(full_path, CONFIG_FILE)).force_encoding('UTF-8').scrub)
  end

  def renderer
    klass = self[:renderer]
    ActiveSupport::Inflector.constantize klass if klass
  end

  def renderer=(klass)
    self[:renderer] = klass.to_s
  end

  def renderer_is_renderer
    begin
      unless renderer <= FeedbackTableRenderer
        errors.add(:renderer, 'should be a subclass of FeedbackTableRenderer')
        return false
      end
    rescue StandardError
      errors.add(:renderer, 'should be a class in scope')
      return false
    end
    true
  end
end
