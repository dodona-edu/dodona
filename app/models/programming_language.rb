# == Schema Information
#
# Table name: programming_languages
#
#  id          :bigint           not null, primary key
#  name        :string(255)      not null
#  editor_name :string(255)      not null
#  icon        :string(255)
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
