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
#

class Judge < ApplicationRecord
  CONFIG_FILE = 'config.json'.freeze
  JUDGE_LOCATIONS = Rails.root.join('data', 'judges')

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :image, presence: true
  validates :path, presence: true, uniqueness: { case_sensitive: false }

  has_many :repositories
  has_many :exercises

  def full_path
    File.join(JUDGE_LOCATIONS, path)
  end

  def config
    JSON.parse(File.read(File.join(full_path, CONFIG_FILE)))
  end
end
