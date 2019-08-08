# == Schema Information
#
# Table name: programming_languages
#
#  id          :bigint(8)        not null, primary key
#  name        :string(255)      not null
#  editor_name :string(255)      not null
#  extension   :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class ProgrammingLanguage < ApplicationRecord
  before_save :fill_fields

  has_many :exercises, dependent: :restrict_with_error

  def fill_fields
    self.editor_name ||= name
    self.extension ||= 'txt'
  end
end
