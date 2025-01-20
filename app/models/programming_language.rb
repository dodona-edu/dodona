# == Schema Information
#
# Table name: programming_languages
#
#  id            :bigint           not null, primary key
#  name          :string(255)      not null
#  editor_name   :string(255)      not null
#  extension     :string(255)      not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  icon          :string(255)
#  renderer_name :string(255)      not null
#

class ProgrammingLanguage < ApplicationRecord
  DEFAULT_ICON = 'file-document-edit-outline'.freeze

  before_save :fill_fields
  after_save :remove_from_cache

  has_many :exercises, dependent: :restrict_with_error

  # There are only a few programming languages, so we can keep them in memory
  @@in_memory_instances = {} # rubocop:disable Style/ClassVars

  def self.cached_find(id)
    return nil if id.nil?

    return nil unless id.is_a?(Integer)

    @@in_memory_instances[id] ||= find(id)
  end

  def remove_from_cache
    @@in_memory_instances.delete(id)
  end

  def fill_fields
    self.editor_name ||= name
    self.renderer_name ||= name
    self.extension ||= 'txt'
  end

  def icon
    self[:icon] || DEFAULT_ICON
  end
end
